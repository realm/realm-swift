////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

#import "RLMApp_Private.hpp"

#if TARGET_OS_OSX

#pragma mark ObjectServer Partition Tests

@interface RLMObjectServerPartitionTests : RLMSyncTestCase
@end

@implementation RLMObjectServerPartitionTests

- (void)roundTripForPartitionValue:(id<RLMBSON>)value {
    NSError *error;
    NSString *appId = [RealmServer.shared
                       createAppWithPartitionKeyType:[self partitionBsonType:value]
                       types:@[Person.self] persistent:false error:&error];
    if (error) {
        return XCTFail(@"Could not create app for partition value %@d", value);
    }

    RLMApp *app = [self appWithId:appId];
    RLMUser *user = [self createUserForApp:app];
    RLMRealm *realm = [self openRealmForPartitionValue:value user:user];
    CHECK_COUNT(0, Person, realm);

    RLMUser *writeUser = [self createUserForApp:app];
    RLMRealm *writeRealm = [self openRealmForPartitionValue:value user:writeUser];

    auto write = [&] {
        [self addPersonsToRealm:writeRealm
                        persons:@[[Person john], [Person paul], [Person ringo]]];
        [self waitForUploadsForRealm:writeRealm];
        [self waitForDownloadsForRealm:realm];
    };

    write();
    CHECK_COUNT(3, Person, realm);
    XCTAssertEqual([Person objectsInRealm:realm where:@"firstName = 'John'"].count, 1UL);

    write();
    CHECK_COUNT(6, Person, realm);
    XCTAssertEqual([Person objectsInRealm:realm where:@"firstName = 'John'"].count, 2UL);
}

- (void)testRoundTripForObjectIdPartitionValue {
    [self roundTripForPartitionValue:[[RLMObjectId alloc] initWithString:@"1234567890ab1234567890ab" error:nil]];
}

- (void)testRoundTripForUUIDPartitionValue {
    [self roundTripForPartitionValue:[[NSUUID alloc] initWithUUIDString:@"85d4fbee-6ec6-47df-bfa1-615931903d7e"]];
}

- (void)testRoundTripForStringPartitionValue {
    [self roundTripForPartitionValue:@"1234567890ab1234567890ab"];
}

- (void)testRoundTripForIntPartitionValue {
    [self roundTripForPartitionValue:@1234567890];
}

@end

#endif // TARGET_OS_OSX
