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


class WriteLogRegistryInterface {
public:
    typedef tightdb::Replication::version_type version_type;
    struct CommitEntry { std::size_t sz; char* data; };
  
    // Add a commit for a given version:
    // The registry takes ownership of the buffer data.
    virtual void add_commit(version_type version, char* data, std::size_t sz) = 0;
    
    // The registry retains commit buffers for as long as there is a
    // registered interest:
    
    // Register an interest in commits following version 'from'
    virtual void register_interest(version_type from) = 0;
    
    // Register that you are no longer interested in commits following
    // version 'from'.
    virtual void unregister_interest(version_type from) = 0;

    // Get an array of commits for a version range - ]from..to]
    // The array will have exactly 'to' - 'from' entries.
    // The caller takes ownership of the array of commits, but not of the
    // buffers pointed to by each commit in the array. Ownership of the
    // buffers remains with the WriteLogRegistry.
    virtual CommitEntry* get_commit_entries(version_type from, version_type to) = 0;

    // This also unregisters interest in the same version range.
    virtual void release_commit_entries(version_type from, version_type to) = 0;
};


WriteLogRegistryInterface* getWriteLogs(std::string filepath);

Replication* makeWriteLogCollector(std::string database_name, 
				   WriteLogRegistryInterface* registry);

} // namespace tightdb
