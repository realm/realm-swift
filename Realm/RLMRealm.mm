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
#import "RLMObjectSchema_Private.hpp"
#import "RLMQueryUtil.hpp"
#import "RLMUpdateChecker.hpp"
#import "RLMUtil.hpp"

#include <sstream>
#include <exception>
#include <sys/types.h>
#include <sys/sysctl.h>

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
NSMutableDictionary *s_keysPerPath;

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
    @synchronized(s_keysPerPath) {
        s_keysPerPath = [NSMutableDictionary dictionary];
    }
}

static NSString *s_defaultRealmPath = nil;
static RLMMigrationBlock s_migrationBlock;
static NSUInteger s_currentSchemaVersion = 0;

void createTablesInTransaction(RLMRealm *realm, RLMSchema *targetSchema) {
    [realm beginWriteTransaction];

    @try {
        RLMRealmCreateMetadataTables(realm);
        if (RLMRealmSchemaVersion(realm) == RLMNotVersioned) {
            RLMRealmSetSchemaVersion(realm, s_currentSchemaVersion);
        }
        RLMRealmCreateTables(realm, targetSchema, false);
    }
    @catch (NSException *) {
        [realm cancelWriteTransaction];
        @throw;
    }

    [realm commitWriteTransaction];
}

bool isDebuggerAttached() {
    int name[] = {
        CTL_KERN,
        KERN_PROC,
        KERN_PROC_PID,
        getpid()
    };

    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    if (sysctl(name, sizeof(name)/sizeof(name[0]), &info, &info_size, NULL, 0) == -1) {
        NSLog(@"sysctl() failed: %s", strerror(errno));
        return false;
    }


    return (info.kp_proc.p_flag & P_TRACED) != 0;
}

static NSString *s_defaultRealmPath = nil;
static RLMMigrationBlock s_migrationBlock;
static NSUInteger s_currentSchemaVersion = 0;

NSMutableDictionary *s_serverBaseURLS = [NSMutableDictionary dictionary];

} // anonymous namespace


@interface RLMServerSync : NSObject
@property (atomic) NSString *baseURL; // E.g. http://187.56.46.23:123
@end

@implementation RLMServerSync {
    NSString *_path;

    NSURLSession *_urlSession;

    // At the present time we need to apply foreign transaction logs
    // via a special SharedGroup instance on which replication is not
    // enabled. This is necessary because some (not all) of the
    // actions taken during transaction log application submits new
    // entries to a new transaction log.
    unique_ptr<Replication> _transactLogRegistry;
    unique_ptr<SharedGroup> _sharedGroup;

    bool _uploadInProgress;
}

- (instancetype)initWithPath:(NSString *)path baseURL:(NSString *)baseURL {
    self = [super init];
    if (self) {
        _baseURL = baseURL;

        _path = path;

        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.name = @"io.Realm.sync";

        // Emphemeral config disables everything that would result in
        // data being automatically saved to disk
        NSURLSessionConfiguration *config =
            [NSURLSessionConfiguration ephemeralSessionConfiguration];

        // Disable caching
        config.URLCache = nil;
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

        config.HTTPShouldUsePipelining = YES;

        _urlSession = [NSURLSession sessionWithConfiguration:config
                                                    delegate:nil
                                               delegateQueue:queue];

        _transactLogRegistry.reset(makeWriteLogCollector(path.UTF8String));
        _sharedGroup.reset(new SharedGroup(path.UTF8String));

        _uploadInProgress = false;
    }
    return self;
}

- (void)initialBlockingDownload {
    Replication::version_type lastVersionUploaded, lastVersionAvailable;
    lastVersionUploaded = _transactLogRegistry->get_last_version_synced(&lastVersionAvailable);
    TIGHTDB_ASSERT(lastVersionUploaded <= lastVersionAvailable);
    Replication::version_type currentVersion = LangBindHelper::get_current_version(*_sharedGroup);
    TIGHTDB_ASSERT(currentVersion == lastVersionAvailable);

    // Never ask for next transaction log that is newer than one
    // beyong the last version uploaded. If we do that, we risk
    // getting something back even when the upload in progress is in
    // conflict with somebody elses transaction, and in that case the
    // received transaction log would be corrupt from our point of
    // view.
    typedef unsigned long long ulonglong;
    if (lastVersionUploaded < currentVersion) {
        NSLog(@"initialBlockingDownload: Skipping due to pending uploads (%llu<%llu)",
              ulonglong(lastVersionUploaded), ulonglong(currentVersion));
        return;
    }

    int maxRetries = 16;
    int numRetries = 0;
    __block NSMutableArray *upToDate = [NSMutableArray arrayWithObject:@NO];
    for (;;) {
        __block NSMutableArray *responseData = [NSMutableArray array];
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSString *url = [NSString stringWithFormat:@"%@/receive/%llu",
                                  self.baseURL, ulonglong(currentVersion)];
        NSMutableURLRequest *request =
            [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        request.HTTPMethod = @"POST";
        [[_urlSession dataTaskWithRequest:request
                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    if (error) {
                        NSLog(@"initialBlockingDownload: HTTP request failed: %@", error);
                    }
                    else if (((NSHTTPURLResponse *)response).statusCode != 200) {
                        NSLog(@"initialBlockingDownload: HTTP request failed with status %ld",
                              long(((NSHTTPURLResponse *)response).statusCode));
                    }
                    else if (!response.MIMEType) {
                        // FIXME: Using the MIME type in this way is
                        // not reliable as it may in general be
                        // modified in complicated ways by various
                        // involved HTTP agents.
                        NSLog(@"initialBlockingDownload: HTTP request failed: "
                              "No MIME type in response");
                    }
                    else if ([response.MIMEType isEqualToString:@"text/plain"]) {
                        NSData *upToDateString = [NSData dataWithBytesNoCopy:(void *)"up-to-date"
                                                                      length:10
                                                                freeWhenDone:NO];
                        if ([data isEqualToData:upToDateString]) {
                            upToDate[0] = @YES;
                        }
                        else {
                            NSLog(@"initialBlockingDownload: Unrecognized message from server %@",
                                  data.description);
                        }
                    }
                    else if ([response.MIMEType isEqualToString:@"application/octet-stream"]) {
                        // Assuming that `data` needs to be copied
                        // here to make it available outside the
                        // completion handler.
                        responseData[0] = [data copy];
                    }
                    else {
                        NSLog(@"initialBlockingDownload: Unexpected MIME type "
                              "in HTTP response '%@'", response.MIMEType);
                    }
                    dispatch_semaphore_signal(semaphore);
                }] resume];

        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

        if (((NSNumber *)upToDate[0]).boolValue)
            break;

        if (responseData.firstObject) {
            NSData *data = responseData.firstObject;
            if (data.length < 1 || ((const char *)data.bytes)[0] != '\0') {
                NSLog(@"initialBlockingDownload: Bad transaction log from server "
                      "(no leading null character)");
            }
            else {
                Replication::version_type receivedVersion = currentVersion + 1;
                const char *data2 = (const char *)data.bytes + 1;
                size_t size = size_t(data.length) - 1;
                NSLog(@"initialBlockingDownload: Received transaction log %llu -> %llu "
                      "of size %llu", ulonglong(receivedVersion-1), ulonglong(receivedVersion),
                      ulonglong(size));
                // Apply transaction log via the special SharedGroup instance
                {
                    WriteTransaction transact(*_sharedGroup);
                    Replication::SimpleInputStream input(data2, size);
                    ostream *applyLog = 0;
                    applyLog = &cerr;
                    try {
                        Replication::apply_transact_log(input, transact.get_group(),
                                                        applyLog); // Throws
                        transact.commit(); // Throws
                        BinaryData transactLog(data2, size);
                        _transactLogRegistry->submit_transact_log(transactLog);
                        _transactLogRegistry->set_last_version_synced(receivedVersion);
                        currentVersion = receivedVersion;
                        numRetries = 0;
                        continue;
                    }
                    catch (Replication::BadTransactLog&) {}
                    NSLog(@"initialBlockingDownload: Transaction log application failed");
                }
            }
        }
        if (numRetries == maxRetries) {
            NSLog(@"initialBlockingDownload: Too many failed HTTP requests, giving up");
            break;
/*
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Too many HTTP request failures"
                                         userInfo:nil];
*/
        }
        ++numRetries;
    }
}

- (void)rescheduleNonblockingDownload {
    // Schedule server download request roughly 100 times per second
    [self rescheduleNonblockingDownload:10 numFastRetries:0];
}

- (void)rescheduleNonblockingDownload:(int)msecDelay numFastRetries:(int)numFastRetries {
    int64_t nsecDelay = int64_t(msecDelay)*1000000L;
    // FIXME: Does dispatch_get_main_queue() imply that the block is
    // going to be executed by the main thread? Such a constraint is
    // not required. Any thread would suffice.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nsecDelay),
                   dispatch_get_main_queue(), ^{
                       [self nonblockingDownload:numFastRetries];
                   });
}

- (void)nonblockingDownload:(int)numFastRetries {
    int maxFastRetries = 16;

    Replication::version_type currentVersion, lastVersionUploaded, lastVersionAvailable;
    @synchronized (self) {
        currentVersion = LangBindHelper::get_current_version(*_sharedGroup);
        lastVersionUploaded = _transactLogRegistry->get_last_version_synced(&lastVersionAvailable);
    }
    TIGHTDB_ASSERT(lastVersionUploaded <= lastVersionAvailable);
    TIGHTDB_ASSERT(currentVersion <= lastVersionAvailable);

    // Never ask for next transaction log that is newer than one
    // beyong the last version uploaded. If we do that, we risk
    // getting something back even when the upload in progress is in
    // conflict with somebody elses transaction, and in that case the
    // received transaction log would be corrupt from our point of
    // view.
    typedef unsigned long long ulonglong;
    if (lastVersionUploaded < currentVersion) {
//        NSLog(@"nonblockingDownload: Skipping due to pending uploads (%llu<%llu)",
//              ulonglong(lastVersionUploaded), ulonglong(currentVersion));
        [self rescheduleNonblockingDownload];
        return;
    }

    NSString *url = [NSString stringWithFormat:@"%@/receive/%llu",
                              self.baseURL, ulonglong(currentVersion)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    Replication::version_type originalVersion = currentVersion;
    [[_urlSession dataTaskWithRequest:request
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error) {
                    NSLog(@"nonblockingDownload: HTTP request failed: %@", error);
                }
                else if (((NSHTTPURLResponse *)response).statusCode != 200) {
                    NSLog(@"nonblockingDownload: HTTP request failed with status %ld",
                          long(((NSHTTPURLResponse *)response).statusCode));
                }
                else if (!response.MIMEType) {
                    // FIXME: Using the MIME type in this way is
                    // not reliable as it may in general be
                    // modified in complicated ways by various
                    // involved HTTP agents.
                    NSLog(@"nonlockingDownload: HTTP request failed: No MIME type in response");
                }
                else if ([response.MIMEType isEqualToString:@"text/plain"]) {
                    NSData *upToDateString = [NSData dataWithBytesNoCopy:(void *)"up-to-date"
                                                                  length:10
                                                            freeWhenDone:NO];
                    if ([data isEqualToData:upToDateString]) {
                        [self rescheduleNonblockingDownload];
                        return;
                    }
                    NSLog(@"nonblockingDownload: Unrecognized message from server %@",
                          data.description);
                }
                else if ([response.MIMEType isEqualToString:@"application/octet-stream"]) {
                    if (data.length < 1 || ((const char *)data.bytes)[0] != '\0') {
                        NSLog(@"nonblockingDownload: Bad transaction log from server "
                              "(no leading null character)");
                    }
                    else {
                        const char *data2 = (const char *)data.bytes + 1;
                        size_t size = size_t(data.length) - 1;
                        Replication::version_type receivedVersion = originalVersion + 1;
                        NSLog(@"nonblockingDownload: Received transaction log %llu -> %llu "
                              "of size %llu", ulonglong(receivedVersion-1),
                              ulonglong(receivedVersion), ulonglong(size));
                        @synchronized (self) {
                            WriteTransaction transact(*_sharedGroup);
                            Replication::version_type newCurrentVersion =
                                LangBindHelper::get_current_version(*_sharedGroup);
                            if (newCurrentVersion != originalVersion) {
                                NSLog(@"nonblockingDownload: Dropping received transaction log "
                                      "due to advance of local version %llu",
                                      ulonglong(newCurrentVersion));
                                [self rescheduleNonblockingDownload];
                                return;
                            }
                            Replication::SimpleInputStream input(data2, size);
                            ostream *applyLog = 0;
                            applyLog = &cerr;
                            try {
                                Replication::apply_transact_log(input, transact.get_group(),
                                                                applyLog); // Throws
                                transact.commit(); // Throws
                                BinaryData transactLog(data2, size);
                                _transactLogRegistry->submit_transact_log(transactLog);
                                _transactLogRegistry->set_last_version_synced(receivedVersion);
                                [RLMRealm notifyRealmsAtPath:_path exceptRealm:nil];
                                [self nonblockingDownload:0];
                                return;
                            }
                            catch (Replication::BadTransactLog&) {}
                        }
                        NSLog(@"nonlockingDownload: Transaction log application failed");
                    }
                }
                else {
                    NSLog(@"nonblockingDownload: Unexpected MIME type in HTTP response '%@'",
                          response.MIMEType);
                }
                if (numFastRetries == maxFastRetries) {
                    NSLog(@"nonblockingDownload: Too many failed HTTP requests, "
                          "waiting 10 seconds");
                    [self rescheduleNonblockingDownload:10000 numFastRetries:numFastRetries];
                    return;
                }
                // Try again in one second
                [self rescheduleNonblockingDownload:1000 numFastRetries:numFastRetries+1];
            }] resume];
}

- (void)resumeNonblockingUpload {
    Replication::version_type lastVersionUploaded, lastVersionAvailable;
    NSData *data;
    @synchronized (self) {
        if (_uploadInProgress)
            return;

        lastVersionUploaded = _transactLogRegistry->get_last_version_synced(&lastVersionAvailable);
        if (lastVersionUploaded == lastVersionAvailable)
            return;

        BinaryData transact_log;
        _transactLogRegistry->get_commit_entries(lastVersionUploaded, lastVersionUploaded+1,
                                                 &transact_log);
        data = [NSData dataWithBytes:transact_log.data() length:transact_log.size()];

        _uploadInProgress = true;
    }

    Replication::version_type version = lastVersionUploaded+1;
    typedef unsigned long long ulonglong;
    NSLog(@"Sending transaction log %llu -> %llu", ulonglong(version-1), ulonglong(version));

    [self nonblockingUpload:data version:version numFastRetries:0];
}

- (void)rescheduleNonblockingUpload:(NSData *)data version:(Replication::version_type)version
                          msecDelay:(int)msecDelay numFastRetries:(int)numFastRetries {
    int64_t nsecDelay = int64_t(msecDelay)*1000000L;
    // FIXME: Does dispatch_get_main_queue() imply that the block is
    // going to be executed by the main thread? Such a constraint is
    // not required. Any thread would suffice.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, nsecDelay),
                   dispatch_get_main_queue(), ^{
                       [self nonblockingUpload:data version:version numFastRetries:numFastRetries];
                   });
}

- (void)nonblockingUpload:(NSData *)data version:(Replication::version_type)version
               numFastRetries:(int)numFastRetries {
    int maxFastRetries = 16;
    typedef unsigned long long ulonglong;
    NSString *url = [NSString stringWithFormat:@"%@/send/%llu", self.baseURL, ulonglong(version)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    [[_urlSession uploadTaskWithRequest:request
                               fromData:data
                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                if (error) {
                    NSLog(@"nonblockingUpload: HTTP request failed: %@", error);
                }
                else if (((NSHTTPURLResponse *)response).statusCode != 200) {
                    NSLog(@"nonblockingUpload: HTTP request failed with status %ld",
                          long(((NSHTTPURLResponse *)response).statusCode));
                }
                else if (!response.MIMEType) {
                    // FIXME: Using the MIME type in this way is
                    // not reliable as it may in general be
                    // modified in complicated ways by various
                    // involved HTTP agents.
                    NSLog(@"nonblockingUpload: HTTP request failed: No MIME type in response");
                }
                else if ([response.MIMEType isEqualToString:@"text/plain"]) {
                    NSData *upToDateString = [NSData dataWithBytesNoCopy:(void *)"ok"
                                                                  length:2
                                                            freeWhenDone:NO];
                    if ([data isEqualToData:upToDateString]) {
                        @synchronized (self) {
                            _transactLogRegistry->set_last_version_synced(version);
                            _uploadInProgress = false;
                            NSLog(@"Server received transaction log %llu -> %llu",
                                  ulonglong(version-1), ulonglong(version));
                        }
                        [self resumeNonblockingUpload];
                        return;
                    }
                    NSData *conflictString = [NSData dataWithBytesNoCopy:(void *)"conflict"
                                                                  length:8
                                                            freeWhenDone:NO];
                    if ([data isEqualToData:conflictString])
                        @throw [NSException exceptionWithName:@"RLMException"
                                                       reason:@"Conflicting transaction detected"
                                                     userInfo:nil];
                    NSLog(@"nonblockingUpload: Unrecognized response from server %@", data.description);
                }
                else {
                    NSLog(@"nonblockingUpload: Unexpected MIME type in HTTP response '%@'",
                          response.MIMEType);
                }
                if (numFastRetries == maxFastRetries) {
                    NSLog(@"nonblockingUpload: Too many failed HTTP requests, waiting 10 seconds");
                    [self rescheduleNonblockingUpload:data version:version msecDelay:10000
                                       numFastRetries:numFastRetries];
                    return;
                }
                // Try again in one second
                [self rescheduleNonblockingUpload:data version:version msecDelay:1000
                                   numFastRetries:numFastRetries+1];
            }] resume];
}
@end

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

    RLMServerSync *_serverSync;
}

+ (BOOL)isCoreDebug {
    return tightdb::Version::has_feature(tightdb::feature_Debug);
}

+ (void)initialize {
    static bool initialized;
    if (initialized) {
        return;
    }
    initialized = true;

    // set up global realm cache
    RLMCheckForUpdates();

    // initilize realm cache
    clearRealmCache();
}

- (instancetype)initWithPath:(NSString *)path key:(NSData *)key readOnly:(BOOL)readonly inMemory:(BOOL)inMemory error:(NSError **)error {
    if (key && [key length] != 64) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Encryption key must be exactly 64 bytes long"
                                     userInfo:nil];
    }

    if (key && isDebuggerAttached()) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Cannot open an encrypted Realm with a debugger attached to the process"
                                     userInfo:nil];
    }

    self = [super init];
    if (self) {
        _path = path;
        _thread = [NSThread currentThread];
        _threadID = pthread_mach_thread_np(pthread_self());
        _notificationHandlers = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory valueOptions:NSPointerFunctionsWeakMemory];
        _readOnly = readonly;
        _inMemory = inMemory;
        _autorefresh = YES;

        try {
            if (readonly) {
                _readGroup = make_unique<Group>(path.UTF8String, static_cast<const char *>(key.bytes));
                _group = _readGroup.get();
            }
            else {
                _replication.reset(tightdb::makeWriteLogCollector(path.UTF8String, false,
                                                                  static_cast<const char *>(key.bytes)));
                SharedGroup::DurabilityLevel durability = inMemory ? SharedGroup::durability_MemOnly :
                                                                     SharedGroup::durability_Full;
                _sharedGroup = make_unique<SharedGroup>(*_replication, durability,
                                                        static_cast<const char *>(key.bytes));
            }
        }
        catch (File::PermissionDenied &ex) {
            NSString *mode = readonly ? @"read" : @"read-write";
            NSString *additionalMessage = [NSString stringWithFormat:@"Unable to open a realm at path '%@'. Please use a path where your app has %@ permissions.", path, mode];
            NSString *newMessage = [NSString stringWithFormat:@"%s\n%@", ex.what(), additionalMessage];
            ex = File::PermissionDenied(newMessage.UTF8String);
            *error = make_realm_error(RLMErrorFilePermissionDenied, ex);
        }
        catch (File::Exists &ex) {
            *error = make_realm_error(RLMErrorFileExists, ex);
        }
        catch (File::AccessError &ex) {
            *error = make_realm_error(RLMErrorFileAccessError, ex);
        }
        catch (exception &ex) {
            *error = make_realm_error(RLMErrorFail, ex);
        }
    }
    return self;
}

- (tightdb::Group *)getOrCreateGroup {
    if (!_group) {
        _group = &const_cast<Group&>(_sharedGroup->begin_read());
    }
    return _group;
}

+ (NSString *)defaultRealmPath
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!s_defaultRealmPath) {
            s_defaultRealmPath = [RLMRealm writeablePathForFile:c_defaultRealmFileName];
        }
    });
    return s_defaultRealmPath;
}

+ (void)setDefaultRealmPath:(NSString *)defaultRealmPath {
    s_defaultRealmPath = defaultRealmPath;
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
    return [self realmWithPath:path key:nil readOnly:readonly inMemory:NO dynamic:NO schema:nil error:outError];
}

+ (instancetype)inMemoryRealmWithIdentifier:(NSString *)identifier {
    return [self realmWithPath:[RLMRealm writeablePathForFile:identifier] key:nil
                      readOnly:NO inMemory:YES dynamic:NO schema:nil error:nil];
}

+ (instancetype)encryptedRealmWithPath:(NSString *)path
                                   key:(NSData *)key
                              readOnly:(BOOL)readonly
                                 error:(NSError **)error
{
    if (!key) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Encryption key must not be nil" userInfo:nil];
    }

    return [self realmWithPath:path key:key readOnly:readonly inMemory:NO dynamic:NO schema:nil error:error];
}


+ (instancetype)realmWithPath:(NSString *)path
                          key:(NSData *)key
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
    __autoreleasing RLMRealm *realm = nil;
    if (!dynamic && !customSchema) {
        realm = cachedRealm(path);
    }

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

    if (!key) {
        @synchronized (s_keysPerPath) {
            key = s_keysPerPath[path];
        }
    }

    NSError *error = nil;
    realm = [[RLMRealm alloc] initWithPath:path key:key readOnly:readonly inMemory:inMemory error:&error];
    realm->_dynamic = dynamic;

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

    // we need to protect the realm cache and accessors cache
    @synchronized(s_realmsPerPath) {
        // create tables, set schema, and create accessors when needed
        if (customSchema) {
            if (!dynamic) {
                @throw [NSException exceptionWithName:@"RLMException" reason:@"Custom schema only supported when using dynamic Realms" userInfo:nil];
            }
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
            RLMRealmSetSchema(realm, [RLMSchema sharedSchema], true);
            RLMRealmCreateAccessors(realm.schema);

            cacheRealm(realm, path);
        }
        else {
            // check cache for existing cached realms with the same path
            NSArray *realms = realmsAtPath(path);
            if (realms.count) {
                // if we have a cached realm on another thread, copy without a transaction
                RLMRealmSetSchema(realm, [realms[0] schema], false);

                realm->_serverSync = ((RLMRealm *)realms[0])->_serverSync;
            }
            else {
                NSString *serverBaseURL;
                @synchronized (s_serverBaseURLS) {
                    serverBaseURL = s_serverBaseURLS[realm.path];
                }
                if (serverBaseURL) {
                    realm->_serverSync = [[RLMServerSync alloc] initWithPath:realm.path
                                                                     baseURL:serverBaseURL];
                }

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
                [realm->_serverSync initialBlockingDownload];

                [realm->_serverSync rescheduleNonblockingDownload];

                // if we are the first realm at this path, set/align schema or perform migration if needed
                NSUInteger schemaVersion = RLMRealmSchemaVersion(realm);
                if (s_currentSchemaVersion == schemaVersion || schemaVersion == RLMNotVersioned) {
                    createTablesInTransaction(realm, [RLMSchema sharedSchema]);
                }
                else {
                    [RLMRealm migrateRealm:realm key:key];
                }

                RLMRealmCreateAccessors(realm.schema);
            }

            // initializing the schema started a read transaction, so end it
            [realm invalidate];

            // cache only realms using a shared schema
            cacheRealm(realm, path);
        }
    }

    [realm->_serverSync resumeNonblockingUpload];

    return realm;
}

+ (void)setEncryptionKey:(NSData *)key forRealmsAtPath:(NSString *)path {
    if (!key) {
        @synchronized (s_keysPerPath) {
            [s_keysPerPath removeObjectForKey:path];
            return;
        }
    }

    if ([key length] != 64) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Encryption key must be exactly 64 bytes"
                                     userInfo:nil];
    }

    @synchronized (s_keysPerPath) {
        s_keysPerPath[path] = key;
    }
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

            // begin the read transaction if needed
            [self getOrCreateGroup];

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

            // notify other realm instances of changes
            [RLMRealm notifyRealmsAtPath:_path exceptRealm:self];

            // send local notification
            [self sendNotifications:RLMRealmDidChangeNotification];

            [_serverSync resumeNonblockingUpload];
        }
        catch (std::exception& ex) {
            throw_objc_exception(ex);
        }
    } else {
       @throw [NSException exceptionWithName:@"RLMException" reason:@"Can't commit a non-existing write transaction" userInfo:nil];
    }
}

+ (void)notifyRealmsAtPath:(NSString *)path exceptRealm:(RLMRealm *)exceptRealm {
    NSArray *realms = realmsAtPath(path);
    for (RLMRealm *realm in realms) {
        // FIXME: Why is this not just a pointer comparison?
        if (exceptRealm && [realm isEqual:exceptRealm])
            continue;
        RLMWeakNotifier *notifier = [[RLMWeakNotifier alloc] initWithRealm:realm];
        [notifier performSelector:@selector(notify)
                         onThread:realm->_thread withObject:nil waitUntilDone:NO];
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

- (void)invalidate {
    RLMCheckThread(self);
    CheckReadWrite(self, @"Cannot invalidate a read-only realm");

    if (_inWriteTransaction) {
        NSLog(@"WARNING: An RLMRealm instance was invalidated during a write "
              "transaction and all pending changes have been rolled back.");
        [self cancelWriteTransaction];
    }
    if (!_group) {
        // Nothing to do if the read transaction hasn't been begun
        return;
    }

    _sharedGroup->end_read();
    _group = nullptr;
    for (RLMObjectSchema *objectSchema in _schema.objectSchema) {
        objectSchema.table = nullptr;
    }
}

- (void)dealloc {
    if (_inWriteTransaction) {
        [self cancelWriteTransaction];
        NSLog(@"WARNING: An RLMRealm instance was deallocated during a write transaction and all "
              "pending changes have been rolled back. Make sure to retain a reference to the "
              "RLMRealm for the duration of the write transaction.");
    }
}

- (void)handleExternalCommit {
    RLMCheckThread(self);
    NSAssert(!_readOnly, @"Read-only realms do not have notifications");
    try {
        if (_sharedGroup->has_changed()) { // Throws
            if (_autorefresh) {
                if (_group) {
                    LangBindHelper::advance_read(*_sharedGroup);
                }
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
            if (_group) {
                LangBindHelper::advance_read(*_sharedGroup);
            }
            else {
                // Create the read transaction
                [self getOrCreateGroup];
            }
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
    RLMAddObjectToRealm(object, self, RLMCreationOptionsNone);
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

    RLMAddObjectToRealm(object, self, RLMCreationOptionsUpdateOrCreate);
}

- (void)addOrUpdateObjectsFromArray:(id)array {
    for (RLMObject *obj in array) {
        [self addOrUpdateObject:obj];
    }
}

- (void)deleteObject:(RLMObject *)object {
    RLMDeleteObjectFromRealm(object);
}

- (void)deleteObjects:(id)array {
    if (NSArray *nsArray = RLMDynamicCast<NSArray>(array)) {
        // for arrays and standalone delete each individually
        for (id obj in nsArray) {
            if ([obj isKindOfClass:RLMObjectBase.class]) {
                RLMDeleteObjectFromRealm(obj);
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
    NSData *key;
    @synchronized (s_keysPerPath) {
        key = s_keysPerPath[realmPath];
    }

    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithPath:realmPath key:key readOnly:NO inMemory:NO dynamic:YES schema:nil error:&error];
    if (error) {
        return error;
    }

    return [self migrateRealm:realm key:key];
}

+ (NSError *)migrateEncryptedRealmAtPath:(NSString *)realmPath key:(NSData *)key {
    if (!key) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Encryption key must not be nil" userInfo:nil];
    }

    NSError *error;
    RLMRealm *realm = [self realmWithPath:realmPath key:key readOnly:NO inMemory:NO dynamic:YES schema:nil error:&error];
    if (error) {
        return error;
    }

    return [self migrateRealm:realm key:key];
}

+ (NSError *)migrateRealm:(RLMRealm *)realm key:(NSData *)key {
    NSError *error;
    RLMMigration *migration = [RLMMigration migrationForRealm:realm key:key error:&error];
    if (error) {
        return error;
    }

    // only perform migration if current version is > on-disk version
    NSUInteger schemaVersion = RLMRealmSchemaVersion(migration.realm);
    if (schemaVersion < s_currentSchemaVersion) {
        [migration migrateWithBlock:s_migrationBlock version:s_currentSchemaVersion];
    }
    else if (schemaVersion > s_currentSchemaVersion && schemaVersion != RLMNotVersioned) {
        if (!s_migrationBlock) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"No migration block specified for a Realm with a schema version greater than 0. You must supply a valid schema version and migration block before accessing any Realm by calling `setSchemaVersion:withMigrationBlock:`"
                                         userInfo:@{@"path" : migration.realm.path}];
        }
        else {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Realm version is higher than the current version provided to `setSchemaVersion:withMigrationBlock:`"
                                         userInfo:@{@"path" : migration.realm.path}];
        }
    }

    return nil;
}

- (RLMObject *)createObject:(NSString *)className withObject:(id)object {
    return (RLMObject *)RLMCreateObjectInRealmWithValue(self, className, object, RLMCreationOptionsNone);
}

+ (void)enableServerSyncOnPath:(NSString *)path serverBaseURL:(NSString *)serverBaseURL {
    @synchronized (s_serverBaseURLS) {
        s_serverBaseURLS[path] = serverBaseURL;
    }
}

- (BOOL)writeCopyToPath:(NSString *)path key:(NSData *)key error:(NSError **)error {
    BOOL success = YES;

    try {
        self.group->write(path.UTF8String, static_cast<const char *>(key.bytes));
    }
    catch (File::PermissionDenied &ex) {
        success = NO;
        if (error) {
            *error = make_realm_error(RLMErrorFilePermissionDenied, ex);
        }
    }
    catch (File::Exists &ex) {
        success = NO;
        if (error) {
            *error = make_realm_error(RLMErrorFileExists, ex);
        }
    }
    catch (File::AccessError &ex) {
        success = NO;
        if (error) {
            *error = make_realm_error(RLMErrorFileAccessError, ex);
        }
    }
    catch (exception &ex) {
        success = NO;
        if (error) {
            *error = make_realm_error(RLMErrorFail, ex);
        }
    }

    return success;
}

- (BOOL)writeCopyToPath:(NSString *)path error:(NSError **)error {
    return [self writeCopyToPath:path key:nil error:error];
}

- (BOOL)writeEncryptedCopyToPath:(NSString *)path key:(NSData *)key error:(NSError **)error {
    if (!key) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"Encryption key must not be nil" userInfo:nil];
    }

    return [self writeCopyToPath:path key:key error:error];
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
