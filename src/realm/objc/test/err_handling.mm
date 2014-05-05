//
//  err_handling.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//


#import "RLMTestCase.h"

#import <realm/objc/Realm.h>
#import <realm/objc/RLMTable_noinst.h>
#import <realm/objc/RLMTableFast.h>
#import <realm/objc/RLMPrivateTableMacrosFast.h>

@interface PeopleErrObject : RLMRow

@property (nonatomic, copy)   NSString *Name;
@property (nonatomic, assign) NSInteger Age;
@property (nonatomic, assign) BOOL      Hired;

@end

@implementation PeopleErrObject
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(PeopleErrTable, PeopleErrObject);

@interface TestQueryObject : RLMRow

@property (nonatomic, assign) NSInteger Age;

@end

@implementation TestQueryObject
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(TestQueryTable, TestQueryObject);

@interface TestQueryAllObject : RLMRow

@property (nonatomic, assign) BOOL      BoolCol;
@property (nonatomic, assign) NSInteger IntCol;
@property (nonatomic, assign) CGFloat   FloatCol;
@property (nonatomic, assign) double    DoubleCol;
@property (nonatomic, copy)   NSString *StringCol;
@property (nonatomic, strong) NSData   *BinaryCol;
@property (nonatomic, strong) NSDate   *DateCol;
@property (nonatomic, strong) TestQueryTable *TableCol;

@end

@implementation TestQueryAllObject
@end

RLM_TABLE_TYPE_FOR_OBJECT_TYPE(TestQueryAllTable, TestQueryAllObject);

@interface MACTestErrHandling: RLMTestCase

@end

@implementation MACTestErrHandling

- (void)testErrHandling {
    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
    //------------------------------------------------------
    NSError* error = nil;

    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        // Create new table in realm
        RLMTable* people = [realm createTableWithName:@"employees" objectClass:[PeopleErrObject class]];
        
        // No longer supports errors, the tes may be redundant
        // Add some rows
        
        [people addRow:@[@"John", @20, @YES]];
        [people addRow:@[@"Mary", @21, @NO]];
        [people addRow:@[@"Lars", @21, @YES]];
        [people addRow:@[@"Phil", @43, @NO]];
        [people addRow:@[@"Anni", @54, @YES]];
        
        // Insert at specific position
        [people insertRow:@[@"Frank", @34, @YES] atIndex:2];
        
        // Getting the size of the table
        NSLog(@"PeopleErrTable Size: %lu - is %@.    [6 - not empty]", [people rowCount],
              people.rowCount == 0 ? @"empty" : @"not empty");
    }];

    XCTAssertNil(error, @"error should be nil after saving a transaction");

    //------------------------------------------------------
    NSLog(@"--- Changing permissions ---");
    //------------------------------------------------------
    
    error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm setAttributes:@{NSFilePosixPermissions: @(0444)}
         ofItemAtPath:RLMTestRealmPath
                error:&error];
    if (error) {
        XCTFail(@"Failed to set readonly attributes");
    }
    
    //------------------------------------------------------
    NSLog(@"--- Make normal again ---");
    //------------------------------------------------------
    
    error = nil;
    [fm setAttributes:@{NSFilePosixPermissions: @(0644)}
         ofItemAtPath:RLMTestRealmPath
                error:&error];
    if (error) {
        XCTFail(@"Failed to set readonly attributes");
    }
    
    RLMRealm *fromDisk = [self realmPersistedAtTestPath];
    XCTAssertNotNil(fromDisk, @"realm from disk should be valid");

    PeopleErrTable *diskTable = [fromDisk tableWithName:@"employees" asTableClass:[PeopleErrTable class]];

    // Fake readonly.
    [((RLMTable*)diskTable) setReadOnly:YES];

    NSLog(@"Disktable size: %zu", [diskTable rowCount]);

//    No longer support for errors here
//    error = nil;
//    if (![diskTable addName:@"Anni" Age:54 Hired:YES error:&error]) {
//        NSLog(@"%@", [error localizedDescription]);
//    } else {
//        XCTFail(@"addName to readonly should have failed.");
//    }
//
//    NSLog(@"Disktable size: %zu", [diskTable rowCount]);
}

- (void)testErrorInsert {
    [self createTestTableWithWriteBlock:^(RLMTable *table) {
        // Create table with all column types
        RLMDescriptor * desc = [table descriptor];
        if ([desc addColumnWithName:@"int" type:RLMTypeInt] == NSNotFound) {
            XCTFail(@"addColumn failed.");
        }
        if ([desc addColumnWithName:@"bool" type:RLMTypeBool] == NSNotFound) {
            XCTFail(@"addColumn failed.");
        }
        
        if ([desc addColumnWithName:@"date" type:RLMTypeDate] == NSNotFound) {
            XCTFail(@"addColumn failed.");
        }
        if ([desc addColumnWithName:@"string" type:RLMTypeString] == NSNotFound) {
            XCTFail(@"addColumn failed.");
        }
        if ([desc addColumnWithName:@"string_long" type:RLMTypeString] == NSNotFound) {
            XCTFail(@"addColumn failed.");
        }
        if ([desc addColumnWithName:@"string_enum" type:RLMTypeString] == NSNotFound) {
            XCTFail(@"addColumn failed.");
        }
        if ([desc addColumnWithName:@"binary" type:RLMTypeBinary] == NSNotFound) {
            XCTFail(@"addColumn failed.");
        }
        if ([desc addColumnWithName:@"mixed" type:RLMTypeMixed] == NSNotFound) {
            XCTFail(@"addColumn failed.");
        }
        RLMDescriptor * subdesc;
        if (!(subdesc = [desc addColumnTable:@"tables"])) {
            XCTFail(@"addColumn failed.");
        }
        if ([subdesc addColumnWithName:@"sub_first" type:RLMTypeInt] == NSNotFound) {
            XCTFail(@"addColumn failed.");
        }
        if ([subdesc addColumnWithName:@"sub_second" type:RLMTypeString] == NSNotFound) {
            XCTFail(@"addColumn failed.");
        }
        
        // Add some rows
        for (NSUInteger i = 0; i < 15; ++i) {
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
    }];
}

- (void)testQueryErrHandling {
    [self.realmWithTestPath writeUsingBlock:^(RLMRealm *realm) {
        TestQueryAllTable *table = [TestQueryAllTable tableInRealm:realm named:@"table"];
        XCTAssertNotNil(table, @"Table is nil");
        
        const char bin[4] = { 0, 1, 2, 3 };
        NSData* bin1 = [[NSData alloc] initWithBytes:bin length:sizeof bin / 2];
        NSData* bin2 = [[NSData alloc] initWithBytes:bin length:sizeof bin];
        NSDate *date = [NSDate date];

        [table addRow:@{@"BoolCol":   @NO,
                        @"IntCol":    @54,
                        @"FloatCol":  @0.7,
                        @"DoubleCol": @0.8,
                        @"StringCol": @"foo",
                        @"BinaryCol": bin1,
                        @"DateCol":   [NSDate dateWithTimeIntervalSince1970:0]}];
        
        [table addRow:@{@"BoolCol":   @YES,
                        @"IntCol":    @506,
                        @"FloatCol":  @7.7,
                        @"DoubleCol": @8.8,
                        @"StringCol": @"banach",
                        @"BinaryCol": bin2,
                        @"DateCol":   date}];
        TestQueryTable *subtable = [table lastRow][@"TableCol"];
        [subtable addRow:@[@100]];
        
        XCTAssertEqual([table countWhere:@"BoolCol == NO"],      (NSUInteger)1, @"BoolCol count");
        XCTAssertEqual([table countWhere:@"IntCol == 54"],       (NSUInteger)1, @"IntCol count");
        XCTAssertEqual([table countWhere:@"FloatCol == 0.7"],    (NSUInteger)1, @"FloatCol count");
        XCTAssertEqual([table countWhere:@"DoubleCol == 0.8"],   (NSUInteger)1, @"DoubleCol count");
        XCTAssertEqual([table countWhere:@"StringCol == 'foo'"], (NSUInteger)1, @"StringCol count");
        NSUInteger binCount = [table countWhere:[NSPredicate predicateWithFormat:@"BinaryCol == %@", bin1]];
        XCTAssertEqual(binCount, (NSUInteger)1, @"BinaryCol count");
        NSUInteger dateCount = [table countWhere:[NSPredicate predicateWithFormat:@"DateCol == %@", date]];
        XCTAssertEqual(dateCount, (NSUInteger)1, @"DateCol count");
        
        // FIXME: Not yet implemented
//        XCTAssertEqualObjects([table minInColumn:@"IntCol" where:@"BoolCol == NO"], @54, @"IntCol min");
//        XCTAssertEqualObjects([table maxInColumn:@"IntCol" where:@"BoolCol == NO"], @54, @"IntCol max");
//        XCTAssertEqualObjects([table sumInColumn:@"IntCol" where:@"BoolCol == NO"], @54, @"IntCol sum");
//        XCTAssertEqualObjects([table avgInColumn:@"IntCol" where:@"BoolCol == NO"], @54, @"IntCol avg");
//        
//        XCTAssertEqualObjects([table minInColumn:@"FloatCol" where:@"BoolCol == NO"], @0.7, @"FloatCol min");
//        XCTAssertEqualObjects([table maxInColumn:@"FloatCol" where:@"BoolCol == NO"], @0.7, @"FloatCol max");
//        XCTAssertEqualObjects([table sumInColumn:@"FloatCol" where:@"BoolCol == NO"], @0.7, @"FloatCol sum");
//        XCTAssertEqualObjects([table avgInColumn:@"FloatCol" where:@"BoolCol == NO"], @0.7, @"FloatCol avg");
//        
//        XCTAssertEqualObjects([table minInColumn:@"DoubleCol" where:@"BoolCol == NO"], @0.8, @"DoubleCol min");
//        XCTAssertEqualObjects([table maxInColumn:@"DoubleCol" where:@"BoolCol == NO"], @0.8, @"DoubleCol max");
//        XCTAssertEqualObjects([table sumInColumn:@"DoubleCol" where:@"BoolCol == NO"], @0.8, @"DoubleCol sum");
//        XCTAssertEqualObjects([table avgInColumn:@"DoubleCol" where:@"BoolCol == NO"], @0.8, @"DoubleCol avg");
        
        [table countWhere:@"BoolCol == NO"];
        
        [table countWhere:@"IntCol == 0 && BoolCol == NO"];
        [table countWhere:@"IntCol != 0 && BoolCol == NO"];
        [table countWhere:@"IntCol < 0  && BoolCol == NO"];
        [table countWhere:@"IntCol <= 0 && BoolCol == NO"];
        [table countWhere:@"IntCol > 0  && BoolCol == NO"];
        [table countWhere:@"IntCol >= 0 && BoolCol == NO"];
        [table countWhere:[NSPredicate predicateWithFormat:@"IntCol between %@ && BoolCol == NO", @[@0, @0]]];

        [table countWhere:@"FloatCol == 0 && BoolCol == NO"];
        [table countWhere:@"FloatCol != 0 && BoolCol == NO"];
        [table countWhere:@"FloatCol < 0  && BoolCol == NO"];
        [table countWhere:@"FloatCol <= 0 && BoolCol == NO"];
        [table countWhere:@"FloatCol > 0  && BoolCol == NO"];
        [table countWhere:@"FloatCol >= 0 && BoolCol == NO"];
        [table countWhere:[NSPredicate predicateWithFormat:@"FloatCol between %@ && BoolCol == NO", @[@0, @0]]];

        [table countWhere:@"DoubleCol == 0 && BoolCol == NO"];
        [table countWhere:@"DoubleCol != 0 && BoolCol == NO"];
        [table countWhere:@"DoubleCol < 0  && BoolCol == NO"];
        [table countWhere:@"DoubleCol <= 0 && BoolCol == NO"];
        [table countWhere:@"DoubleCol > 0  && BoolCol == NO"];
        [table countWhere:@"DoubleCol >= 0 && BoolCol == NO"];
        [table countWhere:[NSPredicate predicateWithFormat:@"DoubleCol between %@ && BoolCol == NO", @[@0, @0]]];

        [table countWhere:@"StringCol == ''            && BoolCol == NO"];
        [table countWhere:@"StringCol ==[c] ''         && BoolCol == NO"];
        [table countWhere:@"StringCol != ''            && BoolCol == NO"];
        [table countWhere:@"StringCol !=[c] ''         && BoolCol == NO"];
        [table countWhere:@"StringCol beginswith ''    && BoolCol == NO"];
        [table countWhere:@"StringCol beginswith[c] '' && BoolCol == NO"];
        [table countWhere:@"StringCol endswith ''      && BoolCol == NO"];
        [table countWhere:@"StringCol endswith[c] ''   && BoolCol == NO"];
        [table countWhere:@"StringCol contains ''      && BoolCol == NO"];
        [table countWhere:@"StringCol contains[c] ''   && BoolCol == NO"];

        [table countWhere:[NSPredicate predicateWithFormat:@"BinaryCol == %@         && BoolCol == NO", bin1]];
        [table countWhere:[NSPredicate predicateWithFormat:@"BinaryCol != %@         && BoolCol == NO", bin1]];
        [table countWhere:[NSPredicate predicateWithFormat:@"BinaryCol beginswith %@ && BoolCol == NO", bin1]];
        [table countWhere:[NSPredicate predicateWithFormat:@"BinaryCol endswith %@   && BoolCol == NO", bin1]];
        [table countWhere:[NSPredicate predicateWithFormat:@"BinaryCol contains %@   && BoolCol == NO", bin1]];
        
        // FIXME: Fix this
//        RLMView *view = [table allWhere:[NSPredicate predicateWithFormat:@"DateCol == %@ && BoolCol == NO", date]];
//        for (RLMRow *row in view) {
//            NSLog(@"row BoolCol: %@", row[@"BoolCol"]);
//        }
        
        [table countWhere:[NSPredicate predicateWithFormat:@"DateCol == %@ && BoolCol == NO", date]];
        [table countWhere:[NSPredicate predicateWithFormat:@"DateCol != %@ && BoolCol == NO", date]];
        [table countWhere:[NSPredicate predicateWithFormat:@"DateCol < %@  && BoolCol == NO", date]];
        [table countWhere:[NSPredicate predicateWithFormat:@"DateCol <= %@ && BoolCol == NO", date]];
        [table countWhere:[NSPredicate predicateWithFormat:@"DateCol > %@  && BoolCol == NO", date]];
        [table countWhere:[NSPredicate predicateWithFormat:@"DateCol >= %@ && BoolCol == NO", date]];
        [table countWhere:[NSPredicate predicateWithFormat:@"DateCol between %@ && BoolCol == NO", @[date, date]]];
        
        // FIXME: Not yet implemented
//        [table countWhere:@"TableCol == nil && BoolCol == NO"];
//        [table countWhere:@"TableCol != nil && BoolCol == NO"];
    }];
}

@end
