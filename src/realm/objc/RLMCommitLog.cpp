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
#include "RLMCommitLog.hpp"

#include <tightdb/replication.hpp>

namespace tightdb {



class RegistryRegistry {
public:
    WriteLogRegistryInterface* get(std::string filepath);
    void add(std::string filepath, WriteLogRegistryInterface* registry);
    void remove(std::string filepath);
private:
    util::Mutex m_mutex;
    std::map<std::string, WriteLogRegistryInterface*> m_registries;
};

RegistryRegistry globalRegistry;


WriteLogRegistryInterface* getWriteLogs(std::string filepath)
{
    return globalRegistry.get(filepath);
}


class WriteLogCollector : public Replication
{
public:
    WriteLogCollector(std::string database_name, 
		      WriteLogRegistryInterface* registry);
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
    WriteLogRegistryInterface* m_registry;
};


class WriteLogRegistry : public WriteLogRegistryInterface
{
public:
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


Replication* makeWriteLogCollector(std::string database_name, WriteLogRegistryInterface* registry)
{
  return  new WriteLogCollector(database_name, registry);
}

WriteLogRegistryInterface* RegistryRegistry::get(std::string filepath)
{
    util::LockGuard lock(m_mutex);
    std::map<std::string, WriteLogRegistryInterface*>::iterator iter;
    iter = m_registries.find(filepath);
    if (iter != m_registries.end())
        return iter->second;
    WriteLogRegistryInterface* result = new WriteLogRegistry;
    m_registries[filepath] = result;
    return result;
};


void RegistryRegistry::add(std::string filepath, WriteLogRegistryInterface* registry)
{
    util::LockGuard lock(m_mutex);
    m_registries[filepath] = registry;
}


void RegistryRegistry::remove(std::string filepath)
{
    util::LockGuard lock(m_mutex);
    m_registries.erase(filepath);
}



WriteLogRegistry::WriteLogRegistry()
{
     m_future_interest_count = 0;
     m_last_forgotten_version = 0;
     m_newest_version = 0;
     m_array_start = 0;
}


void WriteLogRegistry::add_commit(version_type version, char* data, std::size_t sz)
{
    util::LockGuard lock(m_mutex);
    // we assume that commits are entered in version order.
    TIGHTDB_ASSERT(m_newest_version == 0 || version == 1 + m_newest_version);
    if (m_newest_version == 0) {
        m_array_start = version;
        m_last_forgotten_version = version - 1;
    }
    CommitEntry ce = { sz, data };
    m_commits.push_back(ce);
    m_interest_counts.push_back(m_future_interest_count);
    m_newest_version = version;
}
    

void WriteLogRegistry::register_interest(version_type from)
{
    util::LockGuard lock(m_mutex);
    // from is assumed to be within the range of commits already registered
    size_t idx = from + 1 - m_array_start;
    while (idx < m_interest_counts.size()) {
        m_interest_counts[idx] += 1;
    }
    m_future_interest_count += 1;
}
    

void WriteLogRegistry::unregister_interest(version_type from)
{
    util::LockGuard lock(m_mutex);
    // from is assumed to be within the range of commits already registered
    size_t idx = from + 1 - m_array_start;
    while (idx < m_interest_counts.size()) {
        m_interest_counts[idx] -= 1;
    }
    m_future_interest_count -= 1;
    cleanup();
}


WriteLogRegistry::CommitEntry* 
WriteLogRegistry::get_commit_entries(version_type from, version_type to)
{
    util::LockGuard lock(m_mutex);
    WriteLogRegistry::CommitEntry* entries = new CommitEntry[ to - from ];
    for (size_t idx = 0; idx < to - from; idx++) {
        entries[idx] = m_commits[ idx + 1 + from - m_array_start];
    }
    return entries;
}
    

void WriteLogRegistry::release_commit_entries(version_type from, version_type to)
{
    util::LockGuard lock(m_mutex);
    for (size_t idx = 0; idx < to - from; idx++) {
        m_interest_counts[ idx + 1 + from - m_array_start ] -= 1;
    }
    cleanup();
}


void WriteLogRegistry::cleanup()
{
    size_t idx = m_last_forgotten_version - m_array_start + 1;
    while (idx < m_interest_counts.size() &&  m_interest_counts[idx] == 0) {

        delete[] m_commits[idx].data;
        m_commits[idx].data = 0;
        m_commits[idx].sz = 0;
        ++idx;
    }
    m_last_forgotten_version = idx + m_array_start - 1;
    if (idx > (m_interest_counts.size()+1) >> 1) {
            
        // more than half of the housekeeping arrays are free, so we'll
        // shift contents down and resize the arrays.
        std::copy(&m_commits[idx],
                  &m_commits[m_newest_version + 1 - m_array_start],
                  &m_commits[0]);
        m_commits.resize(m_newest_version - m_last_forgotten_version);
        std::copy(&m_interest_counts[idx],
                  &m_interest_counts[m_newest_version + 1 - m_array_start],
                  &m_interest_counts[0]);
        m_interest_counts.resize(m_newest_version - m_last_forgotten_version);
        m_array_start = m_last_forgotten_version + 1;
    }
}


void WriteLogCollector::do_begin_write_transact(SharedGroup& sg) TIGHTDB_OVERRIDE
{
    static_cast<void>(sg);
    m_transact_log_free_begin = m_transact_log_buffer.data();
    m_transact_log_free_end   = m_transact_log_free_begin + m_transact_log_buffer.size();
}


WriteLogCollector::version_type 
WriteLogCollector::do_commit_write_transact(SharedGroup& sg, 
	WriteLogCollector::version_type orig_version) TIGHTDB_OVERRIDE
{
    static_cast<void>(sg);
    char* data     = m_transact_log_buffer.release();
    std::size_t sz = m_transact_log_free_begin - data;
    version_type new_version = orig_version + 1;
    m_registry->add_commit(new_version, data, sz);
    return new_version;
};


void WriteLogCollector::do_rollback_write_transact(SharedGroup& sg) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE
{
    // not used in this setting
    static_cast<void>(sg);
};


void WriteLogCollector::do_transact_log_reserve(std::size_t sz) TIGHTDB_OVERRIDE
{
    transact_log_reserve(sz);
};


void WriteLogCollector::do_transact_log_append(const char* data, std::size_t size) TIGHTDB_OVERRIDE
{
    transact_log_reserve(size);
    m_transact_log_free_begin = std::copy(data, data+size, m_transact_log_free_begin);
};


void WriteLogCollector::transact_log_reserve(std::size_t n) TIGHTDB_OVERRIDE
{
    char* data = m_transact_log_buffer.data();
    std::size_t size = m_transact_log_free_begin - data;
    m_transact_log_buffer.reserve_extra(size, n);
    data = m_transact_log_buffer.data();
    m_transact_log_free_begin = data + size;
    m_transact_log_free_end = data + m_transact_log_buffer.size();
};


WriteLogCollector::WriteLogCollector(std::string database_name, WriteLogRegistryInterface* registry)
{
    m_database_name = database_name;
    m_registry = registry;
}

} // namespace tightdb
