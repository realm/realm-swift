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
#ifndef TIGHTDB_COLUMN_LINK_HPP
#define TIGHTDB_COLUMN_LINK_HPP

#include <tightdb/column.hpp>
#include <tightdb/column_linkbase.hpp>
#include <tightdb/column_backlink.hpp>

namespace tightdb {

/// A link column is an extension of an integer column (Column) and maintains
/// its node structure.
///
/// The individual values in a link column are indexes of rows in the target
/// table (offset with one to allow zero to indicate null links.) The target
/// table is specified by the table descriptor.
class ColumnLink: public ColumnLinkBase {
public:
    ColumnLink(Allocator&, ref_type ref); // Throws
    ~ColumnLink() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    static ref_type create(Allocator&, std::size_t size = 0);

    // Getting and modifying links
    bool is_null_link(std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    std::size_t get_link(std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    void set_link(std::size_t row_ndx, std::size_t target_row_ndx);
    void insert_link(std::size_t row_ndx, std::size_t target_row_ndx);
    void nullify_link(std::size_t row_ndx);

    void clear() TIGHTDB_OVERRIDE;
    void erase(std::size_t, bool) TIGHTDB_OVERRIDE;
    void move_last_over(std::size_t, std::size_t) TIGHTDB_OVERRIDE;

#ifdef TIGHTDB_DEBUG
    void Verify(const Table&, std::size_t) const TIGHTDB_OVERRIDE;
#endif

protected:
    friend class ColumnBackLink;
    void do_nullify_link(std::size_t row_ndx, std::size_t old_target_row_ndx) TIGHTDB_OVERRIDE;
    void do_update_link(std::size_t row_ndx, std::size_t old_target_row_ndx,
                        std::size_t new_target_row_ndx) TIGHTDB_OVERRIDE;

private:
    void remove_backlinks(std::size_t row_ndx);
};


// Implementation

inline ColumnLink::ColumnLink(Allocator& alloc, ref_type ref):
    ColumnLinkBase(alloc, ref) // Throws
{
}

inline ColumnLink::~ColumnLink() TIGHTDB_NOEXCEPT
{
}

inline ref_type ColumnLink::create(Allocator& alloc, std::size_t size)
{
    return Column::create(alloc, Array::type_Normal, size); // Throws
}

inline bool ColumnLink::is_null_link(std::size_t row_ndx) const TIGHTDB_NOEXCEPT
{
    // Zero indicates a missing (null) link
    return (ColumnLinkBase::get(row_ndx) == 0);
}

inline std::size_t ColumnLink::get_link(std::size_t row_ndx) const TIGHTDB_NOEXCEPT
{
    // Row pos is offset by one, to allow null refs
    return to_size_t(ColumnLinkBase::get(row_ndx) - 1);
}

inline void ColumnLink::insert_link(std::size_t row_ndx, std::size_t target_row_ndx)
{
    // Row pos is offsest by one, to allow null refs
    ColumnLinkBase::insert(row_ndx, target_row_ndx + 1);

    m_backlink_column->add_backlink(target_row_ndx, row_ndx);
}

inline void ColumnLink::do_nullify_link(std::size_t row_ndx, std::size_t)
{
    ColumnLinkBase::set(row_ndx, 0);
}

inline void ColumnLink::do_update_link(std::size_t row_ndx, std::size_t,
                                       std::size_t new_target_row_ndx)
{
    // Row pos is offset by one, to allow null refs
    ColumnLinkBase::set(row_ndx, new_target_row_ndx + 1);
}

} //namespace tightdb

#endif //TIGHTDB_COLUMN_LINK_HPP
