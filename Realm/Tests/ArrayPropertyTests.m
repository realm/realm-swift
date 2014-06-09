////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////


#import "RLMTestCase.h"
#import "RLMTestObjects.h"

@interface ArrayPropertyObject : RLMObject
@property NSString *name;
@property RLMArray<RLMTestObject> *array;
@end

@implementation ArrayPropertyObject
@end


@interface ArrayPropertyTests : RLMTestCase
@end

@implementation ArrayPropertyTests


-(void)testPopulateEmptyArray {
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm beginWriteTransaction];
    ArrayPropertyObject *array = [ArrayPropertyObject createInRealm:realm withObject:@[@"arrayObject", @[]]];
    XCTAssertNotNil(array.array, @"Should be able to get an empty array");
    XCTAssertEqual(array.array.count, 0, @"Should start with no array elements");

    RLMTestObject *obj = [[RLMTestObject alloc] init];
    obj.column = @"a";
    [array.array addObject:obj];
    [array.array addObject:[RLMTestObject createInRealm:realm withObject:@[@"b"]]];
    [array.array addObject:obj];
    [realm commitWriteTransaction];
    
    XCTAssertEqual(array.array.count, 3, @"Should have three elements in array");
    XCTAssertEqualObjects([array.array[0] column], @"a", @"First element should have property value 'a'");
    XCTAssertEqualObjects([array.array[1] column], @"b", @"Second element should have property value 'b'");
    XCTAssertEqualObjects([array.array[2] column], @"a", @"Third element should have property value 'a'");

    XCTAssertThrows([array.array addObject:obj], @"Adding array object outside a transaction should throw");
    
    // make sure we can fast enumerate
    for (RLMObject *obj in array.array) {
        XCTAssertTrue(obj.description.length, @"Object should have description");
    }
}


-(void)testModifyDetatchedArray {
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm beginWriteTransaction];
    ArrayPropertyObject *arObj = [ArrayPropertyObject createInRealm:realm withObject:@[@"arrayObject", @[]]];
    XCTAssertNotNil(arObj.array, @"Should be able to get an empty array");
    XCTAssertEqual(arObj.array.count, 0, @"Should start with no array elements");
    
    RLMTestObject *obj = [[RLMTestObject alloc] init];
    obj.column = @"a";
    RLMArray *array = arObj.array;
    [array addObject:obj];
    [array addObject:[RLMTestObject createInRealm:realm withObject:@[@"b"]]];
    [realm commitWriteTransaction];
    
    XCTAssertEqual(array.count, 2, @"Should have two elements in array");
    XCTAssertEqualObjects([array[0] column], @"a", @"First element should have property value 'a'");
    XCTAssertEqualObjects([arObj.array[1] column], @"b", @"Second element should have property value 'b'");
    
    XCTAssertThrows([array addObject:obj], @"Adding array object outside a transaction should throw");
}

-(void)testInsertMultiple {
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm beginWriteTransaction];
    ArrayPropertyObject *obj = [ArrayPropertyObject createInRealm:realm withObject:@[@"arrayObject", @[]]];
    RLMTestObject *child1 = [RLMTestObject createInRealm:realm withObject:@[@"a"]];
    RLMTestObject *child2 = [[RLMTestObject alloc] init];
    child2.column = @"b";
    [obj.array addObjectsFromArray:@[child2, child1]];
    [realm commitWriteTransaction];
    
    RLMArray *children = [realm allObjects:RLMTestObject.className];
    XCTAssertEqualObjects([children[0] column], @"a", @"First child should be 'a'");
    XCTAssertEqualObjects([children[1] column], @"b", @"Second child should be 'b'");
}

-(void)testStandalone {
    RLMRealm *realm = [self realmWithTestPath];
    
    ArrayPropertyObject *array = [[ArrayPropertyObject alloc] init];
    array.name = @"name";
    XCTAssertNotNil(array.array, @"RLMArray property should get created on access");
    
    RLMTestObject *obj = [[RLMTestObject alloc] init];
    obj.column = @"a";
    [array.array addObject:obj];
    [array.array addObject:obj];
    
    [realm beginWriteTransaction];
    [realm addObject:array];
    [realm commitWriteTransaction];
    
    XCTAssertEqual(array.array.count, 2, @"Should have two elements in array");
    XCTAssertEqualObjects([array.array[0] column], @"a", @"First element should have property value 'a'");
    XCTAssertEqualObjects([array.array[1] column], @"a", @"Second element should have property value 'a'");
}

@end

