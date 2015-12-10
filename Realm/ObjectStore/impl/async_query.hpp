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

    AsyncQueryCancelationToken add_callback(std::function<void (std::exception_ptr)>);
    void remove_callback(size_t token);

    void unregister() noexcept;

    // Run/rerun the query if needed
    void run();
    // Prepare the handover object if run() did update the TableView
    void prepare_handover();
    // Update the target results from the handover and call callbacks
    void deliver(SharedGroup& sg, std::exception_ptr err);

    // Attach the handed-over query to `sg`
    void attach_to(SharedGroup& sg);
    // Create a new query handover object and stop using the previously attached
    // SharedGroup
    void detatch();

    Realm& get_realm() { return m_target_results->get_realm(); }
    // Get the version of the current handover object
    SharedGroup::VersionID version() const noexcept { return m_version; }

private:
    // Target Results to update and a mutex which guards it
    std::mutex m_target_mutex;
    Results* m_target_results;

    std::shared_ptr<Realm> m_realm;
    const SortOrder m_sort;
    const std::thread::id m_thread_id = std::this_thread::get_id();

    // The source Query, in handover from iff m_sg is null
    // Only used until the first time the query is actually run, after which
    // both will be null
    std::unique_ptr<SharedGroup::Handover<Query>> m_query_handover;
    std::unique_ptr<Query> m_query;

    // The TableView resulting from running the query. Will be detached if the
    // Query has not yet been run, in which case m_query or m_query_handover will
    // be non-null
    TableView m_tv;
    std::unique_ptr<SharedGroup::Handover<TableView>> m_tv_handover;
    SharedGroup::VersionID m_version;

    struct Callback {
        std::function<void (std::exception_ptr)> fn;
        std::unique_ptr<SharedGroup::Handover<TableView>> handover;
        size_t token;
        uint_fast64_t delivered_version;
    };

    // Currently registered callbacks and a mutex which must always be held
    // while doing anything with them
    std::mutex m_callback_mutex;
    std::vector<Callback> m_callbacks;

    // Callbacks which the user has asked to have removed whose removal has been
    // deferred until after we're done looping over m_callbacks
    std::vector<size_t> m_callbacks_to_remove;

    SharedGroup* m_sg = nullptr;

    uint_fast64_t m_tv_version = -1;
    uint_fast64_t m_next_tv_version = -1;

    bool m_skipped_running = false;
    bool m_initial_run_complete = false;
    bool m_calling_callbacks = false;
    bool m_error = false;

    void do_remove_callback(size_t token) noexcept;

    bool is_for_current_thread() const { return m_thread_id == std::this_thread::get_id(); }
};

} // namespace _impl
} // namespace realm

#endif /* REALM_ASYNC_QUERY_HPP */
