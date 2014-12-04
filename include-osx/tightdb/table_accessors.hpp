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
#ifndef TIGHTDB_TABLE_ACCESSORS_HPP
#define TIGHTDB_TABLE_ACCESSORS_HPP

#include <cstring>
#include <utility>

#include <tightdb/mixed.hpp>
#include <tightdb/table.hpp>

#include <tightdb/query_engine.hpp>

namespace tightdb {


/// A convenience base class for Spec classes that are to be used with
/// BasicTable.
///
/// There are two reasons why you might want to derive your spec class
/// from this one. First, it offers short hand names for each of the
/// available column types. Second, it makes it easier when you do not
/// want to specify colum names or convenience methods, since suitable
/// fallbacks are defined here.
struct SpecBase {
    typedef int64_t             Int;
    typedef bool                Bool;
    typedef tightdb::DateTime   DateTime;
    typedef float               Float;
    typedef double              Double;
    typedef tightdb::StringData String;
    typedef tightdb::BinaryData Binary;
    typedef tightdb::Mixed      Mixed;

    template<class E> class Enum {
    public:
        typedef E enum_type;
        Enum(E v): m_value(v) {}
        operator E() const { return m_value; }
    private:
        E m_value;
    };

    template<class T> class Subtable {
    public:
        typedef T table_type;
        Subtable(T* t): m_table(t) {}
        operator T*() const { return m_table; }
    private:
        T* m_table;
    };

    /// By default, there are no static column names defined for a
    /// BasicTable. One may define a set of column mames as follows:
    ///
    /// \code{.cpp}
    ///
    ///   struct MyTableSpec: SpecBase {
    ///     typedef TypeAppend<void, int>::type Columns1;
    ///     typedef TypeAppend<Columns1, bool>::type Columns;
    ///
    ///     template<template<int> class Col, class Init> struct ColNames {
    ///       typename Col<0>::type foo;
    ///       typename Col<1>::type bar;
    ///       ColNames(Init i) TIGHTDB_NOEXCEPT: foo(i), bar(i) {}
    ///     };
    ///   };
    ///
    /// \endcode
    ///
    /// Note that 'i' in Col<i> links the name that you specify to a
    /// particular column index. You may specify the column names in
    /// any order. Multiple names may refer to the same column, and
    /// you do not have to specify a name for every column.
    template<template<int> class Col, class Init> struct ColNames {
        ColNames(Init) TIGHTDB_NOEXCEPT {}
    };

    /// FIXME: Currently we do not support absence of dynamic column
    /// names.
    static void dyn_col_names(StringData*) TIGHTDB_NOEXCEPT {}

    /// This is the fallback class that is used when no convenience
    /// methods are specified in the users Spec class.
    ///
    /// If you would like to add a more convenient add() method, here
    /// is how you could do it:
    ///
    /// \code{.cpp}
    ///
    ///   struct MyTableSpec: SpecBase {
    ///     typedef tightdb::TypeAppend<void, int>::type Columns1;
    ///     typedef tightdb::TypeAppend<Columns1, bool>::type Columns;
    ///
    ///     struct ConvenienceMethods {
    ///       void add(int foo, bool bar)
    ///       {
    ///         BasicTable<MyTableSpec>* const t = static_cast<BasicTable<MyTableSpec>*>(this);
    ///         t->add((tuple(), name1, name2));
    ///       }
    ///     };
    ///   };
    ///
    /// \endcode
    ///
    /// FIXME: ConvenienceMethods may not contain any virtual methods,
    /// nor may it contain any data memebers. We might want to check
    /// this by TIGHTDB_STATIC_ASSERT(sizeof(Derivative of
    /// ConvenienceMethods) == 1)), however, this would not be
    /// guaranteed by the standard, since even an empty class may add
    /// to the size of the derived class. Fortunately, as long as
    /// ConvenienceMethods is derived from, by BasicTable, after
    /// deriving from Table, this cannot become a problem, nor would
    /// it lead to a violation of the strict aliasing rule of C++03 or
    /// C++11.
    struct ConvenienceMethods {};
};


template<class> class BasicTable;
template<class> class BasicTableView;


namespace _impl {


/// Get the const qualified type of the table being accessed.
///
/// If T matches 'BasicTableView<T2>' or 'const BasicTableView<T2>',
/// then return T2, else simply return T.
template<class Tab> struct GetTableFromView { typedef Tab type; };
template<class Tab> struct GetTableFromView<BasicTableView<Tab> > { typedef Tab type; };
template<class Tab> struct GetTableFromView<const BasicTableView<Tab> > { typedef Tab type; };


/// Determine whether an accessor has const-only access to a table, so
/// that it is not allowed to modify fields, nor return non-const
/// subtable references.
///
/// Note that for Taboid = 'BasicTableView<const Tab>', a column
/// accessor is still allowed to reorder the rows of the view, as long
/// as it does not modify the contents of the table.
template<class Taboid> struct TableIsConst { static const bool value = false; };
template<class Taboid> struct TableIsConst<const Taboid> { static const bool value = true; };
template<class Tab> struct TableIsConst<BasicTableView<const Tab> > {
    static const bool value = true;
};



/// This class gives access to a field of a row of a table, or a table
/// view.
///
/// \tparam Taboid Either a table or a table view, that is, any of
/// 'BasicTable<S>', 'const BasicTable<S>',
/// 'BasicTableView<BasicTable<S> >', 'const
/// BasicTableView<BasicTable<S> >', 'BasicTableView<const
/// BasicTable<S> >', or 'const BasicTableView<const BasicTable<S>
/// >'. Note that the term 'taboid' is used here for something that is
/// table-like, i.e., either a table of a table view.
///
/// \tparam const_tab Indicates whether the accessor has const-only
/// access to the field, that is, if, and only if Taboid matches
/// 'const T' or 'BasicTableView<const T>' for any T.
template<class Taboid, int col_idx, class Type, bool const_tab> class FieldAccessor;


/// Commmon base class for all field accessor specializations.
template<class Taboid> class FieldAccessorBase {
protected:
    typedef std::pair<Taboid*, std::size_t> Init;
    Taboid* const m_table;
    const std::size_t m_row_idx;
    FieldAccessorBase(Init i) TIGHTDB_NOEXCEPT: m_table(i.first), m_row_idx(i.second) {}
};


/// Field accessor specialization for integers.
template<class Taboid, int col_idx, bool const_tab>
class FieldAccessor<Taboid, col_idx, int64_t, const_tab>: public FieldAccessorBase<Taboid> {
private:
    typedef FieldAccessorBase<Taboid> Base;

public:
    int64_t get() const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->get_impl()->get_int(col_idx, Base::m_row_idx);
    }

    void set(int64_t value) const
    {
        Base::m_table->get_impl()->set_int(col_idx, Base::m_row_idx, value);
    }
    operator int64_t() const TIGHTDB_NOEXCEPT { return get(); }
    const FieldAccessor& operator=(int64_t value) const { set(value); return *this; }

    const FieldAccessor& operator+=(int64_t value) const
    {
        // FIXME: Should be optimized (can be both optimized and
        // generalized by using a form of expression templates).
        set(get() + value);
        return *this;
    }

    const FieldAccessor& operator-=(int64_t value) const
    {
        // FIXME: Should be optimized (can be both optimized and
        // generalized by using a form of expression templates).
        set(get() - value);
        return *this;
    }

    const FieldAccessor& operator++() const { return *this += 1; }
    const FieldAccessor& operator--() const { return *this -= 1; }

    int64_t operator++(int) const
    {
        // FIXME: Should be optimized (can be both optimized and
        // generalized by using a form of expression templates).
        const int64_t value = get();
        set(value + 1);
        return value;
    }

    int64_t operator--(int) const
    {
        // FIXME: Should be optimized (can be both optimized and
        // generalized by using a form of expression templates).
        const int64_t value = get();
        set(value - 1);
        return value;
    }


    explicit FieldAccessor(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}
};


/// Field accessor specialization for floats.
template<class Taboid, int col_idx, bool const_tab>
class FieldAccessor<Taboid, col_idx, float, const_tab>: public FieldAccessorBase<Taboid> {
private:
    typedef FieldAccessorBase<Taboid> Base;

public:
    float get() const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->get_impl()->get_float(col_idx, Base::m_row_idx);
    }

    void set(float value) const
    {
        Base::m_table->get_impl()->set_float(col_idx, Base::m_row_idx, value);
    }

    operator float() const TIGHTDB_NOEXCEPT { return get(); }
    const FieldAccessor& operator=(float value) const { set(value); return *this; }

    const FieldAccessor& operator+=(float value) const
    {
        // FIXME: Should be optimized (can be both optimized and
        // generalized by using a form of expression templates).
        set(get() + value);
        return *this;
    }

    const FieldAccessor& operator-=(float value) const
    {
        // FIXME: Should be optimized (can be both optimized and
        // generalized by using a form of expression templates).
        set(get() - value);
        return *this;
    }


    explicit FieldAccessor(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}
};


/// Field accessor specialization for doubles.
template<class Taboid, int col_idx, bool const_tab>
class FieldAccessor<Taboid, col_idx, double, const_tab>: public FieldAccessorBase<Taboid> {
private:
    typedef FieldAccessorBase<Taboid> Base;

public:
    double get() const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->get_impl()->get_double(col_idx, Base::m_row_idx);
    }

    void set(double value) const
    {
        Base::m_table->get_impl()->set_double(col_idx, Base::m_row_idx, value);
    }

    operator double() const TIGHTDB_NOEXCEPT { return get(); }
    const FieldAccessor& operator=(double value) const { set(value); return *this; }

    const FieldAccessor& operator+=(double value) const
    {
        // FIXME: Should be optimized (can be both optimized and
        // generalized by using a form of expression templates).
        set(get() + value);
        return *this;
    }

    const FieldAccessor& operator-=(double value) const
    {
        // FIXME: Should be optimized (can be both optimized and
        // generalized by using a form of expression templates).
        set(get() - value);
        return *this;
    }


    explicit FieldAccessor(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}
};


/// Field accessor specialization for booleans.
template<class Taboid, int col_idx, bool const_tab>
class FieldAccessor<Taboid, col_idx, bool, const_tab>: public FieldAccessorBase<Taboid> {
private:
    typedef FieldAccessorBase<Taboid> Base;

public:
    bool get() const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->get_impl()->get_bool(col_idx, Base::m_row_idx);
    }

    void set(bool value) const
    {
        Base::m_table->get_impl()->set_bool(col_idx, Base::m_row_idx, value);
    }

    operator bool() const TIGHTDB_NOEXCEPT { return get(); }
    const FieldAccessor& operator=(bool value) const { set(value); return *this; }


    explicit FieldAccessor(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}
};


/// Field accessor specialization for enumerations.
template<class Taboid, int col_idx, class E, bool const_tab>
class FieldAccessor<Taboid, col_idx, SpecBase::Enum<E>, const_tab>:
    public FieldAccessorBase<Taboid> {
private:
    typedef FieldAccessorBase<Taboid> Base;

public:
    E get() const TIGHTDB_NOEXCEPT
    {
        return static_cast<E>(Base::m_table->get_impl()->get_int(col_idx, Base::m_row_idx));
    }

    void set(E value) const
    {
        Base::m_table->get_impl()->set_int(col_idx, Base::m_row_idx, value);
    }

    operator E() const TIGHTDB_NOEXCEPT { return get(); }
    const FieldAccessor& operator=(E value) const { set(value); return *this; }


    explicit FieldAccessor(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}
};


/// Field accessor specialization for dates.
template<class Taboid, int col_idx, bool const_tab>
class FieldAccessor<Taboid, col_idx, DateTime, const_tab>: public FieldAccessorBase<Taboid> {
private:
    typedef FieldAccessorBase<Taboid> Base;

public:
    DateTime get() const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->get_impl()->get_datetime(col_idx, Base::m_row_idx);
    }

    void set(DateTime value) const
    {
        Base::m_table->get_impl()->set_datetime(col_idx, Base::m_row_idx, value);
    }

    operator DateTime() const TIGHTDB_NOEXCEPT { return get(); }
    const FieldAccessor& operator=(DateTime value) const { set(value); return *this; }


    explicit FieldAccessor(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}
};


/// Field accessor specialization for strings.
template<class Taboid, int col_idx, bool const_tab>
class FieldAccessor<Taboid, col_idx, StringData, const_tab>: public FieldAccessorBase<Taboid> {
private:
    typedef FieldAccessorBase<Taboid> Base;

public:
    StringData get() const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->get_impl()->get_string(col_idx, Base::m_row_idx);
    }

    void set(StringData value) const
    {
        Base::m_table->get_impl()->set_string(col_idx, Base::m_row_idx, value);
    }

    operator StringData() const TIGHTDB_NOEXCEPT { return get(); }
    const FieldAccessor& operator=(StringData value) const { set(value); return *this; }

    const char* data() const TIGHTDB_NOEXCEPT { return get().data(); }
    std::size_t size() const TIGHTDB_NOEXCEPT { return get().size(); }

    const char* c_str() const TIGHTDB_NOEXCEPT { return data(); }


    explicit FieldAccessor(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}
};


/// Field accessor specialization for binary data.
template<class Taboid, int col_idx, bool const_tab>
class FieldAccessor<Taboid, col_idx, BinaryData, const_tab>: public FieldAccessorBase<Taboid> {
private:
    typedef FieldAccessorBase<Taboid> Base;

public:
    BinaryData get() const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->get_impl()->get_binary(col_idx, Base::m_row_idx);
    }

    void set(const BinaryData& value) const
    {
        Base::m_table->get_impl()->set_binary(col_idx, Base::m_row_idx, value);
    }

    operator BinaryData() const TIGHTDB_NOEXCEPT { return get(); }
    const FieldAccessor& operator=(const BinaryData& value) const { set(value); return *this; }

    const char* data() const TIGHTDB_NOEXCEPT { return get().data(); }
    std::size_t size() const TIGHTDB_NOEXCEPT { return get().size(); }


    explicit FieldAccessor(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}
};


/// Field accessor specialization for subtables of non-const parent.
template<class Taboid, int col_idx, class Subtab>
class FieldAccessor<Taboid, col_idx, SpecBase::Subtable<Subtab>, false>:
    public FieldAccessorBase<Taboid> {
private:
    typedef FieldAccessorBase<Taboid> Base;
    // FIXME: Dangerous slicing posibility as long as Cursor is same as RowAccessor.
    // FIXME: Accessors must not be publicly copyable. This requires that Spec::ColNames is made a friend of BasicTable.
    // FIXME: Need BasicTableView::Cursor and BasicTableView::ConstCursor if Cursors should exist at all.
    struct SubtabRowAccessor: Subtab::RowAccessor {
    public:
        SubtabRowAccessor(Subtab* subtab, std::size_t row_idx):
            Subtab::RowAccessor(std::make_pair(subtab, row_idx)),
            m_owner(subtab->get_table_ref()) {}

    private:
        typename Subtab::Ref const m_owner;
    };

public:
    operator typename Subtab::Ref() const
    {
        Subtab* subtab =
            Base::m_table->template get_subtable_ptr<Subtab>(col_idx, Base::m_row_idx);
        return subtab->get_table_ref();
    }

    operator typename Subtab::ConstRef() const
    {
        const Subtab* subtab =
            Base::m_table->template get_subtable_ptr<Subtab>(col_idx, Base::m_row_idx);
        return subtab->get_table_ref();
    }

    typename Subtab::Ref operator->() const
    {
        Subtab* subtab =
            Base::m_table->template get_subtable_ptr<Subtab>(col_idx, Base::m_row_idx);
        return subtab->get_table_ref();
    }

    SubtabRowAccessor operator[](std::size_t row_idx) const
    {
        Subtab* subtab =
            Base::m_table->template get_subtable_ptr<Subtab>(col_idx, Base::m_row_idx);
        return SubtabRowAccessor(subtab, row_idx);
    }


    explicit FieldAccessor(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}
};


/// Field accessor specialization for subtables of const parent.
template<class Taboid, int col_idx, class Subtab>
class FieldAccessor<Taboid, col_idx, SpecBase::Subtable<Subtab>, true>:
    public FieldAccessorBase<Taboid> {
private:
    typedef FieldAccessorBase<Taboid> Base;
    // FIXME: Dangerous slicing posibility as long as Cursor is same as RowAccessor.
    struct SubtabRowAccessor: Subtab::ConstRowAccessor {
    public:
        SubtabRowAccessor(const Subtab* subtab, std::size_t row_idx):
            Subtab::ConstRowAccessor(std::make_pair(subtab, row_idx)),
            m_owner(subtab->get_table_ref()) {}

    private:
        typename Subtab::ConstRef const m_owner;
    };

public:
    explicit FieldAccessor(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}

    operator typename Subtab::ConstRef() const
    {
        const Subtab* subtab =
            Base::m_table->template get_subtable_ptr<Subtab>(col_idx, Base::m_row_idx);
        return subtab->get_table_ref();
    }

    typename Subtab::ConstRef operator->() const
    {
        const Subtab* subtab =
            Base::m_table->template get_subtable_ptr<Subtab>(col_idx, Base::m_row_idx);
        return subtab->get_table_ref();
    }

    SubtabRowAccessor operator[](std::size_t row_idx) const
    {
        const Subtab* subtab =
            Base::m_table->template get_subtable_ptr<Subtab>(col_idx, Base::m_row_idx);
        return SubtabRowAccessor(subtab, row_idx);
    }
};


/// Base for field accessor specializations for mixed type.
template<class Taboid, int col_idx, class FieldAccessor>
class MixedFieldAccessorBase: public FieldAccessorBase<Taboid> {
private:
    typedef FieldAccessorBase<Taboid> Base;

public:
    Mixed get() const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->get_impl()->get_mixed(col_idx, Base::m_row_idx);
    }

    void set(const Mixed& value) const
    {
        Base::m_table->get_impl()->set_mixed(col_idx, Base::m_row_idx, value);
    }

    operator Mixed() const TIGHTDB_NOEXCEPT { return get(); }

    const FieldAccessor& operator=(const Mixed& value) const
    {
        set(value);
        return static_cast<FieldAccessor&>(*this);
    }

    DataType get_type() const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->get_impl()->get_mixed_type(col_idx, Base::m_row_idx);
    }

    int64_t get_int() const TIGHTDB_NOEXCEPT { return get().get_int(); }

    bool get_bool() const TIGHTDB_NOEXCEPT { return get().get_bool(); }

    DateTime get_datetime() const TIGHTDB_NOEXCEPT { return get().get_datetime(); }

    float get_float() const TIGHTDB_NOEXCEPT { return get().get_float(); }

    double get_double() const TIGHTDB_NOEXCEPT { return get().get_double(); }

    StringData get_string() const TIGHTDB_NOEXCEPT { return get().get_string(); }

    BinaryData get_binary() const TIGHTDB_NOEXCEPT { return get().get_binary(); }

    bool is_subtable() const TIGHTDB_NOEXCEPT { return get_type() == type_Table; }

    /// Checks whether this value is a subtable of the specified type.
    ///
    /// FIXME: Consider deleting this function. It is mostly
    /// redundant, and it is inefficient if you want to also get a
    /// reference to the table, or if you want to check for multiple
    /// table types.
    template<class T> bool is_subtable() const
    {
        // FIXME: Conversion from TableRef to ConstTableRef is relatively expensive, or is it? Check whether it involves access to the reference count!
        ConstTableRef t = static_cast<const FieldAccessor*>(this)->get_subtable();
        return t && T::matches_dynamic_type(TableFriend::get_spec(*t));
    }

    /// Generally more efficient that get_subtable()->size().
    std::size_t get_subtable_size() const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->get_impl()->get_subtable_size(col_idx, Base::m_row_idx);
    }

    template<class T> friend bool operator==(const FieldAccessor& a, const T& b) TIGHTDB_NOEXCEPT
    {
        return a.get() == b;
    }

    template<class T> friend bool operator!=(const FieldAccessor& a, const T& b) TIGHTDB_NOEXCEPT
    {
        return a.get() != b;
    }

    template<class T> friend bool operator==(const T& a, const FieldAccessor& b) TIGHTDB_NOEXCEPT
    {
        return a == b.get();
    }

    template<class T> friend bool operator!=(const T& a, const FieldAccessor& b) TIGHTDB_NOEXCEPT
    {
        return a != b.get();
    }

protected:
    MixedFieldAccessorBase(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}
};


/// Field accessor specialization for mixed type of non-const parent.
template<class Taboid, int col_idx>
class FieldAccessor<Taboid, col_idx, Mixed, false>:
    public MixedFieldAccessorBase<Taboid, col_idx, FieldAccessor<Taboid, col_idx, Mixed, false> > {
private:
    typedef FieldAccessor<Taboid, col_idx, Mixed, false> This;
    typedef MixedFieldAccessorBase<Taboid, col_idx, This> Base;

public:
    /// Returns null if the current value is not a subtable.
    TableRef get_subtable() const
    {
        return Base::m_table->get_impl()->get_subtable(col_idx, Base::m_row_idx);
    }

    /// Overwrites the current value with an empty subtable and
    /// returns a reference to it.
    TableRef set_subtable() const
    {
        Base::m_table->get_impl()->clear_subtable(col_idx, Base::m_row_idx);
        return get_subtable();
    }

    /// Overwrites the current value with a copy of the specified
    /// table and returns a reference to the copy.
    TableRef set_subtable(const Table& t) const
    {
        t.set_into_mixed(Base::m_table->get_impl(), col_idx, Base::m_row_idx);
        return get_subtable();
    }

    /// This function makes the following assumption: If the current
    /// value is a subtable, then it is a subtable of the specified
    /// type. If this is not the case, your computer may catch fire.
    ///
    /// To safely and efficiently check whether the current value is a
    /// subtable of any of a set of specific table types, you may do
    /// as follows:
    ///
    /// \code{.cpp}
    ///
    ///   if (TableRef subtable = my_table[i].mixed.get_subtable()) {
    ///     if (subtable->is_a<MyFirstSubtable>()) {
    ///       MyFirstSubtable::Ref s = unchecked_cast<MyFirstSubtable>(move(subtable))) {
    ///       // ...
    ///     }
    ///     else if (subtable->is_a<MySecondSubtable>()) {
    ///       MySecondSubtable::Ref s = unchecked_cast<MySecondSubtable>(move(subtable))) {
    ///       // ...
    ///     }
    ///   }
    ///
    /// \endcode
    ///
    /// \return Null if the current value is not a subtable.
    ///
    /// \note This function is generally unsafe because it does not
    /// check that the specified table type matches the actual table
    /// type.
    ///
    /// FIXME: Consider deleting this function, since it is both
    /// unsafe and superfluous.
    template<class T> BasicTableRef<T> get_subtable() const
    {
        TIGHTDB_ASSERT(!Base::is_subtable() || Base::template is_subtable<T>());
        return unchecked_cast<T>(get_subtable());
    }

    /// Overwrites the current value with an empty subtable and
    /// returns a reference to it.
    ///
    /// \tparam T The subtable type. It must not be const-qualified.
    template<class T> BasicTableRef<T> set_subtable() const
    {
        BasicTableRef<T> t = unchecked_cast<T>(set_subtable());
        T::set_dynamic_type(*t);
        return t;
    }

    /// Overwrites the current value with a copy of the specified
    /// table and returns a reference to the copy.
    template<class T> typename T::Ref set_subtable(const T& t) const
    {
        t.set_into_mixed(Base::m_table->get_impl(), col_idx, Base::m_row_idx);
        return unchecked_cast<T>(get_subtable());
    }


    explicit FieldAccessor(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}
};


/// Field accessor specialization for mixed type of const parent.
template<class Taboid, int col_idx>
class FieldAccessor<Taboid, col_idx, Mixed, true>:
    public MixedFieldAccessorBase<Taboid, col_idx, FieldAccessor<Taboid, col_idx, Mixed, true> > {
private:
    typedef FieldAccessor<Taboid, col_idx, Mixed, true> This;
    typedef MixedFieldAccessorBase<Taboid, col_idx, This> Base;

public:
    ConstTableRef get_subtable() const
    {
        return Base::m_table->get_impl()->get_subtable(col_idx, Base::m_row_idx);
    }

    /// FIXME: Consider deleting this function, since it is both
    /// unsafe and superfluous.
    template<class T> BasicTableRef<const T> get_subtable() const
    {
        TIGHTDB_ASSERT(!Base::is_subtable() || Base::template is_subtable<T>());
        return unchecked_cast<const T>(get_subtable());
    }


    explicit FieldAccessor(typename Base::Init i) TIGHTDB_NOEXCEPT: Base(i) {}
};




/// This class gives access to a column of a table.
///
/// \tparam Taboid Either a table or a table view. Constness of access
/// is controlled by what is allowed to be done with/on a 'Taboid*'.
template<class Taboid, int col_idx, class Type> class ColumnAccessor;


/// Commmon base class for all column accessor specializations.
template<class Taboid, int col_idx, class Type> class ColumnAccessorBase {
protected:
    typedef typename GetTableFromView<Taboid>::type RealTable;
    typedef FieldAccessor<Taboid, col_idx, Type, TableIsConst<Taboid>::value> Field;

public:
    Field operator[](std::size_t row_idx) const
    {
        return Field(std::make_pair(m_table, row_idx));
    }

    bool has_search_index() const { return m_table->get_impl()->has_search_index(col_idx); }
    void add_search_index() const { m_table->get_impl()->add_search_index(col_idx); }

    BasicTableView<RealTable> get_sorted_view(bool ascending=true) const
    {
        return m_table->get_impl()->get_sorted_view(col_idx, ascending);
    }

    void sort(bool ascending = true) const { m_table->get_impl()->sort(col_idx, ascending); }

protected:
    Taboid* const m_table;

    explicit ColumnAccessorBase(Taboid* t) TIGHTDB_NOEXCEPT: m_table(t) {}
};


/// Column accessor specialization for integers.
template<class Taboid, int col_idx>
class ColumnAccessor<Taboid, col_idx, int64_t>:
    public ColumnAccessorBase<Taboid, col_idx, int64_t>, public Columns<int64_t> {
private:
    typedef ColumnAccessorBase<Taboid, col_idx, int64_t> Base;

public:
    explicit ColumnAccessor(Taboid* t) TIGHTDB_NOEXCEPT: Base(t) {
        // Columns store their own copy of m_table in order not to have too much class dependency/entanglement
        Columns<int64_t>::m_column = col_idx;
        Columns<int64_t>::m_table = reinterpret_cast<const Table*>(Base::m_table->get_impl());
    }

    // fixme/todo, reinterpret_cast to make it compile with TableView which is not supported yet
    virtual Subexpr& clone() {
        return *new Columns<int64_t>(col_idx, reinterpret_cast<const Table*>(Base::m_table->get_impl()));
    }

    std::size_t find_first(int64_t value) const
    {
        return Base::m_table->get_impl()->find_first_int(col_idx, value);
    }

    BasicTableView<typename Base::RealTable> find_all(int64_t value) const
    {
        return Base::m_table->get_impl()->find_all_int(col_idx, value);
    }

    size_t count(int64_t target) const
    {
        return Base::m_table->get_impl()->count_int(col_idx, target);
    }

    int64_t sum() const
    {
        return Base::m_table->get_impl()->sum_int(col_idx);
    }

    int64_t maximum(std::size_t* return_ndx = 0) const
    {
        return Base::m_table->get_impl()->maximum_int(col_idx, return_ndx);
    }

    int64_t minimum(std::size_t* return_ndx = 0) const
    {
        return Base::m_table->get_impl()->minimum_int(col_idx, return_ndx);
    }

    double average() const
    {
        return Base::m_table->get_impl()->average_int(col_idx);
    }

    const ColumnAccessor& operator+=(int64_t value) const
    {
        Base::m_table->get_impl()->add_int(col_idx, value);
        return *this;
    }

    std::size_t lower_bound(int64_t value) const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->lower_bound_int(col_idx, value);
    }

    std::size_t upper_bound(int64_t value) const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->upper_bound_int(col_idx, value);
    }
};


/// Column accessor specialization for float
template<class Taboid, int col_idx>
class ColumnAccessor<Taboid, col_idx, float>:
    public ColumnAccessorBase<Taboid, col_idx, float>, public Columns<float> {
private:
    typedef ColumnAccessorBase<Taboid, col_idx, float> Base;

public:
    explicit ColumnAccessor(Taboid* t) TIGHTDB_NOEXCEPT: Base(t) {
        // Columns store their own copy of m_table in order not to have too much class dependency/entanglement
        Columns<float>::m_column = col_idx;
        Columns<float>::m_table = reinterpret_cast<const Table*>(Base::m_table->get_impl());
    }

    // fixme/todo, reinterpret_cast to make it compile with TableView which is not supported yet
    virtual Subexpr& clone() {
        return *new Columns<float>(col_idx, reinterpret_cast<const Table*>(Base::m_table->get_impl()));
    }

    std::size_t find_first(float value) const
    {
        return Base::m_table->get_impl()->find_first_float(col_idx, value);
    }

    BasicTableView<typename Base::RealTable> find_all(float value) const
    {
        return Base::m_table->get_impl()->find_all_float(col_idx, value);
    }

    size_t count(float target) const
    {
        return Base::m_table->get_impl()->count_float(col_idx, target);
    }

    double sum() const
    {
        return Base::m_table->get_impl()->sum_float(col_idx);
    }

    float maximum(std::size_t* return_ndx = 0) const
    {
        return Base::m_table->get_impl()->maximum_float(col_idx, return_ndx);
    }

    float minimum(std::size_t* return_ndx = 0) const
    {
        return Base::m_table->get_impl()->minimum_float(col_idx, return_ndx);
    }

    double average() const
    {
        return Base::m_table->get_impl()->average_float(col_idx);
    }

    const ColumnAccessor& operator+=(float value) const
    {
        Base::m_table->get_impl()->add_float(col_idx, value);
        return *this;
    }

    std::size_t lower_bound(float value) const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->lower_bound_float(col_idx, value);
    }

    std::size_t upper_bound(float value) const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->upper_bound_float(col_idx, value);
    }
};


/// Column accessor specialization for double
template<class Taboid, int col_idx>
class ColumnAccessor<Taboid, col_idx, double>:
    public ColumnAccessorBase<Taboid, col_idx, double>, public Columns<double> {
private:
    typedef ColumnAccessorBase<Taboid, col_idx, double> Base;

public:
    explicit ColumnAccessor(Taboid* t) TIGHTDB_NOEXCEPT: Base(t) {
        // Columns store their own copy of m_table in order not to have too much class dependency/entanglement
        Columns<double>::m_column = col_idx;
        Columns<double>::m_table = reinterpret_cast<const Table*>(Base::m_table->get_impl());
    }

    // fixme/todo, reinterpret_cast to make it compile with TableView which is not supported yet
    virtual Subexpr& clone() {
        return *new Columns<double>(col_idx, reinterpret_cast<const Table*>(Base::m_table->get_impl()));
    }

    std::size_t find_first(double value) const
    {
        return Base::m_table->get_impl()->find_first_double(col_idx, value);
    }

    BasicTableView<typename Base::RealTable> find_all(double value) const
    {
        return Base::m_table->get_impl()->find_all_double(col_idx, value);
    }

    size_t count(double target) const
    {
        return Base::m_table->get_impl()->count_double(col_idx, target);
    }

    double sum() const
    {
        return Base::m_table->get_impl()->sum_double(col_idx);
    }

    double maximum(std::size_t* return_ndx = 0) const
    {
        return Base::m_table->get_impl()->maximum_double(col_idx, return_ndx);
    }

    double minimum(std::size_t* return_ndx = 0) const
    {
        return Base::m_table->get_impl()->minimum_double(col_idx, return_ndx);
    }

    double average() const
    {
        return Base::m_table->get_impl()->average_double(col_idx);
    }

    const ColumnAccessor& operator+=(double value) const
    {
        Base::m_table->get_impl()->add_double(col_idx, value);
        return *this;
    }

    std::size_t lower_bound(float value) const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->lower_bound_double(col_idx, value);
    }

    std::size_t upper_bound(float value) const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->upper_bound_double(col_idx, value);
    }
};


/// Column accessor specialization for booleans.
template<class Taboid, int col_idx>
class ColumnAccessor<Taboid, col_idx, bool>: public ColumnAccessorBase<Taboid, col_idx, bool> {
private:
    typedef ColumnAccessorBase<Taboid, col_idx, bool> Base;

public:
    explicit ColumnAccessor(Taboid* t) TIGHTDB_NOEXCEPT: Base(t) {}

    std::size_t find_first(bool value) const
    {
        return Base::m_table->get_impl()->find_first_bool(col_idx, value);
    }

    BasicTableView<typename Base::RealTable> find_all(bool value) const
    {
        return Base::m_table->get_impl()->find_all_bool(col_idx, value);
    }

    std::size_t lower_bound(bool value) const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->lower_bound_bool(col_idx, value);
    }

    std::size_t upper_bound(bool value) const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->upper_bound_bool(col_idx, value);
    }
};


/// Column accessor specialization for enumerations.
template<class Taboid, int col_idx, class E>
class ColumnAccessor<Taboid, col_idx, SpecBase::Enum<E> >:
    public ColumnAccessorBase<Taboid, col_idx, SpecBase::Enum<E> > {
private:
    typedef ColumnAccessorBase<Taboid, col_idx, SpecBase::Enum<E> > Base;

public:
    explicit ColumnAccessor(Taboid* t) TIGHTDB_NOEXCEPT: Base(t) {}

    std::size_t find_first(E value) const
    {
        return Base::m_table->get_impl()->find_first_int(col_idx, int64_t(value));
    }

    BasicTableView<typename Base::RealTable> find_all(E value) const
    {
        return Base::m_table->get_impl()->find_all_int(col_idx, int64_t(value));
    }
};


/// Column accessor specialization for dates.
template<class Taboid, int col_idx>
class ColumnAccessor<Taboid, col_idx, DateTime>: public ColumnAccessorBase<Taboid, col_idx, DateTime> {
private:
    typedef ColumnAccessorBase<Taboid, col_idx, DateTime> Base;

public:
    explicit ColumnAccessor(Taboid* t) TIGHTDB_NOEXCEPT: Base(t) {}

    DateTime maximum(std::size_t* return_ndx = 0) const
    {
        return Base::m_table->get_impl()->maximum_datetime(col_idx, return_ndx);
    }

    DateTime minimum(std::size_t* return_ndx = 0) const
    {
        return Base::m_table->get_impl()->minimum_datetime(col_idx, return_ndx);
    }

    std::size_t find_first(DateTime value) const
    {
        return Base::m_table->get_impl()->find_first_datetime(col_idx, value);
    }

    BasicTableView<typename Base::RealTable> find_all(DateTime value) const
    {
        return Base::m_table->get_impl()->find_all_datetime(col_idx, value);
    }
};


/// Column accessor specialization for strings.
template<class Taboid, int col_idx>
class ColumnAccessor<Taboid, col_idx, StringData>:
    public ColumnAccessorBase<Taboid, col_idx, StringData>, public Columns<StringData> {
private:
    typedef ColumnAccessorBase<Taboid, col_idx, StringData> Base;
public:
    explicit ColumnAccessor(Taboid* t) TIGHTDB_NOEXCEPT: Base(t) {
        // Columns store their own copy of m_table in order not to have too much class dependency/entanglement
        Columns<StringData>::m_column = col_idx;
        Columns<StringData>::m_table = reinterpret_cast<const Table*>(Base::m_table->get_impl());
    }

    size_t count(StringData value) const
    {
        return Base::m_table->get_impl()->count_string(col_idx, value);
    }

    std::size_t find_first(StringData value) const
    {
        return Base::m_table->get_impl()->find_first_string(col_idx, value);
    }

    BasicTableView<typename Base::RealTable> find_all(StringData value) const
    {
        return Base::m_table->get_impl()->find_all_string(col_idx, value);
    }

    BasicTableView<typename Base::RealTable> get_distinct_view() const
    {
        return Base::m_table->get_impl()->get_distinct_view(col_idx);
    }

    std::size_t lower_bound(StringData value) const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->lower_bound_string(col_idx, value);
    }

    std::size_t upper_bound(StringData value) const TIGHTDB_NOEXCEPT
    {
        return Base::m_table->upper_bound_string(col_idx, value);
    }
};


/// Column accessor specialization for binary data.
template<class Taboid, int col_idx>
class ColumnAccessor<Taboid, col_idx, BinaryData>:
    public ColumnAccessorBase<Taboid, col_idx, BinaryData> {
private:
    typedef ColumnAccessorBase<Taboid, col_idx, BinaryData> Base;

public:
    explicit ColumnAccessor(Taboid* t) TIGHTDB_NOEXCEPT: Base(t) {}

    std::size_t find_first(const BinaryData &value) const
    {
        return Base::m_table->get_impl()->find_first_binary(col_idx, value.data(), value.size());
    }

    BasicTableView<typename Base::RealTable> find_all(const BinaryData &value) const
    {
        return Base::m_table->get_impl()->find_all_binary(col_idx, value.data(), value.size());
    }
};


/// Column accessor specialization for subtables.
template<class Taboid, int col_idx, class Subtab>
class ColumnAccessor<Taboid, col_idx, SpecBase::Subtable<Subtab> >:
    public ColumnAccessorBase<Taboid, col_idx, SpecBase::Subtable<Subtab> > {
private:
    typedef ColumnAccessorBase<Taboid, col_idx, SpecBase::Subtable<Subtab> > Base;

public:
    explicit ColumnAccessor(Taboid* t) TIGHTDB_NOEXCEPT: Base(t) {}
};


/// Column accessor specialization for mixed type.
template<class Taboid, int col_idx>
class ColumnAccessor<Taboid, col_idx, Mixed>: public ColumnAccessorBase<Taboid, col_idx, Mixed> {
private:
    typedef ColumnAccessorBase<Taboid, col_idx, Mixed> Base;

public:
    explicit ColumnAccessor(Taboid* t) TIGHTDB_NOEXCEPT: Base(t) {}
};



/// ***********************************************************************************************
/// This class implements a column of a table as used in a table query.
///
/// \tparam Taboid Matches either 'BasicTable<Spec>' or
/// 'BasicTableView<Tab>'. Neither may be const-qualified.
///
/// FIXME: These do not belong in this file!
template<class Taboid, int col_idx, class Type> class QueryColumn;


/// Commmon base class for all query column specializations.
template<class Taboid, int col_idx, class Type> class QueryColumnBase {
protected:
    typedef typename Taboid::Query Query;
    Query* const m_query;
    explicit QueryColumnBase(Query* q) TIGHTDB_NOEXCEPT: m_query(q) {}

    Query& equal(const Type& value) const
    {
        m_query->m_impl.equal(col_idx, value);
        return *m_query;
    }

    Query& not_equal(const Type& value) const
    {
        m_query->m_impl.not_equal(col_idx, value);
        return *m_query;
    }
};


/// QueryColumn specialization for integers.
template<class Taboid, int col_idx>
class QueryColumn<Taboid, col_idx, int64_t>: public QueryColumnBase<Taboid, col_idx, int64_t> {
private:
    typedef QueryColumnBase<Taboid, col_idx, int64_t> Base;
    typedef typename Taboid::Query Query;

public:
    explicit QueryColumn(Query* q) TIGHTDB_NOEXCEPT: Base(q) {}

    // Todo, these do not turn up in Visual Studio 2013 intellisense
    using Base::equal;
    using Base::not_equal;

    Query& greater(int64_t value) const
    {
        Base::m_query->m_impl.greater(col_idx, value);
        return *Base::m_query;
    }

    Query& greater_equal(int64_t value) const
    {
        Base::m_query->m_impl.greater_equal(col_idx, value);
        return *Base::m_query;
    }

    Query& less(int64_t value) const
    {
        Base::m_query->m_impl.less(col_idx, value);
        return *Base::m_query;
    }

    Query& less_equal(int64_t value) const
    {
        Base::m_query->m_impl.less_equal(col_idx, value);
        return *Base::m_query;
    }

    Query& between(int64_t from, int64_t to) const
    {
        Base::m_query->m_impl.between(col_idx, from, to);
        return *Base::m_query;
    };

    int64_t sum(std::size_t* resultcount = 0, std::size_t start = 0,
                std::size_t end = std::size_t(-1), std::size_t limit=std::size_t(-1)) const
    {
        return Base::m_query->m_impl.sum_int(col_idx, resultcount, start, end, limit);
    }

    int64_t maximum(std::size_t* resultcount = 0, std::size_t start = 0,
                    std::size_t end = std::size_t(-1), std::size_t limit=std::size_t(-1), 
                    std::size_t* return_ndx = 0) const
    {
        return Base::m_query->m_impl.maximum_int(col_idx, resultcount, start, end, limit, return_ndx);
    }

    int64_t minimum(std::size_t* resultcount = 0, std::size_t start = 0,
                    std::size_t end = std::size_t(-1), std::size_t limit=std::size_t(-1),
                    std::size_t* return_ndx = 0) const
    {
        return Base::m_query->m_impl.minimum_int(col_idx, resultcount, start, end, limit, return_ndx);
    }

    double average(std::size_t* resultcount = 0, std::size_t start = 0,
                   std::size_t end=std::size_t(-1), std::size_t limit=std::size_t(-1)) const
    {
        return Base::m_query->m_impl.average_int(col_idx, resultcount, start, end, limit);
    }
};



/// QueryColumn specialization for floats.
template<class Taboid, int col_idx>
class QueryColumn<Taboid, col_idx, float>: public QueryColumnBase<Taboid, col_idx, float> {
private:
    typedef QueryColumnBase<Taboid, col_idx, float> Base;
    typedef typename Taboid::Query Query;

public:
    explicit QueryColumn(Query* q) TIGHTDB_NOEXCEPT: Base(q) {}
    using Base::equal;
    using Base::not_equal;

    Query& greater(float value) const
    {
        Base::m_query->m_impl.greater(col_idx, value);
        return *Base::m_query;
    }

    Query& greater_equal(float value) const
    {
        Base::m_query->m_impl.greater_equal(col_idx, value);
        return *Base::m_query;
    }

    Query& less(float value) const
    {
        Base::m_query->m_impl.less(col_idx, value);
        return *Base::m_query;
    }

    Query& less_equal(float value) const
    {
        Base::m_query->m_impl.less_equal(col_idx, value);
        return *Base::m_query;
    }

    Query& between(float from, float to) const
    {
        Base::m_query->m_impl.between(col_idx, from, to);
        return *Base::m_query;
    };

    double sum(std::size_t* resultcount = 0, std::size_t start = 0,
               std::size_t end = std::size_t(-1), std::size_t limit=std::size_t(-1)) const
    {
        return Base::m_query->m_impl.sum_float(col_idx, resultcount, start, end, limit);
    }

    float maximum(std::size_t* resultcount = 0, std::size_t start = 0,
                    std::size_t end = std::size_t(-1), std::size_t limit=std::size_t(-1),
                    std::size_t* return_ndx = 0) const
    {
        return Base::m_query->m_impl.maximum_float(col_idx, resultcount, start, end, limit, return_ndx);
    }

    float minimum(std::size_t* resultcount = 0, std::size_t start = 0,
                    std::size_t end = std::size_t(-1), std::size_t limit=std::size_t(-1),
                    std::size_t* return_ndx = 0) const
    {
        return Base::m_query->m_impl.minimum_float(col_idx, resultcount, start, end, limit, return_ndx);
    }

    double average(std::size_t* resultcount = 0, std::size_t start = 0,
                   std::size_t end=std::size_t(-1), std::size_t limit=std::size_t(-1)) const
    {
        return Base::m_query->m_impl.average_float(col_idx, resultcount, start, end, limit);
    }
};



/// QueryColumn specialization for doubles.
template<class Taboid, int col_idx>
class QueryColumn<Taboid, col_idx, double>: public QueryColumnBase<Taboid, col_idx, double> {
private:
    typedef QueryColumnBase<Taboid, col_idx, double> Base;
    typedef typename Taboid::Query Query;

public:
    explicit QueryColumn(Query* q) TIGHTDB_NOEXCEPT: Base(q) {}
    using Base::equal;
    using Base::not_equal;

    Query& greater(double value) const
    {
        Base::m_query->m_impl.greater(col_idx, value);
        return *Base::m_query;
    }

    Query& greater_equal(double value) const
    {
        Base::m_query->m_impl.greater_equal(col_idx, value);
        return *Base::m_query;
    }

    Query& less(double value) const
    {
        Base::m_query->m_impl.less(col_idx, value);
        return *Base::m_query;
    }

    Query& less_equal(double value) const
    {
        Base::m_query->m_impl.less_equal(col_idx, value);
        return *Base::m_query;
    }

    Query& between(double from, double to) const
    {
        Base::m_query->m_impl.between(col_idx, from, to);
        return *Base::m_query;
    };

    double sum(std::size_t* resultcount = 0, std::size_t start = 0,
               std::size_t end = std::size_t(-1), std::size_t limit=std::size_t(-1)) const
    {
        return Base::m_query->m_impl.sum_double(col_idx, resultcount, start, end, limit);
    }

    double maximum(std::size_t* resultcount = 0, std::size_t start = 0,
                    std::size_t end = std::size_t(-1), std::size_t limit=std::size_t(-1),
                    std::size_t* return_ndx = 0) const
    {
        return Base::m_query->m_impl.maximum_double(col_idx, resultcount, start, end, limit, return_ndx);
    }

    double minimum(std::size_t* resultcount = 0, std::size_t start = 0,
                    std::size_t end = std::size_t(-1), std::size_t limit=std::size_t(-1),
                    std::size_t* return_ndx = 0) const
    {
        return Base::m_query->m_impl.minimum_double(col_idx, resultcount, start, end, limit, return_ndx);
    }

    double average(std::size_t* resultcount = 0, std::size_t start = 0,
                   std::size_t end=std::size_t(-1), std::size_t limit=std::size_t(-1)) const
    {
        return Base::m_query->m_impl.average_double(col_idx, resultcount, start, end, limit);
    }
};



/// QueryColumn specialization for booleans.
template<class Taboid, int col_idx>
class QueryColumn<Taboid, col_idx, bool>: public QueryColumnBase<Taboid, col_idx, bool> {
private:
    typedef QueryColumnBase<Taboid, col_idx, bool> Base;
    typedef typename Taboid::Query Query;

public:
    explicit QueryColumn(Query* q) TIGHTDB_NOEXCEPT: Base(q) {}
    using Base::equal;
    using Base::not_equal;
};


/// QueryColumn specialization for enumerations.
template<class Taboid, int col_idx, class E>
class QueryColumn<Taboid, col_idx, SpecBase::Enum<E> >:
    public QueryColumnBase<Taboid, col_idx, SpecBase::Enum<E> > {
private:
    typedef QueryColumnBase<Taboid, col_idx, SpecBase::Enum<E> > Base;
    typedef typename Taboid::Query Query;

public:
    explicit QueryColumn(Query* q) TIGHTDB_NOEXCEPT: Base(q) {}
    using Base::equal;
    using Base::not_equal;
};


/// QueryColumn specialization for dates.
template<class Taboid, int col_idx>
class QueryColumn<Taboid, col_idx, DateTime>: public QueryColumnBase<Taboid, col_idx, DateTime> {
private:
    typedef QueryColumnBase<Taboid, col_idx, DateTime> Base;
    typedef typename Taboid::Query Query;

public:
    explicit QueryColumn(Query* q) TIGHTDB_NOEXCEPT: Base(q) {}

    Query& equal(DateTime value) const
    {
        Base::m_query->m_impl.equal_datetime(col_idx, value);
        return *Base::m_query;
    }

    Query& not_equal(DateTime value) const
    {
        Base::m_query->m_impl.not_equal_datetime(col_idx, value);
        return *Base::m_query;
    }

    Query& greater(DateTime value) const
    {
        Base::m_query->m_impl.greater_datetime(col_idx, value);
        return *Base::m_query;
    }

    Query& greater_equal(DateTime value) const
    {
        Base::m_query->m_impl.greater_equal_datetime(col_idx, value);
        return *Base::m_query;
    }

    Query& less(DateTime value) const
    {
        Base::m_query->m_impl.less_datetime(col_idx, value);
        return *Base::m_query;
    }

    Query& less_equal(DateTime value) const
    {
        Base::m_query->m_impl.less_equal_datetime(col_idx, value);
        return *Base::m_query;
    }

    Query& between(DateTime from, DateTime to) const
    {
        Base::m_query->m_impl.between_datetime(col_idx, from, to);
        return *Base::m_query;
    };

    DateTime maximum(std::size_t* resultcount = 0, std::size_t start = 0,
                 std::size_t end = std::size_t(-1), std::size_t limit=std::size_t(-1),
                 std::size_t* return_ndx = 0) const
    {
        return Base::m_query->m_impl.maximum_datetime(col_idx, resultcount, start, end, limit, return_ndx);
    }

    DateTime minimum(std::size_t* resultcount = 0, std::size_t start = 0,
                 std::size_t end = std::size_t(-1), std::size_t limit=std::size_t(-1),
                 std::size_t* return_ndx = 0) const
    {
        return Base::m_query->m_impl.minimum_datetime(col_idx, resultcount, start, end, limit, return_ndx);
    }
};


/// QueryColumn specialization for strings.
template<class Taboid, int col_idx>
class QueryColumn<Taboid, col_idx, StringData>:
    public QueryColumnBase<Taboid, col_idx, StringData> {
private:
    typedef QueryColumnBase<Taboid, col_idx, StringData> Base;
    typedef typename Taboid::Query Query;

public:
    explicit QueryColumn(Query* q) TIGHTDB_NOEXCEPT: Base(q) {}

    Query& equal(StringData value, bool case_sensitive=true) const
    {
        Base::m_query->m_impl.equal(col_idx, value, case_sensitive);
        return *Base::m_query;
    }

    Query& not_equal(StringData value, bool case_sensitive=true) const
    {
        Base::m_query->m_impl.not_equal(col_idx, value, case_sensitive);
        return *Base::m_query;
    }

    Query& begins_with(StringData value, bool case_sensitive=true) const
    {
        Base::m_query->m_impl.begins_with(col_idx, value, case_sensitive);
        return *Base::m_query;
    }

    Query& ends_with(StringData value, bool case_sensitive=true) const
    {
        Base::m_query->m_impl.ends_with(col_idx, value, case_sensitive);
        return *Base::m_query;
    }

    Query& contains(StringData value, bool case_sensitive=true) const
    {
        Base::m_query->m_impl.contains(col_idx, value, case_sensitive);
        return *Base::m_query;
    }
};


/// QueryColumn specialization for binary data.
template<class Taboid, int col_idx>
class QueryColumn<Taboid, col_idx, BinaryData>:
    public QueryColumnBase<Taboid, col_idx, BinaryData> {
private:
    typedef QueryColumnBase<Taboid, col_idx, BinaryData> Base;
    typedef typename Taboid::Query Query;

public:
    explicit QueryColumn(Query* q) TIGHTDB_NOEXCEPT: Base(q) {}

    Query& equal(BinaryData value) const
    {
        Base::m_query->m_impl.equal(col_idx, value);
        return *Base::m_query;
    }

    Query& not_equal(BinaryData value) const
    {
        Base::m_query->m_impl.not_equal(col_idx, value);
        return *Base::m_query;
    }

    Query& begins_with(BinaryData value) const
    {
        Base::m_query->m_impl.begins_with(col_idx, value);
        return *Base::m_query;
    }

    Query& ends_with(BinaryData value) const
    {
        Base::m_query->m_impl.ends_with(col_idx, value);
        return *Base::m_query;
    }

    Query& contains(BinaryData value) const
    {
        Base::m_query->m_impl.contains(col_idx, value);
        return *Base::m_query;
    }
};


/// QueryColumn specialization for subtables.
template<class Taboid, int col_idx, class Subtab>
class QueryColumn<Taboid, col_idx, SpecBase::Subtable<Subtab> > {
private:
    typedef typename Taboid::Query Query;
    Query* const m_query;

public:
    explicit QueryColumn(Query* q) TIGHTDB_NOEXCEPT: m_query(q) {}

    Query& subtable()
    {
        m_query->m_impl.subtable(col_idx);
        return *m_query;
    }
};


/// QueryColumn specialization for mixed type.
template<class Taboid, int col_idx> class QueryColumn<Taboid, col_idx, Mixed> {
private:
    typedef typename Taboid::Query Query;

public:
    explicit QueryColumn(Query*) TIGHTDB_NOEXCEPT {}
};


} // namespace _impl
} // namespaced tightdb

#endif // TIGHTDB_TABLE_ACCESSORS_HPP
