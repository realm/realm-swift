//
//  smart_context.mm
//  TightDB
//
//  Run tests on RLMSmartContext
//

#import <XCTest/XCTest.h>
#import <realm/objc/Realm.h>
#import "XCTestCase+AsyncTesting.h"

REALM_TABLE_1(RLMSmartContextTable,
              column, String)

@interface RLMSmartContextTests : XCTestCase

@property (nonatomic, copy)   NSString *dbPath;
@property (nonatomic, strong) RLMSmartContext *smartContext;
@property (nonatomic, strong) RLMContext *standardContext;

@end

@implementation RLMSmartContextTests

#pragma mark - Setup/Teardown

- (void)setUp {
    [super setUp];
    
    self.dbPath = @"RLMSmartContextTests.realm";
    
    [[NSFileManager defaultManager] removeItemAtPath:self.dbPath error:nil];
    
    self.smartContext = [RLMSmartContext contextWithPersistenceToFile:self.dbPath];
    self.standardContext = [RLMContext contextPersistedAtPath:self.dbPath error:nil];
}

- (void)tearDown {
    [super tearDown];
    
    self.smartContext = nil;
    self.standardContext = nil;
}

#pragma mark - Tests

- (void)testContextExists {
    XCTAssertNotNil(self.smartContext, @"context should not be nil");
    XCTAssertEqual([self.smartContext class], [RLMSmartContext class], @"context should be of class RLMSmartContext");
}

- (void)testCanReadPreviouslyCreatedTable {
    NSString *tableName = @"testCanReadPreviouslyCreatedTable";
    
    NSError *error = nil;
    
    [self.standardContext writeUsingBlock:^BOOL(RLMTransaction *transaction) {
        [transaction createTableWithName:tableName];
        return YES;
    } error:&error];
    
    XCTAssertNil(error, @"RLMContext error should be nil after write block");
    
    RLMSmartContext *localSmartContext = [RLMSmartContext contextWithPersistenceToFile:self.dbPath];
    RLMTable *table = [localSmartContext tableWithName:tableName];
    
    XCTAssertNotNil(table, @"pre-existing table read from RLMSmartContext should not be nil");
    XCTAssertEqual([table class], [RLMTable class], @"pre-existing table read from \
                   RLMSmartContext should be of class RLMTable");
}

- (void)testCanReadPreviouslyCreatedTypedTable {
    NSString *tableName = @"testCanReadPreviouslyCreatedTypedTable";
    
    NSError *error = nil;
    
    [self.standardContext writeUsingBlock:^BOOL(RLMTransaction *transaction) {
        [transaction createTableWithName:tableName asTableClass:[RLMSmartContextTable class]];
        return YES;
    } error:&error];
    
    XCTAssertNil(error, @"RLMContext error should be nil after write block");
    
    RLMSmartContext *localSmartContext = [RLMSmartContext contextWithPersistenceToFile:self.dbPath];
    RLMSmartContextTable *table = [localSmartContext tableWithName:tableName asTableClass:[RLMSmartContextTable class]];
    
    XCTAssertNotNil(table, @"pre-existing typed table read from RLMSmartContext should not be nil");
    XCTAssertEqual([table class],
                   [RLMSmartContextTable class],
                   @"pre-existing typed table read from RLMSmartContext should be of class RLMTable");
}

- (void)testTableCreatedAfterSmartContextStarted {
    NSString *tableName = @"testTableCreatedAfterSmartContextStarted";
    
    NSError *error = nil;
    
    [self.standardContext writeUsingBlock:^BOOL(RLMTransaction *transaction) {
        [transaction createTableWithName:tableName];
        return YES;
    } error:&error];
    
    XCTAssertNil(error, @"RLMContext error should be nil after write block");
    
    __block RLMTable *table = [self.smartContext tableWithName:tableName];
    
    XCTAssertNil(table, @"RLMSmartContext should not immediately be able to see a \
                 table that was created after the context started");
    
    __block BOOL notificationFired = NO;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:RLMContextDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      notificationFired = YES;
                                                      table = [self.smartContext tableWithName:tableName];
                                                      [self notify:XCTAsyncTestCaseStatusSucceeded];
                                                  }];
    
    [self waitForTimeout:1.0f];
    
    XCTAssertTrue(notificationFired, @"A notification should have fired after a table was created");
    XCTAssertNotNil(table, @"The RLMSmartContext should be able to read a newly \
                    created table after a RLMContextDidChangeNotification was sent");
    XCTAssertEqual([table class], [RLMTable class], @"a newly created table read from \
                   RLMSmartContext should be of class RLMTable");
}

@end
