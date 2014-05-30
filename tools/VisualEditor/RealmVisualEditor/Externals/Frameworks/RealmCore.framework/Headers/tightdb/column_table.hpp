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
#ifndef TIGHTDB_COLUMN_TABLE_HPP
#define TIGHTDB_COLUMN_TABLE_HPP

#include <vector>

#include <RealmCore/tightdb/util/features.h>
#include <RealmCore/tightdb/util/unique_ptr.hpp>
#include <RealmCore/tightdb/column.hpp>
#include <RealmCore/tightdb/table.hpp>

namespace tightdb {


/// Base class for any type of column that can contain subtables.
class ColumnSubtableParent: public Column, public Table::Parent {
public:
    void update_column_index(std::size_t, const Spec&) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

#ifdef TIGHTDB_ENABLE_REPLICATION
    void recursive_mark_table_accessors_dirty() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    void refresh_after_advance_transact(std::size_t, const Spec&) TIGHTDB_OVERRIDE;
#endif

    void adj_accessors_insert_rows(std::size_t, std::size_t) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    void adj_accessors_erase_row(std::size_t) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    void adj_accessors_move_last_over(std::size_t, std::size_t) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    void update_from_parent(std::size_t) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    void detach_subtable_accessors() TIGHTDB_NOEXCEPT;

    ~ColumnSubtableParent() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    static ref_type create(std::size_t size, Allocator&);

    Table* get_subtable_accessor(std::size_t) const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    void discard_subtable_accessor(std::size_t) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

protected:
    /// A pointer to the table that this column is part of. For a
    /// free-standing column, this pointer is null.
    Table* const m_table;

    /// The index of this column within the table that this column is
    /// part of. For a free-standing column, this index is zero.
    ///
    /// This index specifies the position of the column within the
    /// Table::m_cols array. Note that this corresponds to the logical
    /// index of the column, which is not always the same as the index
    /// of this column within Table::m_columns. This is because
    /// Table::m_columns contains columns as well as indexes for those
    /// columns.
    std::size_t m_column_ndx;

    struct SubtableMap {
        ~SubtableMap() TIGHTDB_NOEXCEPT {}
        bool empty() const TIGHTDB_NOEXCEPT { return m_entries.empty(); }
        Table* find(std::size_t subtable_ndx) const TIGHTDB_NOEXCEPT;
        void add(std::size_t subtable_ndx, Table*);
        // Returns true if, and only if at least one entry was detached and
        // removed from the map.
        bool detach_and_remove_all() TIGHTDB_NOEXCEPT;
        // Returns true if, and only if the entry was found and removed, and it
        // was the last entry in the map.
        bool detach_and_remove(std::size_t subtable_ndx) TIGHTDB_NOEXCEPT;
        // Returns true if, and only if the entry was found and removed, and it
        // was the last entry in the map.
        bool remove(Table*) TIGHTDB_NOEXCEPT;
        void update_from_parent(std::size_t old_baseline) const TIGHTDB_NOEXCEPT;
        void adj_insert_rows(std::size_t row_ndx, std::size_t num_rows) TIGHTDB_NOEXCEPT;
        // Returns true if, and only if an entry was found and removed, and it
        // was the last entry in the map.
        bool adj_erase_row(std::size_t row_ndx) TIGHTDB_NOEXCEPT;
        // Returns true if, and only if an entry was found and removed, and it
        // was the last entry in the map.
        bool adj_move_last_over(std::size_t target_row_ndx, std::size_t last_row_ndx)
            TIGHTDB_NOEXCEPT;
        void update_accessors(const std::size_t* col_path_begin, const std::size_t* col_path_end,
                              _impl::TableFriend::AccessorUpdater&);
#ifdef TIGHTDB_ENABLE_REPLICATION
        void recursive_mark_dirty() TIGHTDB_NOEXCEPT;
        void refresh_after_advance_transact(std::size_t spec_ndx_in_parent);
#endif
    private:
        struct entry {
            std::size_t m_subtable_ndx;
            Table* m_table;
        };
        typedef std::vector<entry> entries;
        entries m_entries;
    };

    /// Contains all existing accessors that are attached to a subtable in this
    /// column. It can map a row index into a pointer to the corresponding
    /// accessor when it exists.
    ///
    /// There is an invariant in force: Either `m_table` is null, or there is an
    /// additional referece count on `*m_table` when, and only when the map is
    /// non-empty.
    mutable SubtableMap m_subtable_map;

    ColumnSubtableParent(Allocator&, Table*, std::size_t column_ndx);

    ColumnSubtableParent(Allocator&, Table*, std::size_t column_ndx,
                         ArrayParent*, std::size_t ndx_in_parent, ref_type);

    /// Get a pointer to the accessor of the specified subtable. The
    /// accessor will be created if it does not already exist.
    ///
    /// The returned table pointer must **always** end up being
    /// wrapped in some instantiation of BasicTableRef<>.
    ///
    /// NOTE: This method must be used only for subtables with
    /// independent specs, i.e. for elements of a ColumnMixed.
    Table* get_subtable_ptr(std::size_t subtable_ndx);

    // Overriding method in ArrayParent
    void update_child_ref(std::size_t, ref_type) TIGHTDB_OVERRIDE;

    // Overriding method in ArrayParent
    ref_type get_child_ref(std::size_t) const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    // Overriding method in Table::Parent
    Table* get_parent_table(std::size_t*) const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    // Overriding method in Table::Parent
    void child_accessor_destroyed(Table*) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    /// Assumes that the two tables have the same spec.
    static bool compare_subtable_rows(const Table&, const Table&);

    /// Construct a copy of the columns array of the specified table
    /// and return just the ref to that array.
    ///
    /// In the clone, no string column will be of the enumeration
    /// type.
    ref_type clone_table_columns(const Table*);

    std::size_t* record_subtable_path(std::size_t* begin,
                                      std::size_t* end) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    void update_table_accessors(const std::size_t* col_path_begin, const std::size_t* col_path_end,
                                _impl::TableFriend::AccessorUpdater&);

#ifdef TIGHTDB_DEBUG
    std::pair<ref_type, std::size_t>
    get_to_dot_parent(std::size_t ndx_in_parent) const TIGHTDB_OVERRIDE;
#endif

    friend class Table;
};



class ColumnTable: public ColumnSubtableParent {
public:
    /// Create a subtable column accessor and have it instantiate a
    /// new underlying structure of arrays.
    ///
    /// \param table If this column is used as part of a table you must
    /// pass a pointer to that table. Otherwise you must pass null.
    ///
    /// \param column_ndx If this column is used as part of a table
    /// you must pass the logical index of the column within that
    /// table. Otherwise you should pass zero.
    ColumnTable(Allocator&, Table* table, std::size_t column_ndx);

    /// Create a subtable column accessor and attach it to a
    /// preexisting underlying structure of arrays.
    ///
    /// \param table If this column is used as part of a table you must
    /// pass a pointer to that table. Otherwise you must pass null.
    ///
    /// \param column_ndx If this column is used as part of a table
    /// you must pass the logical index of the column within that
    /// table. Otherwise you should pass zero.
    ColumnTable(Allocator&, Table* table, std::size_t column_ndx,
                ArrayParent*, std::size_t ndx_in_parent, ref_type column_ref);

    ~ColumnTable() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

    std::size_t get_subtable_size(std::size_t ndx) const TIGHTDB_NOEXCEPT;

    /// Get a pointer to the accessor of the specified subtable. The
    /// accessor will be created if it does not already exist.
    ///
    /// The returned table pointer must **always** end up being
    /// wrapped in some instantiation of BasicTableRef<>.
    Table* get_subtable_ptr(std::size_t subtable_ndx);

    const Table* get_subtable_ptr(std::size_t subtable_ndx) const;

    // When passing a table to add() or insert() it is assumed that
    // the table spec is compatible with this column. The number of
    // columns must be the same, and the corresponding columns must
    // have the same data type (as returned by
    // Table::get_column_type()).

    void add() TIGHTDB_OVERRIDE;
    void add(const Table*);
    void insert(std::size_t ndx) TIGHTDB_OVERRIDE;
    void insert(std::size_t ndx, const Table*);
    void set(std::size_t ndx, const Table*);
    void erase(std::size_t ndx, bool is_last) TIGHTDB_OVERRIDE;
    void clear_table(std::size_t ndx);

    void clear() TIGHTDB_OVERRIDE;

    void move_last_over(std::size_t ndx) TIGHTDB_OVERRIDE;

    /// Compare two subtable columns for equality.
    bool compare_table(const ColumnTable&) const;

    void update_column_index(std::size_t, const Spec&) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

#ifdef TIGHTDB_ENABLE_REPLICATION
    void refresh_after_advance_transact(std::size_t, const Spec&) TIGHTDB_OVERRIDE;
#endif

#ifdef TIGHTDB_DEBUG
    void Verify() const TIGHTDB_OVERRIDE; // Must be upper case to avoid conflict with macro in ObjC
    void dump_node_structure(std::ostream&, int level) const TIGHTDB_OVERRIDE;
    using ColumnSubtableParent::dump_node_structure;
    void to_dot(std::ostream&, StringData title) const TIGHTDB_OVERRIDE;
#endif

private:
    mutable std::size_t m_subspec_ndx; // Unknown if equal to `npos`

    std::size_t get_subspec_ndx() const TIGHTDB_NOEXCEPT;

    void destroy_subtable(std::size_t ndx);

    void do_detach_subtable_accessors() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
};





// Implementation

inline void ColumnSubtableParent::update_column_index(std::size_t new_col_ndx, const Spec& spec)
    TIGHTDB_NOEXCEPT
{
    Column::update_column_index(new_col_ndx, spec);
    m_column_ndx = new_col_ndx;
}

#ifdef TIGHTDB_ENABLE_REPLICATION

inline void ColumnSubtableParent::recursive_mark_table_accessors_dirty() TIGHTDB_NOEXCEPT
{
    m_subtable_map.recursive_mark_dirty();
}

inline void ColumnSubtableParent::refresh_after_advance_transact(std::size_t col_ndx,
                                                                 const Spec& spec)
{
    Column::refresh_after_advance_transact(col_ndx, spec); // Throws
    m_column_ndx = col_ndx;
}

#endif // TIGHTDB_ENABLE_REPLICATION

inline void ColumnSubtableParent::adj_accessors_insert_rows(std::size_t row_ndx,
                                                            std::size_t num_rows) TIGHTDB_NOEXCEPT
{
    // This function must be able to operate with only the Minimal Accessor
    // Hierarchy Consistency Guarantee. This means, in particular, that it
    // cannot access the underlying array structure.

    m_subtable_map.adj_insert_rows(row_ndx, num_rows);
}

inline void ColumnSubtableParent::adj_accessors_erase_row(std::size_t row_ndx) TIGHTDB_NOEXCEPT
{
    // This function must be able to operate with only the Minimal Accessor
    // Hierarchy Consistency Guarantee. This means, in particular, that it
    // cannot access the underlying array structure.

    bool last_entry_removed = m_subtable_map.adj_erase_row(row_ndx);
    typedef _impl::TableFriend tf;
    if (last_entry_removed)
        tf::unbind_ref(*m_table);
}

inline void ColumnSubtableParent::adj_accessors_move_last_over(std::size_t target_row_ndx,
                                                               std::size_t last_row_ndx)
    TIGHTDB_NOEXCEPT
{
    // This function must be able to operate with only the Minimal Accessor
    // Hierarchy Consistency Guarantee. This means, in particular, that it
    // cannot access the underlying array structure.

    bool last_entry_removed = m_subtable_map.adj_move_last_over(target_row_ndx, last_row_ndx);
    typedef _impl::TableFriend tf;
    if (last_entry_removed)
        tf::unbind_ref(*m_table);
}

inline Table* ColumnSubtableParent::get_subtable_accessor(std::size_t row_ndx) const
    TIGHTDB_NOEXCEPT
{
    // This function must be able to operate with only the Minimal Accessor
    // Hierarchy Consistency Guarantee. This means, in particular, that it
    // cannot access the underlying array structure.

    Table* subtable = m_subtable_map.find(row_ndx);
    return subtable;
}

inline void ColumnSubtableParent::discard_subtable_accessor(std::size_t row_ndx) TIGHTDB_NOEXCEPT
{
    // This function must be able to operate with only the Minimal Accessor
    // Hierarchy Consistency Guarantee. This means, in particular, that it
    // cannot access the underlying array structure.

    bool last_entry_removed = m_subtable_map.detach_and_remove(row_ndx);
    typedef _impl::TableFriend tf;
    if (last_entry_removed)
        tf::unbind_ref(*m_table);
}

inline void ColumnSubtableParent::SubtableMap::add(std::size_t subtable_ndx, Table* table)
{
    entry e;
    e.m_subtable_ndx = subtable_ndx;
    e.m_table        = table;
    m_entries.push_back(e);
}

inline ColumnSubtableParent::ColumnSubtableParent(Allocator& alloc,
                                                  Table* table, std::size_t column_ndx):
    Column(Array::type_HasRefs, alloc),
    m_table(table), m_column_ndx(column_ndx)
{
}

inline ColumnSubtableParent::ColumnSubtableParent(Allocator& alloc,
                                                  Table* table, std::size_t column_ndx,
                                                  ArrayParent* parent, std::size_t ndx_in_parent,
                                                  ref_type ref):
    Column(ref, parent, ndx_in_parent, alloc),
    m_table(table), m_column_ndx(column_ndx)
{
}

inline void ColumnSubtableParent::update_child_ref(std::size_t child_ndx, ref_type new_ref)
{
    set(child_ndx, new_ref);
}

inline ref_type ColumnSubtableParent::get_child_ref(std::size_t child_ndx) const TIGHTDB_NOEXCEPT
{
    return get_as_ref(child_ndx);
}

inline void ColumnSubtableParent::detach_subtable_accessors() TIGHTDB_NOEXCEPT
{
    bool last_entry_removed = m_subtable_map.detach_and_remove_all();
    if (last_entry_removed && m_table)
        _impl::TableFriend::unbind_ref(*m_table);
}

inline bool ColumnSubtableParent::compare_subtable_rows(const Table& a, const Table& b)
{
    return _impl::TableFriend::compare_rows(a,b);
}

inline ref_type ColumnSubtableParent::clone_table_columns(const Table* t)
{
    return _impl::TableFriend::clone_columns(*t, m_array->get_alloc());
}

inline ref_type ColumnSubtableParent::create(std::size_t size, Allocator& alloc)
{
    int_fast64_t value = 0;
    return Column::create(Array::type_HasRefs, size, value, alloc); // Throws
}

inline std::size_t* ColumnSubtableParent::record_subtable_path(std::size_t* begin,
                                                               std::size_t* end) TIGHTDB_NOEXCEPT
{
    if (end == begin)
        return 0; // Error, not enough space in buffer
    *begin++ = m_column_ndx;
    if (end == begin)
        return 0; // Error, not enough space in buffer
    return _impl::TableFriend::record_subtable_path(*m_table, begin, end);
}

inline void ColumnSubtableParent::
update_table_accessors(const std::size_t* col_path_begin, const std::size_t* col_path_end,
                       _impl::TableFriend::AccessorUpdater& updater)
{
    // This function must be able to operate with only the Minimal Accessor
    // Hierarchy Consistency Guarantee. This means, in particular, that it
    // cannot access the underlying array structure.

    m_subtable_map.update_accessors(col_path_begin, col_path_end, updater); // Throws
}


inline void ColumnTable::update_column_index(std::size_t new_col_ndx, const Spec& spec)
    TIGHTDB_NOEXCEPT
{
    ColumnSubtableParent::update_column_index(new_col_ndx, spec);
    m_subspec_ndx = tightdb::npos;
}

inline ColumnTable::ColumnTable(Allocator& alloc, Table* table, std::size_t column_ndx):
    ColumnSubtableParent(alloc, table, column_ndx), m_subspec_ndx(tightdb::npos)
{
}

inline ColumnTable::ColumnTable(Allocator& alloc, Table* table, std::size_t column_ndx,
                                ArrayParent* parent, std::size_t ndx_in_parent,
                                ref_type column_ref):
    ColumnSubtableParent(alloc, table, column_ndx, parent, ndx_in_parent, column_ref),
    m_subspec_ndx(tightdb::npos)
{
}

inline const Table* ColumnTable::get_subtable_ptr(std::size_t subtable_ndx) const
{
    return const_cast<ColumnTable*>(this)->get_subtable_ptr(subtable_ndx);
}

inline void ColumnTable::add(const Table* subtable)
{
    insert(size(), subtable);
}

#ifdef TIGHTDB_ENABLE_REPLICATION

inline void ColumnTable::refresh_after_advance_transact(std::size_t col_ndx, const Spec& spec)
{
    ColumnSubtableParent::refresh_after_advance_transact(col_ndx, spec); // Throws
    m_subspec_ndx = spec.get_subspec_ndx(col_ndx);
    m_subtable_map.refresh_after_advance_transact(m_subspec_ndx); // Throws
}

#endif // TIGHTDB_ENABLE_REPLICATION

inline std::size_t ColumnTable::get_subspec_ndx() const TIGHTDB_NOEXCEPT
{
    if (TIGHTDB_UNLIKELY(m_subspec_ndx == tightdb::npos)) {
        const Spec* spec = _impl::TableFriend::get_spec(*m_table);
        m_subspec_ndx = spec->get_subspec_ndx(m_column_ndx);
    }
    return m_subspec_ndx;
}


} // namespace tightdb

#endif // TIGHTDB_COLUMN_TABLE_HPP
