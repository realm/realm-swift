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

#ifndef REALM_CACHED_REALM_HPP
#define REALM_CACHED_REALM_HPP

#include <CoreFoundation/CFRunLoop.h>
#include <memory>
#include <thread>

namespace realm {
class Realm;

namespace _impl {

class CachedRealm {
public:
    CachedRealm(const std::shared_ptr<Realm>& realm, bool cache);
    ~CachedRealm();

    CachedRealm(CachedRealm&&);
    CachedRealm& operator=(CachedRealm&&);

    CachedRealm(const CachedRealm&) = delete;
    CachedRealm& operator=(const CachedRealm&) = delete;

    // Get a strong reference to the cached realm
    std::shared_ptr<Realm> realm() const { return m_realm.lock(); }

    // Does this CachedRealm store a Realm instance that should be used on the current thread?
    bool is_cached_for_current_thread() const { return m_cache && m_thread_id == std::this_thread::get_id(); }

    bool expired() const { return m_realm.expired(); }

    // Asyncronously call notify() on the Realm on the appropriate thread
    void notify();

private:
    std::weak_ptr<Realm> m_realm;
    std::thread::id m_thread_id = std::this_thread::get_id();
    bool m_cache = false;

    CFRunLoopRef m_runloop;
    CFRunLoopSourceRef m_signal;
};

} // namespace _impl
} // namespace realm

#endif // REALM_CACHED_REALM_HPP
