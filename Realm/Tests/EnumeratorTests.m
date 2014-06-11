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

@interface EnumPerson : RLMObject
@property NSString * Name;
@property int Age;
@property bool Hired;
@end

@implementation EnumPerson
@end

@interface EnumeratorTests : RLMTestCase

@end

@implementation EnumeratorTests

- (void)testEnum
{
    NSArray *rowsArray = @[@[@"John", @20, @YES],
                           @[@"Mary", @21, @NO],
                           @[@"Lars", @21, @YES],
                           @[@"Phil", @43, @NO],
                           @[@"Anni", @54, @YES]];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    // Add objects
    for (NSArray *rowArray in rowsArray) {
        [EnumPerson createInRealm:realm withObject:rowArray];
    }
    [realm commitWriteTransaction];

    
    RLMArray *people = [EnumPerson allObjects];
    
    // Iterate using for...in
    NSUInteger index = 0;
    for (EnumPerson *row in people) {
        XCTAssertTrue([row.Name isEqualToString:rowsArray[index][0]],
                      @"Name in iteration should be equal to what was set.");
        XCTAssertEqual(row.Age, (int)[rowsArray[index][1] integerValue],
                       @"Age in iteration should be equal to what was set.");
        XCTAssertEqual(row.Hired, (bool)[rowsArray[index][2] boolValue],
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
    RLMArray *res = [EnumPerson objectsWhere:@"Hired = YES && Age >= 20 && Age <= 30"];
    
    
    // 2: Iterate over the resulting RLMArray
    index = 0;
    for (EnumPerson *row in res) {
        XCTAssertTrue([row.Name isEqualToString:filteredArray[index][0]],
                      @"Name in iteration should be equal to what was set.");
        XCTAssertEqual(row.Age, (int)[filteredArray[index][1] integerValue],
                       @"Age in iteration should be equal to what was set.");
        XCTAssertEqual(row.Hired, (bool)[filteredArray[index][2] boolValue],
                       @"Hired in iteration should be equal to what was set.");
        index++;
    }
    
    predicate = [NSPredicate predicateWithBlock:^BOOL(NSArray *evaluatedArray, NSDictionary *bindings) {
        XCTAssertNil(bindings, @"Parameter must be used");
        return [evaluatedArray[1] integerValue] == 21;
    }];
    filteredArray = [rowsArray filteredArrayUsingPredicate:predicate];
}

@end
