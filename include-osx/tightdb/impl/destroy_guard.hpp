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

#ifndef TIGHTDB_IMPL_DESTROY_GUARD_HPP
#define TIGHTDB_IMPL_DESTROY_GUARD_HPP

#include <tightdb/util/features.h>
#include <tightdb/array.hpp>

namespace tightdb {
namespace _impl {


/// Calls `ptr->destroy()` if the guarded pointer (`ptr`) is not null
/// when the guard is destroyed. For arrays (`T` = `Array`) this means
/// that the array is destroyed in a shallow fashion. See
/// `DeepArrayDestroyGuard` for an alternative.
template<class T> class DestroyGuard {
public:
    DestroyGuard() TIGHTDB_NOEXCEPT;

    DestroyGuard(T*) TIGHTDB_NOEXCEPT;

    ~DestroyGuard() TIGHTDB_NOEXCEPT;

    void reset(T*) TIGHTDB_NOEXCEPT;

    T* get() const TIGHTDB_NOEXCEPT;

    T* release() TIGHTDB_NOEXCEPT;

private:
    T* m_ptr;
};

typedef DestroyGuard<Array> ShallowArrayDestroyGuard;


/// Calls `ptr->destroy_deep()` if the guarded Array pointer (`ptr`)
/// is not null when the guard is destroyed.
class DeepArrayDestroyGuard {
public:
    DeepArrayDestroyGuard() TIGHTDB_NOEXCEPT;

    DeepArrayDestroyGuard(Array*) TIGHTDB_NOEXCEPT;

    ~DeepArrayDestroyGuard() TIGHTDB_NOEXCEPT;

    void reset(Array*) TIGHTDB_NOEXCEPT;

    Array* get() const TIGHTDB_NOEXCEPT;

    Array* release() TIGHTDB_NOEXCEPT;

private:
    Array* m_ptr;
};


/// Calls `Array::destroy_deep(ref, alloc)` if the guarded 'ref'
/// (`ref`) is not zero when the guard is destroyed.
class DeepArrayRefDestroyGuard {
public:
    DeepArrayRefDestroyGuard(Allocator&) TIGHTDB_NOEXCEPT;

    DeepArrayRefDestroyGuard(ref_type, Allocator&) TIGHTDB_NOEXCEPT;

    ~DeepArrayRefDestroyGuard() TIGHTDB_NOEXCEPT;

    void reset(ref_type) TIGHTDB_NOEXCEPT;

    ref_type get() const TIGHTDB_NOEXCEPT;

    ref_type release() TIGHTDB_NOEXCEPT;

private:
    ref_type m_ref;
    Allocator& m_alloc;
};





// Implementation:

// DestroyGuard<T>

template<class T> inline DestroyGuard<T>::DestroyGuard() TIGHTDB_NOEXCEPT:
    m_ptr(0)
{
}

template<class T> inline DestroyGuard<T>::DestroyGuard(T* ptr) TIGHTDB_NOEXCEPT:
    m_ptr(ptr)
{
}

template<class T> inline DestroyGuard<T>::~DestroyGuard() TIGHTDB_NOEXCEPT
{
    if (m_ptr)
        m_ptr->destroy();
}

template<class T> inline void DestroyGuard<T>::reset(T* ptr) TIGHTDB_NOEXCEPT
{
    if (m_ptr)
        m_ptr->destroy();
    m_ptr = ptr;
}

template<class T> inline T* DestroyGuard<T>::get() const TIGHTDB_NOEXCEPT
{
    return m_ptr;
}

template<class T> inline T* DestroyGuard<T>::release() TIGHTDB_NOEXCEPT
{
    T* ptr = m_ptr;
    m_ptr = 0;
    return ptr;
}


// DeepArrayDestroyGuard

inline DeepArrayDestroyGuard::DeepArrayDestroyGuard() TIGHTDB_NOEXCEPT:
    m_ptr(0)
{
}

inline DeepArrayDestroyGuard::DeepArrayDestroyGuard(Array* ptr) TIGHTDB_NOEXCEPT:
    m_ptr(ptr)
{
}

inline DeepArrayDestroyGuard::~DeepArrayDestroyGuard() TIGHTDB_NOEXCEPT
{
    if (m_ptr)
        m_ptr->destroy_deep();
}

inline void DeepArrayDestroyGuard::reset(Array* ptr) TIGHTDB_NOEXCEPT
{
    if (m_ptr)
        m_ptr->destroy_deep();
    m_ptr = ptr;
}

inline Array* DeepArrayDestroyGuard::get() const TIGHTDB_NOEXCEPT
{
    return m_ptr;
}

inline Array* DeepArrayDestroyGuard::release() TIGHTDB_NOEXCEPT
{
    Array* ptr = m_ptr;
    m_ptr = 0;
    return ptr;
}


// DeepArrayRefDestroyGuard

inline DeepArrayRefDestroyGuard::DeepArrayRefDestroyGuard(Allocator& alloc) TIGHTDB_NOEXCEPT:
    m_ref(0),
    m_alloc(alloc)
{
}

inline DeepArrayRefDestroyGuard::DeepArrayRefDestroyGuard(ref_type ref,
                                                          Allocator& alloc) TIGHTDB_NOEXCEPT:
    m_ref(ref),
    m_alloc(alloc)
{
}

inline DeepArrayRefDestroyGuard::~DeepArrayRefDestroyGuard() TIGHTDB_NOEXCEPT
{
    if (m_ref)
        Array::destroy_deep(m_ref, m_alloc);
}

inline void DeepArrayRefDestroyGuard::reset(ref_type ref) TIGHTDB_NOEXCEPT
{
    if (m_ref)
        Array::destroy_deep(m_ref, m_alloc);
    m_ref = ref;
}

inline ref_type DeepArrayRefDestroyGuard::get() const TIGHTDB_NOEXCEPT
{
    return m_ref;
}

inline ref_type DeepArrayRefDestroyGuard::release() TIGHTDB_NOEXCEPT
{
    ref_type ref = m_ref;
    m_ref = 0;
    return ref;
}


} // namespace _impl
} // namespace tightdb

#endif // TIGHTDB_IMPL_DESTROY_GUARD_HPP
