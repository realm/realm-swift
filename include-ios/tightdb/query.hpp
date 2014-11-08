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
#ifndef TIGHTDB_QUERY_HPP
#define TIGHTDB_QUERY_HPP

#include <stdint.h>
#include <cstdio>
#include <climits>
#include <algorithm>
#include <string>
#include <vector>

#define TIGHTDB_MULTITHREAD_QUERY 0

#if TIGHTDB_MULTITHREAD_QUERY
// FIXME: Use our C++ thread abstraction API since it provides a much
// higher level of encapsulation and safety.
#include <pthread.h>
#endif

#include <tightdb/views.hpp>
#include <tightdb/table_ref.hpp>
#include <tightdb/binary_data.hpp>
#include <tightdb/datetime.hpp>

namespace tightdb {


// Pre-declarations
class ParentNode;
class Table;
class TableView;
class TableViewBase;
class ConstTableView;
class Array;
class Expression;
class SequentialGetterBase;

class Query {
public:
    Query(const Table& table, RowIndexes* tv = null_ptr);
    Query(const Table& table, const LinkViewRef& lv);
    Query();
    Query(const Query& copy); // FIXME: Try to remove this
    struct TCopyExpressionTag {};
    Query(const Query& copy, const TCopyExpressionTag&);
    ~Query() TIGHTDB_NOEXCEPT;
    void move_assign(Query& query);

    Query& operator = (const Query& source);

    Query& expression(Expression* compare, bool auto_delete = false);
    Expression* get_expression();

    // Find links that point to a specific target row 

    // Find links that point to a specific target row 
    Query& links_to(size_t column_ndx, size_t target_row);

    // Conditions: int64_t
    Query& equal(size_t column_ndx, int64_t value);
    Query& not_equal(size_t column_ndx, int64_t value);
    Query& greater(size_t column_ndx, int64_t value);
    Query& greater_equal(size_t column_ndx, int64_t value);
    Query& less(size_t column_ndx, int64_t value);
    Query& less_equal(size_t column_ndx, int64_t value);
    Query& between(size_t column_ndx, int64_t from, int64_t to);

    // Conditions: int (we need those because conversion from '1234' is ambiguous with float/double)
    Query& equal(size_t column_ndx, int value);
    Query& not_equal(size_t column_ndx, int value);
    Query& greater(size_t column_ndx, int value);
    Query& greater_equal(size_t column_ndx, int value);
    Query& less(size_t column_ndx, int value);
    Query& less_equal(size_t column_ndx, int value);
    Query& between(size_t column_ndx, int from, int to);

    // Conditions: 2 int columns
    Query& equal_int(size_t column_ndx1, size_t column_ndx2);
    Query& not_equal_int(size_t column_ndx1, size_t column_ndx2);
    Query& greater_int(size_t column_ndx1, size_t column_ndx2);
    Query& less_int(size_t column_ndx1, size_t column_ndx2);
    Query& greater_equal_int(size_t column_ndx1, size_t column_ndx2);
    Query& less_equal_int(size_t column_ndx1, size_t column_ndx2);

    // Conditions: float
    Query& equal(size_t column_ndx, float value);
    Query& not_equal(size_t column_ndx, float value);
    Query& greater(size_t column_ndx, float value);
    Query& greater_equal(size_t column_ndx, float value);
    Query& less(size_t column_ndx, float value);
    Query& less_equal(size_t column_ndx, float value);
    Query& between(size_t column_ndx, float from, float to);

    // Conditions: 2 float columns
    Query& equal_float(size_t column_ndx1, size_t column_ndx2);
    Query& not_equal_float(size_t column_ndx1, size_t column_ndx2);
    Query& greater_float(size_t column_ndx1, size_t column_ndx2);
    Query& greater_equal_float(size_t column_ndx1, size_t column_ndx2);
    Query& less_float(size_t column_ndx1, size_t column_ndx2);
    Query& less_equal_float(size_t column_ndx1, size_t column_ndx2);

     // Conditions: double
    Query& equal(size_t column_ndx, double value);
    Query& not_equal(size_t column_ndx, double value);
    Query& greater(size_t column_ndx, double value);
    Query& greater_equal(size_t column_ndx, double value);
    Query& less(size_t column_ndx, double value);
    Query& less_equal(size_t column_ndx, double value);
    Query& between(size_t column_ndx, double from, double to);

    // Conditions: 2 double columns
    Query& equal_double(size_t column_ndx1, size_t column_ndx2);
    Query& not_equal_double(size_t column_ndx1, size_t column_ndx2);
    Query& greater_double(size_t column_ndx1, size_t column_ndx2);
    Query& greater_equal_double(size_t column_ndx1, size_t column_ndx2);
    Query& less_double(size_t column_ndx1, size_t column_ndx2);
    Query& less_equal_double(size_t column_ndx1, size_t column_ndx2);

    // Conditions: bool
    Query& equal(size_t column_ndx, bool value);

    // Conditions: date
    Query& equal_datetime(size_t column_ndx, DateTime value) { return equal(column_ndx, int64_t(value.get_datetime())); }
    Query& not_equal_datetime(size_t column_ndx, DateTime value) { return not_equal(column_ndx, int64_t(value.get_datetime())); }
    Query& greater_datetime(size_t column_ndx, DateTime value) { return greater(column_ndx, int64_t(value.get_datetime())); }
    Query& greater_equal_datetime(size_t column_ndx, DateTime value) { return greater_equal(column_ndx, int64_t(value.get_datetime())); }
    Query& less_datetime(size_t column_ndx, DateTime value) { return less(column_ndx, int64_t(value.get_datetime())); }
    Query& less_equal_datetime(size_t column_ndx, DateTime value) { return less_equal(column_ndx, int64_t(value.get_datetime())); }
    Query& between_datetime(size_t column_ndx, DateTime from, DateTime to) { return between(column_ndx, int64_t(from.get_datetime()), int64_t(to.get_datetime())); }

    // Conditions: strings

    Query& equal(size_t column_ndx, StringData value, bool case_sensitive=true);
    Query& not_equal(size_t column_ndx, StringData value, bool case_sensitive=true);
    Query& begins_with(size_t column_ndx, StringData value, bool case_sensitive=true);
    Query& ends_with(size_t column_ndx, StringData value, bool case_sensitive=true);
    Query& contains(size_t column_ndx, StringData value, bool case_sensitive=true);

    // These are shortcuts for equal(StringData(c_str)) and
    // not_equal(StringData(c_str)), and are needed to avoid unwanted
    // implicit conversion of char* to bool.
    Query& equal(size_t column_ndx, const char* c_str, bool case_sensitive=true);
    Query& not_equal(size_t column_ndx, const char* c_str, bool case_sensitive=true);

    // Conditions: binary data
    Query& equal(size_t column_ndx, BinaryData value);
    Query& not_equal(size_t column_ndx, BinaryData value);
    Query& begins_with(size_t column_ndx, BinaryData value);
    Query& ends_with(size_t column_ndx, BinaryData value);
    Query& contains(size_t column_ndx, BinaryData value);

    // Negation
    Query& Not();

    // Grouping
    Query& group();
    Query& end_group();
    Query& subtable(size_t column);
    Query& end_subtable();
    Query& Or();

    Query& and_query(Query q);
    Query operator||(Query q);
    Query operator&&(Query q);
    Query operator!();


    // Searching
    size_t         find(size_t begin_at_table_row=size_t(0));
    TableView      find_all(size_t start = 0, size_t end=size_t(-1), size_t limit = size_t(-1));
    ConstTableView find_all(size_t start = 0, size_t end=size_t(-1), size_t limit = size_t(-1)) const;

    // Aggregates
    size_t count(size_t start = 0, size_t end=size_t(-1), size_t limit = size_t(-1)) const;

    int64_t sum_int(size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1), 
                    size_t limit = size_t(-1)) const;

    double  average_int(size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1),
                        size_t limit = size_t(-1)) const;

    int64_t maximum_int(size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1), 
                        size_t limit = size_t(-1), size_t* return_ndx = 0) const;

    int64_t minimum_int(size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1), 
                        size_t limit = size_t(-1), size_t* return_ndx = 0) const;

    double sum_float(    size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1), 
                         size_t limit = size_t(-1)) const;

    double average_float(size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1), 
                         size_t limit = size_t(-1)) const;

    float  maximum_float(size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1),
                         size_t limit = size_t(-1), size_t* return_ndx = 0) const;

    float  minimum_float(size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1),
                         size_t limit = size_t(-1), size_t* return_ndx = 0) const;

    double sum_double(    size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1), 
                          size_t limit = size_t(-1)) const;

    double average_double(size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1), 
                          size_t limit = size_t(-1)) const;

    double maximum_double(size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1), 
                          size_t limit = size_t(-1), size_t* return_ndx = 0) const;

    double minimum_double(size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1), 
                          size_t limit = size_t(-1), size_t* return_ndx = 0) const;

    DateTime maximum_datetime(size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1),
                              size_t limit = size_t(-1), size_t* return_ndx = 0) const;

    DateTime minimum_datetime(size_t column_ndx, size_t* resultcount = 0, size_t start = 0, size_t end = size_t(-1), 
                              size_t limit = size_t(-1), size_t* return_ndx = 0) const;

    // Deletion
    size_t  remove(size_t start = 0, size_t end=size_t(-1), size_t limit = size_t(-1));

#if TIGHTDB_MULTITHREAD_QUERY
    // Multi-threading
    TableView      find_all_multi(size_t start = 0, size_t end=size_t(-1));
    ConstTableView find_all_multi(size_t start = 0, size_t end=size_t(-1)) const;
    int            set_threads(unsigned int threadcount);
#endif

    TableRef& get_table() {return m_table;}

    std::string validate();

    mutable bool do_delete;

protected:
    Query(Table& table, RowIndexes* tv = null_ptr);
//    Query(const Table& table); // FIXME: This constructor should not exist. We need a ConstQuery class.
    void Create();

    void   Init(const Table& table) const;
    bool   is_initialized() const;
    size_t FindInternal(size_t start = 0, size_t end=size_t(-1)) const;
    size_t peek_tableview(size_t tv_index) const;
    void   UpdatePointers(ParentNode* p, ParentNode** newnode);
    void HandlePendingNot();

    static bool  comp(const std::pair<size_t, size_t>& a, const std::pair<size_t, size_t>& b);

public:
    TableRef m_table;
    std::vector<ParentNode*> first;
    std::vector<ParentNode**> update;
    std::vector<ParentNode**> update_override;
    std::vector<ParentNode**> subtables;
    std::vector<ParentNode*> all_nodes;
    
    RowIndexes* m_view;
    std::vector<bool> pending_not;

private:
    template <class TColumnType> Query& equal(size_t column_ndx1, size_t column_ndx2);
    template <class TColumnType> Query& less(size_t column_ndx1, size_t column_ndx2);
    template <class TColumnType> Query& less_equal(size_t column_ndx1, size_t column_ndx2);
    template <class TColumnType> Query& greater(size_t column_ndx1, size_t column_ndx2);
    template <class TColumnType> Query& greater_equal(size_t column_ndx1, size_t column_ndx2);
    template <class TColumnType> Query& not_equal(size_t column_ndx1, size_t column_ndx2);

    template <typename T, class N> Query& add_condition(size_t column_ndx, T value);

    template<typename T> double average(size_t column_ndx, size_t* resultcount = 0, size_t start = 0,
                                        size_t end=size_t(-1), size_t limit = size_t(-1)) const;

    template <Action action, typename T, typename R, class ColClass>
        R aggregate(R (ColClass::*method)(size_t, size_t, size_t, size_t*) const,
                    size_t column_ndx, size_t* resultcount, size_t start, size_t end, size_t limit, 
                    size_t* return_ndx = null_ptr) const;

    void aggregate_internal(Action TAction, DataType TSourceColumn,
                            ParentNode* pn, QueryStateBase* st, 
                            size_t start, size_t end, SequentialGetterBase* source_column) const;

    void find_all(TableViewBase& tv, size_t start = 0, size_t end=size_t(-1), size_t limit = size_t(-1)) const;
    void delete_nodes() TIGHTDB_NOEXCEPT;

    std::string error_code;

    friend class Table;
    template <typename T> friend class BasicTable;
    friend class XQueryAccessorInt;
    friend class XQueryAccessorString;
    friend class TableViewBase;

    LinkViewRef m_source_link_view;
};

// Implementation:

inline Query& Query::equal(size_t column_ndx, const char* c_str, bool case_sensitive)
{
    return equal(column_ndx, StringData(c_str), case_sensitive);
}

inline Query& Query::not_equal(size_t column_ndx, const char* c_str, bool case_sensitive)
{
    return not_equal(column_ndx, StringData(c_str), case_sensitive);
}

} // namespace tightdb

#endif // TIGHTDB_QUERY_HPP
