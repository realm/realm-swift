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
#ifndef TIGHTDB_ALLOC_SLAB_HPP
#define TIGHTDB_ALLOC_SLAB_HPP

#include <stdint.h> // unint8_t etc
#include <vector>
#include <string>

#include <tightdb/util/features.h>
#include <tightdb/util/file.hpp>
#include <tightdb/alloc.hpp>

namespace tightdb {


// Pre-declarations
class Group;
class GroupWriter;


/// Thrown by Group and SharedGroup constructors if the specified file
/// (or memory buffer) does not appear to contain a valid TightDB
/// database.
struct InvalidDatabase: util::File::AccessError {
    InvalidDatabase(): util::File::AccessError("Invalid database") {}
};


/// The allocator that is used to manage the memory of a TightDB
/// group, i.e., a TightDB database.
///
/// Optionally, it can be attached to an pre-existing database (file
/// or memory buffer) which then becomes an immuatble part of the
/// managed memory.
///
/// To attach a slab allocator to a pre-existing database, call
/// attach_file() or attach_buffer(). To create a new database
/// in-memory, call attach_empty().
///
/// For efficiency, this allocator manages its mutable memory as a set
/// of slabs.
class SlabAlloc: public Allocator {
public:
    /// Construct a slab allocator in the unattached state.
    SlabAlloc();

    ~SlabAlloc() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

    /// Attach this allocator to the specified file.
    ///
    /// When used by free-standing Group instances, no concurrency is
    /// allowed. When used on behalf of SharedGroup, concurrency is
    /// allowed, but read_only and no_create must both be false in
    /// this case.
    ///
    /// It is an error to call this function on an attached
    /// allocator. Doing so will result in undefined behavor.
    ///
    /// \param is_shared Must be true if, and only if we are called on
    /// behalf of SharedGroup.
    ///
    /// \param read_only Open the file in read-only mode. This implies
    /// \a no_create.
    ///
    /// \param no_create Fail if the file does not already exist.
    ///
    /// \param bool skip_validate Skip validation of file header. In a
    /// set of overlapping SharedGroups, only the first one (the one
    /// that creates/initlializes the coordination file) may validate
    /// the header, otherwise it will result in a race condition.
    ///
    /// \return The `ref` of the root node, or zero if there is none.
    ///
    /// \throw util::File::AccessError
    ref_type attach_file(const std::string& path, bool is_shared, bool read_only, bool no_create,
                         bool skip_validate);

    /// Attach this allocator to the specified memory buffer.
    ///
    /// It is an error to call this function on an attached
    /// allocator. Doing so will result in undefined behavor.
    ///
    /// \return The `ref` of the root node, or zero if there is none.
    ///
    /// \sa own_buffer()
    ///
    /// \throw InvalidDatabase
    ref_type attach_buffer(char* data, std::size_t size);

    /// Attach this allocator to an empty buffer.
    ///
    /// It is an error to call this function on an attached
    /// allocator. Doing so will result in undefined behavor.
    void attach_empty();

    /// Detach from a previously attached file or buffer.
    ///
    /// This function does not reset free space tracking. To
    /// completely reset the allocator, you must also call
    /// reset_free_space_tracking().
    ///
    /// This function has no effect if the allocator is already in the
    /// detached state (idempotency).
    void detach() TIGHTDB_NOEXCEPT;

    class DetachGuard;

    /// If a memory buffer has been attached using attach_buffer(),
    /// mark it as owned by this slab allocator. Behaviour is
    /// undefined if this function is called on a detached allocator,
    /// one that is not attached using attach_buffer(), or one for
    /// which this function has already been called during the latest
    /// attachment.
    void own_buffer() TIGHTDB_NOEXCEPT;

    /// Returns true if, and only if this allocator is currently
    /// in the attached state.
    bool is_attached() const TIGHTDB_NOEXCEPT;

    /// Returns true if, and only if this allocator is currently in
    /// the attached state and attachment was not established using
    /// attach_empty().
    bool nonempty_attachment() const TIGHTDB_NOEXCEPT;

    /// Convert the attached file if the top-ref is not specified in
    /// the header, but in the footer, that is, if the file is on the
    /// streaming form. The streaming form is incompatible with
    /// in-place file modification.
    ///
    /// If validation was disabled at the time the file was attached,
    /// this function does nothing, as it assumes that the file is
    /// already prepared for update in that case.
    ///
    /// It is an error to call this function on an allocator that is
    /// not attached to a file. Doing so will result in undefined
    /// behavior.
    ///
    /// The caller must ensure that the file is not accessed
    /// concurrently by anyone else while this function executes.
    ///
    /// The specified address must be a writable memory mapping of the
    /// attached file, and the mapped region must be at least as big
    /// as what is returned by get_baseline().
    void prepare_for_update(char* mutable_data);

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
    /// It is an error to call this function on an allocator that is
    /// not attached to a file. Doing so will result in undefined
    /// behavior.
    void reserve(std::size_t size_in_bytes);

    /// Get the size of the attached database file or buffer in number
    /// of bytes. This size is not affected by new allocations. After
    /// attachment, it can only be modified by a call to remap().
    ///
    /// It is an error to call this function on a detached allocator,
    /// or one that was attached using attach_empty(). Doing so will
    /// result in undefined behavior.
    std::size_t get_baseline() const TIGHTDB_NOEXCEPT;

    /// Get the total amount of managed memory. This is the baseline plus the
    /// sum of the sizes of the allocated slabs. It includes any free space.
    ///
    /// It is an error to call this function on a detached
    /// allocator. Doing so will result in undefined behavior.
    std::size_t get_total_size() const TIGHTDB_NOEXCEPT;

    /// Mark all managed memory (except the attached file) as free
    /// space.
    void reset_free_space_tracking();

    /// Remap the attached file such that a prefix of the specified
    /// size becomes available in memory. If sucessfull,
    /// get_baseline() will return the specified new file size.
    ///
    /// It is an error to call this function on a detached allocator,
    /// or one that was not attached using attach_file(). Doing so
    /// will result in undefined behavior.
    ///
    /// \return True if, and only if the memory address of the first
    /// mapped byte has changed.
    bool remap(std::size_t file_size);

#ifdef TIGHTDB_DEBUG
    void enable_debug(bool enable) { m_debug_out = enable; }
    void Verify() const TIGHTDB_OVERRIDE;
    bool is_all_free() const;
    void print() const;
#endif

protected:
    MemRef do_alloc(std::size_t size) TIGHTDB_OVERRIDE;
    MemRef do_realloc(ref_type, const char*, std::size_t old_size,
                    std::size_t new_size) TIGHTDB_OVERRIDE;
    // FIXME: It would be very nice if we could detect an invalid free operation in debug mode
    void do_free(ref_type, const char*) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    char* do_translate(ref_type) const TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;

private:
    enum AttachMode {
        attach_None,        // Nothing is attached
        attach_OwnedBuffer, // We own the buffer (m_data = 0 for empty buffer)
        attach_UsersBuffer, // We do not own the buffer
        attach_SharedFile,  // On behalf of SharedGroup
        attach_UnsharedFile // Not on behalf of SharedGroup
    };

    // A slab is a dynamically allocated contiguous chunk of memory used to
    // extend the amount of space available for database node
    // storage. Inter-node references are represented as file offsets
    // (a.k.a. "refs"), and each slab creates an apparently seamless extension
    // of this file offset addressable space. Slabes are stored as rows in the
    // Slabs table in order of ascending file offsets.
    struct Slab {
        ref_type ref_end;
        char* addr;
    };
    struct Chunk {
        ref_type ref;
        size_t size;
    };

    // 24 bytes
    struct Header {
        uint64_t m_top_ref[2]; // 2 * 8 bytes
        // Info-block 8-bytes
        uint8_t m_mnemonic[4]; // "T-DB"
        uint8_t m_file_format_version[2];
        uint8_t m_reserved;
        uint8_t m_select_bit;
    };

    // 16 bytes
    struct StreamingFooter {
        uint64_t m_top_ref;
        uint64_t m_magic_cookie;
    };

    TIGHTDB_STATIC_ASSERT(sizeof (Header) == 24, "Bad header size");
    TIGHTDB_STATIC_ASSERT(sizeof (StreamingFooter) == 16, "Bad footer size");

    static const Header empty_file_header;
    static const Header streaming_header;

    static const uint_fast64_t footer_magic_cookie = 0x3034125237E526C8ULL;

    util::File m_file;
    char* m_data;
    AttachMode m_attach_mode;

    /// If a file or buffer is currently attached and validation was
    /// not skipped during attachement, this flag is true if, and only
    /// if the attached file has a footer specifying the top-ref, that
    /// is, if the file is on the streaming form. This member is
    /// deliberately placed here (after m_attach_mode) in the hope
    /// that it leads to less padding between members due to alignment
    /// requirements.
    bool m_file_on_streaming_form;

    enum FeeeSpaceState {
        free_space_Clean,
        free_space_Dirty,
        free_space_Invalid
    };

    /// When set to free_space_Invalid, the free lists are no longer
    /// up-to-date. This happens if do_free() or
    /// reset_free_space_tracking() fails, presumably due to
    /// std::bad_alloc being thrown during updating of the free space
    /// list. In this this case, alloc(), realloc_(), and
    /// get_free_read_only() must throw. This member is deliberately
    /// placed here (after m_attach_mode) in the hope that it leads to
    /// less padding between members due to alignment requirements.
    FeeeSpaceState m_free_space_state;

    typedef std::vector<Slab> slabs;
    typedef std::vector<Chunk> chunks;
    slabs m_slabs;
    chunks m_free_space;
    chunks m_free_read_only;

#ifdef TIGHTDB_DEBUG
    bool m_debug_out;
#endif

    /// Throws if free-lists are no longer valid.
    const chunks& get_free_read_only() const;

    bool validate_buffer(const char* data, std::size_t len, ref_type& top_ref);

    void do_prepare_for_update(char* mutable_data);

    class ChunkRefEq;
    class ChunkRefEndEq;
    class SlabRefEndEq;
    static bool ref_less_than_slab_ref_end(ref_type, const Slab&) TIGHTDB_NOEXCEPT;

#ifdef TIGHTDB_ENABLE_REPLICATION
    Replication* get_replication() const TIGHTDB_NOEXCEPT { return m_replication; }
    void set_replication(Replication* r) TIGHTDB_NOEXCEPT { m_replication = r; }
#endif

    friend class Group;
    friend class GroupWriter;
};


class SlabAlloc::DetachGuard {
public:
    DetachGuard(SlabAlloc& alloc) TIGHTDB_NOEXCEPT: m_alloc(&alloc) {}
    ~DetachGuard() TIGHTDB_NOEXCEPT;
    SlabAlloc* release() TIGHTDB_NOEXCEPT;
private:
    SlabAlloc* m_alloc;
};





// Implementation:

inline SlabAlloc::SlabAlloc():
    m_attach_mode(attach_None),
    m_free_space_state(free_space_Clean)
{
    m_baseline = 0; // Unattached
#ifdef TIGHTDB_DEBUG
    m_debug_out = false;
#endif
}

inline void SlabAlloc::own_buffer() TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(m_attach_mode == attach_UsersBuffer);
    TIGHTDB_ASSERT(m_data);
    TIGHTDB_ASSERT(!m_file.is_attached());
    m_attach_mode = attach_OwnedBuffer;
}

inline bool SlabAlloc::is_attached() const TIGHTDB_NOEXCEPT
{
    return m_attach_mode != attach_None;
}

inline bool SlabAlloc::nonempty_attachment() const TIGHTDB_NOEXCEPT
{
    return is_attached() && m_data;
}

inline std::size_t SlabAlloc::get_baseline() const TIGHTDB_NOEXCEPT
{
    TIGHTDB_ASSERT(is_attached());
    return m_baseline;
}

inline void SlabAlloc::prepare_for_update(char* mutable_data)
{
    TIGHTDB_ASSERT(m_attach_mode == attach_SharedFile || m_attach_mode == attach_UnsharedFile);
    if (TIGHTDB_LIKELY(!m_file_on_streaming_form))
        return;
    do_prepare_for_update(mutable_data);
}

inline void SlabAlloc::reserve(std::size_t size)
{
    m_file.prealloc_if_supported(0, size);
}

inline SlabAlloc::DetachGuard::~DetachGuard() TIGHTDB_NOEXCEPT
{
    if (m_alloc)
        m_alloc->detach();
}

inline SlabAlloc* SlabAlloc::DetachGuard::release() TIGHTDB_NOEXCEPT
{
    SlabAlloc* alloc = m_alloc;
    m_alloc = 0;
    return alloc;
}

inline bool SlabAlloc::ref_less_than_slab_ref_end(ref_type ref, const Slab& slab) TIGHTDB_NOEXCEPT
{
    return ref < slab.ref_end;
}

} // namespace tightdb

#endif // TIGHTDB_ALLOC_SLAB_HPP
