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
#ifndef TIGHTDB_TABLE_HPP
#define TIGHTDB_TABLE_HPP

#include <algorithm>
#include <utility>
#include <map>

#include <tightdb/util/features.h>
#include <tightdb/util/tuple.hpp>
#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/column_fwd.hpp>
#include <tightdb/table_ref.hpp>
#include <tightdb/link_view_fwd.hpp>
#include <tightdb/row.hpp>
#include <tightdb/descriptor_fwd.hpp>
#include <tightdb/spec.hpp>
#include <tightdb/mixed.hpp>
#include <tightdb/query.hpp>
#include <tightdb/column.hpp>

namespace tightdb {

class TableView;
class LinkView;
class TableViewBase;
class ConstTableView;
class StringIndex;
class Group;
class ColumnLinkBase;
class ColumnLink;
class ColumnLinkList;
class ColumnBackLink;
template<class> class Columns;

struct Link {};
typedef Link LinkList;

namespace _impl { class TableFriend; }

#ifdef TIGHTDB_ENABLE_REPLICATION
class Replication;
#endif


/// The Table class is non-polymorphic, that is, it has no virtual
/// functions. This is important because it ensures that there is no run-time
/// distinction between a Table instance and an instance of any variation of
/// BasicTable<T>, and this, in turn, makes it valid to cast a pointer from
/// Table to BasicTable<T> even when the instance is constructed as a Table. Of
/// course, this also assumes that BasicTable<> is non-polymorphic, has no
/// destructor, and adds no extra data members.
///
/// FIXME: Table assignment (from any group to any group) could be made aliasing
/// safe as follows: Start by cloning source table into target allocator. On
/// success, assign, and then deallocate any previous structure at the target.
///
/// FIXME: It might be desirable to have a 'table move' feature between two
/// places inside the same group (say from a subtable or a mixed column to group
/// level). This could be done in a very efficient manner.
///
/// FIXME: When compiling in debug mode, all public non-static table functions
/// should TIGHTDB_ASSERT(is_attached()).
class Table {
public:
    /// Construct a new freestanding top-level table with static
    /// lifetime.
    ///
    /// This constructor should be used only when placing a table
    /// instance on the stack, and it is then the responsibility of
    /// the application that there are no objects of type TableRef or
    /// ConstTableRef that refer to it, or to any of its subtables,
    /// when it goes out of scope. To create a top-level table with
    /// dynamic lifetime, use Table::create() instead.
    Table(Allocator& = Allocator::get_default());

    /// Construct a copy of the specified table as a new freestanding
    /// top-level table with static lifetime.
    ///
    /// This constructor should be used only when placing a table
    /// instance on the stack, and it is then the responsibility of
    /// the application that there are no objects of type TableRef or
    /// ConstTableRef that refer to it, or to any of its subtables,
    /// when it goes out of scope. To create a top-level table with
    /// dynamic lifetime, use Table::copy() instead.
    Table(const Table&, Allocator& = Allocator::get_default());

    ~Table() TIGHTDB_NOEXCEPT;

    /// Construct a new freestanding top-level table with dynamic lifetime.
    static TableRef create(Allocator& = Allocator::get_default());

    /// Construct a copy of the specified table as a new freestanding top-level
    /// table with dynamic lifetime.
    TableRef copy(Allocator& = Allocator::get_default()) const;

    /// Returns true if, and only if this accessor is currently attached to an
    /// underlying table.
    ///
    /// A table accessor may get detached from the underlying row for various
    /// reasons (see below). When it does, it no longer refers to anything, and
    /// can no longer be used, except for calling is_attached(). The
    /// consequences of calling other non-static functions on a detached table
    /// accessor are unspecified. Table accessors obtained by calling functions in
    /// the TightDB API are always in the 'attached' state immediately upon
    /// return from those functions.
    ///
    /// A table accessor of a free-standing table never becomes detached (except
    /// during its eventual destruction). A group-level table accessor becomes
    /// detached if the underlying table is removed from the group (not
    /// currently possible), or when the group accessor is destroyed. A subtable
    /// accessor becomes detached if the underlying subtable is removed, or if
    /// the parent table accessor is detached. A table accessor does not become
    /// detached for any other reason than those mentioned here.
    ///
    /// FIXME: High level language bindings will probably want to be able to
    /// explicitely detach a group and all tables of that group if any modifying
    /// operation fails (e.g. memory allocation failure) (and something similar
    /// for freestanding tables) since that leaves the group in state where any
    /// further access is disallowed. This way they will be able to reliably
    /// intercept any attempt at accessing such a failed group.
    ///
    /// FIXME: The C++ documentation must state that if any modifying operation
    /// on a group (incl. tables, subtables, and specs) or on a free standing
    /// table (incl. subtables and specs) fails, then any further access to that
    /// group (except ~Group()) or freestanding table (except ~Table()) has
    /// undefined behaviour and is considered an error on behalf of the
    /// application. Note that even Table::is_attached() is disallowed in this
    /// case.
    bool is_attached() const TIGHTDB_NOEXCEPT;

    /// Get the name of this table, if it has one. Only group-level tables have
    /// names. For a table of any other kind, this function returns the empty
    /// string.
    StringData get_name() const TIGHTDB_NOEXCEPT;

    //@{
    /// Conventience functions for inspecting the dynamic table type.
    ///
    /// These functions behave as if they were called on the descriptor returned
    /// by get_descriptor().
    std::size_t get_column_count() const TIGHTDB_NOEXCEPT;
    DataType    get_column_type(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;
    StringData  get_column_name(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;
    std::size_t get_column_index(StringData name) const TIGHTDB_NOEXCEPT;
    //@}

    //@{
    /// Convenience functions for manipulating the dynamic table type.
    ///
    /// These function must be called only for tables with independent dynamic
    /// type. A table has independent dynamic type if the function
    /// has_shared_type() returns false. A table that is a direct member of a
    /// group has independent dynamic type. So does a free-standing table, and a
    /// subtable in a column of type 'mixed'. All other tables have shared
    /// dynamic type. The consequences of calling any of these functions for a
    /// table with shared dynamic type are undefined.
    ///
    /// Apart from that, these functions behave as if they were called on the
    /// descriptor returned by get_descriptor(). Note especially that the
    /// `_link` suffixed functions must be used when inserting link-type
    /// columns.
    ///
    /// If you need to change the shared dynamic type of the subtables in a
    /// subtable column, consider using the API offered by the Descriptor class.
    ///
    /// \param subdesc If a non-null pointer is passed, and the specified type
    /// is `type_Table`, then this function automatically reteives the
    /// descriptor associated with the new subtable column, and stores a
    /// reference to its accessor in `*subdesc`.
    ///
    /// \return The value returned by add_column() and add_column_link(), is the
    /// index of the added column.
    ///
    /// \sa has_shared_type()
    /// \sa get_descriptor()
    /// \sa Descriptor
    std::size_t add_column(DataType type, StringData name, DescriptorRef* subdesc = 0);
    void insert_column(std::size_t column_ndx, DataType type, StringData name,
                       DescriptorRef* subdesc = 0);
    std::size_t add_column_link(DataType type, StringData name, Table& target);
    void insert_column_link(std::size_t column_ndx, DataType type, StringData name, Table& target);
    void remove_column(std::size_t column_ndx);
    void rename_column(std::size_t column_ndx, StringData new_name);
    //@}

    //@{

    /// has_search_index() returns true if, and only if a search index has been
    /// added to the specified column. Rather than throwing, it returns false if
    /// the table accessor is detached or the specified index is out of range.
    ///
    /// add_search_index() adds a search index to the specified column of this
    /// table. It has no effect if a search index has already been added to the
    /// specified column (idempotency).
    ///
    /// has_primary_key() returns true if, and only if a primary key has been
    /// added to this table. Rather than throwing, it returns false if the table
    /// accessor is detached.
    ///
    /// try_add_primary_key() tries to add a primary key to this table, by
    /// forming it from the specified column. It fails and returns false if the
    /// specified column has duplicate values, otherwise it returns true. The
    /// specified column must already have a search index. This table must have
    /// no preexisting primary key.
    ///
    /// remove_primary_key() removes a previously added primary key. It is an
    /// error if this table has no primary key.
    ///
    /// This table must be a root table; that is, it must have an independent
    /// descriptor. Freestanding tables, group-level tables, and subtables in a
    /// column of type 'mixed' are all examples of root tables. See add_column()
    /// for more on this.
    ///
    /// \param column_ndx The index of a column of this table.

    bool has_search_index(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;
    void add_search_index(std::size_t column_ndx);
    bool has_primary_key() const TIGHTDB_NOEXCEPT;
    bool try_add_primary_key(std::size_t column_ndx);
    void remove_primary_key();

    //@}

    //@{
    /// Get the dynamic type descriptor for this table.
    ///
    /// Every table has an associated descriptor that specifies its dynamic
    /// type. For simple tables, that is, tables without subtable columns, the
    /// dynamic type can be inspected and modified directly using member
    /// functions such as get_column_count() and add_column(). For more complex
    /// tables, the type is best managed through the associated descriptor
    /// object which is returned by this function.
    ///
    /// \sa has_shared_type()
    DescriptorRef get_descriptor();
    ConstDescriptorRef get_descriptor() const;
    //@}

    //@{
    /// Get the dynamic type descriptor for the column with the
    /// specified index. That column must have type 'table'.
    ///
    /// This is merely a shorthand for calling `get_subdescriptor(column_ndx)`
    /// on the descriptor returned by `get_descriptor()`.
    DescriptorRef get_subdescriptor(std::size_t column_ndx);
    ConstDescriptorRef get_subdescriptor(std::size_t column_ndx) const;
    //@}

    //@{
    /// Get access to an arbitrarily nested dynamic type descriptor.
    ///
    /// The returned descriptor is the one you would get by calling
    /// Descriptor::get_subdescriptor() once for each entry in the specified
    /// path, starting with the descriptor returned by get_descriptor(). The
    /// path is allowed to be empty.
    typedef std::vector<std::size_t> path_vec;
    DescriptorRef get_subdescriptor(const path_vec& path);
    ConstDescriptorRef get_subdescriptor(const path_vec& path) const;
    //@}

    //@{
    /// Convenience functions for manipulating nested table types.
    ///
    /// These functions behave as if they were called on the descriptor returned
    /// by `get_subdescriptor(path)`. These function must be called only on
    /// tables with independent dynamic type.
    ///
    /// \return The value returned by add_subcolumn(), is the index of
    /// the added column within the descriptor referenced by the
    /// specified path.
    ///
    /// \sa Descriptor::add_column()
    /// \sa has_shared_type()
    std::size_t add_subcolumn(const path_vec& path, DataType type, StringData name);
    void insert_subcolumn(const path_vec& path, std::size_t column_ndx,
                          DataType type, StringData name);
    void remove_subcolumn(const path_vec& path, std::size_t column_ndx);
    void rename_subcolumn(const path_vec& path, std::size_t column_ndx, StringData new_name);
    //@}

    /// Does this table share its type with other tables?
    ///
    /// Tables that are direct members of groups have independent
    /// dynamic types. The same is true for free-standing tables and
    /// subtables in coulmns of type 'mixed'. For such tables, this
    /// function returns false.
    ///
    /// When a table has a column of type 'table', the cells in that
    /// column contain subtables. All those subtables have the same
    /// dynamic type, and they share a single type descriptor. For all
    /// such subtables, this function returns true. See
    /// Descriptor::is_root() for more on this.
    ///
    /// Please note that Table functions that modify the dynamic type
    /// directly, such as add_column(), are only allowed to be used on
    /// tables with non-shared type. If you need to modify a shared
    /// type, you will have to do that through the descriptor returned
    /// by get_descriptor(), but note that it will then affect all the
    /// tables sharing that descriptor.
    ///
    /// \sa get_descriptor()
    /// \sa Descriptor::is_root()
    bool has_shared_type() const TIGHTDB_NOEXCEPT;


    template<class T> Columns<T> column(std::size_t column); // FIXME: Should this one have been declared TIGHTDB_NOEXCEPT?

    // Table size and deletion
    bool        is_empty() const TIGHTDB_NOEXCEPT;
    std::size_t size() const TIGHTDB_NOEXCEPT;
    void        clear();

    typedef BasicRowExpr<Table> RowExpr;
    typedef BasicRowExpr<const Table> ConstRowExpr;

    RowExpr get(std::size_t row_ndx) TIGHTDB_NOEXCEPT;
    ConstRowExpr get(std::size_t row_ndx) const TIGHTDB_NOEXCEPT;

    RowExpr front() TIGHTDB_NOEXCEPT;
    ConstRowExpr front() const TIGHTDB_NOEXCEPT;

    RowExpr back() TIGHTDB_NOEXCEPT;
    ConstRowExpr back() const TIGHTDB_NOEXCEPT;

    RowExpr operator[](std::size_t row_ndx) TIGHTDB_NOEXCEPT;
    ConstRowExpr operator[](std::size_t row_ndx) const TIGHTDB_NOEXCEPT;


    //@{

    /// Row handling
    ///
    /// It is an error to call add_empty_row() or insert_empty_row() on a table
    /// with a primary key, if that would result in a violation the implied
    /// *unique constraint* of the primary key. The consequenses of doing so are
    /// unspecified.

    std::size_t add_empty_row(std::size_t num_rows = 1);
    void insert_empty_row(std::size_t row_ndx, std::size_t num_rows = 1);
    void remove(std::size_t row_ndx);
    void remove_last();

    //@}

    /// Move the last row to the specified index. This overwrites the target row
    /// and reduces the number of rows by one. If the target row is the last one
    /// it will just be deleted.
    void move_last_over(std::size_t target_row_ndx);

    //@{

    /// Insert row
    ///
    /// NOTE: You have to insert values in ALL columns followed by
    /// insert_done(). The values must be inserted in column index order.
    ///
    /// It is an error to insert a value into a column that is part of a primary
    /// key, if that would result in a violation the implied *unique constraint*
    /// of the primary key. The consequenses of doing so are unspecified.

    void insert_int(std::size_t column_ndx, std::size_t row_ndx, int64_t value);
    void insert_bool(std::size_t column_ndx, std::size_t row_ndx, bool value);
    void insert_datetime(std::size_t column_ndx, std::size_t row_ndx, DateTime value);
    template<class E> void insert_enum(std::size_t column_ndx, std::size_t row_ndx, E value);
    void insert_float(std::size_t column_ndx, std::size_t row_ndx, float value);
    void insert_double(std::size_t column_ndx, std::size_t row_ndx, double value);
    void insert_string(std::size_t column_ndx, std::size_t row_ndx, StringData value);
    void insert_binary(std::size_t column_ndx, std::size_t row_ndx, BinaryData value);
    void insert_subtable(std::size_t column_ndx, std::size_t row_ndx); // Insert empty table
    void insert_mixed(std::size_t column_ndx, std::size_t row_ndx, Mixed value);
    void insert_link(std::size_t column_ndx, std::size_t row_ndx, std::size_t target_row_ndx);
    void insert_linklist(std::size_t column_ndx, std::size_t row_ndx); // Insert empty link list
    void insert_done();

    //@}

    // Get cell values
    int64_t     get_int(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    bool        get_bool(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    DateTime    get_datetime(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    float       get_float(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    double      get_double(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    StringData  get_string(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    BinaryData  get_binary(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    Mixed       get_mixed(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    DataType    get_mixed_type(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    std::size_t get_link(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;

    TableRef get_link_target(std::size_t column_ndx) TIGHTDB_NOEXCEPT;
    ConstTableRef get_link_target(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;

    template<class T>
    typename T::RowAccessor get_link_accessor(std::size_t column_ndx, std::size_t row_ndx);

    //@{

    /// Set cell values.
    ///
    /// It is an error to assign a value to a column that is part of a primary
    /// key, if that would result in a violation the implied *unique constraint*
    /// of the primary key. The consequenses of doing so are unspecified.

    void set_int(std::size_t column_ndx, std::size_t row_ndx, int_fast64_t value);
    void set_bool(std::size_t column_ndx, std::size_t row_ndx, bool value);
    void set_datetime(std::size_t column_ndx, std::size_t row_ndx, DateTime value);
    template<class E> void set_enum(std::size_t column_ndx, std::size_t row_ndx, E value);
    void set_float(std::size_t column_ndx, std::size_t row_ndx, float value);
    void set_double(std::size_t column_ndx, std::size_t row_ndx, double value);
    void set_string(std::size_t column_ndx, std::size_t row_ndx, StringData value);
    void set_binary(std::size_t column_ndx, std::size_t row_ndx, BinaryData value);
    void set_mixed(std::size_t column_ndx, std::size_t row_ndx, Mixed value);
    void set_link(std::size_t column_ndx, std::size_t row_ndx, std::size_t target_row_ndx);

    //@}

    // Links
    bool is_null_link(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    void nullify_link(std::size_t column_ndx, std::size_t row_ndx);

    // Link lists
    ConstLinkViewRef get_linklist(std::size_t column_ndx, std::size_t row_ndx) const;
    LinkViewRef get_linklist(std::size_t column_ndx, std::size_t row_ndx);
    bool linklist_is_empty(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;
    std::size_t get_link_count(std::size_t column_ndx, std::size_t row_ndx) const TIGHTDB_NOEXCEPT;

    void add_int(std::size_t column_ndx, int64_t value);

    /// Assumes that the specified column is a subtable column (in
    /// particular, not a mixed column) and that the specified table
    /// has a spec that is compatible with that column, that is, the
    /// number of columns must be the same, and corresponding columns
    /// must have identical data types (as returned by
    /// get_column_type()).
    void insert_subtable(std::size_t col_ndx, std::size_t row_ndx, const Table*);
    void insert_mixed_subtable(std::size_t col_ndx, std::size_t row_ndx, const Table*);

    /// Like insert_subtable(std::size_t, std::size_t, const Table*)
    /// but overwrites the specified cell rather than inserting a new
    /// one.
    void set_subtable(std::size_t col_ndx, std::size_t row_ndx, const Table*);
    void set_mixed_subtable(std::size_t col_ndx, std::size_t row_ndx, const Table*);


    // Sub-tables (works on columns whose type is either 'subtable' or
    // 'mixed', for a value in a mixed column that is not a subtable,
    // get_subtable() returns null, get_subtable_size() returns zero,
    // and clear_subtable() replaces the value with an empty table.)
    TableRef get_subtable(std::size_t column_ndx, std::size_t row_ndx);
    ConstTableRef get_subtable(std::size_t column_ndx, std::size_t row_ndx) const;
    std::size_t get_subtable_size(std::size_t column_ndx, std::size_t row_ndx)
        const TIGHTDB_NOEXCEPT;
    void clear_subtable(std::size_t column_ndx, std::size_t row_ndx);

    // Backlinks
    std::size_t get_backlink_count(std::size_t row_ndx, const Table& origin,
                                   std::size_t origin_col_ndx) const TIGHTDB_NOEXCEPT;
    std::size_t get_backlink(std::size_t row_ndx, const Table& origin,
                             std::size_t origin_col_ndx, std::size_t backlink_ndx) const
        TIGHTDB_NOEXCEPT;


    //@{

    /// If this accessor is attached to a subtable, then that subtable has a
    /// parent table, and the subtable either resides in a column of type
    /// `table` or of type `mixed` in that parent. In that case
    /// get_parent_table() returns a reference to the accessor associated with
    /// the parent, and get_parent_row_index() returns the index of the row in
    /// which the subtable resides. In all other cases (free-standing and
    /// group-level tables), get_parent_table() returns null and
    /// get_parent_row_index() returns tightdb::npos.
    ///
    /// If this accessor is attached to a subtable, and \a column_ndx_out is
    /// specified, then `*column_ndx_out` is set to the index of the column of
    /// the parent table in which the subtable resides. If this accessor is not
    /// attached to a subtable, then `*column_ndx_out` will retain its original
    /// value upon return.

    TableRef get_parent_table(std::size_t* column_ndx_out = 0) TIGHTDB_NOEXCEPT;
    ConstTableRef get_parent_table(std::size_t* column_ndx_out = 0) const TIGHTDB_NOEXCEPT;
    std::size_t get_parent_row_index() const TIGHTDB_NOEXCEPT;

    //@}


    /// Only group-level unordered tables can be used as origins or targets of
    /// links.
    bool is_group_level() const TIGHTDB_NOEXCEPT;

    /// If this table is a group-level table, then this function returns the
    /// index of this table within the group. Otherwise it returns tightdb::npos.
    std::size_t get_index_in_group() const TIGHTDB_NOEXCEPT;

    // Aggregate functions
    std::size_t count_int(std::size_t column_ndx, int64_t value) const;
    std::size_t count_string(std::size_t column_ndx, StringData value) const;
    std::size_t count_float(std::size_t column_ndx, float value) const;
    std::size_t count_double(std::size_t column_ndx, double value) const;

    int64_t sum_int(std::size_t column_ndx) const;
    double  sum_float(std::size_t column_ndx) const;
    double  sum_double(std::size_t column_ndx) const;
    int64_t maximum_int(std::size_t column_ndx, std::size_t* return_ndx = 0) const;
    float   maximum_float(std::size_t column_ndx, std::size_t* return_ndx = 0) const;
    double  maximum_double(std::size_t column_ndx, std::size_t* return_ndx = 0) const;
    int64_t minimum_int(std::size_t column_ndx, std::size_t* return_ndx = 0) const;
    float   minimum_float(std::size_t column_ndx, std::size_t* return_ndx = 0) const;
    double  minimum_double(std::size_t column_ndx, std::size_t* return_ndx = 0) const;
    double  average_int(std::size_t column_ndx) const;
    double  average_float(std::size_t column_ndx) const;
    double  average_double(std::size_t column_ndx) const;

    // Searching
    std::size_t    find_first_link(std::size_t target_row_index) const;
    std::size_t    find_first_int(std::size_t column_ndx, int64_t value) const;
    std::size_t    find_first_bool(std::size_t column_ndx, bool value) const;
    std::size_t    find_first_datetime(std::size_t column_ndx, DateTime value) const;
    std::size_t    find_first_float(std::size_t column_ndx, float value) const;
    std::size_t    find_first_double(std::size_t column_ndx, double value) const;
    std::size_t    find_first_string(std::size_t column_ndx, StringData value) const;
    std::size_t    find_first_binary(std::size_t column_ndx, BinaryData value) const;

    TableView      find_all_link(size_t target_row_index);
    ConstTableView find_all_link(size_t target_row_index) const;
    TableView      find_all_int(std::size_t column_ndx, int64_t value);
    ConstTableView find_all_int(std::size_t column_ndx, int64_t value) const;
    TableView      find_all_bool(std::size_t column_ndx, bool value);
    ConstTableView find_all_bool(std::size_t column_ndx, bool value) const;
    TableView      find_all_datetime(std::size_t column_ndx, DateTime value);
    ConstTableView find_all_datetime(std::size_t column_ndx, DateTime value) const;
    TableView      find_all_float(std::size_t column_ndx, float value);
    ConstTableView find_all_float(std::size_t column_ndx, float value) const;
    TableView      find_all_double(std::size_t column_ndx, double value);
    ConstTableView find_all_double(std::size_t column_ndx, double value) const;
    TableView      find_all_string(std::size_t column_ndx, StringData value);
    ConstTableView find_all_string(std::size_t column_ndx, StringData value) const;
    TableView      find_all_binary(std::size_t column_ndx, BinaryData value);
    ConstTableView find_all_binary(std::size_t column_ndx, BinaryData value) const;

    TableView      get_distinct_view(std::size_t column_ndx);
    ConstTableView get_distinct_view(std::size_t column_ndx) const;

    TableView      get_sorted_view(std::size_t column_ndx, bool ascending = true);
    ConstTableView get_sorted_view(std::size_t column_ndx, bool ascending = true) const;

    TableView      get_range_view(std::size_t begin, std::size_t end);
    ConstTableView get_range_view(std::size_t begin, std::size_t end) const;


    //@{

    /// Find the row with the specified primary key.
    ///
    /// It is an error to call any of these function on a table that has no
    /// primary key, or to call one of them for a column with a mismatching
    /// type.

    RowExpr find_pkey_int(int_fast64_t pkey_value);
    ConstRowExpr find_pkey_int(int_fast64_t pkey_value) const;

    RowExpr find_pkey_string(StringData pkey_value);
    ConstRowExpr find_pkey_string(StringData pkey_value) const;

    //@}


    // Pivot / aggregate operation types. Experimental! Please do not document method publicly.
    enum AggrType {
        aggr_count,
        aggr_sum,
        aggr_avg,
        aggr_min,
        aggr_max
    };

    // Simple pivot aggregate method. Experimental! Please do not document method publicly.
    void aggregate(size_t group_by_column, size_t aggr_column, AggrType op, Table& result, const Column* viewrefs = null_ptr) const;


private:
    template <class T> std::size_t find_first(std::size_t column_ndx, T value) const; // called by above methods
    template <class T> TableView find_all(size_t column_ndx, T value);
public:


    //@{
    /// Find the lower/upper bound according to a column that is
    /// already sorted in ascending order.
    ///
    /// For an integer column at index 0, and an integer value '`v`',
    /// lower_bound_int(0,v) returns the index '`l`' of the first row
    /// such that `get_int(0,l) &ge; v`, and upper_bound_int(0,v)
    /// returns the index '`u`' of the first row such that
    /// `get_int(0,u) &gt; v`. In both cases, if no such row is found,
    /// the returned value is the number of rows in the table.
    ///
    ///     3 3 3 4 4 4 5 6 7 9 9 9
    ///     ^     ^     ^     ^     ^
    ///     |     |     |     |     |
    ///     |     |     |     |      -- Lower and upper bound of 15
    ///     |     |     |     |
    ///     |     |     |      -- Lower and upper bound of 8
    ///     |     |     |
    ///     |     |      -- Upper bound of 4
    ///     |     |
    ///     |      -- Lower bound of 4
    ///     |
    ///      -- Lower and upper bound of 1
    ///
    /// These functions are similar to std::lower_bound() and
    /// std::upper_bound().
    ///
    /// The string versions assume that the column is sorted according
    /// to StringData::operator<().
    std::size_t lower_bound_int(std::size_t column_ndx, int64_t value) const TIGHTDB_NOEXCEPT;
    std::size_t upper_bound_int(std::size_t column_ndx, int64_t value) const TIGHTDB_NOEXCEPT;
    std::size_t lower_bound_bool(std::size_t column_ndx, bool value) const TIGHTDB_NOEXCEPT;
    std::size_t upper_bound_bool(std::size_t column_ndx, bool value) const TIGHTDB_NOEXCEPT;
    std::size_t lower_bound_float(std::size_t column_ndx, float value) const TIGHTDB_NOEXCEPT;
    std::size_t upper_bound_float(std::size_t column_ndx, float value) const TIGHTDB_NOEXCEPT;
    std::size_t lower_bound_double(std::size_t column_ndx, double value) const TIGHTDB_NOEXCEPT;
    std::size_t upper_bound_double(std::size_t column_ndx, double value) const TIGHTDB_NOEXCEPT;
    std::size_t lower_bound_string(std::size_t column_ndx, StringData value) const TIGHTDB_NOEXCEPT;
    std::size_t upper_bound_string(std::size_t column_ndx, StringData value) const TIGHTDB_NOEXCEPT;
    //@}

    // Queries
    // Using where(tv) is the new method to perform queries on TableView. The 'tv' can have any order; it does not
    // need to be sorted, and, resulting view retains its order.
    Query where(RowIndexes* tv = null_ptr) { return Query(*this, tv); }

    // FIXME: We need a ConstQuery class or runtime check against modifications in read transaction.
    Query where(RowIndexes* tv = null_ptr) const { return Query(*this, tv); }

    // Perform queries on a LinkView. The returned Query holds a reference to lv.
    Query where(const LinkViewRef& lv) { return Query(*this, lv); }

    Table& link(size_t link_column);

    // Optimizing
    void optimize();

    /// Write this table (or a slice of this table) to the specified
    /// output stream.
    ///
    /// The output will have the same format as any other TightDB
    /// database file, such as those produced by Group::write(). In
    /// this case, however, the resulting database file will contain
    /// exactly one table, and that table will contain only the
    /// specified slice of the source table (this table).
    ///
    /// The new table will always have the same dynamic type (see
    /// Descriptor) as the source table (this table), and unless it is
    /// overridden (\a override_table_name), the new table will have
    /// the same name as the source table (see get_name()). Indexes
    /// (see add_search_index()) will not be carried over to the new
    /// table.
    ///
    /// \param offset Index of first row to include (if `size >
    /// 0`). Must be less than, or equal to size().
    ///
    /// \param size Number of rows to include. May be zero. If `size >
    /// size() - offset`, then the effective size of the written slice
    /// will be `size() - offset`.
    ///
    /// \throw std::out_of_range If `offset > size()`.
    ///
    /// FIXME: While this function does provided a maximally efficient
    /// way of serializing part of a table, it offers little in terms
    /// of general utility. This is unfortunate, because it pulls
    /// quite a large amount of code into the core library to support
    /// it.
    void write(std::ostream&, std::size_t offset = 0, std::size_t size = npos,
               StringData override_table_name = StringData()) const;

    // Conversion
    void to_json(std::ostream& out, size_t link_depth = 0, std::map<std::string,
                 std::string>* renames = 0) const;
    void to_string(std::ostream& out, std::size_t limit = 500) const;
    void row_to_string(std::size_t row_ndx, std::ostream& out) const;

    // Get a reference to this table
    TableRef get_table_ref() { return TableRef(this); }
    ConstTableRef get_table_ref() const { return ConstTableRef(this); }

    /// Compare two tables for equality. Two tables are equal if, and
    /// only if, they contain the same columns and rows in the same
    /// order, that is, for each value V of type T at column index C
    /// and row index R in one of the tables, there is a value of type
    /// T at column index C and row index R in the other table that
    /// is equal to V.
    bool operator==(const Table&) const;

    /// Compare two tables for inequality. See operator==().
    bool operator!=(const Table& t) const;

    /// A subtable in a column of type 'table' (which shares descriptor with
    /// other subtables in the same column) is initially in a degenerate state
    /// where it takes up a minimal amout of space. This function returns true
    /// if, and only if the table accessor is attached to such a subtable. This
    /// function is mainly intended for debugging purposes.
    bool is_degenerate() const TIGHTDB_NOEXCEPT;

    // Debug
#ifdef TIGHTDB_DEBUG
    void Verify() const; // Must be upper case to avoid conflict with macro in ObjC
    void to_dot(std::ostream&, StringData title = StringData()) const;
    void print() const;
    MemStats stats() const;
    void dump_node_structure() const; // To std::cerr (for GDB)
    void dump_node_structure(std::ostream&, int level) const;
#else
    void Verify() const {}
#endif

    class Parent;

protected:
    /// Get a pointer to the accessor of the specified subtable. The
    /// accessor will be created if it does not already exist.
    ///
    /// The returned table pointer must **always** end up being
    /// wrapped in some instantiation of BasicTableRef<>.
    Table* get_subtable_ptr(std::size_t col_ndx, std::size_t row_ndx);

    /// See non-const get_subtable_ptr().
    const Table* get_subtable_ptr(std::size_t col_ndx, std::size_t row_ndx) const;

    /// Compare the rows of two tables under the assumption that the two tables
    /// have the same number of columns, and the same data type at each column
    /// index (as expressed through the DataType enum).
    bool compare_rows(const Table&) const;

    void insert_into(Table* parent, std::size_t col_ndx, std::size_t row_ndx) const;

    void set_into_mixed(Table* parent, std::size_t col_ndx, std::size_t row_ndx) const;

private:
    class SliceWriter;

    // Number of rows in this table
    std::size_t m_size;

    // Underlying array structure. `m_top` is in use only for root tables; that
    // is, for tables with independent descriptor. `m_columns` contains a ref
    // for each column and search index in order of the columns. A search index
    // ref always occurs immediately after the ref of the column to which the
    // search index belongs.
    //
    // A subtable column (a column of type `type_table`) is essentially just a
    // column of 'refs' pointing to the root node of each subtable.
    //
    // To save space in the database file, a subtable in such a column always
    // starts out in a degenerate form where nothing is allocated on its behalf,
    // and a null 'ref' is stored in the corresponding slot of the column. A
    // subtable remains in this degenerate state until the first row is added to
    // the subtable.
    //
    // For this scheme to work, it must be (and is) possible to create a table
    // accessor that refers to a degenerate subtable. A table accessor (instance
    // of `Table`) refers to a degenerate subtable if, and only if `m_columns`
    // is unattached.
    //
    // FIXME: The fact that `m_columns` may be detached means that many
    // functions (even non-modifying functions) need to check for that before
    // accessing the contents of the table. This incurs a runtime
    // overhead. Consider whether this overhead can be eliminated by having
    // `Table::m_columns` always attached to something, and then detect the
    // degenerate state in a different way.
    Array m_top;
    Array m_columns; // 2nd slot in m_top (for root tables)
    Spec m_spec;     // 1st slot in m_top (for root tables)

    // Is guaranteed to be empty for a detached accessor. Otherwise it is empty
    // when the table accessor is attached to a degenerate subtable (unattached
    // `m_columns`), otherwise it contains precisely one column accessor for
    // each column in the table, in order.
    //
    // In some cases an entry may be null. This is currently possible only in
    // connection with Group::advance_transact(), but it means that several
    // member functions must be prepared to handle these null entries; in
    // particular, detach(), ~Table(), functions called on behalf of detach()
    // and ~Table(), and functiones called on behalf of
    // Group::advance_transact().
    typedef std::vector<ColumnBase*> column_accessors;
    column_accessors m_cols;

    mutable std::size_t m_ref_count;
    mutable const StringIndex* m_primary_key;

    // If this table is a root table (has independent descriptor),
    // then Table::m_descriptor refers to the accessor of its
    // descriptor when, and only when the descriptor accessor
    // exists. This is used to ensure that at most one descriptor
    // accessor exists for each underlying descriptor at any given
    // point in time. Subdescriptors are kept unique by means of a
    // registry in the parent descriptor. Table::m_descriptor is
    // always null for tables with shared descriptor.
    mutable Descriptor* m_descriptor;

    // Table view instances
    typedef std::vector<const TableViewBase*> views;
    mutable views m_views;

    // Points to first bound row accessor, or is null if there are none.
    mutable RowBase* m_row_accessors;

    // Used for queries: Items are added with link() method during buildup of query
    mutable std::vector<size_t> m_link_chain;

    /// Used only in connection with Group::advance_transact() and
    /// Table::refresh_accessor_tree().
    mutable bool m_mark;

#ifdef TIGHTDB_ENABLE_REPLICATION
    mutable uint_fast64_t m_version;
#endif

    /// Update the version of this table and all tables which have links to it.
    /// This causes all views referring to those tables to go out of sync, so that
    /// calls to sync_if_needed() will bring the view up to date by reexecuting the
    /// query.
    ///
    /// \param bump_global chooses whether the global versioning counter must be
    /// bumped first as part of the update. This is the normal mode of operation,
    /// when a change is made to the table. When calling recursively (following links
    /// or going to the parent table), the parameter should be set to false to correctly
    /// prune traversal.
    void bump_version(bool bump_global = true) const TIGHTDB_NOEXCEPT;

    /// Disable copying assignment.
    ///
    /// It could easily be implemented by calling assign(), but the
    /// non-checking nature of the low-level dynamically typed API
    /// makes it too risky to offer this feature as an
    /// operator.
    ///
    /// FIXME: assign() has not yet been implemented, but the
    /// intention is that it will copy the rows of the argument table
    /// into this table after clearing the original contents, and for
    /// target tables without a shared spec, it would also copy the
    /// spec. For target tables with shared spec, it would be an error
    /// to pass an argument table with an incompatible spec, but
    /// assign() would not check for spec compatibility. This would
    /// make it ideal as a basis for implementing operator=() for
    /// typed tables.
    Table& operator=(const Table&);

    /// Used when constructing an accessor whose lifetime is going to be managed
    /// by reference counting. The lifetime of accessors of free-standing tables
    /// allocated on the stack by the application is not managed by reference
    /// counting, so that is a case where this tag must **not** be specified.
    class ref_count_tag {};

    /// Create an uninitialized accessor whose lifetime is managed by reference
    /// counting.
    Table(ref_count_tag, Allocator&);

    void init(ref_type top_ref, ArrayParent*, std::size_t ndx_in_parent,
              bool skip_create_column_accessors = false);
    void init(ConstSubspecRef shared_spec, ArrayParent* parent_column,
              std::size_t parent_row_ndx);

    void reveal_primary_key() const;
    std::size_t do_find_pkey_int(int_fast64_t) const;
    std::size_t do_find_pkey_string(StringData) const;

    static void do_insert_column(Descriptor&, std::size_t col_ndx, DataType type,
                                 StringData name, Table* link_target_table);
    static void do_erase_column(Descriptor&, std::size_t col_ndx);
    static void do_rename_column(Descriptor&, std::size_t col_ndx, StringData name);

    struct InsertSubtableColumns;
    struct EraseSubtableColumns;
    struct RenameSubtableColumns;

    void insert_root_column(std::size_t col_ndx, DataType type, StringData name,
                            Table* link_target_table);
    void erase_root_column(std::size_t col_ndx);
    void do_insert_root_column(std::size_t col_ndx, ColumnType, StringData name);
    void do_erase_root_column(std::size_t col_ndx);
    void insert_backlink_column(std::size_t origin_table_ndx, std::size_t origin_col_ndx);
    void erase_backlink_column(std::size_t origin_table_ndx, std::size_t origin_col_ndx);
    void update_link_target_tables(std::size_t old_col_ndx_begin, std::size_t new_col_ndx_begin);

    struct SubtableUpdater {
        virtual void update(const ColumnTable&, Array& subcolumns) = 0;
        virtual void update_accessor(Table&) = 0;
        virtual ~SubtableUpdater() {}
    };
    static void update_subtables(Descriptor&, SubtableUpdater*);
    void update_subtables(const std::size_t* col_path_begin, const std::size_t* col_path_end,
                          SubtableUpdater*);

    struct AccessorUpdater {
        virtual void update(Table&) = 0;
        virtual void update_parent(Table&) = 0;
        virtual ~AccessorUpdater() {}
    };
    void update_accessors(const std::size_t* col_path_begin, const std::size_t* col_path_end,
                          AccessorUpdater&);

    void create_degen_subtab_columns();
    ColumnBase* create_column_accessor(ColumnType, std::size_t col_ndx, std::size_t ndx_in_parent);
    void destroy_column_accessors() TIGHTDB_NOEXCEPT;

    /// Called in the context of Group::commit() to ensure that
    /// attached table accessors stay valid across a commit. Please
    /// note that this works only for non-transactional commits. Table
    /// accessors obtained during a transaction are always detached
    /// when the transaction ends.
    void update_from_parent(std::size_t old_baseline) TIGHTDB_NOEXCEPT;

    // Support function for conversions
    void to_string_header(std::ostream& out, std::vector<std::size_t>& widths) const;
    void to_string_row(std::size_t row_ndx, std::ostream& out,
                       const std::vector<std::size_t>& widths) const;

    // recursive methods called by to_json, to follow links
    void to_json(std::ostream& out, size_t link_depth, std::map<std::string, std::string>& renames,
        std::vector<ref_type>& followed) const;
    void to_json_row(std::size_t row_ndx, std::ostream& out, size_t link_depth,
        std::map<std::string, std::string>& renames, std::vector<ref_type>& followed) const;
    void to_json_row(std::size_t row_ndx, std::ostream& out, size_t link_depth = 0,
        std::map<std::string, std::string>* renames = null_ptr) const;

    // Detach accessor from underlying table. Caller must ensure that
    // a reference count exists upon return, for example by obtaining
    // an extra reference count before the call.
    //
    // This function puts this table accessor into the detached
    // state. This detaches it from the underlying structure of array
    // nodes. It also recursively detaches accessors for subtables,
    // and the type descriptor accessor. When this function returns,
    // is_attached() will return false.
    //
    // This function may be called for a table accessor that is
    // already in the detached state (idempotency).
    //
    // It is also valid to call this function for a table accessor
    // that has not yet been detached, but whose underlying structure
    // of arrays have changed in an unpredictable/unknown way. This
    // kind of change generally happens when a modifying table
    // operation fails, and also when one transaction is ended and a
    // new one is started.
    void detach() TIGHTDB_NOEXCEPT;

    /// Detach and remove all attached row, link list, and subtable
    /// accessors. This function does not discard the descriptor accessor, if
    /// any, and it does not discard column accessors either.
    void discard_child_accessors() TIGHTDB_NOEXCEPT;

    void discard_row_accessors() TIGHTDB_NOEXCEPT;

    // Detach the type descriptor accessor if it exists.
    void discard_desc_accessor() TIGHTDB_NOEXCEPT;

    void bind_ref() const TIGHTDB_NOEXCEPT { ++m_ref_count; }
    void unbind_ref() const TIGHTDB_NOEXCEPT { if (--m_ref_count == 0) delete this; }

    void register_view(const TableViewBase* view);
    void unregister_view(const TableViewBase* view) TIGHTDB_NOEXCEPT;
    void move_registered_view(const TableViewBase* old_addr,
                              const TableViewBase* new_addr) TIGHTDB_NOEXCEPT;
    void discard_views() TIGHTDB_NOEXCEPT;

    void register_row_accessor(RowBase*) const TIGHTDB_NOEXCEPT;
    void unregister_row_accessor(RowBase*) const TIGHTDB_NOEXCEPT;

    class UnbindGuard;

    ColumnType get_real_column_type(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;

    /// If this table is a group-level table, the parent group is returned,
    /// otherwise null is returned.
    Group* get_parent_group() const TIGHTDB_NOEXCEPT;

    const Array* get_column_root(std::size_t col_ndx) const TIGHTDB_NOEXCEPT;
    std::pair<const Array*, const Array*> get_string_column_roots(std::size_t col_ndx) const
        TIGHTDB_NOEXCEPT;

    const ColumnBase& get_column_base(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;
    ColumnBase& get_column_base(std::size_t column_ndx);
    template <class T, ColumnType col_type> T& get_column(std::size_t ndx);
    template <class T, ColumnType col_type> const T& get_column(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    Column& get_column(std::size_t column_ndx);
    const Column& get_column(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;
    ColumnFloat& get_column_float(std::size_t column_ndx);
    const ColumnFloat& get_column_float(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;
    ColumnDouble& get_column_double(std::size_t column_ndx);
    const ColumnDouble& get_column_double(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;
    AdaptiveStringColumn& get_column_string(std::size_t column_ndx);
    const AdaptiveStringColumn& get_column_string(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;
    ColumnBinary& get_column_binary(std::size_t column_ndx);
    const ColumnBinary& get_column_binary(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;
    ColumnStringEnum& get_column_string_enum(std::size_t column_ndx);
    const ColumnStringEnum& get_column_string_enum(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;
    ColumnTable& get_column_table(std::size_t column_ndx);
    const ColumnTable& get_column_table(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;
    ColumnMixed& get_column_mixed(std::size_t column_ndx);
    const ColumnMixed& get_column_mixed(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;
    const ColumnLinkBase& get_column_link_base(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    ColumnLinkBase& get_column_link_base(std::size_t ndx);
    const ColumnLink& get_column_link(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    ColumnLink& get_column_link(std::size_t ndx);
    const ColumnLinkList& get_column_link_list(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    ColumnLinkList& get_column_link_list(std::size_t ndx);
    const ColumnBackLink& get_column_backlink(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    ColumnBackLink& get_column_backlink(std::size_t ndx);

    void instantiate_before_change();
    void validate_column_type(const ColumnBase& column, ColumnType expected_type,
                              std::size_t ndx) const;

    static std::size_t get_size_from_ref(ref_type top_ref, Allocator&) TIGHTDB_NOEXCEPT;
    static std::size_t get_size_from_ref(ref_type spec_ref, ref_type columns_ref,
                                         Allocator&) TIGHTDB_NOEXCEPT;

    const Table* get_parent_table_ptr(std::size_t* column_ndx_out = 0) const TIGHTDB_NOEXCEPT;
    Table* get_parent_table_ptr(std::size_t* column_ndx_out = 0) TIGHTDB_NOEXCEPT;

    /// Create an empty table with independent spec and return just
    /// the reference to the underlying memory.
    static ref_type create_empty_table(Allocator&);

    /// Create a column of the specified type, fill it with the
    /// specified number of default values, and return just the
    /// reference to the underlying memory.
    static ref_type create_column(ColumnType column_type, size_t num_default_values, Allocator&);

    /// Construct a copy of the columns array of this table using the
    /// specified allocator and return just the ref to that array.
    ///
    /// In the clone, no string column will be of the enumeration
    /// type.
    ref_type clone_columns(Allocator&) const;

    /// Construct a complete copy of this table (including its spec)
    /// using the specified allocator and return just the ref to the
    /// new top array.
    ref_type clone(Allocator&) const;

    /// True for `col_type_Link` and `col_type_LinkList`.
    static bool is_link_type(ColumnType) TIGHTDB_NOEXCEPT;

    void connect_opposite_link_columns(std::size_t link_col_ndx, Table& target_table,
                                       std::size_t backlink_col_ndx) TIGHTDB_NOEXCEPT;

    // Precondition: 1 <= end - begin
    std::size_t* record_subtable_path(std::size_t* begin,
                                      std::size_t* end) const TIGHTDB_NOEXCEPT;

    /// Check if an accessor exists for the specified subtable. If it does,
    /// return a pointer to it, otherwise return null. This function assumes
    /// that the specified column index in a valid index into `m_cols` but does
    /// not otherwise assume more than minimal accessor consistency (see
    /// AccessorConsistencyLevels.)
    Table* get_subtable_accessor(std::size_t col_ndx, std::size_t row_ndx) TIGHTDB_NOEXCEPT;

    /// Unless the column accessor is missing, this function returns the
    /// accessor for the target table of the specified link-type column. The
    /// column accessor is said to be missing if `m_cols[col_ndx]` is null, and
    /// this can happen only during certain operations such as the updating of
    /// the accessor tree when a read transaction is advanced. Note that for
    /// link type columns, the target table accessor exists when, and only when
    /// the origin table accessor exists. This function assumes that the
    /// specified column index in a valid index into `m_cols` and that the
    /// column is a link-type column. Beyond that, it assume nothing more than
    /// minimal accessor consistency (see AccessorConsistencyLevels.)
    Table* get_link_target_table_accessor(std::size_t col_ndx) TIGHTDB_NOEXCEPT;

    void discard_subtable_accessor(std::size_t col_ndx, std::size_t row_ndx) TIGHTDB_NOEXCEPT;

    void adj_accessors_insert_rows(std::size_t row_ndx, std::size_t num_rows) TIGHTDB_NOEXCEPT;
    void adj_accessors_erase_row(std::size_t row_ndx) TIGHTDB_NOEXCEPT;
    void adj_accessors_move(std::size_t target_row_ndx, std::size_t source_row_ndx)
        TIGHTDB_NOEXCEPT;
    void adj_acc_clear_root_table() TIGHTDB_NOEXCEPT;
    void adj_acc_clear_nonroot_table() TIGHTDB_NOEXCEPT;
    void adj_row_acc_insert_rows(std::size_t row_ndx, std::size_t num_rows) TIGHTDB_NOEXCEPT;
    void adj_row_acc_erase_row(std::size_t row_ndx) TIGHTDB_NOEXCEPT;
    void adj_row_acc_move(std::size_t target_row_ndx, std::size_t source_row_ndx)
        TIGHTDB_NOEXCEPT;
    void adj_insert_column(std::size_t col_ndx);
    void adj_erase_column(std::size_t col_ndx) TIGHTDB_NOEXCEPT;

    bool is_marked() const TIGHTDB_NOEXCEPT;
    void mark() TIGHTDB_NOEXCEPT;
    void unmark() TIGHTDB_NOEXCEPT;
    void recursive_mark() TIGHTDB_NOEXCEPT;
    void mark_link_target_tables(std::size_t col_ndx_begin) TIGHTDB_NOEXCEPT;
    void mark_opposite_link_tables() TIGHTDB_NOEXCEPT;

#ifdef TIGHTDB_ENABLE_REPLICATION
    Replication* get_repl() TIGHTDB_NOEXCEPT;
#endif

    void set_ndx_in_parent(std::size_t ndx_in_parent) TIGHTDB_NOEXCEPT;

    /// Refresh the part of the accessor tree that is rooted at this
    /// table. Subtable accessors will be refreshed only if they are marked
    /// (Table::m_mark), and this applies recursively to subtables of
    /// subtables. All refreshed table accessors (including this one) will be
    /// unmarked upon return.
    ///
    /// The following conditions are necessary and sufficient for the proper
    /// operation of this function:
    ///
    ///  - This table must be a group-level table, or a subtable. It must not be
    ///    a free-standing table (because a free-standing table has no parent).
    ///
    ///  - The `index in parent` property is correct. The `index in parent`
    ///    property of the table is the `index in parent` property of
    ///    `m_columns` for subtables with shared descriptor, and the `index in
    ///    parent` property of `m_top` for all other tables.
    ///
    ///  - If this table has shared descriptor, then the `index in parent`
    ///    property of the contained spec accessor is correct.
    ///
    ///  - The parent accessor is in a valid state (already refreshed). If the
    ///    parent is a group, then the group accessor (excluding its table
    ///    accessors) must be in a valid state. If the parent is a table, then
    ///    the table accessor (excluding its subtable accessors) must be in a
    ///    valid state.
    ///
    ///  - Every descendant subtable accessor is marked if it needs to be
    ///    refreshed, or if it has a descendant accessor that needs to be
    ///    refreshed.
    ///
    ///  - This table accessor, as well as all its descendant accessors, are in
    ///    structural correspondence with the underlying node hierarchy whose
    ///    root ref is stored in the parent (see AccessorConsistencyLevels).
    void refresh_accessor_tree();

    void refresh_column_accessors(std::size_t col_ndx_begin = 0);

    bool is_cross_table_link_target() const TIGHTDB_NOEXCEPT;

#ifdef TIGHTDB_DEBUG
    void to_dot_internal(std::ostream&) const;
#endif

    friend class SubtableNode;
    friend class _impl::TableFriend;
    friend class Query;
    template<class> friend class util::bind_ptr;
    friend class LangBindHelper;
    friend class TableViewBase;
    friend class TableView;
    template<class T> friend class Columns;
    friend class Columns<StringData>;
    friend class ParentNode;
    template<class> friend class SequentialGetter;
    friend class RowBase;
    friend class LinksToNode;
    friend class LinkMap;
    friend class LinkView;
};



class Table::Parent: public ArrayParent {
public:
    ~Parent() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {}

protected:
    virtual StringData get_child_name(std::size_t child_ndx) const TIGHTDB_NOEXCEPT;

    /// If children are group-level tables, then this function returns the
    /// group. Otherwise it returns null.
    virtual Group* get_parent_group() TIGHTDB_NOEXCEPT;

    /// If children are subtables, then this function returns the
    /// parent table. Otherwise it returns null.
    ///
    /// If \a column_ndx_out is not null, this function must assign the index of
    /// the column within the parent table to `*column_ndx_out` when , and only
    /// when this table parent is a column in a parent table.
    virtual Table* get_parent_table(std::size_t* column_ndx_out = 0) TIGHTDB_NOEXCEPT;

    /// Must be called whenever a child table accessor is about to be destroyed.
    ///
    /// Note that the argument is a pointer to the child Table rather than its
    /// `ndx_in_parent` property. This is because only minimal accessor
    /// consistency can be assumed by this function.
    virtual void child_accessor_destroyed(Table* child) TIGHTDB_NOEXCEPT = 0;

    virtual std::size_t* record_subtable_path(std::size_t* begin,
                                              std::size_t* end) TIGHTDB_NOEXCEPT;

    friend class Table;
};





// Implementation:


#ifdef TIGHTDB_ENABLE_REPLICATION

inline void Table::bump_version(bool bump_global) const TIGHTDB_NOEXCEPT
{
    if (bump_global) {
        // This is only set on initial entry through an operation on the same
        // table.  recursive calls (via parent or via backlinks) must be done
        // with bump_global=false.
        m_top.get_alloc().bump_global_version();
    }
    if (m_top.get_alloc().should_propagate_version(m_version)) {
        if (const Table* parent = get_parent_table_ptr())
            parent->bump_version(false);
        // Recurse through linked tables, use m_mark to avoid infinite recursion
        std::size_t limit = m_cols.size();
        for (std::size_t i = 0; i < limit; ++i) {
            // We may meet a null pointer in place of a backlink column, pending
            // replacement with a new one. This can happen ONLY when creation of
            // the corresponding forward link column in the origin table is
            // pending as well. In this case it is ok to just ignore the zeroed
            // backlink column, because the origin table is guaranteed to also
            // be refreshed/marked dirty and hence have it's version bumped.
            if (ColumnBase* col = m_cols[i])
                col->bump_link_origin_table_version();
        }
    }
}

#else // TIGHTDB_ENABLE_REPLICATION

inline void Table::bump_version(bool) const TIGHTDB_NOEXCEPT
{
    // No-op when replication is disabled at compile time
}

#endif // TIGHTDB_ENABLE_REPLICATION

inline void Table::remove_last()
{
    if (!is_empty())
        remove(size()-1);
}

inline void Table::register_view(const TableViewBase* view)
{
    m_views.push_back(view);
}

inline bool Table::is_attached() const TIGHTDB_NOEXCEPT
{
    // Note that it is not possible to tie the state of attachment of a table to
    // the state of attachment of m_top, because tables with shared spec do not
    // have a 'top' array. Neither is it possible to tie it to the state of
    // attachment of m_columns, because subtables with shared spec start out in
    // a degenerate form where they do not have a 'columns' array. For these
    // reasons, it is neccessary to define the notion of attachment for a table
    // as follows: A table is attached if, and ony if m_column stores a non-null
    // parent pointer. This works because even for degenerate subtables,
    // m_columns is initialized with the correct parent pointer.
    return m_columns.has_parent();
}

inline StringData Table::get_name() const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    const Array& real_top = m_top.is_attached() ? m_top : m_columns;
    ArrayParent* parent = real_top.get_parent();
    if (!parent)
        return StringData();
    std::size_t index_in_parent = real_top.get_ndx_in_parent();
    TIGHTDB_ASSERT(dynamic_cast<Parent*>(parent));
    return static_cast<Parent*>(parent)->get_child_name(index_in_parent);
}

inline std::size_t Table::get_column_count() const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    return m_spec.get_public_column_count();
}

inline StringData Table::get_column_name(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < get_column_count());
    return m_spec.get_column_name(ndx);
}

inline std::size_t Table::get_column_index(StringData name) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    return m_spec.get_column_index(name);
}

inline ColumnType Table::get_real_column_type(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < m_spec.get_column_count());
    return m_spec.get_column_type(ndx);
}

inline DataType Table::get_column_type(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(ndx < m_spec.get_column_count());
    return m_spec.get_public_column_type(ndx);
}

template<class Col, ColumnType col_type> inline Col& Table::get_column(std::size_t ndx)
{
    ColumnBase& col = get_column_base(ndx);
#ifdef TIGHTDB_DEBUG
    validate_column_type(col, col_type, ndx);
#endif
    TIGHTDB_ASSERT(dynamic_cast<Col*>(&col));
    return static_cast<Col&>(col);
}

template<class Col, ColumnType col_type>
inline const Col& Table::get_column(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    const ColumnBase& col = get_column_base(ndx);
#ifdef TIGHTDB_DEBUG
    validate_column_type(col, col_type, ndx);
#endif
    TIGHTDB_ASSERT(dynamic_cast<const Col*>(&col));
    return static_cast<const Col&>(col);
}

inline bool Table::has_shared_type() const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    return !m_top.is_attached();
}


class Table::UnbindGuard {
public:
    UnbindGuard(Table* table) TIGHTDB_NOEXCEPT: m_table(table)
    {
    }

    ~UnbindGuard() TIGHTDB_NOEXCEPT
    {
        if (m_table)
            m_table->unbind_ref();
    }

    Table& operator*() const TIGHTDB_NOEXCEPT
    {
        return *m_table;
    }

    Table* operator->() const TIGHTDB_NOEXCEPT
    {
        return m_table;
    }

    Table* get() const TIGHTDB_NOEXCEPT
    {
        return m_table;
    }

    Table* release() TIGHTDB_NOEXCEPT
    {
        Table* table = m_table;
        m_table = 0;
        return table;
    }

private:
    Table* m_table;
};


inline Table::Table(Allocator& alloc):
    m_top(alloc),
    m_columns(alloc),
    m_spec(alloc)
{
    m_ref_count = 1; // Explicitely managed lifetime
    m_descriptor = 0;
    m_row_accessors = 0;

    ref_type ref = create_empty_table(alloc); // Throws
    Parent* parent = 0;
    std::size_t ndx_in_parent = 0;
    init(ref, parent, ndx_in_parent);
}

inline Table::Table(const Table& t, Allocator& alloc):
    m_top(alloc),
    m_columns(alloc),
    m_spec(alloc)
{
    m_ref_count = 1; // Explicitely managed lifetime
    m_descriptor = 0;
    m_row_accessors = 0;

    ref_type ref = t.clone(alloc); // Throws
    Parent* parent = 0;
    std::size_t ndx_in_parent = 0;
    init(ref, parent, ndx_in_parent);
}

inline Table::Table(ref_count_tag, Allocator& alloc):
    m_top(alloc),
    m_columns(alloc),
    m_spec(alloc)
{
    m_ref_count = 0; // Lifetime managed by reference counting
    m_descriptor = 0;
    m_row_accessors = 0;
}

inline TableRef Table::create(Allocator& alloc)
{
    util::UniquePtr<Table> table(new Table(ref_count_tag(), alloc)); // Throws
    ref_type ref = create_empty_table(alloc); // Throws
    Parent* parent = 0;
    std::size_t ndx_in_parent = 0;
    table->init(ref, parent, ndx_in_parent); // Throws
    return table.release()->get_table_ref();
}

inline TableRef Table::copy(Allocator& alloc) const
{
    util::UniquePtr<Table> table(new Table(ref_count_tag(), alloc)); // Throws
    ref_type ref = clone(alloc); // Throws
    Parent* parent = 0;
    std::size_t ndx_in_parent = 0;
    table->init(ref, parent, ndx_in_parent); // Throws
    return table.release()->get_table_ref();
}

// For use by queries
template<class T> inline Columns<T> Table::column(std::size_t column)
{
    std::vector<size_t> tmp = m_link_chain;
    if (util::SameType<T, Link>::value || util::SameType<T, LinkList>::value) {
        tmp.push_back(column);
    }
    m_link_chain.clear();
    return Columns<T>(column, this, tmp);
}

// For use by queries
inline Table& Table::link(size_t link_column)
{
    m_link_chain.push_back(link_column);
    return *this;
}

inline bool Table::is_empty() const TIGHTDB_NOEXCEPT
{
    return m_size == 0;
}

inline std::size_t Table::size() const TIGHTDB_NOEXCEPT
{
    return m_size;
}

inline Table::RowExpr Table::get(std::size_t row_ndx) TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(row_ndx < size());
    return RowExpr(this, row_ndx);
}

inline Table::ConstRowExpr Table::get(std::size_t row_ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(row_ndx < size());
    return ConstRowExpr(this, row_ndx);
}

inline Table::RowExpr Table::front() TIGHTDB_NOEXCEPT
{
    return get(0);
}

inline Table::ConstRowExpr Table::front() const TIGHTDB_NOEXCEPT
{
    return get(0);
}

inline Table::RowExpr Table::back() TIGHTDB_NOEXCEPT
{
    return get(m_size-1);
}

inline Table::ConstRowExpr Table::back() const TIGHTDB_NOEXCEPT
{
    return get(m_size-1);
}

inline Table::RowExpr Table::operator[](std::size_t row_ndx) TIGHTDB_NOEXCEPT
{
    return get(row_ndx);
}

inline Table::ConstRowExpr Table::operator[](std::size_t row_ndx) const TIGHTDB_NOEXCEPT
{
    return get(row_ndx);
}

inline std::size_t Table::add_empty_row(std::size_t num_rows)
{
    std::size_t row_ndx = m_size;
    insert_empty_row(row_ndx, num_rows); // Throws
    return row_ndx; // Return index of first new row
}

inline const Table* Table::get_subtable_ptr(std::size_t col_ndx, std::size_t row_ndx) const
{
    return const_cast<Table*>(this)->get_subtable_ptr(col_ndx, row_ndx); // Throws
}

inline void Table::insert_bool(std::size_t column_ndx, std::size_t row_ndx, bool value)
{
    insert_int(column_ndx, row_ndx, value);
}

inline void Table::insert_datetime(std::size_t column_ndx, std::size_t row_ndx, DateTime value)
{
    insert_int(column_ndx, row_ndx, value.get_datetime());
}

template<class E>
inline void Table::insert_enum(std::size_t column_ndx, std::size_t row_ndx, E value)
{
    insert_int(column_ndx, row_ndx, value);
}

inline void Table::insert_subtable(std::size_t col_ndx, std::size_t row_ndx)
{
    insert_subtable(col_ndx, row_ndx, 0); // Null stands for an empty table
}

inline ConstTableRef Table::get_link_target(std::size_t col_ndx) const TIGHTDB_NOEXCEPT
{
    return const_cast<Table*>(this)->get_link_target(col_ndx);
}

template<class E>
inline void Table::set_enum(std::size_t column_ndx, std::size_t row_ndx, E value)
{
    set_int(column_ndx, row_ndx, value);
    bump_version();
}

inline TableRef Table::get_subtable(std::size_t column_ndx, std::size_t row_ndx)
{
    return TableRef(get_subtable_ptr(column_ndx, row_ndx));
}

inline ConstTableRef Table::get_subtable(std::size_t column_ndx, std::size_t row_ndx) const
{
    return ConstTableRef(get_subtable_ptr(column_ndx, row_ndx));
}

inline ConstTableRef Table::get_parent_table(std::size_t* column_ndx_out) const TIGHTDB_NOEXCEPT
{
    return ConstTableRef(get_parent_table_ptr(column_ndx_out));
}

inline TableRef Table::get_parent_table(std::size_t* column_ndx_out) TIGHTDB_NOEXCEPT
{
    return TableRef(get_parent_table_ptr(column_ndx_out));
}

inline bool Table::is_group_level() const TIGHTDB_NOEXCEPT
{
    return bool(get_parent_group());
}

inline Table::RowExpr Table::find_pkey_int(int_fast64_t value)
{
    Table* table = 0;
    std::size_t row_ndx = do_find_pkey_int(value); // Throws
    if (row_ndx != tightdb::not_found)
        table = this;
    return RowExpr(table, row_ndx);
}

inline Table::ConstRowExpr Table::find_pkey_int(int_fast64_t value) const
{
    const Table* table = 0;
    std::size_t row_ndx = do_find_pkey_int(value); // Throws
    if (row_ndx != tightdb::not_found)
        table = this;
    return ConstRowExpr(table, row_ndx);
}

inline Table::RowExpr Table::find_pkey_string(StringData value)
{
    Table* table = 0;
    std::size_t row_ndx = do_find_pkey_string(value); // Throws
    if (row_ndx != tightdb::not_found)
        table = this;
    return RowExpr(table, row_ndx);
}

inline Table::ConstRowExpr Table::find_pkey_string(StringData value) const
{
    const Table* table = 0;
    std::size_t row_ndx = do_find_pkey_string(value); // Throws
    if (row_ndx != tightdb::not_found)
        table = this;
    return ConstRowExpr(table, row_ndx);
}

inline bool Table::operator==(const Table& t) const
{
    return m_spec == t.m_spec && compare_rows(t); // Throws
}

inline bool Table::operator!=(const Table& t) const
{
    return !(*this == t); // Throws
}

inline bool Table::is_degenerate() const TIGHTDB_NOEXCEPT
{
    return !m_columns.is_attached();
}

inline void Table::insert_into(Table* parent, std::size_t col_ndx, std::size_t row_ndx) const
{
    parent->insert_subtable(col_ndx, row_ndx, this);
}

inline void Table::set_into_mixed(Table* parent, std::size_t col_ndx, std::size_t row_ndx) const
{
    parent->insert_mixed_subtable(col_ndx, row_ndx, this);
}

inline std::size_t Table::get_size_from_ref(ref_type top_ref, Allocator& alloc) TIGHTDB_NOEXCEPT
{
    const char* top_header = alloc.translate(top_ref);
    std::pair<int_least64_t, int_least64_t> p = Array::get_two(top_header, 0);
    ref_type spec_ref = to_ref(p.first), columns_ref = to_ref(p.second);
    return get_size_from_ref(spec_ref, columns_ref, alloc);
}

inline Table* Table::get_parent_table_ptr(std::size_t* column_ndx_out) TIGHTDB_NOEXCEPT
{
    const Table* parent = const_cast<const Table*>(this)->get_parent_table_ptr(column_ndx_out);
    return const_cast<Table*>(parent);
}

inline bool Table::is_link_type(ColumnType col_type) TIGHTDB_NOEXCEPT
{
    return col_type == col_type_Link || col_type == col_type_LinkList;
}

inline std::size_t* Table::record_subtable_path(std::size_t* begin,
                                                std::size_t* end) const TIGHTDB_NOEXCEPT
{
    const Array& real_top = m_top.is_attached() ? m_top : m_columns;
    std::size_t index_in_parent = real_top.get_ndx_in_parent();
    TIGHTDB_ASSERT(begin < end);
    *begin++ = index_in_parent;
    ArrayParent* parent = real_top.get_parent();
    TIGHTDB_ASSERT(parent);
    TIGHTDB_ASSERT(dynamic_cast<Parent*>(parent));
    return static_cast<Parent*>(parent)->record_subtable_path(begin, end);
}

inline std::size_t* Table::Parent::record_subtable_path(std::size_t* begin,
                                                        std::size_t*) TIGHTDB_NOEXCEPT
{
    return begin;
}

template<class T>
typename T::RowAccessor Table::get_link_accessor(std::size_t column_ndx, std::size_t row_ndx)
{
    size_t row_pos_in_target = get_link(column_ndx, row_ndx);
    TableRef target_table = get_link_target(column_ndx);

    Table* table = &*target_table;
    T* typed_table = (T*)(table);
    return (*typed_table)[row_pos_in_target];
}

inline bool Table::is_marked() const TIGHTDB_NOEXCEPT
{
    return m_mark;
}

inline void Table::mark() TIGHTDB_NOEXCEPT
{
    m_mark = true;
}

inline void Table::unmark() TIGHTDB_NOEXCEPT
{
    m_mark = false;
}

#ifdef TIGHTDB_ENABLE_REPLICATION
inline Replication* Table::get_repl() TIGHTDB_NOEXCEPT
{
    return m_top.get_alloc().get_replication();
}
#endif

inline void Table::set_ndx_in_parent(std::size_t ndx_in_parent) TIGHTDB_NOEXCEPT
{
    if (m_top.is_attached()) {
        // Root table (independent descriptor)
        m_top.set_ndx_in_parent(ndx_in_parent);
    }
    else {
        // Subtable with shared descriptor
        m_columns.set_ndx_in_parent(ndx_in_parent);
    }
}


// The purpose of this class is to give internal access to some, but
// not all of the non-public parts of the Table class.
class _impl::TableFriend {
public:
    typedef Table::UnbindGuard UnbindGuard;

    static ref_type create_empty_table(Allocator& alloc)
    {
        return Table::create_empty_table(alloc); // Throws
    }

    static ref_type clone(const Table& table, Allocator& alloc)
    {
        return table.clone(alloc); // Throws
    }

    static ref_type clone_columns(const Table& table, Allocator& alloc)
    {
        return table.clone_columns(alloc); // Throws
    }

    static Table* create_accessor(Allocator& alloc, ref_type top_ref,
                                  Table::Parent* parent, std::size_t ndx_in_parent)
    {
        util::UniquePtr<Table> table(new Table(Table::ref_count_tag(), alloc)); // Throws
        table->init(top_ref, parent, ndx_in_parent); // Throws
        return table.release();
    }

    static Table* create_accessor(ConstSubspecRef shared_spec, Table::Parent* parent_column,
                                  std::size_t parent_row_ndx)
    {
        Allocator& alloc = shared_spec.get_alloc();
        util::UniquePtr<Table> table(new Table(Table::ref_count_tag(), alloc)); // Throws
        table->init(shared_spec, parent_column, parent_row_ndx); // Throws
        return table.release();
    }

    // Intended to be used only by Group::create_table_accessor()
    static Table* create_incomplete_accessor(Allocator& alloc, ref_type top_ref,
                                             Table::Parent* parent, std::size_t ndx_in_parent)
    {
        util::UniquePtr<Table> table(new Table(Table::ref_count_tag(), alloc)); // Throws
        bool skip_create_column_accessors = true;
        table->init(top_ref, parent, ndx_in_parent, skip_create_column_accessors); // Throws
        return table.release();
    }

    // Intended to be used only by Group::create_table_accessor()
    static void complete_accessor(Table& table)
    {
        table.refresh_column_accessors(); // Throws
    }

    static void set_top_parent(Table& table, ArrayParent* parent,
                               std::size_t ndx_in_parent) TIGHTDB_NOEXCEPT
    {
        table.m_top.set_parent(parent, ndx_in_parent);
    }

    static void update_from_parent(Table& table, std::size_t old_baseline) TIGHTDB_NOEXCEPT
    {
        table.update_from_parent(old_baseline);
    }

    static void detach(Table& table) TIGHTDB_NOEXCEPT
    {
        table.detach();
    }

    static void discard_row_accessors(Table& table) TIGHTDB_NOEXCEPT
    {
        table.discard_row_accessors();
    }

    static void discard_child_accessors(Table& table) TIGHTDB_NOEXCEPT
    {
        table.discard_child_accessors();
    }

    static void discard_subtable_accessor(Table& table, std::size_t col_ndx, std::size_t row_ndx)
        TIGHTDB_NOEXCEPT
    {
        table.discard_subtable_accessor(col_ndx, row_ndx);
    }

    static void bind_ref(Table& table) TIGHTDB_NOEXCEPT
    {
        table.bind_ref();
    }

    static void unbind_ref(Table& table) TIGHTDB_NOEXCEPT
    {
        table.unbind_ref();
    }

    static bool compare_rows(const Table& a, const Table& b)
    {
        return a.compare_rows(b); // Throws
    }

    static std::size_t get_size_from_ref(ref_type ref, Allocator& alloc) TIGHTDB_NOEXCEPT
    {
        return Table::get_size_from_ref(ref, alloc);
    }

    static std::size_t get_size_from_ref(ref_type spec_ref, ref_type columns_ref,
                                         Allocator& alloc) TIGHTDB_NOEXCEPT
    {
        return Table::get_size_from_ref(spec_ref, columns_ref, alloc);
    }

    static Spec& get_spec(Table& table) TIGHTDB_NOEXCEPT
    {
        return table.m_spec;
    }

    static const Spec& get_spec(const Table& table) TIGHTDB_NOEXCEPT
    {
        return table.m_spec;
    }

    static ColumnBase& get_column(const Table& table, std::size_t col_ndx)
    {
        return *table.m_cols[col_ndx];
    }

    static std::size_t* record_subtable_path(const Table& table, std::size_t* begin,
                                             std::size_t* end) TIGHTDB_NOEXCEPT
    {
        return table.record_subtable_path(begin, end);
    }

    static void insert_column(Descriptor& desc, std::size_t column_ndx, DataType type,
                              StringData name, Table* link_target_table)
    {
        Table::do_insert_column(desc, column_ndx, type, name, link_target_table); // Throws
    }

    static void erase_column(Descriptor& desc, std::size_t column_ndx)
    {
        Table::do_erase_column(desc, column_ndx); // Throws
    }

    static void rename_column(Descriptor& desc, std::size_t column_ndx, StringData name)
    {
        Table::do_rename_column(desc, column_ndx, name); // Throws
    }

    static void clear_root_table_desc(const Table& root_table) TIGHTDB_NOEXCEPT
    {
        TIGHTDB_ASSERT(!root_table.has_shared_type());
        root_table.m_descriptor = 0;
    }

    static Table* get_subtable_accessor(Table& table, std::size_t col_ndx,
                                        std::size_t row_ndx) TIGHTDB_NOEXCEPT
    {
        return table.get_subtable_accessor(col_ndx, row_ndx);
    }

    static const Table* get_link_target_table_accessor(const Table& table,
                                                       std::size_t col_ndx) TIGHTDB_NOEXCEPT
    {
        return const_cast<Table&>(table).get_link_target_table_accessor(col_ndx);
    }

    static Table* get_link_target_table_accessor(Table& table, std::size_t col_ndx) TIGHTDB_NOEXCEPT
    {
        return table.get_link_target_table_accessor(col_ndx);
    }

    static void adj_accessors_insert_rows(Table& table, std::size_t row_ndx,
                                          std::size_t num_rows) TIGHTDB_NOEXCEPT
    {
        table.adj_accessors_insert_rows(row_ndx, num_rows);
    }

    static void adj_accessors_erase_row(Table& table, std::size_t row_ndx) TIGHTDB_NOEXCEPT
    {
        table.adj_accessors_erase_row(row_ndx);
    }

    static void adj_accessors_move(Table& table, std::size_t target_row_ndx,
                                   std::size_t source_row_ndx) TIGHTDB_NOEXCEPT
    {
        table.adj_accessors_move(target_row_ndx, source_row_ndx);
    }

    static void adj_acc_clear_root_table(Table& table) TIGHTDB_NOEXCEPT
    {
        table.adj_acc_clear_root_table();
    }

    static void adj_acc_clear_nonroot_table(Table& table) TIGHTDB_NOEXCEPT
    {
        table.adj_acc_clear_nonroot_table();
    }

    static void adj_insert_column(Table& table, std::size_t col_ndx)
    {
        table.adj_insert_column(col_ndx); // Throws
    }

    static void adj_add_column(Table& table)
    {
        std::size_t num_cols = table.m_cols.size();
        table.adj_insert_column(num_cols); // Throws
    }

    static void adj_erase_column(Table& table, std::size_t col_ndx) TIGHTDB_NOEXCEPT
    {
        table.adj_erase_column(col_ndx);
    }

    static bool is_marked(const Table& table) TIGHTDB_NOEXCEPT
    {
        return table.is_marked();
    }

    static void mark(Table& table) TIGHTDB_NOEXCEPT
    {
        table.mark();
    }

    static void unmark(Table& table) TIGHTDB_NOEXCEPT
    {
        table.unmark();
    }

    static void recursive_mark(Table& table) TIGHTDB_NOEXCEPT
    {
        table.recursive_mark();
    }

    static void mark_link_target_tables(Table& table, std::size_t col_ndx_begin) TIGHTDB_NOEXCEPT
    {
        table.mark_link_target_tables(col_ndx_begin);
    }

    static void mark_opposite_link_tables(Table& table) TIGHTDB_NOEXCEPT
    {
        table.mark_opposite_link_tables();
    }

    static Descriptor* get_root_table_desc_accessor(Table& root_table) TIGHTDB_NOEXCEPT
    {
        return root_table.m_descriptor;
    }

    typedef Table::AccessorUpdater AccessorUpdater;
    static void update_accessors(Table& table, const std::size_t* col_path_begin,
                                 const std::size_t* col_path_end, AccessorUpdater& updatder)
    {
        table.update_accessors(col_path_begin, col_path_end, updatder); // Throws
    }

    static void refresh_accessor_tree(Table& table)
    {
        table.refresh_accessor_tree(); // Throws
    }

    static void set_ndx_in_parent(Table& table, std::size_t ndx_in_parent) TIGHTDB_NOEXCEPT
    {
        table.set_ndx_in_parent(ndx_in_parent);
    }

    static void set_shared_subspec_ndx_in_parent(Table& table, std::size_t spec_ndx_in_parent)
        TIGHTDB_NOEXCEPT
    {
        table.m_spec.set_ndx_in_parent(spec_ndx_in_parent);
    }

    static bool is_link_type(ColumnType type) TIGHTDB_NOEXCEPT
    {
        return Table::is_link_type(type);
    }

    static void bump_version(Table& table, bool bump_global = true) TIGHTDB_NOEXCEPT
    {
        table.bump_version(bump_global);
    }

    static bool is_cross_table_link_target(const Table& table)
    {
        return table.is_cross_table_link_target();
    }

#ifdef TIGHTDB_ENABLE_REPLICATION
    static Replication* get_repl(Table& table) TIGHTDB_NOEXCEPT
    {
        return table.get_repl();
    }
#endif
};


} // namespace tightdb

#endif // TIGHTDB_TABLE_HPP
