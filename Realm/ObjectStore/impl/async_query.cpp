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

#include "async_query.hpp"

#include "realm_coordinator.hpp"
#include "results.hpp"

using namespace realm;
using namespace realm::_impl;

AsyncQuery::AsyncQuery(Results& target)
: m_target_results(&target)
, m_realm(target.get_realm().shared_from_this())
, m_sort(target.get_sort())
, m_sg_version(Realm::Internal::get_shared_group(*m_realm).get_version_of_current_transaction())
{
    Query q = target.get_query();
    m_query_handover = Realm::Internal::get_shared_group(*m_realm).export_for_handover(q, MutableSourcePayload::Move);
}

AsyncQueryCancelationToken AsyncQuery::add_callback(std::function<void (std::exception_ptr)> callback)
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

    if (m_calling_callbacks) {
        // We're being called from within a callback block, so add without
        // locking or faking a commit
        auto token = next_token();
        m_callbacks.push_back({std::move(callback), token, -1ULL});
        return {*this, token};
    }

    std::lock_guard<std::mutex> lock(m_callback_mutex);
    auto token = next_token();
    m_callbacks.push_back({std::move(callback), token, -1ULL});
    Realm::Internal::get_coordinator(*m_realm).send_commit_notifications();
    m_have_callbacks = true;
    return {*this, token};
}

void AsyncQuery::remove_callback(size_t token)
{
    if (is_for_current_thread() &&  m_calling_callbacks) {
        // Schedule the removal for after we're done calling callbacks
        // No need for a lock here because we're on the same thread as the one
        // holding the lock
        m_callbacks_to_remove.push_back(token);
        return;
    }

    std::lock_guard<std::mutex> lock(m_callback_mutex);
    do_remove_callback(token);
}

void AsyncQuery::do_remove_callback(size_t token) noexcept
{
    REALM_ASSERT(m_error || m_callbacks.size() > 0);
    auto it = find_if(begin(m_callbacks), end(m_callbacks),
                      [=](const auto& c) { return c.token == token; });
    // We should only fail to find the callback if it was removed due to an error
    REALM_ASSERT(m_error || it != end(m_callbacks));

    if (it != end(m_callbacks)) {
        if (it != prev(end(m_callbacks))) {
            *it = std::move(m_callbacks.back());
        }
        m_callbacks.pop_back();
    }
    m_have_callbacks = !m_callbacks.empty();
}

void AsyncQuery::unregister() noexcept
{
    RealmCoordinator::unregister_query(*this);

    std::lock_guard<std::mutex> lock(m_target_mutex);
    m_target_results = nullptr;
    m_realm = nullptr;
}

void AsyncQuery::run()
{
    REALM_ASSERT(m_sg);

    {
        std::lock_guard<std::mutex> target_lock(m_target_mutex);
        // Don't run the query if the results aren't actually going to be used
        if (!m_target_results || (!m_have_callbacks && !m_target_results->wants_background_updates())) {
            m_skipped_running = true;
            return;
        }
    }
    m_skipped_running = false;

    // This function must not touch any members touched in deliver(), as they
    // may be called concurrently (as it'd be pretty bad for a running query to
    // block the main thread trying to pick up the previous results)
    if (m_tv.is_attached()) {
        m_tv.sync_if_needed();
    }
    else {
        m_tv = m_query->find_all();
        m_query = nullptr;
        if (m_sort) {
            m_tv.sort(m_sort.columnIndices, m_sort.ascending);
        }
    }
}

void AsyncQuery::prepare_handover()
{
    if (m_skipped_running) {
        m_sg_version = SharedGroup::VersionID{};
        return;
    }

    REALM_ASSERT(m_tv.is_attached());
    REALM_ASSERT(m_tv.is_in_sync());

    m_sg_version = m_sg->get_version_of_current_transaction();
    m_initial_run_complete = true;

    auto table_version = m_tv.outside_version();
    if (!m_tv_handover && table_version == m_handed_over_table_version) {
        // We've already delivered the query results since the last time the
        // table changed, so no need to do anything
        return;
    }

    m_tv_handover = m_sg->export_for_handover(m_tv, ConstSourcePayload::Copy);
    m_handed_over_table_version = table_version;
}

bool AsyncQuery::deliver(SharedGroup& sg, std::exception_ptr err)
{
    if (!is_for_current_thread()) {
        return false;
    }

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
    if (!m_initial_run_complete && !err) {
        return false;
    }

    if (err) {
        m_error = err;
        return m_have_callbacks;
    }

    REALM_ASSERT(!m_query_handover);

    auto realm_sg_version = Realm::Internal::get_shared_group(*m_realm).get_version_of_current_transaction();
    if (m_sg_version != realm_sg_version) {
        // Realm version can be newer if a commit was made on our thread or the
        // user manually called refresh(), or older if a commit was made on a
        // different thread and we ran *really* fast in between the check for
        // if the shared group has changed and when we pick up async results
        return false;
    }

    if (m_tv_handover) {
        Results::AsyncFriend::set_table_view(*m_target_results,
                                             std::move(*sg.import_from_handover(std::move(m_tv_handover))));
        m_delievered_table_version = m_handed_over_table_version;

    }
    REALM_ASSERT(!m_tv_handover);
    return m_have_callbacks;
}

void AsyncQuery::call_callbacks()
{
    REALM_ASSERT(is_for_current_thread());
    std::lock_guard<std::mutex> callback_lock(m_callback_mutex);

    // Tell remove_callback() to defer actually removing them, so that calling it
    // in the callback block works
    m_calling_callbacks = true;

    if (m_error) {
        for (auto& callback : m_callbacks) {
            callback.fn(m_error);
        }

        // Remove all the callbacks as we never need to call anything ever again
        // after delivering an error
        m_callbacks.clear();
        m_callbacks_to_remove.clear();
        m_calling_callbacks = false;
        return;
    }

    // Iterate by index to handle users adding callbacks during iteration
    for (size_t i = 0; i < m_callbacks.size(); ++i) {
        auto& callback = m_callbacks[i];
        // Skip callbacks stopped from within previous callback blocks
        if (find(begin(m_callbacks_to_remove), end(m_callbacks_to_remove), callback.token) != end(m_callbacks_to_remove)) {
            continue;
        }
        if (callback.delivered_version != m_delievered_table_version) {
            callback.delivered_version = m_delievered_table_version;
            // warning: `callback` is invalidated after this call, as the
            /// referenced object could move if the user adds a new callback
            callback.fn(nullptr);
        }
    }

    m_calling_callbacks = false;

    // Actually remove any callbacks whose removal was requested during iteration
    for (auto token : m_callbacks_to_remove) {
        do_remove_callback(token);
    }
    m_callbacks_to_remove.clear();
}

void AsyncQuery::attach_to(realm::SharedGroup& sg)
{
    REALM_ASSERT(!m_sg);
    REALM_ASSERT(m_query_handover);

    m_query = sg.import_from_handover(std::move(m_query_handover));
    m_sg = &sg;
}

void AsyncQuery::detatch()
{
    REALM_ASSERT(m_sg);
    REALM_ASSERT(m_query);
    REALM_ASSERT(!m_tv.is_attached());

    m_query_handover = m_sg->export_for_handover(*m_query, MutableSourcePayload::Move);
    m_sg = nullptr;
    m_query = nullptr;
}
