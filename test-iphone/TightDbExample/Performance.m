//
//  Performance.m
//  TightDbExample
//
//  Created by Bjarne Christiansen on 5/24/12.
//

#import <sqlite3.h>
#import <Tightdb/Tightdb.h>

#import "Performance.h"
#import "Utils.h"

TIGHTDB_TABLE_4(PerfTable,
                Name,  String,
                Age,   Int,
                Hired, Bool,
                Spare, Int)


@implementation Performance
{
    Utils *_utils;
    int _size;
    sqlite3 *db;
}

-(id)initWithUtils:(Utils *)utils
{
    self = [super init];
    if (self) {
        _utils = utils;
        _size = 100000;
    }
    return self;
}

-(void)dealloc
{
    sqlite3_close(db);
    db = NULL;
}


-(void)reportSizeForFile:(NSString *)file msg:(NSString *)msg
{
    NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:file error:nil];
    NSString *fileSize = [fileAttributes objectForKey:NSFileSize];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_SIZE msg:[NSString stringWithFormat:@"%@: %@", msg, fileSize]];
    });
}

- (void)testInsert {

    TDBGroup *group = [TDBGroup group];
    // Create new table in group
    PerfTable *table = [group getOrCreateTableWithName:@"employees" asTableClass:[PerfTable class] ];

    // Add some rows
    NSUInteger count = _size;
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    for (NSUInteger i = 0; i < count; i++) {
        [table addName:@"Foo" Age:25 + (int)(drand48() * 4) Hired:YES Spare:0];
    }
    [table addName:@"Sparse" Age:41 Hired:NO Spare:2];

    NSLog(@"Age verify: %lld", [table intInColumnWithIndex:1 atRowIndex:1000]);
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Inserted %i records in %.2f s",_size, stop-start]];
    });

    // Write to disk
    [[NSFileManager defaultManager] removeItemAtPath:[_utils pathForDataFile:@"bigperfemployees.tightdb"] error:nil];
    [group writeToFile:[_utils pathForDataFile:@"bigperfemployees.tightdb"] withError:nil];
    [self reportSizeForFile:[_utils pathForDataFile:@"bigperfemployees.tightdb"] msg:@"Normal filesize"];
    [table optimize];
    [[NSFileManager defaultManager] removeItemAtPath:[_utils pathForDataFile:@"perfemployees.tightdb"] error:nil];
    [group writeToFile:[_utils pathForDataFile:@"perfemployees.tightdb"] withError:nil];
    [self reportSizeForFile:[_utils pathForDataFile:@"perfemployees.tightdb"] msg:@"Optimized filesize"];


    NSTimeInterval sqlstart = [NSDate timeIntervalSinceReferenceDate];
    char *zErrMsg = NULL;
    db = NULL;
    [[NSFileManager defaultManager] removeItemAtPath:[_utils pathForDataFile:@"perfemployees.sqlite"] error:nil];

    int rc = sqlite3_open([_utils pathForDataFile:@"perfemployees.sqlite"].UTF8String, &db);


    sqlite3_exec(db, "create table t1 (name VARCHAR(100), age INTEGER, hired INTEGER, spare INTEGER);", NULL, NULL, &zErrMsg);
    sqlite3_exec(db, "begin transaction;", NULL, NULL, &zErrMsg);
    sqlite3_stmt *ppStmt = NULL;
    sqlite3_prepare(db, "INSERT INTO t1 VALUES(?1, ?2, ?3, ?4);", -1, &ppStmt, NULL);
    srand(1);
    for (size_t i = 0; i < count; ++i) {
        const int rand_age = 25 + (rand() % 4);
        sqlite3_reset(ppStmt);
        sqlite3_bind_text(ppStmt, 1, "Foo", -1, NULL);
        sqlite3_bind_int(ppStmt, 2, rand_age);
        sqlite3_bind_int(ppStmt, 3, 1); // true
        sqlite3_bind_int(ppStmt, 4, 0);

        rc = sqlite3_step(ppStmt);
        if (rc != SQLITE_DONE) {
            fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(db));
        }
    }
    // Put in last row for sparse queries
    {
        sqlite3_reset(ppStmt);
        sqlite3_bind_text(ppStmt, 1, "Foo", -1, NULL);
        sqlite3_bind_int(ppStmt, 2, 25);
        sqlite3_bind_int(ppStmt, 3, 0); // false
        sqlite3_bind_int(ppStmt, 4, 0);

        rc = sqlite3_step(ppStmt);
        if (rc != SQLITE_DONE) {
            fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(db));
        }
    }
    sqlite3_exec(db, "commit;", NULL, NULL, &zErrMsg);
    sqlite3_finalize(ppStmt); // Cleanup
    sqlite3_close(db);
    db = NULL;
    NSTimeInterval sqlstop = [NSDate timeIntervalSinceReferenceDate];

    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"SQL Inserted %i records in %.2f s",_size, sqlstop-sqlstart]];
    });
    [self reportSizeForFile:[_utils pathForDataFile:@"perfemployees.sqlite"] msg:@"SQL Filesize"];


}
- (void)testFetch
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

    TDBGroup *fromDisk = [TDBGroup groupWithFile:[_utils pathForDataFile:@"perfemployees.tightdb"]withError:nil];
    PerfTable *diskTable = [fromDisk getOrCreateTableWithName:@"employees" asTableClass:[PerfTable class]];

    if ([diskTable rowCount] != _size+1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Size incorrect (%i) - (%i)", _size, [diskTable rowCount]]];
        });
    }
    // Create query (current employees between 20 and 30 years old)
    PerfTable_Query *q = [[[diskTable where].Hired columnIsEqualTo:YES].Age columnIsBetween:20 and_:30];
    NSLog(@"Query count: %i", [q countRows]);
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Read and query in %.2f s (%i)", stop - start, [q countRows]]];
    });

    double diff = [self sqlTestFetch] / (stop-start);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_DIFF msg:[NSString stringWithFormat:@"testFetch %.2f faster than sqlTestFetch", diff]];
    });
}
-(double)sqlTestFetch
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    int rc = sqlite3_open([_utils pathForDataFile:@"perfemployees.sqlite"].UTF8String, &db);

    // Prepare query statement
    char *zErrMsg = NULL;
    sqlite3_stmt *qStmt = NULL;
    rc = sqlite3_prepare(db, "SELECT count(*) FROM t1 WHERE hired = 1 AND age >= 20 AND age <= 30;", -1, &qStmt, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error3: %s\n", sqlite3_errmsg(db));
    }


    rc = sqlite3_step(qStmt);
    if (rc != SQLITE_ROW) {
        fprintf(stderr, "SQL error4: %s\n", zErrMsg);
        sqlite3_free(zErrMsg);
    }
    const int result = sqlite3_column_int(qStmt, 0);
    sqlite3_finalize(qStmt); // Cleanup
    sqlite3_close(db);
    db = NULL;
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"SQL query in %.2f s (%u)", stop - start, result]];
    });

    return stop-start;
}


- (void)testFetchSparse
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

    TDBGroup *fromDisk = [TDBGroup groupWithFile:[_utils pathForDataFile:@"perfemployees.tightdb"]withError:nil];
    PerfTable *diskTable = [fromDisk getOrCreateTableWithName:@"employees" asTableClass:[PerfTable class]];

    // Create query (current employees between 20 and 30 years old)
    PerfTable_Query *q = [[diskTable where].Age columnIsBetween:40 and_:50];
    NSLog(@"Query count: %i", [q countRows]);

    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Read and query sparse in %.2f s (%i)", stop-start, [q countRows]]];
    });

    double diff = [self sqlTestSparse] / (stop-start);
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_DIFF msg:[NSString stringWithFormat:@"testFetchSparse %.2f times faster than sqlTestFetchSparse", diff]];
    });

}

-(double)sqlTestSparse
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

    int rc = sqlite3_open([_utils pathForDataFile:@"perfemployees.sqlite"].UTF8String, &db);

    // Prepare query statement
    char *zErrMsg = NULL;
    sqlite3_stmt *qStmt = NULL;
    rc = sqlite3_prepare(db, "SELECT count(*) FROM t1 WHERE hired = 0 AND age >= 20 AND age <= 30;", -1, &qStmt, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error3: %s\n", sqlite3_errmsg(db));
    }


    rc = sqlite3_step(qStmt);
    if (rc != SQLITE_ROW) {
        fprintf(stderr, "SQL error4: %s\n", zErrMsg);
        sqlite3_free(zErrMsg);
    }
    const int result = sqlite3_column_int(qStmt, 0);
    sqlite3_finalize(qStmt); // Cleanup
    sqlite3_close(db);
    db = NULL;
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"SQL query sparse in %.2f s (%u)", stop - start, result]];
    });

    return stop-start;
}

- (void)testFetchAndIterate
{
    int counter = 0;
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

    TDBGroup *fromDisk = [TDBGroup groupWithFile:[_utils pathForDataFile:@"perfemployees.tightdb"]withError:nil];
    PerfTable *diskTable = [fromDisk getOrCreateTableWithName:@"employees" asTableClass:[PerfTable class]];


    // Create query (current employees between 20 and 30 years old)
    PerfTable_Query *q = [[[diskTable where].Hired columnIsEqualTo:YES].Age columnIsBetween:20 and_:30];

    PerfTable_View *res = [q findAll];
    int agesum = 0;
    for (PerfTable_Row *row in res) {
        agesum += row.Age;
        counter++;
    }
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Read and iterate in %.2f s", stop-start]];
    });
}

- (void)testUnqualifiedFetchAndIterate
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

    TDBGroup *fromDisk = [TDBGroup groupWithFile:[_utils pathForDataFile:@"perfemployees.tightdb"]withError:nil];
    PerfTable *diskTable = [fromDisk getOrCreateTableWithName:@"employees" asTableClass:[PerfTable class]];

    int agesum = 0;
    for (PerfTable_Row *row in diskTable) {
        agesum += row.Age;
    }
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Read and Unq.iterate in %.2f s", stop-start]];
    });
}

- (void)testWriteToDisk
{
    NSString *tightDBPath = [_utils pathForDataFile:@"testemployees.tightdb"];

    TDBGroup *fromDisk = [TDBGroup groupWithFile:[_utils pathForDataFile:@"perfemployees.tightdb"]withError:nil];

    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    [[NSFileManager defaultManager] removeItemAtPath:tightDBPath error:nil];
    [fromDisk writeToFile:tightDBPath withError:nil];

    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Write in %.2f s", stop-start]];
    });

}

-(void)testReadTransaction
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    TDBSharedGroup *fromDisk = [TDBSharedGroup sharedGroupWithFile:[_utils pathForDataFile:@"perfemployees.tightdb"] withError:nil];
    [fromDisk readWithBlock:^(TDBGroup *group) {
        PerfTable *diskTable = [group getOrCreateTableWithName:@"employees" asTableClass:[PerfTable class]];

        // Create query (current employees between 20 and 30 years old)
        PerfTable_Query *q = [[[diskTable where].Hired columnIsEqualTo:YES].Age columnIsBetween:20 and_:30];

        PerfTable_View *res = [q findAll];
        int agesum = 0;
        for (PerfTable_Row *row in res) {
            agesum += row.Age;
        }
    }];

    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Transaction Read and iterate in %.2f s", stop-start]];
    });
}


-(void)testWriteTransaction
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    TDBSharedGroup *fromDisk = [TDBSharedGroup sharedGroupWithFile:[_utils pathForDataFile:@"perfemployees.tightdb"] withError:nil];
    [fromDisk writeWithBlock:^(TDBGroup *group) {
        PerfTable *diskTable = [group getOrCreateTableWithName:@"employees" asTableClass:[PerfTable class]];

        // Add some rows
        NSUInteger count = _size;
        for (NSUInteger i = 0; i < count; i++) {
            [diskTable addName:@"Foo" Age:25 + (int)(drand48() * 4) Hired:YES Spare:0];
        }
        [diskTable addName:@"Sparse" Age:41 Hired:NO Spare:2];

        return YES; // Commit transaction
    } withError:nil];

    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Transaction Write %.2f s", stop-start]];
    });
}



@end
