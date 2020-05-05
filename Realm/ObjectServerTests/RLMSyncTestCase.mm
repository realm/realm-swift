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
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncConfiguration_Private.h"
#import "RLMUtil.hpp"
#import "RLMApp.h"

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
- (NSArray<RLMSyncUser *> *)_allUsers;
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

@implementation Dog

+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray *)requiredProperties {
    return @[@"_id", @"name"];
}

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [RLMObjectId objectId]};
}

@end

@implementation Person

+ (NSDictionary *)defaultPropertyValues {
    return @{@"_id": [RLMObjectId objectId]};
}

+ (NSString *)primaryKey {
    return @"_id";
}

+ (NSArray *)requiredProperties {
    return @[@"_id", @"firstName", @"lastName", @"age", @"dogs"];
}

+ (instancetype)john {
    Person *john = [[Person alloc] init];
    john._id = [RLMObjectId objectId];
    john.age = 30;
    john.firstName = @"John";
    john.lastName = @"Lennon";
    return john;
}

+ (instancetype)paul {
    Person *paul = [[Person alloc] init];
    paul._id = [RLMObjectId objectId];
    paul.age = 30;
    paul.firstName = @"Paul";
    paul.lastName = @"McCartney";
    return paul;
}

+ (instancetype)ringo {
    Person *ringo = [[Person alloc] init];
    ringo._id = [RLMObjectId objectId];
    ringo.age = 30;
    ringo.firstName = @"Ringo";
    ringo.lastName = @"Starr";
    return ringo;
}

+ (instancetype)george {
    Person *george = [[Person alloc] init];
    george._id = [RLMObjectId objectId];
    george.age = 30;
    george.firstName = @"George";
    george.lastName = @"Harrison";
    return george;
}

@end

static NSTask *s_task;

static NSURL *syncDirectoryForChildProcess() {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundleIdentifier = bundle.bundleIdentifier ?: bundle.executablePath.lastPathComponent;
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-child", bundleIdentifier]];
    return [NSURL fileURLWithPath:path isDirectory:YES];
}

@interface RealmObjectServer : NSObject
@property (nonatomic, readonly) NSString *appId;
+ (instancetype)sharedServer;

- (NSString *)createApp;

@end

@implementation RealmObjectServer {
}

+ (instancetype)sharedServer {
    static RealmObjectServer *instance = [RealmObjectServer new];
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self downloadAdminSDK];

        NSString *directory = [@(__FILE__) stringByDeletingLastPathComponent];

        NSTask *task = [[NSTask alloc] init];
        task.currentDirectoryPath = directory;
        task.launchPath = @"/bin/sh";
        task.arguments = @[@"run_baas.sh"];
        [task launch];
        [task waitUntilExit];

        __block BOOL isLive = NO;
        NSInteger tryCount = 0;
        const NSTimeInterval timeout = 4;

        while (tryCount < 100 && !isLive) {
            __block dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            [[[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]]
              dataTaskWithURL:[NSURL URLWithString:@"http://127.0.0.1:9090"]
              completionHandler:^(NSData * _Nullable, NSURLResponse * _Nullable response, NSError * _Nullable) {
                NSHTTPURLResponse *urlResponse = (NSHTTPURLResponse *)response;
                isLive = [urlResponse statusCode] == 200;
                dispatch_semaphore_signal(sema);
            }] resume];

            BOOL canConnect = dispatch_semaphore_wait(sema,
                                                      dispatch_time(DISPATCH_TIME_NOW,
                                                                    (int64_t)(timeout * NSEC_PER_SEC))) == 0;

            if (!canConnect) {
                NSLog(@"Timed out while trying to connect to MongoDB Realm at http://127.0.0.1:9090");
                abort();
            }

            tryCount++;
        }

        if (!isLive) {
            NSLog(@"Timed out while trying to connect to MongoDB Realm at http://127.0.0.1:9090");
            abort();
        }

        atexit([] {
//            [[RealmObjectServer sharedServer] cleanUp];
        });
    }
    return self;
}

- (void)cleanUp {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = nodePath();
    NSString *directory = [@(__FILE__) stringByDeletingLastPathComponent];
    task.arguments = @[[directory stringByAppendingPathComponent:@"admin.js"], @"clean"];
    [task launch];
    [task waitUntilExit];

    task = [[NSTask alloc] init];
    task.currentDirectoryPath = directory;
    task.launchPath = @"/bin/sh";
    task.arguments = @[[directory stringByAppendingPathComponent:@"run_baas.sh"], @"clean"];
    [task launch];
    [task waitUntilExit];

    [[NSTask launchedTaskWithLaunchPath:@"/usr/bin/pkill"
                              arguments:@[@"-f", @"stitch"]] waitUntilExit];
}

- (NSString *)createApp {
    // Set up the actual MongoDB Realm creation task
    NSPipe *pipe = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = nodePath();
    NSString *directory = [@(__FILE__) stringByDeletingLastPathComponent];
    task.arguments = @[[directory stringByAppendingPathComponent:@"admin.js"], @"create"];
    task.standardOutput = pipe;
    [task launch];

    NSData *childStdout = pipe.fileHandleForReading.readDataToEndOfFile;
    NSString *appId = [[NSString alloc] initWithData:childStdout encoding:NSUTF8StringEncoding];

    if (!appId.length) {
        abort();
    }

    return appId;
}

- (NSString *)lastApp {
    // Set up the actual MongoDB Realm last app task
    NSPipe *pipe = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = nodePath();
    NSString *directory = [@(__FILE__) stringByDeletingLastPathComponent];
    task.arguments = @[[directory stringByAppendingPathComponent:@"admin.js"], @"last"];
    task.standardOutput = pipe;
    [task launch];

    NSData *childStdout = pipe.fileHandleForReading.readDataToEndOfFile;
    NSString *appId = [[NSString alloc] initWithData:childStdout encoding:NSUTF8StringEncoding];

    if (!appId.length) {
        abort();
    }

    return appId;
}


- (NSString *)desiredAdminSDKVersion {
    auto path = [[[[@(__FILE__) stringByDeletingLastPathComponent] // RLMSyncTestCase.mm
                   stringByDeletingLastPathComponent] // ObjectServerTests
                  stringByDeletingLastPathComponent] // Realm
                 stringByAppendingPathComponent:@"dependencies.list"];
    auto file = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!file) {
        NSLog(@"Failed to read dependencies.list");
        abort();
    }

    auto regex = [NSRegularExpression regularExpressionWithPattern:@"^MONGODB_STITCH_ADMIN_SDK_VERSION=(.*)$"
                                                           options:NSRegularExpressionAnchorsMatchLines error:nil];
    auto match = [regex firstMatchInString:file options:0 range:{0, file.length}];
    if (!match) {
        NSLog(@"Failed to read MONGODB_STITCH_ADMIN_SDK_VERSION from dependencies.list");
        abort();
    }
    return [file substringWithRange:[match rangeAtIndex:1]];
}

- (NSString *)currentAdminSDKVersion {
    auto path = [[[[@(__FILE__) stringByDeletingLastPathComponent] // RLMSyncTestCase.mm
                 stringByAppendingPathComponent:@"node_modules"]
                 stringByAppendingPathComponent:@"mongodb-stitch"]
                 stringByAppendingPathComponent:@"package.json"];
    auto file = [NSData dataWithContentsOfFile:path];
    if (!file) {
        return nil;
    }

    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:file options:0 error:&error];
    if (!json) {
        NSLog(@"Error reading version from installed Admin SDK: %@", error);
        abort();
    }

    return json[@"version"];
}

- (void)downloadAdminSDK {
    NSString *desiredVersion = [self desiredAdminSDKVersion];
    NSString *currentVersion = [self currentAdminSDKVersion];
    if ([currentVersion isEqualToString:desiredVersion]) {
        return;
    }

    NSLog(@"Installing Realm Cloud %@", desiredVersion);
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
                       [@"mongodb-stitch@" stringByAppendingString:desiredVersion]
    ];
    [task launch];
    [task waitUntilExit];
}
@end

@implementation RLMSyncTestCase

#pragma mark - Helper methods

- (BOOL)isPartial {
    return NO;
}

- (RLMApp *)app {
    return [RLMApp app:self.appId configuration:[self defaultAppConfiguration]];
}

- (RLMAppCredentials *)basicCredentialsWithName:(NSString *)name register:(BOOL)shouldRegister {
    if (shouldRegister) {
        XCTestExpectation *expectation = [self expectationWithDescription:@""];
        [[[self app] usernamePasswordProviderClient] registerEmail:name password:@"password" completion:^(NSError * _Nullable error) {
            XCTAssertNil(error);
            [expectation fulfill];
        }];
        [self waitForExpectationsWithTimeout:4.0 handler:nil];
    }
    return [RLMAppCredentials credentialsWithUsername:name
                                             password:@"password"];
}

+ (NSURL *)onDiskPathForSyncedRealm:(RLMRealm *)realm {
    return [NSURL fileURLWithPath:@(realm->_realm->config().path.data())];
}

- (RLMAppConfiguration*) defaultAppConfiguration {
    return  [[RLMAppConfiguration alloc] initWithBaseURL:@"http://localhost:9090"
                                               transport:nil
                                            localAppName:nil
                                         localAppVersion:nil
                                 defaultRequestTimeoutMS:60];
}

- (void)addPersonsToRealm:(RLMRealm *)realm persons:(NSArray<Person *> *)persons {
    [realm beginWriteTransaction];
    [realm addObjects:persons];
    [realm commitWriteTransaction];
}

- (void)waitForDownloadsForUser:(RLMSyncUser *)user
                         realms:(NSArray<RLMRealm *> *)realms
                      partitionValues:(NSArray<NSString *> *)partitionValues
                 expectedCounts:(NSArray<NSNumber *> *)counts {
    NSAssert(realms.count == counts.count && realms.count == partitionValues.count,
             @"Test logic error: all array arguments must be the same size.");
    for (NSUInteger i = 0; i < realms.count; i++) {
        [self waitForDownloadsForUser:user partitionValue:partitionValues[i] expectation:nil error:nil];
        [realms[i] refresh];
        CHECK_COUNT([counts[i] integerValue], Person, realms[i]);
    }
}

- (RLMRealm *)openRealmForPartitionValue:(NSString *)partitionValue user:(RLMSyncUser *)user {
    return [self openRealmForPartitionValue:partitionValue user:user immediatelyBlock:nil];
}

- (RLMRealm *)openRealmForPartitionValue:(NSString *)partitionValue user:(RLMSyncUser *)user immediatelyBlock:(void(^)(void))block {
    return [self openRealmForPartitionValue:partitionValue
                                       user:user
                              encryptionKey:nil
                                 stopPolicy:RLMSyncStopPolicyAfterChangesUploaded
                           immediatelyBlock:block];
}

- (RLMRealm *)openRealmForPartitionValue:(NSString *)partitionValue
                                    user:(RLMSyncUser *)user
                           encryptionKey:(nullable NSData *)encryptionKey
                              stopPolicy:(RLMSyncStopPolicy)stopPolicy
                        immediatelyBlock:(nullable void(^)(void))block {
    RLMRealm *realm = [self immediatelyOpenRealmForPartitionValue:partitionValue user:user encryptionKey:encryptionKey stopPolicy:stopPolicy];
    if (block) {
        block();
    }
    return realm;
}

- (RLMRealm *)openRealmWithConfiguration:(RLMRealmConfiguration *)configuration {
    return [self openRealmWithConfiguration:configuration immediatelyBlock:nullptr];
}

- (RLMRealm *)openRealmWithConfiguration:(RLMRealmConfiguration *)configuration
                        immediatelyBlock:(nullable void(^)(void))block {
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nullptr];
    if (block) {
        block();
    }
    return realm;
}
- (RLMRealm *)immediatelyOpenRealmForPartitionValue:(NSString *)partitionValue user:(RLMSyncUser *)user {
    return [self immediatelyOpenRealmForPartitionValue:partitionValue
                                                  user:user
                                         encryptionKey:nil
                                            stopPolicy:RLMSyncStopPolicyAfterChangesUploaded];
}

- (RLMRealm *)immediatelyOpenRealmForPartitionValue:(NSString *)partitionValue
                                               user:(RLMSyncUser *)user
                                      encryptionKey:(NSData *)encryptionKey
                                         stopPolicy:(RLMSyncStopPolicy)stopPolicy {
    auto c = [user configurationWithPartitionValue:partitionValue];
    c.encryptionKey = encryptionKey;
    RLMSyncConfiguration *syncConfig = c.syncConfiguration;
    syncConfig.stopPolicy = stopPolicy;
    c.syncConfiguration = syncConfig;
    return [RLMRealm realmWithConfiguration:c error:nil];
}

- (RLMSyncUser *)logInUserForCredentials:(RLMAppCredentials *)credentials {
    RLMApp *app = [self app];
    __block RLMSyncUser* theUser;
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [app loginWithCredential:credentials completion:^(RLMSyncUser * _Nullable user, NSError * _Nullable) {
        theUser = user;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
    XCTAssertTrue(theUser.state == RLMSyncUserStateLoggedIn, @"User should have been valid, but wasn't");
    return theUser;
}

- (void)waitForDownloadsForRealm:(RLMRealm *)realm {
    [self waitForDownloadsForRealm:realm error:nil];
}

- (void)waitForUploadsForRealm:(RLMRealm *)realm {
    [self waitForUploadsForRealm:realm error:nil];
}

- (void)waitForDownloadsForUser:(RLMSyncUser *)user
                 partitionValue:(NSString *)partitionValue
                    expectation:(XCTestExpectation *)expectation
                          error:(NSError **)error {
    RLMSyncSession *session = [user sessionForPartitionValue:partitionValue];
    NSAssert(session, @"Cannot call with invalid partition value");
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
    [self waitForExpectations:@[ex] timeout:20.0];
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
    [self waitForExpectations:@[ex] timeout:20.0];
    if (error)
        *error = completionError;
}

- (void)manuallySetAccessTokenForUser:(RLMSyncUser *)user value:(NSString *)tokenValue {
    [user _syncUser]->update_access_token(tokenValue.UTF8String);
}

// FIXME: remove this API once the new token system is implemented.
- (void)primeSyncManagerWithSemaphore:(dispatch_semaphore_t)semaphore {
    if (semaphore == nil) {
        [[[self app] sharedManager] setSessionCompletionNotifier:^(__unused NSError *error){ }];
        return;
    }
    [[[self app] sharedManager] setSessionCompletionNotifier:^(NSError *error) {
        XCTAssertNil(error, @"Session completion block returned with an error: %@", error);
        dispatch_semaphore_signal(semaphore);
    }];
}

#pragma mark - XCUnitTest Lifecycle

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;


    [self resetSyncManager];

    static bool is_parent = [self isParent];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
//        if (is_parent) [[RealmObjectServer sharedServer] cleanUp];
    });
    atexit([] {
//        if (is_parent) [[RealmObjectServer sharedServer] cleanUp];
    });
    [self setupSyncManager];
}

- (void)tearDown {
    [self resetSyncManager];
    [super tearDown];
}

- (void)setupSyncManager {
    NSURL *clientDataRoot;
    if (self.isParent) {
        _appId = [RealmObjectServer.sharedServer createApp];
        clientDataRoot = [NSURL fileURLWithPath:RLMDefaultDirectoryForBundleIdentifier(nil)];
    }
    else {
        _appId = [RealmObjectServer.sharedServer lastApp];
        clientDataRoot = syncDirectoryForChildProcess();
    }

    NSError *error;
    [NSFileManager.defaultManager removeItemAtURL:clientDataRoot error:&error];
    [NSFileManager.defaultManager createDirectoryAtURL:clientDataRoot
                           withIntermediateDirectories:YES attributes:nil error:&error];

    RLMSyncManager *syncManager = [[self app] sharedManager];

    [syncManager configureWithRootDirectory:clientDataRoot appConfiguration:[[self app] configuration]];
    syncManager.logLevel = RLMSyncLogLevelTrace;
    syncManager.userAgent = self.name;
}

- (void)resetSyncManager {
    if ([self appId]) {
        for (NSString *key in [[self app] allUsers]) {
            RLMSyncUser *user = [[self app] allUsers][key];
            XCTestExpectation *ex = [self expectationWithDescription:@"Wait for logout"];
            [[self app] logOut:user completion:^(NSError * _Nullable error) {
                XCTAssertNil(error);
                [ex fulfill];
            }];
            [self waitForExpectations:@[ex] timeout:20.0];
        }
    }
    [RLMSyncManager resetForTesting];
}

@end
