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

@interface EnumeratorTests : RLMTestCase
@end

@implementation EnumeratorTests

- (void)testEnum
{
    RLMRealm *realm = [RLMRealm defaultRealm];

    RLMResults *emptyPeople = [EmployeeObject allObjects];
    
    // Enum for zero rows added
    for (EmployeeObject *row in emptyPeople) {
        XCTFail(@"No objects should have been added %@", row);
    }
    
    NSArray *rowsArray = @[@{@"name": @"John", @"age": @20, @"hired": @YES},
                           @{@"name": @"Mary", @"age": @21, @"hired": @NO},
                           @{@"name": @"Lars", @"age": @21, @"hired": @YES},
                           @{@"name": @"Phil", @"age": @43, @"hired": @NO},
                           @{@"name": @"Anni", @"age": @54, @"hired": @YES}];
    
    
    // Add objects
    [realm beginWriteTransaction];
    for (NSArray *rowArray in rowsArray) {
        [EmployeeObject createInRealm:realm withValue:rowArray];
    }
    [realm commitWriteTransaction];

    // Get all objects
    RLMResults *people = [EmployeeObject allObjects];
    
    // Iterate using for...in
    NSUInteger index = 0;
    for (EmployeeObject *row in people) {
        XCTAssertEqualObjects(row.name, rowsArray[index][@"name"], @"Name in iteration should be equal to what was set.");
        XCTAssertEqualObjects(@(row.age), rowsArray[index][@"age"], @"Age in iteration should be equal to what was set.");
        XCTAssertEqualObjects(@(row.hired), rowsArray[index][@"hired"], @"Hired in iteration should be equal to what was set.");
        index++;
    }

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"hired = YES && age BETWEEN {20, 30}"];
    NSArray *filteredArray = [rowsArray filteredArrayUsingPredicate:pred];
    
    // Do a query, and get all matches as RLMResults
    RLMResults *res = [EmployeeObject objectsWithPredicate:pred];
    
    // Iterate over the resulting RLMResults
    index = 0;
    for (EmployeeObject *row in res) {
        XCTAssertEqualObjects(row.name, filteredArray[index][@"name"], @"Name in iteration should be equal to what was set.");
        XCTAssertEqualObjects(@(row.age), filteredArray[index][@"age"], @"Age in iteration should be equal to what was set.");
        XCTAssertEqualObjects(@(row.hired), filteredArray[index][@"hired"], @"Hired in iteration should be equal to what was set.");
        index++;
    }
}

@end
