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

@implementation CompactionTests

#pragma mark - Expected Sizes

NSUInteger count = 1000;

#pragma mark - Helpers

- (unsigned long long)fileSize:(NSURL *)fileURL {
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURL.path error:nil];
    return [(NSNumber *)attributes[NSFileSize] unsignedLongLongValue];
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

@end
