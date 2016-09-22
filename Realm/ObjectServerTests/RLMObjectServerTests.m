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

#import <XCTest/XCTest.h>
#import <Realm/Realm.h>
#import "RLMTestCase.h"

@interface SyncObject : RLMObject
@property NSString *stringProp;
@end
@implementation SyncObject
@end

@interface RLMObjectServerTests : RLMTestCase
@property (nonatomic, strong) NSTask *task;
@end

@implementation RLMObjectServerTests

+ (NSURL *)rootRealmCocoaURL {
    return [[[[NSURL fileURLWithPath:@(__FILE__)] URLByDeletingLastPathComponent] URLByDeletingLastPathComponent] URLByDeletingLastPathComponent];
}

+ (NSURL *)authServerURL {
    return [NSURL URLWithString:@"http://127.0.0.1:8080"];
}

+ (void)setUp {
    [super setUp];
    NSString *syncDirectory = [[[RLMObjectServerTests rootRealmCocoaURL] URLByAppendingPathComponent:@"sync"] path];
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:syncDirectory isDirectory:&isDirectory] || !isDirectory) {
        NSLog(@"sync/ directory doesn't exist. You need to run 'build.sh download-object-server' prior to running these tests");
        abort();
    }
}

- (void)setUp {
    [super setUp];
    self.task = [[NSTask alloc] init];
    self.task.currentDirectoryPath = [[RLMObjectServerTests rootRealmCocoaURL] path];
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
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

- (void)tearDown {
    [super tearDown];
    [self.task terminate];
    self.task = [[NSTask alloc] init];
    self.task.currentDirectoryPath = [[RLMObjectServerTests rootRealmCocoaURL] path];
    self.task.launchPath = @"/bin/sh";
    self.task.arguments = @[@"build.sh", @"reset-object-server"];
    self.task.standardOutput = [NSPipe pipe];
    [self.task launch];
    [self.task waitUntilExit];
}

#pragma mark - Authentication

- (void)testUsernamePasswordAuthentication {
    __block RLMSyncUser *firstUser = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [RLMSyncUser authenticateWithCredential:[RLMSyncCredential credentialWithUsername:@"a" password:@"a" actions:RLMAuthenticationActionsCreateAccount]
                              authServerURL:[RLMObjectServerTests authServerURL]
                               onCompletion:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNotNil(user);
        XCTAssertNil(error);
        firstUser = user;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [RLMSyncUser authenticateWithCredential:[RLMSyncCredential credentialWithUsername:@"a" password:@"a" actions:RLMAuthenticationActionsUseExistingAccount]
                              authServerURL:[RLMObjectServerTests authServerURL]
                               onCompletion:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNotNil(user);
        XCTAssertNil(error);
        // Logging in with equivalent credentials should return the same user object instance.
        XCTAssertEqual(user, firstUser);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    expectation = [self expectationWithDescription:@""];
    [RLMSyncUser authenticateWithCredential:[RLMSyncCredential credentialWithUsername:@"a" password:@"a" actions:RLMAuthenticationActionsCreateAccount]
                              authServerURL:[RLMObjectServerTests authServerURL]
                               onCompletion:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNil(user);
        XCTAssertNotNil(error);
        // FIXME: Improve error message
        XCTAssertEqualObjects(error.localizedDescription, @"The operation couldn’t be completed. (io.realm.sync error 3.)");
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testAdminTokenAuthentication {
    NSString *syncDirectoryPath = [[[RLMObjectServerTests rootRealmCocoaURL] URLByAppendingPathComponent:@"sync"] path];
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:syncDirectoryPath];

    NSURL *adminTokenFileURL = nil;
    for (NSString *filename in fileEnumerator) {
        if ([[filename lastPathComponent] isEqualToString:@"admin_token.base64"]) {
            adminTokenFileURL = [[[RLMObjectServerTests rootRealmCocoaURL] URLByAppendingPathComponent:@"sync"] URLByAppendingPathComponent:filename];
        }
    }
    XCTAssertNotNil(adminTokenFileURL);
    NSString *adminToken = [NSString stringWithContentsOfURL:adminTokenFileURL encoding:NSUTF8StringEncoding error:nil];
    XCTAssertNotNil(adminToken);
    RLMSyncCredential *credential = [RLMSyncCredential credentialWithAccessToken:adminToken identity:@"test"];
    XCTAssertNotNil(credential);

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [RLMSyncUser authenticateWithCredential:credential
                              authServerURL:[RLMObjectServerTests authServerURL]
                               onCompletion:^(RLMSyncUser *user, NSError *error) {
        XCTAssertNotNil(user);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

#pragma mark - User Persistence

- (void)testBasicUserPersistence {
    XCTAssertEqual([[RLMSyncUser all] count], 0U);

    __block RLMSyncUser *user = nil;
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [RLMSyncUser authenticateWithCredential:[RLMSyncCredential credentialWithUsername:@"a" password:@"a" actions:RLMAuthenticationActionsCreateAccount]
                              authServerURL:[RLMObjectServerTests authServerURL]
                               onCompletion:^(RLMSyncUser *completionUser, NSError *error) {
        XCTAssertNotNil(completionUser);
        user = completionUser;
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    XCTAssertNotNil(user);
    XCTAssertEqual([[RLMSyncUser all] count], 1U);
    XCTAssertTrue([[RLMSyncUser all] containsObject:user]);
}

#pragma mark - Sync

- (void)testBasicSync {
    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    __block RLMSyncUser *user = nil;
    [RLMSyncUser authenticateWithCredential:[RLMSyncCredential credentialWithUsername:@"a" password:@"a" actions:RLMAuthenticationActionsCreateAccount]
                              authServerURL:[RLMObjectServerTests authServerURL]
                               onCompletion:^(RLMSyncUser *completionUser, NSError *error) {
        XCTAssertNotNil(completionUser);
        user = completionUser;
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.syncConfiguration = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:[NSURL URLWithString:@"realm://localhost:8080/~/testBasicSync"]];
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
    XCTAssertNil(error);
    XCTAssertTrue(realm.isEmpty);

    // FIXME: remove once https://github.com/realm/realm-cocoa-private/issues/281 is resolved
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
}

@end
