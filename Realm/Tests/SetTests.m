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

@property RLMSet<RLMString> *stringSet;
@property RLMSet<RLMDecimal128> *decimalSet;
@property RLMSet<RLMObjectId> *objectIdSet;
@property RLMSet<RLMInt> *numberSet;
@property RLMArray<EmbeddedIntObject> *embeddedSet;
@property RLMSet<RLMData> *dataSet;
@property RLMSet<EmployeeObject> *employeeSet;

@end

@implementation RLMSetObject
@end

@interface SetTests : RLMTestCase

@end

@implementation SetTests

#pragma mark Unmanaged tests

- (void)testUnmanagedSet {
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
/*
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
*/
    [setObj.stringSet removeAllObjects];
    XCTAssertEqual(setObj.stringSet.count, 0U);
}

- (void)testUnmanagedSetComparison {
    RLMSetObject *setObj1 = [RLMSetObject new];
    RLMSetObject *setObj2 = [RLMSetObject new];

    [setObj1.stringSet addObjects:@[@"one", @"two", @"three"]];
    [setObj2.stringSet addObjects:@[@"one", @"two", @"three"]];
    XCTAssertTrue([setObj1.stringSet isEqual:setObj2.stringSet]);

    [setObj1.stringSet addObject:@"four"];
    XCTAssertFalse([setObj1.stringSet isEqual:setObj2.stringSet]);
}

- (void)testUnmanagedSetUnion {
    RLMSetObject *setObj1 = [RLMSetObject new];
    RLMSetObject *setObj2 = [RLMSetObject new];
    RLMSetObject *setObj3 = [RLMSetObject new];

    [setObj1.stringSet addObjects:@[@"one", @"two", @"three", @"four", @"five"]];
    [setObj2.stringSet addObjects:@[@"one", @"two", @"three"]];
    [setObj3.stringSet addObjects:@[@"one", @"two", @"three", @"four", @"five"]];

    [setObj1.stringSet unionSet:setObj2.stringSet];

    XCTAssertEqual(setObj1.stringSet.count, 5U);
    XCTAssertTrue([setObj1.stringSet isEqual:setObj3.stringSet]);
}

- (void)testUnmanagedSetIntersect {
    RLMSetObject *setObj1 = [RLMSetObject new];
    RLMSetObject *setObj2 = [RLMSetObject new];
    RLMSetObject *setObj3 = [RLMSetObject new];

    [setObj1.stringSet addObjects:@[@"ten", @"one", @"nine", @"two", @"eight"]];
    [setObj2.stringSet addObjects:@[@"five", @"six", @"seven", @"eight", @"nine"]];
    [setObj3.stringSet addObjects:@[@"nine", @"eight"]];

    [setObj1.stringSet intersectSet:setObj2.stringSet];
    XCTAssertTrue([setObj1.stringSet intersectsSet:setObj2.stringSet]);

    XCTAssertEqual(setObj1.stringSet.count, 2U);
    XCTAssertTrue([setObj1.stringSet isEqual:setObj3.stringSet]);
}

- (void)testUnmanagedSetMinus {
    RLMSetObject *setObj1 = [RLMSetObject new];
    RLMSetObject *setObj2 = [RLMSetObject new];
    RLMSetObject *setObj3 = [RLMSetObject new];

    [setObj1.stringSet addObjects:@[@"ten", @"one", @"nine", @"two", @"eight"]];
    [setObj2.stringSet addObjects:@[@"five", @"six", @"seven", @"eight", @"nine"]];
    [setObj3.stringSet addObjects:@[@"ten", @"one", @"two"]];

    [setObj1.stringSet minusSet:setObj2.stringSet];

    XCTAssertEqual(setObj1.stringSet.count, 3U);
    XCTAssertTrue([setObj1.stringSet isEqual:setObj3.stringSet]);
}

- (void)testUnmanagedSetIntersectsSet {
    RLMSetObject *setObj1 = [RLMSetObject new];
    RLMSetObject *setObj2 = [RLMSetObject new];

    [setObj1.stringSet addObjects:@[@"ten", @"one", @"nine", @"two", @"eight"]];
    [setObj2.stringSet addObjects:@[@"five", @"six", @"seven", @"eight", @"nine"]];

    XCTAssertTrue([setObj1.stringSet intersectsSet:setObj2.stringSet]);
}

- (void)testUnmanagedSetIsSubsetOfSet {
    RLMSetObject *setObj1 = [RLMSetObject new];
    RLMSetObject *setObj2 = [RLMSetObject new];
    RLMSetObject *setObj3 = [RLMSetObject new];

    [setObj1.stringSet addObjects:@[@"ten", @"one", @"nine", @"two", @"eight"]];
    [setObj2.stringSet addObjects:@[@"five", @"six", @"seven", @"eight", @"nine"]];
    [setObj3.stringSet addObjects:@[@"two", @"one", @"ten"]];

    XCTAssertFalse([setObj1.stringSet isSubsetOfSet:setObj2.stringSet]);
    XCTAssertTrue([setObj3.stringSet isSubsetOfSet:setObj1.stringSet]);
}

- (void)testUnmanagedPrimitive {
    AllPrimitiveSets *obj = [[AllPrimitiveSets alloc] init];
    XCTAssertTrue([obj.intObj isKindOfClass:[RLMSet class]]);
    XCTAssertTrue([obj.floatObj isKindOfClass:[RLMSet class]]);
    XCTAssertTrue([obj.doubleObj isKindOfClass:[RLMSet class]]);
    XCTAssertTrue([obj.boolObj isKindOfClass:[RLMSet class]]);
    XCTAssertTrue([obj.stringObj isKindOfClass:[RLMSet class]]);
    XCTAssertTrue([obj.dataObj isKindOfClass:[RLMSet class]]);
    XCTAssertTrue([obj.dateObj isKindOfClass:[RLMSet class]]);

    [obj.intObj addObject:@1];
    XCTAssertEqualObjects(obj.intObj[0], @1);
    XCTAssertThrows([obj.intObj addObject:@""]);

    XCTAssertTrue([obj.intObj isKindOfClass:[RLMSet class]]);
    XCTAssertTrue([obj.floatObj isKindOfClass:[RLMSet class]]);
    XCTAssertTrue([obj.doubleObj isKindOfClass:[RLMSet class]]);
    XCTAssertTrue([obj.boolObj isKindOfClass:[RLMSet class]]);
    XCTAssertTrue([obj.stringObj isKindOfClass:[RLMSet class]]);
    XCTAssertTrue([obj.dataObj isKindOfClass:[RLMSet class]]);
    XCTAssertTrue([obj.dateObj isKindOfClass:[RLMSet class]]);

    [obj.intObj addObject:@5];
    XCTAssertEqualObjects(obj.intObj.firstObject, @1);
}

// TODO: Needs Set implementation from the core layer, issue is the
// schema generation in the ObjStore level has no conditional for is_set
- (void)testReplaceObjectAtIndexInUnmanagedArray {
    SetPropertyObject *set = [[SetPropertyObject alloc] init];
    set.name = @"name";

    StringObject *stringObj1 = [[StringObject alloc] init];
    stringObj1.stringCol = @"a";
    StringObject *stringObj2 = [[StringObject alloc] init];
    stringObj2.stringCol = @"b";
    StringObject *stringObj3 = [[StringObject alloc] init];
    stringObj3.stringCol = @"c";
    [set.stringSet addObject:stringObj1];
    [set.stringSet addObject:stringObj2];
    [set.stringSet addObject:stringObj3];

    IntObject *intObj1 = [[IntObject alloc] init];
    intObj1.intCol = 0;
    IntObject *intObj2 = [[IntObject alloc] init];
    intObj2.intCol = 1;
    IntObject *intObj3 = [[IntObject alloc] init];
    intObj3.intCol = 2;
    [set.intSet addObject:intObj1];
    [set.intSet addObject:intObj2];
    [set.intSet addObject:intObj3];

    XCTAssertEqualObjects(set.stringSet[0], stringObj1, @"Objects should be equal");
    XCTAssertEqualObjects(set.stringSet[1], stringObj2, @"Objects should be equal");
    XCTAssertEqualObjects(set.stringSet[2], stringObj3, @"Objects should be equal");
    XCTAssertEqual(set.stringSet.count, 3U, @"Should have 3 elements in string array");

    XCTAssertEqualObjects(set.intSet[0], intObj1, @"Objects should be equal");
    XCTAssertEqualObjects(set.intSet[1], intObj2, @"Objects should be equal");
    XCTAssertEqualObjects(set.intSet[2], intObj3, @"Objects should be equal");
    XCTAssertEqual(set.intSet.count, 3U, @"Should have 3 elements in int array");

    StringObject *stringObj4 = [[StringObject alloc] init];
    stringObj4.stringCol = @"d";
/*
    [set.stringSet replaceObjectAtIndex:0 withObject:stringObj4];
    XCTAssertTrue([[set.stringSet objectAtIndex:0] isEqualToObject:stringObj4], @"Objects should be replaced");
    XCTAssertEqual(set.stringSet.count, 3U, @"Should have 3 elements in int array");

    IntObject *intObj4 = [[IntObject alloc] init];
    intObj4.intCol = 3;

    [set.intSet replaceObjectAtIndex:1 withObject:intObj4];
    XCTAssertTrue([[set.intSet objectAtIndex:1] isEqualToObject:intObj4], @"Objects should be replaced");
    XCTAssertEqual(set.intSet.count, 3U, @"Should have 3 elements in int array");

    RLMAssertThrowsWithReasonMatching([set.stringSet replaceObjectAtIndex:0 withObject:(id)intObj4],
                                      @"IntObject.*StringObject");
    RLMAssertThrowsWithReasonMatching([set.intSet replaceObjectAtIndex:1 withObject:(id)stringObj4],
                                      @"StringObject.*IntObject");*/
}

- (void)testDeleteObjectInUnmanagedArray {
    SetPropertyObject *set = [[SetPropertyObject alloc] init];
    set.name = @"name";

    StringObject *stringObj1 = [[StringObject alloc] init];
    stringObj1.stringCol = @"a";
    StringObject *stringObj2 = [[StringObject alloc] init];
    stringObj2.stringCol = @"b";
    StringObject *stringObj3 = [[StringObject alloc] init];
    stringObj3.stringCol = @"c";
    [set.stringSet addObject:stringObj1];
    [set.stringSet addObject:stringObj2];
    [set.stringSet addObject:stringObj3];

    IntObject *intObj1 = [[IntObject alloc] init];
    intObj1.intCol = 0;
    IntObject *intObj2 = [[IntObject alloc] init];
    intObj2.intCol = 1;
    IntObject *intObj3 = [[IntObject alloc] init];
    intObj3.intCol = 2;
    [set.intSet addObject:intObj1];
    [set.intSet addObject:intObj2];
    [set.intSet addObject:intObj3];

    XCTAssertEqualObjects(set.stringSet[0], stringObj1, @"Objects should be equal");
    XCTAssertEqualObjects(set.stringSet[1], stringObj2, @"Objects should be equal");
    XCTAssertEqualObjects(set.stringSet[2], stringObj3, @"Objects should be equal");
    XCTAssertEqual(set.stringSet.count, 3U, @"Should have 3 elements in string array");

    XCTAssertEqualObjects(set.intSet[0], intObj1, @"Objects should be equal");
    XCTAssertEqualObjects(set.intSet[1], intObj2, @"Objects should be equal");
    XCTAssertEqualObjects(set.intSet[2], intObj3, @"Objects should be equal");
    XCTAssertEqual(set.intSet.count, 3U, @"Should have 3 elements in int array");
/*
    [set.stringSet removeLastObject];

    XCTAssertEqualObjects(set.stringSet[0], stringObj1, @"Objects should be equal");
    XCTAssertEqualObjects(set.stringSet[1], stringObj2, @"Objects should be equal");
    XCTAssertEqual(set.stringSet.count, 2U, @"Should have 2 elements in string array");

    [set.stringSet removeLastObject];

    XCTAssertEqualObjects(set.stringSet[0], stringObj1, @"Objects should be equal");
    XCTAssertEqual(set.stringSet.count, 1U, @"Should have 1 elements in string array");

    [set.stringSet removeLastObject];
*/
    XCTAssertEqual(set.stringSet.count, 0U, @"Should have 0 elements in string array");

    [set.intSet removeAllObjects];
    XCTAssertEqual(set.intSet.count, 0U, @"Should have 0 elements in int array");
}

- (void)testUnmanagedSetIndexOf {
    RLMSetObject *setObj1 = [RLMSetObject new];
    [setObj1.stringSet addObjects:@[@"ten", @"one", @"nine", @"two", @"eight"]];

    XCTAssertEqual([setObj1.stringSet indexOfObject:@"nonexistent"], NSNotFound);
    XCTAssertEqual([setObj1.stringSet indexOfObject:@"eight"], 4U);

    XCTAssertEqual(([setObj1.stringSet indexOfObjectWhere:@"SELF == %@", @"one"]), 1U);
    XCTAssertEqual(([setObj1.stringSet indexOfObjectWhere:@"SELF == %@", @"nonexistent"]), NSNotFound);

    XCTAssertEqual(([setObj1.stringSet indexOfObjectWhere:@"SELF == 'one'"]), 1U);
    XCTAssertEqual(([setObj1.stringSet indexOfObjectWhere:@"SELF == 'nonexistent'"]), NSNotFound);

    XCTAssertEqual(([setObj1.stringSet indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:@"SELF == %@", @"one"]]), 1U);
    XCTAssertEqual(([setObj1.stringSet indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:@"SELF == %@", @"nonexistent"]]), NSNotFound);
}

- (void)testUnmanagedSetSort {
    RLMSetObject *setObj1 = [RLMSetObject new];
    XCTAssertThrows([setObj1.stringSet sortedResultsUsingKeyPath:@"age" ascending:YES]);
    XCTAssertThrows([setObj1.stringSet sortedResultsUsingDescriptors:@[]]);
    XCTAssertThrows([setObj1.stringSet distinctResultsUsingKeyPaths:@[]]);
}

- (void)testUnmanagedSetObjectAtIndexedSubscript {
    RLMSetObject *setObj1 = [RLMSetObject new];
    [setObj1.stringSet addObjects:@[@"one", @"two", @"three", @"four", @"five"]];
    XCTAssertTrue([[setObj1.stringSet objectAtIndexedSubscript:1] isEqualToString:@"two"]);

    [setObj1.stringSet setObject:@"hello!" atIndexedSubscript:1];
    XCTAssertTrue([[setObj1.stringSet objectAtIndexedSubscript:1] isEqualToString:@"hello!"]);
}

- (void)testUnmanagedSetAggregate {
    EmbeddedIntObject *intObj1 = [EmbeddedIntObject new];
    intObj1.intCol = 1;
    EmbeddedIntObject *intObj2 = [EmbeddedIntObject new];
    intObj2.intCol = 2;
    EmbeddedIntObject *intObj3 = [EmbeddedIntObject new];
    intObj3.intCol = 3;
    RLMSetObject *setObj = [RLMSetObject new];
    [setObj.embeddedSet addObjects:@[intObj1, intObj2, intObj3]];

    XCTAssertEqual(6, [setObj.embeddedSet sumOfProperty:@"intCol"].intValue);
    XCTAssertEqual(2, [setObj.embeddedSet averageOfProperty:@"intCol"].intValue);
    XCTAssertEqual(1, [[setObj.embeddedSet minOfProperty:@"intCol"] intValue]);
    XCTAssertEqual(3, [[setObj.embeddedSet maxOfProperty:@"intCol"] intValue]);
    XCTAssertThrows([setObj.embeddedSet sumOfProperty:@"prop 1"]);
}

- (void)testManagedSet {
    RLMRealm *r = [self realmWithTestPath];
//    [r beginWriteTransaction];
//    RLMSetObject *setObj1 = [RLMSetObject new];
//    [setObj1.stringSet addObjects:@[@"one", @"two", @"three", @"four", @"five"]];
//    [r addObject:setObj1];
//    [r commitWriteTransaction];


}

@end
