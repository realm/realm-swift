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
#import "RLMTestObjects.h"

@interface CascadeTest : RLMTestCase
@end

@implementation CascadeTest

- (void)testCascadeDelete {
    RLMRealm *testRealm = [RLMRealm inMemoryRealmWithIdentifier:@"cascade-delete-test-identifier"];
    [testRealm beginWriteTransaction];
    
    CascadeTestObject *testOb = [CascadeTestObject new];
    testOb.individualObject = [CascadeIndividualObject new];
    NSInteger numberOfArrayObs = 3;
    for (int i = 0; i < numberOfArrayObs; i++) {
        [testOb.array addObject:[CascadeArrayObject new]];
    }
    
    [testRealm addObject:testOb];
    
    NSInteger indi = [self numberOfObjectsForClass:[CascadeIndividualObject class] inRealm:testRealm];
    XCTAssert(indi == 1, @"Must be only one object of 'CascadeIndividualObject' class");
    NSInteger arr = [self numberOfObjectsForClass:[CascadeArrayObject class] inRealm:testRealm];
    XCTAssert(arr == numberOfArrayObs, @"Not the correct number of array objects!");
    NSInteger test = [self numberOfObjectsForClass:[CascadeTestObject class] inRealm:testRealm];
    XCTAssert(test == 1, @"Must be one object of 'CascadeTestObject' class");
    
    [testRealm deleteObject:testOb];
    
    indi = [self numberOfObjectsForClass:[CascadeIndividualObject class] inRealm:testRealm];
    XCTAssert(indi == 0, @"Must be only 0 objects of 'CascadeIndividualObject' class");
    arr = [self numberOfObjectsForClass:[CascadeArrayObject class] inRealm:testRealm];
    XCTAssert(arr == 0, @"Must be 0 objects of 'CascadeArrayObject' class");
    test = [self numberOfObjectsForClass:[CascadeTestObject class] inRealm:testRealm];
    XCTAssert(test == 0, @"Must be 0 objects of 'CascadeTestObject' class");
    
    [testRealm commitWriteTransaction];
}

- (NSInteger)numberOfObjectsForClass:(Class)cls inRealm:(RLMRealm *)realm {
    XCTAssert([cls isSubclassOfClass:[RLMObject class]], @"Must be realm object class");
    RLMResults *results = [cls allObjectsInRealm:realm];
    return results.count;
}

@end
