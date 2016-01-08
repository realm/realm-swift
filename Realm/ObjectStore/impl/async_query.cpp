////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#include "impl/async_query.hpp"

#include "impl/realm_coordinator.hpp"
#include "results.hpp"

using namespace realm;
using namespace realm::_impl;

AsyncQuery::AsyncQuery(Results& target)
: BackgroundCollection(target.get_realm())
, m_target_results(&target)
, m_sort(target.get_sort())
{
    Query q = target.get_query();
    set_table(*q.get_table());
    m_query_handover = Realm::Internal::get_shared_group(get_realm()).export_for_handover(q, MutableSourcePayload::Move);
}

void AsyncQuery::release_data() noexcept
{
    m_query = nullptr;
}

// Most of the inter-thread synchronization for run(), prepare_handover(),
// attach_to(), detach(), release_query() and deliver() is done by
// RealmCoordinator external to this code, which has some potentially
// non-obvious results on which members are and are not safe to use without
// holding a lock.
//
// attach_to(), detach(), run(), prepare_handover(), and release_query() are
// all only ever called on a single thread. call_callbacks() and deliver() are
// called on the same thread. Calls to prepare_handover() and deliver() are
// guarded by a lock.
//
// In total, this means that the safe data flow is as follows:
//  - prepare_handover(), attach_to(), detach() and release_query() can read
//    members written by each other
//  - deliver() can read members written to in prepare_handover(), deliver(),
//    and call_callbacks()
//  - call_callbacks() and read members written to in deliver()
//
// Separately from this data flow for the query results, all uses of
// m_target_results, m_callbacks, and m_callback_index must be done with the
// appropriate mutex held to avoid race conditions when the Results object is
// destroyed while the background work is running, and to allow removing
// callbacks from any thread.

static bool map_moves(size_t& idx, CollectionChangeIndices const& changes)
{
    for (auto&& move : changes.moves) {
        if (move.from == idx) {
            idx = move.to;
            return true;
        }
    }
    return false;
}

void AsyncQuery::do_add_required_change_info(TransactionChangeInfo& info)
{
    REALM_ASSERT(m_query);
    m_info = &info;
}

void AsyncQuery::run()
{
    REALM_ASSERT(m_info);
    m_did_change = false;

    {
        std::lock_guard<std::mutex> target_lock(m_target_mutex);
        // Don't run the query if the results aren't actually going to be used
        if (!m_target_results || (!have_callbacks() && !m_target_results->wants_background_updates())) {
            return;
        }
    }

    REALM_ASSERT(!m_tv.is_attached());

    size_t table_ndx = m_query->get_table()->get_index_in_group();

    // If we've run previously, check if we need to rerun
    if (m_initial_run_complete) {
        // Make an empty tableview from the query to get the table version, since
        // Query doesn't expose it
        if (m_query->find_all(0, 0, 0).sync_if_needed() == m_handed_over_table_version) {
            return;
        }
    }

    m_tv = m_query->find_all();
    if (m_sort) {
        m_tv.sort(m_sort.column_indices, m_sort.ascending);
    }

    if (m_initial_run_complete) {
        auto changes = table_ndx < m_info->tables.size() ? &m_info->tables[table_ndx] : nullptr;

        std::vector<size_t> next_rows;
        next_rows.reserve(m_tv.size());
        for (size_t i = 0; i < m_tv.size(); ++i)
            next_rows.push_back(m_tv[i].get_index());

        if (changes) {
            for (auto& idx : m_previous_rows) {
                if (changes->deletions.contains(idx))
                    idx = npos;
                else
                    map_moves(idx, *changes);
                REALM_ASSERT_DEBUG(!changes->insertions.contains(idx));
            }
        }

        m_changes = CollectionChangeIndices::calculate(m_previous_rows, next_rows,
                                                       [&](size_t row) { return m_info->row_did_change(*m_query->get_table(), row); },
                                                       !!m_sort);
        m_previous_rows = std::move(next_rows);
        if (m_changes.empty()) {
            m_tv = {};
            return;
        }
    }
    else {
        m_previous_rows.resize(m_tv.size());
        for (size_t i = 0; i < m_tv.size(); ++i)
            m_previous_rows[i] = m_tv[i].get_index();
    }

    m_did_change = true;
}

bool AsyncQuery::do_prepare_handover(SharedGroup& sg)
{
    if (!m_tv.is_attached()) {
        return false;
    }

    REALM_ASSERT(m_tv.is_in_sync());

    m_initial_run_complete = true;
    m_handed_over_table_version = m_tv.sync_if_needed();
    m_tv_handover = sg.export_for_handover(m_tv, MutableSourcePayload::Move);

    add_changes(std::move(m_changes));
    REALM_ASSERT(m_changes.empty());

    // detach the TableView as we won't need it again and keeping it around
    // makes advance_read() much more expensive
    m_tv = {};

    return m_did_change;
}

bool AsyncQuery::do_deliver(SharedGroup& sg)
{
    std::lock_guard<std::mutex> target_lock(m_target_mutex);

    // Target results being null here indicates that it was destroyed while we
    // were in the process of advancing the Realm version and preparing for
    // delivery, i.e. it was destroyed from the "wrong" thread
    if (!m_target_results) {
        return false;
    }

    // We can get called before the query has actually had the chance to run if
    // we're added immediately before a different set of async results are
    // delivered
    if (!m_initial_run_complete) {
        return false;
    }

    REALM_ASSERT(!m_query_handover);

    if (m_tv_handover) {
        m_tv_handover->version = version();
        Results::Internal::set_table_view(*m_target_results,
                                          std::move(*sg.import_from_handover(std::move(m_tv_handover))));
    }
    REALM_ASSERT(!m_tv_handover);
    return have_callbacks();
}

void AsyncQuery::do_attach_to(SharedGroup& sg)
{
    REALM_ASSERT(m_query_handover);
    m_query = sg.import_from_handover(std::move(m_query_handover));
}

void AsyncQuery::do_detach_from(SharedGroup& sg)
{
    REALM_ASSERT(m_query);
    REALM_ASSERT(!m_tv.is_attached());

    m_query_handover = sg.export_for_handover(*m_query, MutableSourcePayload::Move);
    m_query = nullptr;
}
