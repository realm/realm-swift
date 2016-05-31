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

#ifndef REALM_WEAK_REALM_NOTIFIER_BASE_HPP
#define REALM_WEAK_REALM_NOTIFIER_BASE_HPP

#include <memory>
#include <thread>

namespace realm {
class Realm;

namespace _impl {

// WeakRealmNotifierBase stores a weak reference to a Realm instance, along with all of
// the information about a Realm that needs to be accessed from other threads.
// This is needed to avoid forming strong references to the Realm instances on
// other threads, which can produce deadlocks when the last strong reference to
// a Realm instance is released from within a function holding the cache lock.
class WeakRealmNotifierBase {
public:
    WeakRealmNotifierBase(const std::shared_ptr<Realm>& realm, bool cache);

    // Get a strong reference to the cached realm
    std::shared_ptr<Realm> realm() const { return m_realm.lock(); }

    // Does this WeakRealmNotifierBase store a Realm instance that should be used on the current thread?
    bool is_cached_for_current_thread() const { return m_cache && is_for_current_thread(); }

    // Has the Realm instance been destroyed?
    bool expired() const { return m_realm.expired(); }

    // Is this a WeakRealmNotifierBase for the given Realm instance?
    bool is_for_realm(Realm* realm) const { return realm == m_realm_key; }

    bool is_for_current_thread() const { return m_thread_id == std::this_thread::get_id(); }

private:
    std::weak_ptr<Realm> m_realm;
    std::thread::id m_thread_id = std::this_thread::get_id();
    void* m_realm_key;
    bool m_cache = false;
};

inline WeakRealmNotifierBase::WeakRealmNotifierBase(const std::shared_ptr<Realm>& realm, bool cache)
: m_realm(realm)
, m_realm_key(realm.get())
, m_cache(cache)
{
}

} // namespace _impl
} // namespace realm

#endif // REALM_WEAK_REALM_NOTIFIER_BASE_HPP
