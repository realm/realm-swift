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

@interface AggregateObject : RLMObject
@property int     intCol;
@property float   floatCol;
@property double  doubleCol;
@property BOOL    boolCol;
@property NSDate *dateCol;
@end

@implementation AggregateObject
@end

#pragma mark - Tests

@interface ToJsonObject : RLMObject
@property NSString *name;
@property NSInteger age;
@end

RLM_ARRAY_TYPE(ToJsonObject) //Defines an RLMArray<ToJsonObject> type


@implementation ToJsonObject
@end

@interface ToJsonObjectWithLinks : RLMObject
@property RLMArray<ToJsonObject> *links;
@end

@implementation ToJsonObjectWithLinks
@end


@interface ArrayTests : RLMTestCase
@end

@implementation ArrayTests

- (void)testFastEnumeration
{
    RLMRealm *realm = self.realmWithTestPath;
    
    [realm beginWriteTransaction];
    
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
    
    [realm commitWriteTransaction];
       
    RLMArray *result = [realm objects:[AggregateObject className] withPredicate:[NSPredicate predicateWithFormat:@"intCol < %i", 100]];
    
    XCTAssertEqual(result.count, (NSUInteger)10, @"10 objects added");
    
    int totalSum = 0;
    
    for (AggregateObject *ao in result) {
        totalSum +=ao.intCol;
    }
    
    XCTAssertEqual(totalSum, 100, @"total sum should be 100");
}

- (void)testReadOnly
{
    RLMRealm *realm = self.realmWithTestPath;
    
    [realm beginWriteTransaction];
    StringObject *obj = [StringObject createInRealm:realm withObject:@[@"name"]];
    [realm commitWriteTransaction];
    
    RLMArray *array = [realm allObjects:StringObject.className];
    XCTAssertTrue(array.readOnly, @"Array returned from query should be readonly");
    XCTAssertThrows([array addObject:obj], @"Mutating readOnly array should throw");
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
    
    RLMArray *noArray = [AggregateObject objectsWithPredicateFormat:@"boolCol == NO"];
    RLMArray *yesArray = [AggregateObject objectsWithPredicateFormat:@"boolCol == YES"];
    
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


- (void)testArrayToJSONString
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [ToJsonObject createInRealm:realm withObject:@[@"Mary", @1]];
    [ToJsonObject createInRealm:realm withObject:@[@"John", @2]];
    
    ToJsonObjectWithLinks *withLinks = [[ToJsonObjectWithLinks alloc] init];
    withLinks.links = (RLMArray<ToJsonObject> *)[ToJsonObject allObjects];

    [realm addObject:withLinks];
    
    [realm commitWriteTransaction];
    
    RLMArray *all = [ToJsonObject allObjects];
    
    NSString *json = [all JSONString];
    XCTAssertNotNil(json, @"Should contain json string");
    
    XCTAssertTrue([json rangeOfString:@"name"].location != NSNotFound, @"property names should be displayed when calling \"JSONString\" on RLMArray");
    XCTAssertTrue([json rangeOfString:@"Mary"].location != NSNotFound, @"property values should be displayed when calling \"JSONString\" on RLMArray");
    
    XCTAssertTrue([json rangeOfString:@"age"].location != NSNotFound, @"property names should be displayed when calling \"JSONString\" on RLMArray");
    XCTAssertTrue([json rangeOfString:@"1"].location != NSNotFound, @"property values should be displayed when calling \"JSONString\" on RLMArray");

    XCTAssertThrows([withLinks.links JSONString], @"Array with links not supported");
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

    XCTAssertTrue([description rangeOfString:@"12 objects skipped"].location != NSNotFound, @"'12 rows more' should be displayed when calling \"description\" on RLMArray");

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
    XCTAssertEqual(peopleInCompany.count, (NSUInteger)1, @"1 lin replaced");
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
    XCTAssertThrows([allPeople removeObjectAtIndex:3], @"Out of bounds");
    allPeople = [EmployeeObject allObjects]; // FIXME, when accessors are fully implemented, no need to retrieve all again

    //XCTAssertNoThrow([allPeople removeObjectAtIndex:1], @"Should delete employee"); // FIXME, shouldn't it be possible to delete an item in the middle. Only last is supported
    //XCTAssertEqual(allPeople.count, (NSUInteger)2, @" 1 employee should have been deleted");
    [realm commitWriteTransaction];
}

@end
