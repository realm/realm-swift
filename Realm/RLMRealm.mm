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
#import "RLMConstants.h"
#import "RLMObjectStore.hpp"
#import "RLMQueryUtil.hpp"
#import "RLMUpdateChecker.hpp"
#import "RLMUtil.hpp"

#include <exception>

#include <tightdb/version.hpp>
#include <tightdb/group_shared.hpp>
#include <tightdb/commit_log.hpp>
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

// A weak holder for an RLMRealm to allow calling performSelector:onThread: without
// a strong reference to the realm
@interface RLMWeakNotifier : NSObject
@property (nonatomic, weak) RLMRealm *realm;

- (instancetype)initWithRealm:(RLMRealm *)realm;
- (void)notify;
@end

using namespace std;
using namespace tightdb;
using namespace tightdb::util;

namespace {

// create NSException from c++ exception
__attribute__((noreturn)) void throw_objc_exception(exception &ex) {
    NSString *errorMessage = [NSString stringWithUTF8String:ex.what()];
    @throw [NSException exceptionWithName:@"RLMException" reason:errorMessage userInfo:nil];
}

// create NSError from c++ exception
NSError *make_realm_error(RLMError code, exception &ex) {
    NSMutableDictionary *details = [NSMutableDictionary dictionary];
    [details setValue:[NSString stringWithUTF8String:ex.what()] forKey:NSLocalizedDescriptionKey];
    [details setValue:@(code) forKey:@"Error Code"];
    return [NSError errorWithDomain:@"io.realm" code:code userInfo:details];
}

//
// Global RLMRealm instance cache
//
NSMutableDictionary *s_realmsPerPath;

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

void clearRealmCache() {
    @synchronized(s_realmsPerPath) {
        for (NSMapTable *map in s_realmsPerPath.allValues) {
            [map removeAllObjects];
        }
        s_realmsPerPath = [NSMutableDictionary dictionary];
    }
}

void createTablesInTransaction(RLMRealm *realm, RLMSchema *targetSchema) {
    [realm beginWriteTransaction];

    @try {
        if (RLMRealmSchemaVersion(realm) == RLMNotVersioned) {
            RLMRealmSetSchemaVersion(realm, 0);
        }
        RLMRealmCreateTables(realm, targetSchema, false);
    }
    @finally {
        // FIXME: should rollback on exceptions rather than commit once that's implemented
        [realm commitWriteTransaction];
    }
}


static NSString *s_defaultRealmPath = nil;
static RLMMigrationBlock s_migrationBlock;
static NSUInteger s_currentSchemaVersion = 0;

NSMutableArray *s_uploadToServerInProgress = [NSMutableArray arrayWithObject:@NO];

} // anonymous namespace

NSString * const c_defaultRealmFileName = @"default.realm";

@implementation RLMRealm {
    // Used for read-write realms
    NSThread *_thread;
    NSMapTable *_notificationHandlers;

    std::unique_ptr<Replication> _replication;
    std::unique_ptr<SharedGroup> _sharedGroup;

    // Used for read-only realms
    std::unique_ptr<Group> _readGroup;

    // Used for both
    Group *_group;
    BOOL _readOnly;
    BOOL _inMemory;

    NSURLSession *_URLSession;
}

+ (BOOL)isCoreDebug {
    return tightdb::Version::has_feature(tightdb::feature_Debug);
}

+ (void)initialize {
    // set up global realm cache
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RLMCheckForUpdates();

        // initilize realm cache
        clearRealmCache();
    });
}

- (instancetype)initWithPath:(NSString *)path readOnly:(BOOL)readonly inMemory:(BOOL)inMemory error:(NSError **)error {
    self = [super init];
    if (self) {
        _path = path;
        _thread = [NSThread currentThread];
        _threadID = pthread_mach_thread_np(pthread_self());
        _notificationHandlers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsWeakMemory];
        _readOnly = readonly;
        _inMemory = inMemory;
        _autorefresh = YES;
        _serverBaseURL = @"http://192.168.1.50:8080"; // Kristains workstation

        try {
            if (readonly) {
                _readGroup = make_unique<Group>(path.UTF8String);
                _group = _readGroup.get();
            }
            else {
                _replication.reset(tightdb::makeWriteLogCollector(path.UTF8String));
                SharedGroup::DurabilityLevel durability = inMemory ? SharedGroup::durability_MemOnly :
                                                                     SharedGroup::durability_Full;
                _sharedGroup = make_unique<SharedGroup>(*_replication, durability);
                _group = &const_cast<Group&>(_sharedGroup->begin_read());
            }
        }
        catch (File::PermissionDenied &ex) {
            *error = make_realm_error(RLMErrorFilePermissionDenied, ex);
        }
        catch (File::Exists &ex) {
            *error = make_realm_error(RLMErrorFileExists, ex);
        }
        catch (File::AccessError &ex) {
            *error = make_realm_error(RLMErrorFileAccessError, ex);
        }
        catch (SharedGroup::PresumablyStaleLockFile &ex) {
            *error = make_realm_error(RLMErrorStaleLockFile, ex);
        }
        catch (SharedGroup::LockFileButNoData &ex) {
            *error = make_realm_error(RLMErrorLockFileButNoData, ex);
        }
        catch (exception &ex) {
            *error = make_realm_error(RLMErrorFail, ex);
        }
    }
    return self;
}

+ (NSString *)defaultRealmPath
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_defaultRealmPath = [RLMRealm writeablePathForFile:c_defaultRealmFileName];
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

        // create directory
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
#endif
    return [path stringByAppendingPathComponent:fileName];
}

+ (instancetype)defaultRealm
{
    return [RLMRealm realmWithPath:[RLMRealm defaultRealmPath] readOnly:NO error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path
{
    return [self realmWithPath:path readOnly:NO error:nil];
}

+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                        error:(NSError **)outError
{
    return [self realmWithPath:path readOnly:readonly inMemory:NO dynamic:NO schema:nil error:outError];
}

+ (instancetype)inMemoryRealmWithIdentifier:(NSString *)identifier {
    return [self realmWithPath:[RLMRealm writeablePathForFile:identifier] readOnly:NO inMemory:YES dynamic:NO schema:nil error:nil];
}


- (void)initialBlockingSyncWithServer {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.name = @"io.Realm.sync";

    // Emphemeral config disables everything that would result in data being automatically saved to disk
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];

    // Disable caching
    config.URLCache = nil;
    config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

    config.HTTPShouldUsePipelining = YES;

    _URLSession = [NSURLSession sessionWithConfiguration:config
                                                 delegate:nil
                                            delegateQueue:queue];

    // At the present time we need to apply foreign transaction logs
    // via a special SharedGroup instance on which replication is not
    // enabled. This is necessary because some (not all) of the
    // actions taken during transaction log application submits new
    // entries to a new transaction log.
    UniquePtr<Replication> transactLogRegistry(makeWriteLogCollector(self.path.UTF8String));
    SharedGroup sharedGroup(self.path.UTF8String);

    Replication::version_type lastVersionUploaded, lastVersionAvailable;
    lastVersionUploaded = transactLogRegistry->get_last_version_synced(&lastVersionAvailable);
    TIGHTDB_ASSERT(lastVersionUploaded <= lastVersionAvailable);
    Replication::version_type currentVersion = LangBindHelper::get_current_version(sharedGroup);
    TIGHTDB_ASSERT(currentVersion == lastVersionAvailable);

    // Never ask for next transaction log while upload is in
    // progress. If we do that, we risk getting something back even
    // when the upload in progress is in conflict with somebody elses
    // transaction, and in that case the received transaction log
    // would be corrupt from our point of view.
    typedef unsigned long long ulonglong;
    if (lastVersionUploaded < currentVersion) {
        NSLog(@"Skipping initial blocking sync with server due to pending uploads (%llu<%llu)",
              ulonglong(lastVersionUploaded), ulonglong(currentVersion));
        return;
    }

    int maxRetries = 16;
    int numRetries = 0;
    __block NSMutableArray *upToDate = [NSMutableArray arrayWithObject:@NO];
    for (;;) {
        __block NSMutableArray *responseData = [NSMutableArray array];
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSString *url = [NSString stringWithFormat:@"%@/receive/%llu", self.serverBaseURL, ulonglong(currentVersion)];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        request.HTTPMethod = @"POST";
        [[_URLSession dataTaskWithRequest:request
                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                    if (error) {
                        NSLog(@"HTTP receive request failed (1)");
                    }
                    else if (((NSHTTPURLResponse *)response).statusCode != 200) {
                        NSLog(@"HTTP receive request failed (2)");
                    }
                    else {
                        // FIXME: Using the MIME type in this way is
                        // not reliable as it may in general be
                        // modified in complicated ways by various
                        // involved HTTP agents.
                        if (!response.MIMEType) {
                            NSLog(@"HTTP receive request failed (3)");
                        }
                        else if ([response.MIMEType isEqualToString:@"text/plain"]) {
                            NSData *upToDateString = [NSData dataWithBytesNoCopy:(void *)"up-to-date"
                                                                          length:10
                                                                    freeWhenDone:NO];
                            if ([data isEqualToData:upToDateString]) {
                                upToDate[0] = @YES;
                            }
                            else {
                                NSLog(@"HTTP receive request failed (4)");
                            }
                        }
                        else if ([response.MIMEType isEqualToString:@"application/octet-stream"]) {
                            // Assuming that `data` needs to be copied
                            // here to make it available outside the
                            // completion handler.
                            responseData[0] = [data copy];
                        }
                    }
                    dispatch_semaphore_signal(semaphore);
                }] resume];

        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

        if (((NSNumber *)upToDate[0]).boolValue)
            break;

        if (!responseData.firstObject) {
            if (numRetries == maxRetries)
                @throw [NSException exceptionWithName:@"RLMException"
                                               reason:@"Too many HTTP request failures"
                                             userInfo:nil];
            ++numRetries;
            continue;
        }

        // Apply transaction log via the special SharedGroup instance
        Replication::version_type receivedVersion = currentVersion + 1;
        NSData *data = responseData.firstObject;
        {
            WriteTransaction transact(sharedGroup);
            Replication::SimpleInputStream input((const char *)data.bytes, size_t(data.length));
            try {
                Replication::apply_transact_log(input, transact.get_group()); // Throws
            }
            catch (Replication::BadTransactLog&) {
                ++numRetries;
                continue;
            }
            BinaryData transactLog((const char *)data.bytes, size_t(data.length));
            @synchronized(s_uploadToServerInProgress) {
                transactLogRegistry->submit_transact_log(transactLog);
                transactLogRegistry->set_last_version_synced(receivedVersion);
            }
        }
        currentVersion = receivedVersion;
        numRetries = 0;
    }
}


+ (instancetype)realmWithPath:(NSString *)path
                     readOnly:(BOOL)readonly
                     inMemory:(BOOL)inMemory
                      dynamic:(BOOL)dynamic
                       schema:(RLMSchema *)customSchema
                        error:(NSError **)outError
{
    if (!path || path.length == 0) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Path is not valid"
                                     userInfo:@{@"path":(path ?: @"nil")}];
    }

    if (![NSRunLoop currentRunLoop]) {
        @throw [NSException exceptionWithName:@"realm:runloop_exception"
                                       reason:[NSString stringWithFormat:@"%@ \
                                               can only be called from a thread with a runloop.",
                                               NSStringFromSelector(_cmd)] userInfo:nil];
    }

    // try to reuse existing realm first
    __autoreleasing RLMRealm *realm = cachedRealm(path);
    if (realm) {
        // if already opened with different read permissions then throw
        if (realm->_readOnly != readonly) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Realm at path already opened with different read permissions"
                                         userInfo:@{@"path":realm.path}];
        }
        if (realm->_inMemory != inMemory) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Realm at path already opened with different inMemory settings"
                                         userInfo:@{@"path":realm.path}];
        }
        return realm;
    }

    NSError *error = nil;
    realm = [[RLMRealm alloc] initWithPath:path readOnly:readonly inMemory:inMemory error:&error];

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

    if (!realm) {
        return nil;
    }

    // set the schema
    if (customSchema) {
        createTablesInTransaction(realm, customSchema);
    }
    else if (dynamic) {
        createTablesInTransaction(realm, [RLMSchema dynamicSchemaFromRealm:realm]);
    }
    else if (readonly) {
        if (RLMRealmSchemaVersion(realm) == RLMNotVersioned) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Cannot open an uninitialized realm in read-only mode"
                                         userInfo:nil];
        }
        RLMRealmSetSchema(realm, [RLMSchema sharedSchema]);
        cacheRealm(realm, path);
    }
    else {
        // check cache for existing cached realms with the same path
        @synchronized(s_realmsPerPath) {
            NSArray *realms = realmsAtPath(path);
            if (realms.count) {
                // advance read in case another instance initialized the schema
                LangBindHelper::advance_read(*realm->_sharedGroup);

                // if we have a cached realm on another thread, copy without a transaction
                RLMRealmSetSchema(realm, [realms[0] schema], false);
            }
            else {
                // Synchronize with server and block here until
                // synchronization is complete.
                //
                // This is done to ensure that only one client submits
                // a transaction that creates the schema for
                // compile-time specified Realm classes. If all
                // clients did that, there would be an immediate need
                // for conflict resolution, but in the first (proto)
                // implementation of client-server synchronization,
                // conflict resolution will not be available.
                //
                // This kind of blocking is obviously not good enough,
                // especially when it occurs on the main thread, so
                // some kind of nonblocking alternative has to be
                // found.
                //
                // When transaction merging becomes possible, this
                // problem disappears completely, becasue then all the
                // initial schema creating transactions can be merged.
                [realm initialBlockingSyncWithServer];

                // if we are the first realm at this path, set/align schema or perform migration if needed
                NSUInteger schemaVersion = RLMRealmSchemaVersion(realm);
                if (s_currentSchemaVersion == schemaVersion || schemaVersion == RLMNotVersioned) {
                    createTablesInTransaction(realm, [RLMSchema sharedSchema]);
                }
                else {
                    [RLMRealm migrateRealm:realm];
                }
            }

            // cache only realms using a shared schema
            cacheRealm(realm, path);
        }
    }

    [realm resumeUploadToServer];

    return realm;
}

+ (void)resetRealmState {
    s_currentSchemaVersion = 0;
    s_migrationBlock = NULL;
    clearRealmCache();
}

static void CheckReadWrite(RLMRealm *realm, NSString *msg=@"Cannot write to a read-only Realm") {
    if (realm->_readOnly) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:msg
                                     userInfo:nil];
    }
}


- (void)resumeUploadToServer {
    Replication::version_type lastVersionUploaded, lastVersionAvailable;

    @synchronized(s_uploadToServerInProgress) {
        if (((NSNumber *)s_uploadToServerInProgress[0]).boolValue)
            return;

        lastVersionUploaded = _replication->get_last_version_synced(&lastVersionAvailable);
        if (lastVersionUploaded == lastVersionAvailable)
            return;

        s_uploadToServerInProgress[0] = @YES;
    }

    BinaryData transact_log;
    _replication->get_commit_entries(lastVersionUploaded, lastVersionUploaded+1, &transact_log);
    NSData *data = [NSData dataWithBytes:transact_log.data() length:transact_log.size()];
    [self uploadToServer:data version:lastVersionUploaded+1 numRetries:0];
}


- (void)uploadToServer:(NSData *)data version:(Replication::version_type)version numRetries:(int)numRetries {
    int maxRetries = 16;
    typedef unsigned long long ulonglong;
    NSString *url = [NSString stringWithFormat:@"%@/send/%llu", self.serverBaseURL, ulonglong(version)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    [[_URLSession uploadTaskWithRequest:request
                               fromData:data
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error) {
                    NSLog(@"HTTP send request failed (1)");
                }
                else if (((NSHTTPURLResponse *)response).statusCode != 200) {
                    NSLog(@"HTTP send request failed (2)");
                }
                else {
                    // FIXME: Using the MIME type in this way is
                    // not reliable as it may in general be
                    // modified in complicated ways by various
                    // involved HTTP agents.
                    if (!response.MIMEType) {
                        NSLog(@"HTTP send request failed (3)");
                    }
                    else if ([response.MIMEType isEqualToString:@"text/plain"]) {
                        NSData *upToDateString = [NSData dataWithBytesNoCopy:(void *)"ok"
                                                                      length:2
                                                                freeWhenDone:NO];
                        if ([data isEqualToData:upToDateString]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                    _replication->set_last_version_synced(version);
                                    @synchronized(s_uploadToServerInProgress) {
                                        s_uploadToServerInProgress[0] = @NO;
                                    }
                                    [self resumeUploadToServer];
                                });
                            return;
                        }
                        NSData *conflictString = [NSData dataWithBytesNoCopy:(void *)"conflict"
                                                                      length:8
                                                                freeWhenDone:NO];
                        if ([data isEqualToData:conflictString])
                            @throw [NSException exceptionWithName:@"RLMException"
                                                           reason:@"Conflicting transaction detected"
                                                         userInfo:nil];
                        NSLog(@"HTTP send request failed (4)");
                    }
                }
                if (numRetries == maxRetries)
                    NSLog(@"Too many failed HTTP send requests, giving up");
                    return;
                dispatch_async(dispatch_get_main_queue(), ^{
                        [self uploadToServer:data version:version numRetries:numRetries+1];
                    });
            }] resume];
}


- (RLMNotificationToken *)addNotificationBlock:(RLMNotificationBlock)block {
    RLMCheckThread(self);
    CheckReadWrite(self, @"Read-only Realms do not change and do not have change notifications");
    if (!block) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"The notification block should not be nil" userInfo:nil];
    }

    RLMNotificationToken *token = [[RLMNotificationToken alloc] init];
    token.realm = self;
    token.block = block;
    [_notificationHandlers setObject:token forKey:token];
    return token;
}

- (void)removeNotification:(RLMNotificationToken *)token {
    RLMCheckThread(self);
    if (token) {
        [_notificationHandlers removeObjectForKey:token];
        token.realm = nil;
        token.block = nil;
    }
}

- (void)sendNotifications:(NSString *)notification {
    NSAssert(!_readOnly, @"Read-only realms do not have notifications");

    // call this realms notification blocks
    for (RLMNotificationToken *token in [_notificationHandlers copy]) {
        if (token.block) {
            token.block(notification, self);
        }
    }
}

- (void)beginWriteTransaction {
    CheckReadWrite(self);
    RLMCheckThread(self);

    if (!self.inWriteTransaction) {
        try {
            // if the upgrade to write will move the transaction forward,
            // announce the change after promoting
            bool announce = _sharedGroup->has_changed();

            LangBindHelper::promote_to_write(*_sharedGroup);

            if (announce) {
                [self sendNotifications:RLMRealmDidChangeNotification];
            }

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
    CheckReadWrite(self);
    RLMCheckThread(self);

    if (self.inWriteTransaction) {
        try {
            LangBindHelper::commit_and_continue_as_read(*_sharedGroup);

            // update state and make all objects in this realm read-only
            _inWriteTransaction = NO;

            // notify other realm istances of changes
            NSArray *realms = realmsAtPath(_path);
            for (RLMRealm *realm in realms) {
                if (![realm isEqual:self]) {
                    RLMWeakNotifier *notifier = [[RLMWeakNotifier alloc] initWithRealm:realm];
                    [notifier performSelector:@selector(notify)
                                     onThread:realm->_thread withObject:nil waitUntilDone:NO];
                }
            }

            // send local notification
            [self sendNotifications:RLMRealmDidChangeNotification];

            [self resumeUploadToServer];
        }
        catch (std::exception& ex) {
            throw_objc_exception(ex);
        }
    } else {
       @throw [NSException exceptionWithName:@"RLMException" reason:@"Can't commit a non-existing write transaction" userInfo:nil];
    }
}

- (void)transactionWithBlock:(void(^)(void))block {
    [self beginWriteTransaction];
    block();
    if (_inWriteTransaction) {
        [self commitWriteTransaction];
    }
}

- (void)cancelWriteTransaction {
    CheckReadWrite(self);
    RLMCheckThread(self);

    if (self.inWriteTransaction) {
        try {
            LangBindHelper::rollback_and_continue_as_read(*_sharedGroup);
            _inWriteTransaction = NO;
        }
        catch (std::exception& ex) {
            throw_objc_exception(ex);
        }
    } else {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Can't cancel a non-existing write transaction" userInfo:nil];
    }
}

- (void)dealloc {
    if (_inWriteTransaction) {
        [self commitWriteTransaction];
        NSLog(@"A transaction was lacking explicit commit, but it has been auto committed.");
    }
}

- (void)handleExternalCommit {
    RLMCheckThread(self);
    NSAssert(!_readOnly, @"Read-only realms do not have notifications");
    try {
        if (_sharedGroup->has_changed()) { // Throws
            if (_autorefresh) {
                LangBindHelper::advance_read(*_sharedGroup);
                [self sendNotifications:RLMRealmDidChangeNotification];
            }
            else {
                [self sendNotifications:RLMRealmRefreshRequiredNotification];
            }
        }
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
}

- (BOOL)refresh {
    RLMCheckThread(self);
    CheckReadWrite(self, @"Cannot refresh a read-only realm (external modifications to read only realms are not supported)");

    // can't be any new changes if we're in a write transaction
    if (self.inWriteTransaction) {
        return NO;
    }

    try {
        // advance transaction if database has changed
        if (_sharedGroup->has_changed()) { // Throws
            LangBindHelper::advance_read(*_sharedGroup);
            [self sendNotifications:RLMRealmDidChangeNotification];
            return YES;
        }
        return NO;
    }
    catch (exception &ex) {
        throw_objc_exception(ex);
    }
}

- (void)addObject:(RLMObject *)object {
    RLMAddObjectToRealm(object, self);
}

- (void)addObjects:(id<NSFastEnumeration>)array {
    for (RLMObject *obj in array) {
        if (![obj isKindOfClass:[RLMObject class]]) {
            NSString *msg = [NSString stringWithFormat:@"Cannot insert objects of type %@ with addObjects:. Only RLMObjects are supported.", NSStringFromClass(obj.class)];
            @throw [NSException exceptionWithName:@"RLMException" reason:msg userInfo:nil];
        }
        [self addObject:obj];
    }
}

- (void)addOrUpdateObject:(RLMObject *)object {
    // verify primary key
    if (!object.objectSchema.primaryKeyProperty) {
        NSString *reason = [NSString stringWithFormat:@"'%@' does not have a primary key and can not be updated", object.objectSchema.className];
        @throw [NSException exceptionWithName:@"RLMExecption" reason:reason userInfo:nil];
    }

    RLMAddObjectToRealm(object, self, RLMSetFlagUpdateOrCreate);
}

- (void)addOrUpdateObjectsFromArray:(id)array {
    for (RLMObject *obj in array) {
        [self addOrUpdateObject:obj];
    }
}

- (void)deleteObject:(RLMObject *)object {
    RLMDeleteObjectFromRealm(object, self);
}

- (void)deleteObjects:(id)array {
    if (NSArray *nsArray = RLMDynamicCast<NSArray>(array)) {
        // for arrays and standalone delete each individually
        for (id obj in nsArray) {
            if ([obj isKindOfClass:RLMObject.class]) {
                RLMDeleteObjectFromRealm(obj, self);
            }
        }
    }
    else if (RLMArray *rlmArray = RLMDynamicCast<RLMArray>(array)) {
        // call deleteObjectsFromRealm for our RLMArray
        [rlmArray deleteObjectsFromRealm];
    }
    else if (RLMResults *rlmResults = RLMDynamicCast<RLMResults>(array)) {
        // call deleteObjectsFromRealm for our RLMResults
        [rlmResults deleteObjectsFromRealm];
    }
    else {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid array type - container must be an RLMArray, RLMArray, or NSArray of RLMObjects" userInfo:nil];
    }
}

- (void)deleteAllObjects {
    RLMDeleteAllObjectsFromRealm(self);
}

- (RLMResults *)allObjects:(NSString *)objectClassName {
    return RLMGetObjects(self, objectClassName, nil);
}

- (RLMResults *)objects:(NSString *)objectClassName where:(NSString *)predicateFormat, ... {
    va_list args;
    RLM_VARARG(predicateFormat, args);
    return [self objects:objectClassName where:predicateFormat args:args];
}

- (RLMResults *)objects:(NSString *)objectClassName where:(NSString *)predicateFormat args:(va_list)args {
    return [self objects:objectClassName withPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (RLMResults *)objects:(NSString *)objectClassName withPredicate:(NSPredicate *)predicate {
    return RLMGetObjects(self, objectClassName, predicate);
}

+ (void)setSchemaVersion:(NSUInteger)version withMigrationBlock:(RLMMigrationBlock)block {
    s_currentSchemaVersion = version;
    s_migrationBlock = block;
}

+ (NSError *)migrateRealmAtPath:(NSString *)realmPath {
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithPath:realmPath readOnly:NO inMemory:NO dynamic:YES schema:nil error:&error];
    if (error) {
        return error;
    }

    return [self migrateRealm:realm];
}

+ (NSError *)migrateRealm:(RLMRealm *)realm {
    NSError *error;
    RLMMigration *migration = [RLMMigration migrationForRealm:realm error:&error];
    if (error) {
        return error;
    }

    // only perform migration if current version is > on-disk version
    NSUInteger schemaVersion = RLMRealmSchemaVersion(migration.realm);
    if (schemaVersion < s_currentSchemaVersion) {
        [migration migrateWithBlock:s_migrationBlock version:s_currentSchemaVersion];
    }
    else if (schemaVersion > s_currentSchemaVersion && schemaVersion != RLMNotVersioned) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Realm version is higher than the current version provided to `setSchemaVersion:withMigrationBlock:`"
                                     userInfo:@{@"path" : migration.realm.path}];
    }

    // clear cache for future callers
    clearRealmCache();
    return nil;
}

- (RLMObject *)createObject:(NSString *)className withObject:(id)object {
    return RLMCreateObjectInRealmWithValue(self, className, object);
}

@end

@implementation RLMWeakNotifier
- (instancetype)initWithRealm:(RLMRealm *)realm
{
    self = [super init];
    if (self) {
        _realm = realm;
    }
    return self;
}

- (void)notify
{
    [_realm handleExternalCommit];
}
@end
