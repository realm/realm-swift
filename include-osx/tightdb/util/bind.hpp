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
#ifndef TIGHTDB_UTIL_BIND_HPP
#define TIGHTDB_UTIL_BIND_HPP

namespace tightdb {


namespace _impl {


template<class A> class FunOneArgBinder0 {
public:
    FunOneArgBinder0(void (*fun)(A), const A& a):
        m_fun(fun),
        m_a(a)
    {
    }
    void operator()() const
    {
        (*m_fun)(m_a);
    }
private:
    void (*const m_fun)(A);
    const A m_a;
};

template<class A, class B> class FunOneArgBinder1 {
public:
    FunOneArgBinder1(void (*fun)(A,B), const A& a):
        m_fun(fun),
        m_a(a)
    {
    }
    void operator()(B b) const
    {
        (*m_fun)(m_a, b);
    }
private:
    void (*const m_fun)(A,B);
    const A m_a;
};

template<class A, class B, class C> class FunOneArgBinder2 {
public:
    FunOneArgBinder2(void (*fun)(A,B,C), const A& a):
        m_fun(fun),
        m_a(a)
    {
    }
    void operator()(B b, C c) const
    {
        (*m_fun)(m_a, b, c);
    }
private:
    void (*const m_fun)(A,B,C);
    const A m_a;
};



template<class A, class B> class FunTwoArgBinder0 {
public:
    FunTwoArgBinder0(void (*fun)(A,B), const A& a, const B& b):
        m_fun(fun),
        m_a(a),
        m_b(b)
    {
    }
    void operator()() const
    {
        (*m_fun)(m_a, m_b);
    }
private:
    void (*const m_fun)(A,B);
    const A m_a;
    const B m_b;
};

template<class A, class B, class C> class FunTwoArgBinder1 {
public:
    FunTwoArgBinder1(void (*fun)(A,B,C), const A& a, const B& b):
        m_fun(fun),
        m_a(a),
        m_b(b)
    {
    }
    void operator()(C c) const
    {
        (*m_fun)(m_a, m_b, c);
    }
private:
    void (*const m_fun)(A,B,C);
    const A m_a;
    const B m_b;
};

template<class A, class B, class C, class D> class FunTwoArgBinder2 {
public:
    FunTwoArgBinder2(void (*fun)(A,B,C,D), const A& a, const B& b):
        m_fun(fun),
        m_a(a),
        m_b(b)
    {
    }
    void operator()(C c, D d) const
    {
        (*m_fun)(m_a, m_b, c, d);
    }
private:
    void (*const m_fun)(A,B,C,D);
    const A m_a;
    const B m_b;
};



template<class A, class B, class C> class FunThreeArgBinder0 {
public:
    FunThreeArgBinder0(void (*fun)(A,B,C), const A& a, const B& b, const C& c):
        m_fun(fun),
        m_a(a),
        m_b(b),
        m_c(c)
    {
    }
    void operator()() const
    {
        (*m_fun)(m_a, m_b, m_c);
    }
private:
    void (*const m_fun)(A,B,C);
    const A m_a;
    const B m_b;
    const C m_c;
};

template<class A, class B, class C, class D> class FunThreeArgBinder1 {
public:
    FunThreeArgBinder1(void (*fun)(A,B,C,D), const A& a, const B& b, const C& c):
        m_fun(fun),
        m_a(a),
        m_b(b),
        m_c(c)
    {
    }
    void operator()(D d) const
    {
        (*m_fun)(m_a, m_b, m_c, d);
    }
private:
    void (*const m_fun)(A,B,C,D);
    const A m_a;
    const B m_b;
    const C m_c;
};

template<class A, class B, class C, class D, class E> class FunThreeArgBinder2 {
public:
    FunThreeArgBinder2(void (*fun)(A,B,C,D,E), const A& a, const B& b, const C& c):
        m_fun(fun),
        m_a(a),
        m_b(b),
        m_c(c)
    {
    }
    void operator()(D d, E e) const
    {
        (*m_fun)(m_a, m_b, m_c, d, e);
    }
private:
    void (*const m_fun)(A,B,C,D,E);
    const A m_a;
    const B m_b;
    const C m_c;
};



template<class O> class MemFunObjZeroArgBinder0 {
public:
    MemFunObjZeroArgBinder0(void (O::*mem_fun)(), O* obj):
        m_mem_fun(mem_fun),
        m_obj(obj)
    {
    }
    void operator()() const
    {
        (m_obj->*m_mem_fun)();
    }
private:
    void (O::*const m_mem_fun)();
    O* const m_obj;
};

template<class O, class A> class MemFunObjZeroArgBinder1 {
public:
    MemFunObjZeroArgBinder1(void (O::*mem_fun)(A), O* obj):
        m_mem_fun(mem_fun),
        m_obj(obj)
    {
    }
    void operator()(A a) const
    {
        (m_obj->*m_mem_fun)(a);
    }
private:
    void (O::*const m_mem_fun)(A);
    O* const m_obj;
};

template<class O, class A, class B> class MemFunObjZeroArgBinder2 {
public:
    MemFunObjZeroArgBinder2(void (O::*mem_fun)(A,B), O* obj):
        m_mem_fun(mem_fun),
        m_obj(obj)
    {
    }
    void operator()(A a, B b) const
    {
        (m_obj->*m_mem_fun)(a,b);
    }
private:
    void (O::*const m_mem_fun)(A,B);
    O* const m_obj;
};



template<class O, class A> class MemFunObjOneArgBinder0 {
public:
    MemFunObjOneArgBinder0(void (O::*mem_fun)(A), O* obj, const A& a):
        m_mem_fun(mem_fun),
        m_obj(obj),
        m_a(a)
    {
    }
    void operator()() const
    {
        (m_obj->*m_mem_fun)(m_a);
    }
private:
    void (O::*const m_mem_fun)(A);
    O* const m_obj;
    const A m_a;
};

template<class O, class A, class B> class MemFunObjOneArgBinder1 {
public:
    MemFunObjOneArgBinder1(void (O::*mem_fun)(A,B), O* obj, const A& a):
        m_mem_fun(mem_fun),
        m_obj(obj),
        m_a(a)
    {
    }
    void operator()(B b) const
    {
        (m_obj->*m_mem_fun)(m_a, b);
    }
private:
    void (O::*const m_mem_fun)(A,B);
    O* const m_obj;
    const A m_a;
};

template<class O, class A, class B, class C> class MemFunObjOneArgBinder2 {
public:
    MemFunObjOneArgBinder2(void (O::*mem_fun)(A,B,C), O* obj, const A& a):
        m_mem_fun(mem_fun),
        m_obj(obj),
        m_a(a)
    {
    }
    void operator()(B b, C c) const
    {
        (m_obj->*m_mem_fun)(m_a, b, c);
    }
private:
    void (O::*const m_mem_fun)(A,B,C);
    O* const m_obj;
    const A m_a;
};



template<class O, class A, class B> class MemFunObjTwoArgBinder0 {
public:
    MemFunObjTwoArgBinder0(void (O::*mem_fun)(A,B), O* obj, const A& a, const B& b):
        m_mem_fun(mem_fun),
        m_obj(obj),
        m_a(a),
        m_b(b)
    {
    }
    void operator()() const
    {
        (m_obj->*m_mem_fun)(m_a, m_b);
    }
private:
    void (O::*const m_mem_fun)(A,B);
    O* const m_obj;
    const A m_a;
    const B m_b;
};

template<class O, class A, class B, class C> class MemFunObjTwoArgBinder1 {
public:
    MemFunObjTwoArgBinder1(void (O::*mem_fun)(A,B,C), O* obj, const A& a, const B& b):
        m_mem_fun(mem_fun),
        m_obj(obj),
        m_a(a),
        m_b(b)
    {
    }
    void operator()(C c) const
    {
        (m_obj->*m_mem_fun)(m_a, m_b, c);
    }
private:
    void (O::*const m_mem_fun)(A,B,C);
    O* const m_obj;
    const A m_a;
    const B m_b;
};

template<class O, class A, class B, class C, class D> class MemFunObjTwoArgBinder2 {
public:
    MemFunObjTwoArgBinder2(void (O::*mem_fun)(A,B,C,D), O* obj, const A& a, const B& b):
        m_mem_fun(mem_fun),
        m_obj(obj),
        m_a(a),
        m_b(b)
    {
    }
    void operator()(C c, D d) const
    {
        (m_obj->*m_mem_fun)(m_a, m_b, c, d);
    }
private:
    void (O::*const m_mem_fun)(A,B,C,D);
    O* const m_obj;
    const A m_a;
    const B m_b;
};


} // namespace _impl



namespace util {


/// Produce a nullary function by binding the argument of a unary
/// function.
template<class A>
inline _impl::FunOneArgBinder0<A> bind(void (*fun)(A), const A& a)
{
    return _impl::FunOneArgBinder0<A>(fun, a);
}

/// Produce a unary function by binding the first argument of a binary
/// function.
template<class A, class B>
inline _impl::FunOneArgBinder1<A,B> bind(void (*fun)(A,B), const A& a)
{
    return _impl::FunOneArgBinder1<A,B>(fun, a);
}

/// Produce a binary function by binding the first argument of a
/// ternary function.
template<class A, class B, class C>
inline _impl::FunOneArgBinder2<A,B,C> bind(void (*fun)(A,B,C), const A& a)
{
    return _impl::FunOneArgBinder2<A,B,C>(fun, a);
}



/// Produce a nullary function by binding both arguments of a binary
/// function.
template<class A, class B>
inline _impl::FunTwoArgBinder0<A,B> bind(void (*fun)(A,B), const A& a, const B& b)
{
    return _impl::FunTwoArgBinder0<A,B>(fun, a, b);
}

/// Produce a unary function by binding the first two arguments of a
/// ternary function.
template<class A, class B, class C>
inline _impl::FunTwoArgBinder1<A,B,C> bind(void (*fun)(A,B,C), const A& a, const B& b)
{
    return _impl::FunTwoArgBinder1<A,B,C>(fun, a, b);
}

/// Produce a binary function by binding the first two arguments of a
/// quaternary function (4-ary).
template<class A, class B, class C, class D>
inline _impl::FunTwoArgBinder2<A,B,C,D> bind(void (*fun)(A,B,C,D), const A& a, const B& b)
{
    return _impl::FunTwoArgBinder2<A,B,C,D>(fun, a, b);
}



/// Produce a nullary function by binding all three arguments of a
/// ternary function.
template<class A, class B, class C>
inline _impl::FunThreeArgBinder0<A,B,C> bind(void (*fun)(A,B,C), const A& a,
                                             const B& b, const C& c)
{
    return _impl::FunThreeArgBinder0<A,B,C>(fun, a, b, c);
}

/// Produce a unary function by binding the first three arguments of a
/// quaternary function (4-ary).
template<class A, class B, class C, class D>
inline _impl::FunThreeArgBinder1<A,B,C,D> bind(void (*fun)(A,B,C,D), const A& a,
                                               const B& b, const C& c)
{
    return _impl::FunThreeArgBinder1<A,B,C,D>(fun, a, b, c);
}

/// Produce a binary function by binding the first three arguments of
/// a quinary function (5-ary).
template<class A, class B, class C, class D, class E>
inline _impl::FunThreeArgBinder2<A,B,C,D,E> bind(void (*fun)(A,B,C,D,E), const A& a,
                                                 const B& b, const C& c)
{
    return _impl::FunThreeArgBinder2<A,B,C,D,E>(fun, a, b, c);
}



/// Produce a nullary function by binding the object of a nullary
/// class member function.
template<class O>
inline _impl::MemFunObjZeroArgBinder0<O> bind(void (O::*mem_fun)(), O* obj)
{
    return _impl::MemFunObjZeroArgBinder0<O>(mem_fun, obj);
}

/// Produce a unary function by binding the object of a unary class
/// member function.
template<class O, class A>
inline _impl::MemFunObjZeroArgBinder1<O,A> bind(void (O::*mem_fun)(A), O* obj)
{
    return _impl::MemFunObjZeroArgBinder1<O,A>(mem_fun, obj);
}

/// Produce a binary function by binding the object of a binary class
/// member function.
template<class O, class A, class B>
inline _impl::MemFunObjZeroArgBinder2<O,A,B> bind(void (O::*mem_fun)(A,B), O* obj)
{
    return _impl::MemFunObjZeroArgBinder2<O,A,B>(mem_fun, obj);
}



/// Produce a nullary function by binding the object and the argument
/// of a unary class member function.
template<class O, class A>
inline _impl::MemFunObjOneArgBinder0<O,A> bind(void (O::*mem_fun)(A), O* obj, const A& a)
{
    return _impl::MemFunObjOneArgBinder0<O,A>(mem_fun, obj, a);
}

/// Produce a unary function by binding the object and first argument
/// of a binary class member function.
template<class O, class A, class B>
inline _impl::MemFunObjOneArgBinder1<O,A,B> bind(void (O::*mem_fun)(A,B), O* obj, const A& a)
{
    return _impl::MemFunObjOneArgBinder1<O,A,B>(mem_fun, obj, a);
}

/// Produce a binary function by binding the object and first argument
/// of a ternary class member function.
template<class O, class A, class B, class C>
inline _impl::MemFunObjOneArgBinder2<O,A,B,C> bind(void (O::*mem_fun)(A,B,C), O* obj, const A& a)
{
    return _impl::MemFunObjOneArgBinder2<O,A,B,C>(mem_fun, obj, a);
}



/// Produce a nullary function by binding the object and both
/// arguments of a binary class member function.
template<class O, class A, class B>
inline _impl::MemFunObjTwoArgBinder0<O,A,B> bind(void (O::*mem_fun)(A,B), O* obj,
                                                 const A& a, const B& b)
{
    return _impl::MemFunObjTwoArgBinder0<O,A,B>(mem_fun, obj, a, b);
}

/// Produce a unary function by binding the object and the first two
/// arguments of a ternary class member function.
template<class O, class A, class B, class C>
inline _impl::MemFunObjTwoArgBinder1<O,A,B,C> bind(void (O::*mem_fun)(A,B,C), O* obj,
                                                   const A& a, const B& b)
{
    return _impl::MemFunObjTwoArgBinder1<O,A,B,C>(mem_fun, obj, a, b);
}

/// Produce a binary function by binding the object and the first two
/// arguments of a quaternary class member function (4-ary).
template<class O, class A, class B, class C, class D>
inline _impl::MemFunObjTwoArgBinder2<O,A,B,C,D> bind(void (O::*mem_fun)(A,B,C,D), O* obj,
                                                     const A& a, const B& b)
{
    return _impl::MemFunObjTwoArgBinder2<O,A,B,C,D>(mem_fun, obj, a, b);
}


} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_BIND_HPP
