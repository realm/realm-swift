//
//  group_misc_2.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>
#import <realm/objc/RLMRealm.h>
#import <realm/objc/RLMPrivate.h>

@interface MyObject : RLMRow

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) BOOL hired;
@property (nonatomic, assign) NSInteger spare;

@end

@implementation MyObject
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(MyTable, MyObject);

@interface MyObject2 : RLMRow

@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) BOOL hired;

@end

@implementation MyObject2
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(MyTable2, MyObject2);

@interface QueryObject : RLMRow

@property (nonatomic, assign) NSInteger a;
@property (nonatomic, copy) NSString *b;

@end

@implementation QueryObject
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(QueryTable, QueryObject);

@interface MACTestRealmMisc2 : RLMTestCase

@end

@implementation MACTestRealmMisc2

- (void)testRealm_Misc2 {
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        MyTable *table = [MyTable tableInRealm:realm named:@"table"];
        
        // Add some rows
        [table addRow:@[@"John", @20, @YES, @0]];
        [table addRow:@[@"Mary", @21, @NO, @0]];
        [table addRow:@[@"Lars", @21, @YES, @0]];
        [table addRow:@[@"Phil", @43, @NO, @0]];
        [table addRow:@[@"Anni", @54, @YES, @0]];
        
        //------------------------------------------------------
        
        XCTAssertNil([table firstWhere:@"name == 'Philip'"], @"Philip should not be there");
        XCTAssertNotNil([table firstWhere:@"name == 'Mary'"], @"Mary should be there");
        XCTAssertEqual([table countWhere:@"age == 21"], (NSUInteger)2, @"Should be two rows in view");
    
        //------------------------------------------------------

        MyTable2* table2 = [MyTable2 tableInRealm:realm named:@"table2"];
        
        // Add some rows
        [table2 addRow:@[@20, @YES]];
        [table2 addRow:@[@21, @NO]];
        [table2 addRow:@[@22, @YES]];
        [table2 addRow:@[@43, @NO]];
        [table2 addRow:@[@54, @YES]];

        // Create view (current employees between 20 and 30 years old)
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hired == YES && age between %@", @[@20, @30]];
        RLMView *g = [table2 allWhere:predicate];
        
        // Get number of matching entries
        XCTAssertEqual(g.rowCount, (NSUInteger)2, @"Expected 2 rows in query");
        
        // Get the average age
        XCTAssertEqual([[table2 averageOfProperty:@"age" where:predicate] doubleValue], (double)21.0,@"Expected 21 average");
        
        // Iterate over view
        for (NSUInteger i = 0; i < [g rowCount]; i++) {
            NSLog(@"%zu: is %@ years old", i, g[i][@"age"]);
        }

        //------------------------------------------------------
        
        // Load a realm from disk (and print contents)
        RLMRealm * fromDisk = [self realmPersistedAtTestPath];
        MyTable* diskTable = [MyTable tableInRealm:fromDisk named:@"table"];
        
        for (NSUInteger i = 0; i < diskTable.rowCount; i++) {
            MyObject *object = diskTable[i];
            NSLog(@"%zu: %@", i, object.name);
            NSLog(@"%zu: %ld", i, (long)object.age);
        }
    }];
}

// Tables can contain other tables, however this is not yet supported
// by the high level API. The following illustrates how to do it
// through the low level API.
- (void)testSubtables {
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm createTableWithName:@"table"];
        
        // Specify the table type
        {
            RLMDescriptor * desc = table.descriptor;
            [desc addColumnWithName:@"int" type:RLMTypeInt];
            {
                RLMDescriptor * subdesc = [desc addColumnTable:@"tab"];
                [subdesc addColumnWithName:@"int" type:RLMTypeInt];
            }
            [desc addColumnWithName:@"mix" type:RLMTypeMixed];
        }
        
        int COL_TABLE_INT = 0;
        int COL_TABLE_TAB = 1;
        int COL_TABLE_MIX = 2;
        int COL_SUBTABLE_INT = 0;
        
        // Add a row to the top level table
        [table addRow:nil];
        [table RLM_setInt:700 inColumnWithIndex:COL_TABLE_INT atRowIndex:0];
        
        // Add two rows to the subtable
        RLMTable* subtable = [table RLM_tableInColumnWithIndex:COL_TABLE_TAB atRowIndex:0];
        [subtable addRow:nil];
        
        [subtable RLM_setInt:800 inColumnWithIndex:COL_SUBTABLE_INT atRowIndex:0];
        [subtable addRow:nil];
        [subtable RLM_setInt:801 inColumnWithIndex:COL_SUBTABLE_INT atRowIndex:1];
        
        // Make the mixed values column contain another subtable
        RLMTable *subtable2 = [realm createTableWithName:@"subtable2"];
        [table RLM_setMixed:subtable2 inColumnWithIndex:COL_TABLE_MIX atRowIndex:0];
    }];
    
//    Fails!!!
//    // Specify its type
//    OCTopLevelTable* subtable2 = [table getTopLevelTable:COL_TABLE_MIX ndx:0];
//    {
//        RLMDescriptor* desc = [subtable2 getDescriptor];
//        [desc addColumnWithType:RLMTypeInt andName:@"int"];
//    }
//    // Add a row to it
//    [subtable2 addEmptyRow];
//    [subtable2 set:COL_SUBTABLE_INT ndx:0 value:900];
}

@end
