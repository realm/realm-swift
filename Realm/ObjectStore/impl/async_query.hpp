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

#ifndef REALM_ASYNC_QUERY_HPP
#define REALM_ASYNC_QUERY_HPP

#include "results.hpp"

#include <realm/group_shared.hpp>

#include <exception>
#include <mutex>
#include <functional>
#include <thread>
#include <vector>

namespace realm {
namespace _impl {
class AsyncQuery {
public:
    AsyncQuery(Results& target);
    ~AsyncQuery();

    size_t add_callback(std::function<void (std::exception_ptr)>);
    void remove_callback(size_t token);

    void unregister() noexcept;
    void release_query() noexcept;

    // Run/rerun the query if needed
    void run();
    // Prepare the handover object if run() did update the TableView
    void prepare_handover();
    // Update the target results from the handover
    // Returns if any callbacks need to be invoked
    bool deliver(SharedGroup& sg, std::exception_ptr err);
    void call_callbacks();

    // Attach the handed-over query to `sg`
    void attach_to(SharedGroup& sg);
    // Create a new query handover object and stop using the previously attached
    // SharedGroup
    void detatch();

    Realm& get_realm() { return m_target_results->get_realm(); }
    // Get the version of the current handover object
    SharedGroup::VersionID version() const noexcept { return m_sg_version; }

    bool is_alive() const noexcept;

private:
    // Target Results to update and a mutex which guards it
    mutable std::mutex m_target_mutex;
    Results* m_target_results;

    std::shared_ptr<Realm> m_realm;
    const SortOrder m_sort;
    const std::thread::id m_thread_id = std::this_thread::get_id();

    // The source Query, in handover form iff m_sg is null
    std::unique_ptr<SharedGroup::Handover<Query>> m_query_handover;
    std::unique_ptr<Query> m_query;

    // The TableView resulting from running the query. Will be detached unless
    // the query was (re)run since the last time the handover object was created
    TableView m_tv;
    std::unique_ptr<SharedGroup::Handover<TableView>> m_tv_handover;
    SharedGroup::VersionID m_sg_version;
    std::exception_ptr m_error;

    struct Callback {
        std::function<void (std::exception_ptr)> fn;
        size_t token;
        uint_fast64_t delivered_version;
    };

    // Currently registered callbacks and a mutex which must always be held
    // while doing anything with them or m_callback_index
    std::mutex m_callback_mutex;
    std::vector<Callback> m_callbacks;

    SharedGroup* m_sg = nullptr;

    uint_fast64_t m_handed_over_table_version = -1;
    uint_fast64_t m_delievered_table_version = -1;

    // Iteration variable for looping over callbacks
    // remove_callback() updates this when needed
    size_t m_callback_index = npos;

    bool m_initial_run_complete = false;

    // Cached value for if m_callbacks is empty, needed to avoid deadlocks in
    // run() due to lock-order inversion between m_callback_mutex and m_target_mutex
    // It's okay if this value is stale as at worst it'll result in us doing
    // some extra work.
    std::atomic<bool> m_have_callbacks = {false};

    bool is_for_current_thread() const { return m_thread_id == std::this_thread::get_id(); }

    std::function<void (std::exception_ptr)> next_callback();
};

} // namespace _impl
} // namespace realm

#endif /* REALM_ASYNC_QUERY_HPP */
