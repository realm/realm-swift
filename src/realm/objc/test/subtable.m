//
//  subtable.m
//  TightDB
//
//  Test save/load on disk of a group with one table
//

#import <XCTest/XCTest.h>

#import <realm/objc/Realm.h>
#import <realm/objc/group.h>

REALM_TABLE_2(TestSubtableSub,
                Name, String,
                Age,  Int)

REALM_TABLE_3(TestSubtableMain,
                First,  String,
                Sub,    TestSubtableSub,
                Second, Int)

@interface MACTestSubtable: XCTestCase
@end
@implementation MACTestSubtable

- (void)setUp
{
    [super setUp];

    // _group = [Group group];
    // NSLog(@"Group: %@", _group);
    // XCTAssertNotNil(_group, @"Group is nil");
}

- (void)tearDown
{
    // Tear-down code here.

    //  [super tearDown];
    //  _group = nil;
}

- (void)testSubtable
{
    RLMTransaction *group = [RLMTransaction group];

    /* Create new table in group */
    TestSubtableMain *people = [group createTableWithName:@"employees" asTableClass:[TestSubtableMain class]];

    /* FIXME: Add support for specifying a subtable to the 'add'
       method. The subtable must then be copied into the parent
       table. */
    [people addFirst:@"first" Sub:nil Second:8];

    TestSubtableMainRow *cursor = [people rowAtIndex:0];
    TestSubtableSub *subtable = cursor.Sub;
    [subtable addName:@"name" Age:999];

    XCTAssertEqual([subtable rowAtIndex:0].Age, (int64_t)999, @"Age should be 999");
}

@end


