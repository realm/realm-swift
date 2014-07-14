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

    RLMArray *emptyPeople = [EmployeeObject allObjects];
    
    // Enum for zero rows added
    for (EmployeeObject *row in emptyPeople) {
        XCTFail(@"No objects should have been added %@", row);
    }
    
    NSArray *rowsArray = @[@[@"John", @20, @YES],
                           @[@"Mary", @21, @NO],
                           @[@"Lars", @21, @YES],
                           @[@"Phil", @43, @NO],
                           @[@"Anni", @54, @YES]];
    
    
    // Add objects
    [realm beginWriteTransaction];
    for (NSArray *rowArray in rowsArray) {
        [EmployeeObject createInRealm:realm withObject:rowArray];
    }
    [realm commitWriteTransaction];

    // Get all objects
    RLMArray *people = [EmployeeObject allObjects];
    
    // Iterate using for...in
    NSUInteger index = 0;
    for (EmployeeObject *row in people) {
        XCTAssertTrue([row.name isEqualToString:rowsArray[index][0]],
                      @"Name in iteration should be equal to what was set.");
        XCTAssertEqual(row.age, (int)[rowsArray[index][1] integerValue],
                       @"Age in iteration should be equal to what was set.");
        XCTAssertEqual(row.hired, (bool)[rowsArray[index][2] boolValue],
                       @"Hired in iteration should be equal to what was set.");
        index++;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSArray *evaluatedArray, NSDictionary *bindings) {
        XCTAssertNil(bindings, @"Parameter must be used");
        return [evaluatedArray[2] boolValue] &&
               [evaluatedArray[1] integerValue] >= 20 &&
               [evaluatedArray[1] integerValue] <= 30;
    }];
    NSArray *filteredArray = [rowsArray filteredArrayUsingPredicate:predicate];
    
    // Do a query, and get all matches as RLMArray
    RLMArray *res = [EmployeeObject objectsWhere:@"hired = YES && age >= 20 && age <= 30"];
    
    // Iterate over the resulting RLMArray
    index = 0;
    for (EmployeeObject *row in res) {
        XCTAssertTrue([row.name isEqualToString:filteredArray[index][0]],
                      @"Name in iteration should be equal to what was set.");
        XCTAssertEqual(row.age, (int)[filteredArray[index][1] integerValue],
                       @"Age in iteration should be equal to what was set.");
        XCTAssertEqual(row.hired, (bool)[filteredArray[index][2] boolValue],
                       @"Hired in iteration should be equal to what was set.");
        index++;
    }
}

@end
