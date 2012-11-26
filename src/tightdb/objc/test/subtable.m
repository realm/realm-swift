//
//  subtable.m
//  TightDB
//
//  Test save/load on disk of a group with one table
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>

TIGHTDB_TABLE_2(TestTableSub,
                String, Name,
                Int,    Age)

TIGHTDB_TABLE_3(TestTableMain,
                String,       First,
                TestTableSub, Sub,
                Int,          Second)

@interface MACTestSubtable : SenTestCase
@end
@implementation MACTestSubtable

- (void)setUp
{
    [super setUp];

    // _group = [Group group];
    // NSLog(@"Group: %@", _group);
    // STAssertNotNil(_group, @"Group is nil");
}

- (void)tearDown
{
    // Tear-down code here.

    //  [super tearDown];
    //  _group = nil;
}

- (void)testSubtable
{
    Group *group = [Group group];

    /* Create new table in group */
    TestTableMain *people = [group getTable:@"employees" withClass:[TestTableMain class]];

    /* FIXME: Add support for specifying a subtable to the 'add'
       method. The subtable must then be copied into the parent
       table. */
    [people addFirst:@"first" Sub:nil Second:8];

    TestTableMain_Cursor *cursor = [people objectAtIndex:0];
    TestTableSub *subtable = cursor.Sub;
    [subtable addName:@"name" Age:999];

    STAssertEquals([subtable objectAtIndex:0].Age, (int64_t)999, @"Age should be 999");
}

@end


