//
//  enumerator.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>
#import <tightdb/objc/table.h>

TIGHTDB_TABLE_3(EnumPeopleTable,
                Name,  String,
                Age,   Int,
                Hired, Bool)

TIGHTDB_TABLE_2(EnumPeopleTable2,
                Hired, Bool,
                Age,   Int)

@interface MACTestEnumerator: SenTestCase
@end
@implementation MACTestEnumerator

- (void)testTutorial
{
    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
    //------------------------------------------------------
    TightdbGroup *group = [TightdbGroup group];
    // Create new table in group
    EnumPeopleTable *people = [group getTable:@"employees" withClass:[EnumPeopleTable class]];

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
    for (EnumPeopleTable_Cursor *row in people) {
        NSLog(@"(Enum)%@ is %lld years old.", row.Name, row.Age);
    }

    // Do a query, and get all matches as TableView
    EnumPeopleTable_View *res = [[[[people where].Hired equal:YES].Age between:20 to:30] findAll];
    NSLog(@"View count: %zu", [res count]);
    // 2: Iterate over the resulting TableView
    for (EnumPeopleTable_Cursor *row in res) {
        NSLog(@"(Enum2) %@ is %lld years old.", row.Name, row.Age);
    }

    // 3: Iterate over query (lazy)

 EnumPeopleTable_Query *q = [[people where].Age equal:21];
    NSLog(@"Query lazy count: %zu", [q count]);
    for (EnumPeopleTable_Cursor *row in q) {
        NSLog(@"(Enum3) %@ is %lld years old.", row.Name, row.Age);
        if (row.Name == nil)
            break;
    }

}

@end

