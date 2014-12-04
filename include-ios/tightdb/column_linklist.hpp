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
#ifndef TIGHTDB_COLUMN_LINKLIST_HPP
#define TIGHTDB_COLUMN_LINKLIST_HPP

#include <algorithm>
#include <vector>

#include <tightdb/column.hpp>
#include <tightdb/column_linkbase.hpp>
#include <tightdb/table.hpp>
#include <tightdb/column_backlink.hpp>
#include <tightdb/link_view_fwd.hpp>
#include <iostream>

namespace tightdb {


/// A column of link lists (ColumnLinkList) is a single B+-tree, and the root of
/// the column is the root of the B+-tree. All leaf nodes are single arrays of
/// type Array with the hasRefs bit set.
///
/// The individual values in the column are either refs to Columns containing the
/// row positions in the target table, or in the case where they are empty, a zero
/// ref.
class ColumnLinkList: public ColumnLinkBase, public ArrayParent {
public:
    ColumnLinkList(Allocator&, ref_type, Table*, std::size_t column_ndx);
    ~ColumnLinkList() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    static ref_type create(Allocator&, std::size_t size = 0);

    bool has_links(std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    std::size_t get_link_count(std::size_t row_ndx) const TIGHTDB_NOEXCEPT;

    ConstLinkViewRef get(std::size_t row_ndx) const;
    LinkViewRef get(std::size_t row_ndx);

    void erase(std::size_t, bool) TIGHTDB_OVERRIDE;
    void move_last_over(std::size_t, std::size_t) TIGHTDB_OVERRIDE;
    void clear() TIGHTDB_OVERRIDE;

    /// Compare two columns for equality.
    bool compare_link_list(const ColumnLinkList&) const;

    void to_json_row(std::size_t row_ndx, std::ostream& out) const;

    void refresh_accessor_tree(std::size_t, const Spec&) TIGHTDB_OVERRIDE;

    void adj_accessors_move(std::size_t, std::size_t) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    void adj_acc_clear_root_table() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    void update_from_parent(std::size_t) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

#ifdef TIGHTDB_DEBUG
    void Verify() const TIGHTDB_OVERRIDE;
    void Verify(const Table&, std::size_t) const TIGHTDB_OVERRIDE;
#endif

protected:
    void do_discard_child_accessors() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

private:
    // A pointer to the table that this column is part of.
    Table* const m_table;

    // The index of this column within m_table.m_cols.
    std::size_t m_column_ndx;

    struct list_entry {
        std::size_t m_row_ndx;
        LinkView* m_list;
    };
    typedef std::vector<list_entry> list_accessors;
    mutable list_accessors m_list_accessors;

    LinkView* get_ptr(std::size_t row_ndx) const;

    void do_nullify_link(std::size_t row_ndx, std::size_t old_target_row_ndx) TIGHTDB_OVERRIDE;
    void do_update_link(std::size_t row_ndx, std::size_t old_target_row_ndx,
                        std::size_t new_target_row_ndx) TIGHTDB_OVERRIDE;

    void unregister_linkview(const LinkView& view);
    ref_type get_row_ref(std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    void set_row_ref(std::size_t row_ndx, ref_type new_ref);
    void add_backlink(std::size_t target_row, std::size_t source_row);
    void remove_backlink(std::size_t target_row, std::size_t source_row);

    // ArrayParent overrides
    void update_child_ref(std::size_t child_ndx, ref_type new_ref) TIGHTDB_OVERRIDE;
    ref_type get_child_ref(std::size_t child_ndx) const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    void discard_child_accessors() TIGHTDB_NOEXCEPT;

    template<bool fix_ndx_in_parent>
    void adj_move(std::size_t target_row_ndx, std::size_t source_row_ndx) TIGHTDB_NOEXCEPT;

#ifdef TIGHTDB_DEBUG
    std::pair<ref_type, std::size_t> get_to_dot_parent(std::size_t) const TIGHTDB_OVERRIDE;
#endif

    friend class ColumnBackLink;
    friend class LinkView;

#ifdef TIGHTDB_ENABLE_REPLICATION
    friend class Replication;
#endif
};





// Implementation

inline ColumnLinkList::ColumnLinkList(Allocator& alloc, ref_type ref, Table* table, std::size_t column_ndx):
    ColumnLinkBase(alloc, ref), // Throws
    m_table(table),
    m_column_ndx(column_ndx)
{
}

inline ColumnLinkList::~ColumnLinkList() TIGHTDB_NOEXCEPT
{
    discard_child_accessors();
}

inline ref_type ColumnLinkList::create(Allocator& alloc, std::size_t size)
{
    return Column::create(alloc, Array::type_HasRefs, size); // Throws
}

inline bool ColumnLinkList::has_links(std::size_t row_ndx) const TIGHTDB_NOEXCEPT
{
    ref_type ref = ColumnLinkBase::get_as_ref(row_ndx);
    return (ref != 0);
}

inline std::size_t ColumnLinkList::get_link_count(std::size_t row_ndx) const TIGHTDB_NOEXCEPT
{
    ref_type ref = ColumnLinkBase::get_as_ref(row_ndx);
    if (ref == 0)
        return 0;
    return ColumnBase::get_size_from_ref(ref, get_alloc());
}

inline ConstLinkViewRef ColumnLinkList::get(std::size_t row_ndx) const
{
    LinkView* link_list = get_ptr(row_ndx); // Throws
    return ConstLinkViewRef(link_list);
}

inline LinkViewRef ColumnLinkList::get(std::size_t row_ndx)
{
    LinkView* link_list = get_ptr(row_ndx); // Throws
    return LinkViewRef(link_list);
}

inline void ColumnLinkList::do_discard_child_accessors() TIGHTDB_NOEXCEPT
{
    discard_child_accessors();
}

inline void ColumnLinkList::unregister_linkview(const LinkView& list)
{
    typedef list_accessors::iterator iter;
    iter end = m_list_accessors.end();
    for (iter i = m_list_accessors.begin(); i != end; ++i) {
        if (i->m_list == &list) {
            m_list_accessors.erase(i);
            return;
        }
    }
}

inline ref_type ColumnLinkList::get_row_ref(std::size_t row_ndx) const TIGHTDB_NOEXCEPT
{
    return ColumnLinkBase::get_as_ref(row_ndx);
}

inline void ColumnLinkList::set_row_ref(std::size_t row_ndx, ref_type new_ref)
{
    ColumnLinkBase::set(row_ndx, new_ref);
}

inline void ColumnLinkList::add_backlink(std::size_t target_row, std::size_t source_row)
{
    m_backlink_column->add_backlink(target_row, source_row);
}

inline void ColumnLinkList::remove_backlink(std::size_t target_row, std::size_t source_row)
{
    m_backlink_column->remove_backlink(target_row, source_row);
}


} //namespace tightdb

#endif //TIGHTDB_COLUMN_LINKLIST_HPP


