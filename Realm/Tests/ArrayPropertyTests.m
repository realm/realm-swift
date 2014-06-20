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

#pragma mark - Test Objects

@interface ArrayPropertyObject : RLMObject
@property NSString *name;
@property RLMArray<StringObject> *array;
@end

@implementation ArrayPropertyObject
@end

#pragma mark - Tests

@interface ArrayPropertyTests : RLMTestCase
@end

@implementation ArrayPropertyTests

-(void)testPopulateEmptyArray {
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm beginWriteTransaction];
    ArrayPropertyObject *array = [ArrayPropertyObject createInRealm:realm withObject:@[@"arrayObject", @[]]];
    XCTAssertNotNil(array.array, @"Should be able to get an empty array");
    XCTAssertEqual(array.array.count, (NSUInteger)0, @"Should start with no array elements");

    StringObject *obj = [[StringObject alloc] init];
    obj.stringCol = @"a";
    [array.array addObject:obj];
    [array.array addObject:[StringObject createInRealm:realm withObject:@[@"b"]]];
    [array.array addObject:obj];
    [realm commitWriteTransaction];
    
    XCTAssertEqual(array.array.count, (NSUInteger)3, @"Should have three elements in array");
    XCTAssertEqualObjects([array.array[0] stringCol], @"a", @"First element should have property value 'a'");
    XCTAssertEqualObjects([array.array[1] stringCol], @"b", @"Second element should have property value 'b'");
    XCTAssertEqualObjects([array.array[2] stringCol], @"a", @"Third element should have property value 'a'");

    RLMArray *arrayProp = array.array;
    XCTAssertThrows([arrayProp addObject:obj], @"Adding array object outside a transaction should throw");
    
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
    XCTAssertEqual(arObj.array.count, (NSUInteger)0, @"Should start with no array elements");
    
    StringObject *obj = [[StringObject alloc] init];
    obj.stringCol = @"a";
    RLMArray *array = arObj.array;
    [array addObject:obj];
    [array addObject:[StringObject createInRealm:realm withObject:@[@"b"]]];
    [realm commitWriteTransaction];
    
    XCTAssertEqual(array.count, (NSUInteger)2, @"Should have two elements in array");
    XCTAssertEqualObjects([array[0] stringCol], @"a", @"First element should have property value 'a'");
    XCTAssertEqualObjects([arObj.array[1] stringCol], @"b", @"Second element should have property value 'b'");
    
    XCTAssertThrows([array addObject:obj], @"Adding array object outside a transaction should throw");
}

-(void)testInsertMultiple {
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm beginWriteTransaction];
    ArrayPropertyObject *obj = [ArrayPropertyObject createInRealm:realm withObject:@[@"arrayObject", @[]]];
    StringObject *child1 = [StringObject createInRealm:realm withObject:@[@"a"]];
    StringObject *child2 = [[StringObject alloc] init];
    child2.stringCol = @"b";
    [obj.array addObjectsFromArray:@[child2, child1]];
    [realm commitWriteTransaction];
    
    RLMArray *children = [realm allObjects:StringObject.className];
    XCTAssertEqualObjects([children[0] stringCol], @"a", @"First child should be 'a'");
    XCTAssertEqualObjects([children[1] stringCol], @"b", @"Second child should be 'b'");
}

-(void)testStandalone {
    RLMRealm *realm = [self realmWithTestPath];
    
    ArrayPropertyObject *array = [[ArrayPropertyObject alloc] init];
    array.name = @"name";
    XCTAssertNotNil(array.array, @"RLMArray property should get created on access");
    
    StringObject *obj = [[StringObject alloc] init];
    obj.stringCol = @"a";
    [array.array addObject:obj];
    [array.array addObject:obj];
    
    [realm beginWriteTransaction];
    [realm addObject:array];
    [realm commitWriteTransaction];
    
    XCTAssertEqual(array.array.count, (NSUInteger)2, @"Should have two elements in array");
    XCTAssertEqualObjects([array.array[0] stringCol], @"a", @"First element should have property value 'a'");
    XCTAssertEqualObjects([array.array[1] stringCol], @"a", @"Second element should have property value 'a'");
}

@end
