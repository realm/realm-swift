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

// Set this to 1 if you intend to start up a ROS instance manually to test against.
#define PROVIDING_OWN_ROS 0

// Set this to 1 if you want the test ROS instance to log its debug messages to console.
#define LOG_ROS_OUTPUT 0

#if PROVIDING_OWN_ROS
// Define the admin token as an Objective-C string here if you wish to run tests requiring it.
// #define OWN_ROS_ADMIN_TOKEN @"token_goes_here"
#endif

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

+ (NSString *)retrieveAdminToken {
#if PROVIDING_OWN_ROS
#ifdef OWN_ROS_ADMIN_TOKEN
    return OWN_ROS_ADMIN_TOKEN;
#else
    NSAssert(NO, @"Cannot run admin token related tests unless you define OWN_ROS_ADMIN_TOKEN.");
    return nil;
#endif
#else
    NSString *adminTokenPath = @"test-ros-instance/data/keys/admin.json";
    NSURL *target = [[RLMSyncTestCase rootRealmCocoaURL] URLByAppendingPathComponent:adminTokenPath];
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
#endif
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
#if !PROVIDING_OWN_ROS
    NSURL *target = [[RLMSyncTestCase rootRealmCocoaURL] URLByAppendingPathComponent:@"test-ros-instance/ros/bin/ros"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[target path]]) {
        NSLog(@"The Realm Object Server isn't installed. You need to run 'build.sh download-object-server'"
              @" prior to running these tests.");
        abort();
    }
#endif
}

+ (void)logObjectServerOutput:(__unused NSString *)output {
#if LOG_ROS_OUTPUT
    NSArray<NSString *> *array = [output componentsSeparatedByString:@"\n"];
    for (NSString *piece in array) {
        if ([piece length] > 0) {
            NSLog(@"ROS: %@", piece);
        }
    }
#endif
}

- (void)lazilyInitializeObjectServer {
#if !PROVIDING_OWN_ROS
    if (!self.isParent || s_task) {
        return;
    }
    NSPipe *pipe = [NSPipe pipe];
    NSMutableString *stringBuffer = [[NSMutableString alloc] init];
    __block BOOL inUseError = NO;
    [RLMSyncTestCase runResetObjectServer:YES];
    NSTask *task = [[NSTask alloc] init];
    NSString *currentDirPath = [[[RLMSyncTestCase rootRealmCocoaURL]
                                 URLByAppendingPathComponent:@"test-ros-instance/"] path];
    task.currentDirectoryPath = currentDirPath;
    task.launchPath = @"/usr/local/bin/node";
    // Warning: if the way the ROS is launched is changed, remember to also update
    // the regex in build.sh's kill_object_server() function.
    task.arguments = @[@"./ros/bin/ros", @"start", @"--auth", @"debug,password"];
    // Need to set the environment variables to bypass the mandatory email prompt.
    task.environment = @{@"ROS_TOS_EMAIL_ADDRESS": @"ci@realm.io",
                         @"DOCKER_DATA_PATH": @"/tmp"};
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    task.standardOutput = pipe;
    task.standardError = pipe;
    [[task.standardError fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSData *data = [file availableData];
        NSString *fragment = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [stringBuffer appendString:fragment];
        if ([stringBuffer rangeOfString:@"Realm Object Server has started and is listening"].location != NSNotFound) {
            [RLMSyncTestCase logObjectServerOutput:stringBuffer];
            dispatch_semaphore_signal(sema);
        } else if ([stringBuffer rangeOfString:@"Error: listen EADDRINUSE"].location != NSNotFound) {
            [RLMSyncTestCase logObjectServerOutput:stringBuffer];
            inUseError = YES;
            dispatch_semaphore_signal(sema);
        } else if ([fragment characterAtIndex:[fragment length] - 1] == '\n') {
            [RLMSyncTestCase logObjectServerOutput:stringBuffer];
            // Reached EOL, reset the string buffer.
            [stringBuffer setString:@""];
        }
    }];
    s_task = task;
    [task launch];
    const NSTimeInterval timeout = 60;
    BOOL wait_result = dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC))) == 0;
    if (!wait_result || inUseError) {
        s_task = nil;
        if (inUseError) {
            XCTFail(@"Server tried to start up, but the port was already in use (probably already running).");
        } else {
            XCTFail(@"Server did not start up within the allotted timeout interval.");
        }
        abort();
    }
#endif
}

+ (void)runResetObjectServer:(BOOL)initial {
    NSTask *task = [[NSTask alloc] init];
    task.currentDirectoryPath = [[RLMSyncTestCase rootRealmCocoaURL] path];
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"build.sh", initial ? @"reset-object-server" : @"reset-ros-client-state"];
    [task launch];
    [task waitUntilExit];
}

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    [self lazilyInitializeObjectServer];

    if (self.isParent) {
#if !PROVIDING_OWN_ROS
        XCTAssertNotNil(s_task, @"Test suite setup did not complete: server did not start properly.");
        [RLMSyncTestCase runResetObjectServer:NO];
#endif
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

#pragma mark - Test objects

@implementation PartialSyncObjectA

+ (instancetype)objectWithNumber:(NSInteger)number string:(NSString *)string {
    PartialSyncObjectA *object = [[PartialSyncObjectA alloc] init];
    object.number = number;
    object.string = string;
    return object;
}

@end

@implementation PartialSyncObjectB

+ (instancetype)objectWithNumber:(NSInteger)number firstString:(NSString *)first secondString:(NSString *)second {
    PartialSyncObjectB *object = [[PartialSyncObjectB alloc] init];
    object.number = number;
    object.firstString = first;
    object.secondString = second;
    return object;
}

@end
