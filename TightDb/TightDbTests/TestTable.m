//
//  TestTable.m
//  TightDb
//
//  Created by Thomas Andersen on 16/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import "TestTable.h"
#import "OCTable.h"


@implementation TestTable


- (void)testTable
{
    OCTable *table = [[OCTable alloc] init];
    NSLog(@"Table: %@", table);
    STAssertNotNil(table, @"OCTable is nil");
    
    OCMixed *mixed = [OCMixed mixedWithBool:YES];
    STAssertTrue([mixed getBool],@"Not true");
}

@end
