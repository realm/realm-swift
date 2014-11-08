#ifndef TIGHTDB_UTIL_UNIQUE_PTR_HPP
#define TIGHTDB_UTIL_UNIQUE_PTR_HPP

#include <algorithm>

#include <tightdb/util/features.h>
#include <tightdb/util/assert.hpp>

namespace tightdb {
namespace util {


template<class T> class DefaultDelete {
public:
    void operator()(T*) const;
};


/// This class is a C++03 compatible replacement for
/// <tt>std::unique_ptr</tt> (as it exists in C++11). It reproduces
/// only a small subset of the features of
/// <tt>std::unique_ptr</tt>. In particular, it neither provides copy,
/// nor move semantics.
template<class T, class D = DefaultDelete<T> > class UniquePtr {
public:
    typedef T* pointer;
    typedef T element_type;
    typedef D deleter_type;

    explicit UniquePtr(T* = 0) TIGHTDB_NOEXCEPT;
    ~UniquePtr();

    T* get() const TIGHTDB_NOEXCEPT;
    T& operator*() const TIGHTDB_NOEXCEPT;
    T* operator->() const TIGHTDB_NOEXCEPT;

    void swap(UniquePtr&) TIGHTDB_NOEXCEPT;
    void reset(T* = 0);
    T* release() TIGHTDB_NOEXCEPT;

#ifdef TIGHTDB_HAVE_CXX11_EXPLICIT_CONV_OPERATORS
    explicit operator bool() const TIGHTDB_NOEXCEPT;
#else
    typedef T* UniquePtr::*unspecified_bool_type;
    operator unspecified_bool_type() const TIGHTDB_NOEXCEPT;
#endif

private:
    UniquePtr(const UniquePtr&); // Hide
    UniquePtr& operator=(const UniquePtr&); // Hide
    bool operator==(const UniquePtr&); // Hide
    bool operator!=(const UniquePtr&); // Hide

    T* m_ptr;
};


// Specialization for arrays
template<class T> class DefaultDelete<T[]> {
public:
    void operator()(T*) const;
};

// Specialization for arrays
template<class T, class D> class UniquePtr<T[], D>: private UniquePtr<T,D> {
public:
    typedef T* pointer;
    typedef T element_type;
    typedef D deleter_type;

    explicit UniquePtr(T* = 0) TIGHTDB_NOEXCEPT;

    T& operator[](std::size_t) const TIGHTDB_NOEXCEPT;

    void swap(UniquePtr&) TIGHTDB_NOEXCEPT;

    using UniquePtr<T,D>::get;
    using UniquePtr<T,D>::reset;
    using UniquePtr<T,D>::release;

#ifdef __clang__
    // Clang has a bug that causes it to effectively ignore the 'using' declaration.
    T& operator*() const TIGHTDB_NOEXCEPT;
#else
    using UniquePtr<T,D>::operator*;
#endif

#ifdef TIGHTDB_HAVE_CXX11_EXPLICIT_CONV_OPERATORS
    using UniquePtr<T,D>::operator bool;
#else
#  ifdef __clang__
    // Clang 3.0 and 3.1 has a bug that causes it to effectively
    // ignore the 'using' declaration.
    typedef typename UniquePtr<T,D>::unspecified_bool_type unspecified_bool_type;
    operator unspecified_bool_type() const TIGHTDB_NOEXCEPT;
#  else
    using UniquePtr<T,D>::operator typename UniquePtr<T,D>::unspecified_bool_type;
#  endif
#endif
};



template<class T, class D> void swap(UniquePtr<T,D>& p, UniquePtr<T,D>& q) TIGHTDB_NOEXCEPT;





// Implementation:

template<class T> inline void DefaultDelete<T>::operator()(T* p) const
{
    TIGHTDB_STATIC_ASSERT(0 < sizeof(T), "Can't delete via pointer to incomplete type");
    delete p;
}

template<class T> inline void DefaultDelete<T[]>::operator()(T* p) const
{
    TIGHTDB_STATIC_ASSERT(0 < sizeof(T), "Can't delete via pointer to incomplete type");
    delete[] p;
}

template<class T, class D> inline UniquePtr<T,D>::UniquePtr(T* p) TIGHTDB_NOEXCEPT: m_ptr(p)
{
}

template<class T, class D> inline UniquePtr<T[],D>::UniquePtr(T* p) TIGHTDB_NOEXCEPT:
    UniquePtr<T,D>(p)
{
}

template<class T, class D> inline UniquePtr<T,D>::~UniquePtr()
{
    D()(m_ptr);
}

template<class T, class D> inline T* UniquePtr<T,D>::get() const TIGHTDB_NOEXCEPT
{
    return m_ptr;
}

template<class T, class D> inline T& UniquePtr<T,D>::operator*() const TIGHTDB_NOEXCEPT
{
    return *m_ptr;
}

#ifdef __clang__
template<class T, class D>
inline T& UniquePtr<T[],D>::operator*() const TIGHTDB_NOEXCEPT
{
    return UniquePtr<T,D>::operator*();
}
#endif // __clang__

template<class T, class D>
inline T& UniquePtr<T[],D>::operator[](std::size_t i) const TIGHTDB_NOEXCEPT
{
    return (&**this)[i];
}

template<class T, class D> inline T* UniquePtr<T,D>::operator->() const TIGHTDB_NOEXCEPT
{
    return m_ptr;
}

template<class T, class D> inline void UniquePtr<T,D>::swap(UniquePtr& p) TIGHTDB_NOEXCEPT
{
    using std::swap; swap(m_ptr, p.m_ptr);
}

template<class T, class D> inline void UniquePtr<T[],D>::swap(UniquePtr& p) TIGHTDB_NOEXCEPT
{
    UniquePtr<T,D>::swap(p);
}

template<class T, class D> inline void UniquePtr<T,D>::reset(T* p)
{
    UniquePtr(p).swap(*this);
}

template<class T, class D> inline T* UniquePtr<T,D>::release() TIGHTDB_NOEXCEPT
{
    T* p = m_ptr;
    m_ptr = 0;
    return p;
}

#ifdef TIGHTDB_HAVE_CXX11_EXPLICIT_CONV_OPERATORS

template<class T, class D>
inline UniquePtr<T,D>::operator bool() const TIGHTDB_NOEXCEPT
{
    return m_ptr != 0;
}

#else // ! TIGHTDB_HAVE_CXX11_EXPLICIT_CONV_OPERATORS

template<class T, class D>
inline UniquePtr<T,D>::operator unspecified_bool_type() const TIGHTDB_NOEXCEPT
{
    return m_ptr ? &UniquePtr::m_ptr : 0;
}

#  ifdef __clang__
template<class T, class D>
inline UniquePtr<T[],D>::operator unspecified_bool_type() const TIGHTDB_NOEXCEPT
{
    return UniquePtr<T,D>::operator unspecified_bool_type();
}
#  endif // __clang__

#endif // ! TIGHTDB_HAVE_CXX11_EXPLICIT_CONV_OPERATORS

template<class T, class D> inline void swap(UniquePtr<T,D>& p, UniquePtr<T,D>& q) TIGHTDB_NOEXCEPT
{
    p.swap(q);
}


} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_UNIQUE_PTR_HPP
