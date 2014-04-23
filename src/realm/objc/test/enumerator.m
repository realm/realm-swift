//
//  enumerator.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <XCTest/XCTest.h>

#import <realm/objc/Realm.h>
#import <realm/objc/group.h>

@interface EnumPeople : RLMRow
@property NSString * Name;
@property int Age;
@property bool Hired;
@end

@implementation EnumPeople
@end

@interface MACTestEnumerator: XCTestCase
@end
@implementation MACTestEnumerator

- (void)testTutorial
{
    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
    //------------------------------------------------------
    RLMTransaction *group = [RLMTransaction group];
    // Create new table in group
    RLMTable *people = [group createTableWithName:@"employees" objectClass:EnumPeople.class];
    
    // Add some rows
    [people addRow:@[@"John", @20, @YES]];
    [people addRow:@[@"Mary", @21, @NO]];
    [people addRow:@[@"Lars", @21, @YES]];
    [people addRow:@[@"Phil", @43, @NO]];
    [people addRow:@[@"Anni", @54, @YES]];
    
    //------------------------------------------------------
    NSLog(@"--- Iterators ---");
    //------------------------------------------------------
    
    // 1: Iterate over table
    for (EnumPeople *row in people) {
        NSLog(@"(Enum)%@ is %d years old.", row.Name, row.Age);
    }
    
    // Do a query, and get all matches as TableView
    RLMView *res = [people where:@"Hired = YES && Age >= 20 && Age <= 30"];
    NSLog(@"View count: %zu", res.rowCount);
    // 2: Iterate over the resulting TableView
    for (EnumPeople *row in res) {
        NSLog(@"(Enum2) %@ is %d years old.", row.Name, row.Age);
    }
    
    // 3: Iterate over query (lazy)
    RLMView *q = [people where:@"Age = 21"];
    NSLog(@"Query lazy count: %zu", [q rowCount] );
    for (EnumPeople *row in q) {
        NSLog(@"(Enum3) %@ is %d years old.", row.Name, row.Age);
        if (row.Name == nil)
            break;
    }
}


@end

