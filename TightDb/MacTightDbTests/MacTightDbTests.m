//
//  MacTightDbTests.m
//  MacTightDbTests
//
//  Created by Thomas Andersen on 17/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import "MacTightDbTests.h"
#import "OCTable.h"

@implementation MacTightDbTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    OCTable *table = [[OCTable alloc] init];
    NSLog(@"Table: %@", table);
    STAssertNotNil(table, @"OCTable is nil");
    
    OCMixed *mixed = [OCMixed mixedWithBool:YES];
    STAssertTrue([mixed getBool],@"Not true");
}

@end
