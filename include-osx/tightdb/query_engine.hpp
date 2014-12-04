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

/*
A query consists of node objects, one for each query condition. Each node contains pointers to all other nodes:

node1        node2         node3
------       -----         -----
node2*       node1*        node1*
node3*       node3*        node2*

The construction of all this takes part in query.cpp. Each node has two important functions:

    aggregate(start, end)
    aggregate_local(start, end)

The aggregate() function executes the aggregate of a query. You can call the method on any of the nodes
(except children nodes of OrNode and SubtableNode) - it has the same behaviour. The function contains
scheduling that calls aggregate_local(start, end) on different nodes with different start/end ranges,
depending on what it finds is most optimal.

The aggregate_local() function contains a tight loop that tests the condition of its own node, and upon match
it tests all other conditions at that index to report a full match or not. It will remain in the tight loop
after a full match.

So a call stack with 2 and 9 being local matches of a node could look like this:

aggregate(0, 10)
    node1->aggregate_local(0, 3)
        node2->find_first_local(2, 3)
        node3->find_first_local(2, 3)
    node3->aggregate_local(3, 10)
        node1->find_first_local(4, 5)
        node2->find_first_local(4, 5)
        node1->find_first_local(7, 8)
        node2->find_first_local(7, 8)

find_first_local(n, n + 1) is a function that can be used to test a single row of another condition. Note that
this is very simplified. There are other statistical arguments to the methods, and also, find_first_local() can be
called from a callback function called by an integer Array.


Template arguments in methods:
----------------------------------------------------------------------------------------------------

TConditionFunction: Each node has a condition from query_conditions.c such as Equal, GreaterEqual, etc

TConditionValue:    Type of values in condition column. That is, int64_t, float, int, bool, etc

TAction:            What to do with each search result, from the enums act_ReturnFirst, act_Count, act_Sum, etc

TResult:            Type of result of actions - float, double, int64_t, etc. Special notes: For act_Count it's
                    int64_t, for TDB_FIND_ALL it's int64_t which points at destination array.

TSourceColumn:      Type of source column used in actions, or *ignored* if no source column is used (like for
                    act_Count, act_ReturnFirst)


There are two important classes used in queries:
----------------------------------------------------------------------------------------------------
SequentialGetter    Column iterator used to get successive values with leaf caching. Used both for condition columns
                    and aggregate source column

AggregateState      State of the aggregate - contains a state variable that stores intermediate sum, max, min,
                    etc, etc.

*/

#ifndef TIGHTDB_QUERY_ENGINE_HPP
#define TIGHTDB_QUERY_ENGINE_HPP

#include <string>
#include <functional>
#include <algorithm>

#include <tightdb/util/shared_ptr.hpp>
#include <tightdb/util/meta.hpp>
#include <tightdb/unicode.hpp>
#include <tightdb/utilities.hpp>
#include <tightdb/table.hpp>
#include <tightdb/table_view.hpp>
#include <tightdb/column_fwd.hpp>
#include <tightdb/column_string.hpp>
#include <tightdb/column_string_enum.hpp>
#include <tightdb/column_binary.hpp>
#include <tightdb/column_basic.hpp>
#include <tightdb/query_conditions.hpp>
#include <tightdb/array_basic.hpp>
#include <tightdb/array_string.hpp>
#include <tightdb/column_linklist.hpp>
#include <tightdb/column_link.hpp>
#include <tightdb/link_view.hpp>

#include <iostream>
#include <map>

#if _MSC_FULL_VER >= 160040219
#  include <immintrin.h>
#endif

/*

typedef float __m256 __attribute__ ((__vector_size__ (32),
                     __may_alias__));
typedef long long __m256i __attribute__ ((__vector_size__ (32),
                      __may_alias__));
typedef double __m256d __attribute__ ((__vector_size__ (32),
                       __may_alias__));

*/

namespace tightdb {

// Number of matches to find in best condition loop before breaking out to probe other conditions. Too low value gives too many
// constant time overheads everywhere in the query engine. Too high value makes it adapt less rapidly to changes in match
// frequencies.
const size_t findlocals = 64;

// Average match distance in linear searches where further increase in distance no longer increases query speed (because time
// spent on handling each match becomes insignificant compared to time spent on the search).
const size_t bestdist = 512;

// Minimum number of matches required in a certain condition before it can be used to compute statistics. Too high value can spent
// too much time in a bad node (with high match frequency). Too low value gives inaccurate statistics.
const size_t probe_matches = 4;

const size_t bitwidth_time_unit = 64;

typedef bool (*CallbackDummy)(int64_t);

template<class T> struct ColumnTypeTraits;

template<> struct ColumnTypeTraits<int64_t> {
    typedef Column column_type;
    typedef Array array_type;
    typedef int64_t sum_type;
    static const DataType id = type_Int;
};
template<> struct ColumnTypeTraits<bool> {
    typedef Column column_type;
    typedef Array array_type;
    typedef int64_t sum_type;
    static const DataType id = type_Bool;
};
template<> struct ColumnTypeTraits<float> {
    typedef ColumnFloat column_type;
    typedef ArrayFloat array_type;
    typedef double sum_type;
    static const DataType id = type_Float;
};
template<> struct ColumnTypeTraits<double> {
    typedef ColumnDouble column_type;
    typedef ArrayDouble array_type;
    typedef double sum_type;
    static const DataType id = type_Double;
};
template<> struct ColumnTypeTraits<DateTime> {
    typedef Column column_type;
    typedef Array array_type;
    typedef int64_t sum_type;
    static const DataType id = type_DateTime;
};

template<> struct ColumnTypeTraits<StringData> {
    typedef Column column_type;
    typedef Array array_type;
    typedef int64_t sum_type;
    static const DataType id = type_String;
};

// Only purpose is to return 'double' if and only if source column (T) is float and you're doing a sum (A)
template<class T, Action A> struct ColumnTypeTraitsSum {
    typedef T sum_type;
};

template<> struct ColumnTypeTraitsSum<float, act_Sum> {
    typedef double sum_type;
};


class SequentialGetterBase {
public:
    virtual ~SequentialGetterBase() TIGHTDB_NOEXCEPT {}
};

template<class T>class SequentialGetter : public SequentialGetterBase {
public:
    typedef typename ColumnTypeTraits<T>::column_type ColType;
    typedef typename ColumnTypeTraits<T>::array_type ArrayType;

    SequentialGetter(): m_array((Array::no_prealloc_tag())) {}

    SequentialGetter(const Table& table, size_t column_ndx): m_array((Array::no_prealloc_tag()))
    {
        if (column_ndx != not_found)
            m_column = static_cast<const ColType*>(&table.get_column_base(column_ndx));
        m_leaf_end = 0;
    }

    SequentialGetter(const ColType* column): m_array((Array::no_prealloc_tag()))
    {
        init(column);
    }

    ~SequentialGetter() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    void init(const ColType* column)
    {
        m_column = column;
        m_leaf_end = 0;
    }

    TIGHTDB_FORCEINLINE bool cache_next(size_t index)
    {
        // Return wether or not leaf array has changed (could be useful to know for caller)
        if (index >= m_leaf_end || index < m_leaf_start) {
            // GetBlock() does following: If m_column contains only a leaf, then just return pointer to that leaf and
            // leave m_array untouched. Else call init_from_header() on m_array (more time consuming) and return pointer to m_array.
            m_array_ptr = static_cast<const ArrayType*>(m_column->GetBlock(index, m_array, m_leaf_start, true));
            const size_t leaf_size = m_array_ptr->size();
            m_leaf_end = m_leaf_start + leaf_size;
            return true;
        }
        return false;
    }


    TIGHTDB_FORCEINLINE T get_next(size_t index)
    {
#ifdef _MSC_VER
#pragma warning(push)
#pragma warning(disable:4800)   // Disable the Microsoft warning about bool performance issue.
#endif

        cache_next(index);
        T av = m_array_ptr->get(index - m_leaf_start);
        return av;

#ifdef _MSC_VER
#pragma warning(pop)
#endif
    }

    size_t local_end(size_t global_end)
    {
        if (global_end > m_leaf_end)
            return m_leaf_end - m_leaf_start;
        else
            return global_end - m_leaf_start;
    }

    size_t m_leaf_start;
    size_t m_leaf_end;
    const ColType* m_column;

    // See reason for having both a pointer and instance above
    const ArrayType* m_array_ptr;
private:
    // Never access through m_array because it's uninitialized if column is just a leaf
    ArrayType m_array;
};


class ParentNode {
    typedef ParentNode ThisType;
public:

    ParentNode(): m_table(0) 
    { 
    }

    void gather_children(std::vector<ParentNode*>& v)
    {
        m_children.clear();
        ParentNode* p = this;
        size_t i = v.size();
        v.push_back(this);
        p = p->child_criteria();

        if (p)
            p->gather_children(v);

        m_children = v;
        m_children.erase(m_children.begin() + i);
        m_children.insert(m_children.begin(), this);

        m_conds = m_children.size();
    }

    struct score_compare {
        bool operator ()(const ParentNode* a, const ParentNode* b) const { return a->cost() < b->cost(); }
    };

    double cost() const
    {
        return 8 * bitwidth_time_unit / m_dD + m_dT; // dt = 1/64 to 1. Match dist is 8 times more important than bitwidth
    }

    size_t find_first(size_t start, size_t end)
    {
        size_t m = start;
        size_t next_cond = 0;
        size_t first_cond = 0;

        while (start < end) {
            m = m_children[next_cond]->find_first_local(start, end);

            next_cond++;
            if (next_cond == m_conds)
                next_cond = 0;

            if (m == start) {
                if (next_cond == first_cond)
                    return m;
            }
            else {
                first_cond = next_cond;
                start = m;
            }
        }
        return not_found;
    }


    virtual ~ParentNode() TIGHTDB_NOEXCEPT {}

    virtual void init(const Table& table)
    {
        m_table = &table;
        if (m_child)
            m_child->init(table);
        m_column_action_specializer = NULL;
    }

    virtual bool is_initialized() const
    {
        return m_table != null_ptr;
    }

    virtual size_t find_first_local(size_t start, size_t end) = 0;

    virtual ParentNode* child_criteria()
    {
        return m_child;
    }

    virtual void aggregate_local_prepare(Action TAction, DataType col_id)
    {
        if (TAction == act_ReturnFirst)
            m_column_action_specializer = & ThisType::column_action_specialization<act_ReturnFirst, int64_t>;

        else if (TAction == act_Count)
            m_column_action_specializer = & ThisType::column_action_specialization<act_Count, int64_t>;

        else if (TAction == act_Sum && col_id == type_Int)
            m_column_action_specializer = & ThisType::column_action_specialization<act_Sum, int64_t>;

        else if (TAction == act_Sum && col_id == type_Float)
            m_column_action_specializer = & ThisType::column_action_specialization<act_Sum, float>;
        else if (TAction == act_Sum && col_id == type_Double)
            m_column_action_specializer = & ThisType::column_action_specialization<act_Sum, double>;

        else if (TAction == act_Max && col_id == type_Int)
            m_column_action_specializer = & ThisType::column_action_specialization<act_Max, int64_t>;
        else if (TAction == act_Max && col_id == type_Float)
            m_column_action_specializer = & ThisType::column_action_specialization<act_Max, float>;
        else if (TAction == act_Max && col_id == type_Double)
            m_column_action_specializer = & ThisType::column_action_specialization<act_Max, double>;

        else if (TAction == act_Min && col_id == type_Int)
            m_column_action_specializer = & ThisType::column_action_specialization<act_Min, int64_t>;
        else if (TAction == act_Min && col_id == type_Float)
            m_column_action_specializer = & ThisType::column_action_specialization<act_Min, float>;
        else if (TAction == act_Min && col_id == type_Double)
            m_column_action_specializer = & ThisType::column_action_specialization<act_Min, double>;

        else if (TAction == act_FindAll)
            m_column_action_specializer = & ThisType::column_action_specialization<act_FindAll, int64_t>;

        else if (TAction == act_CallbackIdx)
            m_column_action_specializer = & ThisType::column_action_specialization<act_CallbackIdx, int64_t>;

        else {
            TIGHTDB_ASSERT(false);
        }
    }

    template<Action TAction, class TSourceColumn>
    bool column_action_specialization(QueryStateBase* st, SequentialGetterBase* source_column, size_t r)
    {
        // Sum of float column must accumulate in double
        typedef typename ColumnTypeTraitsSum<TSourceColumn, TAction>::sum_type TResult;
        TIGHTDB_STATIC_ASSERT( !(TAction == act_Sum && (util::SameType<TSourceColumn, float>::value &&
                                                        !util::SameType<TResult, double>::value)), "");

        // TResult: type of query result
        // TSourceColumn: type of aggregate source
        TSourceColumn av = (TSourceColumn)0;
        // uses_val test becuase compiler cannot see that Column::Get has no side effect and result is discarded
        if (static_cast<QueryState<TResult>*>(st)->template uses_val<TAction>() && source_column != null_ptr) {
            TIGHTDB_ASSERT(dynamic_cast<SequentialGetter<TSourceColumn>*>(source_column) != null_ptr);
            av = static_cast<SequentialGetter<TSourceColumn>*>(source_column)->get_next(r);
        }
        TIGHTDB_ASSERT(dynamic_cast<QueryState<TResult>*>(st) != null_ptr);
        bool cont = static_cast<QueryState<TResult>*>(st)->template match<TAction, 0>(r, 0, TResult(av));
        return cont;
    }

    virtual size_t aggregate_local(QueryStateBase* st, size_t start, size_t end, size_t local_limit,
                                   SequentialGetterBase* source_column)
    {
        // aggregate called on non-integer column type. Speed of this function is not as critical as speed of the
        // integer version, because find_first_local() is relatively slower here (because it's non-integers).
        //
        // Todo: Two speedups are possible. Simple: Initially test if there are no sub criterias and run find_first_local()
        // in a tight loop if so (instead of testing if there are sub criterias after each match). Harder: Specialize
        // data type array to make array call match() directly on each match, like for integers.

        size_t local_matches = 0;

        size_t r = start - 1;
        for (;;) {
            if (local_matches == local_limit) {
                m_dD = double(r - start) / (local_matches + 1.1);
                return r + 1;
            }

            // Find first match in this condition node
            r = find_first_local(r + 1, end);
            if (r == not_found) {
                m_dD = double(r - start) / (local_matches + 1.1);
                return end;
            }

            local_matches++;

            // Find first match in remaining condition nodes
            size_t m = r;

            for (size_t c = 1; c < m_conds; c++) {
                m = m_children[c]->find_first_local(r, r + 1);
                if (m != r) {
                    break;
                }
            }

            // If index of first match in this node equals index of first match in all remaining nodes, we have a final match
            if (m == r) {
                bool cont = (this->* m_column_action_specializer)(st, source_column, r);
                if (!cont) {
                    return static_cast<size_t>(-1);
                }
            }
        }
    }


    virtual std::string validate()
    {
        if (error_code != "")
            return error_code;
        if (m_child == 0)
            return "";
        else
            return m_child->validate();
    }

    ParentNode(const ParentNode& from)
    {
        m_child = from.m_child;
        m_children = from.m_children;
        m_condition_column_idx = from.m_condition_column_idx;
        m_conds = from.m_conds;
        m_dD = from.m_dD;
        m_dT = from.m_dT;
        m_probes = from.m_probes;
        m_matches = from.m_matches;
    }

    virtual ParentNode* clone() = 0;

    virtual void translate_pointers(const std::map<ParentNode*, ParentNode*>& mapping)
    {
        m_child = mapping.find(m_child)->second;
        for (size_t i = 0; i < m_children.size(); ++i)
            m_children[i] = mapping.find(m_children[i])->second;
    }


    ParentNode* m_child;
    std::vector<ParentNode*>m_children;
    size_t m_condition_column_idx; // Column of search criteria

    size_t m_conds;
    double m_dD; // Average row distance between each local match at current position
    double m_dT; // Time overhead of testing index i + 1 if we have just tested index i. > 1 for linear scans, 0 for index/tableview

    size_t m_probes;
    size_t m_matches;


protected:
    typedef bool (ParentNode::* TColumn_action_specialized)(QueryStateBase*, SequentialGetterBase*, size_t);
    TColumn_action_specialized m_column_action_specializer;
    const Table* m_table;
    std::string error_code;

    const ColumnBase& get_column_base(const Table& table, std::size_t ndx)
    {
        return table.get_column_base(ndx);
    }

    ColumnType get_real_column_type(const Table& table, std::size_t ndx)
    {
        return table.get_real_column_type(ndx);
    }
};

// Used for performing queries on a Tableview. This is done by simply passing the TableView to this query condition
class ListviewNode: public ParentNode {
public:
    ListviewNode(TableView& tv) : m_max(0), m_next(0), m_size(tv.size()), m_tv(tv) { m_child = 0; m_dT = 0.0; }
    ~ListviewNode() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {  }

    // Return the n'th table row index contained in the TableView.
    size_t tableindex(size_t n)
    {
        return to_size_t(m_tv.m_row_indexes.get(n));
    }

    virtual void init(const Table& table) TIGHTDB_OVERRIDE
    {
        m_table = &table;

        m_dD = m_table->size() / (m_tv.size() + 1.0);
        m_probes = 0;
        m_matches = 0;

        m_next = 0;
        if (m_size > 0)
            m_max = tableindex(m_size - 1);
        if (m_child) m_child->init(table);
    }

    size_t find_first_local(size_t start, size_t end)  TIGHTDB_OVERRIDE
    {
        // Simply return index of first table row which is >= start
        size_t r;
        r = m_tv.m_row_indexes.find_gte(start, m_next);

        if (r >= end)
            return not_found;

        m_next = r;
        return tableindex(r);
    }

    virtual ParentNode* clone()
    {
        return new ListviewNode(*this);
    }

    ListviewNode(const ListviewNode& from)
        : ParentNode(from), m_tv(from.m_tv)
    {
        m_max = from.m_max;
        m_next = from.m_next;
        m_size = from.m_size;
        m_child = from.m_child;
    }

protected:
    size_t m_max;
    size_t m_next;
    size_t m_size;

    TableView& m_tv;
};

// For conditions on a subtable (encapsulated in subtable()...end_subtable()). These return the parent row as match if and
// only if one or more subtable rows match the condition.
class SubtableNode: public ParentNode {
public:
    SubtableNode(size_t column): m_column(column) {m_child = 0; m_child2 = 0; m_dT = 100.0;}
    SubtableNode() {};
    ~SubtableNode() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    void init(const Table& table) TIGHTDB_OVERRIDE
    {
        m_dD = 10.0;
        m_probes = 0;
        m_matches = 0;

        m_table = &table;

        // m_child is first node in condition of subtable query.
        if (m_child) {
            // Can't call init() here as usual since the subtable can be degenerate
            // m_child->init(table);
            std::vector<ParentNode*> v;
            m_child->gather_children(v);
        }

        // m_child2 is next node of parent query
        if (m_child2)
            m_child2->init(table);
    }

    std::string validate()
    {
        if (error_code != "")
            return error_code;
        if (m_child == 0)
            return "Unbalanced subtable/end_subtable block";
        else
            return m_child->validate();
    }

    size_t find_first_local(size_t start, size_t end) TIGHTDB_OVERRIDE
    {
        TIGHTDB_ASSERT(m_table);
        TIGHTDB_ASSERT(m_child);

        for (size_t s = start; s < end; ++s) {
            const TableRef subtable = ((Table*)m_table)->get_subtable(m_column, s);

            if (subtable->is_degenerate())
                return not_found;

            m_child->init(*subtable);
            const size_t subsize = subtable->size();
            const size_t sub = m_child->find_first(0, subsize);

            if (sub != not_found)
                return s;
        }
        return not_found;
    }

    ParentNode* child_criteria()
    {
        return m_child2;
    }

    virtual ParentNode* clone()
    {
        return new SubtableNode(*this);
    }

    virtual void translate_pointers(const std::map<ParentNode*, ParentNode*>& mapping) TIGHTDB_OVERRIDE
    {
        ParentNode::translate_pointers(mapping);
        m_child2 = mapping.find(m_child2)->second;
    }

    SubtableNode(const SubtableNode& from) 
        : ParentNode(from)
    {
        m_child2 = from.m_child2;
        m_column = from.m_column;
        m_child = from.m_child;
    }

    ParentNode* m_child2;
    size_t m_column;
};


class IntegerNodeBase : public ParentNode
{
public:
    // This function is called from Array::find() for each search result if TAction == act_CallbackIdx
    // in the IntegerNode::aggregate_local() call. Used if aggregate source column is different from search criteria column
    // Return value: false means that the query-state (which consumes matches) has signalled to stop searching, perhaps
    template <Action TAction, class TSourceColumn> bool match_callback(int64_t v)
    {
        size_t i = to_size_t(v);
        m_last_local_match = i;
        m_local_matches++;

        typedef typename ColumnTypeTraitsSum<TSourceColumn, TAction>::sum_type QueryStateType;
        QueryState<QueryStateType>* state = static_cast<QueryState<QueryStateType>*>(m_state);
        SequentialGetter<TSourceColumn>* source_column = static_cast<SequentialGetter<TSourceColumn>*>(m_source_column);

        // Test remaining sub conditions of this node. m_children[0] is the node that called match_callback(), so skip it
        for (size_t c = 1; c < m_conds; c++) {
            m_children[c]->m_probes++;
            size_t m = m_children[c]->find_first_local(i, i + 1);
            if (m != i)
                return true;
        }

        bool b;
        if (state->template uses_val<TAction>())    { // Compiler cannot see that Column::Get has no side effect and result is discarded
            TSourceColumn av = source_column->get_next(i);
            b = state->template match<TAction, false>(i, 0, av);
        }
        else {
            b = state->template match<TAction, false>(i, 0, TSourceColumn(0));
        }

        return b;
    }

    IntegerNodeBase() :  m_array(Array::no_prealloc_tag())
    {
        m_child = 0;
        m_conds = 0;
        m_dT = 1.0 / 4.0;
        m_probes = 0;
        m_matches = 0;
    }

    IntegerNodeBase(const IntegerNodeBase& from)
        : ParentNode(from), m_array(Array::no_prealloc_tag())
    {
        // state is transient/only valid during search, no need to copy
        m_child = from.m_child;
        m_conds = 0;
        m_dT = 1.0 / 4.0;
        m_probes = 0;
        m_matches = 0;
    }

    size_t m_last_local_match;
    Array m_array;
    size_t m_leaf_start;
    size_t m_leaf_end;
    size_t m_local_end;

    size_t m_local_matches;
    size_t m_local_limit;
    bool m_fastmode_disabled;
    Action m_TAction;

    QueryStateBase* m_state;
    SequentialGetterBase* m_source_column; // Column of values used in aggregate (act_FindAll, act_ReturnFirst, act_Sum, etc)

};

// IntegerNode is for conditions for types stored as integers in a tightdb::Array (int, date, bool).
//
// We don't yet have any integer indexes (only for strings), but when we get one, we should specialize it
// like: template <class TConditionValue, class Equal> class IntegerNode: public ParentNode
template <class TConditionValue, class TConditionFunction> class IntegerNode: public IntegerNodeBase {
    typedef IntegerNode<TConditionValue, TConditionFunction> ThisType;
public:
    typedef typename ColumnTypeTraits<TConditionValue>::column_type ColType;

    // NOTE: Be careful to call Array(no_prealloc_tag) constructors on m_array in the initializer list, otherwise
    // their default constructors are called which are slow
    IntegerNode(TConditionValue v, size_t column) : m_value(v), m_find_callback_specialized(NULL)
    {
        m_condition_column_idx = column;
    }
    ~IntegerNode() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    void init(const Table& table) TIGHTDB_OVERRIDE
    {
        m_dD = 100.0;
        m_condition_column = static_cast<const ColType*>(&get_column_base(table, m_condition_column_idx));
        m_table = &table;
        m_leaf_end = 0;
        if (m_child)
            m_child->init(table);
    }

    void aggregate_local_prepare(Action TAction, DataType col_id) TIGHTDB_OVERRIDE
    {
        m_fastmode_disabled = (col_id == type_Float || col_id == type_Double);
        m_TAction = TAction;

        if (TAction == act_ReturnFirst)
            m_find_callback_specialized = &ThisType::template find_callback_specialization<act_ReturnFirst, int64_t>;

        else if (TAction == act_Count)
            m_find_callback_specialized = & ThisType::template find_callback_specialization<act_Count, int64_t>;

        else if (TAction == act_Sum && col_id == type_Int)
            m_find_callback_specialized = & ThisType::template find_callback_specialization<act_Sum, int64_t>;
        else if (TAction == act_Sum && col_id == type_Float)
            m_find_callback_specialized = & ThisType::template find_callback_specialization<act_Sum, float>;
        else if (TAction == act_Sum && col_id == type_Double)
            m_find_callback_specialized = & ThisType::template find_callback_specialization<act_Sum, double>;

        else if (TAction == act_Max && col_id == type_Int)
            m_find_callback_specialized = & ThisType::template find_callback_specialization<act_Max, int64_t>;
        else if (TAction == act_Max && col_id == type_Float)
            m_find_callback_specialized = & ThisType::template find_callback_specialization<act_Max, float>;
        else if (TAction == act_Max && col_id == type_Double)
            m_find_callback_specialized = & ThisType::template find_callback_specialization<act_Max, double>;

        else if (TAction == act_Min && col_id == type_Int)
            m_find_callback_specialized = & ThisType::template find_callback_specialization<act_Min, int64_t>;
        else if (TAction == act_Min && col_id == type_Float)
            m_find_callback_specialized = & ThisType::template find_callback_specialization<act_Min, float>;
        else if (TAction == act_Min && col_id == type_Double)
            m_find_callback_specialized = & ThisType::template find_callback_specialization<act_Min, double>;

        else if (TAction == act_FindAll)
            m_find_callback_specialized = & ThisType::template find_callback_specialization<act_FindAll, int64_t>;

        else if (TAction == act_CallbackIdx)
            m_find_callback_specialized = & ThisType::template find_callback_specialization<act_CallbackIdx, int64_t>;

        else {
            TIGHTDB_ASSERT(false);
        }
    }

    template <Action TAction, class TSourceColumn>
    bool find_callback_specialization(size_t s, size_t end2)
    {
        bool cont = m_array.find<TConditionFunction, act_CallbackIdx>
            (m_value, s - m_leaf_start, end2, m_leaf_start, null_ptr,
             std::bind1st(std::mem_fun(&IntegerNodeBase::template match_callback<TAction, TSourceColumn>), this));
        return cont;
    }

    // FIXME: should be possible to move this up to IntegerNodeBase...
    size_t aggregate_local(QueryStateBase* st, size_t start, size_t end, size_t local_limit,
                           SequentialGetterBase* source_column) TIGHTDB_OVERRIDE
    {
        TIGHTDB_ASSERT(m_conds > 0);
        int c = TConditionFunction::condition;
        m_local_matches = 0;
        m_local_limit = local_limit;
        m_last_local_match = start - 1;
        m_state = st;

        // If there are no other nodes than us (m_conds == 1) AND the column used for our condition is
        // the same as the column used for the aggregate action, then the entire query can run within scope of that
        // column only, with no references to other columns:
        bool fastmode = (m_conds == 1 &&
                         (source_column == null_ptr ||
                          (!m_fastmode_disabled
                           && static_cast<SequentialGetter<int64_t>*>(source_column)->m_column == m_condition_column)));
        for (size_t s = start; s < end; ) {
            // Cache internal leaves
            if (s >= m_leaf_end || s < m_leaf_start) {
                m_condition_column->GetBlock(s, m_array, m_leaf_start);
                m_leaf_end = m_leaf_start + m_array.size();
                size_t w = m_array.get_width();
                m_dT = (w == 0 ? 1.0 / TIGHTDB_MAX_BPNODE_SIZE : w / float(bitwidth_time_unit));
            }

            size_t end2;
            if (end > m_leaf_end)
                end2 = m_leaf_end - m_leaf_start;
            else
                end2 = end - m_leaf_start;

            if (fastmode) {
                bool cont = m_array.find(c, m_TAction, m_value, s - m_leaf_start, end2, m_leaf_start, (QueryState<int64_t>*)st);
                if (!cont)
                    return not_found;
            }
            // Else, for each match in this node, call our IntegerNode::match_callback to test remaining nodes and/or extract
            // aggregate payload from aggregate column:
            else {
                m_source_column = source_column;
                bool cont = (this->* m_find_callback_specialized)(s, end2);
                if (!cont)
                    return not_found;
            }

            if (m_local_matches == m_local_limit)
                break;

            s = end2 + m_leaf_start;
        }

        if (m_local_matches == m_local_limit) {
            m_dD = (m_last_local_match + 1 - start) / (m_local_matches + 1.0);
            return m_last_local_match + 1;
        }
        else {
            m_dD = (end - start) / (m_local_matches + 1.0);
            return end;
        }
    }

    size_t find_first_local(size_t start, size_t end) TIGHTDB_OVERRIDE
    {
        TConditionFunction condition;
        TIGHTDB_ASSERT(m_table);

        while (start < end) {

            // Cache internal leaves
            if (start >= m_leaf_end || start < m_leaf_start) {
                m_condition_column->GetBlock(start, m_array, m_leaf_start);
                m_leaf_end = m_leaf_start + m_array.size();
            }

            // Do search directly on cached leaf array
            if (start + 1 == end) {
                if (condition(m_array.get(start - m_leaf_start), m_value))
                    return start;
                else
                    return not_found;
            }

            size_t end2;
            if (end > m_leaf_end)
                end2 = m_leaf_end - m_leaf_start;
            else
                end2 = end - m_leaf_start;

            size_t s = m_array.find_first<TConditionFunction>(m_value, start - m_leaf_start, end2);

            if (s == not_found) {
                start = m_leaf_end;
                continue;
            }
            else
                return s + m_leaf_start;
        }

        return not_found;
    }

    virtual ParentNode* clone()
    {
        return new IntegerNode<TConditionValue, TConditionFunction>(*this);
    }

    IntegerNode(const IntegerNode& from)
        : IntegerNodeBase(from)
    {
        m_value = from.m_value;
        m_condition_column = from.m_condition_column;
        m_find_callback_specialized = from.m_find_callback_specialized;
        m_child = from.m_child;
    }

    TConditionValue m_value;

protected:
    typedef bool (ThisType::* TFind_callback_specialised)(size_t, size_t);

    const ColType* m_condition_column;                // Column on which search criteria is applied
    TFind_callback_specialised m_find_callback_specialized;
};




// This node is currently used for floats and doubles only
template <class TConditionValue, class TConditionFunction> class FloatDoubleNode: public ParentNode {
public:
    typedef typename ColumnTypeTraits<TConditionValue>::column_type ColType;

    FloatDoubleNode(TConditionValue v, size_t column_ndx) : m_value(v)
    {
        m_condition_column_idx = column_ndx;
        m_child = 0;
        m_dT = 1.0;
    }
    ~FloatDoubleNode() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    void init(const Table& table) TIGHTDB_OVERRIDE
    {
        m_dD = 100.0;
        m_table = &table;
        m_condition_column.m_column = static_cast<const ColType*>(&get_column_base(table, m_condition_column_idx));
        m_condition_column.m_leaf_end = 0;

        if (m_child)
            m_child->init(table);
    }

    size_t find_first_local(size_t start, size_t end) TIGHTDB_OVERRIDE
    {
        TConditionFunction cond;

        for (size_t s = start; s < end; ++s) {
            TConditionValue v = m_condition_column.get_next(s);
            if (cond(v, m_value))
                return s;
        }
        return not_found;
    }


    virtual ParentNode* clone()
    {
        return new FloatDoubleNode(*this);
    }

    FloatDoubleNode(const FloatDoubleNode& from)
        : ParentNode(from)
    {
        m_value = from.m_value;
        m_child = from.m_child;
        // m_condition_column is not copied
    }

protected:
    TConditionValue m_value;
    SequentialGetter<TConditionValue> m_condition_column;
};


template <class TConditionFunction> class BinaryNode: public ParentNode {
public:
    template <Action TAction> int64_t find_all(Column* /*res*/, size_t /*start*/, size_t /*end*/, size_t /*limit*/, size_t /*source_column*/) {TIGHTDB_ASSERT(false); return 0;}

    BinaryNode(BinaryData v, size_t column)
    {
        m_dT = 100.0;
        m_condition_column_idx = column;
        m_child = 0;

        // FIXME: Store this in std::string instead.
        char* data = new char[v.size()];
        memcpy(data, v.data(), v.size());
        m_value = BinaryData(data, v.size());
    }

    ~BinaryNode() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE
    {
        delete[] m_value.data();
    }

    void init(const Table& table) TIGHTDB_OVERRIDE
    {
        m_dD = 100.0;
        m_table = &table;
        m_condition_column = static_cast<const ColumnBinary*>(&get_column_base(table, m_condition_column_idx));
        m_column_type = get_real_column_type(table, m_condition_column_idx);

        if (m_child)
            m_child->init(table);
    }

    size_t find_first_local(size_t start, size_t end) TIGHTDB_OVERRIDE
    {
        TConditionFunction condition;
        for (size_t s = start; s < end; ++s) {
            BinaryData value = m_condition_column->get(s);
            if (condition(m_value, value))
                return s;
        }
        return not_found;
    }

    virtual ParentNode* clone()
    {
        return new BinaryNode(*this);
    }

    BinaryNode(const BinaryNode& from)
        : ParentNode(from)
    {
        // FIXME: Store this in std::string instead.
        char* data = new char[from.m_value.size()];
        memcpy(data, from.m_value.data(), from.m_value.size());
        m_value = BinaryData(data, from.m_value.size());
        m_condition_column = from.m_condition_column;
        m_column_type = from.m_column_type;
        m_child = from.m_child;
    }


protected:
private:
    BinaryData m_value;
protected:
    const ColumnBinary* m_condition_column;
    ColumnType m_column_type;
};


class StringNodeBase : public ParentNode {
public:
    template <Action TAction>
    int64_t find_all(Column*, size_t, size_t, size_t, size_t)
    {
        TIGHTDB_ASSERT(false);
        return 0;
    }
    StringNodeBase(StringData v, size_t column)
    {
        m_condition_column_idx = column;
        m_child = 0;
        m_dT = 10.0;
        m_leaf = null_ptr;

        // FIXME: Store these in std::string instead.
        // '*6' because case converted strings can take up more space. Todo, investigate
        char* data = new char[6 * v.size()]; // FIXME: Arithmetic is prone to overflow
        memcpy(data, v.data(), v.size());
        m_value = StringData(data, v.size());
    }

    ~StringNodeBase() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE
    {
        delete[] m_value.data();
    }

    void init(const Table& table) TIGHTDB_OVERRIDE
    {
        m_probes = 0;
        m_matches = 0;
        m_end_s = 0;
        m_leaf = 0;
        m_leaf_start = 0;
        m_leaf_end = 0;
        m_table = &table;
        m_condition_column = &get_column_base(table, m_condition_column_idx);
        m_column_type = get_real_column_type(table, m_condition_column_idx);
    }

    void clear_leaf_state()
    {
        if (!m_leaf)
            return;

        switch (m_leaf_type) {
            case AdaptiveStringColumn::leaf_type_Small:
                delete static_cast<ArrayString*>(m_leaf);
                goto delete_done;
            case AdaptiveStringColumn::leaf_type_Medium:
                delete static_cast<ArrayStringLong*>(m_leaf);
                goto delete_done;
            case AdaptiveStringColumn::leaf_type_Big:
                delete static_cast<ArrayBigBlobs*>(m_leaf);
                goto delete_done;
        }
        TIGHTDB_ASSERT(false);

      delete_done:
        m_leaf = 0;
    }

    StringNodeBase(const StringNodeBase& from) 
        : ParentNode(from)
    {
        char* data = new char[from.m_value.size()];
        memcpy(data, from.m_value.data(), from.m_value.size());
        m_value = StringData(data, from.m_value.size());
        m_condition_column = from.m_condition_column;
        m_column_type = from.m_column_type;
        m_leaf = 0;
        m_leaf_type = from.m_leaf_type;
        m_end_s = 0;
        m_leaf_start = 0;
        m_child = from.m_child;
    }

protected:
    StringData m_value;

    const ColumnBase* m_condition_column;
    ColumnType m_column_type;

    // Used for linear scan through short/long-string
    ArrayParent *m_leaf;
    AdaptiveStringColumn::LeafType m_leaf_type;
    size_t m_end_s;
    size_t m_leaf_start;
    size_t m_leaf_end;

};

// Conditions for strings. Note that Equal is specialized later in this file!
template <class TConditionFunction> class StringNode: public StringNodeBase {
public:
    StringNode(StringData v, size_t column) : StringNodeBase(v,column)
    {
        char* upper = new char[6 * v.size()];
        char* lower = new char[6 * v.size()];

        bool b1 = case_map(v, lower, false);
        bool b2 = case_map(v, upper, true);
        if (!b1 || !b2)
            error_code = "Malformed UTF-8: " + std::string(v);

        m_ucase = upper;
        m_lcase = lower;
    }

    ~StringNode() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE
    {
        delete[] m_ucase;
        delete[] m_lcase;

        clear_leaf_state();
    }


    void init(const Table& table) TIGHTDB_OVERRIDE
    {
        clear_leaf_state();

        m_dD = 100.0;

        StringNodeBase::init(table);

        if (m_child)
            m_child->init(table);
    }


    size_t find_first_local(size_t start, size_t end) TIGHTDB_OVERRIDE
    {
        TConditionFunction cond;

        for (size_t s = start; s < end; ++s) {
            StringData t;

            if (m_column_type == col_type_StringEnum) {
                // enum
                t = static_cast<const ColumnStringEnum*>(m_condition_column)->get(s);
            }
            else {
                // short or long
                const AdaptiveStringColumn* asc = static_cast<const AdaptiveStringColumn*>(m_condition_column);
                if (s >= m_end_s || s < m_leaf_start) {
                    // we exceeded current leaf's range
                    clear_leaf_state();

                    m_leaf_type = asc->GetBlock(s, &m_leaf, m_leaf_start);
                    if (m_leaf_type == AdaptiveStringColumn::leaf_type_Small)
                        m_end_s = m_leaf_start + static_cast<ArrayString*>(m_leaf)->size();
                    else if (m_leaf_type ==  AdaptiveStringColumn::leaf_type_Medium)
                        m_end_s = m_leaf_start + static_cast<ArrayStringLong*>(m_leaf)->size();
                    else
                        m_end_s = m_leaf_start + static_cast<ArrayBigBlobs*>(m_leaf)->size();
                }

                if (m_leaf_type == AdaptiveStringColumn::leaf_type_Small)
                    t = static_cast<ArrayString*>(m_leaf)->get(s - m_leaf_start);
                else if (m_leaf_type ==  AdaptiveStringColumn::leaf_type_Medium)
                    t = static_cast<ArrayStringLong*>(m_leaf)->get(s - m_leaf_start);
                else
                    t = static_cast<ArrayBigBlobs*>(m_leaf)->get_string(s - m_leaf_start);
            }
            if (cond(m_value, m_ucase, m_lcase, t))
                return s;
        }
        return not_found;
    }

    virtual ParentNode* clone()
    {
        return new StringNode<TConditionFunction>(*this);
    }

    StringNode(const StringNode& from) : StringNodeBase(from)
    {
        size_t sz = 6 * m_value.size();
        char* lcase = new char[sz];
        char* ucase = new char[sz];
        memcpy(lcase, from.m_lcase, sz);
        memcpy(ucase, from.m_ucase, sz);
        m_lcase = lcase;
        m_ucase = ucase;
        m_child = from.m_child;
    }
protected:
    const char* m_lcase;
    const char* m_ucase;
};



// Specialization for Equal condition on Strings - we specialize because we can utilize indexes (if they exist) for Equal.
// Future optimization: make specialization for greater, notequal, etc
template<> class StringNode<Equal>: public StringNodeBase {
public:
    StringNode(StringData v, size_t column): StringNodeBase(v,column), m_key_ndx(size_t(-1))
    {
        m_index_getter = 0;
        m_index_matches = 0;
        m_index_matches_destroy = false;
    }
    ~StringNode() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE
    {
        deallocate();
    }

    void deallocate() TIGHTDB_NOEXCEPT
    {
        // Must be called after each query execution too free temporary resources used by the execution. Run in
        // destructor, but also in Init because a user could define a query once and execute it multiple times.
        clear_leaf_state();

        if (m_index_matches_destroy)
            m_index_matches->destroy();

        m_index_matches_destroy = false;

        delete m_index_matches;
        m_index_matches = null_ptr;

        delete m_index_getter;
        m_index_getter = null_ptr;
    }

    void init(const Table& table) TIGHTDB_OVERRIDE
    {
        deallocate();
        m_dD = 10.0;
        StringNodeBase::init(table);

        if (m_column_type == col_type_StringEnum) {
            m_dT = 1.0;
            m_key_ndx = ((const ColumnStringEnum*)m_condition_column)->GetKeyNdx(m_value);
        }
        else if (m_condition_column->has_search_index()) {
            m_dT = 0.0;
        }
        else {
            m_dT = 10.0;
        }

        if (m_condition_column->has_search_index()) {

            FindRes fr;
            size_t index_ref;

            if (m_column_type == col_type_StringEnum) {
                fr = static_cast<const ColumnStringEnum*>(m_condition_column)->find_all_indexref(m_value, index_ref);
            }
            else {
                fr = static_cast<const AdaptiveStringColumn*>(m_condition_column)->find_all_indexref(m_value, index_ref);
            }

            m_index_matches_destroy = false;
            if (fr == FindRes_single) {
                m_index_matches = new Column(Column::unattached_root_tag(), Allocator::get_default()); // Throws
                m_index_matches->get_root_array()->create(Array::type_Normal); // Throws
                m_index_matches->add(index_ref);
                m_index_matches_destroy = true;        // we own m_index_matches, so we must destroy it
            }
            else if (fr == FindRes_column) {
                // todo: Apparently we can't use m_index.get_alloc() because it uses default allocator which simply makes
                // translate(x) = x. Shouldn't it inherit owner column's allocator?!
                m_index_matches = new Column(Column::unattached_root_tag(), m_condition_column->get_alloc()); // Throws
                m_index_matches->get_root_array()->init_from_ref(index_ref);
            }
            else if (fr == FindRes_not_found) {
                m_index_matches = new Column(Column::unattached_root_tag(), Allocator::get_default()); // Throws
                m_index_matches->get_root_array()->create(Array::type_Normal); // Throws
                m_index_matches_destroy = true;        // we own m_index_matches, so we must destroy it
            }

            last_indexed = 0;

            m_index_getter = new SequentialGetter<int64_t>(m_index_matches);
            m_index_size = m_index_getter->m_column->size();

        }
        else if (m_column_type != col_type_String) {
            m_cse.m_column = static_cast<const ColumnStringEnum*>(m_condition_column);
            m_cse.m_leaf_end = 0;
            m_cse.m_leaf_start = 0;
        }

        if (m_child)
            m_child->init(table);
    }

    size_t find_first_local(size_t start, size_t end) TIGHTDB_OVERRIDE
    {
        TIGHTDB_ASSERT(m_table);

        for (size_t s = start; s < end; ++s) {
            if (m_condition_column->has_search_index()) {

                // Indexed string column
                size_t f = not_found;

                while (f == not_found && last_indexed < m_index_size) {
                    m_index_getter->cache_next(last_indexed);
                    f = m_index_getter->m_array_ptr->FindGTE(s, last_indexed - m_index_getter->m_leaf_start, null_ptr);

                    if (f >= end || f == not_found) {
                        last_indexed = m_index_getter->m_leaf_end;
                    }
                    else {
                        s = to_size_t(m_index_getter->m_array_ptr->get(f));
                        if (s >= end)
                            return not_found;
                        else {
                            last_indexed = f + m_index_getter->m_leaf_start;
                            return s;
                        }
                    }
                }
                return not_found;
            }
            else {
                if (m_column_type != col_type_String) {

                    // Enum string column
                    if (m_key_ndx == not_found)
                        s = end; // not in key set
                    else {
                        m_cse.cache_next(s);
                        s = m_cse.m_array_ptr->find_first(m_key_ndx, s - m_cse.m_leaf_start, m_cse.local_end(end));
                        if (s == not_found)
                            s = m_cse.m_leaf_end - 1;
                        else
                            return s + m_cse.m_leaf_start;
                    }
                }
                else {

                    // Normal string column, with long or short leaf
                    AdaptiveStringColumn* asc = (AdaptiveStringColumn*)m_condition_column;
                    if (s >= m_leaf_end || s < m_leaf_start) {
                        clear_leaf_state();
                        m_leaf_type = asc->GetBlock(s, &m_leaf, m_leaf_start);
                        if (m_leaf_type == AdaptiveStringColumn::leaf_type_Small)
                            m_leaf_end = m_leaf_start + static_cast<ArrayString*>(m_leaf)->size();
                        else if (m_leaf_type ==  AdaptiveStringColumn::leaf_type_Medium)
                            m_leaf_end = m_leaf_start + static_cast<ArrayStringLong*>(m_leaf)->size();
                        else
                            m_leaf_end = m_leaf_start + static_cast<ArrayBigBlobs*>(m_leaf)->size();
                        TIGHTDB_ASSERT(m_leaf);
                    }
                    size_t end2 = (end > m_leaf_end ? m_leaf_end - m_leaf_start : end - m_leaf_start);

                    if (m_leaf_type == AdaptiveStringColumn::leaf_type_Small)
                        s = static_cast<ArrayString*>(m_leaf)->find_first(m_value, s - m_leaf_start, end2);
                    else if (m_leaf_type ==  AdaptiveStringColumn::leaf_type_Medium)
                        s = static_cast<ArrayStringLong*>(m_leaf)->find_first(m_value, s - m_leaf_start, end2);
                    else
                        s = static_cast<ArrayBigBlobs*>(m_leaf)->find_first(str_to_bin(m_value), true, s - m_leaf_start, end2);

                    if (s == not_found)
                        s = m_leaf_end - 1;
                    else
                        return s + m_leaf_start;
                }
            }
        }
        return not_found;
    }

public:
    virtual ParentNode* clone()
    {
        return new StringNode<Equal>(*this);
    }

    StringNode(const StringNode& from) : StringNodeBase(from)
    {
        m_index_getter = 0;
        m_index_matches = 0;
        m_index_matches_destroy = false;
    }

private:
    inline BinaryData str_to_bin(const StringData& s) TIGHTDB_NOEXCEPT
    {
        return BinaryData(s.data(), s.size());
    }

    size_t m_key_ndx;
    size_t last_indexed;

    // Used for linear scan through enum-string
    SequentialGetter<int64_t> m_cse;

    // Used for index lookup
    Column* m_index_matches;
    bool m_index_matches_destroy;
    SequentialGetter<int64_t>* m_index_getter;
    size_t m_index_size;
};

// OR node contains at least two node pointers: Two or more conditions to OR
// together in m_cond, and the next AND condition (if any) in m_child.
//
// For 'second.equal(23).begin_group().first.equal(111).Or().first.equal(222).end_group().third().equal(555)', this
// will first set m_cond[0] = left-hand-side through constructor, and then later, when .first.equal(222) is invoked,
// invocation will set m_cond[1] = right-hand-side through Query& Query::Or() (see query.cpp). In there, m_child is
// also set to next AND condition (if any exists) following the OR.
class OrNode: public ParentNode {
public:
    template <Action TAction> int64_t find_all(Column*, size_t, size_t, size_t, size_t)
    {
        TIGHTDB_ASSERT(false);
        return 0;
    }

    OrNode(ParentNode* p1) : m_cond(1, p1) {
        m_child = null_ptr;
        m_dT = 50.0;
    }

    ~OrNode() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    void init(const Table& table) TIGHTDB_OVERRIDE
    {
        m_dD = 10.0;

        std::vector<ParentNode*> v;

        m_last.clear();
        m_last.resize(m_cond.size(), 0);

        m_was_match.clear();
        m_was_match.resize(m_cond.size(), false);

        for (size_t c = 0; c < m_cond.size(); ++c) {
            m_cond[c]->init(table);
            v.clear();
            m_cond[c]->gather_children(v);
        }

        if (m_child)
            m_child->init(table);

        m_table = &table;
    }

    size_t find_first_local(size_t start, size_t end) TIGHTDB_OVERRIDE
    {
        if (start >= end)
            return not_found;

        size_t index = not_found;

        for (size_t c = 0; c < m_cond.size(); ++c) {
            if (m_last[c] >= end)
                continue;
            else if (m_was_match[c] && m_last[c] >= start) {
                if (index > m_last[c])
                    index = m_last[c];
            }
            else {
                size_t fmax = m_last[c] > start ? m_last[c] : start;
                size_t f = m_cond[c]->find_first(fmax, end);
                m_was_match[c] = f != not_found;
                m_last[c] = f == not_found ? end : f;
                if (f != not_found && index > m_last[c])
                    index = m_last[c];
            }
        }

        return index;
    }

    std::string validate() TIGHTDB_OVERRIDE
    {
        if (error_code != "")
            return error_code;
        if (m_cond[0] == 0)
            return "Missing left-hand side of OR";
        if (m_cond.back() == 0)
            return "Missing final right-hand side of OR";
        std::string s;
        if (m_child != 0)
            s = m_child->validate();
        if (s != "")
            return s;
        for (size_t i = 0; i < m_cond.size(); ++i) {
            s = m_cond[i]->validate();
            if (s != "")
                return s;
        }
        return "";
    }

    virtual ParentNode* clone()
    {
        return new OrNode(*this);
    }

    virtual void translate_pointers(const std::map<ParentNode*, ParentNode*>& mapping) TIGHTDB_OVERRIDE
    {
        ParentNode::translate_pointers(mapping);
        for (size_t i = 0; i < m_cond.size(); ++i)
            m_cond[i] = mapping.find(m_cond[i])->second;
    }

    std::vector<ParentNode*> m_cond;
private:
    std::vector<size_t> m_last;
    std::vector<bool> m_was_match;
};



class NotNode: public ParentNode {
public:
    template <Action TAction> int64_t find_all(Column*, size_t, size_t, size_t, size_t)
    {
        TIGHTDB_ASSERT(false);
        return 0;
    }

    NotNode() {m_child = null_ptr; m_cond = null_ptr; m_dT = 50.0;}
    ~NotNode() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    void init(const Table& table) TIGHTDB_OVERRIDE
    {
        m_dD = 10.0;

        std::vector<ParentNode*> v;

        m_cond->init(table);
        v.clear();
        m_cond->gather_children(v);
        m_last = 0;
        m_was_match = false;

        if (m_child)
            m_child->init(table);

        m_table = &table;
    }

    size_t find_first_local(size_t start, size_t end) TIGHTDB_OVERRIDE
    {
        for (size_t s = start; s < end; ++s) {

            size_t f;

            if (m_last >= end)
                f = end;
            else if (m_was_match && m_last >= s)
                f = m_last;
            else {
                size_t fmax = m_last > s ? m_last : s;
                for (f = fmax; f < end; f++) {
                    if (m_cond->find_first(f,f+1)==not_found) {
                        m_was_match = true;
                        m_last = f;
                        return f;
                    }
                }
                // ID: f = m_cond->find_first(fmax, end);
                m_was_match = false;
                m_last = end;
                f = end;
            }

            s = f;
            s = s >= end ? not_found : s;

            return s;
        }
        return not_found;
    }

    std::string validate() TIGHTDB_OVERRIDE
    {
        if (error_code != "")
            return error_code;
        if (m_cond == 0)
            return "Missing argument to Not";
        std::string s;
        if (m_child != 0)
            s = m_child->validate();
        if (s != "")
            return s;
        s = m_cond->validate();
        if (s != "")
            return s;
        return "";
    }

    virtual ParentNode* clone()
    {
        return new NotNode(*this);
    }

    virtual void translate_pointers(const std::map<ParentNode*, ParentNode*>& mapping) TIGHTDB_OVERRIDE
    {
        ParentNode::translate_pointers(mapping);
        m_cond = mapping.find(m_cond)->second;
    }

    NotNode(const NotNode& from) 
        : ParentNode(from)
    {
        // here we are just copying the pointers - they'll be remapped by "translate_pointers"
        m_cond = from.m_cond;
        m_last = from.m_last;
        m_was_match = from.m_was_match;
        m_child = from.m_child;
    }

    ParentNode* m_cond;
private:
    size_t m_last;
    bool m_was_match;
};


// Compare two columns with eachother row-by-row
template <class TConditionValue, class TConditionFunction> class TwoColumnsNode: public ParentNode {
public:
    template <Action TAction> int64_t find_all(Column* /*res*/, size_t /*start*/, size_t /*end*/, size_t /*limit*/, size_t /*source_column*/) {TIGHTDB_ASSERT(false); return 0;}

    TwoColumnsNode(size_t column1, size_t column2)
    {
        m_dT = 100.0;
        m_condition_column_idx1 = column1;
        m_condition_column_idx2 = column2;
        m_child = 0;
    }

    ~TwoColumnsNode() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE
    {
        delete[] m_value.data();
    }

    void init(const Table& table) TIGHTDB_OVERRIDE
    {
        typedef typename ColumnTypeTraits<TConditionValue>::column_type ColType;
        m_dD = 100.0;
        m_table = &table;

        const ColType* c = static_cast<const ColType*>(&get_column_base(table, m_condition_column_idx1));
        m_getter1.init(c);

        c = static_cast<const ColType*>(&get_column_base(table, m_condition_column_idx2));
        m_getter2.init(c);

        if (m_child)
            m_child->init(table);
    }

    size_t find_first_local(size_t start, size_t end) TIGHTDB_OVERRIDE
    {
        size_t s = start;

        while (s < end) {
            if (util::SameType<TConditionValue, int64_t>::value) {
                // For int64_t we've created an array intrinsics named CompareLeafs which template expands bitwidths
                // of boths arrays to make Get faster.
                m_getter1.cache_next(s);
                m_getter2.cache_next(s);

                QueryState<int64_t> qs;
                bool resume = m_getter1.m_array_ptr->template CompareLeafs<TConditionFunction, act_ReturnFirst>(m_getter2.m_array_ptr, s - m_getter1.m_leaf_start, m_getter1.local_end(end), 0, &qs, CallbackDummy());

                if (resume)
                    s = m_getter1.m_leaf_end;
                else
                    return to_size_t(qs.m_state) + m_getter1.m_leaf_start;
            }
            else {
                // This is for float and double.

#if 0 && defined(TIGHTDB_COMPILER_AVX)
// AVX has been disabled because of array alignment (see https://app.asana.com/0/search/8836174089724/5763107052506)
//
// For AVX you can call things like if (sseavx<1>()) to test for AVX, and then utilize _mm256_movemask_ps (VC)
// or movemask_cmp_ps (gcc/clang)
//
// See https://github.com/rrrlasse/tightdb/tree/AVX for an example of utilizing AVX for a two-column search which has
// been benchmarked to: floats: 288 ms vs 552 by using AVX compared to 2-level-unrolled FPU loop. doubles: 415 ms vs
// 475 (more bandwidth bound). Tests against SSE have not been performed; AVX may not pay off. Please benchmark
#endif

                TConditionValue v1 = m_getter1.get_next(s);
                TConditionValue v2 = m_getter2.get_next(s);
                TConditionFunction C;

                if (C(v1, v2))
                    return s;
                else
                    s++;
            }
        }
        return not_found;
    }

    virtual ParentNode* clone()
    {
        return new TwoColumnsNode<TConditionValue, TConditionFunction>(*this);
    }

    TwoColumnsNode(const TwoColumnsNode& from)
        : ParentNode(from)
    {
        m_value = from.m_value;
        m_condition_column = from.m_condition_column;
        m_column_type = from.m_column_type;
        m_condition_column_idx1 = from.m_condition_column_idx1;
        m_condition_column_idx2 = from.m_condition_column_idx2;
        m_child = from.m_child;
        // NOT copied:
        // m_getter1 = from.m_getter1;
        // m_getter2 = from.m_getter2;
    }

protected:
    BinaryData m_value;
    const ColumnBinary* m_condition_column;
    ColumnType m_column_type;

    size_t m_condition_column_idx1;
    size_t m_condition_column_idx2;

    SequentialGetter<TConditionValue> m_getter1;
    SequentialGetter<TConditionValue> m_getter2;
};

// todo, fixme: move this up! There are just some annoying compiler errors that need to be resolved when doing this
#include "query_expression.hpp"


// For Next-Generation expressions like col1 / col2 + 123 > col4 * 100.
class ExpressionNode: public ParentNode {

public:
    ~ExpressionNode() TIGHTDB_NOEXCEPT { }

    ExpressionNode(Expression* compare, bool auto_delete)
    {
        m_auto_delete = auto_delete;
        m_child = 0;
        m_compare = util::SharedPtr<Expression>(compare);
        m_dD = 10.0;
        m_dT = 50.0;
    }

    void init(const Table& table)  TIGHTDB_OVERRIDE
    {
        m_compare->set_table();
        if (m_child)
            m_child->init(table);
    }

    size_t find_first_local(size_t start, size_t end) TIGHTDB_OVERRIDE
    {
        size_t res = m_compare->find_first(start, end);
        return res;
    }

    virtual ParentNode* clone()
    {
        return new ExpressionNode(*this);
    }

    ExpressionNode(ExpressionNode& from) 
        : ParentNode(from)
    {
        m_compare = from.m_compare;
        m_child = from.m_child;
    }

    bool m_auto_delete;
    util::SharedPtr<Expression> m_compare;
};


class LinksToNode : public ParentNode {
public:
    LinksToNode(size_t origin_column_index, size_t target_row) : m_origin_column(origin_column_index),
                                                                 m_target_row(target_row)
    {
        m_child = 0;
        m_dD = 10.0;
        m_dT = 50.0;
    }

    void init(const Table& table) TIGHTDB_OVERRIDE
    {
        m_table = &table;
        if (m_child)
            m_child->init(table);
    }

    size_t find_first_local(size_t start, size_t end) TIGHTDB_OVERRIDE
    {
        size_t ret = tightdb::npos; // superfluous init, but gives warnings otherwise
        DataType type = m_table->get_column_type(m_origin_column);

        if (type == type_Link) {
            ColumnLinkBase& clb = const_cast<Table*>(m_table)->get_column_link_base(m_origin_column);
            ColumnLink& cl = static_cast<ColumnLink&>(clb);
            ret = cl.find_first(m_target_row + 1, start); // ColumnLink stores link to row N as the integer N + 1
        }
        else if (type == type_LinkList) {
            ColumnLinkBase& clb = const_cast<Table*>(m_table)->get_column_link_base(m_origin_column);
            ColumnLinkList& cll = static_cast<ColumnLinkList&>(clb);
            for (size_t i = start; i < end; i++) {
                LinkViewRef lv = cll.get(i);
                ret = lv->find(m_target_row);
                if (ret != not_found)
                    return i;
            }
        }
        else {
            TIGHTDB_ASSERT(false);
        }

        return ret;
    }

    virtual ParentNode* clone()
    {
        return new LinksToNode(*this);
    }

    size_t m_origin_column;
    size_t m_target_row;
};


} // namespace tightdb

#endif // TIGHTDB_QUERY_ENGINE_HPP
