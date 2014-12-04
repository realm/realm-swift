/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2012] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/
#ifndef TIGHTDB_UTIL_THREAD_HPP
#define TIGHTDB_UTIL_THREAD_HPP

#include <exception>

#include <pthread.h>

// Use below line to enable a thread bug detection tool. Note: Will make program execution slower.
// #include <../test/pthread_test.hpp>

#include <errno.h>
#include <cstddef>

#include <tightdb/util/features.h>
#include <tightdb/util/assert.hpp>
#include <tightdb/util/terminate.hpp>
#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/util/meta.hpp>

#ifdef TIGHTDB_HAVE_CXX11_ATOMIC
#  include <atomic>
#endif


namespace tightdb {
namespace util {


/// A separate thread of execution.
///
/// This class is a C++03 compatible reproduction of a subset of
/// std::thread from C++11 (when discounting Thread::start()).
class Thread {
public:
    Thread();
    ~Thread() TIGHTDB_NOEXCEPT;

    template<class F> explicit Thread(F func);

    /// This method is an extension of the API provided by
    /// std::thread. This method exists because proper move semantics
    /// is unavailable in C++03. If move semantics had been available,
    /// calling `start(func)` would have been equivalent to `*this =
    /// Thread(func)`. Please see std::thread::operator=() for
    /// details.
    template<class F> void start(F func);

    bool joinable() TIGHTDB_NOEXCEPT;

    void join();

private:
    pthread_t m_id;
    bool m_joinable;

    typedef void* (*entry_func_type)(void*);

    void start(entry_func_type, void* arg);

    template<class> static void* entry_point(void*) TIGHTDB_NOEXCEPT;

    TIGHTDB_NORETURN static void create_failed(int);
    TIGHTDB_NORETURN static void join_failed(int);
};


/// Low-level mutual exclusion device.
class Mutex {
public:
    Mutex();
    ~Mutex() TIGHTDB_NOEXCEPT;

    struct process_shared_tag {};

    /// Initialize this mutex for use across multiple processes. When
    /// constructed this way, the instance may be placed in memory
    /// shared by multiple processes, as well as in a memory mapped
    /// file. Such a mutex remains valid even after the constructing
    /// process terminates. Deleting the instance (freeing the memory
    /// or deleting the file) without first calling the destructor is
    /// legal and will not cause any system resources to be leaked.
    Mutex(process_shared_tag);

    friend class LockGuard;
    friend class UniqueLock;

protected:
    pthread_mutex_t m_impl;

    struct no_init_tag {};
    Mutex(no_init_tag) {}

    void init_as_regular();
    void init_as_process_shared(bool robust_if_available);

    void lock() TIGHTDB_NOEXCEPT;
    void unlock() TIGHTDB_NOEXCEPT;

    TIGHTDB_NORETURN static void init_failed(int);
    TIGHTDB_NORETURN static void attr_init_failed(int);
    TIGHTDB_NORETURN static void destroy_failed(int) TIGHTDB_NOEXCEPT;
    TIGHTDB_NORETURN static void lock_failed(int) TIGHTDB_NOEXCEPT;

    friend class CondVar;
};


/// A simple mutex ownership wrapper.
class LockGuard {
public:
    LockGuard(Mutex&) TIGHTDB_NOEXCEPT;
    ~LockGuard() TIGHTDB_NOEXCEPT;

private:
    Mutex& m_mutex;
    friend class CondVar;
};


/// See UniqueLock.
struct defer_lock_tag {};

/// A general-purpose mutex ownership wrapper supporting deferred
/// locking as well as repeated unlocking and relocking.
class UniqueLock {
public:
    UniqueLock(Mutex&) TIGHTDB_NOEXCEPT;
    UniqueLock(Mutex&, defer_lock_tag) TIGHTDB_NOEXCEPT;
    ~UniqueLock() TIGHTDB_NOEXCEPT;

    void lock() TIGHTDB_NOEXCEPT;
    void unlock() TIGHTDB_NOEXCEPT;

private:
    Mutex* m_mutex;
    bool m_is_locked;
};


/// A robust version of a process-shared mutex.
///
/// A robust mutex is one that detects whether a thread (or process)
/// has died while holding a lock on the mutex.
///
/// When the present platform does not offer support for robust
/// mutexes, this mutex class behaves as a regular process-shared
/// mutex, which means that if a thread dies while holding a lock, any
/// future attempt at locking will block indefinitely.
class RobustMutex: private Mutex {
public:
    RobustMutex();
    ~RobustMutex() TIGHTDB_NOEXCEPT;

    static bool is_robust_on_this_platform() TIGHTDB_NOEXCEPT;

    class NotRecoverable;

    /// \param recover_func If the present platform does not support
    /// robust mutexes, this function is never called. Otherwise it is
    /// called if, and only if a thread has died while holding a
    /// lock. The purpose of the function is to reestablish a
    /// consistent shared state. If it fails to do this by throwing an
    /// exception, the mutex enters the 'unrecoverable' state where
    /// any future attempt at locking it will fail and cause
    /// NotRecoverable to be thrown. This function is advised to throw
    /// NotRecoverable when it fails, but it may throw any exception.
    ///
    /// \throw NotRecoverable If thrown by the specified recover
    /// function, or if the mutex has entered the 'unrecoverable'
    /// state due to a different thread throwing from its recover
    /// function.
    template<class Func> void lock(Func recover_func);

    void unlock() TIGHTDB_NOEXCEPT;

    /// Low-level locking of robust mutex.
    ///
    /// If the present platform does not support robust mutexes, this
    /// function always returns true. Otherwise it returns false if,
    /// and only if a thread has died while holding a lock.
    ///
    /// \note Most application should never call this function
    /// directly. It is called automatically when using the ordinary
    /// lock() function.
    ///
    /// \throw NotRecoverable If this mutex has entered the "not
    /// recoverable" state. It enters this state if
    /// mark_as_consistent() is not called between a call to
    /// robust_lock() that returns false and the corresponding call to
    /// unlock().
    bool low_level_lock();

    /// Pull this mutex out of the 'inconsistent' state.
    ///
    /// Must be called only after low_level_lock() has returned false.
    ///
    /// \note Most application should never call this function
    /// directly. It is called automatically when using the ordinary
    /// lock() function.
    void mark_as_consistent() TIGHTDB_NOEXCEPT;

    friend class CondVar;
};

class RobustMutex::NotRecoverable: public std::exception {
public:
    const char* what() const TIGHTDB_NOEXCEPT_OR_NOTHROW TIGHTDB_OVERRIDE
    {
        return "Failed to recover consistent state of shared memory";
    }
};


/// Condition variable for use in synchronization monitors.
class CondVar {
public:
    CondVar();
    ~CondVar() TIGHTDB_NOEXCEPT;

    struct process_shared_tag {};

    /// Initialize this condition variable for use across multiple
    /// processes. When constructed this way, the instance may be
    /// placed in memory shared by multimple processes, as well as in
    /// a memory mapped file. Such a condition variable remains valid
    /// even after the constructing process terminates. Deleting the
    /// instance (freeing the memory or deleting the file) without
    /// first calling the destructor is legal and will not cause any
    /// system resources to be leaked.
    CondVar(process_shared_tag);

    /// Wait for another thread to call notify() or notify_all().
    void wait(LockGuard& l) TIGHTDB_NOEXCEPT;
    template<class Func>
    void wait(RobustMutex& m, Func recover_func, const struct timespec* tp = 0);

    /// If any threads are wating for this condition, wake up at least
    /// one.
    void notify() TIGHTDB_NOEXCEPT;

    /// Wake up every thread that is currently wating on this
    /// condition.
    void notify_all() TIGHTDB_NOEXCEPT;

private:
    pthread_cond_t m_impl;

    TIGHTDB_NORETURN static void init_failed(int);
    TIGHTDB_NORETURN static void attr_init_failed(int);
    TIGHTDB_NORETURN static void destroy_failed(int) TIGHTDB_NOEXCEPT;
};





// Implementation:

inline Thread::Thread(): m_joinable(false)
{
}

template<class F> inline Thread::Thread(F func): m_joinable(true)
{
    UniquePtr<F> func2(new F(func)); // Throws
    start(&Thread::entry_point<F>, func2.get()); // Throws
    func2.release();
}

template<class F> inline void Thread::start(F func)
{
    if (m_joinable)
        std::terminate();
    UniquePtr<F> func2(new F(func)); // Throws
    start(&Thread::entry_point<F>, func2.get()); // Throws
    func2.release();
    m_joinable = true;
}

inline Thread::~Thread() TIGHTDB_NOEXCEPT
{
    if (m_joinable)
        std::terminate();
}

inline bool Thread::joinable() TIGHTDB_NOEXCEPT
{
    return m_joinable;
}

inline void Thread::start(entry_func_type entry_func, void* arg)
{
    const pthread_attr_t* attr = 0; // Use default thread attributes
    int r = pthread_create(&m_id, attr, entry_func, arg);
    if (TIGHTDB_UNLIKELY(r != 0))
        create_failed(r); // Throws
}

template<class F> inline void* Thread::entry_point(void* cookie) TIGHTDB_NOEXCEPT
{
    UniquePtr<F> func(static_cast<F*>(cookie));
    try {
        (*func)();
    }
    catch (...) {
        std::terminate();
    }
    return 0;
}


inline Mutex::Mutex()
{
    init_as_regular();
}

inline Mutex::Mutex(process_shared_tag)
{
    bool robust_if_available = false;
    init_as_process_shared(robust_if_available);
}

inline Mutex::~Mutex() TIGHTDB_NOEXCEPT
{
    int r = pthread_mutex_destroy(&m_impl);
    if (TIGHTDB_UNLIKELY(r != 0))
        destroy_failed(r);
}

inline void Mutex::init_as_regular()
{
    int r = pthread_mutex_init(&m_impl, 0);
    if (TIGHTDB_UNLIKELY(r != 0))
        init_failed(r);
}

inline void Mutex::lock() TIGHTDB_NOEXCEPT
{
    int r = pthread_mutex_lock(&m_impl);
    if (TIGHTDB_LIKELY(r == 0))
        return;
    lock_failed(r);
}

inline void Mutex::unlock() TIGHTDB_NOEXCEPT
{
    int r = pthread_mutex_unlock(&m_impl);
    TIGHTDB_ASSERT(r == 0);
    static_cast<void>(r);
}


inline LockGuard::LockGuard(Mutex& m) TIGHTDB_NOEXCEPT:
    m_mutex(m)
{
    m_mutex.lock();
}

inline LockGuard::~LockGuard() TIGHTDB_NOEXCEPT
{
    m_mutex.unlock();
}


inline UniqueLock::UniqueLock(Mutex& m) TIGHTDB_NOEXCEPT:
    m_mutex(&m)
{
    m_mutex->lock();
    m_is_locked = true;
}

inline UniqueLock::UniqueLock(Mutex& m, defer_lock_tag) TIGHTDB_NOEXCEPT:
    m_mutex(&m)
{
    m_is_locked = false;
}

inline UniqueLock::~UniqueLock() TIGHTDB_NOEXCEPT
{
    if (m_is_locked)
        m_mutex->unlock();
}

inline void UniqueLock::lock() TIGHTDB_NOEXCEPT
{
    m_mutex->lock();
    m_is_locked = true;
}

inline void UniqueLock::unlock() TIGHTDB_NOEXCEPT
{
    m_mutex->unlock();
    m_is_locked = false;
}



inline RobustMutex::RobustMutex():
    Mutex(no_init_tag())
{
    bool robust_if_available = true;
    init_as_process_shared(robust_if_available);
}

inline RobustMutex::~RobustMutex() TIGHTDB_NOEXCEPT
{
}

template<class Func> inline void RobustMutex::lock(Func recover_func)
{
    bool no_thread_has_died = low_level_lock(); // Throws
    if (TIGHTDB_LIKELY(no_thread_has_died))
        return;
    try {
        recover_func(); // Throws
        mark_as_consistent();
        // If we get this far, the protected memory has been
        // brought back into a consistent state, and the mutex has
        // been notified aboit this. This means that we can safely
        // enter the applications critical section.
    }
    catch (...) {
        // Unlocking without first calling mark_as_consistent()
        // means that the mutex enters the "not recoverable"
        // state, which will cause all future attempts at locking
        // to fail.
        unlock();
        throw;
    }
}

inline void RobustMutex::unlock() TIGHTDB_NOEXCEPT
{
    Mutex::unlock();
}


inline CondVar::CondVar()
{
    int r = pthread_cond_init(&m_impl, 0);
    if (TIGHTDB_UNLIKELY(r != 0))
        init_failed(r);
}

inline CondVar::~CondVar() TIGHTDB_NOEXCEPT
{
    int r = pthread_cond_destroy(&m_impl);
    if (TIGHTDB_UNLIKELY(r != 0))
        destroy_failed(r);
}

inline void CondVar::wait(LockGuard& l) TIGHTDB_NOEXCEPT
{
    int r = pthread_cond_wait(&m_impl, &l.m_mutex.m_impl);
    if (TIGHTDB_UNLIKELY(r != 0))
        TIGHTDB_TERMINATE("pthread_cond_wait() failed");
}

template<class Func>
inline void CondVar::wait(RobustMutex& m, Func recover_func, const struct timespec* tp)
{
    int r;
    if (!tp) {
        r = pthread_cond_wait(&m_impl, &m.m_impl);
    }
    else {
        r = pthread_cond_timedwait(&m_impl, &m.m_impl, tp);
        if (r == ETIMEDOUT)
            return;
    }
    if (TIGHTDB_LIKELY(r == 0))
        return;
#ifdef TIGHTDB_HAVE_ROBUST_PTHREAD_MUTEX
    if (r == ENOTRECOVERABLE)
        throw NotRecoverable();
    if (r != EOWNERDEAD)
        lock_failed(r); // does not return
#endif
    try {
        recover_func(); // Throws
        m.mark_as_consistent();
        // If we get this far, the protected memory has been
        // brought back into a consistent state, and the mutex has
        // been notified aboit this. This means that we can safely
        // enter the applications critical section.
    }
    catch (...) {
        // Unlocking without first calling mark_as_consistent()
        // means that the mutex enters the "not recoverable"
        // state, which will cause all future attempts at locking
        // to fail.
        m.unlock();
        throw;
    }
}

inline void CondVar::notify() TIGHTDB_NOEXCEPT
{
    int r = pthread_cond_signal(&m_impl);
    TIGHTDB_ASSERT(r == 0);
    static_cast<void>(r);
}

inline void CondVar::notify_all() TIGHTDB_NOEXCEPT
{
    int r = pthread_cond_broadcast(&m_impl);
    TIGHTDB_ASSERT(r == 0);
    static_cast<void>(r);
}


// Support for simple atomic variables, inspired by C++11 atomics, but incomplete.
//
// The level of support provided is driven by the need of the tightdb library.
// It is not meant to provide full support for atomics, but it is meant to be
// the place where we put low level code related to atomic variables.
//
// Useful for non-blocking data structures.
//
// These primitives ensure that memory appears consistent around load/store
// of the variables, and ensures that the compiler will not optimize away
// relevant instructions.
//
// This template can only be used for types for which the underlying hardware
// guarantees atomic reads and writes. On almost any machine in production,
// this includes all types with the size of a machine word (or machine register) 
// or less, except bit fields.
// 
// FIXME: This leaves it to the user of the software to ascertain that the
// hardware lives up to the requirement. The long term goal should be to provide
// atomicity in a way which will cause compilation to fail if the underlying
// platform is not guaranteed to support the requirements given by the use of
// the primitives.
//
// FIXME: The current implementation provides the functionality required for the
// tightdb library, but *not* all the functionality often provided by atomics.
// (see C++11 atomics for an example). We'll add additional functionality as
// the need arises.
//
// Usage: For non blocking data structures, you need to wrap any synchronization
// variables using the Atomic template. Variables which are not used for
// synchronization need no special declaration. As long as signaling between threads
// is done using the store and load methods declared here, memory barriers will
// ensure a consistent view of the other variables.
//
// Prior to gcc 4.7 there was no portable ways of providing acquire/release semantics,
// so for earlier versions we fall back to sequential consistency.
// As some architectures, most notably x86, provide release and acquire semantics
// in hardware, this is somewhat annoying, because we will use a full memory barrier
// where no-one is needed.
//
// FIXME: introduce x86 specific optimization to avoid the memory
// barrier!
template<class T>
class Atomic
{
public:
    inline Atomic()
    {
        state = 0;
    }

    inline Atomic(T init_value)
    {
        state = init_value;
    }

    T load() const;
    T load_acquire() const;
    T load_relaxed() const;
    T fetch_sub_relaxed(T v);
    T fetch_sub_release(T v);
    T fetch_add_release(T v);
    T fetch_add_acquire(T v);
    T fetch_sub_acquire(T v);
    void store(T value);
    void store_release(T value);
    void store_relaxed(T value);
    bool compare_and_swap(T& oldvalue, T newvalue);
private:
    // the following is not supported
    Atomic(Atomic<T>&);
    Atomic<T>& operator=(const Atomic<T>&);

    // Assumed to be naturally aligned - if not, hardware might not guarantee atomicity
#ifdef TIGHTDB_HAVE_CXX11_ATOMIC
    std::atomic<T> state;
#else
#ifdef _MSC_VER
    volatile T state;
#else
#ifdef __GNUC__
    T state;
#else
#error "Atomic is not support on this compiler"
#endif
#endif
#endif
};


#ifdef TIGHTDB_HAVE_CXX11_ATOMIC
template<typename T>
inline T Atomic<T>::load() const
{
    return state.load();
}

template<typename T>
inline T Atomic<T>::load_acquire() const
{
    return state.load(std::memory_order_acquire);
}

template<typename T>
inline T Atomic<T>::load_relaxed() const
{
    return state.load(std::memory_order_relaxed);
}

template<typename T>
inline T Atomic<T>::fetch_sub_relaxed(T v)
{
    return state.fetch_sub(v, std::memory_order_relaxed);
}

template<typename T>
inline T Atomic<T>::fetch_sub_release(T v)
{
    return state.fetch_sub(v, std::memory_order_release);
}

template<typename T>
inline T Atomic<T>::fetch_add_release(T v)
{
    return state.fetch_add(v, std::memory_order_release);
}

template<typename T>
inline T Atomic<T>::fetch_add_acquire(T v)
{
    return state.fetch_add(v, std::memory_order_acquire);
}

template<typename T>
inline T Atomic<T>::fetch_sub_acquire(T v)
{
    return state.fetch_sub(v, std::memory_order_acquire);
}

template<typename T>
inline void Atomic<T>::store(T value)
{
    state.store(value);
}

template<typename T>
inline void Atomic<T>::store_release(T value)
{
    state.store(value, std::memory_order_release);
}

template<typename T>
inline void Atomic<T>::store_relaxed(T value)
{
    state.store(value, std::memory_order_relaxed);
}

template<typename T>
inline bool Atomic<T>::compare_and_swap(T& oldvalue, T newvalue)
{
    return state.compare_exchange_weak(oldvalue, newvalue);
}

#else
#ifdef _MSC_VER
template<typename T>
inline T Atomic<T>::load() const
{
    return state;
}

template<typename T>
inline T Atomic<T>::load_relaxed() const
{
    return state;
}

template<typename T>
inline T Atomic<T>::load_acquire() const
{
    return state;
}

template<typename T>
inline void Atomic<T>::store(T value)
{
    state = value;
}

template<typename T>
inline void Atomic<T>::store_relaxed(T value)
{
    state = value;

}

template<typename T>
inline void Atomic<T>::store_release(T value)
{
    state = value;
}

#endif
#ifdef __GNUC__
// gcc implementation, pre c++11:
template<typename T>
inline T Atomic<T>::load_acquire() const
{
    T retval;
#if TIGHTDB_HAVE_AT_LEAST_GCC(4, 7)
    retval = __atomic_load_n(&state, __ATOMIC_ACQUIRE);
#else
    __sync_synchronize();
    retval = load_relaxed();
#endif
    return retval;
}

template<typename T>
inline T Atomic<T>::load_relaxed() const
{
    T retval;
#if TIGHTDB_HAVE_AT_LEAST_GCC(4, 7)
    retval = __atomic_load_n(&state, __ATOMIC_RELAXED);
#else
    if (sizeof(T) >= sizeof(ptrdiff_t)) {
        // do repeated reads until we've seen the same value twice,
        // then we know that the reads were done without changes to the value.
        // under normal circumstances, the loop is never executed
        retval = state;
        asm volatile ("" : : : "memory");
        T val = state;
        while (retval != val) {
            asm volatile ("" : : : "memory");
            val = retval;
            retval = state;
        }
    } else {
        asm volatile ("" : : : "memory");
        retval = state;
    }
#endif
    return retval;
}

template<typename T>
inline T Atomic<T>::load() const
{
#if TIGHTDB_HAVE_AT_LEAST_GCC(4, 7)
    T retval = __atomic_load_n(&state, __ATOMIC_SEQ_CST);
#else
    __sync_synchronize();
    T retval = load_relaxed();
#endif
    return retval;
}

template<typename T>
inline T Atomic<T>::fetch_sub_relaxed(T v)
{
#if TIGHTDB_HAVE_AT_LEAST_GCC(4, 7)
    return __atomic_fetch_sub(&state, v, __ATOMIC_RELAXED);
#else
    return __sync_fetch_and_sub(&state, v);
#endif
}

template<typename T>
inline T Atomic<T>::fetch_sub_release(T v)
{
#if TIGHTDB_HAVE_AT_LEAST_GCC(4, 7)
    return __atomic_fetch_sub(&state, v, __ATOMIC_RELEASE);
#else
    return __sync_fetch_and_sub(&state, v);
#endif
}

template<typename T>
inline T Atomic<T>::fetch_add_release(T v)
{
#if TIGHTDB_HAVE_AT_LEAST_GCC(4, 7)
    return __atomic_fetch_add(&state, v, __ATOMIC_RELEASE);
#else
    return __sync_fetch_and_add(&state, v);
#endif
}

template<typename T>
inline T Atomic<T>::fetch_add_acquire(T v)
{
#if TIGHTDB_HAVE_AT_LEAST_GCC(4, 7)
    return __atomic_fetch_add(&state, v, __ATOMIC_ACQUIRE);
#else
    return __sync_fetch_and_add(&state, v);
#endif
}

template<typename T>
inline T Atomic<T>::fetch_sub_acquire(T v)
{
#if TIGHTDB_HAVE_AT_LEAST_GCC(4, 7)
    return __atomic_fetch_sub(&state, v, __ATOMIC_ACQUIRE);
#else
    return __sync_fetch_and_sub(&state, v);
#endif
}


template<typename T>
inline void Atomic<T>::store(T value)
{
#if TIGHTDB_HAVE_AT_LEAST_GCC(4, 7)
    __atomic_store_n(&state, value, __ATOMIC_SEQ_CST);
#else
    if (sizeof(T) >= sizeof(ptrdiff_t)) {
        T old_value = state;
        // Ensure atomic store for type larger than largest native word.
        // normally, this loop will not be entered.
        while ( ! __sync_bool_compare_and_swap(&state, old_value, value)) {
            old_value = state;
        };
    } else {
        __sync_synchronize();
        state = value;
    }
    // prevent registerization of state (this is not really needed, I think)
    asm volatile ("" : : : "memory");
#endif
}

template<typename T>
inline void Atomic<T>::store_release(T value)
{
#if TIGHTDB_HAVE_AT_LEAST_GCC(4, 7)
    __atomic_store_n(&state, value, __ATOMIC_RELEASE);
#else
    // prior to gcc 4.7 we have no portable way of expressing
    // release semantics, so we do seq_consistent store instead
    store(value);
#endif
}

template<typename T>
inline void Atomic<T>::store_relaxed(T value)
{
#if TIGHTDB_HAVE_AT_LEAST_GCC(4, 7)
    __atomic_store_n(&state, value, __ATOMIC_RELAXED);
#else
    // prior to gcc 4.7 we have no portable way of expressing
    // relaxed semantics, so we do seq_consistent store instead
    // FIXME: we did! ordinary stores (with atomicity..)
    store(value);
#endif
}

template<typename T>
inline bool Atomic<T>::compare_and_swap(T& oldvalue, T newvalue)
{
#if TIGHTDB_HAVE_AT_LEAST_GCC(4, 7)
    return __atomic_compare_exchange_n(&state, &oldvalue, newvalue, false, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE);
#else
    T ov = oldvalue;
    oldvalue = __sync_val_compare_and_swap(&state, oldvalue, newvalue);
    return (ov == oldvalue);
    
#endif
}


#endif // GCC
#endif // C++11 else



} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_THREAD_HPP
