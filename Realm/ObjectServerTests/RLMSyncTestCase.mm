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
#import "RLMRealmConfiguration_Private.h"
#import "RLMSyncManager+ObjectServerTests.h"
#import "RLMSyncSessionRefreshHandle+ObjectServerTests.h"
#import "RLMSyncConfiguration_Private.h"

#import "sync/sync_manager.hpp"
#import "sync/sync_session.hpp"
#import "sync/sync_user.hpp"

#if !TARGET_OS_MAC
#error These tests can only be run on a macOS host.
#endif

@interface RLMSyncManager ()
+ (void)_setCustomBundleID:(NSString *)customBundleID;
- (instancetype)initWithCustomRootDirectory:(NSURL *)rootDirectory;
@end

@interface RLMSyncTestCase ()
@property (nonatomic) NSTask *task;
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
    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    return [NSURL fileURLWithPath:path isDirectory:YES];
}

@implementation RLMSyncTestCase

+ (RLMSyncManager *)managerForCurrentTest {
    return s_managerForTest;
}

#pragma mark - Helper methods

+ (NSURL *)rootRealmCocoaURL {
    return [[[[NSURL fileURLWithPath:@(__FILE__)]
              URLByDeletingLastPathComponent]
             URLByDeletingLastPathComponent]
            URLByDeletingLastPathComponent];
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
    RLMSyncConfiguration *config = [realm.configuration syncConfiguration];
    if (config.user.state == RLMSyncUserStateError) {
        return nil;
    }
    auto on_disk_path = realm::SyncManager::shared().path_for_realm(*[config.user _syncUser],
                                                                    [config.realmURL.absoluteString UTF8String]);
    auto ptr = realm::SyncManager::shared().get_existing_session(on_disk_path);
    if (ptr) {
        return [NSURL fileURLWithPath:@(ptr->path().c_str())];
    }
    return nil;
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
    RLMRealmConfiguration *c = [RLMRealmConfiguration defaultConfiguration];
    c.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:url];
    c.syncConfiguration.stopPolicy = stopPolicy;
    c.encryptionKey = encryptionKey;
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

- (RLMSyncUser *)makeAdminUser:(NSString *)userName password:(NSString *)password server:(NSURL *)url {
    // Admin token user (only needs to be set up once ever per test run).
    // Note: this is shared, persistent state between tests.
    static RLMSyncUser *adminTokenUser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *adminTokenFileURL = [[RLMSyncTestCase rootRealmCocoaURL] URLByAppendingPathComponent:@"sync/admin_token.base64"];
        NSString *adminToken = [NSString stringWithContentsOfURL:adminTokenFileURL
                                                        encoding:NSUTF8StringEncoding error:nil];
        RLMSyncCredentials *credentials = [RLMSyncCredentials credentialsWithAccessToken:adminToken
                                                                                identity:[[NSUUID UUID] UUIDString]];
        adminTokenUser = [self logInUserForCredentials:credentials server:url];
    });
    XCTAssertNotNil(adminTokenUser);

    // Create a new user, which starts off without admin privileges.
    RLMSyncCredentials *creds = [RLMSyncCredentials credentialsWithUsername:userName password:password register:YES];
    RLMSyncUser *adminUser = [self logInUserForCredentials:creds server:url];
    XCTAssertFalse(adminUser.isAdmin);
    NSString *adminUserID = adminUser.identity;
    XCTAssertNotNil(adminUserID);

    // Find reference in admin Realm to newly-created non-admin user.
    @autoreleasepool {
        RLMRealmConfiguration *adminRealmConfig = [RLMRealmConfiguration defaultConfiguration];
        adminRealmConfig.dynamic = true;
        NSURL *adminRealmURL = [NSURL URLWithString:@"realm://localhost:9080/__admin"];
        adminRealmConfig.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:adminTokenUser
                                                                               realmURL:adminRealmURL];

        XCTestExpectation *setAdminEx = [self expectationWithDescription:@"completed setting admin status on user"];
        XCTestExpectation *findAdminEx = [self expectationWithDescription:@"found admin status on user"];
        [RLMRealm asyncOpenWithConfiguration:adminRealmConfig callbackQueue:dispatch_get_main_queue() callback:^(RLMRealm *realm, NSError *error) {
            XCTAssertNil(error);
            __attribute__((objc_precise_lifetime)) RLMNotificationToken *token;
            __block RLMObject *userObject = nil;
            token = [[realm objects:@"User" where:@"id == %@", adminUserID] addNotificationBlock:^(RLMResults *results, __unused id change, NSError *error) {
                XCTAssertNil(error);
                if ([results count] > 0) {
                    userObject = [results firstObject];
                    [findAdminEx fulfill];
                }
            }];
            [self waitForExpectations:@[findAdminEx] timeout:10.0];
            [token stop];
            [realm transactionWithBlock:^{
                [userObject setValue:@YES forKey:@"isAdmin"];
            }];
            [setAdminEx fulfill];
        }];
        [self waitForExpectations:@[setAdminEx] timeout:20.0];
    }

    // Refresh this Realm's token until it becomes an admin user. (We don't have any other
    // way to tell when the server has properly processed this change.)
    BOOL isAdmin = NO;
    for (NSInteger i=0; i<10; i++) {
        // Log the user back in
        RLMSyncCredentials *noRegCreds = [RLMSyncCredentials credentialsWithUsername:userName
                                                                            password:password
                                                                            register:NO];
        RLMSyncUser *testUser = [self logInUserForCredentials:noRegCreds server:url];
        if (testUser.isAdmin) {
            isAdmin = YES;
            break;
        }
        // Wait a bit then try again.
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    XCTAssertTrue(isAdmin);
    return adminUser;
}

- (void)waitForDownloadsForUser:(RLMSyncUser *)user url:(NSURL *)url {
    [self waitForDownloadsForUser:user url:url expectation:nil error:nil];
}

- (void)waitForDownloadsForUser:(RLMSyncUser *)user
                            url:(NSURL *)url
                    expectation:(XCTestExpectation *)expectation
                          error:(NSError **)error {
    RLMSyncSession *session = [user sessionForURL:url];
    NSAssert(session, @"Cannot call with invalid URL");
    XCTestExpectation *ex = expectation ?: [self expectationWithDescription:@"Download waiter expectation"];
    __block NSError *theError = nil;
    BOOL queued = [session waitForDownloadCompletionOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
                                                   callback:^(NSError *err){
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

- (void)waitForUploadsForUser:(RLMSyncUser *)user url:(NSURL *)url {
    [self waitForUploadsForUser:user url:url error:nil];
}

- (void)waitForUploadsForUser:(RLMSyncUser *)user url:(NSURL *)url error:(NSError **)error {
    RLMSyncSession *session = [user sessionForURL:url];
    NSAssert(session, @"Cannot call with invalid URL");
    XCTestExpectation *ex = [self expectationWithDescription:@"Upload waiter expectation"];
    __block NSError *theError = nil;
    BOOL queued = [session waitForUploadCompletionOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
                                                 callback:^(NSError *err){
                                                     theError = err;
                                                     [ex fulfill];
                                                 }];
    if (!queued) {
        XCTFail(@"Upload waiter did not queue; session was invalid or errored out.");
        return;
    }
    // FIXME: If tests involving `HugeSyncObject` are more reliable after July 2017, file an issue against sync
    // regarding performance of ROS.
    [self waitForExpectations:@[ex] timeout:20.0];
    if (error) {
        *error = theError;
    }
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

+ (void)setUp {
    [super setUp];
    NSString *syncDirectory = [[[self rootRealmCocoaURL] URLByAppendingPathComponent:@"sync"] path];
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:syncDirectory isDirectory:&isDirectory] || !isDirectory) {
        NSLog(@"sync/ directory doesn't exist. You need to run 'build.sh download-object-server' prior to running these tests");
        abort();
    }
}

- (void)lazilyInitializeObjectServer {
    if (!self.isParent || s_task) {
        return;
    }
    [RLMSyncTestCase runResetObjectServer:YES];
    NSTask *task = [[NSTask alloc] init];
    task.currentDirectoryPath = [[RLMSyncTestCase rootRealmCocoaURL] path];
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"build.sh", @"start-object-server"];
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    task.standardOutput = [NSPipe pipe];
    [[task.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSData *data = [file availableData];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([output containsString:@"Received: IDENT"]) {
            dispatch_semaphore_signal(sema);
        }
    }];
    s_task = task;
    [task launch];
    const NSTimeInterval timeout = 60;
    BOOL wait_result = dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC))) == 0;
    if (!wait_result) {
        s_task = nil;
        XCTFail(@"Server did not start up within the allotted timeout interval.");
    }
}

+ (void)runResetObjectServer:(BOOL)initial {
    NSTask *task = [[NSTask alloc] init];
    task.currentDirectoryPath = [[RLMSyncTestCase rootRealmCocoaURL] path];
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"build.sh", initial ? @"reset-object-server" : @"reset-object-server-between-tests"];
    task.standardOutput = [NSPipe pipe];
    [task launch];
    [task waitUntilExit];
}

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    [self lazilyInitializeObjectServer];

    if (self.isParent) {
        XCTAssertNotNil(s_task, @"Test suite setup did not complete: server did not start properly.");
        [RLMSyncTestCase runResetObjectServer:NO];
        s_managerForTest = [[RLMSyncManager alloc] initWithCustomRootDirectory:nil];
    } else {
        // Configure the sync manager to use a different directory than the parent process.
        s_managerForTest = [[RLMSyncManager alloc] initWithCustomRootDirectory:syncDirectoryForChildProcess()];
    }
    [RLMSyncManager sharedManager].logLevel = RLMSyncLogLevelOff;
}

- (void)tearDown {
    [s_managerForTest prepareForDestruction];
    s_managerForTest = nil;
    [RLMSyncSessionRefreshHandle calculateFireDateUsingTestLogic:NO blockOnRefreshCompletion:nil];

    [super tearDown];
}

@end
