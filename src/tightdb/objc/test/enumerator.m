//
//  enumerator.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <XCTest/XCTest.h>

#import <tightdb/objc/Tightdb.h>
#import <tightdb/objc/group.h>

TIGHTDB_TABLE_3(EnumPeopleTable,
                Name,  String,
                Age,   Int,
                Hired, Bool)

TIGHTDB_TABLE_2(EnumPeopleTable2,
                Hired, Bool,
                Age,   Int)

@interface MACTestEnumerator: XCTestCase
@end
@implementation MACTestEnumerator

- (void)testTutorial
{
    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
    //------------------------------------------------------
    TDBTransaction *group = [TDBTransaction group];
    // Create new table in group
    EnumPeopleTable *people = [group createTableWithName:@"employees" asTableClass:[EnumPeopleTable class]];

    // Add some rows
    [people addName:@"John" Age:20 Hired:YES];
    [people addName:@"Mary" Age:21 Hired:NO];
    [people addName:@"Lars" Age:21 Hired:YES];
    [people addName:@"Phil" Age:43 Hired:NO];
    [people addName:@"Anni" Age:54 Hired:YES];

    //------------------------------------------------------
    NSLog(@"--- Iterators ---");
    //------------------------------------------------------

    // 1: Iterate over table
    for (EnumPeopleTableRow *row in people) {
        NSLog(@"(Enum)%@ is %lld years old.", row.Name, row.Age);
    }

    // Do a query, and get all matches as TableView
    EnumPeopleTableView *res = [[[[people where].Hired columnIsEqualTo:YES].Age columnIsBetween:20 :30] findAll];
    NSLog(@"View count: %zu", res.rowCount);
    // 2: Iterate over the resulting TableView
    for (EnumPeopleTableRow *row in res) {
        NSLog(@"(Enum2) %@ is %lld years old.", row.Name, row.Age);
    }

    // 3: Iterate over query (lazy)

 EnumPeopleTableQuery *q = [[people where].Age columnIsEqualTo:21];
    NSLog(@"Query lazy count: %zu", [q countRows] );
    for (EnumPeopleTableRow *row in q) {
        NSLog(@"(Enum3) %@ is %lld years old.", row.Name, row.Age);
        if (row.Name == nil)
            break;
    }

}

@end

