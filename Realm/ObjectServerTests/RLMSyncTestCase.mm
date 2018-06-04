////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMSyncTestCase.h"

#import <XCTest/XCTest.h>
#import <Realm/Realm.h>

#import "RLMRealm_Dynamic.h"
#import "RLMRealm_Private.hpp"
#import "RLMRealmConfiguration_Private.h"
#import "RLMSyncManager+ObjectServerTests.h"
#import "RLMSyncSessionRefreshHandle+ObjectServerTests.h"
#import "RLMSyncConfiguration_Private.h"
#import "RLMUtil.hpp"

#import "sync/sync_manager.hpp"
#import "sync/sync_session.hpp"
#import "sync/sync_user.hpp"

// Set this to 1 if you want the test ROS instance to log its debug messages to console.
#define LOG_ROS_OUTPUT 0

#if !TARGET_OS_MAC
#error These tests can only be run on a macOS host.
#endif

static NSString *nodePath() {
    static NSString *path = [] {
        NSDictionary *environment = NSProcessInfo.processInfo.environment;
        if (NSString *path = environment[@"REALM_NODE_PATH"]) {
            return path;
        }
        return @"/usr/local/bin/node";
    }();
    return path;
}

@interface RLMSyncManager ()
+ (void)_setCustomBundleID:(NSString *)customBundleID;
- (instancetype)initWithCustomRootDirectory:(NSURL *)rootDirectory;
@end

@interface RLMSyncTestCase ()
@property (nonatomic) NSTask *task;
@end

@interface RLMSyncCredentials ()
+ (instancetype)credentialsWithDebugUserID:(NSString *)userID isAdmin:(BOOL)isAdmin;
@end

@interface RLMSyncSession ()
- (BOOL)waitForUploadCompletionOnQueue:(dispatch_queue_t)queue callback:(void(^)(NSError *))callback;
- (BOOL)waitForDownloadCompletionOnQueue:(dispatch_queue_t)queue callback:(void(^)(NSError *))callback;
@end

@interface RLMSyncUser()
- (std::shared_ptr<realm::SyncUser>)_syncUser;
@end

@implementation SyncObject
@end

@implementation HugeSyncObject

+ (instancetype)object  {
    const NSInteger fakeDataSize = 1000000;
    HugeSyncObject *object = [[self alloc] init];
    char fakeData[fakeDataSize];
    memset(fakeData, sizeof(fakeData), 16);
    object.dataProp = [NSData dataWithBytes:fakeData length:sizeof(fakeData)];
    return object;
}

@end

static NSTask *s_task;
static RLMSyncManager *s_managerForTest;

static NSURL *syncDirectoryForChildProcess() {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundleIdentifier = bundle.bundleIdentifier ?: bundle.executablePath.lastPathComponent;
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-child", bundleIdentifier]];
    return [NSURL fileURLWithPath:path isDirectory:YES];
}

@interface RealmObjectServer : NSObject
@property (nonatomic, readonly) NSURL *serverDataRoot;

+ (instancetype)sharedServer;

- (void)launch;
@end

@implementation RealmObjectServer {
    NSTask *_task;
    NSURL *_serverDataRoot;
}
+ (instancetype)sharedServer {
    static RealmObjectServer *instance = [RealmObjectServer new];
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _serverDataRoot = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test-ros-data"]];
    }
    return self;
}

- (void)launch {
    if (_task) {
        return;
    }
    // Clean up any old state from the server
    [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/pkill"
                              arguments:@[@"-f", @"node.*test-ros-server.js"]] waitUntilExit];
    [NSFileManager.defaultManager removeItemAtURL:self.serverDataRoot error:nil];
    [NSFileManager.defaultManager createDirectoryAtURL:self.serverDataRoot
                           withIntermediateDirectories:YES attributes:nil error:nil];

    // Install ROS if it isn't already present
    [self downloadObjectServer];

    // Set up the actual ROS task
    NSPipe *pipe = [NSPipe pipe];
    _task = [[NSTask alloc] init];
    _task.currentDirectoryPath = self.serverDataRoot.path;
    _task.launchPath = nodePath();
    NSString *directory = [@(__FILE__) stringByDeletingLastPathComponent];
    _task.arguments = @[[directory stringByAppendingPathComponent:@"test-ros-server.js"],
                        self.serverDataRoot.path];
    _task.standardOutput = pipe;
    [_task launch];

    NSData *childStdout = pipe.fileHandleForReading.readDataToEndOfFile;
    if (![childStdout isEqual:[@"started\n" dataUsingEncoding:NSUTF8StringEncoding]]) {
        abort();
    }

    atexit([] {
        auto self = RealmObjectServer.sharedServer;
        [self->_task terminate];
        [self->_task waitUntilExit];
        [NSFileManager.defaultManager removeItemAtURL:self->_serverDataRoot error:nil];
    });
}

- (NSString *)desiredObjectServerVersion {
    auto path = [[[[@(__FILE__) stringByDeletingLastPathComponent] // RLMSyncTestCase.mm
                 stringByDeletingLastPathComponent] // ObjectServerTests
                 stringByDeletingLastPathComponent] // Realm
                 stringByAppendingPathComponent:@"dependencies.list"];
    auto file = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!file) {
        NSLog(@"Failed to read dependencies.list");
        abort();
    }

    auto regex = [NSRegularExpression regularExpressionWithPattern:@"^REALM_OBJECT_SERVER_VERSION=(.*)$"
                                                           options:NSRegularExpressionAnchorsMatchLines error:nil];
    auto match = [regex firstMatchInString:file options:0 range:{0, file.length}];
    if (!match) {
        NSLog(@"Failed to read REALM_OBJECT_SERVER_VERSION from dependencies.list");
        abort();
    }
    return [file substringWithRange:[match rangeAtIndex:1]];
}

- (NSString *)currentObjectServerVersion {
    auto path = [[[[@(__FILE__) stringByDeletingLastPathComponent] // RLMSyncTestCase.mm
                 stringByAppendingPathComponent:@"node_modules"]
                 stringByAppendingPathComponent:@"realm-object-server"]
                 stringByAppendingPathComponent:@"package.json"];
    auto file = [NSData dataWithContentsOfFile:path];
    if (!file) {
        return nil;
    }

    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:file options:0 error:&error];
    if (!json) {
        NSLog(@"Error reading version from installed ROS: %@", error);
        abort();
    }

    return json[@"version"];
}

- (void)downloadObjectServer {
    NSString *desiredVersion = [self desiredObjectServerVersion];
    NSString *currentVersion = [self currentObjectServerVersion];
    if ([currentVersion isEqualToString:desiredVersion]) {
        return;
    }

    NSLog(@"Installing Realm Object Server %@", desiredVersion);
    NSTask *task = [[NSTask alloc] init];
    task.currentDirectoryPath = [@(__FILE__) stringByDeletingLastPathComponent];
    task.launchPath = nodePath();
    task.arguments = @[[[nodePath() stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"npm"],
                       @"--scripts-prepend-node-path=auto",
                       @"--no-color",
                       @"--no-progress",
                       @"--no-save",
                       @"--no-package-lock",
                       @"install",
                       [@"realm-object-server@" stringByAppendingString:desiredVersion]
                       ];
    [task launch];
    [task waitUntilExit];
}
@end

@implementation RLMSyncTestCase

+ (RLMSyncManager *)managerForCurrentTest {
    return s_managerForTest;
}

#pragma mark - Helper methods

- (BOOL)isPartial {
    return NO;
}

+ (NSURL *)authServerURL {
    return [NSURL URLWithString:@"http://127.0.0.1:9080"];
}

+ (RLMSyncCredentials *)basicCredentialsWithName:(NSString *)name register:(BOOL)shouldRegister {
    return [RLMSyncCredentials credentialsWithUsername:name
                                              password:@"a"
                                              register:shouldRegister];
}

+ (NSURL *)onDiskPathForSyncedRealm:(RLMRealm *)realm {
    return [NSURL fileURLWithPath:@(realm->_realm->config().path.data())];
}

- (void)addSyncObjectsToRealm:(RLMRealm *)realm descriptions:(NSArray<NSString *> *)descriptions {
    [realm beginWriteTransaction];
    for (NSString *desc in descriptions) {
        [SyncObject createInRealm:realm withValue:@[desc]];
    }
    [realm commitWriteTransaction];
}

- (void)waitForDownloadsForUser:(RLMSyncUser *)user
                         realms:(NSArray<RLMRealm *> *)realms
                      realmURLs:(NSArray<NSURL *> *)realmURLs
                 expectedCounts:(NSArray<NSNumber *> *)counts {
    NSAssert(realms.count == counts.count && realms.count == realmURLs.count,
             @"Test logic error: all array arguments must be the same size.");
    for (NSUInteger i = 0; i < realms.count; i++) {
        [self waitForDownloadsForUser:user url:realmURLs[i] expectation:nil error:nil];
        [realms[i] refresh];
        CHECK_COUNT([counts[i] integerValue], SyncObject, realms[i]);
    }
}

- (RLMRealm *)openRealmForURL:(NSURL *)url user:(RLMSyncUser *)user {
    return [self openRealmForURL:url user:user immediatelyBlock:nil];
}

- (RLMRealm *)openRealmForURL:(NSURL *)url user:(RLMSyncUser *)user immediatelyBlock:(void(^)(void))block {
    return [self openRealmForURL:url
                            user:user
                   encryptionKey:nil
                      stopPolicy:RLMSyncStopPolicyAfterChangesUploaded
                immediatelyBlock:block];
}

- (RLMRealm *)openRealmForURL:(NSURL *)url
                         user:(RLMSyncUser *)user
                encryptionKey:(nullable NSData *)encryptionKey
                   stopPolicy:(RLMSyncStopPolicy)stopPolicy
             immediatelyBlock:(nullable void(^)(void))block {
    const NSTimeInterval timeout = 4;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    RLMSyncManager.sharedManager.sessionCompletionNotifier = ^(NSError *error) {
        if (error) {
            XCTFail(@"Received an asynchronous error when trying to open Realm at '%@' for user '%@': %@ (process: %@)",
                    url, user.identity, error, self.isParent ? @"parent" : @"child");
        }
        dispatch_semaphore_signal(sema);
    };

    RLMRealm *realm = [self immediatelyOpenRealmForURL:url user:user encryptionKey:encryptionKey stopPolicy:stopPolicy];
    if (block) {
        block();
    }
    // Wait for login to succeed or fail.
    XCTAssert(dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC))) == 0,
              @"Timed out while trying to asynchronously open Realm for URL: %@", url);
    return realm;
}

- (RLMRealm *)openRealmWithConfiguration:(RLMRealmConfiguration *)configuration {
    return [self openRealmWithConfiguration:configuration immediatelyBlock:nullptr];
}

- (RLMRealm *)openRealmWithConfiguration:(RLMRealmConfiguration *)configuration
             immediatelyBlock:(nullable void(^)(void))block {
    const NSTimeInterval timeout = 4;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    RLMSyncConfiguration *syncConfig = configuration.syncConfiguration;
    RLMSyncManager.sharedManager.sessionCompletionNotifier = ^(NSError *error) {
        if (error) {
            XCTFail(@"Received an asynchronous error when trying to open Realm at '%@' for user '%@': %@ (process: %@)",
                    syncConfig.realmURL, syncConfig.user.identity, error, self.isParent ? @"parent" : @"child");
        }
        dispatch_semaphore_signal(sema);
    };

    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nullptr];
    if (block) {
        block();
    }
    // Wait for login to succeed or fail.
    XCTAssert(dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC))) == 0,
              @"Timed out while trying to asynchronously open Realm for URL: %@", syncConfig.realmURL);
    return realm;
}
- (RLMRealm *)immediatelyOpenRealmForURL:(NSURL *)url user:(RLMSyncUser *)user {
    return [self immediatelyOpenRealmForURL:url
                                       user:user
                              encryptionKey:nil
                                 stopPolicy:RLMSyncStopPolicyAfterChangesUploaded];
}

- (RLMRealm *)immediatelyOpenRealmForURL:(NSURL *)url
                                    user:(RLMSyncUser *)user
                           encryptionKey:(NSData *)encryptionKey
                              stopPolicy:(RLMSyncStopPolicy)stopPolicy {
    auto c = [user configurationWithURL:url fullSynchronization:!self.isPartial];
    c.encryptionKey = encryptionKey;
    RLMSyncConfiguration *syncConfig = c.syncConfiguration;
    syncConfig.stopPolicy = stopPolicy;
    c.syncConfiguration = syncConfig;
    return [RLMRealm realmWithConfiguration:c error:nil];
}

- (RLMSyncUser *)logInUserForCredentials:(RLMSyncCredentials *)credentials
                                  server:(NSURL *)url {
    NSString *process = self.isParent ? @"parent" : @"child";
    __block RLMSyncUser *theUser = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Should log in the user properly"];
    [RLMSyncUser logInWithCredentials:credentials
                        authServerURL:url
                         onCompletion:^(RLMSyncUser *user, NSError *error) {
                             XCTAssertTrue(NSThread.isMainThread);
                             XCTAssertNil(error,
                                          @"Error when trying to log in a user: %@ (process: %@)",
                                          error, process);
                             XCTAssertNotNil(user);
                             theUser = user;
                             [expectation fulfill];
                         }];
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
    XCTAssertTrue(theUser.state == RLMSyncUserStateActive,
                  @"User should have been valid, but wasn't. (process: %@)", process);
    return theUser;
}

- (RLMSyncUser *)createAdminUserForURL:(NSURL *)url username:(NSString *)username {
    return [self logInUserForCredentials:[RLMSyncCredentials credentialsWithDebugUserID:username isAdmin:YES]
                                  server:url];
}

- (NSString *)adminToken {
    NSURL *target = [RealmObjectServer.sharedServer.serverDataRoot
                     URLByAppendingPathComponent:@"/keys/admin.json"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[target path]]) {
        XCTFail(@"Could not find the JSON file containing the admin token.");
        return nil;
    }
    NSData *raw = [NSData dataWithContentsOfURL:target];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:raw options:0 error:nil];
    NSString *token = json[@"ADMIN_TOKEN"];
    if ([token length] == 0) {
        XCTFail(@"Could not successfully extract the token.");
    }
    return token;
}

- (NSString *)emailForAddress:(NSString *)email {
    NSURL *target = [[RealmObjectServer.sharedServer.serverDataRoot
                     URLByAppendingPathComponent:@"/email"]
                     URLByAppendingPathComponent:email];
    NSString *body = [NSString stringWithContentsOfURL:target encoding:NSUTF8StringEncoding error:nil];
    if (body) {
        [NSFileManager.defaultManager removeItemAtURL:target error:nil];
    }
    return body;
}

- (void)waitForDownloadsForRealm:(RLMRealm *)realm {
    [self waitForDownloadsForRealm:realm error:nil];
}

- (void)waitForUploadsForRealm:(RLMRealm *)realm {
    [self waitForUploadsForRealm:realm error:nil];
}

- (void)waitForDownloadsForUser:(RLMSyncUser *)user
                            url:(NSURL *)url
                    expectation:(XCTestExpectation *)expectation
                          error:(NSError **)error {
    RLMSyncSession *session = [user sessionForURL:url];
    NSAssert(session, @"Cannot call with invalid URL");
    XCTestExpectation *ex = expectation ?: [self expectationWithDescription:@"Wait for download completion"];
    __block NSError *theError = nil;
    BOOL queued = [session waitForDownloadCompletionOnQueue:nil callback:^(NSError *err) {
        theError = err;
        [ex fulfill];
    }];
    if (!queued) {
        XCTFail(@"Download waiter did not queue; session was invalid or errored out.");
        return;
    }
    [self waitForExpectations:@[ex] timeout:20.0];
    if (error) {
        *error = theError;
    }
}

- (void)waitForUploadsForRealm:(RLMRealm *)realm error:(NSError **)error {
    RLMSyncSession *session = realm.syncSession;
    NSAssert(session, @"Cannot call with invalid Realm");
    XCTestExpectation *ex = [self expectationWithDescription:@"Wait for upload completion"];
    __block NSError *completionError;
    BOOL queued = [session waitForUploadCompletionOnQueue:nil callback:^(NSError *error) {
        completionError = error;
        [ex fulfill];
    }];
    if (!queued) {
        XCTFail(@"Upload waiter did not queue; session was invalid or errored out.");
        return;
    }
    [self waitForExpectations:@[ex] timeout:2.0];
    if (error)
        *error = completionError;
}

- (void)waitForDownloadsForRealm:(RLMRealm *)realm error:(NSError **)error {
    RLMSyncSession *session = realm.syncSession;
    NSAssert(session, @"Cannot call with invalid Realm");
    XCTestExpectation *ex = [self expectationWithDescription:@"Wait for download completion"];
    __block NSError *completionError;
    BOOL queued = [session waitForDownloadCompletionOnQueue:nil callback:^(NSError *error) {
        completionError = error;
        [ex fulfill];
    }];
    if (!queued) {
        XCTFail(@"Download waiter did not queue; session was invalid or errored out.");
        return;
    }
    [self waitForExpectations:@[ex] timeout:2.0];
    if (error)
        *error = completionError;
}

- (void)manuallySetRefreshTokenForUser:(RLMSyncUser *)user value:(NSString *)tokenValue {
    [user _syncUser]->update_refresh_token(tokenValue.UTF8String);
}

// FIXME: remove this API once the new token system is implemented.
- (void)primeSyncManagerWithSemaphore:(dispatch_semaphore_t)semaphore {
    if (semaphore == nil) {
        [[RLMSyncManager sharedManager] setSessionCompletionNotifier:^(__unused NSError *error){ }];
        return;
    }
    [[RLMSyncManager sharedManager] setSessionCompletionNotifier:^(NSError *error) {
        XCTAssertNil(error, @"Session completion block returned with an error: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
}

#pragma mark - XCUnitTest Lifecycle

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    NSURL *clientDataRoot;
    if (self.isParent) {
        [RealmObjectServer.sharedServer launch];
        clientDataRoot = [NSURL fileURLWithPath:RLMDefaultDirectoryForBundleIdentifier(nil)];
    }
    else {
        clientDataRoot = syncDirectoryForChildProcess();
    }
    NSError *error;
    [NSFileManager.defaultManager removeItemAtURL:clientDataRoot error:&error];
    [NSFileManager.defaultManager createDirectoryAtURL:clientDataRoot
                           withIntermediateDirectories:YES attributes:nil error:&error];
    s_managerForTest = [[RLMSyncManager alloc] initWithCustomRootDirectory:clientDataRoot];
    [RLMSyncManager sharedManager].logLevel = RLMSyncLogLevelOff;
}

- (void)tearDown {
    [s_managerForTest prepareForDestruction];
    s_managerForTest = nil;
    [RLMSyncSessionRefreshHandle calculateFireDateUsingTestLogic:NO blockOnRefreshCompletion:nil];

    [super tearDown];
}

@end
