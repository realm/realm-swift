//
//  enumerator.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>

@interface EnumPeople : RLMRow
@property NSString * Name;
@property int Age;
@property bool Hired;
@end

@implementation EnumPeople
@end

@interface MACTestEnumerator : RLMTestCase
@end
@implementation MACTestEnumerator

- (void)testTutorial
{
    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
    //------------------------------------------------------
    NSArray *rowsArray = @[@[@"John", @20, @YES],
                           @[@"Mary", @21, @NO],
                           @[@"Lars", @21, @YES],
                           @[@"Phil", @43, @NO],
                           @[@"Anni", @54, @YES]];
    // Create new table in realm
    RLMRealm *realm = [RLMRealm realmWithPersistenceToFile:RLMTestRealmPath initBlock:^(RLMRealm *realm) {
        RLMTable *people = [realm createTableWithName:@"people" objectClass:[EnumPeople class]];
        // Add some rows
        for (NSArray *rowArray in rowsArray) {
            [people addRow:rowArray];
        }
    }];
    RLMTable *people = [realm tableWithName:@"people" objectClass:[EnumPeople class]];
    
    //------------------------------------------------------
    NSLog(@"--- Iterators ---");
    //------------------------------------------------------
    
    // Iterate using for...in
    NSUInteger index = 0;
    for (EnumPeople *row in people) {
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
    
    // Do a query, and get all matches as TableView
    RLMView *res = [people where:@"Hired = YES && Age >= 20 && Age <= 30"];
    NSLog(@"View count: %zu", res.rowCount);
    // 2: Iterate over the resulting TableView
    index = 0;
    for (EnumPeople *row in res) {
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
    
    // 3: Iterate over query (lazy)
    RLMView *q = [people where:@"Age = 21"];
    NSLog(@"Query lazy count: %zu", [q rowCount] );
    index = 0;
    for (EnumPeople *row in q) {
        XCTAssertTrue([row.Name isEqualToString:filteredArray[index][0]],
                      @"Name in iteration should be equal to what was set.");
        XCTAssertEqual(row.Age, (int)[filteredArray[index][1] integerValue],
                       @"Age in iteration should be equal to what was set.");
        XCTAssertEqual(row.Hired, (bool)[filteredArray[index][2] boolValue],
                       @"Hired in iteration should be equal to what was set.");
        index++;
        if (row.Name == nil)
            break;
    }
}


@end

