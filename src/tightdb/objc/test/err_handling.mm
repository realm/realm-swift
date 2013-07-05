//
//  err_handling.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import "TestHelper.h"

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>
#import <tightdb/objc/table.h>
#include <tightdb/binary_data.hpp>
#include <tightdb/table.hpp>
#import <tightdb/objc/table_priv.h>

TIGHTDB_TABLE_DEF_3(PeopleErrTable,
                    Name,  String,
                    Age,   Int,
                    Hired, Bool)

TIGHTDB_TABLE_IMPL_3(PeopleErrTable,
                     Name,  String,
                     Age,   Int,
                     Hired, Bool)

TIGHTDB_TABLE_1(TestQueryErrSub,
                Age,  Int)

TIGHTDB_TABLE_9(TestQueryErrAllTypes,
                BoolCol,   Bool,
                IntCol,    Int,
                FloatCol,  Float,
                DoubleCol, Double,
                StringCol, String,
                BinaryCol, Binary,
                DateCol,   Date,
                TableCol,  TestQueryErrSub,
                MixedCol,  Mixed)

@interface MACTestErrHandling: SenTestCase
@end
@implementation MACTestErrHandling

- (void)testErrHandling
{
    @autoreleasepool {
        NSError *error = nil;
        
        //------------------------------------------------------
        NSLog(@"--- Creating tables ---");
        //------------------------------------------------------
        
        TightdbGroup *group = [TightdbGroup group];
        // Create new table in group
        PeopleErrTable *people = [group getTable:@"employees" withClass:[PeopleErrTable class]];
        
        // Add some rows
        error = nil;
        if (![people addName:@"John" Age:20 Hired:YES error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"This should have worked");
        }
        error = nil;
        if (![people addName:@"Mary" Age:21 Hired:NO error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"This should have worked");
        }
        if (![people addName:@"Lars" Age:21 Hired:YES error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"This should have worked");
        }
        error = nil;
        if (![people addName:@"Phil" Age:43 Hired:NO error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"This should have worked");
        }
        error = nil;
        if (![people addName:@"Anni" Age:54 Hired:YES error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"This should have worked");
        }
        
        // Insert at specific position
        [people insertAtIndex:2 Name:@"Frank" Age:34 Hired:YES];
        
        // Getting the size of the table
        NSLog(@"PeopleErrTable Size: %lu - is %@.    [6 - not empty]", [people count],
              [people isEmpty] ? @"empty" : @"not empty");
        
        NSFileManager *fm = [NSFileManager defaultManager];
        
        // Write the group to disk
        [fm removeItemAtPath:@"peopleErr.tightdb" error:NULL];
        error = nil;
        if (![group write:@"peopleErr.tightdb" error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"No error expected");
        }
        
        //------------------------------------------------------
        NSLog(@"--- Changing permissions ---");
        //------------------------------------------------------
        
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
        [attributes setValue:[NSNumber numberWithShort:0444] forKey:NSFilePosixPermissions];
        
        error = nil;
        [fm setAttributes:attributes ofItemAtPath:@"peopleErr.tightdb" error:&error];
        if (error) {
            STFail(@"Failed to set readonly attributes");
        }
        
        //------------------------------------------------------
        NSLog(@"--- Reopen and manipulate ---");
        //------------------------------------------------------
        
        // Load a group from disk (and try to update, even though it is readonly)
        error = nil;
        TightdbGroup *fromDisk = [TightdbGroup groupWithFilename:@"peopleErr.tightdb" error:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        } else {
            STFail(@"Since file cannot be opened, we should have gotten an error here.");
        }
        
        //------------------------------------------------------
        NSLog(@"--- Make normal again ---");
        //------------------------------------------------------
        
        [attributes setValue:[NSNumber numberWithShort:0644] forKey:NSFilePosixPermissions];
        
        error = nil;
        [fm setAttributes:attributes ofItemAtPath:@"peopleErr.tightdb" error:&error];
        if (error) {
            STFail(@"Failed to set readonly attributes");
        }
        
        error = nil;
        fromDisk = [TightdbGroup groupWithFilename:@"peopleErr.tightdb" error:&error];
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"File should have been possible to open");
        }
        
        PeopleErrTable *diskTable = [fromDisk getTable:@"employees" withClass:[PeopleErrTable class]];
        
        // Fake readonly.
        [((TightdbTable *)diskTable) setReadOnly:true];
        
        NSLog(@"Disktable size: %zu", [diskTable count]);
        
        error = nil;
        if (![diskTable addName:@"Anni" Age:54 Hired:YES error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
        } else {
            STFail(@"addName to readonly should have failed.");
        }
        
        NSLog(@"Disktable size: %zu", [diskTable count]);
    }
    TEST_CHECK_ALLOC;
}

-(void)testErrorInsert
{
    @autoreleasepool {
        NSError *error;
        
        // Create table with all column types
        TightdbTable *table = [[TightdbTable alloc] init];
        TightdbSpec *s = [table getSpec];
        if (![s addColumn:tightdb_Int name:@"int" error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"addColumn failed.");
        }
        if (![s addColumn:tightdb_Bool name:@"bool" error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"addColumn failed.");
        }
        
        if (![s addColumn:tightdb_Date name:@"date" error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"addColumn failed.");
        }
        if (![s addColumn:tightdb_String name:@"string" error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"addColumn failed.");
        }
        if (![s addColumn:tightdb_String name:@"string_long" error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"addColumn failed.");
        }
        if (![s addColumn:tightdb_String name:@"string_enum" error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"addColumn failed.");
        }
        if (![s addColumn:tightdb_Binary name:@"binary" error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"addColumn failed.");
        }
        if (![s addColumn:tightdb_Mixed name:@"mixed" error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"addColumn failed.");
        }
        TightdbSpec *sub;
        if (!(sub = [s addColumnTable:@"tables" error:&error])) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"addColumn failed.");
        }
        if (![sub addColumn:tightdb_Int name:@"sub_first" error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"addColumn failed.");
        }
        if (![sub addColumn:tightdb_String name:@"sub_second" error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"addColumn failed.");
        }
        if (![table updateFromSpecWithError:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"UpdateFromSpec failed.");
        }
        
        // Add some rows
        for (size_t i = 0; i < 15; ++i) {
            if (![table insertInt:0 ndx:i value:i error:&error]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"Insert failed.");
            }
            if (![table insertBool:1 ndx:i value:(i % 2 ? YES : NO) error:&error]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"Insert failed.");
            }
            if (![table insertDate:2 ndx:i value:12345 error:&error]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"Insert failed.");
            }
            if (![table insertString:3 ndx:i value:[NSString stringWithFormat:@"string %zu", i] error:&error]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"Insert failed.");
            }
            if (![table insertString:4 ndx:i value:@" Very long string.............." error:&error]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"Insert failed.");
            }
            
            switch (i % 3) {
                case 0:
                    if (![table insertString:5 ndx:i value:@"test1" error:&error]) {
                        NSLog(@"%@", [error localizedDescription]);
                        STFail(@"Insert failed.");
                    }
                    break;
                case 1:
                    if (![table insertString:5 ndx:i value:@"test2" error:&error]) {
                        NSLog(@"%@", [error localizedDescription]);
                        STFail(@"Insert failed.");
                    }
                    break;
                case 2:
                    if (![table insertString:5 ndx:i value:@"test3" error:&error]) {
                        NSLog(@"%@", [error localizedDescription]);
                        STFail(@"Insert failed.");
                    }
                    break;
            }
            
            if (![table insertBinary:6 ndx:i data:"binary" size:7 error:&error]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"Insert failed.");
            }
            switch (i % 3) {
                case 0:
                    if (![table insertMixed:7 ndx:i value:[TightdbMixed mixedWithBool:NO] error:&error]) {
                        NSLog(@"%@", [error localizedDescription]);
                        STFail(@"Insert failed.");
                    }
                    break;
                case 1:
                    if (![table insertMixed:7 ndx:i value:[TightdbMixed mixedWithInt64:i] error:&error]) {
                        NSLog(@"%@", [error localizedDescription]);
                        STFail(@"Insert failed.");
                    }
                    break;
                case 2:
                    if (![table insertMixed:7 ndx:i value:[TightdbMixed mixedWithString:@"string"] error:&error]) {
                        NSLog(@"%@", [error localizedDescription]);
                        STFail(@"Insert failed.");
                    }
                    break;
            }
            if (![table insertSubtable:8 ndx:i error:&error]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"Insert failed.");
            }
            
            if (![table insertDoneWithError:&error]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"InsertDone failed.");
            }
            
            // Add sub-tables
            if (i == 2) {
                TightdbTable *subtable = [table getSubtable:8 ndx:i];
                if (![subtable insertInt:0 ndx:0 value:42 error:&error]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                if (![subtable insertString:1 ndx:0 value:@"meaning" error:&error]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                if (![subtable insertDoneWithError:&error]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"InsertDone failed.");
                }
            }
            
        }
        
        // We also want a ColumnStringEnum
        if (![table optimize]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        
        // Test Deletes
        if (![table remove:14 error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Remove failed.");
        }
        if (![table remove:0 error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Remove failed.");
        }
        if (![table remove:5 error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Remove failed.");
        }
        
        STAssertEquals([table count], (size_t)12, @"Size should have been 12");
#ifdef TIGHTDB_DEBUG
        [table verify];
#endif
        
        // Test Clear
        if (![table clearWithError:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Clear failed.");
        }
        STAssertEquals([table count], (size_t)0, @"Size should have been zero");
        
#ifdef TIGHTDB_DEBUG
        [table verify];
#endif
    }
    TEST_CHECK_ALLOC;
}


- (void)testQueryErrHandling
{
    @autoreleasepool {
        NSError *error;
        TestQueryErrAllTypes *table = [[TestQueryErrAllTypes alloc] init];
        NSLog(@"Table: %@", table);
        STAssertNotNil(table, @"Table is nil");
        
        const char bin[4] = { 0, 1, 2, 3 };
        TightdbBinary *bin1 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin / 2];
        TightdbBinary *bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];
        time_t timeNow = [[NSDate date] timeIntervalSince1970];
        //    TestQueryErrSub *subtab1 = [[TestQueryErrSub alloc] init];
        TestQueryErrSub *subtab2 = [[TestQueryErrSub alloc] init];
        if (![subtab2 insertRowAtIndex:0 error:&error, 50]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        [subtab2 addAge:100];
        STAssertEquals([subtab2 count], size_t(2), @"subtab2 should contain 2 rows");
        
        TightdbMixed *mixInt1   = [TightdbMixed mixedWithInt64:1];
        TightdbMixed *mixSubtab = [TightdbMixed mixedWithTable:subtab2];
        
        [table addBoolCol:NO   IntCol:54       FloatCol:0.7     DoubleCol:0.8       StringCol:@"foo"
                BinaryCol:bin1 DateCol:0       TableCol:nil     MixedCol:mixInt1];
        
        [table addBoolCol:YES  IntCol:506      FloatCol:7.7     DoubleCol:8.8       StringCol:@"banach"
                BinaryCol:bin2 DateCol:timeNow TableCol:subtab2 MixedCol:mixSubtab];
        
        STAssertEquals([[[[table where].BoolCol   equal:NO]      count] unsignedLongValue], (size_t)1, @"BoolCol equal");
        STAssertEquals([[[[table where].IntCol    equal:54]      count] unsignedLongValue], (size_t)1, @"IntCol equal");
        STAssertEquals([[[[table where].FloatCol  equal:0.7f]    count] unsignedLongValue], (size_t)1, @"FloatCol equal");
        STAssertEquals([[[[table where].DoubleCol equal:0.8]     count] unsignedLongValue], (size_t)1, @"DoubleCol equal");
        STAssertEquals([[[[table where].StringCol equal:@"foo"]  count] unsignedLongValue], (size_t)1, @"StringCol equal");
        STAssertEquals([[[[table where].BinaryCol equal:bin1]    count] unsignedLongValue], (size_t)1, @"BinaryCol equal");
        STAssertEquals([[[[table where].DateCol   equal:0]       count] unsignedLongValue], (size_t)1, @"DateCol equal");
        // These are not yet implemented
        //    STAssertEquals([[[table where].TableCol  equal:subtab1] count], (size_t)1, @"TableCol equal");
        //    STAssertEquals([[[table where].MixedCol  equal:mixInt1] count], (size_t)1, @"MixedCol equal");
        
        TestQueryErrAllTypes_Query *query = [[table where].BoolCol   equal:NO];
        
        STAssertEquals([[query.IntCol min] longLongValue], (int64_t)54,    @"IntCol min");
        STAssertEquals([[query.IntCol max] longLongValue], (int64_t)54,    @"IntCol max");
        STAssertEquals([[query.IntCol sum] longLongValue], (int64_t)54,    @"IntCol sum");
        STAssertEquals([[query.IntCol avg] doubleValue], 54.0,           @"IntCol avg");
        
        STAssertEquals([[query.FloatCol min] floatValue], 0.7f,         @"FloatCol min");
        STAssertEquals([[query.FloatCol max] floatValue], 0.7f,         @"FloatCol max");
        STAssertEquals([[query.FloatCol sum] floatValue], 0.7f, @"FloatCol sum");
        STAssertEquals([[query.FloatCol avg] doubleValue], (double)0.7f, @"FloatCol avg");
        
        STAssertEquals([[query.DoubleCol min] doubleValue], 0.8,         @"DoubleCol min");
        STAssertEquals([[query.DoubleCol max] doubleValue], 0.8,         @"DoubleCol max");
        STAssertEquals([[query.DoubleCol sum] doubleValue], 0.8,         @"DoubleCol sum");
        STAssertEquals([[query.DoubleCol avg] doubleValue], 0.8,         @"DoubleCol avg");
        
        // Check that all column conditions return query objects of the
        // right type
        [[[table where].BoolCol equal:NO].BoolCol equal:NO];
        
        [[[table where].IntCol equal:0].BoolCol equal:NO];
        [[[table where].IntCol notEqual:0].BoolCol equal:NO];
        [[[table where].IntCol less:0].BoolCol equal:NO];
        [[[table where].IntCol lessEqual:0].BoolCol equal:NO];
        [[[table where].IntCol greater:0].BoolCol equal:NO];
        [[[table where].IntCol greaterEqual:0].BoolCol equal:NO];
        [[[table where].IntCol between:0 to:0].BoolCol equal:NO];
        
        [[[table where].FloatCol equal:0].BoolCol equal:NO];
        [[[table where].FloatCol notEqual:0].BoolCol equal:NO];
        [[[table where].FloatCol less:0].BoolCol equal:NO];
        [[[table where].FloatCol lessEqual:0].BoolCol equal:NO];
        [[[table where].FloatCol greater:0].BoolCol equal:NO];
        [[[table where].FloatCol greaterEqual:0].BoolCol equal:NO];
        [[[table where].FloatCol between:0 to:0].BoolCol equal:NO];
        
        [[[table where].DoubleCol equal:0].BoolCol equal:NO];
        [[[table where].DoubleCol notEqual:0].BoolCol equal:NO];
        [[[table where].DoubleCol less:0].BoolCol equal:NO];
        [[[table where].DoubleCol lessEqual:0].BoolCol equal:NO];
        [[[table where].DoubleCol greater:0].BoolCol equal:NO];
        [[[table where].DoubleCol greaterEqual:0].BoolCol equal:NO];
        [[[table where].DoubleCol between:0 to:0].BoolCol equal:NO];
        
        [[[table where].StringCol equal:@""].BoolCol equal:NO];
        [[[table where].StringCol equal:@"" caseSensitive:NO].BoolCol equal:NO];
        [[[table where].StringCol notEqual:@""].BoolCol equal:NO];
        [[[table where].StringCol notEqual:@"" caseSensitive:NO].BoolCol equal:NO];
        [[[table where].StringCol beginsWith:@""].BoolCol equal:NO];
        [[[table where].StringCol beginsWith:@"" caseSensitive:NO].BoolCol equal:NO];
        [[[table where].StringCol endsWith:@""].BoolCol equal:NO];
        [[[table where].StringCol endsWith:@"" caseSensitive:NO].BoolCol equal:NO];
        [[[table where].StringCol contains:@""].BoolCol equal:NO];
        [[[table where].StringCol contains:@"" caseSensitive:NO].BoolCol equal:NO];
        
        [[[table where].BinaryCol equal:bin1].BoolCol equal:NO];
        [[[table where].BinaryCol notEqual:bin1].BoolCol equal:NO];
        [[[table where].BinaryCol beginsWith:bin1].BoolCol equal:NO];
        [[[table where].BinaryCol endsWith:bin1].BoolCol equal:NO];
        [[[table where].BinaryCol contains:bin1].BoolCol equal:NO];
        
        TestQueryErrAllTypes_View *view = [[[[table where].DateCol equal:0].BoolCol equal:NO] findAll];
        for (size_t i = 0; i < [view count]; i++) {
            NSLog(@"%zu: %c", i, [[view objectAtIndex:i] BoolCol]);
        }
        
        
        [[[table where].DateCol notEqual:0].BoolCol equal:NO];
        [[[table where].DateCol less:0].BoolCol equal:NO];
        [[[table where].DateCol lessEqual:0].BoolCol equal:NO];
        [[[table where].DateCol greater:0].BoolCol equal:NO];
        [[[table where].DateCol greaterEqual:0].BoolCol equal:NO];
        [[[table where].DateCol between:0 to:0].BoolCol equal:NO];
        
        // These are not yet implemented
        //    [[[table where].TableCol equal:nil].BoolCol equal:NO];
        //    [[[table where].TableCol notEqual:nil].BoolCol equal:NO];
        
        //    [[[table where].MixedCol equal:mixInt1].BoolCol equal:NO];
        //    [[[table where].MixedCol notEqual:mixInt1].BoolCol equal:NO];
    }
    TEST_CHECK_ALLOC;
}



@end
