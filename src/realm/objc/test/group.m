//
//  group.m
//  TightDB
//
//  Test save/load on disk of a realm with one table
//

#import "RLMTestCase.h"

#import <realm/objc/Realm.h>
#import <realm/objc/RLMRealm.h>

REALM_TABLE_2(TestTableRealm,
              First,  String,
              Second, Int)

REALM_TABLE_8(TestTableRealmJson,
              BoolCol,   Bool,
              IntCol,    Int,
              FloatCol,  Float,
              DoubleCol, Double,
              StringCol, String,
              BinaryCol, Binary,
              DateCol,   Date,
              MixedCol,  Mixed)

@interface MACTestRealm : RLMTestCase

@end

@implementation MACTestRealm

- (void)testRealm {
    // Load the realm
    RLMRealm *realm = [self realmWithTestPath];
    XCTAssertTrue(realm, @"Realm from disk should be valid");

    // Create new table in realm
    [realm beginWriteTransaction];
    [realm createTableWithName:@"test" asTableClass:[TestTableRealm class]];
    TestTableRealm *t = [realm tableWithName:@"test" asTableClass:[TestTableRealm class]];

    // Verify
    XCTAssertEqual(t.columnCount, (NSUInteger)2, @"Should have 2 columns");
    XCTAssertEqual(t.rowCount, (NSUInteger)0, @"Should have 0 rows");

    // Modify table
    t = [realm tableWithName:@"test" asTableClass:[TestTableRealm class]];
    [t addFirst:@"Test" Second:YES];
    [realm commitWriteTransaction];
    
    // Verify
    RLMRealm *realm2 = [self realmWithTestPath];
    TestTableRealm *t2 = [realm2 tableWithName:@"test" asTableClass:[TestTableRealm class]];
    XCTAssertEqual(t2.rowCount, (NSUInteger)1, @"test table should have one row");
}

- (void)testGetTable {
    XCTAssertNil([[self realmWithTestPath] tableWithName:@"noTable"], @"Table does not exist");
}

- (void)testRealmTableCount {
    XCTAssertEqual([[self realmWithTestPath] tableCount], (NSUInteger)0, @"No tables added");
    [[self realmWithTestPath] writeUsingBlock:^(RLMRealm *realm) {
        [realm createTableWithName:@"tableName"];
    }];
    XCTAssertEqual([[self realmWithTestPath] tableCount], (NSUInteger)1, @"1 table added");
}

- (void)testToJSONString {

    RLMRealm *realm = [self realmWithTestPath];

    [realm writeUsingBlock:^(RLMRealm *realm) {
        TestTableRealmJson *table = [realm createTableWithName:@"test" asTableClass:[TestTableRealmJson class]];
        
        const char bin[4] = { 0, 1, 2, 3 };
        NSData *binary = [[NSData alloc] initWithBytes:bin length:sizeof bin];
        
        NSDate *date = (NSDate *)[NSDate dateWithString:@"2014-05-17 13:15:10 +0100"];
        [table addRow:@[@YES, @1234, @((float)12.34), @1234.5678, @"I'm just a String", binary, @((int)[date timeIntervalSince1970]), @"I'm also a string in a mixed column"]];
        
        NSString *result = [realm toJSONString];
        
        XCTAssertEqualObjects(result, @"{\"test\":[{\"BoolCol\":true,\"IntCol\":1234,\"FloatCol\":1.2340000e+01,\"DoubleCol\":1.2345678000000000e+03,\"StringCol\":\"I'm just a String\",\"BinaryCol\":\"00010203\",\"DateCol\":\"2014-05-17 12:15:10\",\"MixedCol\":\"I'm also a string in a mixed column\"}]}", @"JSON string expected to one 8-column row");
    }];
}

@end
