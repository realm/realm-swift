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

#include <functional>

namespace realm {
namespace _impl {
class AsyncQuery : public std::enable_shared_from_this<AsyncQuery> {
public:
    AsyncQuery(SortOrder sort,
               std::unique_ptr<SharedGroup::Handover<Query>> handover,
               std::unique_ptr<AsyncQueryCallback> callback,
               RealmCoordinator& parent);

    void get_results(const SharedRealm& realm, SharedGroup& sg, std::vector<std::function<void()>>& ret);

    void update();
    void set_error(std::exception_ptr err);

    SharedGroup::VersionID version() const noexcept;

    void attach_to(SharedGroup& sg);
    void detatch();

    std::shared_ptr<RealmCoordinator> parent;

private:
    const SortOrder m_sort;

    std::unique_ptr<SharedGroup::Handover<Query>> m_query_handover;
    std::unique_ptr<Query> m_query;

    std::unique_ptr<SharedGroup::Handover<TableView>> m_tv_handover;
    TableView m_tv;

    const std::unique_ptr<AsyncQueryCallback> m_callback;

    SharedGroup* m_sg = nullptr;

    std::exception_ptr m_error;
};

} // namespace _impl
} // namespace realm

#endif /* REALM_ASYNC_QUERY_HPP */
