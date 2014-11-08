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
#ifndef TIGHTDB_LANG_BIND_HELPER_HPP
#define TIGHTDB_LANG_BIND_HELPER_HPP

#include <cstddef>

#include <tightdb/table.hpp>
#include <tightdb/table_view.hpp>
#include <tightdb/link_view.hpp>
#include <tightdb/group.hpp>
#include <tightdb/group_shared.hpp>

namespace tightdb {


/// These functions are only to be used by language bindings to gain
/// access to certain memebers that are othewise private.
///
/// \note Applications are not supposed to call any of these functions
/// directly.
///
/// All of the get_subtable_ptr() functions bind the table accessor pointer
/// before it is returned (bind_table_ptr()). The caller is then responsible for
/// making the corresponding call to unbind_table_ptr().
class LangBindHelper {
public:
    /// Increment the reference counter of the specified table accessor. This is
    /// done automatically by all of the functions in this class that return
    /// table accessor pointers, but if the binding/application makes a copy of
    /// such a pointer, and the copy needs to have an "independent life", then
    /// the binding/application must bind that copy using this function.
    static void bind_table_ptr(const Table*) TIGHTDB_NOEXCEPT;

    /// Decrement the reference counter of the specified table accessor. The
    /// binding/application must call this function for every bound table
    /// accessor pointer object, when that pointer object ends its life.
    static void unbind_table_ptr(const Table*) TIGHTDB_NOEXCEPT;

    /// Construct a new freestanding table. The table accessor pointer is bound
    /// by the callee before it is returned (bind_table_ptr()).
    static Table* new_table();

    /// Construct a new freestanding table as a copy of the specified one. The
    /// table accessor pointer is bound by the callee before it is returned
    /// (bind_table_ptr()).
    static Table* copy_table(const Table&);

    //@{

    /// These functions are like their namesakes in Group, but these bypass the
    /// construction of a smart-pointer object (TableRef). The table accessor
    /// pointer is bound by the callee before it is returned (bind_table_ptr()).

    static Table* get_table(Group&, std::size_t index_in_group);
    static const Table* get_table(const Group&, std::size_t index_in_group);

    static Table* get_table(Group&, StringData name);
    static const Table* get_table(const Group&, StringData name);

    static Table* add_table(Group&, StringData name, bool require_unique_name = true);
    static Table* get_or_add_table(Group&, StringData name, bool* was_added = 0);

    //@}

    static Table* get_subtable_ptr(Table*, std::size_t column_ndx, std::size_t row_ndx);
    static const Table* get_subtable_ptr(const Table*, std::size_t column_ndx,
                                         std::size_t row_ndx);

    // FIXME: This is an 'oddball', do we really need it? If we do,
    // please provide a comment that explains why it is needed!
    static Table* get_subtable_ptr_during_insert(Table*, std::size_t col_ndx,
                                                 std::size_t row_ndx);

    static Table* get_subtable_ptr(TableView*, std::size_t column_ndx, std::size_t row_ndx);
    static const Table* get_subtable_ptr(const TableView*, std::size_t column_ndx,
                                         std::size_t row_ndx);
    static const Table* get_subtable_ptr(const ConstTableView*, std::size_t column_ndx,
                                         std::size_t row_ndx);

    /// Calls parent.insert_subtable(col_ndx, row_ndx, &source). Note
    /// that the source table must have a descriptor that is
    /// compatible with the target subtable column.
    static void insert_subtable(Table& parent, std::size_t col_ndx, std::size_t row_ndx,
                                const Table& source);


    /// Calls parent.insert_mixed_subtable(col_ndx, row_ndx, &source).
    static void insert_mixed_subtable(Table& parent, std::size_t col_ndx, std::size_t row_ndx,
                                      const Table& source);

    /// Calls parent.set_mixed_subtable(col_ndx, row_ndx, &source).
    static void set_mixed_subtable(Table& parent, std::size_t col_ndx, std::size_t row_ndx,
                                   const Table& source);

    static LinkView* get_linklist_ptr(Row&, std::size_t col_ndx);
    static void unbind_linklist_ptr(LinkView*);

#ifdef TIGHTDB_ENABLE_REPLICATION
    typedef SharedGroup::TransactLogRegistry TransactLogRegistry;

    /// Wrappers - forward calls to shared group. A bit like NSA. Circumventing privacy :-)
    static void advance_read(SharedGroup&, TransactLogRegistry& write_logs);
    static void promote_to_write(SharedGroup&, TransactLogRegistry& write_logs);
    static void commit_and_continue_as_read(SharedGroup&);
    static void rollback_and_continue_as_read(SharedGroup&);
#endif

    /// Returns the name of the specified data type as follows:
    ///
    /// <pre>
    ///
    ///   type_Int       ->  "int"
    ///   type_Bool      ->  "bool"
    ///   type_Float     ->  "float"
    ///   type_Double    ->  "double"
    ///   type_String    ->  "string"
    ///   type_Binary    ->  "binary"
    ///   type_DateTime  ->  "date"
    ///   type_Table     ->  "table"
    ///   type_Mixed     ->  "mixed"
    ///
    /// </pre>
    static const char* get_data_type_name(DataType) TIGHTDB_NOEXCEPT;
};




// Implementation:

inline Table* LangBindHelper::new_table()
{
    typedef _impl::TableFriend tf;
    Allocator& alloc = Allocator::get_default();
    std::size_t ref = tf::create_empty_table(alloc); // Throws
    Table::Parent* parent = 0;
    std::size_t ndx_in_parent = 0;
    Table* table = tf::create_accessor(alloc, ref, parent, ndx_in_parent); // Throws
    tf::bind_ref(*table);
    return table;
}

inline Table* LangBindHelper::copy_table(const Table& table)
{
    typedef _impl::TableFriend tf;
    Allocator& alloc = Allocator::get_default();
    std::size_t ref = tf::clone(table, alloc); // Throws
    Table::Parent* parent = 0;
    std::size_t ndx_in_parent = 0;
    Table* copy_of_table = tf::create_accessor(alloc, ref, parent, ndx_in_parent); // Throws
    tf::bind_ref(*copy_of_table);
    return copy_of_table;
}

inline Table* LangBindHelper::get_subtable_ptr(Table* t, std::size_t column_ndx,
                                               std::size_t row_ndx)
{
    Table* subtab = t->get_subtable_ptr(column_ndx, row_ndx); // Throws
    subtab->bind_ref();
    return subtab;
}

inline const Table* LangBindHelper::get_subtable_ptr(const Table* t, std::size_t column_ndx,
                                                     std::size_t row_ndx)
{
    const Table* subtab = t->get_subtable_ptr(column_ndx, row_ndx); // Throws
    subtab->bind_ref();
    return subtab;
}

inline Table* LangBindHelper::get_subtable_ptr(TableView* tv, std::size_t column_ndx,
                                               std::size_t row_ndx)
{
    return get_subtable_ptr(&tv->get_parent(), column_ndx, tv->get_source_ndx(row_ndx));
}

inline const Table* LangBindHelper::get_subtable_ptr(const TableView* tv, std::size_t column_ndx,
                                                     std::size_t row_ndx)
{
    return get_subtable_ptr(&tv->get_parent(), column_ndx, tv->get_source_ndx(row_ndx));
}

inline const Table* LangBindHelper::get_subtable_ptr(const ConstTableView* tv,
                                                     std::size_t column_ndx, std::size_t row_ndx)
{
    return get_subtable_ptr(&tv->get_parent(), column_ndx, tv->get_source_ndx(row_ndx));
}

inline Table* LangBindHelper::get_table(Group& group, std::size_t index_in_group)
{
    typedef _impl::GroupFriend gf;
    Table* table = &gf::get_table(group, index_in_group); // Throws
    table->bind_ref();
    return table;
}

inline const Table* LangBindHelper::get_table(const Group& group, std::size_t index_in_group)
{
    typedef _impl::GroupFriend gf;
    const Table* table = &gf::get_table(group, index_in_group); // Throws
    table->bind_ref();
    return table;
}

inline Table* LangBindHelper::get_table(Group& group, StringData name)
{
    typedef _impl::GroupFriend gf;
    Table* table = gf::get_table(group, name); // Throws
    if (table)
        table->bind_ref();
    return table;
}

inline const Table* LangBindHelper::get_table(const Group& group, StringData name)
{
    typedef _impl::GroupFriend gf;
    const Table* table = gf::get_table(group, name); // Throws
    if (table)
        table->bind_ref();
    return table;
}

inline Table* LangBindHelper::add_table(Group& group, StringData name, bool require_unique_name)
{
    typedef _impl::GroupFriend gf;
    Table* table = &gf::add_table(group, name, require_unique_name); // Throws
    table->bind_ref();
    return table;
}

inline Table* LangBindHelper::get_or_add_table(Group& group, StringData name, bool* was_added)
{
    typedef _impl::GroupFriend gf;
    Table* table = &gf::get_or_add_table(group, name, was_added); // Throws
    table->bind_ref();
    return table;
}

inline void LangBindHelper::unbind_table_ptr(const Table* t) TIGHTDB_NOEXCEPT
{
   t->unbind_ref();
}

inline void LangBindHelper::bind_table_ptr(const Table* t) TIGHTDB_NOEXCEPT
{
   t->bind_ref();
}

inline void LangBindHelper::insert_subtable(Table& parent, std::size_t col_ndx,
                                            std::size_t row_ndx, const Table& source)
{
    parent.insert_subtable(col_ndx, row_ndx, &source);
}


inline void LangBindHelper::insert_mixed_subtable(Table& parent, std::size_t col_ndx,
                                                  std::size_t row_ndx, const Table& source)
{
    parent.insert_mixed_subtable(col_ndx, row_ndx, &source);
}

inline void LangBindHelper::set_mixed_subtable(Table& parent, std::size_t col_ndx,
                                               std::size_t row_ndx, const Table& source)
{
    parent.set_mixed_subtable(col_ndx, row_ndx, &source);
}

inline LinkView* LangBindHelper::get_linklist_ptr(Row& row, std::size_t col_ndx)
{
    LinkViewRef link_view = row.get_linklist(col_ndx);
    link_view->bind_ref();
    return &*link_view;
}

inline void LangBindHelper::unbind_linklist_ptr(LinkView* link_view)
{
   link_view->unbind_ref();
}

#ifdef TIGHTDB_ENABLE_REPLICATION

inline void LangBindHelper::advance_read(SharedGroup& sg,
                                         TransactLogRegistry& log_registry)
{
    sg.advance_read(log_registry);
}

inline void LangBindHelper::promote_to_write(SharedGroup& sg,
                                             TransactLogRegistry& log_registry)
{
    sg.promote_to_write(log_registry);
}

inline void LangBindHelper::commit_and_continue_as_read(SharedGroup& sg)
{
    sg.commit_and_continue_as_read();
}

inline void LangBindHelper::rollback_and_continue_as_read(SharedGroup& sg)
{
    sg.rollback_and_continue_as_read();
}


#endif

} // namespace tightdb

#endif // TIGHTDB_LANG_BIND_HELPER_HPP
