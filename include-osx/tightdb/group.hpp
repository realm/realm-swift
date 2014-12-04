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

#ifndef TIGHTDB_GROUP_HPP
#define TIGHTDB_GROUP_HPP

#include <string>
#include <vector>
#include <map>

#include <tightdb/util/features.h>
#include <tightdb/exceptions.hpp>
#include <tightdb/impl/output_stream.hpp>
#include <tightdb/table.hpp>
#include <tightdb/table_basic_fwd.hpp>
#include <tightdb/alloc_slab.hpp>

namespace tightdb {

class SharedGroup;
namespace _impl { class GroupFriend; }


/// A group is a collection of named tables.
///
/// Tables occur in the group in an unspecified order, but an order that
/// generally remains fixed. The order is guaranteed to remain fixed between two
/// points in time if no tables are added to, or removed from the group during
/// that time. When tables are added to, or removed from the group, the order
/// may change arbitrarily.
///
/// If `table` is a table accessor attached to a group-level table, and `group`
/// is a group accessor attached to the group, then the following is guaranteed,
/// even after a change in the table order:
///
/// \code{.cpp}
///
///     table == group.get_table(table.get_index_in_group())
///
/// \endcode
///
class Group: private Table::Parent {
public:
    /// Construct a free-standing group. This group instance will be
    /// in the attached state, but neither associated with a file, nor
    /// with an external memory buffer.
    Group();

    enum OpenMode {
        /// Open in read-only mode. Fail if the file does not already exist.
        mode_ReadOnly,
        /// Open in read/write mode. Create the file if it doesn't exist.
        mode_ReadWrite,
        /// Open in read/write mode. Fail if the file does not already exist.
        mode_ReadWriteNoCreate
    };

    /// Equivalent to calling open(const std::string&, OpenMode) on an
    /// unattached group accessor.
    explicit Group(const std::string& file, OpenMode = mode_ReadOnly);

    /// Equivalent to calling open(BinaryData, bool) on an unattached
    /// group accessor. Note that if this constructor throws, the
    /// ownership of the memory buffer will remain with the caller,
    /// regardless of whether \a take_ownership is set to `true` or
    /// `false`.
    explicit Group(BinaryData, bool take_ownership = true);

    struct unattached_tag {};

    /// Create a Group instance in its unattached state. It may then
    /// be attached to a database file later by calling one of the
    /// open() methods. You may test whether this instance is
    /// currently in its attached state by calling
    /// is_attached(). Calling any other method (except the
    /// destructor) while in the unattached state has undefined
    /// behavior.
    Group(unattached_tag) TIGHTDB_NOEXCEPT;

    ~Group() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    /// Attach this Group instance to the specified database file.
    ///
    /// By default, the specified file is opened in read-only mode
    /// (mode_ReadOnly). This allows opening a file even when the
    /// caller lacks permission to write to that file. The opened
    /// group may still be modified freely, but the changes cannot be
    /// written back to the same file using the commit() function. An
    /// attempt to do that, will cause an exception to be thrown. When
    /// opening in read-only mode, it is an error if the specified
    /// file does not already exist in the file system.
    ///
    /// Alternatively, the file can be opened in read/write mode
    /// (mode_ReadWrite). This allows use of the commit() function,
    /// but, of course, it also requires that the caller has
    /// permission to write to the specified file. When opening in
    /// read-write mode, an attempt to create the specified file will
    /// be made, if it does not already exist in the file system.
    ///
    /// In any case, if the file already exists, it must contain a
    /// valid TightDB database. In many cases invalidity will be
    /// detected and cause the InvalidDatabase exception to be thrown,
    /// but you should not rely on it.
    ///
    /// Note that changes made to the database via a Group instance
    /// are not automatically committed to the specified file. You
    /// may, however, at any time, explicitly commit your changes by
    /// calling the commit() method, provided that the specified
    /// open-mode is not mode_ReadOnly. Alternatively, you may call
    /// write() to write the entire database to a new file. Writing
    /// the database to a new file does not end, or in any other way
    /// change the association between the Group instance and the file
    /// that was specified in the call to open().
    ///
    /// A file that is passed to Group::open(), may not be modified by
    /// a third party until after the Group object is
    /// destroyed. Behavior is undefined if a file is modified by a
    /// third party while any Group object is associated with it.
    ///
    /// Calling open() on a Group instance that is already in the
    /// attached state has undefined behavior.
    ///
    /// Accessing a TightDB database file through manual construction
    /// of a Group object does not offer any level of thread safety or
    /// transaction safety. When any of those kinds of safety are a
    /// concern, consider using a SharedGroup instead. When accessing
    /// a database file in read/write mode through a manually
    /// constructed Group object, it is entirely the responsibility of
    /// the application that the file is not accessed in any way by a
    /// third party during the life-time of that group object. It is,
    /// on the other hand, safe to concurrently access a database file
    /// by multiple manually created Group objects, as long as all of
    /// them are opened in read-only mode, and there is no other party
    /// that modifies the file concurrently.
    ///
    /// Do not call this function on a group instance that is managed
    /// by a shared group. Doing so will result in undefined behavior.
    ///
    /// Even if this function throws, it may have the side-effect of
    /// creating the specified file, and the file may get left behind
    /// in an invalid state. Of course, this can only happen if
    /// read/write mode (mode_ReadWrite) was requested, and the file
    /// did not already exist.
    ///
    /// \param file File system path to a TightDB database file.
    ///
    /// \param mode Specifying a mode that is not mode_ReadOnly
    /// requires that the specified file can be opened in read/write
    /// mode. In general there is no reason to open a group in
    /// read/write mode unless you want to be able to call
    /// Group::commit().
    ///
    /// \throw util::File::AccessError If the file could not be
    /// opened. If the reason corresponds to one of the exception
    /// types that are derived from util::File::AccessError, the
    /// derived exception type is thrown. Note that InvalidDatabase is
    /// among these derived exception types.
    void open(const std::string& file, OpenMode mode = mode_ReadOnly);

    /// Attach this Group instance to the specified memory buffer.
    ///
    /// This is similar to constructing a group from a file except
    /// that in this case the database is assumed to be stored in the
    /// specified memory buffer.
    ///
    /// If \a take_ownership is `true`, you pass the ownership of the
    /// specified buffer to the group. In this case the buffer will
    /// eventually be freed using std::free(), so the buffer you pass,
    /// must have been allocated using std::malloc().
    ///
    /// On the other hand, if \a take_ownership is set to `false`, it
    /// is your responsibility to keep the memory buffer alive during
    /// the lifetime of the group, and in case the buffer needs to be
    /// deallocated afterwards, that is your responsibility too.
    ///
    /// If this function throws, the ownership of the memory buffer
    /// will remain with the caller, regardless of whether \a
    /// take_ownership is set to `true` or `false`.
    ///
    /// Calling open() on a Group instance that is already in the
    /// attached state has undefined behavior.
    ///
    /// Do not call this function on a group instance that is managed
    /// by a shared group. Doing so will result in undefined behavior.
    ///
    /// \throw InvalidDatabase If the specified buffer does not appear
    /// to contain a valid database.
    void open(BinaryData, bool take_ownership = true);

    /// A group may be created in the unattached state, and then later
    /// attached to a file with a call to open(). Calling any method
    /// other than open(), and is_attached() on an unattached instance
    /// results in undefined behavior.
    bool is_attached() const TIGHTDB_NOEXCEPT;

    /// Returns true if, and only if the number of tables in this
    /// group is zero.
    bool is_empty() const TIGHTDB_NOEXCEPT;

    /// Returns the number of tables in this group.
    std::size_t size() const;

    //@{

    /// has_table() returns true if, and only if this group contains a table
    /// with the specified name.
    ///
    /// find_table() returns the index of the first table in this group with the
    /// specified name, or `tightdb::not_found` if this group does not contain a
    /// table with the specified name.
    ///
    /// get_table_name() returns the name of table at the specified index.
    ///
    /// The versions of get_table(), that accepts a \a name argument, return the
    /// first table with the specified name, or null if no such table exists.
    ///
    /// add_table() adds a table with the specified name to this group. It
    /// throws TableNameInUse if \a require_unique_name is true and \a name
    /// clashes with the name of an existing table. If \a require_unique_name is
    /// false, it is possible to add more than one table with the same
    /// name. Whenever a table is added, the order of the preexisting tables may
    /// change arbitrarily, and the new table may not end up as the last one
    /// either. But know that you can always call Table::get_index_in_group() on
    /// the returned table accessor to find out at which index it ends up.
    ///
    /// remove_table() removes the specified table from this group. A table can
    /// be removed only when it is not the target of a link column of a
    /// different table. Whenever a table is removed, the order of the remaining
    /// tables may change arbitrarily.
    ///
    /// rename_table() changes the name of a preexisting table. If \a
    /// require_unique_name is false, it becomes possible to have more than one
    /// table with a given name in a single group.
    ///
    /// The template functions work exactly like their non-template namesakes
    /// except as follows: The template versions of get_table() and
    /// get_or_add_table() throw DescriptorMismatch if the dynamic type of the
    /// specified table does not match the statically specified custom table
    /// type. The template versions of add_table() and get_or_add_table() set
    /// the dynamic type (descriptor) to match the statically specified custom
    /// table type.
    ///
    /// \tparam T An instance of the BasicTable class template.
    ///
    /// \param index Index of table in this group.
    ///
    /// \param name Name of table. All strings are valid table names as long as
    /// they are valid UTF-8 encodings.
    ///
    /// \param new_name New name for preexisting table.
    ///
    /// \param require_unique_name When set to true (the default), it becomes
    /// impossible to add a table with a name that is already in use, or to
    /// rename a table to a name that is already in use.
    ///
    /// \param was_added When specified, the boolean variable is set to true if
    /// the table was added, and to false otherwise. If the function throws, the
    /// boolean variable retains its original value.
    ///
    /// \return get_table(), add_table(), and get_or_add_table() return a table
    /// accessor attached to the requested (or added) table. get_table() may
    /// return null.
    ///
    /// \throw DescriptorMismatch Thrown by get_table() and get_or_add_table()
    /// tf the dynamic table type does not match the statically specified custom
    /// table type (\a T).
    ///
    /// \throw NoSuchTable Thrown by remove_table() and rename_table() if there
    /// is no table with the specified \a name.
    ///
    /// \throw TableNameInUse Thrown by add_table() if \a require_unique_name is
    /// true and \a name clashes with the name of a preexisting table. Thrown by
    /// rename_table() if \a require_unique_name is true and \a new_name clashes
    /// with the name of a preexisting table.
    ///
    /// \throw CrossTableLinkTarget Thrown by remove_table() if the specified
    /// table is the target of a link column of a different table.

    bool has_table(StringData name) const TIGHTDB_NOEXCEPT;
    std::size_t find_table(StringData name) const TIGHTDB_NOEXCEPT;
    StringData get_table_name(std::size_t table_ndx) const;

    TableRef get_table(std::size_t index);
    ConstTableRef get_table(std::size_t index) const;

    TableRef get_table(StringData name);
    ConstTableRef get_table(StringData name) const;

    TableRef add_table(StringData name, bool require_unique_name = true);
    TableRef get_or_add_table(StringData name, bool* was_added = 0);

    template<class T> BasicTableRef<T> get_table(std::size_t index);
    template<class T> BasicTableRef<const T> get_table(std::size_t index) const;

    template<class T> BasicTableRef<T> get_table(StringData name);
    template<class T> BasicTableRef<const T> get_table(StringData name) const;

    template<class T> BasicTableRef<T> add_table(StringData name, bool require_unique_name = true);
    template<class T> BasicTableRef<T> get_or_add_table(StringData name, bool* was_added = 0);

    void remove_table(std::size_t index);
    void remove_table(StringData name);

    void rename_table(std::size_t index, StringData new_name, bool require_unique_name = true);
    void rename_table(StringData name, StringData new_name, bool require_unique_name = true);

    //@}

    // Serialization

    /// Write this database to the specified output stream.
    void write(std::ostream&) const;

    /// Write this database to a new file. It is an error to specify a
    /// file that already exists. This is to protect against
    /// overwriting a database file that is currently open, which
    /// would cause undefined behaviour.
    ///
    /// \param file A filesystem path.
    ///
    /// \throw util::File::AccessError If the file could not be
    /// opened. If the reason corresponds to one of the exception
    /// types that are derived from util::File::AccessError, the
    /// derived exception type is thrown. In particular,
    /// util::File::Exists will be thrown if the file exists already.
    void write(const std::string& file) const;

    /// Write this database to a memory buffer.
    ///
    /// Ownership of the returned buffer is transferred to the
    /// caller. The memory will have been allocated using
    /// std::malloc().
    BinaryData write_to_mem() const;

    /// Commit changes to the attached file. This requires that the
    /// attached file is opened in read/write mode.
    ///
    /// Calling this function on an unattached group, a free-standing
    /// group, a group whose attached file is opened in read-only
    /// mode, a group that is attached to a memory buffer, or a group
    /// that is managed by a shared group, is an error and will result
    /// in undefined behavior.
    ///
    /// Table accesors will remain valid across the commit. Note that
    /// this is not the case when working with proper transactions.
    void commit();

    // Conversion
    template<class S> void to_json(S& out, size_t link_depth = 0,
        std::map<std::string, std::string>* renames = null_ptr) const;
    void to_string(std::ostream& out) const;

    /// Compare two groups for equality. Two groups are equal if, and
    /// only if, they contain the same tables in the same order, that
    /// is, for each table T at index I in one of the groups, there is
    /// a table at index I in the other group that is equal to T.
    bool operator==(const Group&) const;

    /// Compare two groups for inequality. See operator==().
    bool operator!=(const Group& g) const { return !(*this == g); }

#ifdef TIGHTDB_DEBUG
    void Verify() const; // Uncapitalized 'verify' cannot be used due to conflict with macro in Obj-C
    void print() const;
    void print_free() const;
    MemStats stats();
    void enable_mem_diagnostics(bool enable = true) { m_alloc.enable_debug(enable); }
    void to_dot(std::ostream&) const;
    void to_dot() const; // To std::cerr (for GDB)
    void to_dot(const char* file_path) const;
#else
    void Verify() const {}
#endif

private:
    SlabAlloc m_alloc;

    // Underlying node structure. The third slot in m_top is the "logical file
    // size" and it is always present. The 7th slot is the "database version"
    // (a.k.a. the "transaction number") and is present only when
    // m_free_versions is present.
    Array m_top;
    Array m_tables;            // 2nd slot in m_top
    ArrayString m_table_names; // 1st slot in m_top
    Array m_free_positions;    // 4th slot in m_top (optional)
    Array m_free_lengths;      // 5th slot in m_top (optional)
    Array m_free_versions;     // 6th slot in m_top (optional)

    typedef std::vector<Table*> table_accessors;
    mutable table_accessors m_table_accessors;
    const bool m_is_shared;
    bool m_is_attached;

    struct shared_tag {};
    Group(shared_tag) TIGHTDB_NOEXCEPT;

    // FIXME: Implement a proper copy constructor (fairly trivial).
    Group(const Group&); // Disable copying

    void init_array_parents() TIGHTDB_NOEXCEPT;
    void detach() TIGHTDB_NOEXCEPT;
    void detach_but_retain_data() TIGHTDB_NOEXCEPT;
    void complete_detach() TIGHTDB_NOEXCEPT;

    /// Add free-space versioning nodes, if they do not already exist. Othewise,
    /// set the version to zero on all free space chunks. This must be done
    /// whenever the lock file is created or reinitialized.
    void reset_free_space_versions();

    void reattach_from_retained_data();
    bool may_reattach_if_same_version() const TIGHTDB_NOEXCEPT;

    /// Recursively update refs stored in all cached array
    /// accessors. This includes cached array accessors in any
    /// currently attached table accessors. This ensures that the
    /// group instance itself, as well as any attached table accessor
    /// that exists across Group::commit() will remain valid. This
    /// function is not appropriate for use in conjunction with
    /// commits via shared group.
    void update_refs(ref_type top_ref, std::size_t old_baseline) TIGHTDB_NOEXCEPT;

    /// Reinitialize group for a new read or write transaction.
    void init_for_transact(ref_type new_top_ref, std::size_t new_file_size);

    // Overriding method in ArrayParent
    void update_child_ref(std::size_t, ref_type) TIGHTDB_OVERRIDE;

    // Overriding method in ArrayParent
    ref_type get_child_ref(std::size_t) const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    // Overriding method in Table::Parent
    StringData get_child_name(std::size_t) const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    // Overriding method in Table::Parent
    void child_accessor_destroyed(Table*) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    // Overriding method in Table::Parent
    Group* get_parent_group() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    class TableWriter;
    class DefaultTableWriter;

    static void write(std::ostream&, TableWriter&);

    /// Create a new underlying node structure and attach this
    /// accessor instance to it
    void create(bool add_free_versions);

    /// Attach this accessor instance to a preexisting underlying node
    /// structure.
    void init_from_ref(ref_type top_ref) TIGHTDB_NOEXCEPT;

    typedef void (*DescSetter)(Table&);
    typedef bool (*DescMatcher)(const Spec&);

    Table* do_get_table(size_t table_ndx, DescMatcher desc_matcher);
    const Table* do_get_table(size_t table_ndx, DescMatcher desc_matcher) const;
    Table* do_get_table(StringData name, DescMatcher desc_matcher);
    const Table* do_get_table(StringData name, DescMatcher desc_matcher) const;
    Table* do_add_table(StringData name, DescSetter desc_setter, bool require_unique_name);
    Table* do_add_table(StringData name, DescSetter desc_setter);
    Table* do_get_or_add_table(StringData name, DescMatcher desc_matcher,
                               DescSetter desc_setter, bool* was_added);

    std::size_t create_table(StringData name); // Returns index of new table
    Table* create_table_accessor(std::size_t table_ndx);

    void detach_table_accessors() TIGHTDB_NOEXCEPT;

    void mark_all_table_accessors() TIGHTDB_NOEXCEPT;

#ifdef TIGHTDB_ENABLE_REPLICATION
    Replication* get_replication() const TIGHTDB_NOEXCEPT;
    void set_replication(Replication*) TIGHTDB_NOEXCEPT;
    class TransactAdvancer;
    class TransactReverser;
    void advance_transact(ref_type new_top_ref, std::size_t new_file_size,
                          const BinaryData* logs_begin, const BinaryData* logs_end);
    void reverse_transact(ref_type new_top_ref, const BinaryData& log);
    void refresh_dirty_accessors();
#endif

#ifdef TIGHTDB_DEBUG
    std::pair<ref_type, std::size_t>
    get_to_dot_parent(std::size_t ndx_in_parent) const TIGHTDB_OVERRIDE;
#endif

    friend class Table;
    friend class GroupWriter;
    friend class SharedGroup;
    friend class _impl::GroupFriend;
    friend class Replication;
    friend class TrivialReplication;
};





// Implementation

inline Group::Group():
    m_alloc(), // Throws
    m_top(m_alloc), m_tables(m_alloc), m_table_names(m_alloc), m_free_positions(m_alloc),
    m_free_lengths(m_alloc), m_free_versions(m_alloc), m_is_shared(false), m_is_attached(false)
{
    init_array_parents();
    m_alloc.attach_empty(); // Throws
    bool add_free_versions = false;
    create(add_free_versions); // Throws
}

inline Group::Group(const std::string& file, OpenMode mode):
    m_alloc(), // Throws
    m_top(m_alloc), m_tables(m_alloc), m_table_names(m_alloc), m_free_positions(m_alloc),
    m_free_lengths(m_alloc), m_free_versions(m_alloc), m_is_shared(false), m_is_attached(false)
{
    init_array_parents();
    open(file, mode); // Throws
}

inline Group::Group(BinaryData buffer, bool take_ownership):
    m_alloc(), // Throws
    m_top(m_alloc), m_tables(m_alloc), m_table_names(m_alloc), m_free_positions(m_alloc),
    m_free_lengths(m_alloc), m_free_versions(m_alloc), m_is_shared(false), m_is_attached(false)
{
    init_array_parents();
    open(buffer, take_ownership); // Throws
}

inline Group::Group(unattached_tag) TIGHTDB_NOEXCEPT:
    m_alloc(), // Throws
    m_top(m_alloc), m_tables(m_alloc), m_table_names(m_alloc), m_free_positions(m_alloc),
    m_free_lengths(m_alloc), m_free_versions(m_alloc), m_is_shared(false), m_is_attached(false)
{
    init_array_parents();
}

inline Group* Group::get_parent_group() TIGHTDB_NOEXCEPT
{
    return this;
}

inline Group::Group(shared_tag) TIGHTDB_NOEXCEPT:
    m_alloc(), // Throws
    m_top(m_alloc), m_tables(m_alloc), m_table_names(m_alloc), m_free_positions(m_alloc),
    m_free_lengths(m_alloc), m_free_versions(m_alloc), m_is_shared(true), m_is_attached(false)
{
    init_array_parents();
}

inline bool Group::is_attached() const TIGHTDB_NOEXCEPT
{
    return m_is_attached;
}

inline bool Group::is_empty() const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    return m_table_names.is_empty();
}

inline std::size_t Group::size() const
{
    TIGHTDB_ASSERT(is_attached());
    return m_table_names.size();
}

inline StringData Group::get_table_name(std::size_t table_ndx) const
{
    TIGHTDB_ASSERT(is_attached());
    if (table_ndx >= m_table_names.size())
        throw LogicError(LogicError::table_index_out_of_range);
    return m_table_names.get(table_ndx);
}

inline bool Group::has_table(StringData name) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    std::size_t ndx = m_table_names.find_first(name);
    return ndx != not_found;
}

inline std::size_t Group::find_table(StringData name) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    std::size_t ndx = m_table_names.find_first(name);
    return ndx;
}

inline TableRef Group::get_table(std::size_t table_ndx)
{
    TIGHTDB_ASSERT(is_attached());
    DescMatcher desc_matcher = 0; // Do not check descriptor
    Table* table = do_get_table(table_ndx, desc_matcher); // Throws
    return TableRef(table);
}

inline ConstTableRef Group::get_table(std::size_t table_ndx) const
{
    TIGHTDB_ASSERT(is_attached());
    DescMatcher desc_matcher = 0; // Do not check descriptor
    const Table* table = do_get_table(table_ndx, desc_matcher); // Throws
    return ConstTableRef(table);
}

inline TableRef Group::get_table(StringData name)
{
    TIGHTDB_ASSERT(is_attached());
    DescMatcher desc_matcher = 0; // Do not check descriptor
    Table* table = do_get_table(name, desc_matcher); // Throws
    return TableRef(table);
}

inline ConstTableRef Group::get_table(StringData name) const
{
    TIGHTDB_ASSERT(is_attached());
    DescMatcher desc_matcher = 0; // Do not check descriptor
    const Table* table = do_get_table(name, desc_matcher); // Throws
    return ConstTableRef(table);
}

inline TableRef Group::add_table(StringData name, bool require_unique_name)
{
    TIGHTDB_ASSERT(is_attached());
    DescSetter desc_setter = 0; // Do not add any columns
    Table* table = do_add_table(name, desc_setter, require_unique_name); // Throws
    return TableRef(table);
}

inline TableRef Group::get_or_add_table(StringData name, bool* was_added)
{
    TIGHTDB_ASSERT(is_attached());
    DescMatcher desc_matcher = 0; // Do not check descriptor
    DescSetter desc_setter = 0; // Do not add any columns
    Table* table = do_get_or_add_table(name, desc_matcher, desc_setter, was_added); // Throws
    return TableRef(table);
}

template<class T> inline BasicTableRef<T> Group::get_table(std::size_t table_ndx)
{
    TIGHTDB_STATIC_ASSERT(IsBasicTable<T>::value, "Invalid table type");
    TIGHTDB_ASSERT(is_attached());
    DescMatcher desc_matcher = &T::matches_dynamic_type;
    Table* table = do_get_table(table_ndx, desc_matcher); // Throws
    return BasicTableRef<T>(static_cast<T*>(table));
}

template<class T> inline BasicTableRef<const T> Group::get_table(std::size_t table_ndx) const
{
    TIGHTDB_STATIC_ASSERT(IsBasicTable<T>::value, "Invalid table type");
    TIGHTDB_ASSERT(is_attached());
    DescMatcher desc_matcher = &T::matches_dynamic_type;
    const Table* table = do_get_table(table_ndx, desc_matcher); // Throws
    return BasicTableRef<const T>(static_cast<const T*>(table));
}

template<class T> inline BasicTableRef<T> Group::get_table(StringData name)
{
    TIGHTDB_STATIC_ASSERT(IsBasicTable<T>::value, "Invalid table type");
    TIGHTDB_ASSERT(is_attached());
    DescMatcher desc_matcher = &T::matches_dynamic_type;
    Table* table = do_get_table(name, desc_matcher); // Throws
    return BasicTableRef<T>(static_cast<T*>(table));
}

template<class T> inline BasicTableRef<const T> Group::get_table(StringData name) const
{
    TIGHTDB_STATIC_ASSERT(IsBasicTable<T>::value, "Invalid table type");
    TIGHTDB_ASSERT(is_attached());
    DescMatcher desc_matcher = &T::matches_dynamic_type;
    const Table* table = do_get_table(name, desc_matcher); // Throws
    return BasicTableRef<const T>(static_cast<const T*>(table));
}

template<class T>
inline BasicTableRef<T> Group::add_table(StringData name, bool require_unique_name)
{
    TIGHTDB_STATIC_ASSERT(IsBasicTable<T>::value, "Invalid table type");
    TIGHTDB_ASSERT(is_attached());
    DescSetter desc_setter = &T::set_dynamic_type;
    Table* table = do_add_table(name, desc_setter, require_unique_name); // Throws
    return BasicTableRef<T>(static_cast<T*>(table));
}

template<class T> inline BasicTableRef<T> Group::get_or_add_table(StringData name, bool* was_added)
{
    TIGHTDB_STATIC_ASSERT(IsBasicTable<T>::value, "Invalid table type");
    TIGHTDB_ASSERT(is_attached());
    DescMatcher desc_matcher = &T::matches_dynamic_type;
    DescSetter desc_setter = &T::set_dynamic_type;
    Table* table = do_get_or_add_table(name, desc_matcher, desc_setter, was_added); // Throws
    return BasicTableRef<T>(static_cast<T*>(table));
}

template<class S>
void Group::to_json(S& out, std::size_t link_depth,
                    std::map<std::string, std::string>* renames) const
{
    if (!is_attached()) {
        out << "{}";
        return;
    }

    std::map<std::string, std::string> renames2;
    renames = renames ? renames : &renames2;

    out << "{";

    for (std::size_t i = 0; i < m_tables.size(); ++i) {
        StringData name = m_table_names.get(i);
        std::map<std::string, std::string>& m = *renames;
        if (m[name] != "")
            name = m[name];

        ConstTableRef table = get_table(i);

        if (i)
            out << ",";
        out << "\"" << name << "\"";
        out << ":";
        table->to_json(out, link_depth, renames);
    }

    out << "}";
}

inline void Group::init_array_parents() TIGHTDB_NOEXCEPT
{
    m_table_names.set_parent(&m_top, 0);
    m_tables.set_parent(&m_top, 1);
    // Third slot is "logical file size"
    m_free_positions.set_parent(&m_top, 3);
    m_free_lengths.set_parent(&m_top, 4);
    m_free_versions.set_parent(&m_top, 5);
    // Seventh slot is "database version" (a.k.a. transaction number)
}

inline bool Group::may_reattach_if_same_version() const TIGHTDB_NOEXCEPT
{
    return m_top.is_attached();
}

inline void Group::update_child_ref(std::size_t child_ndx, ref_type new_ref)
{
    m_tables.set(child_ndx, new_ref);
}

inline ref_type Group::get_child_ref(std::size_t child_ndx) const TIGHTDB_NOEXCEPT
{
    return m_tables.get_as_ref(child_ndx);
}

inline StringData Group::get_child_name(std::size_t child_ndx) const TIGHTDB_NOEXCEPT
{
    return m_table_names.get(child_ndx);
}

inline void Group::child_accessor_destroyed(Table*) TIGHTDB_NOEXCEPT
{
    // Ignore
}

class Group::TableWriter {
public:
    virtual std::size_t write_names(_impl::OutputStream&) = 0;
    virtual std::size_t write_tables(_impl::OutputStream&) = 0;
    virtual ~TableWriter() TIGHTDB_NOEXCEPT {}
};

inline const Table* Group::do_get_table(size_t table_ndx, DescMatcher desc_matcher) const
{
    return const_cast<Group*>(this)->do_get_table(table_ndx, desc_matcher); // Throws
}

inline const Table* Group::do_get_table(StringData name, DescMatcher desc_matcher) const
{
    return const_cast<Group*>(this)->do_get_table(name, desc_matcher); // Throws
}

#ifdef TIGHTDB_ENABLE_REPLICATION

inline Replication* Group::get_replication() const TIGHTDB_NOEXCEPT
{
    return m_alloc.get_replication();
}

inline void Group::set_replication(Replication* repl) TIGHTDB_NOEXCEPT
{
    m_alloc.set_replication(repl);
}

#endif // TIGHTDB_ENABLE_REPLICATION

// The purpose of this class is to give internal access to some, but
// not all of the non-public parts of the Group class.
class _impl::GroupFriend {
public:
    static Table& get_table(Group& group, std::size_t ndx_in_group)
    {
        Group::DescMatcher desc_matcher = 0; // Do not check descriptor
        Table* table = group.do_get_table(ndx_in_group, desc_matcher); // Throws
        return *table;
    }

    static const Table& get_table(const Group& group, std::size_t ndx_in_group)
    {
        Group::DescMatcher desc_matcher = 0; // Do not check descriptor
        const Table* table = group.do_get_table(ndx_in_group, desc_matcher); // Throws
        return *table;
    }

    static Table* get_table(Group& group, StringData name)
    {
        Group::DescMatcher desc_matcher = 0; // Do not check descriptor
        Table* table = group.do_get_table(name, desc_matcher); // Throws
        return table;
    }

    static const Table* get_table(const Group& group, StringData name)
    {
        Group::DescMatcher desc_matcher = 0; // Do not check descriptor
        const Table* table = group.do_get_table(name, desc_matcher); // Throws
        return table;
    }

    static Table& add_table(Group& group, StringData name, bool require_unique_name)
    {
        Group::DescSetter desc_setter = 0; // Do not add any columns
        Table* table = group.do_add_table(name, desc_setter, require_unique_name); // Throws
        return *table;
    }

    static Table& get_or_add_table(Group& group, StringData name, bool* was_added)
    {
        Group::DescMatcher desc_matcher = 0; // Do not check descriptor
        Group::DescSetter desc_setter = 0; // Do not add any columns
        Table* table = group.do_get_or_add_table(name, desc_matcher, desc_setter,
                                                 was_added); // Throws
        return *table;
    }

#ifdef TIGHTDB_ENABLE_REPLICATION
    static Replication* get_replication(const Group& group) TIGHTDB_NOEXCEPT
    {
        return group.get_replication();
    }

    static void set_replication(Group& group, Replication* repl) TIGHTDB_NOEXCEPT
    {
        group.set_replication(repl);
    }
#endif // TIGHTDB_ENABLE_REPLICATION
};


} // namespace tightdb

#endif // TIGHTDB_GROUP_HPP
