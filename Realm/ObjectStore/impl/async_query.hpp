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

#include "background_collection.hpp"
#include "results.hpp"

#include <realm/group_shared.hpp>

#include <exception>
#include <mutex>
#include <functional>
#include <set>
#include <thread>
#include <vector>

namespace realm {
namespace _impl {
struct TransactionChangeInfo;

class AsyncQuery : public BackgroundCollection {
public:
    AsyncQuery(Results& target);

private:
    // Run/rerun the query if needed
    void run() override;
    // Prepare the handover object if run() did update the TableView
    bool do_prepare_handover(SharedGroup&) override;
    // Update the target results from the handover
    // Returns if any callbacks need to be invoked
    bool do_deliver(SharedGroup& sg) override;

    void do_add_required_change_info(TransactionChangeInfo& info) override;

    void release_data() noexcept override;
    void do_attach_to(SharedGroup& sg) override;
    void do_detach_from(SharedGroup& sg) override;

    // Target Results to update and a mutex which guards it
    mutable std::mutex m_target_mutex;
    Results* m_target_results;

    const SortOrder m_sort;

    // The source Query, in handover form iff m_sg is null
    std::unique_ptr<SharedGroup::Handover<Query>> m_query_handover;
    std::unique_ptr<Query> m_query;

    // The TableView resulting from running the query. Will be detached unless
    // the query was (re)run since the last time the handover object was created
    TableView m_tv;
    std::unique_ptr<SharedGroup::Handover<TableView>> m_tv_handover;

    CollectionChangeIndices m_changes;
    TransactionChangeInfo* m_info = nullptr;

    uint_fast64_t m_handed_over_table_version = -1;
    bool m_did_change = false;

    std::vector<size_t> m_previous_rows;

    bool m_initial_run_complete = false;
};

} // namespace _impl
} // namespace realm

#endif /* REALM_ASYNC_QUERY_HPP */
