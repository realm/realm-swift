


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
#import <tightdb/objc/TDBTable_noinst.h>

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
    if (![transaction writeContextToFile:@"peopleErr.tightdb" error:&error]) {
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
    TDBTransaction* fromDisk = [TDBTransaction groupWithFile:@"peopleErr.tightdb" error:&error];
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
    fromDisk = [TDBTransaction groupWithFile:@"peopleErr.tightdb" error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"File should have been possible to open");
    }

    PeopleErrTable* diskTable = [fromDisk tableWithName:@"employees" asTableClass:[PeopleErrTable class]];

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


    // Create table with all column types
    TDBTable* table = [[TDBTable alloc] init];
    TDBDescriptor* desc = [table descriptor];
    if (![desc addColumnWithName:@"int" type:TDBIntType]) {
        STFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"bool" type:TDBBoolType]) {
        STFail(@"addColumn failed.");
    }

    if (![desc addColumnWithName:@"date" type:TDBDateType]) {
        STFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"string" type:TDBStringType]) {
        STFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"string_long" type:TDBStringType]) {
        STFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"string_enum" type:TDBStringType]) {
        STFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"binary" type:TDBBinaryType]) {
        STFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"mixed" type:TDBMixedType]) {
        STFail(@"addColumn failed.");
    }
    TDBDescriptor* subdesc;
    if (!(subdesc = [desc addColumnTable:@"tables"])) {
        STFail(@"addColumn failed.");
    }
    if (![subdesc addColumnWithName:@"sub_first" type:TDBIntType]) {
        STFail(@"addColumn failed.");
    }
    if (![subdesc addColumnWithName:@"sub_second" type:TDBStringType]) {
        STFail(@"addColumn failed.");
    }

    // Add some rows
    for (size_t i = 0; i < 15; ++i) {
        if (![table TDB_insertInt:0 ndx:i value:i ]) {
           // NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        if (![table TDB_insertBool:1 ndx:i value:(i % 2 ? YES : NO)  ]) {
            STFail(@"Insert failed.");
        }
        if (![table TDB_insertDate:2 ndx:i value:[NSDate date] ]) {
            STFail(@"Insert failed.");
        }
        if (![table TDB_insertString:3 ndx:i value:[NSString stringWithFormat:@"string %zu", i] ]) {
            STFail(@"Insert failed.");
        }
        if (![table TDB_insertString:4 ndx:i value:@" Very long string.............."  ]) {
            STFail(@"Insert failed.");
        }

        switch (i % 3) {
            case 0:
                if (![table TDB_insertString:5 ndx:i value:@"test1" ]) {
                    STFail(@"Insert failed.");
                }
                break;
            case 1:
                if (![table TDB_insertString:5 ndx:i value:@"test2" ]) {
                    STFail(@"Insert failed.");
                }
                break;
            case 2:
                if (![table TDB_insertString:5 ndx:i value:@"test3" ]) {
                    STFail(@"Insert failed.");
                }
                break;
        }

        if (![table TDB_insertBinary:6 ndx:i data:"binary" size:7 ]) {
            STFail(@"Insert failed.");
        }
        switch (i % 3) {
            case 0:
               if (![table TDB_insertMixed:7 ndx:i value:[NSNumber numberWithBool:NO] ]) {
                    STFail(@"Insert failed.");
                }
                break;
            case 1:
                if (![table TDB_insertMixed:7 ndx:i value:[NSNumber numberWithLongLong:i] ]) {
                    STFail(@"Insert failed.");
                }
                break;
            case 2:
                if (![table TDB_insertMixed:7 ndx:i value:[NSString stringWithUTF8String:"string"] ]) {
                    STFail(@"Insert failed.");
                }
                break;
        }
        if (![table TDB_insertSubtable:8 ndx:i ]) {
            STFail(@"Insert failed.");
        }

        if (![table TDB_insertDone ]) {
            STFail(@"InsertDone failed.");
        }

        // Add sub-tables
        if (i == 2) {
            TDBTable* subtable = [table TDB_tableInColumnWithIndex:8 atRowIndex:i];
            if (![subtable TDB_insertInt:0 ndx:0 value:42 ]) {
                STFail(@"Insert failed.");
            }
            if (![subtable TDB_insertString:1 ndx:0 value:@"meaning" ]) {
                STFail(@"Insert failed.");
            }
            if (![subtable TDB_insertDone ]) {
                STFail(@"InsertDone failed.");
            }
        }


    }

    // We also want a ColumnStringEnum
    if (![table optimize]) {
        STFail(@"Insert failed.");
    }

    // Test Deletes
    if (![table removeRowAtIndex:14 ]) {
        STFail(@"Remove failed.");
    }
    if (![table removeRowAtIndex:0 ]) {
        STFail(@"Remove failed.");
    }
    if (![table removeRowAtIndex:5 ]) {
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
    NSNumber* mixInt1   = [NSNumber numberWithLongLong:1];
//    TDBMixed* mixSubtab = [TDBMixed mixedWithTable:subtab2];

    [table addBoolCol:NO   IntCol:54       FloatCol:0.7     DoubleCol:0.8       StringCol:@"foo"
            BinaryCol:bin1 DateCol:0       TableCol:nil     MixedCol:mixInt1];

    [table addBoolCol:YES  IntCol:506      FloatCol:7.7     DoubleCol:8.8       StringCol:@"banach"
            BinaryCol:bin2 DateCol:timeNow TableCol:subtab2 MixedCol:subtab2];

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


