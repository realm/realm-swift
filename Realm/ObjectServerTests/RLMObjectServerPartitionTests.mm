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

#pragma mark - Helpers

// These are defined in Swift. Importing the auto-generated header doesn't work
// when building with SPM, so just redeclare the bits we need.
@interface RealmServer : NSObject
+ (RealmServer *)shared;
- (NSString *)createAppForBSONType:(NSString *)bsonType
                             error:(NSError **)error;;
@end

#pragma mark ObjectServer Partition Tests

@interface RLMObjectServerPartitionTests : RLMSyncTestCase
@end

@implementation RLMObjectServerPartitionTests

- (void)roundTripForPartitionValue:(id<RLMBSON>)value  {
    NSString *appId;
    if (self.isParent) {
        NSError *error;
        appId = [RealmServer.shared createAppForBSONType:[self partitionBsonType:value] error:&error];

        if (error) {
            XCTFail(@"Could not create app for partition value %@d", value);
            return;
        }
    } else {
        appId = self.appIds[0];
    }

    RLMApp *app = [RLMApp appWithId:appId
                      configuration:[self defaultAppConfiguration]
                      rootDirectory:[self clientDataRoot]];
    RLMCredentials *credentials = [self basicCredentialsWithName:NSStringFromSelector(_cmd)
                                                        register:self.isParent
                                                             app:app];
    RLMUser *user = [self logInUserForCredentials:credentials app:app];
    RLMRealm *realm = [self openRealmForPartitionValue:value user:user];
    if (self.isParent) {
        [realm beginWriteTransaction];
        [realm deleteAllObjects];
        [realm commitWriteTransaction];
        CHECK_COUNT(0, Person, realm);

        int code1 = [self runChildAndWaitWithAppIds:@[appId]];
        XCTAssertEqual(0, code1);
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(3, Person, realm);
        XCTAssertEqual([Person objectsInRealm:realm where:@"firstName = 'John'"].count, 1UL);

        int code2 = [self runChildAndWaitWithAppIds:@[appId]];
        XCTAssertEqual(0, code2);
        [self waitForDownloadsForRealm:realm];
        CHECK_COUNT(6, Person, realm);
        XCTAssertEqual([Person objectsInRealm:realm where:@"firstName = 'John'"].count, 2UL);
    } else {
        // Add objects.
        [self addPersonsToRealm:realm
                        persons:@[[Person john],
                                  [Person paul],
                                  [Person ringo]]];
        [self waitForUploadsForRealm:realm];
    }
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
