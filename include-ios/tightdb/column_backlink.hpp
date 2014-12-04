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
#ifndef TIGHTDB_COLUMN_BACKLINK_HPP
#define TIGHTDB_COLUMN_BACKLINK_HPP

#include <vector>

#include <tightdb/column.hpp>
#include <tightdb/column_linkbase.hpp>
#include <tightdb/table.hpp>

namespace tightdb {

/// A column of backlinks (ColumnBackLink) is a single B+-tree, and the root of
/// the column is the root of the B+-tree. All leaf nodes are single arrays of
/// type Array with the hasRefs bit set.
///
/// The individual values in the column are either refs to Columns containing
/// the row indexes in the origin table that links to it, or in the case where
/// there is a single link, a tagged ref encoding the origin row position.
class ColumnBackLink: public Column, public ArrayParent {
public:
    ColumnBackLink(Allocator&, ref_type);
    ~ColumnBackLink() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    static ref_type create(Allocator&, std::size_t size = 0);

    bool has_backlinks(std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    std::size_t get_backlink_count(std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    std::size_t get_backlink(std::size_t row_ndx, std::size_t backlink_ndx) const TIGHTDB_NOEXCEPT;

    void add_backlink(std::size_t row_ndx, std::size_t origin_row_ndx);
    void remove_backlink(std::size_t row_ndx, std::size_t origin_row_ndx);
    void update_backlink(std::size_t row_ndx, std::size_t old_row_ndx, std::size_t new_row_ndx);

    void add_row();

    void clear() TIGHTDB_OVERRIDE;
    void erase(std::size_t, bool) TIGHTDB_OVERRIDE;
    void move_last_over(std::size_t, std::size_t) TIGHTDB_OVERRIDE;

    // Link origination info
    Table& get_origin_table() const TIGHTDB_NOEXCEPT;
    void set_origin_table(Table&) TIGHTDB_NOEXCEPT;
    ColumnLinkBase& get_origin_column() const TIGHTDB_NOEXCEPT;
    void set_origin_column(ColumnLinkBase&) TIGHTDB_NOEXCEPT;

    void adj_accessors_insert_rows(std::size_t, std::size_t) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    void adj_accessors_erase_row(std::size_t) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    void adj_accessors_move(std::size_t, std::size_t) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    void adj_acc_clear_root_table() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    void mark(int) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    void bump_link_origin_table_version() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

#ifdef TIGHTDB_DEBUG
    void Verify() const TIGHTDB_OVERRIDE;
    void Verify(const Table&, std::size_t) const TIGHTDB_OVERRIDE;
    struct VerifyPair {
        std::size_t origin_row_ndx, target_row_ndx;
        bool operator<(const VerifyPair&) const TIGHTDB_NOEXCEPT;
    };
    void get_backlinks(std::vector<VerifyPair>&); // Sorts
#endif

protected:
    // ArrayParent overrides
    void update_child_ref(std::size_t child_ndx, ref_type new_ref) TIGHTDB_OVERRIDE;
    ref_type get_child_ref(std::size_t child_ndx) const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

#ifdef TIGHTDB_DEBUG
    std::pair<ref_type, std::size_t> get_to_dot_parent(std::size_t) const TIGHTDB_OVERRIDE;
#endif

private:
    TableRef        m_origin_table;
    ColumnLinkBase* m_origin_column;

    void nullify_links(std::size_t row_ndx, bool do_destroy);
};




// Implementation

inline ColumnBackLink::ColumnBackLink(Allocator& alloc, ref_type ref):
    Column(alloc, ref), // Throws
    m_origin_column(0)
{
}

inline ref_type ColumnBackLink::create(Allocator& alloc, std::size_t size)
{
    return Column::create(alloc, Array::type_HasRefs, size); // Throws
}

inline bool ColumnBackLink::has_backlinks(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    return Column::get(ndx) != 0;
}

inline Table& ColumnBackLink::get_origin_table() const TIGHTDB_NOEXCEPT
{
    return *m_origin_table;
}

inline void ColumnBackLink::set_origin_table(Table& table) TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(!m_origin_table);
    m_origin_table = table.get_table_ref();
}

inline ColumnLinkBase& ColumnBackLink::get_origin_column() const TIGHTDB_NOEXCEPT
{
    return *m_origin_column;
}

inline void ColumnBackLink::set_origin_column(ColumnLinkBase& column) TIGHTDB_NOEXCEPT
{
    m_origin_column = &column;
}

inline void ColumnBackLink::add_row()
{
    Column::add(0);
}

inline void ColumnBackLink::adj_accessors_insert_rows(std::size_t row_ndx,
                                                      std::size_t num_rows) TIGHTDB_NOEXCEPT
{
    Column::adj_accessors_insert_rows(row_ndx, num_rows);

    // For tables with link-type columns, the insertion point must be after all
    // existsing rows, so the origin table cannot be affected by this change.
}

inline void ColumnBackLink::adj_accessors_erase_row(std::size_t) TIGHTDB_NOEXCEPT
{
    // Rows cannot be erased this way in tables with link-type columns
    TIGHTDB_ASSERT(false);
}

inline void ColumnBackLink::adj_accessors_move(std::size_t target_row_ndx,
                                               std::size_t source_row_ndx) TIGHTDB_NOEXCEPT
{
    Column::adj_accessors_move(target_row_ndx, source_row_ndx);

    typedef _impl::TableFriend tf;
    tf::mark(*m_origin_table);
}

inline void ColumnBackLink::adj_acc_clear_root_table() TIGHTDB_NOEXCEPT
{
    Column::adj_acc_clear_root_table();

    typedef _impl::TableFriend tf;
    tf::mark(*m_origin_table);
}

inline void ColumnBackLink::mark(int type) TIGHTDB_NOEXCEPT
{
    if (type & mark_LinkOrigins) {
        typedef _impl::TableFriend tf;
        tf::mark(*m_origin_table);
    }
}

inline void ColumnBackLink::bump_link_origin_table_version() TIGHTDB_NOEXCEPT
{
    typedef _impl::TableFriend tf;
    if (m_origin_table) {
        bool bump_global = false;
        tf::bump_version(*m_origin_table, bump_global);
    }
}

#ifdef TIGHTDB_DEBUG

inline bool ColumnBackLink::VerifyPair::operator<(const VerifyPair& p) const TIGHTDB_NOEXCEPT
{
    return origin_row_ndx < p.origin_row_ndx;
}

#endif // TIGHTDB_DEBUG

} // namespace tightdb

#endif // TIGHTDB_COLUMN_BACKLINK_HPP
