


//
//  err_handling.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//


#import <XCTest/XCTest.h>

#import <realm/objc/Realm.h>
#import <realm/objc/group.h>

#include <tightdb/binary_data.hpp>
#include <tightdb/table.hpp>
#import <realm/objc/RLMTable_noinst.h>
#import <realm/objc/RLMTableFast.h>

REALM_TABLE_DEF_3(PeopleErrTable,
                    Name,  String,
                    Age,   Int,
                    Hired, Bool)

REALM_TABLE_IMPL_3(PeopleErrTable,
                     Name,  String,
                     Age,   Int,
                     Hired, Bool)

REALM_TABLE_1(TestQueryErrSub,
                Age,  Int)

REALM_TABLE_9(TestQueryErrAllTypes,
                BoolCol,   Bool,
                IntCol,    Int,
                FloatCol,  Float,
                DoubleCol, Double,
                StringCol, String,
                BinaryCol, Binary,
                DateCol,   Date,
                TableCol,  TestQueryErrSub,
                MixedCol,  Mixed)



@interface MACTestErrHandling: XCTestCase
@end
@implementation MACTestErrHandling





- (void)testErrHandling
{
    NSError* error = nil;

    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
    //------------------------------------------------------

    RLMTransaction * transaction = [RLMTransaction group];
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
    [fm removeItemAtPath:@"peopleErr.realm" error:NULL];
    error = nil;
    if (![transaction writeContextToFile:@"peopleErr.realm" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        XCTFail(@"No error expected");
    }

    //------------------------------------------------------
    NSLog(@"--- Changing permissions ---");
    //------------------------------------------------------

    NSMutableDictionary* attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setValue:[NSNumber numberWithShort:0444] forKey:NSFilePosixPermissions];

    error = nil;
    [fm setAttributes:attributes ofItemAtPath:@"peopleErr.realm" error:&error];
    if (error) {
        XCTFail(@"Failed to set readonly attributes");
    }

    //------------------------------------------------------
    NSLog(@"--- Reopen and manipulate ---");
    //------------------------------------------------------

    // Load a group from disk (and try to update, even though it is readonly)
    error = nil;
    RLMTransaction * fromDisk = [RLMTransaction groupWithFile:@"peopleErr.realm" error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    else {
        // This is no longer an error, becuase read/write mode is no longer required per default.
        // XCTFail(@"Since file cannot be opened, we should have gotten an error here.");
    }

    //------------------------------------------------------
    NSLog(@"--- Make normal again ---");
    //------------------------------------------------------

    [attributes setValue:[NSNumber numberWithShort:0644] forKey:NSFilePosixPermissions];

    error = nil;
    [fm setAttributes:attributes ofItemAtPath:@"peopleErr.realm" error:&error];
    if (error) {
        XCTFail(@"Failed to set readonly attributes");
    }

    error = nil;
    fromDisk = [RLMTransaction groupWithFile:@"peopleErr.realm" error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        XCTFail(@"File should have been possible to open");
    }

    PeopleErrTable* diskTable = [fromDisk tableWithName:@"employees" asTableClass:[PeopleErrTable class]];

    // Fake readonly.
    [((RLMTable*)diskTable) setReadOnly:true];

    NSLog(@"Disktable size: %zu", [diskTable rowCount]);

    /* No longer support for errors here
    error = nil;
    if (![diskTable addName:@"Anni" Age:54 Hired:YES error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        XCTFail(@"addName to readonly should have failed.");
    }*/

    NSLog(@"Disktable size: %zu", [diskTable rowCount]);
}




-(void)testErrorInsert
{


    // Create table with all column types
    RLMTable* table = [[RLMTable alloc] init];
    RLMDescriptor * desc = [table descriptor];
    if (![desc addColumnWithName:@"int" type:RLMTypeInt]) {
        XCTFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"bool" type:RLMTypeBool]) {
        XCTFail(@"addColumn failed.");
    }

    if (![desc addColumnWithName:@"date" type:RLMTypeDate]) {
        XCTFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"string" type:RLMTypeString]) {
        XCTFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"string_long" type:RLMTypeString]) {
        XCTFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"string_enum" type:RLMTypeString]) {
        XCTFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"binary" type:RLMTypeBinary]) {
        XCTFail(@"addColumn failed.");
    }
    if (![desc addColumnWithName:@"mixed" type:RLMTypeMixed]) {
        XCTFail(@"addColumn failed.");
    }
    RLMDescriptor * subdesc;
    if (!(subdesc = [desc addColumnTable:@"tables"])) {
        XCTFail(@"addColumn failed.");
    }
    if (![subdesc addColumnWithName:@"sub_first" type:RLMTypeInt]) {
        XCTFail(@"addColumn failed.");
    }
    if (![subdesc addColumnWithName:@"sub_second" type:RLMTypeString]) {
        XCTFail(@"addColumn failed.");
    }

    // Add some rows
    for (size_t i = 0; i < 15; ++i) {
        if (![table RLM_insertInt:0 ndx:i value:i]) {
           // NSLog(@"%@", [error localizedDescription]);
            XCTFail(@"Insert failed.");
        }
        if (![table RLM_insertBool:1 ndx:i value:(i % 2 ? YES : NO)]) {
            XCTFail(@"Insert failed.");
        }
        if (![table RLM_insertDate:2 ndx:i value:[NSDate date]]) {
            XCTFail(@"Insert failed.");
        }
        if (![table RLM_insertString:3 ndx:i value:[NSString stringWithFormat:@"string %zu", i]]) {
            XCTFail(@"Insert failed.");
        }
        if (![table RLM_insertString:4 ndx:i value:@" Very long string.............."]) {
            XCTFail(@"Insert failed.");
        }

        switch (i % 3) {
            case 0:
                if (![table RLM_insertString:5 ndx:i value:@"test1"]) {
                    XCTFail(@"Insert failed.");
                }
                break;
            case 1:
                if (![table RLM_insertString:5 ndx:i value:@"test2"]) {
                    XCTFail(@"Insert failed.");
                }
                break;
            case 2:
                if (![table RLM_insertString:5 ndx:i value:@"test3"]) {
                    XCTFail(@"Insert failed.");
                }
                break;
        }

        if (![table RLM_insertBinary:6 ndx:i data:"binary" size:7]) {
            XCTFail(@"Insert failed.");
        }
        switch (i % 3) {
            case 0:
               if (![table RLM_insertMixed:7 ndx:i value:[NSNumber numberWithBool:NO] ]) {
                    XCTFail(@"Insert failed.");
                }
                break;
            case 1:
                if (![table RLM_insertMixed:7 ndx:i value:[NSNumber numberWithLongLong:i] ]) {
                    XCTFail(@"Insert failed.");
                }
                break;
            case 2:
                if (![table RLM_insertMixed:7 ndx:i value:[NSString stringWithUTF8String:"string"] ]) {
                    XCTFail(@"Insert failed.");
                }
                break;
        }
        if (![table RLM_insertSubtable:8 ndx:i]) {
            XCTFail(@"Insert failed.");
        }

        if (![table RLM_insertDone ]) {
            XCTFail(@"InsertDone failed.");
        }

        // Add sub-tables
        if (i == 2) {
            RLMTable* subtable = [table RLM_tableInColumnWithIndex:8 atRowIndex:i];
            if (![subtable RLM_insertInt:0 ndx:0 value:42]) {
                XCTFail(@"Insert failed.");
            }
            if (![subtable RLM_insertString:1 ndx:0 value:@"meaning"]) {
                XCTFail(@"Insert failed.");
            }
            if (![subtable RLM_insertDone ]) {
                XCTFail(@"InsertDone failed.");
            }
        }


    }

    // We also want a ColumnStringEnum
    if (![table optimize]) {
        XCTFail(@"Insert failed.");
    }

    // Test Deletes
    XCTAssertNoThrow([table removeRowAtIndex:14]);
    XCTAssertNoThrow([table removeRowAtIndex:0]);
    XCTAssertNoThrow([table removeRowAtIndex:5]);

    XCTAssertEqual(table.rowCount, (NSUInteger)12, @"Size should have been 12");

    // Test Clear
    XCTAssertNoThrow([table removeAllRows]);
    XCTAssertEqual(table.rowCount, (NSUInteger)0, @"Size should have been zero");

}


- (void)testQueryErrHandling
{
    TestQueryErrAllTypes* table = [[TestQueryErrAllTypes alloc] init];
    NSLog(@"Table: %@", table);
    XCTAssertNotNil(table, @"Table is nil");

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

    XCTAssertEqual([[[table where].BoolCol   columnIsEqualTo:NO]      countRows], (size_t)1, @"BoolCol equal");
    XCTAssertEqual([[[table where].IntCol    columnIsEqualTo:54]      countRows], (size_t)1, @"IntCol equal");
    XCTAssertEqual([[[table where].FloatCol  columnIsEqualTo:0.7f]    countRows], (size_t)1, @"FloatCol equal");
    XCTAssertEqual([[[table where].DoubleCol columnIsEqualTo:0.8]     countRows], (size_t)1, @"DoubleCol equal");
    XCTAssertEqual([[[table where].StringCol columnIsEqualTo:@"foo"]  countRows], (size_t)1, @"StringCol equal");
    XCTAssertEqual([[[table where].BinaryCol columnIsEqualTo:bin1]    countRows], (size_t)1, @"BinaryCol equal");
    XCTAssertEqual([[[table where].DateCol   columnIsEqualTo:0]       countRows], (size_t)1, @"DateCol equal");
    // These are not yet implemented
    //    XCTAssertEqual([[[table where].TableCol  columnIsEqualTo:subtab1] count], (size_t)1, @"TableCol equal");
    //    XCTAssertEqual([[[table where].MixedCol  columnIsEqualTo:mixInt1] count], (size_t)1, @"MixedCol equal");

    TestQueryErrAllTypesQuery* query = [[table where].BoolCol   columnIsEqualTo:NO];

    XCTAssertEqual([query.IntCol min] , (int64_t)54,    @"IntCol min");
    XCTAssertEqual([query.IntCol max], (int64_t)54,    @"IntCol max");
    XCTAssertEqual([query.IntCol sum] , (int64_t)54,    @"IntCol sum");
    XCTAssertEqual([query.IntCol avg] , 54.0,           @"IntCol avg");

    XCTAssertEqual([query.FloatCol min], 0.7f,         @"FloatCol min");
    XCTAssertEqual([query.FloatCol max], 0.7f,         @"FloatCol max");
    XCTAssertEqual([query.FloatCol sum], (double)0.7f, @"FloatCol sum");
    XCTAssertEqual([query.FloatCol avg], (double)0.7f, @"FloatCol avg");

    XCTAssertEqual([query.DoubleCol min], 0.8,         @"DoubleCol min");
    XCTAssertEqual([query.DoubleCol max], 0.8,         @"DoubleCol max");
    XCTAssertEqual([query.DoubleCol sum] , 0.8,         @"DoubleCol sum");
    XCTAssertEqual([query.DoubleCol avg], 0.8,         @"DoubleCol avg");

    // Check that all column conditions return query objects of the
    // right type
    [[[table where].BoolCol columnIsEqualTo:NO].BoolCol columnIsEqualTo:NO];

    [[[table where].IntCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].IntCol columnIsBetween:0 :0].BoolCol columnIsEqualTo:NO];

    [[[table where].FloatCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].FloatCol columnIsBetween:0 :0].BoolCol columnIsEqualTo:NO];

    [[[table where].DoubleCol columnIsEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DoubleCol columnIsBetween:0 :0].BoolCol columnIsEqualTo:NO];

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
        NSLog(@"%zu: %c", i, [view rowAtIndex:i].BoolCol);
    }


    [[[table where].DateCol columnIsNotEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsLessThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsLessThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsGreaterThan:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsGreaterThanOrEqualTo:0].BoolCol columnIsEqualTo:NO];
    [[[table where].DateCol columnIsBetween:0 :0].BoolCol columnIsEqualTo:NO];

    // These are not yet implemented
    //    [[[table where].TableCol columnIsEqualTo:nil].BoolCol columnIsEqualTo:NO];
    //    [[[table where].TableCol columnIsNotEqualTo:nil].BoolCol columnIsEqualTo:NO];

    //    [[[table where].MixedCol columnIsEqualTo:mixInt1].BoolCol columnIsEqualTo:NO];
    //    [[[table where].MixedCol columnIsNotEqualTo:mixInt1].BoolCol columnIsEqualTo:NO];
}



@end


