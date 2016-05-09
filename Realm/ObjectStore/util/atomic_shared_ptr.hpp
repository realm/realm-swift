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

#ifndef REALM_ATOMIC_SHARED_PTR_HPP
#define REALM_ATOMIC_SHARED_PTR_HPP

#include <atomic>
#include <memory>
#include <mutex>

namespace realm {
namespace _impl {

// Check if std::atomic_load has an overload taking a std::shared_ptr, and set
// HasAtomicPtrOps to either true_type or false_type

template<typename... Ts> struct make_void { typedef void type; };
template<typename... Ts> using void_t = typename make_void<Ts...>::type;

template<typename, typename = void_t<>>
struct HasAtomicPtrOps : std::false_type { };

template<class T>
struct HasAtomicPtrOps<T, void_t<decltype(std::atomic_load(std::declval<T*>()))>> : std::true_type { };
} // namespace _impl

namespace util {
// A wrapper for std::shared_ptr that enables sharing a shared_ptr instance
// (and not just a thing *pointed to* by a shared_ptr) between threads. Is
// lock-free iff the underlying shared_ptr implementation supports atomic
// operations. Currently the only implemented operation other than copy/move
// construction/assignment is exchange().
template<typename T, bool = _impl::HasAtomicPtrOps<std::shared_ptr<T>>::value>
class AtomicSharedPtr;

template<typename T>
class AtomicSharedPtr<T, true> {
public:
    AtomicSharedPtr() = default;
    AtomicSharedPtr(std::shared_ptr<T> ptr) : m_ptr(std::move(ptr)) { }

    AtomicSharedPtr(AtomicSharedPtr const& ptr) : m_ptr(std::atomic_load(&ptr.m_ptr)) { }
    AtomicSharedPtr(AtomicSharedPtr&& ptr) : m_ptr(std::atomic_exchange(&ptr.m_ptr, {})) { }

    AtomicSharedPtr& operator=(AtomicSharedPtr const& ptr)
    {
        if (&ptr != this) {
            std::atomic_store(&m_ptr, std::atomic_load(&ptr.m_ptr));
        }
        return *this;
    }

    AtomicSharedPtr& operator=(AtomicSharedPtr&& ptr)
    {
        std::atomic_store(&m_ptr, std::atomic_exchange(&ptr.m_ptr, {}));
        return *this;
    }

    std::shared_ptr<T> exchange(std::shared_ptr<T> ptr)
    {
        return std::atomic_exchange(&m_ptr, std::move(ptr));
    }

private:
    std::shared_ptr<T> m_ptr = nullptr;
};

template<typename T>
class AtomicSharedPtr<T, false> {
public:
    AtomicSharedPtr() = default;
    AtomicSharedPtr(std::shared_ptr<T> ptr) : m_ptr(std::move(ptr)) { }

    AtomicSharedPtr(AtomicSharedPtr const& ptr)
    {
        std::lock_guard<std::mutex> lock(ptr.m_mutex);
        m_ptr = ptr.m_ptr;
    }
    AtomicSharedPtr(AtomicSharedPtr&& ptr)
    {
        std::lock_guard<std::mutex> lock(ptr.m_mutex);
        m_ptr = std::move(ptr.m_ptr);
    }

    AtomicSharedPtr& operator=(AtomicSharedPtr const& ptr)
    {
        if (&ptr != this) {
            // std::lock() ensures that these are locked in a consistent order
            // to avoid deadlock
            std::lock(m_mutex, ptr.m_mutex);
            m_ptr = ptr.m_ptr;
            m_mutex.unlock();
            ptr.m_mutex.unlock();
        }
        return *this;
    }

    AtomicSharedPtr& operator=(AtomicSharedPtr&& ptr)
    {
        std::lock(m_mutex, ptr.m_mutex);
        m_ptr = std::move(ptr.m_ptr);
        m_mutex.unlock();
        ptr.m_mutex.unlock();
        return *this;
    }

    std::shared_ptr<T> exchange(std::shared_ptr<T> ptr)
    {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_ptr.swap(ptr);
        return ptr;
    }

private:
    std::mutex m_mutex;
    std::shared_ptr<T> m_ptr = nullptr;
};

}
}

#endif // REALM_ASYNC_QUERY_HPP
