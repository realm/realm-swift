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

bool TransactionChangeInfo::row_did_change(Table const& table, size_t idx, int depth) const
{
    if (depth > 16)  // arbitrary limit
        return false;

    size_t table_ndx = table.get_index_in_group();
    if (table_ndx < tables.size() && tables[table_ndx].modifications.contains(idx))
        return true;

    for (size_t i = 0, count = table.get_column_count(); i < count; ++i) {
        auto type = table.get_column_type(i);
        if (type == type_Link) {
            if (table.is_null_link(i, idx))
                continue;
            auto dst = table.get_link(i, idx);
            return row_did_change(*table.get_link_target(i), dst, depth + 1);
        }
        if (type != type_LinkList)
            continue;

        auto& target = *table.get_link_target(i);
        auto lvr = table.get_linklist(i, idx);
        for (size_t j = 0; j < lvr->size(); ++j) {
            size_t dst = lvr->get(j).get_index();
            if (row_did_change(target, dst, depth + 1))
                return true;
        }
    }

    return false;
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

// Recursively add `table` and all tables it links to to `out`
static void find_relevant_tables(std::vector<size_t>& out, Table const& table)
{
    auto table_ndx = table.get_index_in_group();
    if (find(begin(out), end(out), table_ndx) != end(out))
        return;
    out.push_back(table_ndx);

    for (size_t i = 0, count = table.get_column_count(); i != count; ++i) {
        if (table.get_column_type(i) == type_Link || table.get_column_type(i) == type_LinkList) {
            find_relevant_tables(out, *table.get_link_target(i));
        }
    }
}

void CollectionNotifier::set_table(Table const& table)
{
    find_relevant_tables(m_relevant_tables, table);
}

void CollectionNotifier::add_required_change_info(TransactionChangeInfo& info)
{
    if (!do_add_required_change_info(info)) {
        return;
    }

    auto max = *max_element(begin(m_relevant_tables), end(m_relevant_tables)) + 1;
    if (max > info.table_modifications_needed.size())
        info.table_modifications_needed.resize(max, false);
    for (auto table_ndx : m_relevant_tables) {
        info.table_modifications_needed[table_ndx] = true;
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
