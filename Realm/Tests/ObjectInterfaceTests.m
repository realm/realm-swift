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

#import "RLMTestCase.h"

@interface ObjectInterfaceTests : RLMTestCase
@end

@implementation ObjectInterfaceTests

- (void)testCustomAccessors
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    CustomAccessors *ca = [CustomAccessors createInRealm:realm withObject:@[@"name", @2]];
    XCTAssertEqualObjects([ca getThatName], @"name", @"name property should be name.");
    
    [ca setTheInt:99];
    XCTAssertEqual((int)ca.age, (int)99, @"age property should be 99");
    [realm commitWriteTransaction];
}

- (void)testObjectSubclass
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    NSArray *obj = @[@1, @"throw"];
    XCTAssertThrows([InvalidSubclassObject createInRealm:realm withObject:obj],
                    @"Adding invalid object should throw");
    [realm commitWriteTransaction];
}

- (void)testClassExtension
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    BaseClassTestObject *bObject = [[BaseClassTestObject alloc ] init];
    bObject.intCol = 1;
    bObject.stringCol = @"stringVal";
    [realm addObject:bObject];
    [realm commitWriteTransaction];
    
    BaseClassTestObject *objectFromRealm = [BaseClassTestObject allObjects][0];
    XCTAssertEqual(1, objectFromRealm.intCol, @"Should be 1");
    XCTAssertEqualObjects(@"stringVal", objectFromRealm.stringCol, @"Should be stringVal");
}

@end
