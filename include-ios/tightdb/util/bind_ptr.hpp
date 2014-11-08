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
#ifndef TIGHTDB_UTIL_BIND_PTR_HPP
#define TIGHTDB_UTIL_BIND_PTR_HPP

#include <algorithm>
#include <ostream>

#include <tightdb/util/features.h>

#ifdef TIGHTDB_HAVE_CXX11_RVALUE_REFERENCE
#  include <utility>
#endif

#ifdef TIGHTDB_HAVE_CXX11_ATOMIC
#  include <atomic>
#endif


namespace tightdb {
namespace util {

/// A generic intrusive smart pointer that binds itself explicitely to
/// the target object.
///
/// This class is agnostic towards what 'binding' means for the target
/// object, but a common use is 'reference counting'. See RefCountBase
/// for an example of that.
///
/// This class provides a form of move semantics that is compatible
/// with C++03. It is similar to, but not as powerful as what is
/// provided natively by C++11. Instead of using `std::move()` (in
/// C++11), one must use `move()` without qualification. This will
/// call a special function that is a friend of this class. The
/// effectiveness of this form of move semantics relies on 'return
/// value optimization' being enabled in the compiler.
///
/// This smart pointer implementation assumes that the target object
/// destructor never throws.
template<class T> class bind_ptr {
public:
    TIGHTDB_CONSTEXPR bind_ptr() TIGHTDB_NOEXCEPT: m_ptr(0) {}
    explicit bind_ptr(T* p) TIGHTDB_NOEXCEPT { bind(p); }
    template<class U> explicit bind_ptr(U* p) TIGHTDB_NOEXCEPT { bind(p); }
    ~bind_ptr() TIGHTDB_NOEXCEPT { unbind(); }

#ifdef TIGHTDB_HAVE_CXX11_RVALUE_REFERENCE

    // Copy construct
    bind_ptr(const bind_ptr& p) TIGHTDB_NOEXCEPT { bind(p.m_ptr); }
    template<class U> bind_ptr(const bind_ptr<U>& p) TIGHTDB_NOEXCEPT { bind(p.m_ptr); }

    // Copy assign
    bind_ptr& operator=(const bind_ptr& p) TIGHTDB_NOEXCEPT { bind_ptr(p).swap(*this); return *this; }
    template<class U> bind_ptr& operator=(const bind_ptr<U>& p) TIGHTDB_NOEXCEPT { bind_ptr(p).swap(*this); return *this; }

    // Move construct
    bind_ptr(bind_ptr&& p) TIGHTDB_NOEXCEPT: m_ptr(p.release()) {}
    template<class U> bind_ptr(bind_ptr<U>&& p) TIGHTDB_NOEXCEPT: m_ptr(p.release()) {}

    // Move assign
    bind_ptr& operator=(bind_ptr&& p) TIGHTDB_NOEXCEPT { bind_ptr(std::move(p)).swap(*this); return *this; }
    template<class U> bind_ptr& operator=(bind_ptr<U>&& p) TIGHTDB_NOEXCEPT { bind_ptr(std::move(p)).swap(*this); return *this; }

#else // !TIGHTDB_HAVE_CXX11_RVALUE_REFERENCE

    // Copy construct
    bind_ptr(const bind_ptr& p) TIGHTDB_NOEXCEPT { bind(p.m_ptr); }
    template<class U> bind_ptr(bind_ptr<U> p) TIGHTDB_NOEXCEPT: m_ptr(p.release()) {}

    // Copy assign
    bind_ptr& operator=(bind_ptr p) TIGHTDB_NOEXCEPT { p.swap(*this); return *this; }
    template<class U> bind_ptr& operator=(bind_ptr<U> p) TIGHTDB_NOEXCEPT { bind_ptr(move(p)).swap(*this); return *this; }

#endif // !TIGHTDB_HAVE_CXX11_RVALUE_REFERENCE

    // Replacement for std::move() in C++11
    friend bind_ptr move(bind_ptr& p) TIGHTDB_NOEXCEPT { return bind_ptr(&p, move_tag()); }

    //@{
    // Comparison
    template<class U> bool operator==(const bind_ptr<U>&) const TIGHTDB_NOEXCEPT;
    template<class U> bool operator==(U*) const TIGHTDB_NOEXCEPT;
    template<class U> bool operator!=(const bind_ptr<U>&) const TIGHTDB_NOEXCEPT;
    template<class U> bool operator!=(U*) const TIGHTDB_NOEXCEPT;
    template<class U> bool operator<(const bind_ptr<U>&) const TIGHTDB_NOEXCEPT;
    template<class U> bool operator<(U*) const TIGHTDB_NOEXCEPT;
    template<class U> bool operator>(const bind_ptr<U>&) const TIGHTDB_NOEXCEPT;
    template<class U> bool operator>(U*) const TIGHTDB_NOEXCEPT;
    template<class U> bool operator<=(const bind_ptr<U>&) const TIGHTDB_NOEXCEPT;
    template<class U> bool operator<=(U*) const TIGHTDB_NOEXCEPT;
    template<class U> bool operator>=(const bind_ptr<U>&) const TIGHTDB_NOEXCEPT;
    template<class U> bool operator>=(U*) const TIGHTDB_NOEXCEPT;
    //@}

    // Dereference
    T& operator*() const TIGHTDB_NOEXCEPT { return *m_ptr; }
    T* operator->() const TIGHTDB_NOEXCEPT { return m_ptr; }

#ifdef TIGHTDB_HAVE_CXX11_EXPLICIT_CONV_OPERATORS
    explicit operator bool() const TIGHTDB_NOEXCEPT { return m_ptr != 0; }
#else
    typedef T* bind_ptr::*unspecified_bool_type;
    operator unspecified_bool_type() const TIGHTDB_NOEXCEPT { return m_ptr ? &bind_ptr::m_ptr : 0; }
#endif

    T* get() const TIGHTDB_NOEXCEPT { return m_ptr; }
    void reset() TIGHTDB_NOEXCEPT { bind_ptr().swap(*this); }
    void reset(T* p) TIGHTDB_NOEXCEPT { bind_ptr(p).swap(*this); }
    template<class U> void reset(U* p) TIGHTDB_NOEXCEPT { bind_ptr(p).swap(*this); }

    void swap(bind_ptr& p) TIGHTDB_NOEXCEPT { std::swap(m_ptr, p.m_ptr); }
    friend void swap(bind_ptr& a, bind_ptr& b) TIGHTDB_NOEXCEPT { a.swap(b); }

protected:
    struct move_tag {};
    bind_ptr(bind_ptr* p, move_tag) TIGHTDB_NOEXCEPT: m_ptr(p->release()) {}

    struct casting_move_tag {};
    template<class U> bind_ptr(bind_ptr<U>* p, casting_move_tag) TIGHTDB_NOEXCEPT:
        m_ptr(static_cast<T*>(p->release())) {}

private:
    T* m_ptr;

    void bind(T* p) TIGHTDB_NOEXCEPT { if (p) p->bind_ref(); m_ptr = p; }
    void unbind() TIGHTDB_NOEXCEPT { if (m_ptr) m_ptr->unbind_ref(); }

    T* release() TIGHTDB_NOEXCEPT { T* const p = m_ptr; m_ptr = 0; return p; }

    template<class> friend class bind_ptr;
};


template<class C, class T, class U>
inline std::basic_ostream<C,T>& operator<<(std::basic_ostream<C,T>& out, const bind_ptr<U>& p)
{
    out << static_cast<const void*>(p.get());
    return out;
}


//@{
// Comparison
template<class T, class U> bool operator==(T*, const bind_ptr<U>&) TIGHTDB_NOEXCEPT;
template<class T, class U> bool operator!=(T*, const bind_ptr<U>&) TIGHTDB_NOEXCEPT;
template<class T, class U> bool operator<(T*, const bind_ptr<U>&) TIGHTDB_NOEXCEPT;
template<class T, class U> bool operator>(T*, const bind_ptr<U>&) TIGHTDB_NOEXCEPT;
template<class T, class U> bool operator<=(T*, const bind_ptr<U>&) TIGHTDB_NOEXCEPT;
template<class T, class U> bool operator>=(T*, const bind_ptr<U>&) TIGHTDB_NOEXCEPT;
//@}



/// Polymorphic convenience base class for reference counting objects.
///
/// Together with bind_ptr, this class delivers simple instrusive
/// reference counting.
///
/// \sa bind_ptr
class RefCountBase {
public:
    RefCountBase() TIGHTDB_NOEXCEPT: m_ref_count(0) {}
    virtual ~RefCountBase() TIGHTDB_NOEXCEPT {}

protected:
    void bind_ref() const TIGHTDB_NOEXCEPT { ++m_ref_count; }
    void unbind_ref() const TIGHTDB_NOEXCEPT { if (--m_ref_count == 0) delete this; }

private:
    mutable unsigned long m_ref_count;

    template<class> friend class bind_ptr;
};


#ifdef TIGHTDB_HAVE_CXX11_ATOMIC
/// Same as RefCountBase, but this one makes the copying of, and the
/// destruction of counted references thread-safe.
///
/// \sa RefCountBase
/// \sa bind_ptr
class AtomicRefCountBase {
public:
    AtomicRefCountBase() TIGHTDB_NOEXCEPT: m_ref_count(0) {}
    virtual ~AtomicRefCountBase() TIGHTDB_NOEXCEPT {}

protected:
    // FIXME: Operators ++ and -- as used below use
    // std::memory_order_seq_cst. I'm not sure whether this is the
    // choice that leads to maximum efficiency, but at least it is
    // safe.
    void bind_ref() const TIGHTDB_NOEXCEPT { ++m_ref_count; }
    void unbind_ref() const TIGHTDB_NOEXCEPT { if (--m_ref_count == 0) delete this; }

private:
    mutable std::atomic<unsigned long> m_ref_count;

    template<class> friend class bind_ptr;
};
#endif // TIGHTDB_HAVE_CXX11_ATOMIC





// Implementation:

template<class T> template<class U> bool bind_ptr<T>::operator==(const bind_ptr<U>& p) const TIGHTDB_NOEXCEPT
{
    return m_ptr == p.m_ptr;
}

template<class T> template<class U> bool bind_ptr<T>::operator==(U* p) const TIGHTDB_NOEXCEPT
{
    return m_ptr == p;
}

template<class T> template<class U> bool bind_ptr<T>::operator!=(const bind_ptr<U>& p) const TIGHTDB_NOEXCEPT
{
    return m_ptr != p.m_ptr;
}

template<class T> template<class U> bool bind_ptr<T>::operator!=(U* p) const TIGHTDB_NOEXCEPT
{
    return m_ptr != p;
}

template<class T> template<class U> bool bind_ptr<T>::operator<(const bind_ptr<U>& p) const TIGHTDB_NOEXCEPT
{
    return m_ptr < p.m_ptr;
}

template<class T> template<class U> bool bind_ptr<T>::operator<(U* p) const TIGHTDB_NOEXCEPT
{
    return m_ptr < p;
}

template<class T> template<class U> bool bind_ptr<T>::operator>(const bind_ptr<U>& p) const TIGHTDB_NOEXCEPT
{
    return m_ptr > p.m_ptr;
}

template<class T> template<class U> bool bind_ptr<T>::operator>(U* p) const TIGHTDB_NOEXCEPT
{
    return m_ptr > p;
}

template<class T> template<class U> bool bind_ptr<T>::operator<=(const bind_ptr<U>& p) const TIGHTDB_NOEXCEPT
{
    return m_ptr <= p.m_ptr;
}

template<class T> template<class U> bool bind_ptr<T>::operator<=(U* p) const TIGHTDB_NOEXCEPT
{
    return m_ptr <= p;
}

template<class T> template<class U> bool bind_ptr<T>::operator>=(const bind_ptr<U>& p) const TIGHTDB_NOEXCEPT
{
    return m_ptr >= p.m_ptr;
}

template<class T> template<class U> bool bind_ptr<T>::operator>=(U* p) const TIGHTDB_NOEXCEPT
{
    return m_ptr >= p;
}

template<class T, class U> bool operator==(T* a, const bind_ptr<U>& b) TIGHTDB_NOEXCEPT
{
    return b == a;
}

template<class T, class U> bool operator!=(T* a, const bind_ptr<U>& b) TIGHTDB_NOEXCEPT
{
    return b != a;
}

template<class T, class U> bool operator<(T* a, const bind_ptr<U>& b) TIGHTDB_NOEXCEPT
{
    return b > a;
}

template<class T, class U> bool operator>(T* a, const bind_ptr<U>& b) TIGHTDB_NOEXCEPT
{
    return b < a;
}

template<class T, class U> bool operator<=(T* a, const bind_ptr<U>& b) TIGHTDB_NOEXCEPT
{
    return b >= a;
}

template<class T, class U> bool operator>=(T* a, const bind_ptr<U>& b) TIGHTDB_NOEXCEPT
{
    return b <= a;
}


} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_BIND_PTR_HPP
