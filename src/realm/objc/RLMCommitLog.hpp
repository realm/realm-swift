/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
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

#include <exception>

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/util/thread.hpp>
#include <tightdb/group_shared.hpp>
#include <map>

#include <tightdb/replication.hpp>

namespace tightdb {

class WriteLogRegistry;

class RegistryRegistry {
public:
    WriteLogRegistry* get(std::string fname);
    void add(std::string fname, WriteLogRegistry* registry);
    void remove(std::string fname);
private:
    util::Mutex m_mutex;
    std::map<std::string, WriteLogRegistry*> m_registries;
};

extern RegistryRegistry globalRegistry;

class WriteLogRegistry {
public:
    typedef tightdb::Replication::version_type version_type;
    struct CommitEntry { std::size_t sz; char* data; };
    WriteLogRegistry();
  
    // Add a commit for a given version:
    // The registry takes ownership of the buffer data.
    void add_commit(version_type version, char* data, std::size_t sz);
    
    // The registry retains commit buffers for as long as there is a
    // registered interest:
    
    // Register an interest in commits following version 'from'
    void register_interest(version_type from);
    
    // Register that you are no longer interested in commits following
    // version 'from'.
    void unregister_interest(version_type from);

    // Get an array of commits for a version range - ]from..to]
    // The array will have exactly 'to' - 'from' entries.
    // The caller takes ownership of the array of commits, but not of the
    // buffers pointed to by each commit in the array. Ownership of the
    // buffers remains with the WriteLogRegistry.
    CommitEntry* get_commit_entries(version_type from, version_type to);

    // This also unregisters interest in the same version range.
    void release_commit_entries(version_type from, version_type to);
private:
    // cleanup and release unreferenced buffers. Buffers might be big, so
    // we release them asap. Only to be called under lock.
    void cleanup();
    std::vector<CommitEntry> m_commits;
    std::vector<int> m_interest_counts;
    int m_future_interest_count;
    version_type m_array_start;
    version_type m_last_forgotten_version;
    version_type m_newest_version;
    util::Mutex m_mutex;
};

class WriteLogCollector : public Replication
{
public:
    WriteLogCollector(std::string database_name, WriteLogRegistry* registry);
    ~WriteLogCollector() TIGHTDB_NOEXCEPT {};
    std::string do_get_database_path() TIGHTDB_OVERRIDE { return m_database_name; }
    void do_begin_write_transact(SharedGroup& sg) TIGHTDB_OVERRIDE;
    version_type do_commit_write_transact(SharedGroup& sg, version_type orig_version) TIGHTDB_OVERRIDE;
    void do_rollback_write_transact(SharedGroup& sg) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE;
    void do_interrupt() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {};
    void do_clear_interrupt() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {};
    void do_transact_log_reserve(std::size_t sz) TIGHTDB_OVERRIDE;
    void do_transact_log_append(const char* data, std::size_t size) TIGHTDB_OVERRIDE;
    void transact_log_reserve(std::size_t n) TIGHTDB_OVERRIDE;
protected:
    std::string m_database_name;
    util::Buffer<char> m_transact_log_buffer;
    WriteLogRegistry* m_registry;
};

}; // namespace
