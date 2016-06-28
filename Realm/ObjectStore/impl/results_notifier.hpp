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

#ifndef REALM_RESULTS_NOTIFIER_HPP
#define REALM_RESULTS_NOTIFIER_HPP

#include "collection_notifier.hpp"
#include "results.hpp"

#include <realm/group_shared.hpp>

namespace realm {
namespace _impl {
class ResultsNotifier : public CollectionNotifier {
public:
    ResultsNotifier(Results& target);

    void target_results_moved(Results& old_target, Results& new_target);

private:
    // Target Results to update
    // Can only be used with lock_target() held
    Results* m_target_results;

    const SortOrder m_sort;
    bool m_target_is_in_table_order;

    // The source Query, in handover form iff m_sg is null
    std::unique_ptr<SharedGroup::Handover<Query>> m_query_handover;
    std::unique_ptr<Query> m_query;

    // The TableView resulting from running the query. Will be detached unless
    // the query was (re)run since the last time the handover object was created
    TableView m_tv;
    std::unique_ptr<SharedGroup::Handover<TableView>> m_tv_handover;

    // The table version from the last time the query was run. Used to avoid
    // rerunning the query when there's no chance of it changing.
    uint_fast64_t m_last_seen_version = -1;

    // The rows from the previous run of the query, for calculating diffs
    std::vector<size_t> m_previous_rows;

    // The changeset calculated during run() and delivered in do_prepare_handover()
    CollectionChangeBuilder m_changes;
    TransactionChangeInfo* m_info = nullptr;

    // Flag for whether or not the query has been run at all, as goofy timing
    // can lead to deliver() being called before that
    bool m_initial_run_complete = false;

    bool need_to_run();
    void calculate_changes();

    void run() override;
    void do_prepare_handover(SharedGroup&) override;
    bool do_deliver(SharedGroup& sg) override;
    bool do_add_required_change_info(TransactionChangeInfo& info) override;

    void release_data() noexcept override;
    void do_attach_to(SharedGroup& sg) override;
    void do_detach_from(SharedGroup& sg) override;
};

} // namespace _impl
} // namespace realm

#endif /* REALM_RESULTS_NOTIFIER_HPP */
