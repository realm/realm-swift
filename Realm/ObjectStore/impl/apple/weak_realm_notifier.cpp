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

#include "impl/weak_realm_notifier.hpp"

#include "shared_realm.hpp"

#include <atomic>

using namespace realm;
using namespace realm::_impl;

WeakRealmNotifier::WeakRealmNotifier(const std::shared_ptr<Realm>& realm, bool cache)
: WeakRealmNotifierBase(realm, cache)
{
    struct RefCountedWeakPointer {
        std::weak_ptr<Realm> realm;
        std::atomic<size_t> ref_count;
    };

    CFRunLoopSourceContext ctx{};
    ctx.info = new RefCountedWeakPointer{realm, {0}};
    ctx.perform = [](void* info) {
        if (auto realm = static_cast<RefCountedWeakPointer*>(info)->realm.lock()) {
            realm->notify();
        }
    };
    ctx.retain = [](const void* info) {
        static_cast<RefCountedWeakPointer*>(const_cast<void*>(info))->ref_count.fetch_add(1, std::memory_order_relaxed);
        return info;
    };
    ctx.release = [](const void* info) {
        auto ptr = static_cast<RefCountedWeakPointer*>(const_cast<void*>(info));
        if (ptr->ref_count.fetch_add(-1, std::memory_order_acq_rel) == 1) {
            delete ptr;
        }
    };

    m_runloop = CFRunLoopGetCurrent();
    CFRetain(m_runloop);
    m_signal = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &ctx);
    CFRunLoopAddSource(m_runloop, m_signal, kCFRunLoopDefaultMode);
}

WeakRealmNotifier::WeakRealmNotifier(WeakRealmNotifier&& rgt)
: WeakRealmNotifierBase(std::move(rgt))
, m_runloop(rgt.m_runloop)
, m_signal(rgt.m_signal)
{
    rgt.m_runloop = nullptr;
    rgt.m_signal = nullptr;
}

WeakRealmNotifier& WeakRealmNotifier::operator=(WeakRealmNotifier&& rgt)
{
    WeakRealmNotifierBase::operator=(std::move(rgt));

    invalidate();
    m_runloop = rgt.m_runloop;
    m_signal = rgt.m_signal;
    rgt.m_runloop = nullptr;
    rgt.m_signal = nullptr;

    return *this;
}

WeakRealmNotifier::~WeakRealmNotifier()
{
    invalidate();
}

void WeakRealmNotifier::invalidate()
{
    if (m_signal) {
        CFRunLoopSourceInvalidate(m_signal);
        CFRelease(m_signal);
        CFRelease(m_runloop);
    }
}

void WeakRealmNotifier::notify()
{
    CFRunLoopSourceSignal(m_signal);
    // Signalling the source makes it run the next time the runloop gets
    // to it, but doesn't make the runloop start if it's currently idle
    // waiting for events
    CFRunLoopWakeUp(m_runloop);
}
