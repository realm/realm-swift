


//
//  err_handling.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//


#import <SenTestingKit/SenTestingKit.h>

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




-(void)testErrorInsert
{

    NSError *error;

    // Create table with all column types
    TightdbTable *table = [[TightdbTable alloc] init];
    TightdbSpec *s = [table getSpec];
    if (![s addColumnWithType:tightdb_Int andName:@"int" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![s addColumnWithType:tightdb_Bool andName:@"bool" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }

    if (![s addColumnWithType:tightdb_Date andName:@"date" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![s addColumnWithType:tightdb_String andName:@"string" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![s addColumnWithType:tightdb_String andName:@"string_long" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![s addColumnWithType:tightdb_String andName:@"string_enum" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![s addColumnWithType:tightdb_Binary andName:@"binary" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![s addColumnWithType:tightdb_Mixed andName:@"mixed" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    TightdbSpec *sub;
    if (!(sub = [s addColumnTable:@"tables" error:&error])) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![sub addColumnWithType:tightdb_Int andName:@"sub_first" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![sub addColumnWithType:tightdb_String andName:@"sub_second" error:&error]) {
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
    if (![table removeRowAtIndex:14 error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"Remove failed.");
    }
    if (![table removeRowAtIndex:0 error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"Remove failed.");
    }
    if (![table removeRowAtIndex:5 error:&error]) {
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


- (void)testQueryErrHandling
{
    TestQueryErrAllTypes *table = [[TestQueryErrAllTypes alloc] init];
    NSLog(@"Table: %@", table);
    STAssertNotNil(table, @"Table is nil");

    const char bin[4] = { 0, 1, 2, 3 };
    TightdbBinary *bin1 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin / 2];
    TightdbBinary *bin2 = [[TightdbBinary alloc] initWithData:bin size:sizeof bin];
    time_t timeNow = [[NSDate date] timeIntervalSince1970];
    //    TestQueryErrSub *subtab1 = [[TestQueryErrSub alloc] init];
    TestQueryErrSub *subtab2 = [[TestQueryErrSub alloc] init];
    [subtab2 addAge:100];
    TightdbMixed *mixInt1   = [TightdbMixed mixedWithInt64:1];
    TightdbMixed *mixSubtab = [TightdbMixed mixedWithTable:subtab2];

    [table addBoolCol:NO   IntCol:54       FloatCol:0.7     DoubleCol:0.8       StringCol:@"foo"
            BinaryCol:bin1 DateCol:0       TableCol:nil     MixedCol:mixInt1];

    [table addBoolCol:YES  IntCol:506      FloatCol:7.7     DoubleCol:8.8       StringCol:@"banach"
            BinaryCol:bin2 DateCol:timeNow TableCol:subtab2 MixedCol:mixSubtab];

    STAssertEquals([[[[table where].BoolCol   columnIsEqualTo:NO]      count] unsignedLongValue], (size_t)1, @"BoolCol equal");
    STAssertEquals([[[[table where].IntCol    columnIsEqualTo:54]      count] unsignedLongValue], (size_t)1, @"IntCol equal");
    STAssertEquals([[[[table where].FloatCol  columnIsEqualTo:0.7f]    count] unsignedLongValue], (size_t)1, @"FloatCol equal");
    STAssertEquals([[[[table where].DoubleCol columnIsEqualTo:0.8]     count] unsignedLongValue], (size_t)1, @"DoubleCol equal");
    STAssertEquals([[[[table where].StringCol columnIsEqualTo:@"foo"]  count] unsignedLongValue], (size_t)1, @"StringCol equal");
    STAssertEquals([[[[table where].BinaryCol columnIsEqualTo:bin1]    count] unsignedLongValue], (size_t)1, @"BinaryCol equal");
    STAssertEquals([[[[table where].DateCol   columnIsEqualTo:0]       count] unsignedLongValue], (size_t)1, @"DateCol equal");
    // These are not yet implemented
    //    STAssertEquals([[[table where].TableCol  columnIsEqualTo:subtab1] count], (size_t)1, @"TableCol equal");
    //    STAssertEquals([[[table where].MixedCol  columnIsEqualTo:mixInt1] count], (size_t)1, @"MixedCol equal");

    TestQueryErrAllTypes_Query *query = [[table where].BoolCol   columnIsEqualTo:NO];

    STAssertEquals([[query.IntCol minimum] longLongValue], (int64_t)54,    @"IntCol min");
    STAssertEquals([[query.IntCol maximum] longLongValue], (int64_t)54,    @"IntCol max");
    STAssertEquals([[query.IntCol sum] longLongValue], (int64_t)54,    @"IntCol sum");
    STAssertEquals([[query.IntCol average] doubleValue], 54.0,           @"IntCol avg");

    STAssertEquals([[query.FloatCol minimum] floatValue], 0.7f,         @"FloatCol min");
    STAssertEquals([[query.FloatCol maximum] floatValue], 0.7f,         @"FloatCol max");
    STAssertEquals([[query.FloatCol sum] floatValue], 0.7f, @"FloatCol sum");
    STAssertEquals([[query.FloatCol average] doubleValue], (double)0.7f, @"FloatCol avg");

    STAssertEquals([[query.DoubleCol minimum] doubleValue], 0.8,         @"DoubleCol min");
    STAssertEquals([[query.DoubleCol maximum] doubleValue], 0.8,         @"DoubleCol max");
    STAssertEquals([[query.DoubleCol sum] doubleValue], 0.8,         @"DoubleCol sum");
    STAssertEquals([[query.DoubleCol average] doubleValue], 0.8,         @"DoubleCol avg");

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

    TestQueryErrAllTypes_View *view = [[[[table where].DateCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO] findAll];
    for (size_t i = 0; i < [view count]; i++) {
        NSLog(@"%zu: %c", i, [[view cursorAtIndex:i] BoolCol]);
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


