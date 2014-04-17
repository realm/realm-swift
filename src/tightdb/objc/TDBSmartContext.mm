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

// FIXME: this is absolutely no-go:
#include </Users/test/tightdb/src/tightdb/replication.hpp>

#import "TDBConstants.h"
#import "TDBTable_noinst.h"
#import "TDBSmartContext_noinst.h"
#import "PrivateTDB.h"
#import "util_noinst.hpp"

using namespace std;
using namespace tightdb;
using namespace tightdb::util;


namespace {

void throw_objc_exception(exception &ex)
{
    NSString *errorMessage = [NSString stringWithUTF8String:ex.what()];
    @throw [NSException exceptionWithName:@"TDBException" reason:errorMessage userInfo:nil];
}

} // anonymous namespace


@interface TDBPrivateWeakTableReference: NSObject
- (instancetype)initWithTable:(TDBTable *)table indexInGroup:(size_t)index;
- (TDBTable *)table;
- (size_t)indexInGroup;
@end

@implementation TDBPrivateWeakTableReference
{
    __weak TDBTable *_table;
    size_t _indexInGroup;
}

- (instancetype)initWithTable:(TDBTable *)table indexInGroup:(size_t)index
{
    _table = table;
    _indexInGroup = index;
    return self;
}

- (TDBTable *)table
{
    return _table;
}

- (size_t)indexInGroup
{
    return _indexInGroup;
}

@end


@class TDBSmartContext;

@interface TDBPrivateWeakTimerTarget: NSObject
- (instancetype)initWithContext:(TDBSmartContext *)target;
- (void)timerDidFire:(NSTimer *)timer;
@end

@implementation TDBPrivateWeakTimerTarget
{
    __weak TDBSmartContext *_context;
}

- (instancetype)initWithContext:(TDBSmartContext *)context
{
    _context = context;
    return self;
}

- (void)timerDidFire:(NSTimer *)timer
{
    [_context checkForChange:timer];
}

@end

class WriteLogRegistry;

class RegistryRegistry {
public:
    WriteLogRegistry* get(std::string fname)
    {
        util::LockGuard lock(m_mutex);
        return  m_registries.find(fname)->second;
    };
    void add(std::string fname, WriteLogRegistry* registry)
    {
        util::LockGuard lock(m_mutex);
        m_registries[fname] = registry;
    }
    void remove(std::string fname)
    {
        util::LockGuard lock(m_mutex);
        m_registries.erase(fname);
    }
private:
    util::Mutex m_mutex;
    std::map<std::string, WriteLogRegistry*> m_registries;
};

RegistryRegistry globalRegistry;

// FIXME: To be moved to a separate file
class WriteLogRegistry {
public:
    typedef Replication::version_type version_type;
    struct CommitEntry { std::size_t sz; char* data; };
    WriteLogRegistry()
    {
        m_future_interest_count = 0;
	    m_last_forgotten_version = 0;
        m_newest_version = 0;
        m_array_start = 0;
    }
    // Add a commit for a given version:
    // The registry takes ownership of the buffer data.
    void add_commit(version_type version, char* data, std::size_t sz)
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
    
    // The registry retains commit buffers for as long as there is a
    // registered interest:
    
    // Register an interest in commits following version 'from'
    void register_interest(version_type from)
    {
        util::LockGuard lock(m_mutex);
        // from is assumed to be within the range of commits already registered
        size_t idx = from + 1 - m_array_start;
        while (idx < m_interest_counts.size()) {
            m_interest_counts[idx] += 1;
        }
        m_future_interest_count += 1;
    }
    
    // Register that you are no longer interested in commits following
    // version 'from'.
    void unregister_interest(version_type from)
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

    // Get an array of commits for a version range - ]from..to]
    // The array will have exactly 'to' - 'from' entries.
    // The caller takes ownership of the array of commits, but not of the
    // buffers pointed to by each commit in the array. Ownership of the
    // buffers remains with the WriteLogRegistry.
    CommitEntry* get_commit_entries(version_type from, version_type to)
    {
        util::LockGuard lock(m_mutex);
        CommitEntry* entries = new CommitEntry[ to - from ];
        for (size_t idx = 0; idx < to - from; idx++) {
            entries[idx] = m_commits[ idx + 1 + from - m_array_start];
        }
        return entries;
    }
    
    // Release access to commits for a version range - ]from..to]
    // This also unregisters interest in the same version range.
    void release_commit_entries(version_type from, version_type to)
    {
        util::LockGuard lock(m_mutex);
        for (size_t idx = 0; idx < to - from; idx++) {
            m_interest_counts[ idx + 1 + from - m_array_start ] -= 1;
        }
        cleanup();
    }
private:
    // cleanup and release unreferenced buffers. Buffers might be big, so
    // we release them asap. Only to be called under lock.
    void cleanup()
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
    void do_begin_write_transact(SharedGroup& sg) TIGHTDB_OVERRIDE
    {
        static_cast<void>(sg);
        m_transact_log_free_begin = m_transact_log_buffer.data();
        m_transact_log_free_end   = m_transact_log_free_begin + m_transact_log_buffer.size();
    }
    version_type do_commit_write_transact(SharedGroup& sg, version_type orig_version) TIGHTDB_OVERRIDE
    {
        static_cast<void>(sg);
        char* data     = m_transact_log_buffer.release();
        std::size_t sz = m_transact_log_free_begin - data;
        version_type new_version = orig_version + 1;
        m_registry->add_commit(new_version, data, sz);
        return new_version;
    };
    void do_rollback_write_transact(SharedGroup& sg) TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE
    {
        // not used in this setting
        static_cast<void>(sg);
    };
    void do_interrupt() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {};
    void do_clear_interrupt() TIGHTDB_NOEXCEPT TIGHTDB_OVERRIDE {};
    void do_transact_log_reserve(std::size_t sz) TIGHTDB_OVERRIDE
    {
        transact_log_reserve(sz);
    };
    void do_transact_log_append(const char* data, std::size_t size) TIGHTDB_OVERRIDE
    {
        transact_log_reserve(size);
        m_transact_log_free_begin = copy(data, data+size, m_transact_log_free_begin);
    };
    void transact_log_reserve(std::size_t n) TIGHTDB_OVERRIDE
    {
        char* data = m_transact_log_buffer.data();
        std::size_t size = m_transact_log_free_begin - data;
        m_transact_log_buffer.reserve_extra(size, n);
        data = m_transact_log_buffer.data();
        m_transact_log_free_begin = data + size;
        m_transact_log_free_end = data + m_transact_log_buffer.size();
    };
protected:
    std::string m_database_name;
    util::Buffer<char> m_transact_log_buffer;
    WriteLogRegistry* m_registry;
};

WriteLogCollector::WriteLogCollector(std::string database_name, WriteLogRegistry* registry)
{
    m_database_name = database_name;
    m_registry = registry;
}

@implementation TDBSmartContext
{
    NSNotificationCenter *_notificationCenter;
    UniquePtr<SharedGroup> _sharedGroup;
    const Group *_group;
    NSTimer *_timer;
    NSMutableArray *_weakTableRefs; // Elements are instances of TDBPrivateWeakTableReference
    BOOL _tableRefsHaveDied;
    WriteLogRegistry* _registry;
}

+(TDBSmartContext *)contextWithPersistenceToFile:(NSString *)path
{
    NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    return [self contextWithPersistenceToFile:path
                                      runLoop:runLoop
                           notificationCenter:notificationCenter
                                        error:nil];
}

+(TDBSmartContext *)contextWithPersistenceToFile:(NSString *)path
                                         runLoop:(NSRunLoop *)runLoop
                              notificationCenter:(NSNotificationCenter *)notificationCenter
                                           error:(NSError **)error
{
    TDBSmartContext *context = [[TDBSmartContext alloc] init];
    if (!context)
        return nil;

    context->_notificationCenter = notificationCenter;

    TightdbErr errorCode = tdb_err_Ok;
    NSString *errorMessage;
    // FIXME: Should not be created here, but passed in by ref or be a global singleton
    context->_registry = globalRegistry.get(StringData(ObjcStringAccessor(path)));
    WriteLogCollector* collector = new WriteLogCollector(StringData(ObjcStringAccessor(path)), context->_registry);
    try {
        context->_sharedGroup.reset(new SharedGroup( *collector));
    }
    catch (File::PermissionDenied &ex) {
        errorCode    = tdb_err_File_PermissionDenied;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    catch (File::Exists &ex) {
        errorCode    = tdb_err_File_Exists;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    catch (File::AccessError &ex) {
        errorCode    = tdb_err_File_AccessError;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    catch (exception &ex) {
        errorCode    = tdb_err_Fail;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    if (errorCode != tdb_err_Ok) {
        if (error)
            *error = make_tightdb_error(errorCode, errorMessage);
        return nil;
    }

    // Register an interval timer on specified runLoop
    NSTimeInterval seconds = 0.1; // Ten times per second
    TDBPrivateWeakTimerTarget *weakTimerTarget =
        [[TDBPrivateWeakTimerTarget alloc] initWithContext:context];
    context->_timer = [NSTimer timerWithTimeInterval:seconds target:weakTimerTarget
                                            selector:@selector(timerDidFire:)
                                            userInfo:nil repeats:YES];
    [runLoop addTimer:context->_timer forMode:NSDefaultRunLoopMode];

    context->_weakTableRefs = [NSMutableArray array];

    try {
        context->_group = &context->_sharedGroup->begin_read();
        context->_registry->register_interest(context->_sharedGroup->get_last_transaction_version());
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }

    return context;
}

-(void)dealloc
{
    [_timer invalidate];
    _registry->unregister_interest(_sharedGroup->get_last_transaction_version());
}

- (void)checkForChange:(NSTimer *)theTimer
{
    static_cast<void>(theTimer);

    // Remove dead table references from list
    if (_tableRefsHaveDied) {
        NSMutableArray *deadTableRefs = [NSMutableArray array];
        for (TDBPrivateWeakTableReference *weakTableRef in _weakTableRefs) {
            if (![weakTableRef table])
                [deadTableRefs addObject:weakTableRef];
        }
        [_weakTableRefs removeObjectsInArray:deadTableRefs];
        _tableRefsHaveDied = NO;
    }

    // Advance transaction if database has changed
    try {
        if (_sharedGroup->has_changed()) { // Throws
            Replication::version_type from_version = _sharedGroup->get_last_transaction_version();
            _sharedGroup->end_read();
            _group = &_sharedGroup->begin_read(); // Throws
            Replication::version_type to_version = _sharedGroup->get_last_transaction_version();
            WriteLogRegistry::CommitEntry* commits = _registry->get_commit_entries(from_version, to_version);
            // FIXME: Use the commit entries to update accessors...
            // TODO
            static_cast<void>(commits); // avoding a warning until we put the entries to use
            // Done - tell the registry, that we're done reading the commit entries:
            _registry->release_commit_entries(from_version, to_version);
            delete[] commits;
            
            // Revive all group level table accessors
            for (TDBPrivateWeakTableReference *weakTableRef in _weakTableRefs) {
                TDBTable *table = [weakTableRef table];
                size_t indexInGroup = [weakTableRef indexInGroup];
                ConstTableRef table_2 = _group->get_table(indexInGroup); // Throws
                // Note: Const spoofing is alright, because the
                // Objective-C table accessor is in 'read-only' mode.
                [table setNativeTable:const_cast<Table*>(table_2.get())];
            }

            [_notificationCenter postNotificationName:TDBContextDidChangeNotification object:self];
        }
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
}

-(TDBTable *)tableWithName:(NSString *)name
{
    ObjcStringAccessor name_2(name);
    if (!_group->has_table(name_2))
        return nil;
    TDBTable *table = [[TDBTable alloc] _initRaw];
    size_t indexInGroup;
    try {
        ConstTableRef table_2 = _group->get_table(name_2); // Throws
        // Note: Const spoofing is alright, because the
        // Objective-C table accessor is in 'read-only' mode.
        [table setNativeTable:const_cast<Table*>(table_2.get())];
        indexInGroup = table_2->get_index_in_parent();
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
    [table setParent:self];
    [table setReadOnly:YES];
    TDBPrivateWeakTableReference *weakTableRef =
        [[TDBPrivateWeakTableReference alloc] initWithTable:table indexInGroup:indexInGroup];
    [_weakTableRefs addObject:weakTableRef];
    return table;
}

- (void)tableRefDidDie
{
    _tableRefsHaveDied = YES;
}

@end
