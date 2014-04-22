//
//  subtable.m
//  TightDB
//
//  Test save/load on disk of a realm with one table
//

#import <XCTest/XCTest.h>

#import <realm/objc/Realm.h>

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

- (void)testSubtable {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // Delete realm file
    [fm removeItemAtPath:@"employees.realm" error:nil];
    RLMContext *context = [RLMContext contextPersistedAtPath:@"employees.realm"
                                                       error:nil];
    
    [context writeUsingBlock:^BOOL(RLMRealm *realm) {
        // Create new table in realm
        TestSubtableMain *people = [realm createTableWithName:@"employees" asTableClass:[TestSubtableMain class]];
        
        /* FIXME: Add support for specifying a subtable to the 'add'
         method. The subtable must then be copied into the parent
         table. */
        [people addFirst:@"first" Sub:nil Second:8];
        
        TestSubtableMainRow *cursor = [people rowAtIndex:0];
        TestSubtableSub *subtable = cursor.Sub;
        [subtable addName:@"name" Age:999];
        XCTAssertEqual([subtable rowAtIndex:0].Age, (int64_t)999, @"Age should be 999");
    } error:nil];
}

@end


