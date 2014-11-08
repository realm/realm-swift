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
#ifndef TIGHTDB_TABLE_VIEW_BASIC_HPP
#define TIGHTDB_TABLE_VIEW_BASIC_HPP

#include <tightdb/util/type_traits.hpp>
#include <tightdb/table_view.hpp>
#include <tightdb/table_accessors.hpp>

namespace tightdb {


/// Common base class for BasicTableView<Tab> and BasicTableView<const
/// Tab>.
///
/// \tparam Impl Is either TableView or ConstTableView.
template<class Tab, class View, class Impl> class BasicTableViewBase {
public:
    typedef typename Tab::spec_type spec_type;
    typedef Tab table_type;

    bool is_empty() const TIGHTDB_NOEXCEPT { return m_impl.is_empty(); }
    bool is_attached() const TIGHTDB_NOEXCEPT { return m_impl.is_attached(); }
    size_t size() const TIGHTDB_NOEXCEPT { return m_impl.size(); }

    // Get row index in the source table this view is "looking" at.
    size_t get_source_ndx(size_t row_ndx) const TIGHTDB_NOEXCEPT
    {
        return m_impl.get_source_ndx(row_ndx);
    }

    void to_json(std::ostream& out) const { m_impl.to_json(out); };
    void to_string(std::ostream& out, size_t limit=500) const
    {
        m_impl.to_string(out, limit);
    }
    void row_to_string(std::size_t row_ndx, std::ostream& out) const
    {
        m_impl.row_to_string(row_ndx, out);
    }

private:
    typedef typename Tab::spec_type Spec;

    template<int col_idx> struct Col {
        typedef typename util::TypeAt<typename Spec::Columns, col_idx>::type value_type;
        typedef _impl::ColumnAccessor<View, col_idx, value_type> type;
    };
    typedef typename Spec::template ColNames<Col, View*> ColsAccessor;

    template<int col_idx> struct ConstCol {
        typedef typename util::TypeAt<typename Spec::Columns, col_idx>::type value_type;
        typedef _impl::ColumnAccessor<const View, col_idx, value_type> type;
    };
    typedef typename Spec::template ColNames<ConstCol, const View*> ConstColsAccessor;

public:
    ColsAccessor column() TIGHTDB_NOEXCEPT
    {
        return ColsAccessor(static_cast<View*>(this));
    }

    ConstColsAccessor column() const TIGHTDB_NOEXCEPT
    {
        return ConstColsAccessor(static_cast<const View*>(this));
    }

private:
    template<int col_idx> struct Field {
        typedef typename util::TypeAt<typename Spec::Columns, col_idx>::type value_type;
        typedef _impl::FieldAccessor<View, col_idx, value_type, util::IsConst<Tab>::value> type;
    };
    typedef std::pair<View*, std::size_t> FieldInit;
    typedef typename Spec::template ColNames<Field, FieldInit> RowAccessor;

    template<int col_idx> struct ConstField {
        typedef typename util::TypeAt<typename Spec::Columns, col_idx>::type value_type;
        typedef _impl::FieldAccessor<const View, col_idx, value_type, true> type;
    };
    typedef std::pair<const View*, std::size_t> ConstFieldInit;
    typedef typename Spec::template ColNames<ConstField, ConstFieldInit> ConstRowAccessor;

public:
    RowAccessor operator[](std::size_t row_idx) TIGHTDB_NOEXCEPT
    {
        return RowAccessor(std::make_pair(static_cast<View*>(this), row_idx));
    }

    ConstRowAccessor operator[](std::size_t row_idx) const TIGHTDB_NOEXCEPT
    {
        return ConstRowAccessor(std::make_pair(static_cast<const View*>(this), row_idx));
    }

protected:
    template<class, int, class, bool> friend class _impl::FieldAccessor;
    template<class, int, class> friend class _impl::MixedFieldAccessorBase;
    template<class Spec> friend class BasicTable;

    Impl m_impl;

    BasicTableViewBase() {}
    BasicTableViewBase(Impl i): m_impl(move(i)) {}

    Impl* get_impl() TIGHTDB_NOEXCEPT { return &m_impl; }
    const Impl* get_impl() const TIGHTDB_NOEXCEPT { return &m_impl; }
};




/// A BasicTableView wraps a TableView and provides a type and
/// structure safe set of access methods. The TableView methods are
/// not visible through a BasicTableView. A BasicTableView is used
/// essentially the same way as a BasicTable.
///
/// Note that this class is specialized for const-qualified parent
/// tables.
///
/// There are three levels of consteness to consider. A 'const
/// BasicTableView<Tab>' prohibits any modification of the table as
/// well as any modification of the table view, regardless of whether
/// Tab is const-qualified or not.
///
/// A non-const 'BasicTableView<Tab>' where Tab is const-qualified,
/// still does not allow any modification of the parent
/// table. However, the view itself may be modified, for example, by
/// reordering its rows.
///
/// A non-const 'BasicTableView<Tab>' where Tab is not
/// const-qualified, gives full modification access to both the parent
/// table and the view.
///
/// Just like TableView, a BasicTableView has both copy and move
/// semantics. See TableView for more on this.
///
/// \tparam Tab The possibly const-qualified parent table type. This
/// must always be an instance of the BasicTable template.
///
template<class Tab>
class BasicTableView: public BasicTableViewBase<Tab, BasicTableView<Tab>, TableView> {
private:
    typedef BasicTableViewBase<Tab, BasicTableView<Tab>, TableView> Base;

public:
    BasicTableView() {}
    BasicTableView& operator=(BasicTableView tv) { Base::m_impl = move(tv.m_impl); return *this; }
    friend BasicTableView move(BasicTableView& tv) { return BasicTableView(&tv); }

    // Deleting
    void clear() { Base::m_impl.clear(); }
    void remove(size_t ndx) { Base::m_impl.remove(ndx); }
    void remove_last() { Base::m_impl.remove_last(); }

    // Resort after requery
    void apply_same_order(BasicTableView& order) { Base::m_impl.apply_same_order(order.m_impl); };

    Tab& get_parent() TIGHTDB_NOEXCEPT
    {
        return static_cast<Tab&>(Base::m_impl.get_parent());
    }

    const Tab& get_parent() const TIGHTDB_NOEXCEPT
    {
        return static_cast<const Tab&>(Base::m_impl.get_parent());
    }

private:
    BasicTableView(BasicTableView* tv): Base(move(tv->m_impl)) {}
    BasicTableView(TableView tv): Base(move(tv)) {}

    template<class Subtab> Subtab* get_subtable_ptr(size_t column_ndx, size_t ndx)
    {
        return get_parent().template
            get_subtable_ptr<Subtab>(column_ndx, Base::m_impl.get_source_ndx(ndx));
    }

    template<class Subtab> const Subtab* get_subtable_ptr(size_t column_ndx, size_t ndx) const
    {
        return get_parent().template
            get_subtable_ptr<Subtab>(column_ndx, Base::m_impl.get_source_ndx(ndx));
    }

    friend class BasicTableView<const Tab>;
    template<class, int, class, bool> friend class _impl::FieldAccessor;
    template<class, int, class> friend class _impl::MixedFieldAccessorBase;
    template<class, int, class> friend class _impl::ColumnAccessorBase;
    template<class, int, class> friend class _impl::ColumnAccessor;
    friend class Tab::Query;
};




/// Specialization for 'const' access to parent table.
///
template<class Tab> class BasicTableView<const Tab>:
    public BasicTableViewBase<const Tab, BasicTableView<const Tab>, ConstTableView> {
private:
    typedef BasicTableViewBase<const Tab, BasicTableView<const Tab>, ConstTableView> Base;

public:
    BasicTableView() {}
    BasicTableView& operator=(BasicTableView tv) { Base::m_impl = move(tv.m_impl); return *this; }
    friend BasicTableView move(BasicTableView& tv) { return BasicTableView(&tv); }

    /// Construct BasicTableView<const Tab> from BasicTableView<Tab>.
    ///
    BasicTableView(BasicTableView<Tab> tv): Base(move(tv.m_impl)) {}

    /// Assign BasicTableView<Tab> to BasicTableView<const Tab>.
    ///
    BasicTableView& operator=(BasicTableView<Tab> tv)
    {
        Base::m_impl = move(tv.m_impl);
        return *this;
    }

    const Tab& get_parent() const TIGHTDB_NOEXCEPT
    {
        return static_cast<const Tab&>(Base::m_impl.get_parent());
    }

private:
    BasicTableView(BasicTableView* tv): Base(move(tv->m_impl)) {}
    BasicTableView(ConstTableView tv): Base(move(tv)) {}

    template<class Subtab> const Subtab* get_subtable_ptr(size_t column_ndx, size_t ndx) const
    {
        return get_parent().template
            get_subtable_ptr<Subtab>(column_ndx, Base::m_impl.get_source_ndx(ndx));
    }

    template<class, int, class, bool> friend class _impl::FieldAccessor;
    template<class, int, class> friend class _impl::MixedFieldAccessorBase;
    template<class, int, class> friend class _impl::ColumnAccessorBase;
    template<class, int, class> friend class _impl::ColumnAccessor;
    friend class Tab::Query;
};


} // namespace tightdb

#endif // TIGHTDB_TABLE_VIEW_BASIC_HPP
