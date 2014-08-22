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

#import <libkern/OSAtomic.h>

@interface ArrayPropertyTests : RLMTestCase
@end

@implementation ArrayPropertyTests

-(void)testPopulateEmptyArray {
    RLMRealm *realm = [self realmWithTestPath];
    
    [realm beginWriteTransaction];
    ArrayPropertyObject *array = [ArrayPropertyObject createInRealm:realm withObject:@[@"arrayObject", @[], @[]]];
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
    ArrayPropertyObject *arObj = [ArrayPropertyObject createInRealm:realm withObject:@[@"arrayObject", @[], @[]]];
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
    ArrayPropertyObject *obj = [ArrayPropertyObject createInRealm:realm withObject:@[@"arrayObject", @[], @[]]];
    StringObject *child1 = [StringObject createInRealm:realm withObject:@[@"a"]];
    StringObject *child2 = [[StringObject alloc] init];
    child2.stringCol = @"b";
    [obj.array addObjectsFromArray:@[child2, child1]];
    [realm commitWriteTransaction];
    
    RLMArray *children = [StringObject allObjectsInRealm:realm];
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
    XCTAssertEqualObjects([array.array objectAtIndex:0], obj3, @"Objects should be replaced");
    array.array[0] = obj1;
    XCTAssertEqualObjects([array.array objectAtIndex:0], obj1, @"Objects should be replaced");
    [array.array removeLastObject];
    XCTAssertEqual(array.array.count, (NSUInteger)2, @"2 objects left");
    [array.array addObject:obj1];
    [array.array removeAllObjects];
    XCTAssertEqual(array.array.count, (NSUInteger)0, @"All objects removed");
    [realm commitWriteTransaction];

    ArrayPropertyObject *intArray = [[ArrayPropertyObject alloc] init];
    IntObject *intObj = [[IntObject alloc] init];
    intObj.intCol = 1;
    XCTAssertThrows([intArray.array addObject:intObj], @"Addint to string array should throw");
    [intArray.intArray addObject:intObj];

    XCTAssertThrows([intArray.intArray sumOfProperty:@"intCol"], @"Should throw on standalone RLMArray");
    XCTAssertThrows([intArray.intArray averageOfProperty:@"intCol"], @"Should throw on standalone RLMArray");
    XCTAssertThrows([intArray.intArray minOfProperty:@"intCol"], @"Should throw on standalone RLMArray");
    XCTAssertThrows([intArray.intArray maxOfProperty:@"intCol"], @"Should throw on standalone RLMArray");

    XCTAssertThrows([intArray.intArray objectsWhere:@"intCol == 1"], @"Should throw on standalone RLMArray");
    XCTAssertThrows(([intArray.intArray objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol == %i", 1]]), @"Should throw on standalone RLMArray");
    XCTAssertThrows([intArray.intArray arraySortedByProperty:@"intCol" ascending:YES], @"Should throw on standalone RLMArray");
    
    XCTAssertThrows([intArray.intArray indexOfObjectWhere:@"intCol == 1"], @"Not yet implemented");
    XCTAssertThrows(([intArray.intArray indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:@"intCol == %i", 1]]), @"Not yet implemented");

    XCTAssertEqual([intArray.intArray indexOfObject:intObj], (NSUInteger)0, @"Should be first element");

    XCTAssertThrows([intArray.intArray JSONString], @"Not yet implemented");

    // test standalone with literals
    __unused ArrayPropertyObject *obj = [[ArrayPropertyObject alloc] initWithObject:@[@"n", @[], @[[[IntObject alloc] initWithObject:@[@1]]]]];
}

- (void)testIndexOfObject
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    EmployeeObject *po1 = [EmployeeObject createInRealm:realm withObject:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    EmployeeObject *po2 = [EmployeeObject createInRealm:realm withObject:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    EmployeeObject *po3 = [EmployeeObject createInRealm:realm withObject:@{@"name": @"Jill", @"age": @25, @"hired": @YES}];

    // create company
    CompanyObject *company = [[CompanyObject alloc] init];
    company.name = @"name";
    company.employees = (RLMArray<EmployeeObject> *)[EmployeeObject allObjects];
    [company.employees removeObjectAtIndex:1];

    // test standalone
    XCTAssertEqual((NSUInteger)0, [company.employees indexOfObject:po1]);
    XCTAssertEqual((NSUInteger)1, [company.employees indexOfObject:po3]);
    XCTAssertEqual((NSUInteger)NSNotFound, [company.employees indexOfObject:po2]);

    // add to realm
    [realm addObject:company];
    [realm commitWriteTransaction];

    // test LinkView RLMArray
    XCTAssertEqual((NSUInteger)0, [company.employees indexOfObject:po1]);
    XCTAssertEqual((NSUInteger)1, [company.employees indexOfObject:po3]);
    XCTAssertEqual((NSUInteger)NSNotFound, [company.employees indexOfObject:po2]);

    // non realm employee
    EmployeeObject *notInRealm = [[EmployeeObject alloc] initWithObject:@[@"NoName", @1, @NO]];
    XCTAssertEqual((NSUInteger)NSNotFound, [company.employees indexOfObject:notInRealm]);
}

- (void)testFastEnumeration
{
    RLMRealm *realm = self.realmWithTestPath;

    [realm beginWriteTransaction];
    CompanyObject *company = [[CompanyObject alloc] init];
    company.name = @"name";
    [realm addObject:company];
    [realm commitWriteTransaction];

    // enumerate empty array
    for (__unused id obj in company.employees) {
        XCTFail(@"Should be empty");
    }

    [realm beginWriteTransaction];
    for (int i = 0; i < 30; ++i) {
        EmployeeObject *eo = [EmployeeObject createInRealm:realm withObject:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
        [company.employees addObject:eo];
    }
    [realm commitWriteTransaction];

    XCTAssertEqual(company.employees.count, (NSUInteger)30);

    __weak id objects[30];
    NSInteger count = 0;
    for (EmployeeObject *e in company.employees) {
        XCTAssertNotNil(e, @"Object is not nil and accessible");
        if (count > 16) {
            // 16 is the size of blocks fast enumeration happens to ask for at
            // the moment, but of course that's just an implementation detail
            // that may change
            XCTAssertNil(objects[count - 16]);
        }
        objects[count++] = e;
    }

    XCTAssertEqual(count, 30, @"should have enumerated 30 objects");

    for (int i = 0; i < count; i++) {
        XCTAssertNil(objects[i], @"Object should have been released");
    }

    @autoreleasepool {
        for (EmployeeObject *e in company.employees) {
            objects[0] = e;
            break;
        }
    }
    XCTAssertNil(objects[0], @"Object should have been released");
}

- (void)testCrossThreadAccess
{
    CompanyObject *company = [[CompanyObject alloc] init];
    company.name = @"name";

    EmployeeObject *eo = [[EmployeeObject alloc] init];
    eo.name = @"Joe";
    eo.age = 40;
    eo.hired = YES;
    [company.employees addObject:eo];
    RLMArray *employees = company.employees;

    // Standalone can be accessed from other threads
    // Using dispatch_async to ensure it actually lands on another thread
    __block OSSpinLock spinlock = OS_SPINLOCK_INIT;
    OSSpinLockLock(&spinlock);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertNoThrow(company.employees);
        XCTAssertNoThrow([employees lastObject]);
        OSSpinLockUnlock(&spinlock);
    });
    OSSpinLockLock(&spinlock);

    [RLMRealm.defaultRealm beginWriteTransaction];
    [RLMRealm.defaultRealm addObject:company];
    [RLMRealm.defaultRealm commitWriteTransaction];

    employees = company.employees;
    XCTAssertNoThrow(company.employees);
    XCTAssertNoThrow([employees lastObject]);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertThrows(company.employees);
        XCTAssertThrows([employees lastObject]);
        OSSpinLockUnlock(&spinlock);
    });
    OSSpinLockLock(&spinlock);
}

@end
