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


@interface IntArrayPropertyObject : RLMObject
@property RLMArray<StringObject> *array;
@end

@implementation IntArrayPropertyObject
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
    
    // Test JSON output
    XCTAssertThrows([array.array JSONString], @"Not yet implemented");
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
    
    XCTAssertNil(array.array.firstObject, @"No objects added yet");
    XCTAssertNil(array.array.lastObject, @"No objects added yet");
    
    StringObject *obj1 = [[StringObject alloc] init];
    obj1.stringCol = @"a";
    StringObject *obj2 = [[StringObject alloc] init];
    obj2.stringCol = @"b";
    StringObject *obj3 = [[StringObject alloc] init];
    obj3.stringCol = @"c";
    [array.array addObject:obj1];
    [array.array addObject:obj2];
    [array.array addObject:obj3];
    
    XCTAssertEqualObjects(array.array.firstObject, obj1, @"Objects should be equal");
    XCTAssertEqualObjects(array.array.lastObject, obj3, @"Objects should be equal");
    XCTAssertEqualObjects([array.array objectAtIndex:1], obj2, @"Objects should be equal");
    
    [realm beginWriteTransaction];
    [realm addObject:array];
    [realm commitWriteTransaction];
    
    XCTAssertEqual(array.array.count, (NSUInteger)3, @"Should have two elements in array");
    XCTAssertEqualObjects([array.array[0] stringCol], @"a", @"First element should have property value 'a'");
    XCTAssertEqualObjects([array.array[1] stringCol], @"b", @"Second element should have property value 'b'");
    
    [realm beginWriteTransaction];
    [array.array replaceObjectAtIndex:0 withObject:obj3];
    // XCTAssertEqualObjects([array.array objectAtIndex:0], obj3, @"Objects should be replaced"); FIXME ASANA: https://app.asana.com/0/861870036984/13123030433568
    array.array[0] = obj1;
    // XCTAssertEqualObjects([array.array objectAtIndex:0], obj1, @"Objects should be replaced"); FIXME ASANA: https://app.asana.com/0/861870036984/13123030433568
    [array.array removeLastObject];
    XCTAssertEqual(array.array.count, (NSUInteger)2, @"2 objects left");
    [array.array addObject:obj1];
    [array.array removeAllObjects];
    XCTAssertEqual(array.array.count, (NSUInteger)0, @"All objects removed");
    [realm commitWriteTransaction];
    
    IntArrayPropertyObject *intArray = [[IntArrayPropertyObject alloc] init];
    IntObject *intObj = [[IntObject alloc] init];
    intObj.intCol = 1;
    [intArray.array addObject:intObj];
    
    XCTAssertThrows([intArray.array sumOfProperty:@"intCol"], @"Should throw on standalone RLMArray");
    XCTAssertThrows([intArray.array averageOfProperty:@"intCol"], @"Should throw on standalone RLMArray");
    XCTAssertThrows([intArray.array minOfProperty:@"intCol"], @"Should throw on standalone RLMArray");
    XCTAssertThrows([intArray.array maxOfProperty:@"intCol"], @"Should throw on standalone RLMArray");
    
    XCTAssertThrows([intArray.array objectsWithPredicateFormat:@"intCol == 1"], @"Should throw on standalone RLMArray");
    XCTAssertThrows(([intArray.array objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol == %i", 1]]), @"Should throw on standalone RLMArray");
    XCTAssertThrows([intArray.array arraySortedByProperty:@"intCol" ascending:YES], @"Should throw on standalone RLMArray");
    
    XCTAssertThrows([intArray.array indexOfObjectWithPredicateFormat:@"intCol == 1"], @"Not yet implemented");
    XCTAssertThrows(([intArray.array indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:@"intCol == %i", 1]]), @"Not yet implemented");
    
    XCTAssertEqual([intArray.array indexOfObject:intObj], (NSUInteger)0, @"Should be first element");
    
    XCTAssertThrows([intArray.array JSONString], @"Not yet implemented");
}

@end
