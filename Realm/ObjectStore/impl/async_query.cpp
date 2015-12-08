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
, m_version(m_realm->m_shared_group->get_version_of_current_transaction())
{
    Query q = target.get_query();
    m_query_handover = m_realm->m_shared_group->export_for_handover(q, MutableSourcePayload::Move);
}

AsyncQueryCancelationToken AsyncQuery::add_callback(std::function<void (std::exception_ptr)> callback)
{
    std::lock_guard<std::mutex> lock(m_callback_mutex);

    size_t token = 0;
    for (auto& callback : m_callbacks) {
        if (token <= callback.token) {
            token = callback.token + 1;
        }
    }

    m_callbacks.push_back({std::move(callback), nullptr, token, true});
    m_realm->m_coordinator->send_commit_notifications();
    return {*this, token};
}

void AsyncQuery::remove_callback(size_t token)
{
    std::lock_guard<std::mutex> lock(m_callback_mutex);
    if (is_for_current_thread() &&  m_calling_callbacks) {
        // Schedule the removal for after we're done calling callbacks
        m_callbacks_to_remove.push_back(token);
        return;
    }
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
}

void AsyncQuery::unregister() noexcept
{
    std::lock_guard<std::mutex> lock(m_target_mutex);
    RealmCoordinator::unregister_query(*this);
    m_target_results = nullptr;
    m_realm = nullptr;
}

void AsyncQuery::run()
{
    // This function must not touch any members touched in deliver(), as they
    // may be called concurrently (as it'd be pretty bad for a running query to
    // block the main thread trying to pick up the previous results)

    REALM_ASSERT(m_sg);

    if (m_tv.is_attached()) {
        m_did_update = m_tv.sync_if_needed();
    }
    else {
        m_tv = m_query->find_all();
        m_query = nullptr;
        if (m_sort) {
            m_tv.sort(m_sort.columnIndices, m_sort.ascending);
        }
        m_did_update = true;
    }
}

void AsyncQuery::prepare_handover()
{
    std::lock_guard<std::mutex> lock(m_callback_mutex);

    REALM_ASSERT(m_tv.is_in_sync());

    m_version = m_sg->get_version_of_current_transaction();
    m_initial_run_complete = true;

    // Even if the TV didn't change, we need to re-export it if the previous
    // export has not been consumed yet, as the old handover object is no longer
    // usable due to the version not matching
    if (m_did_update || (m_tv_handover && m_tv_handover->version != m_version)) {
        m_tv_handover = m_sg->export_for_handover(m_tv, ConstSourcePayload::Copy);
    }
}

void AsyncQuery::deliver(SharedGroup& sg, std::exception_ptr err)
{
    if (!is_for_current_thread()) {
        return;
    }

    std::lock_guard<std::mutex> callback_lock(m_callback_mutex);
    std::lock_guard<std::mutex> target_lock(m_target_mutex);

    // Target results being null here indicates that it was destroyed while we
    // were in the process of advancing the Realm version and preparing for
    // delivery, i.e. it was destroyed from the "wrong" thread
    if (!m_target_results) {
        return;
    }

    // We can get called before the query has actually had the chance to run if
    // we're added immediately before a different set of async results are
    // delivered
    if (!m_initial_run_complete && !err) {
        return;
    }

    // Tell remove_callback() to defer actually removing them, so that calling it
    // in the callback block works
    m_calling_callbacks = true;

    if (err) {
        m_error = true;
        for (auto& callback : m_callbacks) {
            callback.fn(err);
        }

        // Remove all the callbacks as we never need to call anything ever again
        // after delivering an error
        m_callbacks.clear();
        m_callbacks_to_remove.clear();
        m_calling_callbacks = false;
        return;
    }

    REALM_ASSERT(!m_query_handover);

    auto realm_version = m_realm->m_shared_group->get_version_of_current_transaction();
    if (m_version != realm_version) {
        // Realm version can be newer if a commit was made on our thread or the
        // user manually called refresh(), or older if a commit was made on a
        // different thread and we ran *really* fast in between the check for
        // if the shared group has changed and when we pick up async results
        return;
    }

    // Cannot use m_did_update here as it is used unlocked in run()
    bool did_update = false;
    if (m_tv_handover) {
        Results::AsyncFriend::set_table_view(*m_target_results,
                                             std::move(*sg.import_from_handover(std::move(m_tv_handover))));

        did_update = true;
    }
    REALM_ASSERT(!m_tv_handover);

    for (auto& callback : m_callbacks) {
        if (did_update || callback.first_run) {
            callback.fn(nullptr);
            callback.first_run = false;
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
