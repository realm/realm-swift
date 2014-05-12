////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#include <exception>
#include <sstream>

#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/group_shared.hpp>
#include <tightdb/group.hpp>
#include <tightdb/lang_bind_helper.hpp>

#import "RLMConstants.h"
#import "RLMTable_noinst.h"
#import "RLMRealm_noinst.h"
#import "RLMPrivate.h"
#import "util_noinst.hpp"

using namespace std;
using namespace tightdb;
using namespace tightdb::util;

namespace {

// create NSException from c++ exception
void throw_objc_exception(exception &ex) {
    NSString *errorMessage = [NSString stringWithUTF8String:ex.what()];
    @throw [NSException exceptionWithName:@"RLMException" reason:errorMessage userInfo:nil];
}

} // anonymous namespace


// simple weak wrapper for a weak target timer
@interface RLMWeakTarget : NSObject
@property (nonatomic, weak) RLMRealm *realm;
@end
@implementation RLMWeakTarget
- (void)checkForUpdate {
    [_realm performSelector:@selector(refresh)];
}
@end


// functionality for caching Realm instances
static NSMutableDictionary *s_realmsPerPath;

// FIXME: In the following 3 functions, we should be identifying files by the inode,device number pair
//  rather than by the path (since the path is not a reliable identifier). This requires additional support
//  from the core library though, because the inode,device number pair needs to be taken from the open file
//  (to avoid race conditions).
RLMRealm *cachedRealm(NSString *path) {
    mach_port_t threadID = pthread_mach_thread_np(pthread_self());
    @synchronized(s_realmsPerPath) {
        return [s_realmsPerPath[path] objectForKey:@(threadID)];
    }
}

void cacheRealm(RLMRealm *realm, NSString *path) {
    mach_port_t threadID = pthread_mach_thread_np(pthread_self());
    @synchronized(s_realmsPerPath) {
        if (!s_realmsPerPath[path]) {
            s_realmsPerPath[path] = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPersonality valueOptions:NSPointerFunctionsWeakMemory];
        }
        [s_realmsPerPath[path] setObject:realm forKey:@(threadID)];
    }
}

NSArray *realmsAtPath(NSString *path) {
    @synchronized(s_realmsPerPath) {
        return [s_realmsPerPath[path] objectEnumerator].allObjects;
    }
}

typedef NS_ENUM(NSUInteger, RLMTransactionMode) {
    RLMTransactionModeNone = 0,
    RLMTransactionModeRead,
    RLMTransactionModeWrite
};

@interface RLMRealm ()
@property (readonly) RLMTransactionMode transactionMode;
@end

@implementation RLMRealm {
    UniquePtr<SharedGroup> _sharedGroup;
    NSMapTable *_objects;
    NSRunLoop *_runLoop;
    NSString *_path;
    NSTimer *_updateTimer;
    NSMutableArray *_notificationHandlers;
    
    tightdb::Group *_readGroup;
    tightdb::Group *_writeGroup;
}

+ (void)initialize {
    // set up global realm cache
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_realmsPerPath = [NSMutableDictionary dictionary];
    });
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = path;
        _runLoop = [NSRunLoop currentRunLoop];
        _objects = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsOpaquePersonality
                                             valueOptions:NSPointerFunctionsWeakMemory
                                                 capacity:128];
        _notificationHandlers = [NSMutableArray array];
        
        RLMWeakTarget *wt = [RLMWeakTarget new];
        wt.realm = self;
        _updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:wt selector:@selector(checkForUpdate) userInfo:nil repeats:YES];
    }
    return self;
}

NSString *const defaultRealmFileName = @"default.realm";

+(NSString *)defaultPath
{
    return [RLMRealm writeablePathForFile:defaultRealmFileName];
}

+ (NSString *)writeablePathForFile:(NSString*)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

+ (instancetype)defaultRealm
{
    return [RLMRealm realmWithPath:RLMRealm.defaultPath error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path
{
    return [self realmWithPath:path error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path
                        error:(NSError **)error
{
    NSRunLoop *currentRunloop = [NSRunLoop currentRunLoop];
    if (!currentRunloop) {
        @throw [NSException exceptionWithName:@"realm:runloop_exception"
                                       reason:[NSString stringWithFormat:@"%@ \
                                               can only be called from a thread with a runloop. \
                                               Use an RLMTransactionManager read or write block \
                                               instead.", NSStringFromSelector(_cmd)] userInfo:nil];
    }

    // try to reuse existing realm first
    RLMRealm *realm = cachedRealm(path);
    if (realm) {
        return realm;
    }
    
    realm = [[RLMRealm alloc] initWithPath:path];
    if (!realm) {
        return nil;
    }
    
    RLMError errorCode = RLMErrorOk;
    NSString *errorMessage;
    try {
        realm->_sharedGroup.reset(new SharedGroup(StringData(ObjcStringAccessor(path))));
    }
    catch (File::PermissionDenied &ex) {
        errorCode    = RLMErrorFilePermissionDenied;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    catch (File::Exists &ex) {
        errorCode    = RLMErrorFileExists;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    catch (File::AccessError &ex) {
        errorCode    = RLMErrorFileAccessError;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    catch (exception &ex) {
        errorCode    = RLMErrorFail;
        errorMessage = [NSString stringWithUTF8String:ex.what()];
    }
    if (errorCode != RLMErrorOk) {
        if (error) {
            *error = make_realm_error(errorCode, errorMessage);
        }
        return nil;
    }
    
    // cache main thread realm at this path
    cacheRealm(realm, path);

    // begin read transaction
    [realm beginReadTransaction];
    
    return realm;
}

- (void)addNotification:(RLMNotificationBlock)block {
    [_notificationHandlers addObject:block];
}

- (void)removeNotification:(RLMNotificationBlock)block {
    [_notificationHandlers removeObject:block];
}

- (void)removeAllNotifications {
    [_notificationHandlers removeAllObjects];
}

- (void)sendNotifications {
    // call this realms notification blocks
    for (RLMNotificationBlock block in _notificationHandlers) {
        block(RLMRealmDidChangeNotification, self);
    }
}

- (RLMTransactionMode)transactionMode {
    if (_readGroup != NULL) {
        return RLMTransactionModeRead;
    }
    if (_writeGroup != NULL) {
        return RLMTransactionModeWrite;
    }
    return RLMTransactionModeNone;
    
}


- (void)beginReadTransaction {
    if (self.transactionMode == RLMTransactionModeNone) {
        try {
            _readGroup = (tightdb::Group *)&_sharedGroup->begin_read();
            [self updateAllObjects];
        }
        catch (exception &ex) {
            throw_objc_exception(ex);
        }
    }
}

- (void)endReadTransaction {
    if (self.transactionMode == RLMTransactionModeRead) {
        try {
            _sharedGroup->end_read();
            _readGroup = NULL;
        }
        catch (std::exception& ex) {
            throw_objc_exception(ex);
        }
    }
}


- (void)beginWriteTransaction {
    if (self.transactionMode != RLMTransactionModeWrite) {
        try {
            // if we are moving the transaction forward, send local notifications
            if (_sharedGroup->has_changed()) {
                [self sendNotifications];
            }
            
            // end current read
            [self endReadTransaction];
            
            // create group
            _writeGroup = &_sharedGroup->begin_write();
            
            // make all objects in this realm writable
            [self updateAllObjects];
        }
        catch (std::exception& ex) {
            // File access errors are treated as exceptions here since they should not occur after the shared
            // group has already been successfully opened on the file and memory mapped. The shared group constructor handles
            // the excepted error related to file access.
            throw_objc_exception(ex);
        }
    }
}

- (void)commitWriteTransaction {
    if (self.transactionMode == RLMTransactionModeWrite) {
        try {
            _sharedGroup->commit();
            _writeGroup = NULL;
            
            [self beginReadTransaction];

            // notify other realm istances of changes
            for (RLMRealm *realm in realmsAtPath(_path)) {
                if (![realm isEqual:self]) {
                    [realm->_runLoop performSelector:@selector(refresh) target:realm argument:nil order:0 modes:@[NSRunLoopCommonModes]];
                }
            }
            
            // send local notification
            [self sendNotifications];
        }
        catch (std::exception& ex) {
            throw_objc_exception(ex);
        }
    }
}

- (void)rollbackWriteTransaction {
    if (self.transactionMode == RLMTransactionModeWrite) {
        try {
            _sharedGroup->rollback();
            _writeGroup = NULL;
            
            [self beginReadTransaction];
        }
        catch (std::exception& ex) {
            throw_objc_exception(ex);
        }
    }
}

- (void)writeUsingBlock:(RLMWriteBlock)block {
    [self beginWriteTransaction];
    block(self);
    [self commitWriteTransaction];
}

- (void)dealloc
{
    [_updateTimer invalidate];
    _updateTimer = nil;
    
    [self commitWriteTransaction];
    [self endReadTransaction];
}


- (void)refresh {
    try {
        // no-op if writing
        if (self.transactionMode == RLMTransactionModeWrite) {
            return;
        }
        
        // advance transaction if database has changed
        if (_sharedGroup->has_changed()) { // Throws
            [self endReadTransaction];
            [self beginReadTransaction];
            [self updateAllObjects];
            
            // send notification that someone else changed the realm
            [self sendNotifications];
        }
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
}

- (void)updateAllObjects {
    try {
        // get the group
        tightdb::Group *group = self.group;
        BOOL readOnly = (self.transactionMode == RLMTransactionModeRead);

        // refresh all outstanding objects
        for (RLMTable *obj in _objects.objectEnumerator.allObjects) {
            NSIndexPath *path = obj.indexPath;
            // NOTE: would like to get a non-const TableRef back here but that doesn't seem to work
            // so we must const_cast
            ConstTableRef tableRef = group->get_table([path indexAtPosition:0]); // Throws
            [obj setNativeTable:const_cast<Table*>(tableRef.get())];
            [obj setReadOnly:readOnly];
        }
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
}

- (tightdb::Group *)group {
    return _writeGroup ? _writeGroup : _readGroup;
}

- (RLMTable *)tableWithName:(NSString *)name
{
    if ([name length] == 0) {
        // FIXME: Exception name must be `TDBException` according to
        // the exception naming conventions of the official Cocoa
        // style guide. The same is true for most (if not all) of the
        // exceptions we throw.
        @throw [NSException exceptionWithName:@"realm:table_name_exception"
                                       reason:@"Name must be a non-empty NSString"
                                     userInfo:nil];
    }
    
    ObjcStringAccessor nameRef(name);
    if (!self.group->has_table(nameRef)) {
        return nil;
    }
    RLMTable *table = [[RLMTable alloc] _initRaw];
    try {
        TableRef tableRef = self.group->get_table(nameRef); // Throws
        [table setNativeTable:tableRef.get()];
        table.indexPath = [NSIndexPath indexPathWithIndex:tableRef->get_index_in_parent()];
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
    [table setParent:self];
    [table setReadOnly:(self.transactionMode == RLMTransactionModeRead)];
    
    // add to objects map
    [_objects setObject:table forKey:table];
    return table;
}

-(NSUInteger)tableCount // Overrides the property getter
{
    return self.group->size();
}

-(BOOL)isEmpty // Overrides the property getter
{
    return self.tableCount == 0;
}

-(BOOL)hasTableWithName:(NSString*)name
{
    return self.group->has_table(ObjcStringAccessor(name));
}

- (id)tableWithName:(NSString *)name objectClass:(__unsafe_unretained Class)objClass tableClass:(__unsafe_unretained Class)tableClass
{
    ObjcStringAccessor nameRef(name);
    if (!self.group->has_table(nameRef)) {
        return nil;
    }
    RLMTable *table = [[tableClass alloc] _initRaw];
    try {
        TableRef tableRef = self.group->get_table(nameRef); // Throws
        [table setNativeTable:tableRef.get()];
        table.indexPath = [NSIndexPath indexPathWithIndex:tableRef->get_index_in_parent()];
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
    [table setParent:self];
    [table setReadOnly:(self.transactionMode == RLMTransactionModeRead)];
    [_objects setObject:table forKey:table];
    
    if (objClass) {
        table.objectClass = objClass;
    }

    return table;
}

-(BOOL)hasTableWithName:(NSString *)name withTableClass:(__unsafe_unretained Class)class_obj
{
    if (!self.group->has_table(ObjcStringAccessor(name))) {
        return NO;
    }
    RLMTable *table = [self tableWithName:name objectClass:nil tableClass:class_obj];
    return table != nil;
}

-(RLMTable *)createTableWithName:(NSString*)name
{
    return [self createTableWithName:name objectClass:nil tableClass:[RLMTable class]];
}

-(RLMTable *)createTableWithName:(NSString*)name columns:(NSArray*)columns
{
    RLMTable *table = [self createTableWithName:name];
    
    //Set columns
    tightdb::TableRef nativeTable = [table getNativeTable].get_table_ref();
    if (!set_columns(nativeTable, columns)) {
        // Parsing the schema failed
        //TODO: More detailed error msg in exception
        @throw [NSException exceptionWithName:@"realm:invalid_columns"
                                       reason:@"The supplied list of columns was invalid"
                                     userInfo:nil];
    }
    
    return table;
}

// FIXME: Check that the specified class derives from Table.
-(id)createTableWithName:(NSString*)name objectClass:(__unsafe_unretained Class)objClass tableClass:(__unsafe_unretained Class)tableClass
{
    if ([name length] == 0) {
        @throw [NSException exceptionWithName:@"realm:table_name_exception"
                                       reason:@"Name must be a non-empty NSString"
                                     userInfo:nil];
    }
    
    if (self.transactionMode != RLMTransactionModeWrite) {
        @throw [NSException exceptionWithName:@"realm:core_read_only_exception"
                                       reason:@"Realm is read-only."
                                     userInfo:nil];
    }
    
    if ([self hasTableWithName:name]) {
        @throw [NSException exceptionWithName:@"realm:table_with_name_already_exists"
                                       reason:[NSString stringWithFormat:@"A table with the name '%@' already exists in the realm.", name]
                                     userInfo:nil];
    }
    
    RLMTable *table = [[tableClass alloc] _initRaw];
    if (TIGHTDB_UNLIKELY(!table))
        return nil;
    bool was_created;
    REALM_EXCEPTION_HANDLER_CORE_EXCEPTION(
                                           tightdb::TableRef tableRef = self.group->get_table(ObjcStringAccessor(name), was_created);
                                           [table setNativeTable:tableRef.get()];)
    [table setParent:self];
    [table setReadOnly:(self.transactionMode == RLMTransactionModeRead)];
    
    if (was_created) {
        if (![table _addColumns])
            return nil;
    }
    else {
        if (![table _checkType])
            return nil;
    }
    
    [_objects setObject:table forKey:table];
    
    if (objClass) {
        if ([objClass superclass] == [RLMRow class]) {
            table.objectClass = objClass;
        } else {
            @throw [NSException exceptionWithName:@"realm:row_object_not_valid"
                                           reason:[NSString stringWithFormat:@"Table cannot contain %@ objects.", NSStringFromClass(objClass)]
                                         userInfo:nil];
        }
    }

    return table;
}

-(NSString*)nameOfTableWithIndex:(NSUInteger)table_ndx
{
    return to_objc_string(self.group->get_table_name(table_ndx));
}

- (NSString *)toJSONString {

    ostringstream out;
    self.group->to_json(out);
    string str = out.str();
    
    return [NSString stringWithUTF8String:str.c_str()];
}

@end
