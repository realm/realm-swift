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
#include <memory>
#include <vector>

namespace realm {
namespace _impl {
    class CollectionNotifier;
}

// A token which keeps an asynchronous query alive
struct NotificationToken {
    NotificationToken() = default;
    NotificationToken(std::shared_ptr<_impl::CollectionNotifier> notifier, size_t token);
    ~NotificationToken();

    NotificationToken(NotificationToken&&);
    NotificationToken& operator=(NotificationToken&&);

    NotificationToken(NotificationToken const&) = delete;
    NotificationToken& operator=(NotificationToken const&) = delete;

private:
    util::AtomicSharedPtr<_impl::CollectionNotifier> m_notifier;
    size_t m_token;
};

struct CollectionChangeSet {
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
};

using CollectionChangeCallback = std::function<void (CollectionChangeSet, std::exception_ptr)>;
} // namespace realm

#endif // REALM_COLLECTION_NOTIFICATIONS_HPP
