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
#ifndef TIGHTDB_GROUP_WRITER_HPP
#define TIGHTDB_GROUP_WRITER_HPP

#include <stdint.h> // unint8_t etc
#include <utility>

#include <tightdb/util/file.hpp>
#include <tightdb/alloc.hpp>


namespace tightdb {

// Pre-declarations
class Group;
class SlabAlloc;

class GroupWriter {
public:
    GroupWriter(Group&);

    void set_versions(uint64_t current, uint64_t read_lock);

    /// Write all changed array nodes into free space.
    ///
    /// Returns the new top ref. When in full durability mode, call
    /// commit() with the returned top ref.
    ref_type write_group();

    /// Flush changes to physical medium, then write the new top ref
    /// to the file header, then flush again. Pass the top ref
    /// returned by write_group().
    void commit(ref_type new_top_ref);

    std::size_t get_file_size() const TIGHTDB_NOEXCEPT;

    /// Write the specified chunk into free space.
    void write(const char* data, std::size_t size);

    /// Write the specified array data and its checksum into free
    /// space.
    ///
    /// Returns the position in the file where the first byte was
    /// written.
    std::size_t write_array(const char* data, std::size_t size, uint_fast32_t checksum);

#ifdef TIGHTDB_DEBUG
    void dump();
#endif

private:
    Group&     m_group;
    SlabAlloc& m_alloc;
    uint64_t   m_current_version;
    uint64_t   m_readlock_version;
    util::File::Map<char> m_file_map;

    void merge_free_space();

    /// Allocate a chunk of free space of the specified size. The
    /// specified size must be 8-byte aligned. Extend the file if
    /// required. The returned chunk is removed from the amount of
    /// remaing free space.
    ///
    /// \return The position within the database file of the allocated
    /// chunk.
    std::size_t get_free_space(std::size_t size);

    /// Find a block of free space that is at least as big as the
    /// specified size. The specified size does not need to be 8-byte
    /// aligned. Extend the file if required. The returned chunk is
    /// not removed from the amount of remaing free space. This
    /// function guarantees that it will add at most one entry to the
    /// free-lists.
    ///
    /// \return A pair (`chunk_ndx`, `chunk_size`) where `chunk_ndx`
    /// is the index of a chunk whose size is at least the requestd
    /// size, and `chunk_size` is the size of that chunk.
    std::pair<std::size_t, std::size_t> reserve_free_space(std::size_t size);

    /// Extend the file to ensure that a chunk of free space of the
    /// specified size is available. The specified size does not need
    /// to be 8-byte aligned. This function guarantees that it will
    /// add at most one entry to the free-lists.
    ///
    /// \return A pair (`chunk_ndx`, `chunk_size`) where `chunk_ndx`
    /// is the index of a chunk whose size is at least the requestd
    /// size, and `chunk_size` is the size of that chunk.
    std::pair<std::size_t, std::size_t> extend_free_space(std::size_t requested_size);

    void write_array_at(std::size_t pos, const char* data, std::size_t size);
};




// Implementation:

inline std::size_t GroupWriter::get_file_size() const TIGHTDB_NOEXCEPT
{
    return m_file_map.get_size();
}

inline void GroupWriter::set_versions(uint64_t current, uint64_t read_lock)
{
    TIGHTDB_ASSERT(read_lock <= current);
    m_current_version  = current;
    m_readlock_version = read_lock;
}

} // namespace tightdb

#endif // TIGHTDB_GROUP_WRITER_HPP
