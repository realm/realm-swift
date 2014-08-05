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
    if (_realm.autorefresh) {
        [_realm refresh];
    }
    else {
        [_realm notifyIfChanged];
    }
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
        for (NSMapTable *map in s_realmsPerPath.allValues) {
            [map removeAllObjects];
        }
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
    NSThread *_thread;
    NSTimer *_updateTimer;
    NSMapTable *_notificationHandlers;
    
    LangBindHelper::TransactLogRegistry *_writeLogs;
    Replication *_replication;
    SharedGroup *_sharedGroup;
    
    Group *_group;
}

@synthesize inWriteTransaction = _inWriteTransaction;
@synthesize group = _group;

+ (BOOL)isCoreDebug {
    return tightdb::Version::has_feature(tightdb::feature_Debug);
}

+ (void)initialize {
    // set up global realm cache
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // initilize realm cache
        clearRealmCache();
    });
}

- (instancetype)initWithPath:(NSString *)path readOnly:(BOOL)readonly {
    self = [super init];
    if (self) {
        _path = path;
        _thread = [NSThread currentThread];
        _notificationHandlers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsWeakMemory];
        _readOnly = readonly;
        _autorefresh = YES;
    }
    return self;
}

+ (NSString *)defaultRealmPath
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_defaultRealmPath = [RLMRealm writeablePathForFile:c_defaultRealmFileName];

#if !TARGET_OS_IPHONE
        [[NSFileManager defaultManager] createDirectoryAtPath:[s_defaultRealmPath stringByDeletingLastPathComponent]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
#endif
    });
    return s_defaultRealmPath;
}

+ (NSString *)writeablePathForFile:(NSString*)fileName
{
#if TARGET_OS_IPHONE
    // On iOS the Documents directory isn't user-visible, so put files there
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#else
    // On OS X it is, so put files in Application Support. If we aren't running
    // in a sandbox, put it in a subdirectory based on the bundle identifier
    // to avoid accidentally sharing files between applications
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    if (![[NSProcessInfo processInfo] environment][@"APP_SANDBOX_CONTAINER_ID"]) {
        NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
        if ([identifier length] == 0) {
            identifier = [[[NSBundle mainBundle] executablePath] lastPathComponent];
        }
        path = [path stringByAppendingPathComponent:identifier];
    }
#endif
    return [path stringByAppendingPathComponent:fileName];
}

+ (instancetype)defaultRealm
{
    return [RLMRealm realmWithPath:[RLMRealm defaultRealmPath] readOnly:NO error:nil];
}

+ (void)useInMemoryDefaultRealm
{
    @synchronized(s_realmsPerPath) {
        if (realmsAtPath([RLMRealm defaultRealmPath]).count) {
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
    return [self realmWithPath:path readOnly:readonly dynamic:NO schema:nil error:outError];
}

+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                      dynamic:(BOOL)dynamic
                       schema:(RLMSchema *)customSchema
                        error:(NSError **)outError
{
    if (!path || path.length == 0) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Path is not valid"
                                     userInfo:@{@"path":(path ?: @"nil")}];
    }
    
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
        if (s_useInMemoryDefaultRealm && [path isEqualToString:[RLMRealm defaultRealmPath]]) { // Only for default realm
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
            return nil;
        }
        else {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:[error localizedDescription]
                                         userInfo:nil];
        }
    }
    
    // begin read
    Group &group = const_cast<Group&>(realm->_sharedGroup->begin_read());
    realm->_group = &group;

    // determine schema
    RLMSchema *schema;
    if (customSchema) {
        schema = customSchema;
    }
    else if (dynamic) {
        schema = [RLMSchema dynamicSchemaFromRealm:realm];
    }
    else {
        schema = [RLMSchema sharedSchema];
    }

    // apply schema
    [realm beginWriteTransaction];
    RLMRealmSetSchema(realm, schema);
    [realm commitWriteTransaction];
    
    // cache realm at this path if using a vanilla realm
    if (!dynamic && !customSchema) {
        cacheRealm(realm, path);
    }
    
#if !TARGET_IPHONE
    // start update timer on osx
    realm->_updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                           target:[RLMWeakTarget createWithRealm:realm]
                                                         selector:@selector(checkForUpdate)
                                                         userInfo:nil
                                                          repeats:YES];
#endif
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

            // notify other realm istances of changes
            NSArray *realms = realmsAtPath(_path);
            for (RLMRealm *realm in realms) {
                if (![realm isEqual:self]) {
                    if (realm.autorefresh) {
                        [realm performSelector:@selector(refresh) onThread:realm->_thread withObject:nil waitUntilDone:NO];
                    }
                    else {
                        [realm performSelector:@selector(notifyIfChanged) onThread:realm->_thread withObject:nil waitUntilDone:NO];
                    }
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

- (void)transactionWithBlock:(void(^)(void))block {
    [self beginWriteTransaction];
    block();
    [self commitWriteTransaction];
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

- (void)notifyIfChanged {
    try {
        // if changed notify
        if (_sharedGroup->has_changed()) { // Throws
            // send notification that someone else changed the realm
            [self sendNotifications];
        }
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
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
            
            // send notification that someone else changed the realm
            [self sendNotifications];
        }
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
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

- (void)deleteObjects:(id)array {
    if ([array isKindOfClass:NSArray.class]) {
        // for arrays and standalone delete each individually
        for (id obj in array) {
            if (RLMIsKindOfClass([obj class], "RLMObject")) {
                RLMDeleteObjectFromRealm(obj);
            }
        }
    }
    else if (RLMIsKindOfClass([array class], "RLMArray")) {
        // call deleteObjectsFromRealm for our RLMArray
        [(RLMArray *)array deleteObjectsFromRealm];
    }
    else {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid array type - container must be an RLMArray or NSArray of RLMObjects" userInfo:nil];
    }
}

- (RLMArray *)allObjects:(NSString *)objectClassName {
    return RLMGetObjects(self, objectClassName, nil, nil);
}

- (RLMArray *)objects:(NSString *)objectClassName where:(NSString *)predicateFormat, ...
{
    va_list args;
    RLM_VARARG(predicateFormat, args);
    return [self objects:objectClassName where:predicateFormat args:args];
}

- (RLMArray *)objects:(NSString *)objectClassName where:(NSString *)predicateFormat args:(va_list)args
{
    return [self objects:objectClassName withPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (RLMArray *)objects:(NSString *)objectClassName withPredicate:(NSPredicate *)predicate
{
    return RLMGetObjects(self, objectClassName, predicate, nil);
}

+ (NSError *)migrateDefaultRealmWithBlock:(RLMMigrationBlock)block {
    return [self migrateRealmAtPath:[RLMRealm defaultRealmPath] withBlock:block];
}

+ (NSError *)migrateRealmAtPath:(NSString *)realmPath withBlock:(RLMMigrationBlock)block {
    NSError *error;
    RLMMigration *migration = [RLMMigration migrationAtPath:realmPath error:&error];
    if (error) {
        return error;
    }
    [migration migrateWithBlock:block];

    // clear cache for future callers
    clearRealmCache();
    return nil;
}

@end
