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
#ifndef TIGHTDB_GROUP_SHARED_HPP
#define TIGHTDB_GROUP_SHARED_HPP

#include <limits>

#include <tightdb/util/features.h>
#include <tightdb/group.hpp>
//#include <tightdb/commit_log.hpp>

namespace tightdb {

namespace _impl {
class WriteLogCollector;
}

/// A SharedGroup facilitates transactions.
///
/// When multiple threads or processes need to access a database
/// concurrently, they must do so using transactions. By design,
/// TightDB does not allow for multiple threads (or processes) to
/// share a single instance of SharedGroup. Instead, each concurrently
/// executing thread or process must use a separate instance of
/// SharedGroup.
///
/// Each instance of SharedGroup manages a single transaction at a
/// time. That transaction can be either a read transaction, or a
/// write transaction.
///
/// Utility classes ReadTransaction and WriteTransaction are provided
/// to make it safe and easy to work with transactions in a scoped
/// manner (by means of the RAII idiom). However, transactions can
/// also be explicitly started (begin_read(), begin_write()) and
/// stopped (end_read(), commit(), rollback()).
///
/// If a transaction is active when the SharedGroup is destroyed, that
/// transaction is implicitely terminated, either by a call to
/// end_read() or rollback().
///
/// Two processes that want to share a database file must reside on
/// the same host.
///
///
/// Desired exception behavior (not yet fully implemented)
/// ------------------------------------------------------
///
///  - If any data access API function throws an unexpcted exception during a
///    read transaction, the shared group accessor is left in state "error
///    during read".
///
///  - If any data access API function throws an unexpcted exception during a
///    write transaction, the shared group accessor is left in state "error
///    during write".
///
///  - If GroupShared::begin_write() or GroupShared::begin_read() throws an
///    unexpcted exception, the shared group accessor is left in state "no
///    transaction in progress".
///
///  - GroupShared::end_read() and GroupShared::rollback() do not throw.
///
///  - If GroupShared::commit() throws an unexpcted exception, the shared group
///    accessor is left in state "error during write" and the transaction was
///    not comitted.
///
///  - If GroupShared::advance_read() or GroupShared::promote_to_write() throws
///    an unexpcted exception, the shared group accessor is left in state "error
///    during read".
///
///  - If GroupShared::commit_and_continue_as_read() or
///    GroupShared::rollback_and_continue_as_read() throws an unexpcted
///    exception, the shared group accessor is left in state "error during
///    write".
///
/// It has not yet been decided exactly what an "unexpected exception" is, but
/// `std::bad_alloc` is surely one example. On the other hand, an expected
/// exception is one that is mentioned in the function specific documentation,
/// and is used to abort an operation due to a special, but expected condition.
///
/// States
/// ------
///
///  - A newly created shared group accessor is in state "no transaction in
///    progress".
///
///  - In state "error during read", almost all TightDB API functions are
///    illegal on the connected group of accessors. The only valid operations
///    are destruction of the shared group, and GroupShared::end_read(). If
///    GroupShared::end_read() is called, the new state becomes "no transaction
///    in progress".
///
///  - In state "error during write", almost all TightDB API functions are
///    illegal on the connected group of accessors. The only valid operations
///    are destruction of the shared group, and GroupShared::rollback(). If
///    GroupShared::end_write() is called, the new state becomes "no transaction
///    in progress"
class SharedGroup {
public:
    enum DurabilityLevel {
        durability_Full,
        durability_MemOnly
#ifndef _WIN32
        // Async commits are not yet supported on windows
        , durability_Async
#endif
    };

    /// Equivalent to calling open(const std::string&, bool,
    /// DurabilityLevel) on a default constructed instance.
    explicit SharedGroup(const std::string& file, bool no_create = false,
                         DurabilityLevel dlevel = durability_Full);

    struct unattached_tag {};

    /// Create a SharedGroup instance in its unattached state. It may
    /// then be attached to a database file later by calling
    /// open(). You may test whether this instance is currently in its
    /// attached state by calling is_attached(). Calling any other
    /// function (except the destructor) while in the unattached state
    /// has undefined behavior.
    SharedGroup(unattached_tag) TIGHTDB_NOEXCEPT;

    ~SharedGroup() TIGHTDB_NOEXCEPT;

    /// Attach this SharedGroup instance to the specified database
    /// file.
    ///
    /// If the database file does not already exist, it will be
    /// created (unless \a no_create is set to true.) When multiple
    /// threads are involved, it is safe to let the first thread, that
    /// gets to it, create the file.
    ///
    /// While at least one instance of SharedGroup exists for a
    /// specific database file, a "lock" file will be present too. The
    /// lock file will be placed in the same directory as the database
    /// file, and its name will be derived by appending ".lock" to the
    /// name of the database file.
    ///
    /// When multiple SharedGroup instances refer to the same file,
    /// they must specify the same durability level, otherwise an
    /// exception will be thrown.
    ///
    /// Calling open() on a SharedGroup instance that is already in
    /// the attached state has undefined behavior.
    ///
    /// \param file Filesystem path to a TightDB database file.
    ///
    /// \throw util::File::AccessError If the file could not be
    /// opened. If the reason corresponds to one of the exception
    /// types that are derived from util::File::AccessError, the
    /// derived exception type is thrown. Note that InvalidDatabase is
    /// among these derived exception types.
    void open(const std::string& file, bool no_create = false,
              DurabilityLevel dlevel = durability_Full,
              bool is_backend = false);

#ifdef TIGHTDB_ENABLE_REPLICATION

    /// Equivalent to calling open(Replication&) on a
    /// default constructed instance.
    explicit SharedGroup(Replication& repl,
                         DurabilityLevel dlevel = durability_Full);

    /// Open this group in replication mode. The specified Replication
    /// instance must remain in exixtence for as long as the
    /// SharedGroup.
    void open(Replication&, DurabilityLevel dlevel = durability_Full);

    friend class Replication;

#endif

    /// A SharedGroup may be created in the unattached state, and then
    /// later attached to a file with a call to open(). Calling any
    /// function other than open(), is_attached(), and ~SharedGroup()
    /// on an unattached instance results in undefined behavior.
    bool is_attached() const TIGHTDB_NOEXCEPT;

    /// Reserve disk space now to avoid allocation errors at a later
    /// point in time, and to minimize on-disk fragmentation. In some
    /// cases, less fragmentation translates into improved
    /// performance.
    ///
    /// When supported by the system, a call to this function will
    /// make the database file at least as big as the specified size,
    /// and cause space on the target device to be allocated (note
    /// that on many systems on-disk allocation is done lazily by
    /// default). If the file is already bigger than the specified
    /// size, the size will be unchanged, and on-disk allocation will
    /// occur only for the initial section that corresponds to the
    /// specified size. On systems that do not support preallocation,
    /// this function has no effect. To know whether preallocation is
    /// supported by TightDB on your platform, call
    /// util::File::is_prealloc_supported().
    ///
    /// It is an error to call this function on an unattached shared
    /// group. Doing so will result in undefined behavior.
    void reserve(std::size_t size_in_bytes);

    // Has db been modified since last transaction?
    bool has_changed();

    // Transactions:

    // Begin a new read transaction. Accessors obtained prior to this point
    // are invalid (if they weren't already) and new accessors must be
    // obtained from the group returned.
    const Group& begin_read();

    // End a read transaction. Accessors are detached.
    void end_read() TIGHTDB_NOEXCEPT;

    // Begin a new write transaction. Accessors obtained prior to this point
    // are invalid (if they weren't already) and new accessors must be
    // obtained from the group returned. It is illegal to call begin_write
    // inside an active transaction.
    Group& begin_write();

    // End the current write transaction. All accessors are detached.
    void commit();

    // End the current write transaction. All accessors are detached.
    void rollback() TIGHTDB_NOEXCEPT;

    // Pinned transactions:

    // Shared group can work with either pinned or unpinned read transactions.
    // - With unpinned read transactions, each new read transaction will refer
    //   to the latest database state.
    // - With pinned read transactions, each new read transaction will refer
    //   to the database state as it was, when pin_read_transactions() was called,
    //   ignoring further changes until shared group is either unpinned or
    //   pinned again to a new state.
    // Default is to use unpinned read transactions.
    //
    // You can only pin read transactions. You must unpin before starting a
    // write transaction.
    //
    // Note that a write transaction can proceed via one SharedGroup, while
    // read transactions are pinned via another SharedGroup that is attached
    // to the same database. It is important to understand that each such
    // write transaction will allocate resources (memory and/or disk), which
    // will not be freed until the pinning is ended. For this reason, one should
    // be careful to avoid long lived pinnings on databases that also see many
    // write transactions.

    // Pin subsequent read transactions to the current state. It is illegal
    // to use pin_read_transactions() while a transaction is in progress. Returns true,
    // if transactions are pinned to a new version of the database, false
    // if there are no changes.
    bool pin_read_transactions();

    // Unpin, i.e. allow subsequent read transactions to refer to whatever
    // is the current state when they are initiated. It is illegal to use
    // unpin_read_transactions() while a transaction is in progress.
    void unpin_read_transactions();

#ifdef TIGHTDB_DEBUG
    void test_ringbuf();
#endif

    /// If a stale .lock file is present when a SharedGroup is opened,
    /// an Exception of type PresumablyStaleLockFile will be thrown.
    /// The name of the stale lock file will be given as argument to the
    /// exception. Important: In a heavily loaded scenario a lock file
    /// may be considered stale, merely because the system is unresponsive
    /// for a long period of time. Depending on your knowledge of the
    /// system and its load, you must choose to either retry the operation
    /// or manually remove the stale lock file.
    class PresumablyStaleLockFile : public std::runtime_error {
    public:
        PresumablyStaleLockFile(const std::string& msg): std::runtime_error(msg) {}
    };

    // If the database file is deleted while there are open shared groups,
    // subsequent attempts to open shared groups will try to join an already
    // active sharing scheme, but fail due to the missing database file.
    // This causes the following exception to be thrown from Open or the constructor.
    class LockFileButNoData : public std::runtime_error {
    public:
        LockFileButNoData(const std::string& msg) : std::runtime_error(msg) {}
    };

private:
    struct SharedInfo;
    struct ReadLockInfo {
        uint_fast64_t   m_version;
        uint_fast32_t   m_reader_idx;
        ref_type        m_top_ref;
        size_t          m_file_size;
        ReadLockInfo() : m_version(std::numeric_limits<std::size_t>::max()), 
                         m_reader_idx(0), m_top_ref(0), m_file_size(0) {};
    };

    // Member variables
    Group      m_group;
    ReadLockInfo m_readlock;
    uint_fast32_t   m_local_max_entry;
    util::File m_file;
    util::File::Map<SharedInfo> m_file_map; // Never remapped
    util::File::Map<SharedInfo> m_reader_map;
    std::string m_file_path;
    enum TransactStage {
        transact_Ready,
        transact_Reading,
        transact_Writing
    };
    TransactStage m_transact_stage;
    bool m_transactions_are_pinned;
    struct ReadCount;

    // Ring buffer managment
    bool        ringbuf_is_empty() const TIGHTDB_NOEXCEPT;
    std::size_t ringbuf_size() const TIGHTDB_NOEXCEPT;
    std::size_t ringbuf_capacity() const TIGHTDB_NOEXCEPT;
    bool        ringbuf_is_first(std::size_t ndx) const TIGHTDB_NOEXCEPT;
    void        ringbuf_remove_first() TIGHTDB_NOEXCEPT;
    std::size_t ringbuf_find(uint64_t version) const TIGHTDB_NOEXCEPT;
    ReadCount&  ringbuf_get(std::size_t ndx) TIGHTDB_NOEXCEPT;
    ReadCount&  ringbuf_get_first() TIGHTDB_NOEXCEPT;
    ReadCount&  ringbuf_get_last() TIGHTDB_NOEXCEPT;
    void        ringbuf_put(const ReadCount& v);
    void        ringbuf_expand();

    // Grab the latest readlock and update readlock info. Compare latest against
    // current (before updating) and determine if the version is the same as before.
    // As a side effect update memory mapping to ensure that the ringbuffer entries
    // referenced in the readlock info is accessible.
    // The caller may provide an uninitialized readlock in which case same_as_before
    // is given an undefined value.
    void grab_latest_readlock(ReadLockInfo& readlock, bool& same_as_before);

    // Release a specific readlock. The readlock info MUST have been obtained by a
    // call to grab_latest_readlock().
    void release_readlock(ReadLockInfo& readlock) TIGHTDB_NOEXCEPT;

    void do_begin_write();
    void do_commit();

    // Must be called only by someone that has a lock on the write
    // mutex.
    uint_fast64_t get_current_version();

    // make sure the given index is within the currently mapped area.
    // if not, expand the mapped area. Returns true if the area is expanded.
    bool grow_reader_mapping(uint_fast32_t index);

    // Must be called only by someone that has a lock on the write
    // mutex.
    void low_level_commit(uint_fast64_t new_version);

    void do_async_commits();

#ifdef TIGHTDB_ENABLE_REPLICATION

    class TransactLogRegistry {
    public:
        /// Get all transaction logs between the specified versions. The number
        /// of requested logs is exactly `to_version - from_version`. If this
        /// number is greater than zero, the first requested log is the one that
        /// brings the database from `from_version` to `from_version +
        /// 1`. References to the requested logs are store in successive entries
        /// of `logs_buffer`. The calee retains ownership of the memory
        /// referenced by those entries.
        virtual void get_commit_entries(uint_fast64_t from_version, uint_fast64_t to_version,
                         BinaryData* logs_buffer) TIGHTDB_NOEXCEPT = 0;

        /// Declare no further interest in the transaction logs between the
        /// specified versions.
        virtual void release_commit_entries(uint_fast64_t to_version) TIGHTDB_NOEXCEPT = 0;
        virtual ~TransactLogRegistry() {}
    };

    // Advance the current read transaction to include latest state.
    // All accessors are retained and synchronized to the new state
    // according to the (to be) defined operational transform.
    void advance_read(TransactLogRegistry& write_logs);

    // Promote the current read transaction to a write transaction.
    // CAUTION: This also synchronizes with latest state of the database,
    // including synchronization of all accessors.
    // FIXME: A version of this which does NOT synchronize with latest
    // state will be made available later, once we are able to merge commits.
    void promote_to_write(TransactLogRegistry& write_logs);

    // End the current write transaction and transition atomically into
    // a read transaction, WITHOUT synchronizing to external changes
    // to data. All accessors are retained and continue to reflect the
    // state at commit.
    void commit_and_continue_as_read();

    // Abort the current write transaction, discarding all changes within it,
    // and thus restoring state to when promote_to_write() was last called.
    // Any accessors referring to the aborted state will be detached. Accessors
    // which was detached during the write transaction (for whatever reason)
    // are not restored but will remain detached.
    void rollback_and_continue_as_read();

    // called by WriteLogCollector to transfer the actual commit log for
    // accessor retention/update as part of rollback.
    void do_rollback_and_continue_as_read(const char* begin, const char* end);
#endif
    friend class ReadTransaction;
    friend class WriteTransaction;
    friend class LangBindHelper;
    friend class _impl::WriteLogCollector;
};


class ReadTransaction {
public:
    ReadTransaction(SharedGroup& sg):
        m_shared_group(sg)
    {
        m_shared_group.begin_read(); // Throws
    }

    ~ReadTransaction() TIGHTDB_NOEXCEPT
    {
        m_shared_group.end_read();
    }

    bool has_table(StringData name) const TIGHTDB_NOEXCEPT
    {
        return get_group().has_table(name);
    }

    ConstTableRef get_table(std::size_t table_ndx) const
    {
        return get_group().get_table(table_ndx); // Throws
    }

    ConstTableRef get_table(StringData name) const
    {
        return get_group().get_table(name); // Throws
    }

    template<class T> BasicTableRef<const T> get_table(StringData name) const
    {
        return get_group().get_table<T>(name); // Throws
    }

    const Group& get_group() const TIGHTDB_NOEXCEPT
    {
        return m_shared_group.m_group;
    }

private:
    SharedGroup& m_shared_group;
};


class WriteTransaction {
public:
    WriteTransaction(SharedGroup& sg):
        m_shared_group(&sg)
    {
        m_shared_group->begin_write(); // Throws
    }

    ~WriteTransaction() TIGHTDB_NOEXCEPT
    {
        if (m_shared_group)
            m_shared_group->rollback();
    }

    TableRef get_table(std::size_t table_ndx) const
    {
        return get_group().get_table(table_ndx); // Throws
    }

    TableRef get_table(StringData name) const
    {
        return get_group().get_table(name); // Throws
    }

    TableRef add_table(StringData name, bool require_unique_name = true) const
    {
        return get_group().add_table(name, require_unique_name); // Throws
    }

    TableRef get_or_add_table(StringData name, bool* was_added = 0) const
    {
        return get_group().get_or_add_table(name, was_added); // Throws
    }

    template<class T> BasicTableRef<T> get_table(StringData name) const
    {
        return get_group().get_table<T>(name); // Throws
    }

    template<class T>
    BasicTableRef<T> add_table(StringData name, bool require_unique_name = true) const
    {
        return get_group().add_table<T>(name, require_unique_name); // Throws
    }

    template<class T> BasicTableRef<T> get_or_add_table(StringData name, bool* was_added = 0) const
    {
        return get_group().get_or_add_table<T>(name, was_added); // Throws
    }

    Group& get_group() const TIGHTDB_NOEXCEPT
    {
        TIGHTDB_ASSERT(m_shared_group);
        return m_shared_group->m_group;
    }

    void commit()
    {
        TIGHTDB_ASSERT(m_shared_group);
        m_shared_group->commit();
        m_shared_group = 0;
    }

private:
    SharedGroup* m_shared_group;
};





// Implementation:

inline SharedGroup::SharedGroup(const std::string& file, bool no_create, DurabilityLevel dlevel):
    m_group(Group::shared_tag()),
    m_transactions_are_pinned(false)
{
    open(file, no_create, dlevel);
}

inline SharedGroup::SharedGroup(unattached_tag) TIGHTDB_NOEXCEPT:
    m_group(Group::shared_tag()),
    m_transactions_are_pinned(false)
{
}

inline bool SharedGroup::is_attached() const TIGHTDB_NOEXCEPT
{
    return m_file_map.is_attached();
}

#ifdef TIGHTDB_ENABLE_REPLICATION
inline SharedGroup::SharedGroup(Replication& repl, DurabilityLevel dlevel):
    m_group(Group::shared_tag()),
    m_transactions_are_pinned(false)
{
    open(repl, dlevel);
}
#endif


} // namespace tightdb

#endif // TIGHTDB_GROUP_SHARED_HPP
