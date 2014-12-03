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
#import "Realm_Private.h"
#import "RLMTestDataGenerator.h"
#import "RLMTestObjects.h"

@interface RealmBrowserTests : XCTestCase

@end

@implementation RealmBrowserTests

- (void)testGenerateDemoDatabase
{
    NSString *fileName = [NSString stringWithFormat:@"%@.realm", [[NSUUID UUID] UUIDString]];
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    BOOL success = [RLMTestDataGenerator createRealmAtUrl:fileURL withClassesNamed:@[[RealmObject1 className]] objectCount:10];
    XCTAssertEqual(YES, success);
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithPath:fileURL.path
                                     readOnly:NO
                                     inMemory:NO
                                      dynamic:YES
                                       schema:nil
                                        error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(realm);
    XCTAssertEqual(10, [[realm allObjects:[RealmObject1 className]] count]);
}

@end
