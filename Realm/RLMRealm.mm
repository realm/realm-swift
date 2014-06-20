////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMObject_Private.h"
#import "RLMArray_Private.hpp"
#import "RLMMigration_Private.h"
#import "RLMObjectStore.h"
#import "RLMConstants.h"
#import "RLMQueryUtil.hpp"
#import "RLMUtil.hpp"

#include <exception>
#include <sstream>

#include <tightdb/version.hpp>
#include <tightdb/group_shared.hpp>
#include <tightdb/commit_log.hpp>
#include <tightdb/util/unique_ptr.hpp>
#include <tightdb/lang_bind_helper.hpp>

// Notification Token

@interface RLMNotificationToken ()
@property (nonatomic, strong) RLMRealm *realm;
@property (nonatomic, copy) RLMNotificationBlock block;
@end

@implementation RLMNotificationToken
- (void)dealloc
{
    if (_realm || _block) {
        NSLog(@"RLMNotificationToken released without unregistering a notification. You must hold \
              on to the RLMNotificationToken returned from addNotificationBlock and call \
              removeNotification: when you no longer wish to recieve RLMRealm notifications.");
    }
}
@end

using namespace std;
using namespace tightdb;
using namespace tightdb::util;

namespace {

// create NSException from c++ exception
void throw_objc_exception(exception &ex) {
    NSString *errorMessage = [NSString stringWithUTF8String:ex.what()];
    @throw [NSException exceptionWithName:@"RLMException" reason:errorMessage userInfo:nil];
}
 
// create NSError from c++ exception
inline NSError* make_realm_error(RLMError code, exception &ex) {
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    [details setValue:[NSString stringWithUTF8String:ex.what()] forKey:NSLocalizedDescriptionKey];
    [details setValue:@(code) forKey:@"Error Code"];
    return [NSError errorWithDomain:@"io.realm" code:code userInfo:details];
}

} // anonymous namespace


// simple weak wrapper for a weak target timer
@interface RLMWeakTarget : NSObject
+ (instancetype)createWithRealm:(id)target;
@property (nonatomic, weak) RLMRealm *realm;
@end
@implementation RLMWeakTarget
+ (instancetype)createWithRealm:(RLMRealm *)realm {
    RLMWeakTarget *wt = [RLMWeakTarget new];
    wt.realm = realm;
    return wt;
}
- (void)checkForUpdate {
    [_realm performSelector:@selector(refresh)];
}
@end


//
// Global RLMRealm instance cache
//
static NSMutableDictionary *s_realmsPerPath;

// FIXME: In the following 3 functions, we should be identifying files by the inode,device number pair
//  rather than by the path (since the path is not a reliable identifier). This requires additional support
//  from the core library though, because the inode,device number pair needs to be taken from the open file
//  (to avoid race conditions).
inline RLMRealm *cachedRealm(NSString *path) {
    mach_port_t threadID = pthread_mach_thread_np(pthread_self());
    @synchronized(s_realmsPerPath) {
        return [s_realmsPerPath[path] objectForKey:@(threadID)];
    }
}

inline void cacheRealm(RLMRealm *realm, NSString *path) {
    mach_port_t threadID = pthread_mach_thread_np(pthread_self());
    @synchronized(s_realmsPerPath) {
        if (!s_realmsPerPath[path]) {
            s_realmsPerPath[path] = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsObjectPersonality valueOptions:NSPointerFunctionsWeakMemory];
        }
        [s_realmsPerPath[path] setObject:realm forKey:@(threadID)];
    }
}

inline NSArray *realmsAtPath(NSString *path) {
    @synchronized(s_realmsPerPath) {
        return [s_realmsPerPath[path] objectEnumerator].allObjects;
    }
}

inline void clearRealmCache() {
    @synchronized(s_realmsPerPath) {
        s_realmsPerPath = [NSMutableDictionary dictionary];
    }
}

@interface RLMRealm ()
@property (nonatomic) NSString *path;
@end


NSString *const c_defaultRealmFileName = @"default.realm";
static BOOL s_useInMemoryDefaultRealm = NO;
static NSString *s_defaultRealmPath = nil;
static NSArray *s_objectDescriptors = nil;

@implementation RLMRealm {
    NSMapTable *_objects;
    NSRunLoop *_runLoop;
    NSTimer *_updateTimer;
    NSMapTable *_notificationHandlers;
    
    LangBindHelper::TransactLogRegistry *_writeLogs;
    Replication *_replication;
    SharedGroup *_sharedGroup;
    
    Group *_group;
}

+ (BOOL)isCoreDebug {
    return tightdb::Version::has_feature(tightdb::feature_Debug);
}

+ (void)initialize {
    // set up global realm cache
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // initilize realm cache
        clearRealmCache();
        
        // initialize object store
        RLMInitializeObjectStore();
    });
}

- (instancetype)initWithPath:(NSString *)path readOnly:(BOOL)readonly {
    self = [super init];
    if (self) {
        _path = path;
        _runLoop = [NSRunLoop currentRunLoop];
        _objects = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsOpaquePersonality
                                             valueOptions:NSPointerFunctionsWeakMemory
                                                 capacity:128];
        _notificationHandlers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsWeakMemory];
        _readOnly = readonly;
        _updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                        target:[RLMWeakTarget createWithRealm:self]
                                                      selector:@selector(checkForUpdate)
                                                      userInfo:nil
                                                       repeats:YES];
    }
    return self;
}

+(NSString *)defaultPath
{
    return s_defaultRealmPath;
}

+ (NSString *)writeablePathForFile:(NSString*)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

+ (instancetype)defaultRealm
{
    if (!s_defaultRealmPath) {
        s_defaultRealmPath = [RLMRealm writeablePathForFile:c_defaultRealmFileName];
    }
    return [RLMRealm realmWithPath:RLMRealm.defaultPath readOnly:NO error:nil];
}

+ (void)setDefaultRealmPath:(NSString *)path
{
    // if already set then throw
    @synchronized(s_realmsPerPath) {
        if (s_realmsPerPath.count) {
            @throw [NSException exceptionWithName:@"RLMException" reason:@"Can only set default realm path before creating or getting an RLMRealm instance" userInfo:nil];
        }
    }
    s_defaultRealmPath = path;
}

+ (void)useInMemoryDefaultRealm
{
    @synchronized(s_realmsPerPath) {
        if (realmsAtPath(RLMRealm.defaultPath).count) {
            @throw [NSException exceptionWithName:@"RLMException" reason:@"Can only set default realm to use in Memory before creating or getting a default RLMRealm instance" userInfo:nil];
        }
    }
    s_useInMemoryDefaultRealm = YES;
}

+ (instancetype)realmWithPath:(NSString *)path
{
    return [self realmWithPath:path readOnly:NO error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                        error:(NSError **)outError
{
    return [self realmWithPath:path readOnly:readonly dynamic:NO error:outError];
}

+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                      dynamic:(BOOL)dynamic
                        error:(NSError **)outError
{
    NSRunLoop *currentRunloop = [NSRunLoop currentRunLoop];
    if (!currentRunloop) {
        @throw [NSException exceptionWithName:@"realm:runloop_exception"
                                       reason:[NSString stringWithFormat:@"%@ \
                                               can only be called from a thread with a runloop.",
                                               NSStringFromSelector(_cmd)] userInfo:nil];
    }
    
    // try to reuse existing realm first
    RLMRealm *realm = cachedRealm(path);
    if (realm) {
        // if already opened with different read permissions then throw
        if (realm.isReadOnly != readonly) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Realm at path already opened with different read permissions"
                                         userInfo:@{@"path":realm.path}];
        }
        return realm;
    }
    
    realm = [[RLMRealm alloc] initWithPath:path readOnly:readonly];
    if (!realm) {
        return nil;
    }
    
    NSError *error = nil;
    try {
        if (s_useInMemoryDefaultRealm && [path isEqualToString:RLMRealm.defaultPath]) { // Only for default realm
            realm->_sharedGroup = new SharedGroup(path.UTF8String, false, SharedGroup::durability_MemOnly);
        } else {
        	realm->_writeLogs = tightdb::getWriteLogs(path.UTF8String);
        	realm->_replication = tightdb::makeWriteLogCollector(path.UTF8String);
        	realm->_sharedGroup = new SharedGroup(*realm->_replication);
        }
    }
    catch (File::PermissionDenied &ex) {
        error = make_realm_error(RLMErrorFilePermissionDenied, ex);
    }
    catch (File::Exists &ex) {
        error = make_realm_error(RLMErrorFileExists, ex);
    }
    catch (File::AccessError &ex) {
        error = make_realm_error(RLMErrorFileAccessError, ex);
    }
    catch (SharedGroup::PresumablyStaleLockFile &ex) {
        error = make_realm_error(RLMErrorStaleLockFile, ex);
    }
    catch (SharedGroup::LockFileButNoData &ex) {
        error = make_realm_error(RLMErrorLockFileButNoData, ex);
    }
    catch (exception &ex) {
        error = make_realm_error(RLMErrorFail, ex);
    }
    if (error) {
        if (outError) {
            *outError = error;
        }
        else {
            // if no error provided, throw
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Error while opening the Realm"
                                         userInfo:error.userInfo];
        }
        return nil;
    }
    
    // begin read
    Group &group = const_cast<Group&>(realm->_sharedGroup->begin_read());
    realm->_group = &group;
    
    if (dynamic) {
        // for dynamic realms, get schema from stored tables
        realm->_schema = [RLMSchema dynamicSchemaFromRealm:realm];
    }
    else {
        // set the schema for this realm
        realm.schema = [RLMSchema sharedSchema];

        // initialize object store for this realm
        RLMVerifyAndCreateTables(realm);
        
        // cache main thread realm at this path
        cacheRealm(realm, path);
    }
    
    return realm;
}

+ (void)clearRealmCache {
    clearRealmCache();
}

- (RLMNotificationToken *)addNotificationBlock:(RLMNotificationBlock)block {
    RLMNotificationToken *token = [[RLMNotificationToken alloc] init];
    token.realm = self;
    token.block = block;
    [_notificationHandlers setObject:token forKey:token];
    return token;
}

- (void)removeNotification:(RLMNotificationToken *)token {
    if (token) {
        [_notificationHandlers removeObjectForKey:token];
        token.realm = nil;
        token.block = nil;
    }
}

- (void)sendNotifications {
    // call this realms notification blocks
    for (RLMNotificationToken *token in _notificationHandlers) {
        token.block(RLMRealmDidChangeNotification, self);
    }
}

- (void)beginWriteTransaction {
    if (!self.inWriteTransaction) {
        try {
            // if we are moving the transaction forward, send local notifications
            if (_sharedGroup->has_changed()) {
                [self sendNotifications];
            }
            
            // upgratde to write
            LangBindHelper::promote_to_write(*_sharedGroup, *_writeLogs);
            
            // update state and make all objects in this realm writable
            _inWriteTransaction = YES;
            [self updateAllObjects];
        }
        catch (std::exception& ex) {
            // File access errors are treated as exceptions here since they should not occur after the shared
            // group has already been successfully opened on the file and memory mapped. The shared group constructor handles
            // the excepted error related to file access.
            throw_objc_exception(ex);
        }
    } else {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"The Realm is already in a writetransaction" userInfo:nil];
    }
}

- (void)commitWriteTransaction {
    if (self.inWriteTransaction) {
        try {
            LangBindHelper::commit_and_continue_as_read(*_sharedGroup);
            
            // update state and make all objects in this realm read-only
            _inWriteTransaction = NO;
            [self updateAllObjects];
            
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
    } else {
       @throw [NSException exceptionWithName:@"RLMException" reason:@"Can't commit a non-existing writetransaction" userInfo:nil];
    }
}

/*
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
    } else {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Can't roll-back a non-existing writetransaction" userInfo:nil];
    }
}*/

- (void)dealloc
{
    [_updateTimer invalidate];
    _updateTimer = nil;
    
    if (self.inWriteTransaction) {
        [self commitWriteTransaction];
        NSLog(@"A transaction was lacking explicit commit, but it has been auto committed.");
    }
    
    if (_sharedGroup) {
        delete _sharedGroup;
    }
    if (_replication) {
        delete _replication;
    }
    if (_writeLogs) {
        delete _writeLogs;
    }
}

- (void)refresh {
    try {
        // no-op if writing
        if (self.inWriteTransaction) {
            return;
        }
        
        // advance transaction if database has changed
        if (_sharedGroup->has_changed()) { // Throws
            LangBindHelper::advance_read(*_sharedGroup, *_writeLogs);
            [self updateAllObjects];
            
            // send notification that someone else changed the realm
            [self sendNotifications];
        }
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
}

- (void)registerAccessor:(id<RLMAccessor>)accessor {
    [_objects setObject:accessor forKey:accessor];
}

- (void)updateAllObjects {
    try {
        // refresh all outstanding objects
        for (id<RLMAccessor> obj in _objects.objectEnumerator.allObjects) {
            if ([obj isKindOfClass:RLMObject.class]) {
                if (!((RLMObject *)obj)->_row.is_attached()) {
                    obj.RLMAccessor_invalid = YES;
                    continue; // don't change writeable one invalid
                }
            }
            else if([obj isKindOfClass:RLMArrayLinkView.class]) {
                if (!((RLMArrayLinkView *)obj)->_backingLinkView->is_attached()) {
                    obj.RLMAccessor_invalid = YES;
                    continue; // don't change writeable one invalid
                }
            }
            obj.RLMAccessor_writable = _inWriteTransaction;
        }
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
}

- (tightdb::Group *)group {
    return _group;
}

- (void)addObject:(RLMObject *)object {
    RLMAddObjectToRealm(object, self);
}

- (void)addObjectsFromArray:(id)array {
    for (RLMObject *obj in array) {
        [self addObject:obj];
    }
}

- (void)deleteObject:(RLMObject *)object {
    RLMDeleteObjectFromRealm(object);
}

- (RLMArray *)allObjects:(NSString *)objectClassName {
    return RLMGetObjects(self, objectClassName, nil, nil);
}

- (RLMArray *)objects:(NSString *)objectClassName withPredicateFormat:(NSString *)predicateFormat, ...
{
    NSPredicate *outPredicate = nil;
    RLM_PREDICATE(predicateFormat, outPredicate);
    return [self objects:objectClassName withPredicate:outPredicate];
}

- (RLMArray *)objects:(NSString *)objectClassName withPredicate:(NSPredicate *)predicate
{
    return RLMGetObjects(self, objectClassName, predicate, nil);
}

+ (void)applyMigrationBlock:(RLMMigrationBlock)block error:(NSError *__autoreleasing *)error {
    [self applyMigrationBlock:block atPath:[RLMRealm defaultPath] error:error];
}

+(void)applyMigrationBlock:(RLMMigrationBlock)block atPath:(NSString *)realmPath error:(NSError *__autoreleasing *)error {
    RLMMigration *migration = [RLMMigration migrationAtPath:realmPath error:error];
    if (error) {
        return;
    }
    
    // start write transaction
    [migration.realm beginWriteTransaction];
    
    // apply block and set new schema version
    NSInteger oldVersion = RLMRealmSchemaVersion(migration.realm);
    NSUInteger newVersion = block(migration, oldVersion);
    RLMRealmSetSchemaVersion(migration.realm, newVersion);
   
    // end transaction
    [migration.realm commitWriteTransaction];
}


@end
