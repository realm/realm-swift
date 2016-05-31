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

#include "impl/results_notifier.hpp"

using namespace realm;
using namespace realm::_impl;

ResultsNotifier::ResultsNotifier(Results& target)
: CollectionNotifier(target.get_realm())
, m_target_results(&target)
, m_sort(target.get_sort())
, m_target_is_in_table_order(target.is_in_table_order())
{
    Query q = target.get_query();
    set_table(*q.get_table());
    m_query_handover = Realm::Internal::get_shared_group(*get_realm()).export_for_handover(q, MutableSourcePayload::Move);
}

void ResultsNotifier::target_results_moved(Results& old_target, Results& new_target)
{
    auto lock = lock_target();

    REALM_ASSERT(m_target_results == &old_target);
    m_target_results = &new_target;
}

void ResultsNotifier::release_data() noexcept
{
    m_query = nullptr;
}

// Most of the inter-thread synchronization for run(), prepare_handover(),
// attach_to(), detach(), release_data() and deliver() is done by
// RealmCoordinator external to this code, which has some potentially
// non-obvious results on which members are and are not safe to use without
// holding a lock.
//
// add_required_change_info(), attach_to(), detach(), run(),
// prepare_handover(), and release_data() are all only ever called on a single
// background worker thread. call_callbacks() and deliver() are called on the
// target thread. Calls to prepare_handover() and deliver() are guarded by a
// lock.
//
// In total, this means that the safe data flow is as follows:
//  - add_Required_change_info(), prepare_handover(), attach_to(), detach() and
//    release_data() can read members written by each other
//  - deliver() can read members written to in prepare_handover(), deliver(),
//    and call_callbacks()
//  - call_callbacks() and read members written to in deliver()
//
// Separately from the handover data flow, m_target_results is guarded by the target lock

bool ResultsNotifier::do_add_required_change_info(TransactionChangeInfo& info)
{
    REALM_ASSERT(m_query);
    m_info = &info;

    auto table_ndx = m_query->get_table()->get_index_in_group();
    if (info.table_moves_needed.size() <= table_ndx)
        info.table_moves_needed.resize(table_ndx + 1);
    info.table_moves_needed[table_ndx] = true;

    return m_initial_run_complete && have_callbacks();
}

bool ResultsNotifier::need_to_run()
{
    REALM_ASSERT(m_info);
    REALM_ASSERT(!m_tv.is_attached());

    {
        auto lock = lock_target();
        // Don't run the query if the results aren't actually going to be used
        if (!get_realm() || (!have_callbacks() && !m_target_results->wants_background_updates())) {
            return false;
        }
    }

    // If we've run previously, check if we need to rerun
    if (m_initial_run_complete && m_query->sync_view_if_needed() == m_last_seen_version) {
        return false;
    }

    return true;
}

void ResultsNotifier::calculate_changes()
{
    size_t table_ndx = m_query->get_table()->get_index_in_group();
    if (m_initial_run_complete) {
        auto changes = table_ndx < m_info->tables.size() ? &m_info->tables[table_ndx] : nullptr;

        std::vector<size_t> next_rows;
        next_rows.reserve(m_tv.size());
        for (size_t i = 0; i < m_tv.size(); ++i)
            next_rows.push_back(m_tv[i].get_index());

        if (changes) {
            auto const& moves = changes->moves;
            for (auto& idx : m_previous_rows) {
                auto it = lower_bound(begin(moves), end(moves), idx,
                                      [](auto const& a, auto b) { return a.from < b; });
                if (it != moves.end() && it->from == idx)
                    idx = it->to;
                else if (changes->deletions.contains(idx))
                    idx = npos;
                else
                    REALM_ASSERT_DEBUG(!changes->insertions.contains(idx));
            }
        }

        m_changes = CollectionChangeBuilder::calculate(m_previous_rows, next_rows,
                                                       get_modification_checker(*m_info, *m_query->get_table()),
                                                       m_target_is_in_table_order && !m_sort);

        m_previous_rows = std::move(next_rows);
    }
    else {
        m_previous_rows.resize(m_tv.size());
        for (size_t i = 0; i < m_tv.size(); ++i)
            m_previous_rows[i] = m_tv[i].get_index();
    }
}

void ResultsNotifier::run()
{
    if (!need_to_run())
        return;

    m_query->sync_view_if_needed();
    m_tv = m_query->find_all();
    if (m_sort) {
        m_tv.sort(m_sort.column_indices, m_sort.ascending);
    }
    m_last_seen_version = m_tv.sync_if_needed();

    calculate_changes();
}

void ResultsNotifier::do_prepare_handover(SharedGroup& sg)
{
    if (!m_tv.is_attached()) {
        return;
    }

    REALM_ASSERT(m_tv.is_in_sync());

    m_initial_run_complete = true;
    m_tv_handover = sg.export_for_handover(m_tv, MutableSourcePayload::Move);

    add_changes(std::move(m_changes));
    REALM_ASSERT(m_changes.empty());

    // detach the TableView as we won't need it again and keeping it around
    // makes advance_read() much more expensive
    m_tv = {};
}

bool ResultsNotifier::do_deliver(SharedGroup& sg)
{
    auto lock = lock_target();

    // Target realm being null here indicates that we were unregistered while we
    // were in the process of advancing the Realm version and preparing for
    // delivery, i.e. the results was destroyed from the "wrong" thread
    if (!get_realm()) {
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
    return true;
}

void ResultsNotifier::do_attach_to(SharedGroup& sg)
{
    REALM_ASSERT(m_query_handover);
    m_query = sg.import_from_handover(std::move(m_query_handover));
}

void ResultsNotifier::do_detach_from(SharedGroup& sg)
{
    REALM_ASSERT(m_query);
    REALM_ASSERT(!m_tv.is_attached());

    m_query_handover = sg.export_for_handover(*m_query, MutableSourcePayload::Move);
    m_query = nullptr;
}
