////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#include "impl/collection_notifier.hpp"

#include "impl/realm_coordinator.hpp"
#include "shared_realm.hpp"

#include <realm/link_view.hpp>

using namespace realm;
using namespace realm::_impl;

std::function<bool (size_t)>
CollectionNotifier::get_modification_checker(TransactionChangeInfo const& info,
                                             Table const& root_table)
{
    // First check if any of the tables accessible from the root table were
    // actually modified. This can be false if there were only insertions, or
    // deletions which were not linked to by any row in the linking table
    auto table_modified = [&](auto& tbl) {
        return tbl.table_ndx < info.tables.size()
            && !info.tables[tbl.table_ndx].modifications.empty();
    };
    if (!any_of(begin(m_related_tables), end(m_related_tables), table_modified)) {
        return [](size_t) { return false; };
    }

    return DeepChangeChecker(info, root_table, m_related_tables);
}

void DeepChangeChecker::find_related_tables(std::vector<RelatedTable>& out, Table const& table)
{
    auto table_ndx = table.get_index_in_group();
    if (any_of(begin(out), end(out), [=](auto& tbl) { return tbl.table_ndx == table_ndx; }))
        return;

    // We need to add this table to `out` before recurring so that the check
    // above works, but we can't store a pointer to the thing being populated
    // because the recursive calls may resize `out`, so instead look it up by
    // index every time
    size_t out_index = out.size();
    out.push_back({table_ndx, {}});

    for (size_t i = 0, count = table.get_column_count(); i != count; ++i) {
        auto type = table.get_column_type(i);
        if (type == type_Link || type == type_LinkList) {
            out[out_index].links.push_back({i, type == type_LinkList});
            find_related_tables(out, *table.get_link_target(i));
        }
    }
}

DeepChangeChecker::DeepChangeChecker(TransactionChangeInfo const& info,
                                     Table const& root_table,
                                     std::vector<RelatedTable> const& related_tables)
: m_info(info)
, m_root_table(root_table)
, m_root_table_ndx(root_table.get_index_in_group())
, m_root_modifications(m_root_table_ndx < info.tables.size() ? &info.tables[m_root_table_ndx].modifications : nullptr)
, m_related_tables(related_tables)
{
}

bool DeepChangeChecker::check_outgoing_links(size_t table_ndx,
                                             Table const& table,
                                             size_t row_ndx, size_t depth)
{
    auto it = find_if(begin(m_related_tables), end(m_related_tables),
                      [&](auto&& tbl) { return tbl.table_ndx == table_ndx; });
    if (it == m_related_tables.end())
        return false;

    // Check if we're already checking if the destination of the link is
    // modified, and if not add it to the stack
    auto already_checking = [&](size_t col) {
        for (auto p = m_current_path.begin(); p < m_current_path.begin() + depth; ++p) {
            if (p->table == table_ndx && p->row == row_ndx && p->col == col)
                return true;
        }
        m_current_path[depth] = {table_ndx, row_ndx, col, false};
        return false;
    };

    for (auto const& link : it->links) {
        if (already_checking(link.col_ndx))
            continue;
        if (!link.is_list) {
            if (table.is_null_link(link.col_ndx, row_ndx))
                continue;
            auto dst = table.get_link(link.col_ndx, row_ndx);
            return check_row(*table.get_link_target(link.col_ndx), dst, depth + 1);
        }

        auto& target = *table.get_link_target(link.col_ndx);
        auto lvr = table.get_linklist(link.col_ndx, row_ndx);
        for (size_t j = 0, size = lvr->size(); j < size; ++j) {
            size_t dst = lvr->get(j).get_index();
            if (check_row(target, dst, depth + 1))
                return true;
        }
    }

    return false;
}

bool DeepChangeChecker::check_row(Table const& table, size_t idx, size_t depth)
{
    // Arbitrary upper limit on the maximum depth to search
    if (depth >= m_current_path.size()) {
        // Don't mark any of the intermediate rows checked along the path as
        // not modified, as a search starting from them might hit a modification
        for (size_t i = 1; i < m_current_path.size(); ++i)
            m_current_path[i].depth_exceeded = true;
        return false;
    }

    size_t table_ndx = table.get_index_in_group();
    if (depth > 0 && table_ndx < m_info.tables.size() && m_info.tables[table_ndx].modifications.contains(idx))
        return true;

    if (m_not_modified.size() <= table_ndx)
        m_not_modified.resize(table_ndx + 1);
    if (m_not_modified[table_ndx].contains(idx))
        return false;

    bool ret = check_outgoing_links(table_ndx, table, idx, depth);
    if (!ret && !m_current_path[depth].depth_exceeded)
        m_not_modified[table_ndx].add(idx);
    return ret;
}

bool DeepChangeChecker::operator()(size_t ndx)
{
    if (m_root_modifications && m_root_modifications->contains(ndx))
        return true;
    return check_row(m_root_table, ndx, 0);
}

CollectionNotifier::CollectionNotifier(std::shared_ptr<Realm> realm)
: m_realm(std::move(realm))
, m_sg_version(Realm::Internal::get_shared_group(*m_realm).get_version_of_current_transaction())
{
}

CollectionNotifier::~CollectionNotifier()
{
    // Need to do this explicitly to ensure m_realm is destroyed with the mutex
    // held to avoid potential double-deletion
    unregister();
}

size_t CollectionNotifier::add_callback(CollectionChangeCallback callback)
{
    m_realm->verify_thread();

    auto next_token = [=] {
        size_t token = 0;
        for (auto& callback : m_callbacks) {
            if (token <= callback.token) {
                token = callback.token + 1;
            }
        }
        return token;
    };

    std::lock_guard<std::mutex> lock(m_callback_mutex);
    auto token = next_token();
    m_callbacks.push_back({std::move(callback), token, false});
    if (m_callback_index == npos) { // Don't need to wake up if we're already sending notifications
        Realm::Internal::get_coordinator(*m_realm).send_commit_notifications();
        m_have_callbacks = true;
    }
    return token;
}

void CollectionNotifier::remove_callback(size_t token)
{
    Callback old;
    {
        std::lock_guard<std::mutex> lock(m_callback_mutex);
        REALM_ASSERT(m_error || m_callbacks.size() > 0);

        auto it = find_if(begin(m_callbacks), end(m_callbacks),
                          [=](const auto& c) { return c.token == token; });
        // We should only fail to find the callback if it was removed due to an error
        REALM_ASSERT(m_error || it != end(m_callbacks));
        if (it == end(m_callbacks)) {
            return;
        }

        size_t idx = distance(begin(m_callbacks), it);
        if (m_callback_index != npos && m_callback_index >= idx) {
            --m_callback_index;
        }

        old = std::move(*it);
        m_callbacks.erase(it);

        m_have_callbacks = !m_callbacks.empty();
    }
}

void CollectionNotifier::unregister() noexcept
{
    std::lock_guard<std::mutex> lock(m_realm_mutex);
    m_realm = nullptr;
}

bool CollectionNotifier::is_alive() const noexcept
{
    std::lock_guard<std::mutex> lock(m_realm_mutex);
    return m_realm != nullptr;
}

std::unique_lock<std::mutex> CollectionNotifier::lock_target()
{
    return std::unique_lock<std::mutex>{m_realm_mutex};
}

void CollectionNotifier::set_table(Table const& table)
{
    m_related_tables.clear();
    DeepChangeChecker::find_related_tables(m_related_tables, table);
}

void CollectionNotifier::add_required_change_info(TransactionChangeInfo& info)
{
    if (!do_add_required_change_info(info)) {
        return;
    }

    auto max = max_element(begin(m_related_tables), end(m_related_tables),
                           [](auto&& a, auto&& b) { return a.table_ndx < b.table_ndx; });

    if (max->table_ndx >= info.table_modifications_needed.size())
        info.table_modifications_needed.resize(max->table_ndx + 1, false);
    for (auto& tbl : m_related_tables) {
        info.table_modifications_needed[tbl.table_ndx] = true;
    }
}

void CollectionNotifier::prepare_handover()
{
    REALM_ASSERT(m_sg);
    m_sg_version = m_sg->get_version_of_current_transaction();
    do_prepare_handover(*m_sg);
}

bool CollectionNotifier::deliver(Realm& realm, SharedGroup& sg, std::exception_ptr err)
{
    {
        std::lock_guard<std::mutex> lock(m_realm_mutex);
        if (m_realm.get() != &realm) {
            return false;
        }
    }

    if (err) {
        m_error = err;
        return have_callbacks();
    }

    auto realm_sg_version = sg.get_version_of_current_transaction();
    if (version() != realm_sg_version) {
        // Realm version can be newer if a commit was made on our thread or the
        // user manually called refresh(), or older if a commit was made on a
        // different thread and we ran *really* fast in between the check for
        // if the shared group has changed and when we pick up async results
        return false;
    }

    bool should_call_callbacks = do_deliver(sg);
    m_changes_to_deliver = std::move(m_accumulated_changes);

    // fixup modifications to be source rows rather than dest rows
    // FIXME: the actual change calculations should be updated to just calculate
    // the correct thing instead
    m_changes_to_deliver.modifications.erase_at(m_changes_to_deliver.insertions);
    m_changes_to_deliver.modifications.shift_for_insert_at(m_changes_to_deliver.deletions);

    return should_call_callbacks && have_callbacks();
}

void CollectionNotifier::call_callbacks()
{
    while (auto fn = next_callback()) {
        fn(m_changes_to_deliver, m_error);
    }

    if (m_error) {
        // Remove all the callbacks as we never need to call anything ever again
        // after delivering an error
        std::lock_guard<std::mutex> callback_lock(m_callback_mutex);
        m_callbacks.clear();
    }
}

CollectionChangeCallback CollectionNotifier::next_callback()
{
    std::lock_guard<std::mutex> callback_lock(m_callback_mutex);

    for (++m_callback_index; m_callback_index < m_callbacks.size(); ++m_callback_index) {
        auto& callback = m_callbacks[m_callback_index];
        if (!m_error && callback.initial_delivered && m_changes_to_deliver.empty()) {
            continue;
        }
        callback.initial_delivered = true;
        return callback.fn;
    }

    m_callback_index = npos;
    return nullptr;
}

void CollectionNotifier::attach_to(SharedGroup& sg)
{
    REALM_ASSERT(!m_sg);

    m_sg = &sg;
    do_attach_to(sg);
}

void CollectionNotifier::detach()
{
    REALM_ASSERT(m_sg);
    do_detach_from(*m_sg);
    m_sg = nullptr;
}
