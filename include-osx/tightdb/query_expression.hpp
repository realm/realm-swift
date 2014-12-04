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
This file lets you write queries in C++ syntax like: Expression* e = (first + 1 / second >= third + 12.3);

Type conversion/promotion semantics is the same as in the C++ expressions, e.g float + int > double == float +
(float)int > double.


Grammar:
-----------------------------------------------------------------------------------------------------------------------
    Expression:         Subexpr2<T>  Compare<Cond, T>  Subexpr2<T>
                        operator! Expression

    Subexpr2<T>:        Value<T>
                        Columns<T>
                        Subexpr2<T>  Operator<Oper<T>  Subexpr2<T>
                        power(Subexpr2<T>) // power(x) = x * x, as example of unary operator

    Value<T>:           T

    Operator<Oper<T>>:  +, -, *, /

    Compare<Cond, T>:   ==, !=, >=, <=, >, <

    T:                  bool, int, int64_t, float, double, StringData


Class diagram
-----------------------------------------------------------------------------------------------------------------------
Subexpr2
    void evaluate(size_t i, ValueBase* destination)

Compare: public Subexpr2
    size_t find_first(size_t start, size_t end)     // main method that executes query

    bool m_auto_delete
    Subexpr2& m_left;                               // left expression subtree
    Subexpr2& m_right;                              // right expression subtree

Operator: public Subexpr2
    void evaluate(size_t i, ValueBase* destination)
    bool m_auto_delete
    Subexpr2& m_left;                               // left expression subtree
    Subexpr2& m_right;                              // right expression subtree

Value<T>: public Subexpr2
    void evaluate(size_t i, ValueBase* destination)
    T m_v[8];

Columns<T>: public Subexpr2
    void evaluate(size_t i, ValueBase* destination)
    SequentialGetter<T> sg;                         // class bound to a column, lets you read values in a fast way
    Table* m_table;

class ColumnAccessor<>: public Columns<double>


Call diagram:
-----------------------------------------------------------------------------------------------------------------------
Example of 'table.first > 34.6 + table.second':

size_t Compare<Greater>::find_first()-------------+
         |                                        |
         |                                        |
         |                                        |
         +--> Columns<float>::evaluate()          +--------> Operator<Plus>::evaluate()
                                                                |               |
                                               Value<float>::evaluate()    Columns<float>::evaluate()

Operator, Value and Columns have an evaluate(size_t i, ValueBase* destination) method which returns a Value<T>
containing 8 values representing table rows i...i + 7.

So Value<T> contains 8 concecutive values and all operations are based on these chunks. This is
to save overhead by virtual calls needed for evaluating a query that has been dynamically constructed at runtime.


Memory allocation:
-----------------------------------------------------------------------------------------------------------------------
Operator and Compare contain a 'bool m_auto_delete' which tell if their subtrees were created by the query system or by the
end-user. If created by query system, they are deleted upon destructed of Operator and Compare.

Value and Columns given to Operator or Compare constructors are cloned with 'new' and hence deleted unconditionally
by query system.


Caveats, notes and todos
-----------------------------------------------------------------------------------------------------------------------
    * Perhaps disallow columns from two different tables in same expression
    * The name Columns (with s) an be confusing because we also have Column (without s)
    * Memory allocation: Maybe clone Compare and Operator to get rid of m_auto_delete. However, this might become
      bloated, with non-trivial copy constructors instead of defaults
    * Hack: In compare operator overloads (==, !=, >, etc), Compare class is returned as Query class, resulting in object
      slicing. Just be aware.
    * clone() some times new's, sometimes it just returns *this. Can be confusing. Rename method or copy always.
    * We have Columns::m_table, Query::m_table and ColumnAccessorBase::m_table that point at the same thing, even with
      ColumnAccessor<> extending Columns. So m_table is redundant, but this is in order to keep class dependencies and
      entanglement low so that the design is flexible (if you perhaps later want a Columns class that is not dependent
      on ColumnAccessor)
*/


#ifndef TIGHTDB_QUERY_EXPRESSION_HPP
#define TIGHTDB_QUERY_EXPRESSION_HPP

// Normally, if a next-generation-syntax condition is supported by the old query_engine.hpp, a query_engine node is
// created because it's faster (by a factor of 5 - 10). Because many of our existing next-generation-syntax unit
// unit tests are indeed simple enough to fallback to old query_engine, query_expression gets low test coverage. Undef
// flag to get higher query_expression test coverage. This is a good idea to try out each time you develop on/modify
// query_expression.

#define TIGHTDB_OLDQUERY_FALLBACK

// namespace tightdb {

template <class T> T minimum(T a, T b)
{
    return a < b ? a : b;
}

// FIXME, this needs to exist elsewhere
typedef int64_t             Int;
typedef bool                Bool;
typedef tightdb::DateTime   DateTime;
typedef float               Float;
typedef double              Double;
typedef tightdb::StringData String;


// Return StringData if either T or U is StringData, else return T. See description of usage in export2().
template<class T, class U> struct EitherIsString
{
    typedef T type;
};

template<class T> struct EitherIsString<T, StringData>
{
    typedef StringData type;
};

// Hack to avoid template instantiation errors. See create(). Todo, see if we can simplify OnlyNumberic and
// EitherIsString somehow
template<class T> struct OnlyNumeric
{
    static T get(T in) { return in; }
    typedef T type;
};

template<> struct OnlyNumeric<StringData>
{
    static int get(StringData in) { static_cast<void>(in); return 0; }
    typedef StringData type;
};


template<class T>struct Plus {
    T operator()(T v1, T v2) const { return v1 + v2; }
    typedef T type;
};

template<class T>struct Minus {
    T operator()(T v1, T v2) const { return v1 - v2; }
    typedef T type;
};

template<class T>struct Div {
    T operator()(T v1, T v2) const { return v1 / v2; }
    typedef T type;
};

template<class T>struct Mul {
    T operator()(T v1, T v2) const { return v1 * v2; }
    typedef T type;
};

// Unary operator
template<class T>struct Pow {
    T operator()(T v) const { return v * v; }
    typedef T type;
};

// Finds a common type for T1 and T2 according to C++ conversion/promotion in arithmetic (float + int => float, etc)
template<class T1, class T2,
    bool T1_is_int = std::numeric_limits<T1>::is_integer,
    bool T2_is_int = std::numeric_limits<T2>::is_integer,
    bool T1_is_widest = (sizeof(T1) > sizeof(T2)) > struct Common;
template<class T1, class T2, bool b> struct Common<T1, T2, b, b, true > {
    typedef T1 type;
};
template<class T1, class T2, bool b> struct Common<T1, T2, b, b, false> {
    typedef T2 type;
};
template<class T1, class T2, bool b> struct Common<T1, T2, false, true , b> {
    typedef T1 type;
};
template<class T1, class T2, bool b> struct Common<T1, T2, true , false, b> {
    typedef T2 type;
};


struct ValueBase
{
    static const size_t default_size = 8;
    virtual void export_bool(ValueBase& destination) const = 0;
    virtual void export_int(ValueBase& destination) const = 0;
    virtual void export_float(ValueBase& destination) const = 0;
    virtual void export_int64_t(ValueBase& destination) const = 0;
    virtual void export_double(ValueBase& destination) const = 0;
    virtual void export_StringData(ValueBase& destination) const = 0;
    virtual void import(const ValueBase& destination) = 0;

    // If true, all values in the class come from a link of a single field in the parent table (m_table). If
    // false, then values come from successive rows of m_table (query operations are operated on in bulks for speed)
    bool from_link;

    // Number of values stored in the class.
    size_t m_values;
};

class Expression : public Query
{
public:
    Expression() { }

    virtual size_t find_first(size_t start, size_t end) const = 0;
    virtual void set_table() = 0;
    virtual const Table* get_table() = 0;
    virtual ~Expression() {}
};

class Subexpr
{
public:
    virtual ~Subexpr() {}

    // todo, think about renaming, or actualy doing deep copy
    virtual Subexpr& clone()
    {
        return *this;
    }

    // Recursively set table pointers for all Columns object in the expression tree. Used for late binding of table
    virtual void set_table() {}

    // Recursively fetch tables of columns in expression tree. Used when user first builds a stand-alone expression and
    // binds it to a Query at a later time
    virtual const Table* get_table()
    {
        return null_ptr;
    }

    virtual void evaluate(size_t index, ValueBase& destination) = 0;
};

class ColumnsBase {};

template <class T> class Columns;
template <class T> class Value;
template <class T> class Subexpr2;
template <class oper, class TLeft = Subexpr, class TRight = Subexpr> class Operator;
template <class oper, class TLeft = Subexpr> class UnaryOperator;
template <class TCond, class T, class TLeft = Subexpr, class TRight = Subexpr> class Compare;
class UnaryLinkCompare;
class ColumnAccessorBase;


// Handle cases where left side is a constant (int, float, int64_t, double, StringData)
template <class L, class Cond, class R> Query create (L left, const Subexpr2<R>& right)
{
    // Purpose of below code is to intercept the creation of a condition and test if it's supported by the old
    // query_engine.hpp which is faster. If it's supported, create a query_engine.hpp node, otherwise create a
    // query_expression.hpp node.
    //
    // This method intercepts only Value <cond> Subexpr2. Interception of Subexpr2 <cond> Subexpr is elsewhere.

#ifdef TIGHTDB_OLDQUERY_FALLBACK // if not defined, then never fallback to query_engine.hpp; always use query_expression
    OnlyNumeric<L> num;
    static_cast<void>(num);

    const Columns<R>* column = dynamic_cast<const Columns<R>*>(&right);
    if (column && (std::numeric_limits<L>::is_integer) && (std::numeric_limits<R>::is_integer) &&
        !column->m_link_map.m_table) {
        const Table* t = (const_cast<Columns<R>*>(column))->get_table();
        Query q = Query(*t);

        if (util::SameType<Cond, Less>::value)
            q.greater(column->m_column, num.get(left));
        else if (util::SameType<Cond, Greater>::value)
            q.less(column->m_column, num.get(left));
        else if (util::SameType<Cond, Equal>::value)
            q.equal(column->m_column, num.get(left));
        else if (util::SameType<Cond, NotEqual>::value)
            q.not_equal(column->m_column, num.get(left));
        else if (util::SameType<Cond, LessEqual>::value)
            q.greater_equal(column->m_column, num.get(left));
        else if (util::SameType<Cond, GreaterEqual>::value)
            q.less_equal(column->m_column, num.get(left));
        else {
            // query_engine.hpp does not support this Cond. Please either add support for it in query_engine.hpp or
            // fallback to using use 'return *new Compare<>' instead.
            TIGHTDB_ASSERT(false);
        }
        // Return query_engine.hpp node
        return q;
    }
    else
#endif
    {
        // Return query_expression.hpp node
        return *new Compare<Cond, typename Common<L, R>::type>(*new Value<L>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
    }
}


// All overloads where left-hand-side is Subexpr2<L>:
//
// left-hand-side       operator                              right-hand-side
// Subexpr2<L>          +, -, *, /, <, >, ==, !=, <=, >=      R, Subexpr2<R>
//
// For L = R = {int, int64_t, float, double, StringData}:
template <class L, class R> class Overloads
{
    typedef typename Common<L, R>::type CommonType;
public:

    // Arithmetic, right side constant
    Operator<Plus<CommonType> >& operator + (R right)
    {
       return *new Operator<Plus<CommonType> >(static_cast<Subexpr2<L>&>(*this).clone(), *new Value<R>(right), true);
    }
    Operator<Minus<CommonType> >& operator - (R right)
    {
       return *new Operator<Minus<CommonType> > (static_cast<Subexpr2<L>&>(*this).clone(), *new Value<R>(right), true);
    }
    Operator<Mul<CommonType> >& operator * (R right)
    {
       return *new Operator<Mul<CommonType> > (static_cast<Subexpr2<L>&>(*this).clone(), *new Value<R>(right), true);
    }
    Operator<Div<CommonType> >& operator / (R right)
    {
        return *new Operator<Div<CommonType> > (static_cast<Subexpr2<L>&>(*this).clone(), *new Value<R>(right), true);
    }

    // Arithmetic, right side subexpression
    Operator<Plus<CommonType> >& operator + (const Subexpr2<R>& right)
    {
        return *new Operator<Plus<CommonType> > (static_cast<Subexpr2<L>&>(*this).clone(), const_cast<Subexpr2<R>&>(right).clone(), true);
    }
    Operator<Minus<CommonType> >& operator - (const Subexpr2<R>& right)
    {
        return *new Operator<Minus<CommonType> > (static_cast<Subexpr2<L>&>(*this).clone(), const_cast<Subexpr2<R>&>(right).clone(), true);
    }
    Operator<Mul<CommonType> >& operator * (const Subexpr2<R>& right)
    {
        return *new Operator<Mul<CommonType> > (static_cast<Subexpr2<L>&>(*this).clone(), const_cast<Subexpr2<R>&>(right).clone(), true);
    }
    Operator<Div<CommonType> >& operator / (const Subexpr2<R>& right)
    {
        return *new Operator<Div<CommonType> > (static_cast<Subexpr2<L>&>(*this).clone(), const_cast<Subexpr2<R>&>(right).clone(), true);
    }

    // Compare, right side constant
    Query operator > (R right)
    {
        return create<R, Less, L>(right, static_cast<Subexpr2<L>&>(*this));
    }
    Query operator < (R right)
    {
        return create<R, Greater, L>(right, static_cast<Subexpr2<L>&>(*this));
    }
    Query operator >= (R right)
    {
        return create<R, LessEqual, L>(right, static_cast<Subexpr2<L>&>(*this));
    }
    Query operator <= (R right)
    {
        return create<R, GreaterEqual, L>(right, static_cast<Subexpr2<L>&>(*this));
    }
    Query operator == (R right)
    {
        return create<R, Equal, L>(right, static_cast<Subexpr2<L>&>(*this));
    }
    Query operator != (R right)
    {
        return create<R, NotEqual, L>(right, static_cast<Subexpr2<L>&>(*this));
    }

    // Purpose of this method is to intercept the creation of a condition and test if it's supported by the old
    // query_engine.hpp which is faster. If it's supported, create a query_engine.hpp node, otherwise create a
    // query_expression.hpp node.
    //
    // This method intercepts Subexpr2 <cond> Subexpr2 only. Value <cond> Subexpr2 is intercepted elsewhere.
    template <class Cond> Query create2 (const Subexpr2<R>& right)
    {
#ifdef TIGHTDB_OLDQUERY_FALLBACK // if not defined, never fallback query_engine; always use query_expression
        // Test if expressions are of type Columns. Other possibilities are Value and Operator.
        const Columns<R>* left_col = dynamic_cast<const Columns<R>*>(static_cast<Subexpr2<L>*>(this));
        const Columns<R>* right_col = dynamic_cast<const Columns<R>*>(&right);

        // query_engine supports 'T-column <op> <T-column>' for T = {int64_t, float, double}, op = {<, >, ==, !=, <=, >=}
        if (left_col && right_col && util::SameType<L, R>::value) {
            const Table* t = (const_cast<Columns<R>*>(left_col))->get_table();
            Query q = Query(*t);

            if (std::numeric_limits<L>::is_integer || util::SameType<L, DateTime>::value) {
                if (util::SameType<Cond, Less>::value)
                    q.less_int(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, Greater>::value)
                    q.greater_int(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, Equal>::value)
                    q.equal_int(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, NotEqual>::value)
                    q.not_equal_int(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, LessEqual>::value)
                    q.less_equal_int(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, GreaterEqual>::value)
                    q.greater_equal_int(left_col->m_column, right_col->m_column);
                else {
                    TIGHTDB_ASSERT(false);
                }
            }
            else if (util::SameType<L, float>::value) {
                if (util::SameType<Cond, Less>::value)
                    q.less_float(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, Greater>::value)
                    q.greater_float(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, Equal>::value)
                    q.equal_float(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, NotEqual>::value)
                    q.not_equal_float(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, LessEqual>::value)
                    q.less_equal_float(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, GreaterEqual>::value)
                    q.greater_equal_float(left_col->m_column, right_col->m_column);
                else {
                    TIGHTDB_ASSERT(false);
                }
            }
            else if (util::SameType<L, double>::value) {
                if (util::SameType<Cond, Less>::value)
                    q.less_double(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, Greater>::value)
                    q.greater_double(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, Equal>::value)
                    q.equal_double(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, NotEqual>::value)
                    q.not_equal_double(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, LessEqual>::value)
                    q.less_equal_double(left_col->m_column, right_col->m_column);
                else if (util::SameType<Cond, GreaterEqual>::value)
                    q.greater_equal_double(left_col->m_column, right_col->m_column);
                else {
                    TIGHTDB_ASSERT(false);
                }
            }
            else {
                TIGHTDB_ASSERT(false);
            }
            // Return query_engine.hpp node
            return q;
        }
        else
#endif
        {
            // Return query_expression.hpp node
            return *new Compare<Cond, typename Common<R, float>::type>
                        (static_cast<Subexpr2<L>&>(*this).clone(), const_cast<Subexpr2<R>&>(right).clone(), true);
        }
    }

    // Compare, right side subexpression
    Query operator == (const Subexpr2<R>& right)
    {
        return create2<Equal>(right);
    }
    Query operator != (const Subexpr2<R>& right)
    {
        return create2<NotEqual>(right);
    }
    Query operator > (const Subexpr2<R>& right)
    {
        return create2<Greater>(right);
    }
    Query operator < (const Subexpr2<R>& right)
    {
        return create2<Less>(right);
    }
    Query operator >= (const Subexpr2<R>& right)
    {
        return create2<GreaterEqual>(right);
    }
    Query operator <= (const Subexpr2<R>& right)
    {
        return create2<LessEqual>(right);
    }
};

// With this wrapper class we can define just 20 overloads inside Overloads<L, R> instead of 5 * 20 = 100. Todo: We can
// consider if it's simpler/better to remove this class completely and just list all 100 overloads manually anyway.
template <class T> class Subexpr2 : public Subexpr, public Overloads<T, const char*>, public Overloads<T, int>, public
    Overloads<T, float>, public Overloads<T, double>, public Overloads<T, int64_t>, public Overloads<T, StringData>,
    public Overloads<T, bool>, public Overloads<T, DateTime>
{
public:
    virtual ~Subexpr2() {};

    #define TDB_U2(t, o) using Overloads<T, t>::operator o;
    #define TDB_U(o) TDB_U2(int, o) TDB_U2(float, o) TDB_U2(double, o) TDB_U2(int64_t, o) TDB_U2(StringData, o) TDB_U2(bool, o) TDB_U2(DateTime, o)
    TDB_U(+) TDB_U(-) TDB_U(*) TDB_U(/) TDB_U(>) TDB_U(<) TDB_U(==) TDB_U(!=) TDB_U(>=) TDB_U(<=)
};

// Stores N values of type T. Can also exchange data with other ValueBase of different types
template<class T> class Value : public ValueBase, public Subexpr2<T>
{
public:
    Value()
    {
        m_v = null_ptr;
        init(false, ValueBase::default_size, 0);
    }
    Value(T v)
    {
        m_v = null_ptr;
        init(false, ValueBase::default_size, v);
    }
    Value(bool link, size_t values)
    {
        m_v = null_ptr;
        init(link, values, 0);
    }

    Value(bool link, size_t values, T v)
    {
        m_v = null_ptr;
        init(link, values, v);
    }

    ~Value()
    {
        // If we store more than default_size elements then we used 'new', else we used m_cache
        if (m_values > ValueBase::default_size)
            delete[] m_v;
        m_v = null_ptr;
    }

    void init(bool link, size_t values, T v) {
        if (m_v) {
            // If we store more than default_size elements then we used 'new', else we used m_cache
            if (m_values > ValueBase::default_size)
                delete[] m_v;
            m_v = null_ptr;
        }
        ValueBase::from_link = link;
        ValueBase::m_values = values;
        if (m_values > 0) {
            // If we store more than default_size elements then use 'new', else use m_cache
            if (m_values > ValueBase::default_size)
                m_v = new T[m_values];
            else
                m_v = m_cache;
            std::fill(m_v, m_v + ValueBase::m_values, v);
        }
    }

    void evaluate(size_t, ValueBase& destination)
    {
        destination.import(*this);
    }

    template <class TOperator> TIGHTDB_FORCEINLINE void fun(const Value* left, const Value* right)
    {
        TOperator o;
        size_t vals = minimum(left->m_values, right->m_values);
        for (size_t t = 0; t < vals; t++)
            m_v[t] = o(left->m_v[t], right->m_v[t]);
    }

    template <class TOperator> TIGHTDB_FORCEINLINE void fun(const Value* value)
    {
        TOperator o;
        for (size_t t = 0; t < value->m_values; t++)
            m_v[t] = o(value->m_v[t]);
    }


    // Below import and export methods are for type conversion between float, double, int64_t, etc.
    template<class D> TIGHTDB_FORCEINLINE void export2(ValueBase& destination) const
    {
        // export2 is also instantiated for impossible conversions like T = StringData, D = int64_t. These are never
        // performed at runtime but still result in compiler errors. We therefore introduce EitherIsString which turns
        // both T and D into StringData if just one of them are
        typedef typename EitherIsString <D, T>::type dst_t;
        typedef typename EitherIsString <T, D>::type src_t;
        Value<dst_t>& d = static_cast<Value<dst_t>&>(destination);
        d.init(ValueBase::from_link, ValueBase::m_values, 0);
        for (size_t t = 0; t < ValueBase::m_values; t++) {
            src_t* source = reinterpret_cast<src_t*>(m_v);
            d.m_v[t] = static_cast<dst_t>(source[t]);
        }
    }

    TIGHTDB_FORCEINLINE void export_bool(ValueBase& destination) const
    {
        export2<bool>(destination);
    }

    TIGHTDB_FORCEINLINE void export_int64_t(ValueBase& destination) const
    {
        export2<int64_t>(destination);
    }

    TIGHTDB_FORCEINLINE void export_float(ValueBase& destination) const
    {
        export2<float>(destination);
    }

    TIGHTDB_FORCEINLINE void export_int(ValueBase& destination) const
    {
        export2<int>(destination);
    }

    TIGHTDB_FORCEINLINE void export_double(ValueBase& destination) const
    {
        export2<double>(destination);
    }
    TIGHTDB_FORCEINLINE void export_StringData(ValueBase& destination) const
    {
        export2<StringData>(destination); 
    }

    TIGHTDB_FORCEINLINE void import(const ValueBase& source)
    {
        if (util::SameType<T, int>::value)
            source.export_int(*this);
        else if (util::SameType<T, bool>::value)
            source.export_bool(*this);
        else if (util::SameType<T, float>::value)
            source.export_float(*this);
        else if (util::SameType<T, double>::value)
            source.export_double(*this);
        else if (util::SameType<T, int64_t>::value)
            source.export_int64_t(*this);
        else if (util::SameType<T, StringData>::value)
            source.export_StringData(*this);
        else
            TIGHTDB_ASSERT(false);
    }

    // Given a TCond (==, !=, >, <, >=, <=) and two Value<T>, return index of first match
    template <class TCond> TIGHTDB_FORCEINLINE static size_t compare(Value<T>* left, Value<T>* right)
    {
        TCond c;

        if (!left->from_link && !right->from_link) {
            // Compare values one-by-one (one value is one row; no links)
            size_t min = minimum(left->ValueBase::m_values, right->ValueBase::m_values);
            for (size_t m = 0; m < min; m++) {
                if (c(left->m_v[m], right->m_v[m]))
                    return m;
            }
        }
        else if (left->from_link && right->from_link) {
            // Many-to-many links not supported yet. Need to specify behaviour
            TIGHTDB_ASSERT(false);
        }
        else if (!left->from_link && right->from_link) {
            // Right values come from link. Left must come from single row. Semantics: Match if at least 1 
            // linked-to-value fulfills the condition
            TIGHTDB_ASSERT(left->m_values == 0 || left->m_values == ValueBase::default_size);
            for (size_t r = 0; r < right->ValueBase::m_values; r++) {
                if (c(left->m_v[0], right->m_v[r]))
                    return 0;
            }
        }
        else if (left->from_link && !right->from_link) {
            // Same as above, right left values coming from links
            TIGHTDB_ASSERT(right->m_values == 0 || right->m_values == ValueBase::default_size);
            for (size_t l = 0; l < left->ValueBase::m_values; l++) {
                if (c(left->m_v[l], right->m_v[0]))
                    return 0;
            }
        }

        return not_found; // no match
    }

    virtual Subexpr& clone()
    {
        Value<T>& n = *new Value<T>();

        // Copy all members, except the m_v pointer which the above Value constructor allocated
        T* tmp = n.m_v;
        n = *this;
        n.m_v = tmp;

        // Copy payload
        memcpy(n.m_v, m_v, sizeof(T)* m_values);

        return n;
    }

    // Pointer to value payload
    T *m_v;

    // If there is less than default_size elements in payload, then use this cache, else use 'new'
    T m_cache[ValueBase::default_size];
};


// All overloads where left-hand-side is L:
//
// left-hand-side       operator                              right-hand-side
// L                    +, -, *, /, <, >, ==, !=, <=, >=      Subexpr2<R>
//
// For L = R = {int, int64_t, float, double}:
// Compare numeric values
template <class R> Query operator > (double left, const Subexpr2<R>& right) {
    return create<double, Greater, R>(left, right);
}
template <class R> Query operator > (float left, const Subexpr2<R>& right) {
    return create<float, Greater, R>(left, right);
}
template <class R> Query operator > (int left, const Subexpr2<R>& right) {
    return create<int, Greater, R>(left, right);
}
template <class R> Query operator > (int64_t left, const Subexpr2<R>& right) {
    return create<int64_t, Greater, R>(left, right);
}
template <class R> Query operator < (double left, const Subexpr2<R>& right) {
    return create<float, Less, R>(left, right);
}
template <class R> Query operator < (float left, const Subexpr2<R>& right) {
    return create<int, Less, R>(left, right);
}
template <class R> Query operator < (int left, const Subexpr2<R>& right) {
    return create<int, Less, R>(left, right);
}
template <class R> Query operator < (int64_t left, const Subexpr2<R>& right) {
    return create<int64_t, Less, R>(left, right);
}
template <class R> Query operator == (double left, const Subexpr2<R>& right) {
    return create<double, Equal, R>(left, right);
}
template <class R> Query operator == (float left, const Subexpr2<R>& right) {
    return create<float, Equal, R>(left, right);
}
template <class R> Query operator == (int left, const Subexpr2<R>& right) {
    return create<int, Equal, R>(left, right);
}
template <class R> Query operator == (int64_t left, const Subexpr2<R>& right) {
    return create<int64_t, Equal, R>(left, right);
}
template <class R> Query operator >= (double left, const Subexpr2<R>& right) {
    return create<double, GreaterEqual, R>(left, right);
}
template <class R> Query operator >= (float left, const Subexpr2<R>& right) {
    return create<float, GreaterEqual, R>(left, right);
}
template <class R> Query operator >= (int left, const Subexpr2<R>& right) {
    return create<int, GreaterEqual, R>(left, right);
}
template <class R> Query operator >= (int64_t left, const Subexpr2<R>& right) {
    return create<int64_t, GreaterEqual, R>(left, right);
}
template <class R> Query operator <= (double left, const Subexpr2<R>& right) {
    return create<double, LessEqual, R>(left, right);
}
template <class R> Query operator <= (float left, const Subexpr2<R>& right) {
    return create<float, LessEqual, R>(left, right);
}
template <class R> Query operator <= (int left, const Subexpr2<R>& right) {
    return create<int, LessEqual, R>(left, right);
}
template <class R> Query operator <= (int64_t left, const Subexpr2<R>& right) {
    return create<int64_t, LessEqual, R>(left, right);
}
template <class R> Query operator != (double left, const Subexpr2<R>& right) {
    return create<double, NotEqual, R>(left, right);
}
template <class R> Query operator != (float left, const Subexpr2<R>& right) {
    return create<float, NotEqual, R>(left, right);
}
template <class R> Query operator != (int left, const Subexpr2<R>& right) {
    return create<int, NotEqual, R>(left, right);
}
template <class R> Query operator != (int64_t left, const Subexpr2<R>& right) {
    return create<int64_t, NotEqual, R>(left, right);
}

// Arithmetic
template <class R> Operator<Plus<typename Common<R, double>::type> >& operator + (double left, const Subexpr2<R>& right) {
    return *new Operator<Plus<typename Common<R, double>::type> >(*new Value<double>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Plus<typename Common<R, float>::type> >& operator + (float left, const Subexpr2<R>& right) {
    return *new Operator<Plus<typename Common<R, float>::type> >(*new Value<float>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Plus<typename Common<R, int>::type> >& operator + (int left, const Subexpr2<R>& right) {
    return *new Operator<Plus<typename Common<R, int>::type> >(*new Value<int>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Plus<typename Common<R, int64_t>::type> >& operator + (int64_t left, const Subexpr2<R>& right) {
    return *new Operator<Plus<typename Common<R, int64_t>::type> >(*new Value<int64_t>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Minus<typename Common<R, double>::type> >& operator - (double left, const Subexpr2<R>& right) {
    return *new Operator<Minus<typename Common<R, double>::type> >(*new Value<double>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Minus<typename Common<R, float>::type> >& operator - (float left, const Subexpr2<R>& right) {
    return *new Operator<Minus<typename Common<R, float>::type> >(*new Value<float>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Minus<typename Common<R, int>::type> >& operator - (int left, const Subexpr2<R>& right) {
    return *new Operator<Minus<typename Common<R, int>::type> >(*new Value<int>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Minus<typename Common<R, int64_t>::type> >& operator - (int64_t left, const Subexpr2<R>& right) {
    return *new Operator<Minus<typename Common<R, int64_t>::type> >(*new Value<int64_t>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Mul<typename Common<R, double>::type> >& operator * (double left, const Subexpr2<R>& right) {
    return *new Operator<Mul<typename Common<R, double>::type> >(*new Value<double>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Mul<typename Common<R, float>::type> >& operator * (float left, const Subexpr2<R>& right) {
    return *new Operator<Mul<typename Common<R, float>::type> >(*new Value<float>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Mul<typename Common<R, int>::type> >& operator * (int left, const Subexpr2<R>& right) {
    return *new Operator<Mul<typename Common<R, int>::type> >(*new Value<int>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Mul<typename Common<R, int64_t>::type> >& operator * (int64_t left, const Subexpr2<R>& right) {
    return *new Operator<Mul<typename Common<R, int64_t>::type> >(*new Value<int64_t>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Div<typename Common<R, double>::type> >& operator / (double left, const Subexpr2<R>& right) {
    return *new Operator<Div<typename Common<R, double>::type> >(*new Value<double>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Div<typename Common<R, float>::type> >& operator / (float left, const Subexpr2<R>& right) {
    return *new Operator<Div<typename Common<R, float>::type> >*(new Value<float>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Div<typename Common<R, int>::type> >& operator / (int left, const Subexpr2<R>& right) {
    return *new Operator<Div<typename Common<R, int>::type> >(*new Value<int>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}
template <class R> Operator<Div<typename Common<R, int64_t>::type> >& operator / (int64_t left, const Subexpr2<R>& right) {
    return *new Operator<Div<typename Common<R, int64_t>::type> >(*new Value<int64_t>(left), const_cast<Subexpr2<R>&>(right).clone(), true);
}

// Unary operators
template <class T> UnaryOperator<Pow<T> >& power (Subexpr2<T>& left) {
    return *new UnaryOperator<Pow<T> >(left.clone(), true);
}



// Classes used for LinkMap (see below).
struct LinkMapFunction
{
    // Your consume() method is given row index of the linked-to table as argument, and you must return wether or 
    // not you want the LinkMapFunction to exit (return false) or continue (return true) harvesting the link tree
    // for the current main table row index (it will be a link tree if you have multiple type_LinkList columns
    // in a link()->link() query.
    virtual bool consume(size_t row_index) = 0;
};

struct FindNullLinks : public LinkMapFunction
{
    FindNullLinks() : m_has_link(false) {};

    virtual bool consume(size_t row_index) {
        static_cast<void>(row_index);
        m_has_link = true;
        return false; // we've found a row index, so this can't be a null-link, so exit link harvesting
    }

    bool m_has_link;
};

struct MakeLinkVector : public LinkMapFunction
{
    MakeLinkVector(std::vector<size_t>& result) : m_links(result) {}

    virtual bool consume(size_t row_index) {
        m_links.push_back(row_index);
        return true; // continue evaluation
    }
    std::vector<size_t> &m_links;
};


/*
The LinkMap and LinkMapFunction classes are used for query conditions on links themselves (contrary to conditions on
the value payload they point at).

MapLink::map_links() takes a row index of the link column as argument and follows any link chain stated in the query
(through the link()->link() methods) until the final payload table is reached, and then applies LinkMapFunction on 
the linked-to row index(es). 

If all link columns are type_Link, then LinkMapFunction is only invoked for a single row index. If one or more 
columns are type_LinkList, then it may result in multiple row indexes.

The reason we use this map pattern is that we can exit the link-tree-traversal as early as possible, e.g. when we've
found the first link that points to row '5'. Other solutions could be a vector<size_t> harvest_all_links(), or an
iterator pattern. First solution can't exit, second solution requires internal state.
*/
class LinkMap
{
public:
    LinkMap() : m_table(null_ptr) {};

    void init(Table* table, std::vector<size_t> columns)
    {
        for (size_t t = 0; t < columns.size(); t++) {
            // Link column can be either LinkList or single Link
            ColumnType type = table->get_real_column_type(columns[t]);
            if (type == col_type_LinkList) {
                ColumnLinkList& cll = table->get_column_link_list(columns[t]);
                m_tables.push_back(table);
                m_link_columns.push_back(&(table->get_column_link_list(columns[t])));
                m_link_types.push_back(tightdb::type_LinkList);
                table = &cll.get_target_table();
            }
            else {
                ColumnLink& cl = table->get_column_link(columns[t]);
                m_tables.push_back(table);
                m_link_columns.push_back(&(table->get_column_link(columns[t])));
                m_link_types.push_back(tightdb::type_Link);
                table = &cl.get_target_table();
            }
        }
        m_table = table;
    }

    std::vector<size_t> get_links(size_t index)
    {
        std::vector<size_t> res;
        get_links(index, res);
        return res;
    }

    void map_links(size_t row, LinkMapFunction& lm)
    {
        map_links(0, row, lm);
    }

    const Table* m_table;
    std::vector<ColumnLinkBase*> m_link_columns;
    std::vector<Table*> m_tables;

private:
    void map_links(size_t column, size_t row, LinkMapFunction& lm)
    {
        bool last = (column + 1 == m_link_columns.size());
        if (m_link_types[column] == type_Link) {
            ColumnLink& cl = *static_cast<ColumnLink*>(m_link_columns[column]);
            size_t r = to_size_t(cl.get(row));
            if (r == 0)
                return;
            r--; // ColumnLink stores link to row N as N + 1
            if (last) {
                bool continue2 = lm.consume(r);
                if (!continue2)
                    return;
            }
            else
                map_links(column + 1, r, lm);
        }
        else {
            ColumnLinkList& cll = *static_cast<ColumnLinkList*>(m_link_columns[column]);
            LinkViewRef lvr = cll.get(row);
            for (size_t t = 0; t < lvr->size(); t++) {
                size_t r = lvr->get(t).get_index();
                if (last) {
                    bool continue2 = lm.consume(r);
                    if (!continue2)
                        return;
                }
                else
                    map_links(column + 1, r, lm);
            }
        }
    }


    void get_links(size_t row, std::vector<size_t>& result)
    {
        MakeLinkVector mlv = MakeLinkVector(result);
        map_links(row, mlv);
    }

    std::vector<tightdb::DataType> m_link_types;
};


// Handling of String columns. These support only == and != compare operators. No 'arithmetic' operators (+, etc).
template <> class Columns<StringData> : public Subexpr2<StringData>
{
public:
    Columns(size_t column, const Table* table, std::vector<size_t> links) : m_table_linked_from(null_ptr),
                                                                            m_table(null_ptr), 
                                                                            m_column(column)
    {
        m_link_map.init(const_cast<Table*>(table), links);
        m_table = table;
    }

    Columns(size_t column, const Table* table) : m_table_linked_from(null_ptr), m_table(null_ptr), m_column(column)
    {
        m_table = table;
    }

    explicit Columns() : m_table_linked_from(null_ptr), m_table(null_ptr) { }


    explicit Columns(size_t column) : m_table_linked_from(null_ptr), m_table(null_ptr), m_column(column)
    {
    }

    virtual Subexpr& clone()
    {
        Columns<StringData>& n = *new Columns<StringData>();
        n = *this;
        return n;
    }

    virtual const Table* get_table()
    {
        return m_table;
    }

    virtual void evaluate(size_t index, ValueBase& destination)
    {
        Value<StringData>& d = static_cast<Value<StringData>&>(destination);

        if (m_link_map.m_link_columns.size() > 0) {
            std::vector<size_t> links = m_link_map.get_links(index);
            Value<StringData> v(true, links.size());
            for (size_t t = 0; t < links.size(); t++) {
                size_t link_to = links[t];
                v.m_v[t] = m_link_map.m_table->get_string(m_column, link_to);
            }
            destination.import(v);
        }
        else {
            // Not a link column
            for (size_t t = 0; t < destination.m_values && index + t < m_table->size(); t++) {
                d.m_v[t] = m_table->get_string(m_column, index + t);
            }
        }
    }

    const Table* m_table_linked_from;

    // Pointer to payload table (which is the linked-to table if this is a link column) used for condition operator
    const Table* m_table;

    // Column index of payload column of m_table
    size_t m_column;

    LinkMap m_link_map;
};


// String == Columns<String>
template <class T> Query operator == (T left, const Columns<StringData>& right) {
    return operator==(right, left);
}

// String != Columns<String>
template <class T> Query operator != (T left, const Columns<StringData>& right) {
    return operator!=(right, left);
}

// Columns<String> == String
template <class T> Query operator == (const Columns<StringData>& left, T right) {
    return create<StringData, Equal, StringData>(right, left);
}

// Columns<String> != String
template <class T> Query operator != (const Columns<StringData>& left, T right) {
    return create<StringData, NotEqual, StringData>(right, left);
}

// This class is intended to perform queries on the *pointers* of links, contrary to performing queries on *payload* 
// in linked-to tables. Queries can be "find first link that points at row X" or "find first null-link". Currently
// only "find first null-link" is supported. More will be added later.
class UnaryLinkCompare : public Expression
{
public:
    UnaryLinkCompare(LinkMap lm) : m_link_map(lm)
    {
        Query::expression(this, true);
        Table* t = const_cast<Table*>(get_table());
        Query::m_table = t->get_table_ref();
    }

    void set_table()
    {
    }

    // Return main table of query (table on which table->where()... is invoked). Note that this is not the same as 
    // any linked-to payload tables
    virtual const Table* get_table()
    {
        return m_link_map.m_tables[0];
    }

    size_t find_first(size_t start, size_t end) const
    {
        for (; start < end;) {
            std::vector<size_t> l = m_link_map.get_links(start);
            // We have found a Link which is NULL, or LinkList with 0 entries. Return it as match.

            FindNullLinks fnl;
            m_link_map.map_links(start, fnl);
            if (!fnl.m_has_link)
                return start;
            
            start++;
        }

        return not_found;
    }

private:
    mutable LinkMap m_link_map;
};

// This is for LinkList too because we have 'typedef List LinkList'
template <> class Columns<Link> : public Subexpr2<Link>
{
public:
    Query is_null() {
        if (m_link_map.m_link_columns.size() > 1)
            throw std::runtime_error("Cannot find null-links in a linked-to table (link()...is_null() not supported).");
        // Todo, it may be useful to support the above, but we would need to figure out an intuitive behaviour
        return *new UnaryLinkCompare(m_link_map);
    }

private:
    Columns(size_t column, const Table* table, std::vector<size_t> links) :
        m_table(null_ptr)
    {
        static_cast<void>(column);
        m_link_map.init(const_cast<Table*>(table), links);
        m_table = table;
    }

    Columns() : m_table(null_ptr) { }

    explicit Columns(size_t column) : m_table(null_ptr) { static_cast<void>(column); }

    Columns(size_t column, const Table* table) : m_table(null_ptr)
    {
        static_cast<void>(column);
        m_table = table;
    }

    virtual Subexpr& clone()
    {
        return *this;
    }

    virtual const Table* get_table()
    {
        return m_table;
    }

    virtual void evaluate(size_t index, ValueBase& destination)
    {
        static_cast<void>(index);
        static_cast<void>(destination);
        TIGHTDB_ASSERT(false);
    }

    // m_table is redundant with ColumnAccessorBase<>::m_table, but is in order to decrease class dependency/entanglement
    const Table* m_table;

    // Column index of payload column of m_table
    size_t m_column;

    LinkMap m_link_map;
    bool auto_delete;

   friend class Table;
};


template <class T> class Columns : public Subexpr2<T>, public ColumnsBase
{
public:

    Columns(size_t column, const Table* table, std::vector<size_t> links) : m_table_linked_from(null_ptr), 
                                                                            m_table(null_ptr), sg(null_ptr),
                                                                            m_column(column)
    {
        m_link_map.init(const_cast<Table*>(table), links);
        m_table = table; 
    }

    Columns(size_t column, const Table* table) : m_table_linked_from(null_ptr), m_table(null_ptr), sg(null_ptr),
                                                 m_column(column)
    {
        m_table = table;
    }


    Columns() : m_table_linked_from(null_ptr), m_table(null_ptr), sg(null_ptr) { }

    explicit Columns(size_t column) : m_table_linked_from(null_ptr), m_table(null_ptr), sg(null_ptr),
                                      m_column(column) {}

    ~Columns()
    {
        delete sg;
    }

    virtual Subexpr& clone()
    {
        Columns<T>& n = *new Columns<T>();
        n = *this;
        SequentialGetter<T> *s = new SequentialGetter<T>();
        n.sg = s;
        return n;
    }

    // Recursively set table pointers for all Columns object in the expression tree. Used for late binding of table
    virtual void set_table()
    {
        typedef typename ColumnTypeTraits<T>::column_type ColType;
        const ColType* c;
        if (m_link_map.m_link_columns.size() == 0)
            c = static_cast<const ColType*>(&m_table->get_column_base(m_column));
        else
            c = static_cast<const ColType*>(&m_link_map.m_table->get_column_base(m_column));

        if (sg == null_ptr)
            sg = new SequentialGetter<T>();
        sg->init(c);
    }

    // Recursively fetch tables of columns in expression tree. Used when user first builds a stand-alone expression and
    // binds it to a Query at a later time
    virtual const Table* get_table()
    {
        return m_table;
    }

    // Load values from Column into destination
    void evaluate(size_t index, ValueBase& destination) {
        if (m_link_map.m_link_columns.size() > 0) {
            // LinkList with more than 0 values. Create Value with payload for all fields

            std::vector<size_t> links = m_link_map.get_links(index);
            Value<T> v(true, links.size());

            for (size_t t = 0; t < links.size(); t++) {
                size_t link_to = links[t];
                sg->cache_next(link_to); // todo, needed?
                v.m_v[t] = sg->get_next(link_to);
            }
            destination.import(v);
        }
        else {
            // Not a Link column
            sg->cache_next(index);
            size_t colsize = sg->m_column->size();

            if (util::SameType<T, int64_t>::value && index + ValueBase::default_size < sg->m_leaf_end) {
                Value<T> v;
                TIGHTDB_ASSERT(ValueBase::default_size == 8); // If you want to modify 'default_size' then update Array::get_chunk()
                // int64_t leaves have a get_chunk optimization that returns 8 int64_t values at once
                sg->m_array_ptr->get_chunk(index - sg->m_leaf_start, static_cast<Value<int64_t>*>(static_cast<ValueBase*>(&v))->m_v);
                destination.import(v);
            }
            else {
                // To make Valgrind happy we must initialize all default_size in v even if Column ends earlier. Todo, benchmark
                // if an unconditional zero out is faster
                size_t rows = colsize - index;
                if (rows > ValueBase::default_size)
                    rows = ValueBase::default_size;
                Value<T> v(false, rows);

                for (size_t t = 0; t < rows; t++)
                    v.m_v[t] = sg->get_next(index + t);

                destination.import(v);
            }
        }
    }

    const Table* m_table_linked_from;

    // m_table is redundant with ColumnAccessorBase<>::m_table, but is in order to decrease class dependency/entanglement
    const Table* m_table;

    // Fast (leaf caching) value getter for payload column (column in table on which query condition is executed)
    SequentialGetter<T>* sg;

    // Column index of payload column of m_table
    size_t m_column;

    LinkMap m_link_map;
};


template <class oper, class TLeft> class UnaryOperator : public Subexpr2<typename oper::type>
{
public:
    UnaryOperator(TLeft& left, bool auto_delete = false) : m_auto_delete(auto_delete), m_left(left) {}

    ~UnaryOperator()
    {
        if (m_auto_delete)
            delete &m_left;
    }

    // Recursively set table pointers for all Columns object in the expression tree. Used for late binding of table
    void set_table()
    {
        m_left.set_table();
    }

    // Recursively fetch tables of columns in expression tree. Used when user first builds a stand-alone expression and
    // binds it to a Query at a later time
    virtual const Table* get_table()
    {
        const Table* l = m_left.get_table();
        return l;
    }

    // destination = operator(left)
    void evaluate(size_t index, ValueBase& destination)
    {
        Value<T> result;
        Value<T> left;
        m_left.evaluate(index, left);
        result.template fun<oper>(&left);
        destination.import(result);
    }

private:
    typedef typename oper::type T;
    bool m_auto_delete;
    TLeft& m_left;
};


template <class oper, class TLeft, class TRight> class Operator : public Subexpr2<typename oper::type>
{
public:

    Operator(TLeft& left, const TRight& right, bool auto_delete = false) : m_left(left), m_right(const_cast<TRight&>(right))
    {
        m_auto_delete = auto_delete;
    }

    ~Operator()
    {
        if (m_auto_delete) {
            delete &m_left;
            delete &m_right;
        }
    }

    // Recursively set table pointers for all Columns object in the expression tree. Used for late binding of table
    void set_table()
    {
        m_left.set_table();
        m_right.set_table();
    }

    // Recursively fetch tables of columns in expression tree. Used when user first builds a stand-alone expression and
    // binds it to a Query at a later time
    virtual const Table* get_table()
    {
        const Table* l = m_left.get_table();
        const Table* r = m_right.get_table();

        // Queries do not support multiple different tables; all tables must be the same.
        TIGHTDB_ASSERT(l == null_ptr || r == null_ptr || l == r);

        // null_ptr pointer means expression which isn't yet associated with any table, or is a Value<T>
        return l ? l : r;
    }

    // destination = operator(left, right)
    void evaluate(size_t index, ValueBase& destination)
    {
        Value<T> result;
        Value<T> left;
        Value<T> right;
        m_left.evaluate(index, left);
        m_right.evaluate(index, right);
        result.template fun<oper>(&left, &right);
        destination.import(result);
    }

private:
    typedef typename oper::type T;
    bool m_auto_delete;
    TLeft& m_left;
    TRight& m_right;
};


template <class TCond, class T, class TLeft, class TRight> class Compare : public Expression
{
public:

    // Compare extends Expression which extends Query. This constructor for Compare initializes the Query part by
    // adding an ExpressionNode (see query_engine.hpp) and initializes Query::table so that it's ready to call
    // Query methods on, like find_first(), etc.
    Compare(TLeft& left, const TRight& right, bool auto_delete = false) : m_left(left), m_right(const_cast<TRight&>(right))
    {
        m_auto_delete = auto_delete;
        Query::expression(this, auto_delete);
        Table* t = const_cast<Table*>(get_table()); // todo, const

        if (t)
            Query::m_table = t->get_table_ref();
    }

    ~Compare()
    {
        if (m_auto_delete) {
            delete &m_left;
            delete &m_right;
        }
    }

    // Recursively set table pointers for all Columns object in the expression tree. Used for late binding of table
    void set_table()
    {
        m_left.set_table();
        m_right.set_table();
    }

    // Recursively fetch tables of columns in expression tree. Used when user first builds a stand-alone expression and
    // binds it to a Query at a later time
    virtual const Table* get_table()
    {
        const Table* l = m_left.get_table();
        const Table* r = m_right.get_table();

        // All main tables in each subexpression of a query (table.columns() or table.link()) must be the same.
        TIGHTDB_ASSERT(l == null_ptr || r == null_ptr || l == r);

        // null_ptr pointer means expression which isn't yet associated with any table, or is a Value<T>
        return l ? l : r;
    }

    size_t find_first(size_t start, size_t end) const
    {
        size_t match;
        Value<T> right;
        Value<T> left;

        for (; start < end;) {
            m_left.evaluate(start, left);
            m_right.evaluate(start, right);
            match = Value<T>::template compare<TCond>(&left, &right);

            if (match != not_found && match + start < end)
                return start + match;

            size_t rows = (left.from_link || right.from_link) ? 1 : minimum(right.m_values, left.m_values);
            start += rows;
        }

        return not_found; // no match
    }

private:
    bool m_auto_delete;
    TLeft& m_left;
    TRight& m_right;
};



//}
#endif // TIGHTDB_QUERY_EXPRESSION_HPP

