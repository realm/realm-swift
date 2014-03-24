


//
//  err_handling.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//


#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/Tightdb.h>
#import <tightdb/objc/group.h>

#include <tightdb/binary_data.hpp>
#include <tightdb/table.hpp>
#import <tightdb/objc/TDBTable_priv.h>

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
    NSError* error = nil;

    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
    //------------------------------------------------------

    TDBTransaction* transaction = [TDBTransaction group];
    // Create new table in group
    PeopleErrTable* people = [transaction createTableWithName:@"employees" asTableClass:[PeopleErrTable class]];

    // No longer supports errors, the tes may be redundant
    // Add some rows

    [people addName:@"John" Age:20 Hired:YES];
    [people addName:@"Mary" Age:21 Hired:NO];
    [people addName:@"Lars" Age:21 Hired:YES];
    [people addName:@"Phil" Age:43 Hired:NO];
    [people addName:@"Anni" Age:54 Hired:YES];



    // Insert at specific position
    [people insertEmptyRowAtIndex:2 Name:@"Frank" Age:34 Hired:YES];

    // Getting the size of the table
    NSLog(@"PeopleErrTable Size: %lu - is %@.    [6 - not empty]", [people rowCount],
        people.rowCount == 0 ? @"empty" : @"not empty");

    NSFileManager* fm = [NSFileManager defaultManager];

    // Write the group to disk
    [fm removeItemAtPath:@"peopleErr.tightdb" error:NULL];
    error = nil;
    if (![transaction writeContextToFile:@"peopleErr.tightdb" withError:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"No error expected");
    }

    //------------------------------------------------------
    NSLog(@"--- Changing permissions ---");
    //------------------------------------------------------

    NSMutableDictionary* attributes = [NSMutableDictionary dictionaryWithCapacity:1];
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
    TDBTransaction* fromDisk = [TDBTransaction groupWithFile:@"peopleErr.tightdb" withError:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    else {
        // This is no longer an error, becuase read/write mode is no longer required per default.
        // STFail(@"Since file cannot be opened, we should have gotten an error here.");
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
    fromDisk = [TDBTransaction groupWithFile:@"peopleErr.tightdb" withError:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"File should have been possible to open");
    }

    PeopleErrTable* diskTable = [fromDisk getTableWithName:@"employees" asTableClass:[PeopleErrTable class]];

    // Fake readonly.
    [((TDBTable*)diskTable) setReadOnly:true];

    NSLog(@"Disktable size: %zu", [diskTable rowCount]);

    /* No longer support for errors here
    error = nil;
    if (![diskTable addName:@"Anni" Age:54 Hired:YES error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        STFail(@"addName to readonly should have failed.");
    }*/

    NSLog(@"Disktable size: %zu", [diskTable rowCount]);
}




-(void)testErrorInsert
{

    NSError* error;

    // Create table with all column types
    TDBTable* table = [[TDBTable alloc] init];
    TDBDescriptor* desc = [table descriptor];
    if (![desc addColumnWithName:@"int" andType:TDBIntType error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"bool" andType:TDBBoolType error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }

    if (![desc addColumnWithName:@"date" andType:TDBDateType error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"string" andType:TDBStringType error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"string_long" andType:TDBStringType error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"string_enum" andType:TDBStringType error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"binary" andType:TDBBinaryType error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"mixed" andType:TDBMixedType error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    TDBDescriptor* subdesc;
    if (!(subdesc = [desc addColumnTable:@"tables" error:&error])) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![subdesc addColumnWithName:@"sub_first" andType:TDBIntType error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![subdesc addColumnWithName:@"sub_second" andType:TDBStringType error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }

    // Add some rows
    for (size_t i = 0; i < 15; ++i) {
        if (![table TDBInsertInt:0 ndx:i value:i ]) {
           // NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        if (![table TDBInsertBool:1 ndx:i value:(i % 2 ? YES : NO)  ]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        if (![table TDBInsertDate:2 ndx:i value:[NSDate date] ]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        if (![table TDBInsertString:3 ndx:i value:[NSString stringWithFormat:@"string %zu", i] ]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        if (![table TDBInsertString:4 ndx:i value:@" Very long string.............."  ]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }

        switch (i % 3) {
            case 0:
                if (![table TDBInsertString:5 ndx:i value:@"test1" ]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                break;
            case 1:
                if (![table TDBInsertString:5 ndx:i value:@"test2" ]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                break;
            case 2:
                if (![table TDBInsertString:5 ndx:i value:@"test3" ]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                break;
        }

        if (![table TDBInsertBinary:6 ndx:i data:"binary" size:7 ]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        switch (i % 3) {
            case 0:
                if (![table TDBInsertMixed:7 ndx:i value:[TDBMixed mixedWithBool:NO] ]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                break;
            case 1:
                if (![table TDBInsertMixed:7 ndx:i value:[TDBMixed mixedWithInt64:i] ]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                break;
            case 2:
                if (![table TDBInsertMixed:7 ndx:i value:[TDBMixed mixedWithString:@"string"] ]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                break;
        }
        if (![table TDBInsertSubtable:8 ndx:i ]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }

        if (![table TDBInsertDone ]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"InsertDone failed.");
        }

        // Add sub-tables
        if (i == 2) {
            TDBTable* subtable = [table tableInColumnWithIndex:8 atRowIndex:i];
            if (![subtable TDBInsertInt:0 ndx:0 value:42 ]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"Insert failed.");
            }
            if (![subtable TDBInsertString:1 ndx:0 value:@"meaning" ]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"Insert failed.");
            }
            if (![subtable TDBInsertDone ]) {
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
    if (![table removeRowAtIndex:14 ]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"Remove failed.");
    }
    if (![table removeRowAtIndex:0 ]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"Remove failed.");
    }
    if (![table removeRowAtIndex:5 ]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"Remove failed.");
    }

    STAssertEquals([table rowCount], (size_t)12, @"Size should have been 12");

    // Test Clear
    if (![table removeAllRows]) {
        STFail(@"Clear failed.");
    }
    STAssertEquals([table rowCount], (size_t)0, @"Size should have been zero");

}


- (void)testQueryErrHandling
{
    TestQueryErrAllTypes* table = [[TestQueryErrAllTypes alloc] init];
    NSLog(@"Table: %@", table);
    STAssertNotNil(table, @"Table is nil");

    const char bin[4] = { 0, 1, 2, 3 };
    NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
    NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
    NSDate *timeNow = [NSDate date];
    //    TestQueryErrSub* subtab1 = [[TestQueryErrSub alloc] init];
    TestQueryErrSub* subtab2 = [[TestQueryErrSub alloc] init];
    [subtab2 addAge:100];
    TDBMixed* mixInt1   = [TDBMixed mixedWithInt64:1];
    TDBMixed* mixSubtab = [TDBMixed mixedWithTable:subtab2];

    [table addBoolCol:NO   IntCol:54       FloatCol:0.7     DoubleCol:0.8       StringCol:@"foo"
            BinaryCol:bin1 DateCol:0       TableCol:nil     MixedCol:mixInt1];

    [table addBoolCol:YES  IntCol:506      FloatCol:7.7     DoubleCol:8.8       StringCol:@"banach"
            BinaryCol:bin2 DateCol:timeNow TableCol:subtab2 MixedCol:mixSubtab];

    STAssertEquals([[[table where].BoolCol   columnIsEqualTo:NO]      countRows], (size_t)1, @"BoolCol equal");
    STAssertEquals([[[table where].IntCol    columnIsEqualTo:54]      countRows], (size_t)1, @"IntCol equal");
    STAssertEquals([[[table where].FloatCol  columnIsEqualTo:0.7f]    countRows], (size_t)1, @"FloatCol equal");
    STAssertEquals([[[table where].DoubleCol columnIsEqualTo:0.8]     countRows], (size_t)1, @"DoubleCol equal");
    STAssertEquals([[[table where].StringCol columnIsEqualTo:@"foo"]  countRows], (size_t)1, @"StringCol equal");
    STAssertEquals([[[table where].BinaryCol columnIsEqualTo:bin1]    countRows], (size_t)1, @"BinaryCol equal");
    STAssertEquals([[[table where].DateCol   columnIsEqualTo:0]       countRows], (size_t)1, @"DateCol equal");
    // These are not yet implemented
    //    STAssertEquals([[[table where].TableCol  columnIsEqualTo:subtab1] count], (size_t)1, @"TableCol equal");
    //    STAssertEquals([[[table where].MixedCol  columnIsEqualTo:mixInt1] count], (size_t)1, @"MixedCol equal");

    TestQueryErrAllTypesQuery* query = [[table where].BoolCol   columnIsEqualTo:NO];

    STAssertEquals([query.IntCol min] , (int64_t)54,    @"IntCol min");
    STAssertEquals([query.IntCol max], (int64_t)54,    @"IntCol max");
    STAssertEquals([query.IntCol sum] , (int64_t)54,    @"IntCol sum");
    STAssertEquals([query.IntCol avg] , 54.0,           @"IntCol avg");

    STAssertEquals([query.FloatCol min], 0.7f,         @"FloatCol min");
    STAssertEquals([query.FloatCol max], 0.7f,         @"FloatCol max");
    STAssertEquals([query.FloatCol sum], (double)0.7f, @"FloatCol sum");
    STAssertEquals([query.FloatCol avg], (double)0.7f, @"FloatCol avg");

    STAssertEquals([query.DoubleCol min], 0.8,         @"DoubleCol min");
    STAssertEquals([query.DoubleCol max], 0.8,         @"DoubleCol max");
    STAssertEquals([query.DoubleCol sum] , 0.8,         @"DoubleCol sum");
    STAssertEquals([query.DoubleCol avg], 0.8,         @"DoubleCol avg");

    // Check that all column conditions return query objects of the
    // right type
    [[[table where].BoolCol columnIsEqualTo:NO].BoolCol columnIsEqualTo:NO];

    [[[table where].IntCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsBetween:0 and_:0].BoolCol columnIsEqualTo:NO];

    [[[table where].FloatCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsBetween:0 and_:0].BoolCol columnIsEqualTo:NO];

    [[[table where].DoubleCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsBetween:0 and_:0].BoolCol columnIsEqualTo:NO];

    [[[table where].StringCol columnIsEqualTo:@""].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnIsEqualTo:@"" caseSensitive:NO].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnIsNotEqualTo:@""].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnIsNotEqualTo:@"" caseSensitive:NO].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnBeginsWith:@""].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnBeginsWith:@"" caseSensitive:NO].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnEndsWith:@""].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnEndsWith:@"" caseSensitive:NO].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnContains:@""].BoolCol columnIsEqualTo:NO];
    [[[table where].StringCol columnContains:@"" caseSensitive:NO].BoolCol columnIsEqualTo:NO];

    [[[table where].BinaryCol columnIsEqualTo:bin1].BoolCol columnIsEqualTo:NO];
    [[[table where].BinaryCol columnIsNotEqualTo:bin1].BoolCol columnIsEqualTo:NO];
    [[[table where].BinaryCol columnBeginsWith:bin1].BoolCol columnIsEqualTo:NO];
    [[[table where].BinaryCol columnEndsWith:bin1].BoolCol columnIsEqualTo:NO];
    [[[table where].BinaryCol columnContains:bin1].BoolCol columnIsEqualTo:NO];

    TestQueryErrAllTypesView* view = [[[[table where].DateCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO] findAll];
    for (size_t i = 0; i < [view rowCount]; i++) {
        NSLog(@"%zu: %c", i, [[view rowAtIndex:i] BoolCol]);
    }


    [[[table where].DateCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsBetween:0 and_:0].BoolCol columnIsEqualTo:NO];

    // These are not yet implemented
    //    [[[table where].TableCol columnIsEqualTo:nil].BoolCol columnIsEqualTo:NO];
    //    [[[table where].TableCol columnIsNotEqualTo:nil].BoolCol columnIsEqualTo:NO];

    //    [[[table where].MixedCol columnIsEqualTo:mixInt1].BoolCol columnIsEqualTo:NO];
    //    [[[table where].MixedCol columnIsNotEqualTo:mixInt1].BoolCol columnIsEqualTo:NO];
}



@end


