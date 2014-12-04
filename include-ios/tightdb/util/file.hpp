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
#ifndef TIGHTDB_UTIL_FILE_HPP
#define TIGHTDB_UTIL_FILE_HPP

#include <cstddef>
#include <stdint.h>
#include <stdexcept>
#include <string>
#include <streambuf>

#include <tightdb/util/features.h>
#include <tightdb/util/assert.hpp>
#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/util/safe_int_ops.hpp>

namespace tightdb {
namespace util {


/// Create the specified directory in the file system.
///
/// \throw File::AccessError If the directory could not be created. If
/// the reason corresponds to one of the exception types that are
/// derived from File::AccessError, the derived exception type is
/// thrown (as long as the underlying system provides the information
/// to unambiguously distinguish that particular reason).
void make_dir(const std::string& path);

/// Remove the specified directory path from the file system. If the
/// specified path is a directory, this function is equivalent to
/// std::remove(const char*).
///
/// \throw File::AccessError If the directory could not be removed. If
/// the reason corresponds to one of the exception types that are
/// derived from File::AccessError, the derived exception type is
/// thrown (as long as the underlying system provides the information
/// to unambiguously distinguish that particular reason).
void remove_dir(const std::string& path);

/// Create a new unique directory for temporary files. The absolute
/// path to the new directory is returned without a trailing slash.
std::string make_temp_dir();


/// This class provides a RAII abstraction over the concept of a file
/// descriptor (or file handle).
///
/// Locks are automatically and immediately released when the File
/// instance is closed.
///
/// You can use CloseGuard and UnlockGuard to acheive exception-safe
/// closing or unlocking prior to the File instance being detroyed.
///
/// A single File instance must never be accessed concurrently by
/// multiple threads.
///
/// You can write to a file via an std::ostream as follows:
///
/// \code{.cpp}
///
///   File::Streambuf my_streambuf(&my_file);
///   std::ostream out(&my_strerambuf);
///   out << 7945.9;
///
/// \endcode
class File {
public:
    enum Mode {
        mode_Read,   ///< access_ReadOnly,  create_Never             (fopen: rb)
        mode_Update, ///< access_ReadWrite, create_Never             (fopen: rb+)
        mode_Write,  ///< access_ReadWrite, create_Auto, flag_Trunc  (fopen: wb+)
        mode_Append  ///< access_ReadWrite, create_Auto, flag_Append (fopen: ab+)
    };

    /// Equivalent to calling open(const std::string&, Mode) on a
    /// default constructed instance.
    explicit File(const std::string& path, Mode = mode_Read);

    /// Create an instance that is not initially attached to an open
    /// file.
    File() TIGHTDB_NOEXCEPT;

    ~File() TIGHTDB_NOEXCEPT;

    /// Calling this function on an instance that is already attached
    /// to an open file has undefined behavior.
    ///
    /// \throw AccessError If the file could not be opened. If the
    /// reason corresponds to one of the exception types that are
    /// derived from AccessError, the derived exception type is thrown
    /// (as long as the underlying system provides the information to
    /// unambiguously distinguish that particular reason).
    void open(const std::string& path, Mode = mode_Read);

    /// This function is idempotent, that is, it is valid to call it
    /// regardless of whether this instance currently is attached to
    /// an open file.
    void close() TIGHTDB_NOEXCEPT;

    /// Check whether this File instance is currently attached to an
    /// open file.
    bool is_attached() const TIGHTDB_NOEXCEPT;

    enum AccessMode {
        access_ReadOnly,
        access_ReadWrite
    };

    enum CreateMode {
        create_Auto,  ///< Create the file if it does not already exist.
        create_Never, ///< Fail if the file does not already exist.
        create_Must   ///< Fail if the file already exists.
    };

    enum {
        flag_Trunc  = 1, ///< Truncate the file if it already exists.
        flag_Append = 2  ///< Move to end of file before each write.
    };

    /// See open(const std::string&, Mode).
    ///
    /// Specifying access_ReadOnly together with a create mode that is
    /// not create_Never, or together with a non-zero \a flags
    /// argument, results in undefined behavior. Specifying flag_Trunc
    /// together with create_Must results in undefined behavior.
    void open(const std::string& path, AccessMode, CreateMode, int flags);

    /// Same as open(path, access_ReadWrite, create_Auto, 0), except
    /// that this one returns an indication of whether a new file was
    /// created, or an existing file was opened.
    void open(const std::string& path, bool& was_created);

    /// Read data into the specified buffer and return the number of
    /// bytes read. If the returned number of bytes is less than \a
    /// size, then the end of the file has been reached.
    ///
    /// Calling this function on an instance, that is not currently
    /// attached to an open file, has undefined behavior.
    std::size_t read(char* data, std::size_t size);

    /// Write the specified data to this file.
    ///
    /// Calling this function on an instance, that is not currently
    /// attached to an open file, has undefined behavior.
    ///
    /// Calling this function on an instance, that was opened in
    /// read-only mode, has undefined behavior.
    void write(const char* data, std::size_t size);

    /// Calls write(s.data(), s.size()).
    void write(const std::string& s) { write(s.data(), s.size()); }

    /// Calls read(data, N).
    template<std::size_t N> std::size_t read(char (&data)[N]) { return read(data, N); }

    /// Calls write(data(), N).
    template<std::size_t N> void write(const char (&data)[N]) { write(data, N); }

    /// Plays the same role as off_t in POSIX
    typedef int_fast64_t SizeType;

    /// Calling this function on an instance that is not attached to
    /// an open file has undefined behavior.
    SizeType get_size() const;

    /// If this causes the file to grow, then the new section will
    /// have undefined contents. Setting the size with this function
    /// does not necessarily allocate space on the target device. If
    /// you want to ensure allocation, call alloc(). Calling this
    /// function will generally affect the read/write offset
    /// associated with this File instance.
    ///
    /// Calling this function on an instance that is not attached to
    /// an open file has undefined behavior. Calling this function on
    /// a file that is opened in read-only mode, is an error.
    void resize(SizeType);

    /// The same as prealloc_if_supported() but when the operation is
    /// not supported by the system, this function will still increase
    /// the file size when the specified region extends beyond the
    /// current end of the file. This allows you to both extend and
    /// allocate in one operation.
    ///
    /// The downside is that this function is not guaranteed to have
    /// atomic behaviour on all systems, that is, two processes, or
    /// two threads should never call this function concurrently for
    /// the same underlying file even though they access the file
    /// through distinct File instances.
    ///
    /// \sa prealloc_if_supported()
    void prealloc(SizeType offset, std::size_t size);

    /// When supported by the system, allocate space on the target
    /// device for the specified region of the file. If the region
    /// extends beyond the current end of the file, the file size is
    /// increased as necessary.
    ///
    /// On systems that do not support this operation, this function
    /// has no effect. You may call is_prealloc_supported() to
    /// determine if it is supported on your system.
    ///
    /// Calling this function on an instance, that is not attached to
    /// an open file, has undefined behavior. Calling this function on
    /// a file, that is opened in read-only mode, is an error.
    ///
    /// This function is guaranteed to have atomic behaviour, that is,
    /// there is never any risk of the file size being reduced even
    /// with concurrently executing invocations.
    ///
    /// \sa prealloc()
    /// \sa is_prealloc_supported()
    void prealloc_if_supported(SizeType offset, std::size_t size);

    /// See prealloc_if_supported().
    static bool is_prealloc_supported();

    /// Reposition the read/write offset of this File
    /// instance. Distinct File instances have separate independent
    /// offsets, as long as the cucrrent process is not forked.
    void seek(SizeType);

    /// Flush in-kernel buffers to disk. This blocks the caller until
    /// the synchronization operation is complete.
    void sync();

    /// Place an exclusive lock on this file. This blocks the caller
    /// until all other locks have been released.
    ///
    /// Locks acquired on distinct File instances have fully recursive
    /// behavior, even if they are acquired in the same process (or
    /// thread) and are attached to the same underlying file.
    ///
    /// Calling this function on an instance that is not attached to
    /// an open file, or on an instance that is already locked has
    /// undefined behavior.
    void lock_exclusive();

    /// Place an shared lock on this file. This blocks the caller
    /// until all other exclusive locks have been released.
    ///
    /// Locks acquired on distinct File instances have fully recursive
    /// behavior, even if they are acquired in the same process (or
    /// thread) and are attached to the same underlying file.
    ///
    /// Calling this function on an instance that is not attached to
    /// an open file, or on an instance that is already locked has
    /// undefined behavior.
    void lock_shared();

    /// Non-blocking version of lock_exclusive(). Returns true iff it
    /// succeeds.
    bool try_lock_exclusive();

    /// Non-blocking version of lock_shared(). Returns true iff it
    /// succeeds.
    bool try_lock_shared();

    /// Release a previously acquired lock on this file. This function
    /// is idempotent.
    void unlock() TIGHTDB_NOEXCEPT;

    enum {
        /// If possible, disable opportunistic flushing of dirted
        /// pages of a memory mapped file to physical medium. On some
        /// systems this cannot be disabled. On other systems it is
        /// the default behavior. An explicit call to sync_map() will
        /// flush the buffers regardless of whether this flag is
        /// specified or not.
        map_NoSync = 1
    };

    /// Map this file into memory. The file is mapped as shared
    /// memory. This allows two processes to interact under exatly the
    /// same rules as applies to the interaction via regular memory of
    /// multiple threads inside a single process.
    ///
    /// This File instance does not need to remain in existence after
    /// the mapping is established.
    ///
    /// Multiple concurrent mappings may be created from the same File
    /// instance.
    ///
    /// Specifying access_ReadWrite for a file that is opened in
    /// read-only mode, is an error.
    ///
    /// Calling this function on an instance that is not attached to
    /// an open file, or one that is attached to an empty file has
    /// undefined behavior.
    ///
    /// Calling this function with a size that is greater than the
    /// size of the file has undefined behavior.
    void* map(AccessMode, std::size_t size, int map_flags = 0) const;

    /// The same as unmap(old_addr, old_size) followed by map(a,
    /// new_size, map_flags), but more efficient on some systems.
    ///
    /// The old address range must have been acquired by a call to
    /// map() or remap() on this File instance, the specified access
    /// mode and flags must be the same as the ones specified
    /// previously, and this File instance must not have been reopend
    /// in the meantime. Failing to adhere to these rules will result
    /// in undefined behavior.
    ///
    /// If this function throws, the old address range will remain
    /// mapped.
    void* remap(void* old_addr, std::size_t old_size, AccessMode a, std::size_t new_size,
                int map_flags = 0) const;

    /// Unmap the specified address range which must have been
    /// previously returned by map().
    static void unmap(void* addr, std::size_t size) TIGHTDB_NOEXCEPT;

    /// Flush in-kernel buffers to disk. This blocks the caller until
    /// the synchronization operation is complete. The specified
    /// address range must be one that was previously returned by
    /// map().
    static void sync_map(void* addr, std::size_t size);

    /// Check whether the specified file or directory exists. Note
    /// that a file or directory that resides in a directory that the
    /// calling process has no access to, will necessarily be reported
    /// as not existing.
    static bool exists(const std::string& path);

    /// Remove the specified file path from the file system. If the
    /// specified path is not a directory, this function is equivalent
    /// to std::remove(const char*).
    ///
    /// The specified file must not be open by the calling process. If
    /// it is, this function has undefined behaviour. Note that an
    /// open memory map of the file counts as "the file being open".
    ///
    /// \throw AccessError If the specified directory entry could not
    /// be removed. If the reason corresponds to one of the exception
    /// types that are derived from AccessError, the derived exception
    /// type is thrown (as long as the underlying system provides the
    /// information to unambiguously distinguish that particular
    /// reason).
    static void remove(const std::string& path);

    /// Same as remove() except that this one returns false, rather
    /// than thriowing an exception, if the specified file does not
    /// exist. If the file did exist, and was deleted, this function
    /// returns true.
    static bool try_remove(const std::string& path);

    /// Change the path of a directory entry. This can be used to
    /// rename a file, and/or to move it from one directory to
    /// another. This function is equivalent to std::rename(const
    /// char*, const char*).
    ///
    /// \throw AccessError If the path of the directory entry could
    /// not be changed. If the reason corresponds to one of the
    /// exception types that are derived from AccessError, the derived
    /// exception type is thrown (as long as the underlying system
    /// provides the information to unambiguously distinguish that
    /// particular reason).
    static void move(const std::string& old_path, const std::string& new_path);

    /// Check whether two open file descriptors refer to the same
    /// underlying file, that is, if writing via one of them, will
    /// affect what is read from the other. In UNIX this boils down to
    /// comparing inode numbers.
    ///
    /// Both instances have to be attached to open files. If they are
    /// not, this function has undefined behavior.
    bool is_same_file(const File&) const;

    // FIXME: Can we get rid of this one please!!!
    bool is_removed() const;

    class ExclusiveLock;
    class SharedLock;

    template<class> class Map;

    class CloseGuard;
    class UnlockGuard;
    class UnmapGuard;

    class Streambuf;

    /// Used for any I/O related exception. Note the derived exception
    /// types that are used for various specific types of errors.
    struct AccessError: std::runtime_error {
        AccessError(const std::string& msg): std::runtime_error(msg) {}
    };

    /// Thrown if the user does not have permission to open or create
    /// the specified file in the specified access mode.
    struct PermissionDenied: AccessError {
        PermissionDenied(const std::string& msg): AccessError(msg) {}
    };

    /// Thrown if the directory part of the specified path was not
    /// found, or create_Never was specified and the file did no
    /// exist.
    struct NotFound: AccessError {
        NotFound(const std::string& msg): AccessError(msg) {}
    };

    /// Thrown if create_Always was specified and the file did already
    /// exist.
    struct Exists: AccessError {
        Exists(const std::string& msg): AccessError(msg) {}
    };

private:
#ifdef _WIN32
    void* m_handle;
    bool m_have_lock; // Only valid when m_handle is not null
#else
    int m_fd;
#endif

    bool lock(bool exclusive, bool non_blocking);
    void open_internal(const std::string& path, AccessMode, CreateMode, int flags, bool* success);

    struct MapBase {
        void* m_addr;
        std::size_t m_size;

        MapBase() TIGHTDB_NOEXCEPT;
        ~MapBase() TIGHTDB_NOEXCEPT;

        void map(const File&, AccessMode, std::size_t size, int map_flags);
        void remap(const File&, AccessMode, std::size_t size, int map_flags);
        void unmap() TIGHTDB_NOEXCEPT;
        void sync();
    };
};



class File::ExclusiveLock {
public:
    ExclusiveLock(File& f): m_file(f) { f.lock_exclusive(); }
    ~ExclusiveLock() TIGHTDB_NOEXCEPT { m_file.unlock(); }
private:
    File& m_file;
};

class File::SharedLock {
public:
    SharedLock(File& f): m_file(f) { f.lock_shared(); }
    ~SharedLock() TIGHTDB_NOEXCEPT { m_file.unlock(); }
private:
    File& m_file;
};



/// This class provides a RAII abstraction over the concept of a
/// memory mapped file.
///
/// Once created, the Map instance makes no reference to the File
/// instance that it was based upon, and that File instance may be
/// destroyed before the Map instance is destroyed.
///
/// Multiple concurrent mappings may be created from the same File
/// instance.
///
/// You can use UnmapGuard to acheive exception-safe unmapping prior
/// to the Map instance being detroyed.
///
/// A single Map instance must never be accessed concurrently by
/// multiple threads.
template<class T> class File::Map: private MapBase {
public:
    /// Equivalent to calling map() on a default constructed instance.
    explicit Map(const File&, AccessMode = access_ReadOnly, std::size_t size = sizeof (T),
                 int map_flags = 0);

    /// Create an instance that is not initially attached to a memory
    /// mapped file.
    Map() TIGHTDB_NOEXCEPT;

    ~Map() TIGHTDB_NOEXCEPT;

    /// See File::map().
    ///
    /// Calling this function on a Map instance that is already
    /// attached to a memory mapped file has undefined behavior. The
    /// returned pointer is the same as what will subsequently be
    /// returned by get_addr().
    T* map(const File&, AccessMode = access_ReadOnly, std::size_t size = sizeof (T),
           int map_flags = 0);

    /// See File::unmap(). This function is idempotent, that is, it is
    /// valid to call it regardless of whether this instance is
    /// currently attached to a memory mapped file.
    void unmap() TIGHTDB_NOEXCEPT;

    /// See File::remap().
    ///
    /// Calling this function on a Map instance that is not currently
    /// attached to a memory mapped file has undefined behavior. The
    /// returned pointer is the same as what will subsequently be
    /// returned by get_addr().
    T* remap(const File&, AccessMode = access_ReadOnly, std::size_t size = sizeof (T),
             int map_flags = 0);

    /// See File::sync_map().
    ///
    /// Calling this function on an instance that is not currently
    /// attached to a memory mapped file, has undefined behavior.
    void sync();

    /// Check whether this Map instance is currently attached to a
    /// memory mapped file.
    bool is_attached() const TIGHTDB_NOEXCEPT;

    /// Returns a pointer to the beginning of the memory mapped file,
    /// or null if this instance is not currently attached.
    T* get_addr() const TIGHTDB_NOEXCEPT;

    /// Returns the size of the mapped region, or zero if this
    /// instance does not currently refer to a memory mapped
    /// file. When this instance refers to a memory mapped file, the
    /// returned value will always be identical to the size passed to
    /// the constructor or to map().
    std::size_t get_size() const TIGHTDB_NOEXCEPT;

    /// Release the currently attached memory mapped file from this
    /// Map instance. The address range may then be unmapped later by
    /// a call to File::unmap().
    T* release() TIGHTDB_NOEXCEPT;

    friend class UnmapGuard;
};


class File::CloseGuard {
public:
    CloseGuard(File& f) TIGHTDB_NOEXCEPT: m_file(&f) {}
    ~CloseGuard()  TIGHTDB_NOEXCEPT { if (m_file) m_file->close(); }
    void release() TIGHTDB_NOEXCEPT { m_file = 0; }
private:
    File* m_file;
};


class File::UnlockGuard {
public:
    UnlockGuard(File& f) TIGHTDB_NOEXCEPT: m_file(&f) {}
    ~UnlockGuard()  TIGHTDB_NOEXCEPT { if (m_file) m_file->unlock(); }
    void release() TIGHTDB_NOEXCEPT { m_file = 0; }
private:
    File* m_file;
};


class File::UnmapGuard {
public:
    template<class T> UnmapGuard(Map<T>& m) TIGHTDB_NOEXCEPT: m_map(&m) {}
    ~UnmapGuard()  TIGHTDB_NOEXCEPT { if (m_map) m_map->unmap(); }
    void release() TIGHTDB_NOEXCEPT { m_map = 0; }
private:
    MapBase* m_map;
};



/// Only output is supported at this point.
class File::Streambuf: public std::streambuf {
public:
    explicit Streambuf(File*);
    ~Streambuf();

private:
    static const std::size_t buffer_size = 4096;

    File& m_file;
    UniquePtr<char[]> const m_buffer;

    int_type overflow(int_type) TIGHTDB_OVERRIDE;
    int sync() TIGHTDB_OVERRIDE;
    pos_type seekpos(pos_type, std::ios_base::openmode) TIGHTDB_OVERRIDE;
    void flush();

    // Disable copying
    Streambuf(const Streambuf&);
    Streambuf& operator=(const Streambuf&);
};






// Implementation:

inline File::File(const std::string& path, Mode m)
{
#ifdef _WIN32
    m_handle = 0;
#else
    m_fd = -1;
#endif

    open(path, m);
}

inline File::File() TIGHTDB_NOEXCEPT
{
#ifdef _WIN32
    m_handle = 0;
#else
    m_fd = -1;
#endif
}

inline File::~File() TIGHTDB_NOEXCEPT
{
    close();
}

inline void File::open(const std::string& path, Mode m)
{
    AccessMode a = access_ReadWrite;
    CreateMode c = create_Auto;
    int flags = 0;
    switch (m) {
        case mode_Read:   a = access_ReadOnly; c = create_Never; break;
        case mode_Update:                      c = create_Never; break;
        case mode_Write:  flags = flag_Trunc;                    break;
        case mode_Append: flags = flag_Append;                   break;
    }
    open(path, a, c, flags);
}

inline void File::open(const std::string& path, AccessMode am, CreateMode cm, int flags)
{
    open_internal(path, am, cm, flags, NULL);
}


inline void File::open(const std::string& path, bool& was_created)
{
    while (1) {
        bool success;
        open_internal(path, access_ReadWrite, create_Must, 0, &success);
        if (success) {
            was_created = true;
            return;
        }
        open_internal(path, access_ReadWrite, create_Never, 0, &success);
        if (success) {
            was_created = false;
            return;
        }
    }
}

inline bool File::is_attached() const TIGHTDB_NOEXCEPT
{
#ifdef _WIN32
    return (m_handle != NULL);
#else
    return 0 <= m_fd;
#endif
}

inline void File::lock_exclusive()
{
    lock(true, false);
}

inline void File::lock_shared()
{
    lock(false, false);
}

inline bool File::try_lock_exclusive()
{
    return lock(true, true);
}

inline bool File::try_lock_shared()
{
    return lock(false, true);
}

inline File::MapBase::MapBase() TIGHTDB_NOEXCEPT
{
    m_addr = 0;
}

inline File::MapBase::~MapBase() TIGHTDB_NOEXCEPT
{
    unmap();
}

inline void File::MapBase::map(const File& f, AccessMode a, std::size_t size, int map_flags)
{
    TIGHTDB_ASSERT(!m_addr);

    m_addr = f.map(a, size, map_flags);
    m_size = size;
}

inline void File::MapBase::unmap() TIGHTDB_NOEXCEPT
{
    if (!m_addr) return;
    File::unmap(m_addr, m_size);
    m_addr = 0;
}

inline void File::MapBase::remap(const File& f, AccessMode a, std::size_t size, int map_flags)
{
    TIGHTDB_ASSERT(m_addr);

    m_addr = f.remap(m_addr, m_size, a, size, map_flags);
    m_size = size;
}

inline void File::MapBase::sync()
{
    TIGHTDB_ASSERT(m_addr);

    File::sync_map(m_addr, m_size);
}

template<class T>
inline File::Map<T>::Map(const File& f, AccessMode a, std::size_t size, int map_flags)
{
    map(f, a, size, map_flags);
}

template<class T> inline File::Map<T>::Map() TIGHTDB_NOEXCEPT {}

template<class T> inline File::Map<T>::~Map() TIGHTDB_NOEXCEPT {}

template<class T>
inline T* File::Map<T>::map(const File& f, AccessMode a, std::size_t size, int map_flags)
{
    MapBase::map(f, a, size, map_flags);
    return static_cast<T*>(m_addr);
}

template<class T> inline void File::Map<T>::unmap() TIGHTDB_NOEXCEPT
{
    MapBase::unmap();
}

template<class T>
inline T* File::Map<T>::remap(const File& f, AccessMode a, std::size_t size, int map_flags)
{
    MapBase::remap(f, a, size, map_flags);
    return static_cast<T*>(m_addr);
}

template<class T> inline void File::Map<T>::sync()
{
    MapBase::sync();
}

template<class T> inline bool File::Map<T>::is_attached() const TIGHTDB_NOEXCEPT
{
    return (m_addr != NULL);
}

template<class T> inline T* File::Map<T>::get_addr() const TIGHTDB_NOEXCEPT
{
    return static_cast<T*>(m_addr);
}

template<class T> inline std::size_t File::Map<T>::get_size() const TIGHTDB_NOEXCEPT
{
    return m_addr ? m_size : 0;
}

template<class T> inline T* File::Map<T>::release() TIGHTDB_NOEXCEPT
{
    T* addr = static_cast<T*>(m_addr);
    m_addr = 0;
    return addr;
}


inline File::Streambuf::Streambuf(File* f): m_file(*f), m_buffer(new char[buffer_size])
{
    char* b = m_buffer.get();
    setp(b, b + buffer_size);
}

inline File::Streambuf::~Streambuf()
{
    try {
        if (m_file.is_attached()) flush();
    }
    catch (...) {
        // Errors deliberately ignored
    }
}

inline File::Streambuf::int_type File::Streambuf::overflow(int_type c)
{
    flush();
    if (c == traits_type::eof())
        return traits_type::not_eof(c);
    *pptr() = traits_type::to_char_type(c);
    pbump(1);
    return c;
}

inline int File::Streambuf::sync()
{
    flush();
    return 0;
}

inline File::Streambuf::pos_type File::Streambuf::seekpos(pos_type pos, std::ios_base::openmode)
{
    flush();
    SizeType pos2 = 0;
    if (int_cast_with_overflow_detect(std::streamsize(pos), pos2))
        throw std::runtime_error("Seek position overflow");
    m_file.seek(pos2);
    return pos;
}

inline void File::Streambuf::flush()
{
    std::size_t n = pptr() - pbase();
    m_file.write(pbase(), n);
    setp(m_buffer.get(), epptr());
}


} // namespace util
} // namespace tightdb

#endif // TIGHTDB_UTIL_FILE_HPP
