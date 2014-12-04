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
#ifndef TIGHTDB_COLUMN_TPL_HPP
#define TIGHTDB_COLUMN_TPL_HPP

#include <cstdlib>

#include <tightdb/util/features.h>
#include <tightdb/array.hpp>
#include <tightdb/array_basic.hpp>
#include <tightdb/column.hpp>
#include <tightdb/column_fwd.hpp>

namespace tightdb {

template<class T, class cond> class FloatDoubleNode;
template<class T, class cond> class IntegerNode;
template<class T> class SequentialGetter;

template<class cond, class T> struct ColumnTypeTraits2;

template<class cond> struct ColumnTypeTraits2<cond, int64_t> {
    typedef Column column_type;
    typedef Array array_type;
};
template<class cond> struct ColumnTypeTraits2<cond, bool> {
    typedef Column column_type;
    typedef Array array_type;
};
template<class cond> struct ColumnTypeTraits2<cond, float> {
    typedef ColumnFloat column_type;
    typedef ArrayFloat array_type;
};
template<class cond> struct ColumnTypeTraits2<cond, double> {
    typedef ColumnDouble column_type;
    typedef ArrayDouble array_type;
};


template <class T, class R, Action action, class condition>
    R ColumnBase::aggregate(T target, std::size_t start, std::size_t end,
                            std::size_t limit, std::size_t* return_ndx) const
{

    condition cond;
    int c = condition::condition;
    typedef typename ColumnTypeTraits2<condition, T>::column_type ColType;
    typedef typename ColumnTypeTraits2<condition, T>::array_type ArrType;

    if (end == std::size_t(-1))
        end = size();

    QueryState<R> state;
    state.init(action, null_ptr, limit);

    ColType* column = const_cast<ColType*>(static_cast<const ColType*>(this));
    SequentialGetter<T> sg(column);

    bool cont = true;
    for (size_t s = start; cont && s < end; ) {
        sg.cache_next(s);
        size_t end2 = sg.local_end(end);

        if(util::SameType<T, int64_t>::value) {
            cont = (static_cast<const Array*>(sg.m_array_ptr))->find(c, action, int64_t(target), s - sg.m_leaf_start, end2, sg.m_leaf_start, reinterpret_cast<QueryState<int64_t>*>(&state));
        }
        else {
            for(size_t local_index = s - sg.m_leaf_start; cont && local_index < end2; local_index++) {
                T v = ((ArrType*)(sg.m_array_ptr))->get(local_index);
                if(cond(v, target)) {
                    cont = (static_cast<QueryState<R>*>(&state))->template match<action, false>(s + local_index , 0, static_cast<R>(v));
                }
            }
        }
        s = end2 + sg.m_leaf_start;
    }

    if (return_ndx)
        *return_ndx = state.m_minmax_index;

    return state.m_state;
}


} // namespace tightdb

#endif // TIGHTDB_COLUMN_TPL_HPP
