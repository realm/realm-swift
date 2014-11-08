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
#ifndef TIGHTDB_DESCRIPTOR_HPP
#define TIGHTDB_DESCRIPTOR_HPP

#include <cstddef>

#include <tightdb/util/assert.hpp>
#include <tightdb/descriptor_fwd.hpp>
#include <tightdb/table.hpp>


namespace tightdb {

namespace _impl { class DescriptorFriend; }


/// Accessor for table type descriptors.
///
/// A table type descriptor is an entity that specifies the dynamic
/// type of a TightDB table. Objects of this class are accessors
/// through which the descriptor can be inspected and
/// changed. Accessors can become detached, see is_attached() for more
/// on this. The descriptor itself is stored inside the database file,
/// or elsewhere in case of a free-standing table or a table in a
/// free-stading group.
///
/// The dynamic type consists first, and foremost of an ordered list
/// of column descriptors. Each column descriptor specifies the name
/// and type of the column.
///
/// When a table has a subtable column, every cell in than column
/// contains a subtable. All those subtables have the same dynamic
/// type, and therefore have a shared descriptor. See is_root() for
/// more on this.
///
/// The Table class contains convenience methods, such as
/// Table::get_column_count() and Table::add_column(), that allow you
/// to inspect and change the dynamic type of simple tables without
/// resorting to use of descriptors. For example, the following two
/// statements have the same effect:
///
///     table->add_column(type, name);
///     table->get_descriptor()->add_column(type, name);
///
/// Note, however, that this equivalence holds only as long as no
/// shared subtable descriptors are involved.
///
/// \sa Table::get_descriptor()
class Descriptor {
public:
    /// Get the number of columns in the associated tables.
    std::size_t get_column_count() const TIGHTDB_NOEXCEPT;

    /// Get the type of the column at the specified index.
    ///
    /// The consequences of specifying a column index that is out of
    /// range, are undefined.
    DataType get_column_type(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;

    /// Get the name of the column at the specified index.
    ///
    /// The consequences of specifying a column index that is out of
    /// range, are undefined.
    StringData get_column_name(std::size_t column_ndx) const TIGHTDB_NOEXCEPT;

    /// Search for a column with the specified name.
    ///
    /// This function finds the first column with the specified name,
    /// and returns its index. If there are no such columns, it
    /// returns `not_found`.
    std::size_t get_column_index(StringData name) const TIGHTDB_NOEXCEPT;

    /// Shorthand for calling insert_column() with a column index equal to the
    /// original number of columns. The returned value is that column index.
    ///
    /// \sa insert_column()
    /// \sa add_column_link()
    /// \sa Table::add_column()
    std::size_t add_column(DataType type, StringData name, DescriptorRef* subdesc = 0);

    /// Insert a new column into all the tables associated wiuth this
    /// descriptor. If any of the tables are not empty, the new column will be
    /// filled with the default value associated with the specified type. This
    /// function cannot be used to insert link-type columns. For that, you have
    /// to use insert_column_link() instead.
    ///
    /// This function modifies the dynamic type of all the tables that
    /// share this descriptor. It does this by inserting a new column
    /// with the specified name and type into the descriptor at the
    /// specified index, and into each of the tables that share this
    /// descriptor.
    ///
    /// \param subdesc If a non-null pointer is passed, and the
    /// specified type is `type_Table`, then this function
    /// automatically reteives the descriptor associated with the new
    /// subtable column, and stores a reference to its accessor in
    /// `*subdesc`.
    ///
    /// \sa is_root()
    /// \sa insert_column_link()
    /// \sa Table::insert_column()
    void insert_column(std::size_t column_ndx, DataType type, StringData name,
                       DescriptorRef* subdesc = 0);

    //@{
    /// Add link-type columns to group-level tables. It is not possible to add
    /// link-type columns to tables that are not group-level tables. These
    /// functions must be used in place of the ones without the `_link` suffix
    /// when the column type is `type_Link` or `type_LinkList`. A link-type
    /// column is associated with a particular target table. All links in a
    /// link-type column refer to rows in the target table of that column. The
    /// target table must also be a group-level table.
    std::size_t add_column_link(DataType type, StringData name, Table& target);
    void insert_column_link(std::size_t column_ndx, DataType type, StringData name, Table& target);
    //@}

    /// Remove the specified column from each of the associated
    /// tables. If the removed column is the only column in the
    /// descriptor, then the table size will drop to zero for all
    /// tables that were not already empty.
    ///
    /// This function modifies the dynamic type of all the tables that
    /// share this descriptor. It does this by removing the column at
    /// the specified index from the descriptor, and from each of the
    /// tables that share this descriptor. The consequences of
    /// specifying a column index that is out of range, are undefined.
    ///
    /// If the removed column was a subtable column, then the
    /// associated descriptor accessor will be detached, if it
    /// exists. This function will also detach all accessors of
    /// subtables of the root table. Only the accessor of the root
    /// table will remain attached. The root table is the table
    /// associated with the root descriptor.
    ///
    /// \sa is_root()
    /// \sa Table::remove_column()
    void remove_column(std::size_t column_ndx);

    /// Rename the specified column.
    ///
    /// This function modifies the dynamic type of all the tables that
    /// share this descriptor. The consequences of specifying a column
    /// index that is out of range, are undefined.
    ///
    /// This function will detach all accessors of subtables of the
    /// root table. Only the accessor of the root table will remain
    /// attached. The root table is the table associated with the root
    /// descriptor.
    ///
    /// \sa is_root()
    /// \sa Table::rename_column()
    void rename_column(std::size_t column_ndx, StringData new_name);

    //@{
    /// Get the descriptor for the specified subtable column.
    ///
    /// This function provides access to the shared subtable
    /// descriptor for the subtables in the specified column. The
    /// specified column must be a column whose type is 'table'. The
    /// consequences of specifying a column of a different type, or
    /// specifying an index that is out of range, are undefined.
    ///
    /// Note that this function cannot be used with 'mixed' columns,
    /// since subtables of that kind have independent dynamic types,
    /// and therefore, have independent descriptors. You can only get
    /// access to the descriptor of a subtable in a mixed column by
    /// first getting access to the subtable itself.
    ///
    /// \sa is_root()
    DescriptorRef get_subdescriptor(std::size_t column_ndx);
    ConstDescriptorRef get_subdescriptor(std::size_t column_ndx) const;
    //@}

    //@{
    /// Returns the parent table descriptor, if any.
    ///
    /// If this descriptor is the *root destriptor*, then this
    /// function returns null. Otherwise it returns the accessor of
    /// the parent descriptor.
    ///
    /// \sa is_root()
    DescriptorRef get_parent() TIGHTDB_NOEXCEPT;
    ConstDescriptorRef get_parent() const TIGHTDB_NOEXCEPT;
    //@}

    //@{
    /// Get the table associated with the root descriptor.
    ///
    /// \sa get_parent()
    /// \sa is_root()
    TableRef get_root_table() TIGHTDB_NOEXCEPT;
    ConstTableRef get_root_table() const TIGHTDB_NOEXCEPT;
    //@}

    /// Is this a root descriptor?
    ///
    /// Descriptors of tables with independent dynamic type are root
    /// destriptors. Root descriptors are never shared. Tables that
    /// are direct members of groups have independent dynamic
    /// types. The same is true for free-standing tables and subtables
    /// in columns of type 'mixed'.
    ///
    /// When a table has a column of type 'table', the cells in that
    /// column contain subtables. All those subtables have the same
    /// dynamic type, and they share a single dynamic type
    /// descriptor. Such shared descriptors are never root
    /// descriptors.
    ///
    /// A type descriptor can even be shared by subtables with
    /// different parent tables, but only if the parent tables
    /// themselves have a shared type descritpor. For examaple, if a
    /// table has a column `foo` of type 'table', and each of the
    /// subtables in `foo` havs a column `bar` of type 'table', then
    /// all the subtables in all the `bar` columns share the same
    /// dynamic type descriptor.
    ///
    /// \sa Table::has_shared_type()
    bool is_root() const TIGHTDB_NOEXCEPT;

    /// Determine whether this accessor is still attached.
    ///
    /// A table descriptor accesor may get detached from the
    /// underlying descriptor for various reasons (see below). When it
    /// does, it no longer refers to that descriptor, and can no
    /// longer be used, except for calling is_attached(). The
    /// consequences of calling other methods on a detached accessor
    /// are undefined. Descriptor accessors obtained by calling
    /// functions in the TightDB API are always in the 'attached'
    /// state immediately upon return from those functions.
    ///
    /// A descriptor accessor that is obtained directly from a table
    /// becomes detached if the table becomes detached. A shared
    /// subtable descriptor accessor that is obtained by a call to
    /// get_subdescriptor() becomes detached if the parent descriptor
    /// accessor becomes detached, or if the corresponding subtable
    /// column is removed. A descriptor accessor does not get detached
    /// under any other circumstances.
    bool is_attached() const TIGHTDB_NOEXCEPT;

    //@{
    /// Compare two table descriptors. Two descriptors are equal if,
    /// and only if they contain the same number of columns, and each
    /// corresponding pair of columns have the same name and type.
    ///
    /// The consequences of comparing a deatched descriptor are
    /// undefined.
    bool operator==(const Descriptor&) const TIGHTDB_NOEXCEPT;
    bool operator!=(const Descriptor&) const TIGHTDB_NOEXCEPT;
    //@}

    /// If the specified column is optimized to store only unique values, then
    /// this function returns the number of unique values currently
    /// stored. Otherwise it returns zero. This function is mainly intended for
    /// debugging purposes.
    std::size_t get_num_unique_values(std::size_t column_ndx) const;

    ~Descriptor() TIGHTDB_NOEXCEPT;


private:
    TableRef m_root_table; // Table associated with root descriptor. Detached iff null.
    DescriptorRef m_parent; // Null iff detached or root descriptor.
    Spec* m_spec; // Valid if attached. Owned iff valid and `m_parent`.

    mutable unsigned long m_ref_count;

    // Whenever a subtable descriptor accessor is created, it is
    // stored in this map. This ensures that when get_subdescriptor()
    // is called to created multiple DescriptorRef objects that
    // overlap in time, then they will all refer to the same
    // descriptor object.
    //
    // It also enables the necessary resursive detaching of descriptor
    // objects.
    struct subdesc_entry {
        std::size_t m_column_ndx;
        Descriptor* m_subdesc;
        subdesc_entry(std::size_t column_ndx, Descriptor*);
    };
    typedef std::vector<subdesc_entry> subdesc_map;
    mutable subdesc_map m_subdesc_map;

    Descriptor() TIGHTDB_NOEXCEPT;

    void bind_ref() const TIGHTDB_NOEXCEPT;
    void unbind_ref() const TIGHTDB_NOEXCEPT;

    // Called by the root table if this becomes the root
    // descriptor. Otherwise it is called by the descriptor that
    // becomes its parent.
    //
    // Puts this descriptor accessor into the attached state. This
    // attaches it to the underlying structure of array nodes. It does
    // not establish the parents reference to this descriptor, that is
    // the job of the parent. When this function returns,
    // is_attached() will return true.
    //
    // Not idempotent.
    //
    // The specified table is not allowed to be a subtable with a
    // shareable spec. That is, Table::has_shared_spec() must return
    // false.
    //
    // The specified spec must be the spec of the specified table or
    // of one of its direct or indirect subtable columns.
    //
    // When the specified spec is the spec of the root table, the
    // parent must be specified as null. When the specified spec is
    // not the root spec, a proper parent must be specified.
    void attach(Table*, Descriptor* parent, Spec*) TIGHTDB_NOEXCEPT;

    // Detach accessor from underlying descriptor. Caller must ensure
    // that a reference count exists upon return, for example by
    // obtaining an extra reference count before the call.
    //
    // This function is called either by the root table if this is the
    // root descriptor, or by the parent descriptor, if it is not.
    //
    // Puts this descriptor accessor into the detached state. This
    // detaches it from the underlying structure of array nodes. It
    // also calls detach_subdesc_accessors(). When this function
    // returns, is_attached() will return false.
    //
    // Not idempotent.
    void detach() TIGHTDB_NOEXCEPT;

    // Recursively detach all subtable descriptor accessors that
    // exist, that is, all subtable descriptor accessors that have
    // this descriptor as ancestor.
    void detach_subdesc_accessors() TIGHTDB_NOEXCEPT;

    // Remove the entry from m_subdesc_map that refers to the
    // specified subtable descriptor. It must be there.
    void remove_subdesc_entry(Descriptor* subdesc) const TIGHTDB_NOEXCEPT;

    // Record the path in terms of subtable column indexes from the
    // root descriptor to this descriptor. If this descriptor is a
    // root descriptor, the path is empty. Returns zero if the path is
    // too long to fit in the specified buffer. Otherwise the path
    // indexes will be stored between `begin_2`and `end`, where
    // `begin_2` is the returned pointer.
    std::size_t* record_subdesc_path(std::size_t* begin, std::size_t* end) const TIGHTDB_NOEXCEPT;

    // Returns a pointer to the accessor of the specified
    // subdescriptor if that accessor exists, otherwise this function
    // return null.
    Descriptor* get_subdesc_accessor(std::size_t column_ndx) TIGHTDB_NOEXCEPT;

    void adj_insert_column(std::size_t col_ndx) TIGHTDB_NOEXCEPT;
    void adj_erase_column(std::size_t col_ndx) TIGHTDB_NOEXCEPT;

    friend class util::bind_ptr<Descriptor>;
    friend class util::bind_ptr<const Descriptor>;
    friend class _impl::DescriptorFriend;
};




// Implementation:

inline std::size_t Descriptor::get_column_count() const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    return m_spec->get_public_column_count();
}

inline StringData Descriptor::get_column_name(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    return m_spec->get_column_name(ndx);
}

inline DataType Descriptor::get_column_type(std::size_t ndx) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    return m_spec->get_public_column_type(ndx);
}

inline std::size_t Descriptor::get_column_index(StringData name) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    return m_spec->get_column_index(name);
}

inline std::size_t Descriptor::add_column(DataType type, StringData name, DescriptorRef* subdesc)
{
    std::size_t column_ndx = m_spec->get_public_column_count();
    insert_column(column_ndx, type, name, subdesc); // Throws
    return column_ndx;
}

inline void Descriptor::insert_column(std::size_t column_ndx, DataType type, StringData name,
                                      DescriptorRef* subdesc)
{
    typedef _impl::TableFriend tf;
    TIGHTDB_ASSERT(is_attached());
    TIGHTDB_ASSERT(column_ndx <= get_column_count());
    TIGHTDB_ASSERT(!tf::is_link_type(ColumnType(type)));

    Table* link_target_table = 0;
    tf::insert_column(*this, column_ndx, type, name, link_target_table); // Throws
    adj_insert_column(column_ndx);
    if (subdesc && type == type_Table)
        *subdesc = get_subdescriptor(column_ndx);
}

inline std::size_t Descriptor::add_column_link(DataType type, StringData name, Table& target)
{
    std::size_t column_ndx = m_spec->get_public_column_count();
    insert_column_link(column_ndx, type, name, target); // Throws
    return column_ndx;
}

inline void Descriptor::insert_column_link(std::size_t column_ndx, DataType type, StringData name,
                                           Table& target)
{
    typedef _impl::TableFriend tf;
    TIGHTDB_ASSERT(is_attached());
    TIGHTDB_ASSERT(column_ndx <= get_column_count());
    TIGHTDB_ASSERT(tf::is_link_type(ColumnType(type)));
    // Both origin and target must be group-level tables
    TIGHTDB_ASSERT(is_root() && get_root_table()->is_group_level());
    TIGHTDB_ASSERT(target.is_group_level());

    tf::insert_column(*this, column_ndx, type, name, &target); // Throws
    adj_insert_column(column_ndx);
}

inline void Descriptor::remove_column(std::size_t column_ndx)
{
    typedef _impl::TableFriend tf;
    TIGHTDB_ASSERT(is_attached());
    tf::erase_column(*this, column_ndx); // Throws
    adj_erase_column(column_ndx);
}

inline void Descriptor::rename_column(std::size_t column_ndx, StringData name)
{
    typedef _impl::TableFriend tf;
    TIGHTDB_ASSERT(is_attached());
    tf::rename_column(*this, column_ndx, name); // Throws
}

inline ConstDescriptorRef Descriptor::get_subdescriptor(std::size_t column_ndx) const
{
    return const_cast<Descriptor*>(this)->get_subdescriptor(column_ndx);
}

inline DescriptorRef Descriptor::get_parent() TIGHTDB_NOEXCEPT
{
    return m_parent;
}

inline ConstDescriptorRef Descriptor::get_parent() const TIGHTDB_NOEXCEPT
{
    return const_cast<Descriptor*>(this)->get_parent();
}

inline TableRef Descriptor::get_root_table() TIGHTDB_NOEXCEPT
{
    return m_root_table;
}

inline ConstTableRef Descriptor::get_root_table() const TIGHTDB_NOEXCEPT
{
    return const_cast<Descriptor*>(this)->get_root_table();
}

inline bool Descriptor::is_root() const TIGHTDB_NOEXCEPT
{
    return !m_parent;
}

inline Descriptor::Descriptor() TIGHTDB_NOEXCEPT: m_ref_count(0)
{
}

inline void Descriptor::bind_ref() const TIGHTDB_NOEXCEPT
{
    ++m_ref_count;
}

inline void Descriptor::unbind_ref() const TIGHTDB_NOEXCEPT
{
    if (--m_ref_count == 0)
        delete this;
}

inline void Descriptor::attach(Table* table, Descriptor* parent, Spec* spec) TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(!is_attached());
    TIGHTDB_ASSERT(!table->has_shared_type());
    m_root_table.reset(table);
    m_parent.reset(parent);
    m_spec = spec;
}

inline bool Descriptor::is_attached() const TIGHTDB_NOEXCEPT
{
    return bool(m_root_table);
}

inline Descriptor::subdesc_entry::subdesc_entry(std::size_t n, Descriptor* d):
    m_column_ndx(n),
    m_subdesc(d)
{
}

inline bool Descriptor::operator==(const Descriptor& d) const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    TIGHTDB_ASSERT(d.is_attached());
    return *m_spec == *d.m_spec;
}

inline bool Descriptor::operator!=(const Descriptor& d) const TIGHTDB_NOEXCEPT
{
    return !(*this == d);
}

// The purpose of this class is to give internal access to some, but
// not all of the non-public parts of the Descriptor class.
class _impl::DescriptorFriend {
public:
    static Descriptor* create()
    {
        return new Descriptor; // Throws
    }

    static void attach(Descriptor& desc, Table* table, Descriptor* parent, Spec* spec)
        TIGHTDB_NOEXCEPT
    {
        desc.attach(table, parent, spec);
    }

    static void detach(Descriptor& desc) TIGHTDB_NOEXCEPT
    {
        desc.detach();
    }

    static Table& get_root_table(Descriptor& desc) TIGHTDB_NOEXCEPT
    {
        return *desc.m_root_table;
    }

    static const Table& get_root_table(const Descriptor& desc) TIGHTDB_NOEXCEPT
    {
        return *desc.m_root_table;
    }

    static Spec& get_spec(Descriptor& desc) TIGHTDB_NOEXCEPT
    {
        return *desc.m_spec;
    }

    static const Spec& get_spec(const Descriptor& desc) TIGHTDB_NOEXCEPT
    {
        return *desc.m_spec;
    }

    static std::size_t* record_subdesc_path(const Descriptor& desc, std::size_t* begin,
                                            std::size_t* end) TIGHTDB_NOEXCEPT
    {
        return desc.record_subdesc_path(begin, end);
    }

    static Descriptor* get_subdesc_accessor(Descriptor& desc, std::size_t column_ndx)
        TIGHTDB_NOEXCEPT
    {
        return desc.get_subdesc_accessor(column_ndx);
    }

    static void adj_insert_column(Descriptor& desc, std::size_t col_ndx) TIGHTDB_NOEXCEPT
    {
        desc.adj_insert_column(col_ndx);
    }

    static void adj_erase_column(Descriptor& desc, std::size_t col_ndx) TIGHTDB_NOEXCEPT
    {
        desc.adj_erase_column(col_ndx);
    }
};

} // namespace tightdb

#endif // TIGHTDB_DESCRIPTOR_HPP
