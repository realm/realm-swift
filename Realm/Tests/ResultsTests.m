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

#import <mach/mach.h>
#import <objc/runtime.h>

@interface ResultsTests : RLMTestCase
@end

@implementation ResultsTests

- (void)testFastEnumeration
{
    RLMRealm *realm = self.realmWithTestPath;

    // enumerate empty array
    for (__unused id obj in [AggregateObject allObjectsInRealm:realm]) {
        XCTFail(@"Should be empty");
    }

    [realm beginWriteTransaction];
    for (int i = 0; i < 18; ++i) {
        [AggregateObject createInRealm:realm withValue:@[@10, @1.2f, @0.0, @YES, NSDate.date]];
    }
    [realm commitWriteTransaction];

    RLMResults *result = [AggregateObject objectsInRealm:realm where:@"intCol < %i", 100];
    XCTAssertEqual(result.count, 18U);

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

- (void)testFirst {
    XCTAssertNil(IntObject.allObjects.firstObject);
    XCTAssertNil([IntObject objectsWhere:@"intCol > 5"].firstObject);

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [IntObject createInDefaultRealmWithValue:@[@10]];
    [IntObject createInDefaultRealmWithValue:@[@20]];
    [realm commitWriteTransaction];

    XCTAssertEqual(10, [IntObject.allObjects.firstObject intCol]);
    XCTAssertEqual(10, [[IntObject objectsWhere:@"intCol > 5"].firstObject intCol]);
    XCTAssertEqual(20, [[IntObject objectsWhere:@"intCol > 10"].firstObject intCol]);
}

- (void)testLast {
    XCTAssertNil(IntObject.allObjects.lastObject);
    XCTAssertNil([IntObject objectsWhere:@"intCol > 5"].lastObject);

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [IntObject createInDefaultRealmWithValue:@[@20]];
    [IntObject createInDefaultRealmWithValue:@[@10]];
    [realm commitWriteTransaction];

    XCTAssertEqual(10, [IntObject.allObjects.lastObject intCol]);
    XCTAssertEqual(10, [[IntObject objectsWhere:@"intCol > 5"].lastObject intCol]);
    XCTAssertEqual(20, [[IntObject objectsWhere:@"intCol > 10"].lastObject intCol]);
}

- (void)testSubscript {
    RLMAssertThrowsWithReasonMatching([IntObject allObjects][0], @"0.*less than 0");
    RLMAssertThrowsWithReasonMatching([IntObject objectsWhere:@"intCol > 5"][0], @"0.*less than 0");

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [IntObject createInDefaultRealmWithValue:@[@10]];
    [IntObject createInDefaultRealmWithValue:@[@20]];
    [realm commitWriteTransaction];

    XCTAssertEqual(10, [IntObject.allObjects[0] intCol]);
    XCTAssertEqual(10, [[IntObject objectsWhere:@"intCol > 5"][0] intCol]);
    XCTAssertEqual(20, [[IntObject objectsWhere:@"intCol > 10"][0] intCol]);

    RLMAssertThrowsWithReasonMatching([IntObject allObjects][2], @"2.*less than 2");
    RLMAssertThrowsWithReasonMatching([IntObject objectsWhere:@"intCol > 5"][2], @"2.*less than 2");
}

- (void)testValueForKey {
    RLMRealm *realm = self.realmWithTestPath;

    [realm beginWriteTransaction];

    XCTAssertEqualObjects([[AggregateObject allObjectsInRealm:realm] valueForKey:@"intCol"], @[]);

    // Truncate to seconds so it round-trips exactly
    NSDate *dateMinInput = [NSDate dateWithTimeIntervalSince1970:(int64_t)[[NSDate date] timeIntervalSince1970]];
    NSDate *dateMaxInput = [dateMinInput dateByAddingTimeInterval:1000];

    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];

    XCTAssertEqualObjects([[AggregateObject allObjectsInRealm:realm] valueForKey:@"intCol"],
                          (@[@0, @1, @0, @1, @0, @1, @0, @1, @0, @0]));
    XCTAssertTrue([[[[AggregateObject allObjectsInRealm:realm] valueForKey:@"self"] firstObject]
                   isEqualToObject:[AggregateObject allObjectsInRealm:realm].firstObject]);
    XCTAssertTrue([[[[AggregateObject allObjectsInRealm:realm] valueForKey:@"self"] lastObject]
                   isEqualToObject:[AggregateObject allObjectsInRealm:realm].lastObject]);

    XCTAssertEqualObjects([[AggregateObject objectsInRealm:realm where:@"intCol != 1"] valueForKey:@"intCol"],
                          (@[@0, @0, @0, @0, @0, @0]));
    XCTAssertTrue([[[[AggregateObject objectsInRealm:realm where:@"intCol != 1"] valueForKey:@"self"] firstObject]
                   isEqualToObject:[AggregateObject objectsInRealm:realm where:@"intCol != 1"].firstObject]);
    XCTAssertTrue([[[[AggregateObject objectsInRealm:realm where:@"intCol != 1"] valueForKey:@"self"] lastObject]
                   isEqualToObject:[AggregateObject objectsInRealm:realm where:@"intCol != 1"].lastObject]);

    [realm commitWriteTransaction];

    XCTAssertEqualObjects([[AggregateObject allObjectsInRealm:realm] valueForKey:@"intCol"],
                          (@[@0, @1, @0, @1, @0, @1, @0, @1, @0, @0]));
    XCTAssertEqualObjects([[AggregateObject objectsInRealm:realm where:@"intCol != 1"] valueForKey:@"intCol"],
                          (@[@0, @0, @0, @0, @0, @0]));

    XCTAssertThrows([[AggregateObject allObjectsInRealm:realm] valueForKey:@"invalid"]);
}

- (void)testSetValueForKey {
    RLMRealm *realm = self.realmWithTestPath;

    [realm beginWriteTransaction];

    // Truncate to seconds so it round-trips exactly
    NSDate *dateMinInput = [NSDate dateWithTimeIntervalSince1970:(int64_t)[[NSDate date] timeIntervalSince1970]];
    NSDate *dateMaxInput = [dateMinInput dateByAddingTimeInterval:1000];

    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];

    [[AggregateObject allObjectsInRealm:realm] setValue:@25 forKey:@"intCol"];
    XCTAssertEqualObjects([[AggregateObject allObjectsInRealm:realm] valueForKey:@"intCol"],
                          (@[@25, @25, @25, @25, @25, @25, @25, @25, @25, @25]));

    [[AggregateObject objectsInRealm:realm where:@"floatCol > 1"] setValue:@10 forKey:@"intCol"];
    XCTAssertEqualObjects([[AggregateObject objectsInRealm:realm where:@"floatCol > 1"] valueForKey:@"intCol"],
                          (@[@10, @10, @10, @10, @10, @10]));

    XCTAssertThrows([[AggregateObject allObjectsInRealm:realm] valueForKey:@"invalid"]);

    [[AggregateObject objectsInRealm:realm where:@"intCol != 5"] setValue:@5 forKey:@"intCol"];
    XCTAssertEqualObjects([[AggregateObject allObjectsInRealm:realm] valueForKey:@"intCol"],
                          (@[@5, @5, @5, @5, @5, @5, @5, @5, @5, @5]));

    [realm commitWriteTransaction];

    RLMAssertThrowsWithReasonMatching([[AggregateObject allObjectsInRealm:realm] setValue:@25 forKey:@"intCol"],
                                      @"write transaction");
    RLMAssertThrowsWithReasonMatching([[AggregateObject objectsInRealm:realm where:@"floatCol > 1"] setValue:@10 forKey:@"intCol"],
                                      @"write transaction");
}

- (void)testObjectAggregate
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    RLMResults *noArray = [AggregateObject objectsWhere:@"boolCol == NO"];
    RLMResults *yesArray = [AggregateObject objectsWhere:@"boolCol == YES"];
    RLMResults *allArray = [AggregateObject allObjects];

    XCTAssertEqual(0, [noArray sumOfProperty:@"intCol"].intValue);
    XCTAssertEqual(0, [allArray sumOfProperty:@"intCol"].intValue);

    XCTAssertNil([noArray averageOfProperty:@"intCol"]);
    XCTAssertNil([allArray averageOfProperty:@"intCol"]);
    XCTAssertNil([noArray minOfProperty:@"intCol"]);
    XCTAssertNil([allArray minOfProperty:@"intCol"]);
    XCTAssertNil([noArray maxOfProperty:@"intCol"]);
    XCTAssertNil([allArray maxOfProperty:@"intCol"]);

    [realm beginWriteTransaction];

    // Truncate to seconds so it round-trips exactly
    NSDate *dateMinInput = [NSDate dateWithTimeIntervalSince1970:(int64_t)[[NSDate date] timeIntervalSince1970]];
    NSDate *dateMaxInput = [dateMinInput dateByAddingTimeInterval:1000];

    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@1, @0.0f, @2.5, @NO, dateMaxInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];
    [AggregateObject createInRealm:realm withValue:@[@0, @1.2f, @0.0, @YES, dateMinInput]];

    [realm commitWriteTransaction];

    // SUM ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int sum
    XCTAssertEqual([noArray sumOfProperty:@"intCol"].integerValue, 4);
    XCTAssertEqual([yesArray sumOfProperty:@"intCol"].integerValue, 0);
    XCTAssertEqual([allArray sumOfProperty:@"intCol"].integerValue, 4);

    // Test float sum
    XCTAssertEqualWithAccuracy([noArray sumOfProperty:@"floatCol"].floatValue, 0.0f, 0.1f);
    XCTAssertEqualWithAccuracy([yesArray sumOfProperty:@"floatCol"].floatValue, 7.2f, 0.1f);
    XCTAssertEqualWithAccuracy([allArray sumOfProperty:@"floatCol"].floatValue, 7.2f, 0.1f);

    // Test double sum
    XCTAssertEqualWithAccuracy([noArray sumOfProperty:@"doubleCol"].doubleValue, 10.0, 0.1f);
    XCTAssertEqualWithAccuracy([yesArray sumOfProperty:@"doubleCol"].doubleValue, 0.0, 0.1f);
    XCTAssertEqualWithAccuracy([allArray sumOfProperty:@"doubleCol"].doubleValue, 10.0, 0.1f);

    // Test invalid column name
    RLMAssertThrowsWithReasonMatching([yesArray sumOfProperty:@"foo"], @"foo.*AggregateObject");
    RLMAssertThrowsWithReasonMatching([allArray sumOfProperty:@"foo"], @"foo.*AggregateObject");

    // Test operation not supported
    RLMAssertThrowsWithReasonMatching([yesArray sumOfProperty:@"boolCol"], @"sum.*bool");
    RLMAssertThrowsWithReasonMatching([allArray sumOfProperty:@"boolCol"], @"sum.*bool");


    // Average ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int average
    XCTAssertEqualWithAccuracy([noArray averageOfProperty:@"intCol"].doubleValue, 1.0, 0.1f);
    XCTAssertEqualWithAccuracy([yesArray averageOfProperty:@"intCol"].doubleValue, 0.0, 0.1f);
    XCTAssertEqualWithAccuracy([allArray averageOfProperty:@"intCol"].doubleValue, 0.4, 0.1f);

    // Test float average
    XCTAssertEqualWithAccuracy([noArray averageOfProperty:@"floatCol"].doubleValue, 0.0, 0.1f);
    XCTAssertEqualWithAccuracy([yesArray averageOfProperty:@"floatCol"].doubleValue, 1.2, 0.1f);
    XCTAssertEqualWithAccuracy([allArray averageOfProperty:@"floatCol"].doubleValue, 0.72, 0.1f);

    // Test double average
    XCTAssertEqualWithAccuracy([noArray averageOfProperty:@"doubleCol"].doubleValue, 2.5, 0.1f);
    XCTAssertEqualWithAccuracy([yesArray averageOfProperty:@"doubleCol"].doubleValue, 0.0, 0.1f);
    XCTAssertEqualWithAccuracy([allArray averageOfProperty:@"doubleCol"].doubleValue, 1.0, 0.1f);

    // Test invalid column name
    RLMAssertThrowsWithReasonMatching([yesArray averageOfProperty:@"foo"], @"foo.*AggregateObject");
    RLMAssertThrowsWithReasonMatching([allArray averageOfProperty:@"foo"], @"foo.*AggregateObject");

    // Test operation not supported
    RLMAssertThrowsWithReasonMatching([yesArray averageOfProperty:@"boolCol"], @"average.*bool");
    RLMAssertThrowsWithReasonMatching([allArray averageOfProperty:@"boolCol"], @"average.*bool");

    // MIN ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int min
    XCTAssertEqual(1, [[noArray minOfProperty:@"intCol"] intValue]);
    XCTAssertEqual(0, [[yesArray minOfProperty:@"intCol"] intValue]);
    XCTAssertEqual(0, [[allArray minOfProperty:@"intCol"] intValue]);

    // Test float min
    XCTAssertEqual(0.0f, [[noArray minOfProperty:@"floatCol"] floatValue]);
    XCTAssertEqual(1.2f, [[yesArray minOfProperty:@"floatCol"] floatValue]);
    XCTAssertEqual(0.0f, [[allArray minOfProperty:@"floatCol"] floatValue]);

    // Test double min
    XCTAssertEqual(2.5, [[noArray minOfProperty:@"doubleCol"] doubleValue]);
    XCTAssertEqual(0.0, [[yesArray minOfProperty:@"doubleCol"] doubleValue]);
    XCTAssertEqual(0.0, [[allArray minOfProperty:@"doubleCol"] doubleValue]);

    // Test date min
    XCTAssertEqualObjects(dateMaxInput, [noArray minOfProperty:@"dateCol"]);
    XCTAssertEqualObjects(dateMinInput, [yesArray minOfProperty:@"dateCol"]);
    XCTAssertEqualObjects(dateMinInput, [allArray minOfProperty:@"dateCol"]);

    // Test invalid column name
    RLMAssertThrowsWithReasonMatching([yesArray minOfProperty:@"foo"], @"foo.*AggregateObject");
    RLMAssertThrowsWithReasonMatching([allArray minOfProperty:@"foo"], @"foo.*AggregateObject");

    // Test operation not supported
    RLMAssertThrowsWithReasonMatching([yesArray minOfProperty:@"boolCol"], @"min.*bool");
    RLMAssertThrowsWithReasonMatching([allArray minOfProperty:@"boolCol"], @"min.*bool");

    // MAX ::::::::::::::::::::::::::::::::::::::::::::::
    // Test int max
    XCTAssertEqual(1, [[noArray maxOfProperty:@"intCol"] intValue]);
    XCTAssertEqual(0, [[yesArray maxOfProperty:@"intCol"] intValue]);
    XCTAssertEqual(1, [[allArray maxOfProperty:@"intCol"] intValue]);

    // Test float max
    XCTAssertEqual(0.0f, [[noArray maxOfProperty:@"floatCol"] floatValue]);
    XCTAssertEqual(1.2f, [[yesArray maxOfProperty:@"floatCol"] floatValue]);
    XCTAssertEqual(1.2f, [[allArray maxOfProperty:@"floatCol"] floatValue]);

    // Test double max
    XCTAssertEqual(2.5, [[noArray maxOfProperty:@"doubleCol"] doubleValue]);
    XCTAssertEqual(0.0, [[yesArray maxOfProperty:@"doubleCol"] doubleValue]);
    XCTAssertEqual(2.5, [[allArray maxOfProperty:@"doubleCol"] doubleValue]);

    // Test date max
    XCTAssertEqualObjects(dateMaxInput, [noArray maxOfProperty:@"dateCol"]);
    XCTAssertEqualObjects(dateMinInput, [yesArray maxOfProperty:@"dateCol"]);
    XCTAssertEqualObjects(dateMaxInput, [allArray maxOfProperty:@"dateCol"]);

    // Test invalid column name
    RLMAssertThrowsWithReasonMatching([yesArray maxOfProperty:@"foo"], @"foo.*AggregateObject");
    RLMAssertThrowsWithReasonMatching([allArray maxOfProperty:@"foo"], @"foo.*AggregateObject");

    // Test operation not supported
    RLMAssertThrowsWithReasonMatching([yesArray maxOfProperty:@"boolCol"], @"max.*bool");
    RLMAssertThrowsWithReasonMatching([allArray maxOfProperty:@"boolCol"], @"max.*bool");
}

- (void)testValueForCollectionOperationKeyPath
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    EmployeeObject *c1e1 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    EmployeeObject *c1e2 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    EmployeeObject *c1e3 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Jill", @"age": @25, @"hired": @YES}];
    [CompanyObject createInRealm:realm withValue:@{@"name": @"InspiringNames LLC", @"employees": @[c1e1, c1e2, c1e3]}];

    EmployeeObject *c2e1 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"A", @"age": @20, @"hired": @YES}];
    EmployeeObject *c2e2 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"B", @"age": @30, @"hired": @NO}];
    EmployeeObject *c2e3 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"C", @"age": @40, @"hired": @YES}];
    [CompanyObject createInRealm:realm withValue:@{@"name": @"ABC AG", @"employees": @[c2e1, c2e2, c2e3]}];

    EmployeeObject *c3e1 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"A", @"age": @21, @"hired": @YES}];
    [CompanyObject createInRealm:realm withValue:@{@"name": @"ABC AG", @"employees": @[c3e1]}];
    [realm commitWriteTransaction];

    RLMResults *allCompanies = [CompanyObject allObjects];
    RLMResults *allEmployees = [EmployeeObject allObjects];

    // count operator
    XCTAssertEqual([[allCompanies valueForKeyPath:@"@count"] integerValue], 3);

    // numeric operators
    XCTAssertEqual([[allEmployees valueForKeyPath:@"@min.age"] intValue], 20);
    XCTAssertEqual([[allEmployees valueForKeyPath:@"@max.age"] intValue], 40);
    XCTAssertEqual([[allEmployees valueForKeyPath:@"@sum.age"] integerValue], 206);
    XCTAssertEqualWithAccuracy([[allEmployees valueForKeyPath:@"@avg.age"] doubleValue], 29.43, 0.1f);

    // collection
    XCTAssertEqualObjects([allCompanies valueForKeyPath:@"@unionOfObjects.name"], (@[@"InspiringNames LLC", @"ABC AG", @"ABC AG"]));
    XCTAssertEqualObjects([allCompanies valueForKeyPath:@"@distinctUnionOfObjects.name"], (@[@"ABC AG", @"InspiringNames LLC"]));
    XCTAssertEqualObjects([allCompanies valueForKeyPath:@"employees.@unionOfArrays.name"], (@[@"Joe", @"John", @"Jill", @"A", @"B", @"C", @"A"]));
    XCTAssertEqualObjects([NSSet setWithArray:[allCompanies valueForKeyPath:@"employees.@distinctUnionOfArrays.name"]], ([NSSet setWithArray:@[@"Joe", @"John", @"Jill", @"A", @"B", @"C"]]));

    // invalid key paths
    RLMAssertThrowsWithReasonMatching([allCompanies valueForKeyPath:@"@invalid"], @"Unsupported KVC collection operator found in key path '@invalid'");
    RLMAssertThrowsWithReasonMatching([allCompanies valueForKeyPath:@"@sum"], @"Missing key path for KVC collection operator sum in key path '@sum'");
    RLMAssertThrowsWithReasonMatching([allCompanies valueForKeyPath:@"@sum."], @"Missing key path for KVC collection operator sum in key path '@sum.'");
    RLMAssertThrowsWithReasonMatching([allCompanies valueForKeyPath:@"@sum.employees.@sum.age"], @"Nested key paths.*not supported");
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

    XCTAssertTrue([description rangeOfString:@"name"].location != NSNotFound);
    XCTAssertTrue([description rangeOfString:@"Mary"].location != NSNotFound);

    XCTAssertTrue([description rangeOfString:@"age"].location != NSNotFound);
    XCTAssertTrue([description rangeOfString:@"24"].location != NSNotFound);

    XCTAssertTrue([description rangeOfString:@"912 objects skipped"].location != NSNotFound);
}

- (void)testIndexOfObject
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    EmployeeObject *po1 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    EmployeeObject *po2 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    EmployeeObject *po3 = [EmployeeObject createInRealm:realm withValue:@{@"name": @"Jill", @"age": @25, @"hired": @YES}];
    StringObject *so = [StringObject createInRealm:realm withValue:@[@""]];
    StringObject *deletedObject = [StringObject createInRealm:realm withValue:@[@""]];
    [realm deleteObject:deletedObject];
    [realm commitWriteTransaction];

    EmployeeObject *standalone = [[EmployeeObject alloc] init];

    RLMResults *results = [EmployeeObject objectsWhere:@"hired = YES"];
    XCTAssertEqual(0U, [results indexOfObject:po1]);
    XCTAssertEqual(1U, [results indexOfObject:po3]);
    XCTAssertEqual((NSUInteger)NSNotFound, [results indexOfObject:po2]);
    XCTAssertEqual((NSUInteger)NSNotFound, [results indexOfObject:standalone]);
    RLMAssertThrowsWithReasonMatching([results indexOfObject:so], @"StringObject.*EmployeeObject");
    RLMAssertThrowsWithReasonMatching([results indexOfObject:deletedObject], @"Object has been invalidated");

    [results lastObject]; // Force to tableview mode
    XCTAssertEqual(0U, [results indexOfObject:po1]);
    XCTAssertEqual(1U, [results indexOfObject:po3]);
    XCTAssertEqual((NSUInteger)NSNotFound, [results indexOfObject:po2]);
    XCTAssertEqual((NSUInteger)NSNotFound, [results indexOfObject:standalone]);
    RLMAssertThrowsWithReasonMatching([results indexOfObject:so], @"StringObject.*EmployeeObject");
    RLMAssertThrowsWithReasonMatching([results indexOfObject:deletedObject], @"Object has been invalidated");

    // reverse order from sort
    results = [[EmployeeObject objectsWhere:@"hired = YES"] sortedResultsUsingProperty:@"age" ascending:YES];
    XCTAssertEqual(1U, [results indexOfObject:po1]);
    XCTAssertEqual(0U, [results indexOfObject:po3]);
    XCTAssertEqual((NSUInteger)NSNotFound, [results indexOfObject:po2]);
    XCTAssertEqual((NSUInteger)NSNotFound, [results indexOfObject:standalone]);
    RLMAssertThrowsWithReasonMatching([results indexOfObject:so], @"StringObject.*EmployeeObject");
    RLMAssertThrowsWithReasonMatching([results indexOfObject:deletedObject], @"Object has been invalidated");

    results = [EmployeeObject allObjects];
    XCTAssertEqual(0U, [results indexOfObject:po1]);
    XCTAssertEqual(1U, [results indexOfObject:po2]);
    XCTAssertEqual(2U, [results indexOfObject:po3]);
    XCTAssertEqual((NSUInteger)NSNotFound, [results indexOfObject:standalone]);
    RLMAssertThrowsWithReasonMatching([results indexOfObject:so], @"StringObject.*EmployeeObject");
    RLMAssertThrowsWithReasonMatching([results indexOfObject:deletedObject], @"Object has been invalidated");
}

- (void)testIndexOfObjectWhere
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"Jill", @"age": @25, @"hired": @YES}];
    [realm commitWriteTransaction];

    RLMResults *results = [EmployeeObject objectsWhere:@"hired = YES"];
    XCTAssertEqual(0U, ([results indexOfObjectWhere:@"age = %d", 40]));
    XCTAssertEqual(1U, ([results indexOfObjectWhere:@"age = %d", 25]));
    XCTAssertEqual((NSUInteger)NSNotFound, ([results indexOfObjectWhere:@"age = %d", 30]));

    results = [EmployeeObject allObjects];
    XCTAssertEqual(0U, ([results indexOfObjectWhere:@"age = %d", 40]));
    XCTAssertEqual(1U, ([results indexOfObjectWhere:@"age = %d", 30]));
    XCTAssertEqual(2U, ([results indexOfObjectWhere:@"age = %d", 25]));
    XCTAssertEqual((NSUInteger)NSNotFound, ([results indexOfObjectWhere:@"age = %d", 35]));
}

- (void)testSubqueryLifetime
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"Jill",  @"age": @50, @"hired": @YES}];
    [realm commitWriteTransaction];

    RLMResults *subarray = nil;
    {
        __attribute((objc_precise_lifetime)) RLMResults *results = [EmployeeObject objectsWhere:@"hired = YES"];
        subarray = [results objectsWhere:@"age = 40"];
    }

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
    [realm commitWriteTransaction];

    XCTAssertEqualObjects(@"Joe", subarray[0][@"name"]);
}

- (void)testMultiSortLifetime
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"John", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"Jill",  @"age": @50, @"hired": @YES}];
    [realm commitWriteTransaction];

    RLMResults *subarray = nil;
    {
        __attribute((objc_precise_lifetime)) RLMResults *results = [[EmployeeObject allObjects] sortedResultsUsingProperty:@"age" ascending:YES];
        subarray = [results sortedResultsUsingProperty:@"age" ascending:NO];
    }

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"Joe",  @"age": @40, @"hired": @YES}];
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
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"A",  @"age": @20, @"hired": @YES}];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"B", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"C", @"age": @40, @"hired": @YES}];
    [realm commitWriteTransaction];

    RLMResults *sortedAge = [[EmployeeObject allObjects] sortedResultsUsingProperty:@"age" ascending:YES];
    RLMResults *sortedName = [sortedAge sortedResultsUsingProperty:@"name" ascending:NO];

    XCTAssertEqual(20, [(EmployeeObject *)sortedAge[0] age]);
    XCTAssertEqual(40, [(EmployeeObject *)sortedName[0] age]);
}

- (void)testRerunningSortedQuery {
    RLMRealm *realm = [RLMRealm defaultRealm];

    RLMResults *sortedAge = [[EmployeeObject allObjects] sortedResultsUsingProperty:@"age" ascending:YES];
    [sortedAge lastObject]; // Force creation of the TableView
    RLMResults *sortedName = [sortedAge sortedResultsUsingProperty:@"name" ascending:NO];
    [sortedName lastObject]; // Force creation of the TableView
    RLMResults *filtered = [sortedName objectsWhere:@"age > 20"];
    [filtered lastObject]; // Force creation of the TableView

    [realm beginWriteTransaction];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"A",  @"age": @20, @"hired": @YES}];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"B", @"age": @30, @"hired": @NO}];
    [EmployeeObject createInRealm:realm withValue:@{@"name": @"C", @"age": @40, @"hired": @YES}];
    [realm commitWriteTransaction];

    XCTAssertEqual(3U, sortedAge.count);
    XCTAssertEqual(3U, sortedName.count);
    XCTAssertEqual(2U, filtered.count);

    XCTAssertEqual(20, [(EmployeeObject *)sortedAge[0] age]);
    XCTAssertEqual(30, [(EmployeeObject *)sortedAge[1] age]);
    XCTAssertEqual(40, [(EmployeeObject *)sortedAge[2] age]);

    XCTAssertEqual(40, [(EmployeeObject *)sortedName[0] age]);
    XCTAssertEqual(30, [(EmployeeObject *)sortedName[1] age]);
    XCTAssertEqual(20, [(EmployeeObject *)sortedName[2] age]);

    XCTAssertEqual(40, [(EmployeeObject *)filtered[0] age]);
    XCTAssertEqual(30, [(EmployeeObject *)filtered[1] age]);
}

- (void)testLiveUpdateFirst {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    [IntObject createInRealm:realm withValue:@[@0]];

    RLMResults *objects = [IntObject objectsInRealm:realm where:@"intCol = 0"];
    XCTAssertNotNil([objects firstObject]);
    [objects.firstObject setIntCol:1];
    XCTAssertNil([objects firstObject]);

    [realm cancelWriteTransaction];
}

- (void)testLiveUpdateLast {
    RLMRealm *realm = self.realmWithTestPath;
    [realm beginWriteTransaction];
    [IntObject createInRealm:realm withValue:@[@0]];

    RLMResults *objects = [IntObject objectsInRealm:realm where:@"intCol = 0"];
    XCTAssertNotNil([objects lastObject]);
    [objects.lastObject setIntCol:1];
    XCTAssertNil([objects lastObject]);

    [realm cancelWriteTransaction];
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

- (void)testDeleteAllObjects
{
    RLMRealm *realm = self.realmWithTestPath;

    [realm beginWriteTransaction];
    [StringObject createInRealm:realm withValue:@[@"name1"]];
    [StringObject createInRealm:realm withValue:@[@"name2"]];
    [realm commitWriteTransaction];

    RLMResults *results = [StringObject objectsInRealm:realm where:@"stringCol = 'name1'"];
    RLMAssertThrowsWithReasonMatching([realm deleteObjects:results], @"write transaction");
    [realm beginWriteTransaction];
    [realm deleteObjects:results];
    [realm commitWriteTransaction];
    XCTAssertEqual(0U, results.count);
    XCTAssertEqual(1U, [StringObject allObjectsInRealm:realm].count);

    results = [StringObject allObjectsInRealm:realm];
    RLMAssertThrowsWithReasonMatching([realm deleteObjects:results], @"write transaction");
    [realm beginWriteTransaction];
    [realm deleteObjects:results];
    [realm commitWriteTransaction];
    XCTAssertEqual(0U, results.count);
    XCTAssertEqual(0U, [StringObject allObjectsInRealm:realm].count);
}

- (void)testEnumerateAndDeleteTableResults {
    RLMRealm *realm = self.realmWithTestPath;
    const int count = 40;

    [realm beginWriteTransaction];
    for (int i = 0; i < count; ++i) {
        [IntObject createInRealm:realm withValue:@[@(i)]];
    }

    int enumeratedCount = 0;
    for (IntObject *io in [IntObject allObjectsInRealm:realm]) {
        ++enumeratedCount;
        [realm deleteObject:io];
    }

    XCTAssertEqual(0U, [IntObject allObjectsInRealm:realm].count);
    XCTAssertEqual(count, enumeratedCount);

    [realm cancelWriteTransaction];
}

- (void)testEnumerateAndMutateQueryCondition {
    RLMRealm *realm = self.realmWithTestPath;
    const int count = 40;

    [realm beginWriteTransaction];
    for (int i = 0; i < count; ++i) {
        [IntObject createInRealm:realm withValue:@[@(0)]];
    }

    int enumeratedCount = 0;
    for (IntObject *io in [IntObject objectsInRealm:realm where:@"intCol = 0"]) {
        ++enumeratedCount;
        io.intCol = enumeratedCount;
    }

    XCTAssertEqual(0U, [IntObject objectsInRealm:realm where:@"intCol = 0"].count);
    XCTAssertEqual(count, enumeratedCount);

    [realm cancelWriteTransaction];
}

- (void)testManualRefreshDuringEnumeration {
    RLMRealm *realm = self.realmWithTestPath;
    const int count = 40;

    [realm beginWriteTransaction];
    for (int i = 0; i < count; ++i) {
        [IntObject createInRealm:realm withValue:@[@(0)]];
    }
    [realm commitWriteTransaction];

    realm.autorefresh = NO;
    [self dispatchAsyncAndWait:^{
        RLMRealm *realm = self.realmWithTestPath;
        [realm beginWriteTransaction];
        // FIXME: this is roundabout because `table.clear()` does not update
        // table views correctly
        [realm deleteObjects:[IntObject objectsInRealm:realm where:@"intCol = 0"]];
        [realm commitWriteTransaction];
    }];

    int enumeratedCount = 0;
    for (IntObject *io in [IntObject allObjectsInRealm:realm]) {
        [realm refresh];
        XCTAssertTrue(io.invalidated);
        ++enumeratedCount;
    }

    XCTAssertEqual(enumeratedCount, count);
}

- (void)testCallInvalidateDuringEnumeration {
    RLMRealm *realm = self.realmWithTestPath;
    const int count = 40;

    [realm beginWriteTransaction];
    for (int i = 0; i < count; ++i) {
        [IntObject createInRealm:realm withValue:@[@(0)]];
    }
    [realm commitWriteTransaction];

    int enumeratedCount = 0;
    @try {
        for (__unused IntObject *io in [IntObject objectsInRealm:realm where:@"intCol = 0"]) {
            ++enumeratedCount;
            [realm invalidate];
        }
        XCTFail(@"Should have thrown an exception");
    }
    @catch (NSException *e) {
        XCTAssertEqualObjects(e.reason, @"Collection is no longer valid");
    }
    XCTAssertEqual(16, enumeratedCount);

    // Also test with the enumeration done within a write transaction
    [realm beginWriteTransaction];
    enumeratedCount = 0;
    @try {
        for (__unused IntObject *io in [IntObject objectsInRealm:realm where:@"intCol = 0"]) {
            ++enumeratedCount;
            [realm invalidate];
        }
        XCTFail(@"Should have thrown an exception");
    }
    @catch (NSException *e) {
        XCTAssertEqualObjects(e.reason, @"Collection is no longer valid");
    }
    XCTAssertEqual(16, enumeratedCount);
}

- (void)testBeginWriteTransactionDuringEnumeration {
    RLMRealm *realm = self.realmWithTestPath;
    const int count = 40;

    [realm beginWriteTransaction];
    for (int i = 0; i < count; ++i) {
        [IntObject createInRealm:realm withValue:@[@(0)]];
    }
    [realm commitWriteTransaction];

    for (IntObject *io in [IntObject objectsInRealm:realm where:@"intCol = 0"]) {
        [realm beginWriteTransaction];
        io.intCol = 1;
        [realm commitWriteTransaction];
    }

    XCTAssertEqual(40U, [IntObject objectsInRealm:realm where:@"intCol = 1"].count);
}

- (void)testAllMethodsCheckThread {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [IntObject createInDefaultRealmWithValue:@[@0]];
    }];

    RLMResults *results = [IntObject allObjects];
    XCTAssertNoThrow([results objectAtIndex:0]);
    XCTAssertNoThrow([results firstObject]);
    XCTAssertNoThrow([results lastObject]);
    XCTAssertNoThrow([results indexOfObject:[IntObject allObjects].firstObject]);
    XCTAssertNoThrow([results indexOfObjectWhere:@"intCol = 0"]);
    XCTAssertNoThrow([results indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:@"intCol = 0"]]);
    XCTAssertNoThrow([results objectsWhere:@"intCol = 0"]);
    XCTAssertNoThrow([results objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol = 0"]]);
    XCTAssertNoThrow([results sortedResultsUsingProperty:@"intCol" ascending:YES]);
    XCTAssertNoThrow([results sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"intCol" ascending:YES]]]);
    XCTAssertNoThrow([results minOfProperty:@"intCol"]);
    XCTAssertNoThrow([results maxOfProperty:@"intCol"]);
    XCTAssertNoThrow([results sumOfProperty:@"intCol"]);
    XCTAssertNoThrow([results averageOfProperty:@"intCol"]);
    XCTAssertNoThrow(results[0]);
    XCTAssertNoThrow([results valueForKey:@"intCol"]);

    [self dispatchAsyncAndWait:^{
        XCTAssertThrows([results objectAtIndex:0]);
        XCTAssertThrows([results firstObject]);
        XCTAssertThrows([results lastObject]);
        XCTAssertThrows([results indexOfObject:[IntObject allObjects].firstObject]);
        XCTAssertThrows([results indexOfObjectWhere:@"intCol = 0"]);
        XCTAssertThrows([results indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:@"intCol = 0"]]);
        XCTAssertThrows([results objectsWhere:@"intCol = 0"]);
        XCTAssertThrows([results objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol = 0"]]);
        XCTAssertThrows([results sortedResultsUsingProperty:@"intCol" ascending:YES]);
        XCTAssertThrows([results sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"intCol" ascending:YES]]]);
        XCTAssertThrows([results minOfProperty:@"intCol"]);
        XCTAssertThrows([results maxOfProperty:@"intCol"]);
        XCTAssertThrows([results sumOfProperty:@"intCol"]);
        XCTAssertThrows([results averageOfProperty:@"intCol"]);
        XCTAssertThrows(results[0]);
        XCTAssertThrows([results valueForKey:@"intCol"]);
    }];
}

- (void)testAllMethodsCheckForInvalidation {
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [IntObject createInDefaultRealmWithValue:@[@0]];
    }];

    RLMResults *results = [IntObject allObjects];
    XCTAssertNoThrow([results objectAtIndex:0]);
    XCTAssertNoThrow([results firstObject]);
    XCTAssertNoThrow([results lastObject]);
    XCTAssertNoThrow([results indexOfObject:[IntObject allObjects].firstObject]);
    XCTAssertNoThrow([results indexOfObjectWhere:@"intCol = 0"]);
    XCTAssertNoThrow([results indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:@"intCol = 0"]]);
    XCTAssertNoThrow([results objectsWhere:@"intCol = 0"]);
    XCTAssertNoThrow([results objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol = 0"]]);
    XCTAssertNoThrow([results sortedResultsUsingProperty:@"intCol" ascending:YES]);
    XCTAssertNoThrow([results sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"intCol" ascending:YES]]]);
    XCTAssertNoThrow([results minOfProperty:@"intCol"]);
    XCTAssertNoThrow([results maxOfProperty:@"intCol"]);
    XCTAssertNoThrow([results sumOfProperty:@"intCol"]);
    XCTAssertNoThrow([results averageOfProperty:@"intCol"]);
    XCTAssertNoThrow(results[0]);
    XCTAssertNoThrow([results valueForKey:@"intCol"]);
    XCTAssertNoThrow({for (__unused id obj in results);});

    [realm invalidate];

    XCTAssertThrows([results objectAtIndex:0]);
    XCTAssertThrows([results firstObject]);
    XCTAssertThrows([results lastObject]);
    XCTAssertThrows([results indexOfObject:[IntObject allObjects].firstObject]);
    XCTAssertThrows([results indexOfObjectWhere:@"intCol = 0"]);
    XCTAssertThrows([results indexOfObjectWithPredicate:[NSPredicate predicateWithFormat:@"intCol = 0"]]);
    XCTAssertThrows([results objectsWhere:@"intCol = 0"]);
    XCTAssertThrows([results objectsWithPredicate:[NSPredicate predicateWithFormat:@"intCol = 0"]]);
    XCTAssertThrows([results sortedResultsUsingProperty:@"intCol" ascending:YES]);
    XCTAssertThrows([results sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"intCol" ascending:YES]]]);
    XCTAssertThrows([results minOfProperty:@"intCol"]);
    XCTAssertThrows([results maxOfProperty:@"intCol"]);
    XCTAssertThrows([results sumOfProperty:@"intCol"]);
    XCTAssertThrows([results averageOfProperty:@"intCol"]);
    XCTAssertThrows(results[0]);
    XCTAssertThrows([results valueForKey:@"intCol"]);
    XCTAssertThrows({for (__unused id obj in results);});
}

@end
