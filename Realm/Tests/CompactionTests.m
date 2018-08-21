////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import "RLMTestCase.h"

@interface RLMRealm ()
- (BOOL)compact;
@end

@interface CompactionTests : RLMTestCase
@end

@implementation CompactionTests {
    uint64_t _expectedTotalBytesBefore;
}

static const NSUInteger expectedUsedBytesBeforeMin = 50000;
static const NSUInteger count = 1000;

#pragma mark - Helpers

- (unsigned long long)fileSize:(NSURL *)fileURL {
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURL.path error:nil];
    return [attributes[NSFileSize] unsignedLongLongValue];
}

- (void)setUp {
    [super setUp];
    @autoreleasepool {
        // Make compactable Realm
        RLMRealm *realm = self.realmWithTestPath;
        NSString *uuid = [[NSUUID UUID] UUIDString];
        [realm transactionWithBlock:^{
            [StringObject createInRealm:realm withValue:@[@"A"]];
            for (NSUInteger i = 0; i < count; ++i) {
                [StringObject createInRealm:realm withValue:@[uuid]];
            }
            [StringObject createInRealm:realm withValue:@[@"B"]];
        }];
    }
    _expectedTotalBytesBefore = [self fileSize:RLMTestRealmURL()];
}

#pragma mark - Tests

- (void)testCompact {
    RLMRealm *realm = self.realmWithTestPath;
    unsigned long long fileSizeBefore = [self fileSize:realm.configuration.fileURL];
    StringObject *object = [StringObject allObjectsInRealm:realm].firstObject;

    XCTAssertTrue([realm compact]);

    XCTAssertTrue(object.isInvalidated);
    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], count + 2);
    XCTAssertEqualObjects(@"A", [[StringObject allObjectsInRealm:realm].firstObject stringCol]);
    XCTAssertEqualObjects(@"B", [[StringObject allObjectsInRealm:realm].lastObject stringCol]);

    unsigned long long fileSizeAfter = [self fileSize:realm.configuration.fileURL];
    XCTAssertGreaterThan(fileSizeBefore, fileSizeAfter);
}

- (void)testSuccessfulCompactOnLaunch {
    // Configure the Realm to compact on launch
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.fileURL = RLMTestRealmURL();
    configuration.shouldCompactOnLaunch = ^BOOL(NSUInteger totalBytes, NSUInteger usedBytes){
        // Confirm expected sizes
        XCTAssertEqual(totalBytes, _expectedTotalBytesBefore);
        XCTAssertTrue((usedBytes < totalBytes) && (usedBytes > expectedUsedBytesBeforeMin));

        // Compact if the file is over 500KB in size and less than 20% 'used'
        // In practice, users might want to use values closer to 100MB and 50%
        NSUInteger fiveHundredKB = 500 * 1024;
        return (totalBytes > fiveHundredKB) && (usedBytes / totalBytes) < 0.2;
    };

    // Confirm expected sizes before and after opening the Realm
    XCTAssertEqual([self fileSize:configuration.fileURL], _expectedTotalBytesBefore);
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
    XCTAssertLessThan([self fileSize:configuration.fileURL], _expectedTotalBytesBefore);

    // Validate that the file still contains what it should
    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], count + 2);
    XCTAssertEqualObjects(@"A", [[StringObject allObjectsInRealm:realm].firstObject stringCol]);
    XCTAssertEqualObjects(@"B", [[StringObject allObjectsInRealm:realm].lastObject stringCol]);
}

- (void)testNoBlockCompactOnLaunch {
    // Configure the Realm to compact on launch
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.fileURL = RLMTestRealmURL();
    // Confirm expected sizes before and after opening the Realm
    XCTAssertEqual([self fileSize:configuration.fileURL], _expectedTotalBytesBefore);
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
    XCTAssertEqual([self fileSize:configuration.fileURL], _expectedTotalBytesBefore);

    // Validate that the file still contains what it should
    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], count + 2);
    XCTAssertEqualObjects(@"A", [[StringObject allObjectsInRealm:realm].firstObject stringCol]);
    XCTAssertEqualObjects(@"B", [[StringObject allObjectsInRealm:realm].lastObject stringCol]);
}

- (void)testCachedRealmCompactOnLaunch {
    // Test that the compaction block never gets called if there are cached Realms
    // Access Realm before opening it with a compaction block
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.fileURL = RLMTestRealmURL();
    __unused RLMRealm *firstRealm = [RLMRealm realmWithConfiguration:configuration error:nil];

    // Configure the Realm to compact on launch
    RLMRealmConfiguration *configurationWithCompactBlock = [configuration copy];
    __block BOOL compactBlockInvoked = NO;
    configurationWithCompactBlock.shouldCompactOnLaunch = ^BOOL(__unused NSUInteger totalBytes, __unused NSUInteger usedBytes){
        compactBlockInvoked = YES;
        // Always attempt to compact
        return YES;
    };

    // Confirm expected sizes before and after opening the Realm
    XCTAssertEqual([self fileSize:configuration.fileURL], _expectedTotalBytesBefore);
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configurationWithCompactBlock error:nil];
    XCTAssertFalse(compactBlockInvoked);
    XCTAssertEqual([self fileSize:configuration.fileURL], _expectedTotalBytesBefore);

    // Validate that the file still contains what it should
    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], count + 2);
    XCTAssertEqualObjects(@"A", [[StringObject allObjectsInRealm:realm].firstObject stringCol]);
    XCTAssertEqualObjects(@"B", [[StringObject allObjectsInRealm:realm].lastObject stringCol]);
}

- (void)testCachedRealmOtherThreadCompactOnLaunch {
    // Test that the compaction block never gets called if the Realm is open on a different thread
    // Access Realm before opening it with a compaction block
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.fileURL = RLMTestRealmURL();

    dispatch_semaphore_t failedCompactTestCompleteSema = dispatch_semaphore_create(0);
    dispatch_semaphore_t bgRealmClosedSema = dispatch_semaphore_create(0);

    XCTestExpectation *realmOpenedExpectation = [self expectationWithDescription:@"Realm was opened on background thread"];
    [self dispatchAsync:^{
        @autoreleasepool {
            __unused RLMRealm *firstRealm = [RLMRealm realmWithConfiguration:configuration error:nil];
            [realmOpenedExpectation fulfill];
            dispatch_semaphore_wait(failedCompactTestCompleteSema, DISPATCH_TIME_FOREVER);
        }
        dispatch_semaphore_signal(bgRealmClosedSema);
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];

    @autoreleasepool {
        // Configure the Realm to compact on launch
        RLMRealmConfiguration *configurationWithCompactBlock = [configuration copy];
        __block BOOL compactBlockInvoked = NO;

        configurationWithCompactBlock.shouldCompactOnLaunch = ^BOOL(__unused NSUInteger totalBytes, __unused NSUInteger usedBytes){
            compactBlockInvoked = YES;
            // Always attempt to compact
            return YES;
        };

        // Confirm expected sizes before and after opening the Realm
        XCTAssertEqual([self fileSize:configuration.fileURL], _expectedTotalBytesBefore);
        __unused RLMRealm *realm = [RLMRealm realmWithConfiguration:configurationWithCompactBlock error:nil];
        XCTAssertFalse(compactBlockInvoked);
        XCTAssertEqual([self fileSize:configuration.fileURL], _expectedTotalBytesBefore);
        dispatch_semaphore_signal(failedCompactTestCompleteSema);
    }

    dispatch_semaphore_wait(bgRealmClosedSema, DISPATCH_TIME_FOREVER);

    // Configure the Realm to compact on launch
    RLMRealmConfiguration *configurationWithCompactBlock = [configuration copy];
    __block BOOL compactBlockInvoked = NO;

    configurationWithCompactBlock.shouldCompactOnLaunch = ^BOOL(NSUInteger totalBytes, NSUInteger usedBytes){
        // Confirm expected sizes
        XCTAssertEqual(totalBytes, _expectedTotalBytesBefore);
        XCTAssertTrue((usedBytes < totalBytes) && (usedBytes > expectedUsedBytesBeforeMin));

        // Compact if the file is over 500KB in size and less than 20% 'used'
        // In practice, users might want to use values closer to 100MB and 50%
        NSUInteger fiveHundredKB = 500 * 1024;
        BOOL shouldCompact = (totalBytes > fiveHundredKB) && (usedBytes / totalBytes) < 0.2;
        compactBlockInvoked = YES;
        return shouldCompact;
    };

    // Confirm expected sizes before and after opening the Realm
    XCTAssertEqual([self fileSize:configuration.fileURL], _expectedTotalBytesBefore);
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configurationWithCompactBlock error:nil];
    XCTAssertTrue(compactBlockInvoked);
    XCTAssertLessThan([self fileSize:configuration.fileURL], _expectedTotalBytesBefore);

    // Validate that the file still contains what it should
    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], count + 2);
    XCTAssertEqualObjects(@"A", [[StringObject allObjectsInRealm:realm].firstObject stringCol]);
    XCTAssertEqualObjects(@"B", [[StringObject allObjectsInRealm:realm].lastObject stringCol]);
}

- (void)testReturnNoCompactOnLaunch {
    // Configure the Realm to compact on launch
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.fileURL = RLMTestRealmURL();
    configuration.shouldCompactOnLaunch = ^BOOL(NSUInteger totalBytes, NSUInteger usedBytes){
        // Confirm expected sizes
        XCTAssertEqual(totalBytes, _expectedTotalBytesBefore);
        XCTAssertTrue((usedBytes < totalBytes) && (usedBytes > expectedUsedBytesBeforeMin));

        // Don't compact.
        return NO;
    };

    // Confirm expected sizes before and after opening the Realm
    XCTAssertEqual([self fileSize:configuration.fileURL], _expectedTotalBytesBefore);
    RLMRealm *realm = [RLMRealm realmWithConfiguration:configuration error:nil];
    XCTAssertEqual([self fileSize:configuration.fileURL], _expectedTotalBytesBefore);

    // Validate that the file still contains what it should
    XCTAssertEqual([[StringObject allObjectsInRealm:realm] count], count + 2);
    XCTAssertEqualObjects(@"A", [[StringObject allObjectsInRealm:realm].firstObject stringCol]);
    XCTAssertEqualObjects(@"B", [[StringObject allObjectsInRealm:realm].lastObject stringCol]);
}

- (void)testCompactOnLaunchValidation {
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.readOnly = YES;

    BOOL (^compactBlock)(NSUInteger, NSUInteger) = ^BOOL(__unused NSUInteger totalBytes, __unused NSUInteger usedBytes){
        return NO;
    };
    RLMAssertThrowsWithReasonMatching(configuration.shouldCompactOnLaunch = compactBlock,
                                      @"Cannot set `shouldCompactOnLaunch` when `readOnly` is set.");

    configuration.readOnly = NO;
    configuration.shouldCompactOnLaunch = compactBlock;
    RLMAssertThrowsWithReasonMatching(configuration.readOnly = YES,
                                      @"Cannot set `readOnly` when `shouldCompactOnLaunch` is set.");
}

- (void)testAccessDeniedOnTemporaryFile {
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.fileURL = RLMTestRealmURL();
    configuration.shouldCompactOnLaunch = ^(__unused NSUInteger totalBytes, __unused NSUInteger usedBytes){
        return YES;
    };
    NSURL *tmpURL = [configuration.fileURL URLByAppendingPathExtension:@"tmp_compaction_space"];
    [NSData.data writeToURL:tmpURL atomically:NO];
    [NSFileManager.defaultManager setAttributes:@{NSFileImmutable: @YES} ofItemAtPath:tmpURL.path error:nil];
    RLMAssertThrowsWithReason([RLMRealm realmWithConfiguration:configuration error:nil],
                              @"unlink() failed: Operation not permitted");
    [NSFileManager.defaultManager setAttributes:@{NSFileImmutable: @NO} ofItemAtPath:tmpURL.path error:nil];
    XCTAssertNoThrow([RLMRealm realmWithConfiguration:configuration error:nil]);
}

@end
