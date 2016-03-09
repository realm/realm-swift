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

#ifndef REALM_COLLECTION_NOTIFICATIONS_HPP
#define REALM_COLLECTION_NOTIFICATIONS_HPP

#include "index_set.hpp"
#include "util/atomic_shared_ptr.hpp"

#include <exception>
#include <functional>

namespace realm {
namespace _impl {
    class BackgroundCollection;
}

// A token which keeps an asynchronous query alive
struct NotificationToken {
    NotificationToken() = default;
    NotificationToken(std::shared_ptr<_impl::BackgroundCollection> query, size_t token);
    ~NotificationToken();

    NotificationToken(NotificationToken&&);
    NotificationToken& operator=(NotificationToken&&);

    NotificationToken(NotificationToken const&) = delete;
    NotificationToken& operator=(NotificationToken const&) = delete;

private:
    util::AtomicSharedPtr<_impl::BackgroundCollection> m_query;
    size_t m_token;
};

struct CollectionChangeIndices {
    struct Move {
        size_t from;
        size_t to;

        bool operator==(Move m) const { return from == m.from && to == m.to; }
    };

    IndexSet deletions;
    IndexSet insertions;
    IndexSet modifications;
    std::vector<Move> moves;

    bool empty() const { return deletions.empty() && insertions.empty() && modifications.empty() && moves.empty(); }

    CollectionChangeIndices(CollectionChangeIndices const&) = default;
    CollectionChangeIndices(CollectionChangeIndices&&) = default;
    CollectionChangeIndices& operator=(CollectionChangeIndices const&) = default;
    CollectionChangeIndices& operator=(CollectionChangeIndices&&) = default;

    CollectionChangeIndices(IndexSet deletions = {},
                            IndexSet insertions = {},
                            IndexSet modification = {},
                            std::vector<Move> moves = {});
};

using CollectionChangeCallback = std::function<void (CollectionChangeIndices, std::exception_ptr)>;

namespace _impl {
class CollectionChangeBuilder : public CollectionChangeIndices {
public:
    using CollectionChangeIndices::CollectionChangeIndices;

    static CollectionChangeBuilder calculate(std::vector<size_t> const& old_rows,
                                             std::vector<size_t> const& new_rows,
                                             std::function<bool (size_t)> row_did_change,
                                             bool sort);

    void merge(CollectionChangeBuilder&&);

    void insert(size_t ndx, size_t count=1);
    void modify(size_t ndx);
    void erase(size_t ndx);
    void move_over(size_t ndx, size_t last_ndx);
    void clear(size_t old_size);
    void move(size_t from, size_t to);

private:
    void verify();
};
} // namespace _impl
} // namespace realm

#endif // REALM_COLLECTION_NOTIFICATIONS_HPP
