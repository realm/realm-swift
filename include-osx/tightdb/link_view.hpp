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
#ifndef TIGHTDB_LINK_VIEW_HPP
#define TIGHTDB_LINK_VIEW_HPP

#include <tightdb/util/bind_ptr.hpp>
#include <tightdb/column.hpp>
#include <tightdb/column_linklist.hpp>
#include <tightdb/link_view_fwd.hpp>
#include <tightdb/table.hpp>
#include <tightdb/table_view.hpp>

namespace tightdb {

class ColumnLinkList;


/// The effect of calling most of the link list functions on a detached accessor
/// is unspecified and may lead to general corruption, or even a crash. The
/// exceptions are is_attached() and the destructor.
///
/// FIXME: Rename this class to `LinkList`.
class LinkView : public RowIndexes {
public:
    ~LinkView() TIGHTDB_NOEXCEPT;
    bool is_attached() const TIGHTDB_NOEXCEPT;

    // Size info
    bool is_empty() const TIGHTDB_NOEXCEPT;
    std::size_t size() const TIGHTDB_NOEXCEPT;

    bool operator==(const LinkView&) const TIGHTDB_NOEXCEPT;
    bool operator!=(const LinkView&) const TIGHTDB_NOEXCEPT;

    // Getting links
    Table::ConstRowExpr operator[](std::size_t link_ndx) const TIGHTDB_NOEXCEPT;
    Table::RowExpr operator[](std::size_t link_ndx) TIGHTDB_NOEXCEPT;
    Table::ConstRowExpr get(std::size_t link_ndx) const TIGHTDB_NOEXCEPT;
    Table::RowExpr get(std::size_t link_ndx) TIGHTDB_NOEXCEPT;

    // Modifiers
    void add(std::size_t target_row_ndx);
    void insert(std::size_t link_ndx, std::size_t target_row_ndx);
    void set(std::size_t link_ndx, std::size_t target_row_ndx);
    void move(std::size_t old_link_ndx, std::size_t new_link_ndx);
    void remove(std::size_t link_ndx);
    void clear();

    void sort(size_t column, bool ascending = true);
    void sort(std::vector<size_t> columns, std::vector<bool> ascending);

    TableView get_sorted_view(std::vector<std::size_t> column_indexes, std::vector<bool> ascending) const;
    TableView get_sorted_view(std::size_t column_index, bool ascending = true) const;

    /// Remove the target row of the specified link from the target table. This
    /// also removes the specified link from this link list, and any other link
    /// pointing to that row. This is merely a shorthand for
    /// `get_target_table.move_last_over(get(link_ndx))`.
    void remove_target_row(std::size_t link_ndx);

    /// Remove all target rows pointed to by links in this link list, and clear
    /// this link list.
    void remove_all_target_rows();

    /// Search this list for a link to the specified target table row (specified
    /// by its index in the target table). If found, the index of the link to
    /// that row within this list is returned, otherwise `tightdb::not_found` is
    /// returned.
    std::size_t find(std::size_t target_row_ndx) const TIGHTDB_NOEXCEPT;

    const ColumnBase& get_column_base(size_t index) const;
    const Table& get_origin_table() const TIGHTDB_NOEXCEPT;
    Table& get_origin_table() TIGHTDB_NOEXCEPT;

    std::size_t get_origin_row_index() const TIGHTDB_NOEXCEPT;

    const Table& get_target_table() const TIGHTDB_NOEXCEPT;
    Table& get_target_table() TIGHTDB_NOEXCEPT;

private:
    TableRef m_origin_table;
    ColumnLinkList& m_origin_column;
    mutable std::size_t m_ref_count;

    // constructor (protected since it can only be used by friends)
    LinkView(Table* origin_table, ColumnLinkList&, std::size_t row_ndx);

    void detach();
    void set_origin_row_index(std::size_t row_ndx);

    void do_nullify_link(std::size_t old_target_row_ndx);
    void do_update_link(std::size_t old_target_row_ndx, std::size_t new_target_row_ndx);

    void bind_ref() const TIGHTDB_NOEXCEPT;
    void unbind_ref() const TIGHTDB_NOEXCEPT;

    void refresh_accessor_tree(std::size_t new_row_ndx) TIGHTDB_NOEXCEPT;

    void update_from_parent(std::size_t old_baseline) TIGHTDB_NOEXCEPT;

#ifdef TIGHTDB_ENABLE_REPLICATION
    Replication* get_repl() TIGHTDB_NOEXCEPT;
    void repl_unselect() TIGHTDB_NOEXCEPT;
    friend class Replication;
#endif

#ifdef TIGHTDB_DEBUG
    void Verify(std::size_t row_ndx) const;
#endif

    friend class ColumnLinkList;
    friend class util::bind_ptr<LinkView>;
    friend class util::bind_ptr<const LinkView>;
    friend class LangBindHelper;
};


// Implementation

inline LinkView::LinkView(Table* origin_table, ColumnLinkList& column, std::size_t row_ndx):
    RowIndexes(Column::unattached_root_tag(), column.get_alloc()), // Throws
    m_origin_table(origin_table->get_table_ref()),
    m_origin_column(column),
    m_ref_count(0)
{
    Array& root = *m_row_indexes.get_root_array();
    root.set_parent(&column, row_ndx);
    if (ref_type ref = root.get_ref_from_parent())
        root.init_from_ref(ref);
}

inline LinkView::~LinkView() TIGHTDB_NOEXCEPT
{
    if (is_attached()) {
#ifdef TIGHTDB_ENABLE_REPLICATION
        repl_unselect();
#endif
        m_origin_column.unregister_linkview(*this);
    }
}

inline void LinkView::bind_ref() const TIGHTDB_NOEXCEPT
{
    ++m_ref_count;
}

inline void LinkView::unbind_ref() const TIGHTDB_NOEXCEPT
{
    if (--m_ref_count > 0)
        return;

    delete this;
}

inline void LinkView::detach()
{
    TIGHTDB_ASSERT(is_attached());
#ifdef TIGHTDB_ENABLE_REPLICATION
    repl_unselect();
#endif
    m_origin_table.reset();
    m_row_indexes.detach();
}

inline bool LinkView::is_attached() const TIGHTDB_NOEXCEPT
{
    return static_cast<bool>(m_origin_table);
}

inline bool LinkView::is_empty() const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());

    if (!m_row_indexes.is_attached())
        return true;

    return m_row_indexes.is_empty();
}

inline std::size_t LinkView::size() const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());

    if (!m_row_indexes.is_attached())
        return 0;

    return m_row_indexes.size();
}

inline bool LinkView::operator==(const LinkView& link_list) const TIGHTDB_NOEXCEPT
{
    Table& target_table_1 = m_origin_column.get_target_table();
    Table& target_table_2 = link_list.m_origin_column.get_target_table();
    if (target_table_1.get_index_in_group() != target_table_2.get_index_in_group())
        return false;
    if (!m_row_indexes.is_attached() || m_row_indexes.is_empty()) {
        return !link_list.m_row_indexes.is_attached() ||
            link_list.m_row_indexes.is_empty();
    }
    return link_list.m_row_indexes.is_attached() &&
        m_row_indexes.compare_int(link_list.m_row_indexes);
}

inline bool LinkView::operator!=(const LinkView& link_list) const TIGHTDB_NOEXCEPT
{
    return !(*this == link_list);
}

inline Table::ConstRowExpr LinkView::get(std::size_t link_ndx) const TIGHTDB_NOEXCEPT
{
    return const_cast<LinkView*>(this)->get(link_ndx);
}

inline Table::RowExpr LinkView::get(std::size_t link_ndx) TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    TIGHTDB_ASSERT(m_row_indexes.is_attached());
    TIGHTDB_ASSERT(link_ndx < m_row_indexes.size());

    Table& target_table = m_origin_column.get_target_table();
    std::size_t target_row_ndx = to_size_t(m_row_indexes.get(link_ndx));
    return target_table[target_row_ndx];
}

inline Table::ConstRowExpr LinkView::operator[](std::size_t link_ndx) const TIGHTDB_NOEXCEPT
{
    return get(link_ndx);
}

inline Table::RowExpr LinkView::operator[](std::size_t link_ndx) TIGHTDB_NOEXCEPT
{
    return get(link_ndx);
}

inline void LinkView::add(std::size_t target_row_ndx)
{
    TIGHTDB_ASSERT(is_attached());
    std::size_t ins_pos = (m_row_indexes.is_attached()) ? m_row_indexes.size() : 0;
    insert(ins_pos, target_row_ndx);
}

inline std::size_t LinkView::find(std::size_t target_row_ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    TIGHTDB_ASSERT(target_row_ndx < m_origin_column.get_target_table().size());

    if (!m_row_indexes.is_attached())
        return not_found;

    return m_row_indexes.find_first(target_row_ndx);
}

inline const ColumnBase& LinkView::get_column_base(size_t index) const
{
    return get_target_table().get_column_base(index);
}

inline const Table& LinkView::get_origin_table() const TIGHTDB_NOEXCEPT
{
    return *m_origin_table;
}

inline Table& LinkView::get_origin_table() TIGHTDB_NOEXCEPT
{
    return *m_origin_table;
}

inline std::size_t LinkView::get_origin_row_index() const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    return m_row_indexes.get_root_array()->get_ndx_in_parent();
}

inline void LinkView::set_origin_row_index(std::size_t row_ndx)
{
    TIGHTDB_ASSERT(is_attached());
    m_row_indexes.get_root_array()->set_ndx_in_parent(row_ndx);
}

inline const Table& LinkView::get_target_table() const TIGHTDB_NOEXCEPT
{
    return m_origin_column.get_target_table();
}

inline Table& LinkView::get_target_table() TIGHTDB_NOEXCEPT
{
    return m_origin_column.get_target_table();
}

inline void LinkView::refresh_accessor_tree(std::size_t new_row_ndx) TIGHTDB_NOEXCEPT
{
    Array& root = *m_row_indexes.get_root_array();
    root.set_ndx_in_parent(new_row_ndx);
    if (ref_type ref = root.get_ref_from_parent()) {
        root.init_from_ref(ref);
    }
    else {
        root.detach();
    }
}

inline void LinkView::update_from_parent(std::size_t old_baseline) TIGHTDB_NOEXCEPT
{
    if (m_row_indexes.is_attached())
        m_row_indexes.update_from_parent(old_baseline);
}

#ifdef TIGHTDB_ENABLE_REPLICATION
inline Replication* LinkView::get_repl() TIGHTDB_NOEXCEPT
{
    typedef _impl::TableFriend tf;
    return tf::get_repl(*m_origin_table);
}
#endif

} // namespace tightdb

#endif // TIGHTDB_LINK_VIEW_HPP
