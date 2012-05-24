//
//  Performance.m
//  TightDbExample
//
//  Created by Bjarne Christiansen on 5/24/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import "Performance.h"
#import "TightDb.h"
#import "Group.h"
#import "Utils.h"

TDB_TABLE_4(PerfTable,
            String, Name,
            Int,    Age,
            Bool,   Hired,
            Int,	Spare)


@implementation Performance
{
    Utils *_utils;
    int _size;
}

-(id)initWithUtils:(Utils *)utils
{
    self = [super init];
    if (self) {
        _utils = utils;
        _size = 1000;
    }
    return self;
}

- (void)testInsert {
    Group *group = [Group group];
    // Create new table in group
    PerfTable *table = [group getTable:@"employees"withClass:[PerfTable class]];
    
    // Add some rows
    NSUInteger count = _size;
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    for (NSUInteger i = 0; i < count; i++) {
        [table addName:@"Foo" Age:25 + (int)(drand48() * 4) Hired:YES Spare:0];
    }
    [table addName:@"Sparse" Age:41 Hired:NO Spare:2];

    NSLog(@"Age verify: %lld", [table get:1 ndx:1000]);
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils Eval:YES msg:[NSString stringWithFormat:@"Inserted %i records in %.2f s",_size, stop-start]];
    });

    // Write to disk
    [group write:[_utils pathForDataFile:@"perfemployees.tightdb"]];
}
- (void)testFetch 
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    Group *fromDisk = [Group groupWithFilename:[_utils pathForDataFile:@"perfemployees.tightdb"]];
    PerfTable *diskTable = [fromDisk getTable:@"employees" withClass:[PerfTable class]];

    if ([diskTable count] != _size+1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils Eval:NO msg:[NSString stringWithFormat:@"Size incorrect (%i) - (%zu)", _size, [diskTable count]]];    
        });        
    }
    // Create query (current employees between 20 and 30 years old)
    PerfTable_Query *q = [[[diskTable getQuery].Hired equal:YES].Age between:20 to:30];
    NSLog(@"Query count: %zu", [q count]);
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils Eval:YES msg:[NSString stringWithFormat:@"Read and query in %.2f s (%zu)", stop - start, [q count]]];    
    });
}
- (void)testFetchSparse
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    Group *fromDisk = [Group groupWithFilename:[_utils pathForDataFile:@"perfemployees.tightdb"]];
    PerfTable *diskTable = [fromDisk getTable:@"employees" withClass:[PerfTable class]];
    
    // Create query (current employees between 20 and 30 years old)
    PerfTable_Query *q = [[diskTable getQuery].Age between:40 to:50];
    NSLog(@"Query count: %zu", [q count]);
    
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils Eval:YES msg:[NSString stringWithFormat:@"Read and query sparse in %.2f s (%zu)", stop-start, [q count]]];    
    });
}

- (void)testFetchAndIterate 
{
    int counter = 0;
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    Group *fromDisk = [Group groupWithFilename:[_utils pathForDataFile:@"perfemployees.tightdb"]];
    PerfTable *diskTable = [fromDisk getTable:@"employees" withClass:[PerfTable class]];
    
    
    // Create query (current employees between 20 and 30 years old)
    PerfTable_Query *q = [[[diskTable getQuery].Hired equal:YES].Age between:20 to:30];
    
    PerfTable_View *res = [q findAll];
    int agesum = 0;
    for (PerfTable_Cursor *cur in res) {
        agesum += cur.Age;
        counter++;
    }
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils Eval:YES msg:[NSString stringWithFormat:@"Read and iterate in %.2f s", stop-start]];    
    });
}

- (void)testUnqualifiedFetchAndIterate
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    Group *fromDisk = [Group groupWithFilename:[_utils pathForDataFile:@"perfemployees.tightdb"]];
    PerfTable *diskTable = [fromDisk getTable:@"employees" withClass:[PerfTable class]];

    int agesum = 0;
    for (PerfTable_Cursor *cur in diskTable) {
        agesum += cur.Age;
    }
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils Eval:YES msg:[NSString stringWithFormat:@"Read and Unq.iterate in %.2f s", stop-start]]; 
    });
}

- (void)testWriteToDisk
{
    NSString *tightDBPath = [_utils pathForDataFile:@"testemployees.tightdb"];
    
    Group *fromDisk = [Group groupWithFilename:[_utils pathForDataFile:@"perfemployees.tightdb"]];

    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    [fromDisk write:tightDBPath];

    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils Eval:YES msg:[NSString stringWithFormat:@"Write in %.2f s", stop-start]];    
    });

}


@end
