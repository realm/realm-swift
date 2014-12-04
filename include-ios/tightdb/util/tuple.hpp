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
#ifndef TIGHTDB_UTIL_TUPLE_HPP
#define TIGHTDB_UTIL_TUPLE_HPP

#include <ostream>

#include <tightdb/util/type_list.hpp>

namespace tightdb {
namespace util {


template<class L> struct Tuple {
    typedef typename L::head head_type;
    typedef Tuple<typename L::tail> tail_type;
    head_type m_head;
    tail_type m_tail;
    Tuple(const head_type& h, const tail_type& t): m_head(h), m_tail(t) {}
};
template<> struct Tuple<void> {};


template<class H, class T> inline Tuple<TypeCons<H,T> > cons(const H& h, const Tuple<T>& t)
{
    return Tuple<TypeCons<H,T> >(h,t);
}


inline Tuple<void> tuple() { return Tuple<void>(); }

template<class A> inline Tuple<TypeCons<A, void> > tuple(const A& a)
{
    return cons(a, tuple());
}

template<class A, class B>
inline Tuple<TypeCons<A, TypeCons<B, void> > > tuple(const A& a, const B& b)
{
    return cons(a, tuple(b));
}

template<class A, class B, class C>
inline Tuple<TypeCons<A, TypeCons<B, TypeCons<C, void> > > >
tuple(const A& a, const B& b, const C& c)
{
    return cons(a, tuple(b,c));
}

template<class A, class B, class C, class D>
inline Tuple<TypeCons<A, TypeCons<B, TypeCons<C, TypeCons<D, void> > > > >
tuple(const A& a, const B& b, const C& c, const D& d)
{
    return cons(a, tuple(b,c,d));
}

template<class A, class B, class C, class D, class E>
inline Tuple<TypeCons<A, TypeCons<B, TypeCons<C, TypeCons<D, TypeCons<E, void> > > > > >
tuple(const A& a, const B& b, const C& c, const D& d, const E& e)
{
    return cons(a, tuple(b,c,d,e));
}

template<class A, class B, class C, class D, class E, class F> inline
Tuple<TypeCons<A, TypeCons<B, TypeCons<C, TypeCons<D, TypeCons<E, TypeCons<F, void> > > > > > >
tuple(const A& a, const B& b, const C& c, const D& d, const E& e, const F& f)
{
    return cons(a, tuple(b,c,d,e,f));
}


template<class L, class V>
inline Tuple<typename TypeAppend<L,V>::type> append(const Tuple<L>& t, const V& v)
{
    return cons(t.m_head, append(t.m_tail, v));
}
template<class V>
inline Tuple<TypeCons<V, void> > append(const Tuple<void>&, const V& v)
{
    return tuple(v);
}
template<class L, class V>
inline Tuple<typename TypeAppend<L,V>::type> operator,(const Tuple<L>& t, const V& v)
{
    return append(t,v);
}

} // namespace util

namespace _impl {
    template<class L, int i> struct TupleAt {
        static typename util::TypeAt<L,i>::type exec(const util::Tuple<L>& t)
        {
            return TupleAt<typename L::tail, i-1>::exec(t.m_tail);
        }
    };
    template<class L> struct TupleAt<L,0> {
        static typename L::head exec(const util::Tuple<L>& t) { return t.m_head; }
    };

    template<class Ch, class Tr, class T>
    inline void write(std::basic_ostream<Ch, Tr>& out,
                      const util::Tuple<util::TypeCons<T, void> >& t)
    {
        out << t.m_head;
    }
    template<class Ch, class Tr>
    inline void write(std::basic_ostream<Ch, Tr>&, const util::Tuple<void>&) {}
    template<class Ch, class Tr, class L>
    inline void write(std::basic_ostream<Ch, Tr>& out, const util::Tuple<L>& t)
    {
        out << t.m_head << ',';
        write(out, t.m_tail);
    }
}

namespace util {

template<int i, class L> inline typename TypeAt<L,i>::type at(const Tuple<L>& tuple)
{
    return _impl::TupleAt<L,i>::exec(tuple);
}

template<template<class T> class Op, class L>
inline void for_each(const Tuple<L>& tuple)
{
    Op<typename L::head>()(tuple.head);
    for_each<Op>(tuple.m_tail);
}
template<template<class T> class Op>
inline void for_each(const Tuple<void>&) {}

template<template<class T> class Op, class L, class A>
inline void for_each(const Tuple<L>& tuple, const A& a)
{
    Op<typename L::head>()(tuple.m_head, a);
    for_each<Op>(tuple.m_tail, a);
}
template<template<class T> class Op, class A>
inline void for_each(const Tuple<void>&, const A&) {}

template<class Ch, class Tr, class L>
inline std::basic_ostream<Ch, Tr>& operator<<(std::basic_ostream<Ch, Tr>& out, const Tuple<L>& t)
{
    out << '(';
    _impl::write(out, t);
    out << ')';
    return out;
}


} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_TUPLE_HPP
