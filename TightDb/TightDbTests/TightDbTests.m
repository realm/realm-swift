//
//  InvulgoGameLibTests.m
//  InvulgoGameLibTests
//
//  Created by Thomas Andersen on 12/02/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import "TightDbTests.h"
#define TIGHT_IMPL
#include "TightDb.h"
M_TABLE_DEF_2(NSString*,fun,int,fun2);

@implementation TightDbTests

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
    TightDb *test = [[TightDb alloc] init];
    NSLog(@"%@", [test getfun]);
    STAssertNotNil(test, @"Test is nil");
}

@end
