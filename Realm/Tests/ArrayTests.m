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
#import <mach/mach.h>

@interface ArrayTests : RLMTestCase
@end

@implementation ArrayTests

- (void)testFastEnumeration
{
    RLMRealm *realm = self.realmWithTestPath;
    
    [realm beginWriteTransaction];

    // enumerate empty array
    for (__unused id obj in [AggregateObject allObjectsInRealm:realm]) {
        XCTFail(@"Should be empty");
    }

    NSDate *dateMinInput = [NSDate date];
    NSDate *dateMaxInput = [dateMinInput dateByAddingTimeInterval:1000];
    
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@10, @1.2f, @0.0, @YES, dateMinInput]];
    
    [realm commitWriteTransaction];
       
    RLMArray *result = [AggregateObject objectsInRealm:realm where:@"intCol < %i", 100];
    
    XCTAssertEqual(result.count, (NSUInteger)18, @"18 objects added");

    __weak id objects[18];
    NSInteger count = 0;
    for (AggregateObject *ao in result) {
        XCTAssertNotNil(ao, @"Object is not nil and accessible");
        if (count > 16) {
            // 16 is the size of blocks fast enumeration happens to ask for at
            // the moment, but of course that's just an implementation detail
            // that may change
            XCTAssertNil(objects[count - 16]);
        }
        objects[count++] = ao;
    }
    
    XCTAssertEqual(count, 18, @"should have enumerated 18 objects");

    for (int i = 0; i < count; i++) {
        XCTAssertNil(objects[i], @"Object should have been released");
    }

    @autoreleasepool {
        for (AggregateObject *ao in result) {
            objects[0] = ao;
            break;
        }
    }
    XCTAssertNil(objects[0], @"Object should have been released");
}

- (void)testReadOnly
{
    RLMRealm *realm = self.realmWithTestPath;
    
    [realm beginWriteTransaction];
    StringObject *obj1 = [StringObject createInRealm:realm withObject:@[@"name1"]];
    StringObject *obj2 = [StringObject createInRealm:realm withObject:@[@"name2"]];
    [realm commitWriteTransaction];
    
    RLMArray *array = [StringObject allObjects];
    XCTAssertTrue(array.readOnly, @"Array returned from query should be readonly");
    XCTAssertThrowsSpecificNamed([array addObject:obj1], NSException, @"RLMException", @"Mutating readOnly array should throw");
    XCTAssertThrowsSpecificNamed([array replaceObjectAtIndex:0 withObject:obj2], NSException, @"RLMException", @"Mutating readOnly array should throw");
    XCTAssertThrowsSpecificNamed([array insertObject:obj1 atIndex:0], NSException, @"RLMException", @"Mutating readOnly array should throw");
}

- (void)testObjectAggregate
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    
    NSDate *dateMinInput = [NSDate date];
    NSDate *dateMaxInput = [dateMinInput dateByAddingTimeInterval:1000];
    
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withObject:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    
    [realm commitWriteTransaction];
    
    RLMArray *noArray = [AggregateObject objectsWhere:@"boolCol == NO"];
    RLMArray *yesArray = [AggregateObject objectsWhere:@"boolCol == YES"];
    
    // SUM ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int sum
    XCTAssertEqual([noArray sumOfProperty:@"intCol"].integerValue, (NSInteger)4, @"Sum should be 4");
    XCTAssertEqual([yesArray sumOfProperty:@"intCol"].integerValue, (NSInteger)0, @"Sum should be 0");
    
    // Test float sum
    XCTAssertEqualWithAccuracy([noArray sumOfProperty:@"floatCol"].floatValue, (float)0.0f, 0.1f, @"Sum should be 0.0");
    XCTAssertEqualWithAccuracy([yesArray sumOfProperty:@"floatCol"].floatValue, (float)7.2f, 0.1f, @"Sum should be 7.2");
    
    // Test double sum
    XCTAssertEqualWithAccuracy([noArray sumOfProperty:@"doubleCol"].doubleValue, (double)10.0, 0.1f, @"Sum should be 10.0");
    XCTAssertEqualWithAccuracy([yesArray sumOfProperty:@"doubleCol"].doubleValue, (double)0.0, 0.1f, @"Sum should be 0.0");
    
    // Test invalid column name
    XCTAssertThrows([yesArray sumOfProperty:@"foo"], @"Should throw exception");
    
    // Test operation not supported
    XCTAssertThrows([yesArray sumOfProperty:@"boolCol"], @"Should throw exception");
    
    
    // Average ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int average
    XCTAssertEqualWithAccuracy([noArray averageOfProperty:@"intCol"].doubleValue, (double)1.0, 0.1f, @"Average should be 1.0");
    XCTAssertEqualWithAccuracy([yesArray averageOfProperty:@"intCol"].doubleValue, (double)0.0, 0.1f, @"Average should be 0.0");
    
    // Test float average
    XCTAssertEqualWithAccuracy([noArray averageOfProperty:@"floatCol"].doubleValue, (double)0.0f, 0.1f, @"Average should be 0.0");
    XCTAssertEqualWithAccuracy([yesArray averageOfProperty:@"floatCol"].doubleValue, (double)1.2f, 0.1f, @"Average should be 1.2");
    
    // Test double average
    XCTAssertEqualWithAccuracy([noArray averageOfProperty:@"doubleCol"].doubleValue, (double)2.5, 0.1f, @"Average should be 2.5");
    XCTAssertEqualWithAccuracy([yesArray averageOfProperty:@"doubleCol"].doubleValue, (double)0.0, 0.1f, @"Average should be 0.0");
    
    // Test invalid column name
    XCTAssertThrows([yesArray averageOfProperty:@"foo"], @"Should throw exception");
    
    // Test operation not supported
    XCTAssertThrows([yesArray averageOfProperty:@"boolCol"], @"Should throw exception");
    
    // MIN ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int min
    NSNumber *min = [noArray minOfProperty:@"intCol"];
    XCTAssertEqual(min.intValue, (NSInteger)1, @"Minimum should be 1");
    min = [yesArray minOfProperty:@"intCol"];
    XCTAssertEqual(min.intValue, (NSInteger)0, @"Minimum should be 0");
    
    // Test float min
    min = [noArray minOfProperty:@"floatCol"];
    XCTAssertEqualWithAccuracy(min.floatValue, (float)0.0f, 0.1f, @"Minimum should be 0.0f");
    min = [yesArray minOfProperty:@"floatCol"];
    XCTAssertEqualWithAccuracy(min.floatValue, (float)1.2f, 0.1f, @"Minimum should be 1.2f");
    
    // Test double min
    min = [noArray minOfProperty:@"doubleCol"];
    XCTAssertEqualWithAccuracy(min.doubleValue, (double)2.5, 0.1f, @"Minimum should be 1.5");
    min = [yesArray minOfProperty:@"doubleCol"];
    XCTAssertEqualWithAccuracy(min.doubleValue, (double)0.0, 0.1f, @"Minimum should be 0.0");
    
    // Test date min
    NSDate *dateMinOutput = [noArray minOfProperty:@"dateCol"];
    XCTAssertEqualWithAccuracy(dateMinOutput.timeIntervalSince1970, dateMaxInput.timeIntervalSince1970, 1, @"Minimum should be dateMaxInput");
    dateMinOutput = [yesArray minOfProperty:@"dateCol"];
    XCTAssertEqualWithAccuracy(dateMinOutput.timeIntervalSince1970, dateMinInput.timeIntervalSince1970, 1, @"Minimum should be dateMinInput");
    
    // Test invalid column name
    XCTAssertThrows([noArray minOfProperty:@"foo"], @"Should throw exception");
    
    // Test operation not supported
    XCTAssertThrows([noArray minOfProperty:@"boolCol"], @"Should throw exception");
    
    
    // MAX ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int max
    NSNumber *max = [noArray maxOfProperty:@"intCol"];
    XCTAssertEqual(max.integerValue, (NSInteger)1, @"Maximum should be 8");
    max = [yesArray maxOfProperty:@"intCol"];
    XCTAssertEqual(max.integerValue, (NSInteger)0, @"Maximum should be 10");
    
    // Test float max
    max = [noArray maxOfProperty:@"floatCol"];
    XCTAssertEqualWithAccuracy(max.floatValue, (float)0.0f, 0.1f, @"Maximum should be 0.0f");
    max = [yesArray maxOfProperty:@"floatCol"];
    XCTAssertEqualWithAccuracy(max.floatValue, (float)1.2f, 0.1f, @"Maximum should be 1.2f");
    
    // Test double max
    max = [noArray maxOfProperty:@"doubleCol"];
    XCTAssertEqualWithAccuracy(max.doubleValue, (double)2.5, 0.1f, @"Maximum should be 3.5");
    max = [yesArray maxOfProperty:@"doubleCol"];
    XCTAssertEqualWithAccuracy(max.doubleValue, (double)0.0, 0.1f, @"Maximum should be 0.0");
    
    // Test date max
    NSDate *dateMaxOutput = [noArray maxOfProperty:@"dateCol"];
    XCTAssertEqualWithAccuracy(dateMaxOutput.timeIntervalSince1970, dateMaxInput.timeIntervalSince1970, 1, @"Maximum should be dateMaxInput");
    dateMaxOutput = [yesArray maxOfProperty:@"dateCol"];
    XCTAssertEqualWithAccuracy(dateMaxOutput.timeIntervalSince1970, dateMinInput.timeIntervalSince1970, 1, @"Maximum should be dateMinInput");
    
    // Test invalid column name
    XCTAssertThrows([noArray maxOfProperty:@"foo"], @"Should throw exception");
    
    // Test operation not supported
    XCTAssertThrows([noArray maxOfProperty:@"boolCol"], @"Should throw exception");
}

- (void)testArrayDescription
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    for (NSInteger i = 0; i < 1012; ++i) {
        EmployeeObject *person = [[EmployeeObject alloc] init];
        person.name = @"Mary";
        person.age = 24;
        person.hired = YES;
        [realm addObject:person];
    }
    [realm commitWriteTransaction];
    
    NSString *description = [[EmployeeObject allObjects] description];
    
    XCTAssertTrue([description rangeOfString:@"name"].location != NSNotFound, @"property names should be displayed when calling \"description\" on RLMArray");
    XCTAssertTrue([description rangeOfString:@"Mary"].location != NSNotFound, @"property values should be displayed when calling \"description\" on RLMArray");
    
    XCTAssertTrue([description rangeOfString:@"age"].location != NSNotFound, @"property names should be displayed when calling \"description\" on RLMArray");
    XCTAssertTrue([description rangeOfString:@"24"].location != NSNotFound, @"property values should be displayed when calling \"description\" on RLMArray");

    XCTAssertTrue([description rangeOfString:@"912 objects skipped"].location != NSNotFound, @"'912 rows more' should be displayed when calling \"description\" on RLMArray");
    
    XCTAssertThrowsSpecificNamed(([[EmployeeObject allObjects] JSONString]), NSException, @"RLMNotImplementedException", @"Not yet implemented");
}

- (void)testDeleteLinksAndObjectsInArray
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    EmployeeObject *po1 = [[EmployeeObject alloc] init];
    po1.age = 40;
    po1.name = @"Joe";
    po1.hired = YES;
    
    EmployeeObject *po2 = [[EmployeeObject alloc] init];
    po2.age = 30;
    po2.name = @"John";
    po2.hired = NO;
    
    EmployeeObject *po3 = [[EmployeeObject alloc] init];
    po3.age = 25;
    po3.name = @"Jill";
    po3.hired = YES;
    
    [realm addObject:po1];
    [realm addObject:po2];
    [realm addObject:po3];
    
    CompanyObject *company = [[CompanyObject alloc] init];
    company.name = @"name";
    company.employees = (RLMArray<EmployeeObject> *)[EmployeeObject allObjects];
    [realm addObject:company];
    
    [realm commitWriteTransaction];
    
    RLMArray *peopleInCompany = company.employees;
    
    // Delete link to employee
    XCTAssertThrowsSpecificNamed([peopleInCompany removeObjectAtIndex:1], NSException, @"RLMException", @"Not allowed in read transaction");
    XCTAssertEqual(peopleInCompany.count, (NSUInteger)3, @"No links should have been deleted");
    
    [realm beginWriteTransaction];
    XCTAssertThrowsSpecificNamed([peopleInCompany removeObjectAtIndex:3], NSException, @"RLMException", @"Out of bounds");
    XCTAssertNoThrow([peopleInCompany removeObjectAtIndex:1], @"Should delete link to employee");
    [realm commitWriteTransaction];
    
    XCTAssertEqual(peopleInCompany.count, (NSUInteger)2, @"link deleted when accessing via links");
    EmployeeObject *test = peopleInCompany[0];
    XCTAssertEqual(test.age, po1.age, @"Should be equal");
    XCTAssertEqualObjects(test.name, po1.name, @"Should be equal");
    XCTAssertEqual(test.hired, po1.hired, @"Should be equal");
    //XCTAssertEqualObjects(test, po1, @"Should be equal"); //FIXME, should work. Asana : https://app.asana.com/0/861870036984/13123030433568
    
    test = peopleInCompany[1];
    XCTAssertEqual(test.age, po3.age, @"Should be equal");
    XCTAssertEqualObjects(test.name, po3.name, @"Should be equal");
    XCTAssertEqual(test.hired, po3.hired, @"Should be equal");
    //XCTAssertEqualObjects(test, po3, @"Should be equal"); // FIXME, should work Asana : https://app.asana.com/0/861870036984/13123030433568
    
    XCTAssertThrowsSpecificNamed([peopleInCompany removeLastObject], NSException, @"RLMException", @"Not allowed in read transaction");
    XCTAssertThrowsSpecificNamed([peopleInCompany removeAllObjects], NSException, @"RLMException", @"Not allowed in read transaction");
    XCTAssertThrowsSpecificNamed([peopleInCompany replaceObjectAtIndex:0 withObject:po2], NSException, @"RLMException", @"Not allowed in read transaction");
    XCTAssertThrowsSpecificNamed([peopleInCompany insertObject:po2 atIndex:0], NSException, @"RLMException", @"Not allowed in read transaction");

    [realm beginWriteTransaction];
    XCTAssertNoThrow([peopleInCompany removeLastObject], @"Should delete last link");
    XCTAssertEqual(peopleInCompany.count, (NSUInteger)1, @"1 remaining link");
    [peopleInCompany replaceObjectAtIndex:0 withObject:po2];
    XCTAssertEqual(peopleInCompany.count, (NSUInteger)1, @"1 link replaced");
    [peopleInCompany insertObject:po1 atIndex:0];
    XCTAssertEqual(peopleInCompany.count, (NSUInteger)2, @"2 links");
    XCTAssertNoThrow([peopleInCompany removeAllObjects], @"Should delete all links");
    XCTAssertEqual(peopleInCompany.count, (NSUInteger)0, @"0 remaining links");
    [realm commitWriteTransaction];
    
    RLMArray *allPeople = [EmployeeObject allObjects];
    XCTAssertEqual(allPeople.count, (NSUInteger)3, @"Only links should have been deleted, not the employees");
    
    
    // Delete the actual employees
    XCTAssertThrowsSpecificNamed([allPeople removeObjectAtIndex:1], NSException, @"RLMException", @"Not allowed in read transaction");
    XCTAssertEqual(allPeople.count, (NSUInteger)3, @"No employees should have been deleted");

    [realm beginWriteTransaction];
    XCTAssertThrows([allPeople removeObjectAtIndex:0], @"Not implemented");
    allPeople = [EmployeeObject allObjects]; // FIXME, when accessors are fully implemented, no need to retrieve all again

    //XCTAssertNoThrow([allPeople removeObjectAtIndex:1], @"Should delete employee"); // FIXME, shouldn't it be possible to delete an item in the middle. Only last is supported
    //XCTAssertEqual(allPeople.count, (NSUInteger)2, @" 1 employee should have been deleted");
    [realm commitWriteTransaction];
}

- (void)testIndexOfObject
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    EmployeeObject *po1 = [EmployeeObject createInRealm:realm withObject:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    EmployeeObject *po2 = [EmployeeObject createInRealm:realm withObject:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    EmployeeObject *po3 = [EmployeeObject createInRealm:realm withObject:@{@"name": @"Jill", @"age": @25, @"hired": @YES}];
    [realm commitWriteTransaction];

    // test TableView RLMArray
    RLMArray *results = [EmployeeObject objectsWhere:@"hired = YES"];
    XCTAssertEqual((NSUInteger)0, [results indexOfObject:po1]);
    XCTAssertEqual((NSUInteger)1, [results indexOfObject:po3]);
    XCTAssertEqual((NSUInteger)NSNotFound, [results indexOfObject:po2]);
}

- (void)testIndexOfObjectWhere
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"Jill", @"age": @25, @"hired": @YES}];
    [realm commitWriteTransaction];

    RLMArray *results = [EmployeeObject objectsWhere:@"hired = YES"];
    XCTAssertEqual((NSUInteger)0, ([results indexOfObjectWhere:@"age = %d", 40]));
    XCTAssertEqual((NSUInteger)1, ([results indexOfObjectWhere:@"age = %d", 25]));
    XCTAssertEqual((NSUInteger)NSNotFound, ([results indexOfObjectWhere:@"age = %d", 30]));
}

- (void)testSubqueryLifetime
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    [realm commitWriteTransaction];

    RLMArray *subarray = nil;
    {
        __attribute((objc_precise_lifetime)) RLMArray *results = [EmployeeObject objectsWhere:@"hired = YES"];
        subarray = [results objectsWhere:@"age = 40"];
    }
    {
        __unused __attribute((objc_precise_lifetime)) RLMArray *results = [EmployeeObject objectsWhere:@"hired = NO"];
    }

    XCTAssertEqualObjects(@"Joe", subarray[0][@"name"]);
}

- (void)testSortingExistingQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"A",  @"age": @20, @"hired": @YES}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"B", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"C", @"age": @40, @"hired": @YES}];
    [realm commitWriteTransaction];

    RLMArray *sortedAge = [[EmployeeObject allObjects] arraySortedByProperty:@"age" ascending:YES];
    RLMArray *sortedName = [sortedAge arraySortedByProperty:@"name" ascending:NO];

    XCTAssertEqual(20, [(EmployeeObject *)sortedAge[0] age]);
    XCTAssertEqual(40, [(EmployeeObject *)sortedName[0] age]);
}

static vm_size_t get_resident_size() {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return info.resident_size;
}

- (void)testQueryMemoryUsage {
    RLMRealm *realm = [self realmWithTestPath];

    [realm beginWriteTransaction];
    StringObject *obj = [[StringObject alloc] init];
    obj.stringCol = @"a";
    [realm addObject:obj];
    [realm commitWriteTransaction];

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"stringCol = 'a'"];

    // Check for memory leaks when creating queries by comparing the memory usage
    // before and after creating a very large number of queries. Anything less
    // than doubling is allowed as there's going to be some natural fluctuation,
    // and failing to clean up 10k queries resulted in far more than doubling.
    vm_size_t size = get_resident_size();
    for (int i = 0; i < 10000; ++i) {
        @autoreleasepool {
            RLMArray *matches = [StringObject objectsInRealm:realm withPredicate:pred];
            XCTAssertEqualObjects([matches[0] stringCol], @"a");
        }
    }
    XCTAssert(get_resident_size() < size * 2);
}

- (void)testCrossThreadAccess
{
    RLMRealm *realm = self.realmWithTestPath;

    [realm beginWriteTransaction];
    [StringObject createInRealm:realm withObject:@[@"name1"]];
    [StringObject createInRealm:realm withObject:@[@"name2"]];
    [realm commitWriteTransaction];

    RLMArray *array = [StringObject allObjects];
    XCTAssertNoThrow([array lastObject]);

    // Using dispatch_async to ensure it actually lands on another thread
    __block OSSpinLock spinlock = OS_SPINLOCK_INIT;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertThrows([array lastObject]);
        OSSpinLockUnlock(&spinlock);
    });
    OSSpinLockLock(&spinlock);
}

@end
