//
//  smart_context.mm
//  TightDB
//
//  Run tests on TDBSmartContext
//

#import <XCTest/XCTest.h>
#import <tightdb/objc/Tightdb.h>
#import "XCTestCase+AsyncTesting.h"

TIGHTDB_TABLE_1(TDBSmartContextTable,
                column, String)

@interface TDBSmartContextTests : XCTestCase

@property (nonatomic, copy)   NSString *dbPath;
@property (nonatomic, strong) TDBSmartContext *smartContext;
@property (nonatomic, strong) TDBContext *standardContext;

@end

@implementation TDBSmartContextTests

#pragma mark - Setup/Teardown

- (void)setUp {
    [super setUp];
    
    self.dbPath = @"TDBSmartContextTests.tightdb";
    
    [[NSFileManager defaultManager] removeItemAtPath:self.dbPath error:nil];
    
    self.smartContext = [TDBSmartContext contextWithPersistenceToFile:self.dbPath];
    self.standardContext = [TDBContext contextPersistedAtPath:self.dbPath error:nil];
}

- (void)tearDown {
    [super tearDown];
    
    self.smartContext = nil;
    self.standardContext = nil;
}

#pragma mark - Tests

- (void)testContextExists {
    XCTAssertNotNil(self.smartContext, @"context should not be nil");
    XCTAssertEqual([self.smartContext class], [TDBSmartContext class], @"context should be of class TDBSmartContext");
}

- (void)testCanReadPreviouslyCreatedTable {
    NSString *tableName = @"testCanReadPreviouslyCreatedTable";
    
    NSError *error = nil;
    
    [self.standardContext writeUsingBlock:^BOOL(TDBTransaction *transaction) {
        [transaction createTableWithName:tableName];
        return YES;
    } error:&error];
    
    XCTAssertNil(error, @"TDBContext error should be nil after write block");
    
    TDBSmartContext *localSmartContext = [TDBSmartContext contextWithPersistenceToFile:self.dbPath];
    TDBTable *table = [localSmartContext tableWithName:tableName];
    
    XCTAssertNotNil(table, @"pre-existing table read from TDBSmartContext should not be nil");
    XCTAssertEqual([table class], [TDBTable class], @"pre-existing table read from \
                   TDBSmartContext should be of class TDBTable");
}

- (void)testCanReadPreviouslyCreatedTypedTable {
    NSString *tableName = @"testCanReadPreviouslyCreatedTypedTable";
    
    NSError *error = nil;
    
    [self.standardContext writeUsingBlock:^BOOL(TDBTransaction *transaction) {
        [transaction createTableWithName:tableName asTableClass:[TDBSmartContextTable class]];
        return YES;
    } error:&error];
    
    XCTAssertNil(error, @"TDBContext error should be nil after write block");
    
    TDBSmartContext *localSmartContext = [TDBSmartContext contextWithPersistenceToFile:self.dbPath];
    TDBSmartContextTable *table = [localSmartContext tableWithName:tableName asTableClass:[TDBSmartContextTable class]];
    
    XCTAssertNotNil(table, @"pre-existing typed table read from TDBSmartContext should not be nil");
    XCTAssertEqual([table class],
                   [TDBSmartContextTable class],
                   @"pre-existing typed table read from TDBSmartContext should be of class TDBTable");
}

- (void)testTableCreatedAfterSmartContextStarted {
    NSString *tableName = @"testTableCreatedAfterSmartContextStarted";
    
    NSError *error = nil;
    
    [self.standardContext writeUsingBlock:^BOOL(TDBTransaction *transaction) {
        [transaction createTableWithName:tableName];
        return YES;
    } error:&error];
    
    XCTAssertNil(error, @"TDBContext error should be nil after write block");
    
    __block TDBTable *table = [self.smartContext tableWithName:tableName];
    
    XCTAssertNil(table, @"TDBSmartContext should not immediately be able to see a \
                 table that was created after the context started");
    
    __block BOOL notificationFired = NO;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:TDBContextDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      notificationFired = YES;
                                                      table = [self.smartContext tableWithName:tableName];
                                                      [self notify:XCTAsyncTestCaseStatusSucceeded];
                                                  }];
    
    [self waitForTimeout:1.0f];
    
    XCTAssertTrue(notificationFired, @"A notification should have fired after a table was created");
    XCTAssertNotNil(table, @"The TDBSmartContext should be able to read a newly \
                    created table after a TDBContextDidChangeNotification was sent");
    XCTAssertEqual([table class], [TDBTable class], @"a newly created table read from \
                   TDBSmartContext should be of class TDBTable");
}

@end
