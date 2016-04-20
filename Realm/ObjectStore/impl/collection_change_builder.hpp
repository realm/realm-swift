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

#ifndef REALM_COLLECTION_CHANGE_BUILDER_HPP
#define REALM_COLLECTION_CHANGE_BUILDER_HPP

#include "collection_notifications.hpp"

#include <unordered_map>

namespace realm {
namespace _impl {
class CollectionChangeBuilder : public CollectionChangeSet {
public:
    CollectionChangeBuilder(CollectionChangeBuilder const&) = default;
    CollectionChangeBuilder(CollectionChangeBuilder&&) = default;
    CollectionChangeBuilder& operator=(CollectionChangeBuilder const&) = default;
    CollectionChangeBuilder& operator=(CollectionChangeBuilder&&) = default;

    CollectionChangeBuilder(IndexSet deletions = {},
                            IndexSet insertions = {},
                            IndexSet modification = {},
                            std::vector<Move> moves = {});

    // Calculate where rows need to be inserted or deleted from old_rows to turn
    // it into new_rows, and check all matching rows for modifications
    static CollectionChangeBuilder calculate(std::vector<size_t> const& old_rows,
                                             std::vector<size_t> const& new_rows,
                                             std::function<bool (size_t)> row_did_change,
                                             bool sort);

    void merge(CollectionChangeBuilder&&);
    void clean_up_stale_moves();

    void insert(size_t ndx, size_t count=1, bool track_moves=true);
    void modify(size_t ndx);
    void erase(size_t ndx);
    void move_over(size_t ndx, size_t last_ndx, bool track_moves=true);
    void clear(size_t old_size);
    void move(size_t from, size_t to);

    void parse_complete();

private:
    std::unordered_map<size_t, size_t> m_move_mapping;

    void verify();
};
} // namespace _impl
} // namespace realm

#endif // REALM_COLLECTION_CHANGE_BUILDER_HPP
