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

#import "RLMSyncManager+ObjectServerTests.h"
#import "RLMSyncUser+ObjectServerTests.h"

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

@implementation SyncObject
@end

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

+ (RLMSyncCredential *)basicCredential:(BOOL)createAccount {
    return [RLMSyncCredential credentialWithUsername:@"a"
                                            password:@"a"
                                             actions:(createAccount
                                                      ? RLMAuthenticationActionsCreateAccount
                                                      : RLMAuthenticationActionsUseExistingAccount)];
}

- (void)addSyncObjectsToRealm:(RLMRealm *)realm descriptions:(NSArray<NSString *> *)descriptions {
    [realm beginWriteTransaction];
    for (NSString *desc in descriptions) {
        [realm addObject:[[SyncObject alloc] initWithValue:@[desc]]];
    }
    [realm commitWriteTransaction];
}

- (void)waitForDownloadsForUser:(RLMSyncUser *)user
                         realms:(NSArray<RLMRealm *> *)realms
                      realmURLs:(NSArray<NSURL *> *)realmURLs
                 expectedCounts:(NSArray<NSNumber *> *)counts {
    NSAssert(realms.count == counts.count && realms.count == realmURLs.count,
             @"Test logic error: all array arguments must be the same size.");
    XCTestExpectation *checkCountExpectation = [self expectationWithDescription:@"Downloads should complete"];
    for (NSUInteger i = 0; i < realms.count; i++) {
        WAIT_FOR_DOWNLOAD(user, realmURLs[i]);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSUInteger i = 0; i < realms.count; i++) {
            CHECK_COUNT([counts[i] integerValue], SyncObject, realms[i]);
        }
        [checkCountExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:20.0 handler:nil];
}

- (RLMRealm *)openRealmForURL:(NSURL *)url user:(RLMSyncUser *)user {
    NSError *error = nil;
    const NSTimeInterval timeout = 4;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    RLMSyncBasicErrorReportingBlock basicBlock = ^(NSError *error) {
        if (error) {
            XCTFail(@"Received an asynchronous error: %@ (process: %@)", error, self.isParent ? @"parent" : @"child");
        }
        dispatch_semaphore_signal(sema);
    };
    [[RLMSyncManager sharedManager] setSessionCompletionNotifier:basicBlock];
    RLMRealmConfiguration *c = [[RLMRealmConfiguration defaultConfiguration] copy];
    c.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:url];
    RLMRealm *r = [RLMRealm realmWithConfiguration:c error:&error];
    // Wait for login to succeed or fail.
    XCTAssert(dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC))) == 0,
              @"Timed out while trying to asynchronously open Realm for URL: %@", url);
    return r;
}

- (RLMRealm *)immediatelyOpenRealmForURL:(NSURL *)url user:(RLMSyncUser *)user {
    NSError *error = nil;
    RLMRealmConfiguration *c = [[RLMRealmConfiguration defaultConfiguration] copy];
    c.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:url];
    RLMRealm *r = [RLMRealm realmWithConfiguration:c error:&error];
    XCTAssertNil(error, @"Experienced an error opening the Realm at %@: %@", url, error);
    return r;
}

- (RLMSyncUser *)logInUserForCredential:(RLMSyncCredential *)credential
                                 server:(NSURL *)url {
    NSString *process = self.isParent ? @"parent" : @"child";
    __block RLMSyncUser *theUser = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Should log in the user properly"];
    [RLMSyncUser authenticateWithCredential:credential
                              authServerURL:url
                               onCompletion:^(RLMSyncUser *user, NSError *error) {
                                   XCTAssertNotNil(user);
                                   XCTAssertNil(error,
                                                @"Error when trying to log in a user: %@ (process: %@)",
                                                error, process);
                                   theUser = user;
                                   [expectation fulfill];
                               }];
    [self waitForExpectationsWithTimeout:4.0 handler:nil];
    XCTAssertTrue(theUser.state == RLMSyncUserStateActive,
                  @"User should have been valid, but wasn't. (process: %@)", process);
    return theUser;
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

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;

    if (!self.isParent) {
        // Don't start the sync server if not the originating process.
        // Do configure the sync manager to use a different directory than the parent process.
        s_managerForTest = [[RLMSyncManager alloc] initWithCustomRootDirectory:syncDirectoryForChildProcess()];
        return;
    } else {
        s_managerForTest = [[RLMSyncManager alloc] initWithCustomRootDirectory:nil];
    }

    // FIXME: we need a more robust way of waiting till a test's server process has completed cleaning
    // up before starting another test.
    sleep(1);
    [RLMSyncManager sharedManager].logLevel = RLMSyncLogLevelOff;
    self.task = [[NSTask alloc] init];
    self.task.currentDirectoryPath = [[RLMSyncTestCase rootRealmCocoaURL] path];
    self.task.launchPath = @"/bin/sh";
    self.task.arguments = @[@"build.sh", @"start-object-server"];
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    self.task.standardOutput = [NSPipe pipe];
    [[self.task.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSData *data = [file availableData];
        NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if ([output containsString:@"Received: IDENT"]) {
            dispatch_semaphore_signal(sema);
        }
    }];
    [self.task launch];
    const NSTimeInterval timeout = 60;
    XCTAssert(dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC))) == 0,
              @"Object server did not launch properly, terminating test...");
}

- (void)tearDown {
    [s_managerForTest prepareForDestruction];
    usleep(500000);
    if (self.isParent) {
        [self.task terminate];
        self.task = [[NSTask alloc] init];
        self.task.currentDirectoryPath = [[RLMSyncTestCase rootRealmCocoaURL] path];
        self.task.launchPath = @"/bin/sh";
        self.task.arguments = @[@"build.sh", @"reset-object-server"];
        self.task.standardOutput = [NSPipe pipe];
        [self.task launch];
        [self.task waitUntilExit];
        usleep(500000);
    }
    s_managerForTest = nil;
    [super tearDown];
}

- (int)runChildAndWait {
    int value = [super runChildAndWait];
    // Give client some time to stop asynchronous work before killing server.
    usleep(20000);
    return value;
}

@end
