////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

@interface RLMSetObject : RLMObject
//@property (nonatomic, strong) RLMArray<RLMString> *stringSetArray;

@property (nonatomic, strong) RLMSet<RLMString> *stringSet;
@property (nonatomic, strong) RLMSet<RLMDecimal128> *decimalSet;
//@property (nonatomic, strong) RLMSet<RLMObjectId *> *objectIdSet;
//@property (nonatomic, strong) RLMSet<NSNumber *> *numberSet;
//@property (nonatomic, strong) RLMSet<RLMEmbeddedObject *> *embeddedSet;
//@property (nonatomic, strong) RLMSet<NSData *> *dataSet;

@end

@implementation RLMSetObject
@end

@interface SetTests : RLMTestCase

@end

@implementation SetTests

#pragma mark Unmanaged tests

-(void)testUnmanagedSet {
    RLMSetObject *setObj = [RLMSetObject new];
    XCTAssertNotNil(setObj.stringSet);

    [setObj.stringSet addObject:@"string1"];
    XCTAssertEqual(setObj.stringSet.count, 1U);
    XCTAssertTrue([[setObj.stringSet firstObject] isEqualToString:@"string1"]);
    [setObj.stringSet addObjects:@[@"string1", @"string2", @"string3"]]; // should not accept duplicates
    XCTAssertEqual(setObj.stringSet.count, 3U);
    XCTAssertTrue([setObj.stringSet[1] isEqualToString:@"string2"]);
    XCTAssertTrue([setObj.stringSet[2] isEqualToString:@"string3"]);

    NSSet *aSet = [NSSet setWithArray:@[@"string1", @"string4"]];
    [setObj.stringSet addObjects:aSet];
    XCTAssertEqual(setObj.stringSet.count, 4U);

    [setObj.stringSet insertObject:@"meFirst" atIndex:0];
    XCTAssertTrue([setObj.stringSet[0] isEqualToString:@"meFirst"]);
    XCTAssertEqual(setObj.stringSet.count, 5U);

    // should throw exception
    XCTAssertThrows([setObj.stringSet addObject:@123]);

    [setObj.stringSet removeLastObject];
    XCTAssertEqual(setObj.stringSet.count, 4U);

    [setObj.stringSet removeObjectAtIndex:0];
    XCTAssertEqual(setObj.stringSet.count, 3U);
    XCTAssertTrue([setObj.stringSet[0] isEqualToString:@"string1"]);

    [setObj.stringSet removeAllObjects];
    XCTAssertEqual(setObj.stringSet.count, 0U);
}

-(void)testUnmanagedSetComparison {
    RLMSetObject *setObj1 = [RLMSetObject new];
    RLMSetObject *setObj2 = [RLMSetObject new];

    [setObj1.stringSet addObjects:@[@"one", @"two", @"three"]];
    [setObj2.stringSet addObjects:@[@"one", @"two", @"three"]];
    XCTAssertTrue([setObj1.stringSet isEqual:setObj2.stringSet]);

    [setObj1.stringSet addObject:@"four"];
    XCTAssertFalse([setObj1.stringSet isEqual:setObj2.stringSet]);
}

-(void)testUnmanagedSetUnion {
    RLMSetObject *setObj1 = [RLMSetObject new];
    RLMSetObject *setObj2 = [RLMSetObject new];

    [setObj1.stringSet addObjects:@[@"one", @"two", @"three", @"four", @"five"]];
    [setObj2.stringSet addObjects:@[@"one", @"two", @"three"]];
    [setObj2.decimalSet addObjects:@[[RLMDecimal128 new]]];

    [setObj1.stringSet unionSet:setObj2.stringSet];
}

-(void)testUnmanagedSetIntersect {

}

-(void)testUnmanagedSetMinus {

}

-(void)testUnmanagedSetSort {

}

/*
- (void)intersectSet:(NSSet<ObjectType> *)other;
- (void)minusSet:(NSSet<ObjectType> *)other;
- (void)unionSet:(NSSet<ObjectType> *)other;
*/
@end
