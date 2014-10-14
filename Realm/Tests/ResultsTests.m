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
       
    RLMResults *result = [AggregateObject objectsInRealm:realm where:@"intCol < %i", 100];
    
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
    
    RLMResults *noArray = [AggregateObject objectsWhere:@"boolCol == NO"];
    RLMResults *yesArray = [AggregateObject objectsWhere:@"boolCol == YES"];
    
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

- (void)testResultsDescription
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    CompanyObject *company = [CompanyObject createInDefaultRealmWithObject:@[@"company", @[]]];
    for (NSInteger i = 0; i < 1012; ++i) {
        EmployeeObject *person = [[EmployeeObject alloc] init];
        person.name = @"Mary";
        person.age = 24;
        person.hired = YES;
        [company.employees addObject:person];
        [realm addObject:person];
    }
    [realm commitWriteTransaction];
    
    NSString *description = [[EmployeeObject allObjects] description];

    XCTAssertTrue([description rangeOfString:@"name"].location != NSNotFound, @"property names should be displayed when calling \"description\" on RLMResults");
    XCTAssertTrue([description rangeOfString:@"Mary"].location != NSNotFound, @"property values should be displayed when calling \"description\" on RLMResults");

    XCTAssertTrue([description rangeOfString:@"age"].location != NSNotFound, @"property names should be displayed when calling \"description\" on RLMResults");
    XCTAssertTrue([description rangeOfString:@"24"].location != NSNotFound, @"property values should be displayed when calling \"description\" on RLMResults");

    XCTAssertTrue([description rangeOfString:@"912 objects skipped"].location != NSNotFound, @"'912 rows more' should be displayed when calling \"description\" on RLMResults");
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
    RLMResults *results = [EmployeeObject objectsWhere:@"hired = YES"];
    XCTAssertEqual((NSUInteger)0, [results indexOfObject:po1]);
    XCTAssertEqual((NSUInteger)1, [results indexOfObject:po3]);
    XCTAssertEqual((NSUInteger)NSNotFound, [results indexOfObject:po2]);
}

- (void)testArrayWithRange
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"Jill", @"age": @25, @"hired": @YES}];
    [realm commitWriteTransaction];

    // test TableView RLMArray
    RLMResults *results = [EmployeeObject allObjects];
    NSArray *sub = [results arrayWithRange:NSMakeRange(0, 3)];
    XCTAssertEqual(sub.count, 3U);
    XCTAssertEqualObjects([sub[0] name], @"Joe");
    XCTAssertEqualObjects([sub[2] name], @"Jill");

    sub = [results arrayWithRange:NSMakeRange(1, 1)];
    XCTAssertEqual(sub.count, 1U);
    XCTAssertEqualObjects([sub[0] name], @"John");

    sub = [results arrayWithRange:NSMakeRange(1, 0)];
    XCTAssertEqual(sub.count, 0U);

    XCTAssertThrows([results arrayWithRange:NSMakeRange(1, 3)]);
}

- (void)testIndexOfObjectWhere
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"Jill", @"age": @25, @"hired": @YES}];
    [realm commitWriteTransaction];

    RLMResults *results = [EmployeeObject objectsWhere:@"hired = YES"];
    XCTAssertEqual((NSUInteger)0, ([results indexOfObjectWhere:@"age = %d", 40]));
    XCTAssertEqual((NSUInteger)1, ([results indexOfObjectWhere:@"age = %d", 25]));
    XCTAssertEqual((NSUInteger)NSNotFound, ([results indexOfObjectWhere:@"age = %d", 30]));
}

- (void)testSubqueryLifetime
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"Jill",  @"age": @50, @"hired": @YES}];
    [realm commitWriteTransaction];

    RLMResults *subarray = nil;
    {
        __attribute((objc_precise_lifetime)) RLMResults *results = [EmployeeObject objectsWhere:@"hired = YES"];
        subarray = [results objectsWhere:@"age = 40"];
    }

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [realm commitWriteTransaction];

    XCTAssertEqualObjects(@"Joe", subarray[0][@"name"]);
}

- (void)testMultiSortLifetime
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"Jill",  @"age": @50, @"hired": @YES}];
    [realm commitWriteTransaction];

    RLMResults *subarray = nil;
    {
        __attribute((objc_precise_lifetime)) RLMResults *results = [[EmployeeObject allObjects] sortedResultsUsingProperty:@"age" ascending:YES];
        subarray = [results sortedResultsUsingProperty:@"age" ascending:NO];
    }

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [realm commitWriteTransaction];

    XCTAssertEqual(3U, subarray.count);
    XCTAssertEqualObjects(@"Jill", subarray[0][@"name"]);
    XCTAssertEqualObjects(@"Joe", subarray[1][@"name"]);
    XCTAssertEqualObjects(@"John", subarray[2][@"name"]);
}

- (void)testSortingExistingQuery
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"A",  @"age": @20, @"hired": @YES}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"B", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withObject:@{@"name": @"C", @"age": @40, @"hired": @YES}];
    [realm commitWriteTransaction];

    RLMResults *sortedAge = [[EmployeeObject allObjects] sortedResultsUsingProperty:@"age" ascending:YES];
    RLMResults *sortedName = [sortedAge sortedResultsUsingProperty:@"name" ascending:NO];

    XCTAssertEqual(20, [(EmployeeObject *)sortedAge[0] age]);
    XCTAssertEqual(40, [(EmployeeObject *)sortedName[0] age]);
}


- (void)testSortByMultipleColumns {
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    DogObject *a1 = [DogObject createInDefaultRealmWithObject:@[@"a", @1]];
    DogObject *a2 = [DogObject createInDefaultRealmWithObject:@[@"a", @2]];
    DogObject *b1 = [DogObject createInDefaultRealmWithObject:@[@"b", @1]];
    DogObject *b2 = [DogObject createInDefaultRealmWithObject:@[@"b", @2]];
    [realm commitWriteTransaction];

    bool (^checkOrder)(NSArray *, NSArray *, NSArray *) = ^bool(NSArray *properties, NSArray *ascending, NSArray *dogs) {
        NSArray *sort = @[[RLMSortDescriptor sortDescriptorWithProperty:properties[0] ascending:[ascending[0] boolValue]],
                          [RLMSortDescriptor sortDescriptorWithProperty:properties[1] ascending:[ascending[1] boolValue]]];
        RLMResults *actual = [[DogObject allObjectsInRealm:realm] sortedResultsUsingDescriptors:sort];

        return [actual[0] isEqualToObject:dogs[0]]
        && [actual[1] isEqualToObject:dogs[1]]
        && [actual[2] isEqualToObject:dogs[2]]
        && [actual[3] isEqualToObject:dogs[3]];
    };

    // Check each valid sort
    XCTAssertTrue(checkOrder(@[@"dogName", @"age"], @[@YES, @YES], @[a1, a2, b1, b2]));
    XCTAssertTrue(checkOrder(@[@"dogName", @"age"], @[@YES, @NO], @[a2, a1, b2, b1]));
    XCTAssertTrue(checkOrder(@[@"dogName", @"age"], @[@NO, @YES], @[b1, b2, a1, a2]));
    XCTAssertTrue(checkOrder(@[@"dogName", @"age"], @[@NO, @NO], @[b2, b1, a2, a1]));
    XCTAssertTrue(checkOrder(@[@"age", @"dogName"], @[@YES, @YES], @[a1, b1, a2, b2]));
    XCTAssertTrue(checkOrder(@[@"age", @"dogName"], @[@YES, @NO], @[b1, a1, b2, a2]));
    XCTAssertTrue(checkOrder(@[@"age", @"dogName"], @[@NO, @YES], @[a2, b2, a1, b1]));
    XCTAssertTrue(checkOrder(@[@"age", @"dogName"], @[@NO, @NO], @[b2, a2, b1, a1]));
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
            RLMResults *matches = [StringObject objectsInRealm:realm withPredicate:pred];
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

    RLMResults *results = [StringObject allObjects];
    XCTAssertNoThrow([results lastObject]);

    // Using dispatch_async to ensure it actually lands on another thread
    __block OSSpinLock spinlock = OS_SPINLOCK_INIT;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertThrows([results lastObject]);
        OSSpinLockUnlock(&spinlock);
    });
    OSSpinLockLock(&spinlock);
}

@end
