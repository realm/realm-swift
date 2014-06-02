////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import <sqlite3.h>
#import <Realm/Realm.h>

#import "Performance.h"
#import "Utils.h"

@interface PerfObj : RLMObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) BOOL hired;
@property (nonatomic, assign) NSInteger spare;

@end

@implementation PerfObj
@end




@implementation Performance
{
    Utils *_utils;
    int _size;
    sqlite3 *db;
    size_t _rounds;
}

-(id)initWithUtils:(Utils *)utils
{
    self = [super init];
    if (self) {
        _utils = utils;
        _size = 1000000;
        _rounds = 100;
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
    
    NSUInteger count = _size;
    
    [[NSFileManager defaultManager] removeItemAtPath:[_utils pathForDataFile:@"perfemployees.realm"] error:nil];
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

    RLMRealm *realm = [RLMRealm realmWithPath:[_utils pathForDataFile:@"perfemployees.realm"]];
    [realm beginWriteTransaction];
    
        // Add some rows
    for (NSUInteger i = 0; i < count; i++) {
        PerfObj *perf = [[PerfObj alloc] init];
        perf.name = @"Foo";
        perf.age = (25 + (int)(drand48() * 4));
        perf.hired = YES;
        perf.spare = 0;
        [realm addObject:perf];
    }
    
    PerfObj *perf = [[PerfObj alloc] init];
    perf.name = @"Sparse";
    perf.age = 41;
    perf.hired = NO;
    perf.spare = 2;
    
    [realm addObject:perf];
    
    [realm commitWriteTransaction];

    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"RLM inserted %i records in %.2f s",_size, stop-start]];
    });



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
        sqlite3_bind_text(ppStmt, 1, "Sparse", -1, NULL);
        sqlite3_bind_int(ppStmt, 2, 41);
        sqlite3_bind_int(ppStmt, 3, 0); // false
        sqlite3_bind_int(ppStmt, 4, 2);

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
    
    // Write out file sizes:
    [self reportSizeForFile:[_utils pathForDataFile:@"perfemployees.realm"] msg:@"RLM Filesize"];
    [self reportSizeForFile:[_utils pathForDataFile:@"perfemployees.sqlite"] msg:@"SQL Filesize"];


}

- (void)testLinearInt
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Linear search on integer column:"]];
    });

    // Realm
    NSTimeInterval rlmTime = 0;
    {
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

        int count __block = 0;
        RLMRealm *realm = [RLMRealm realmWithPath:[_utils pathForDataFile:@"perfemployees.realm"]];
            for (size_t i = 0; i < _rounds; i++) {
                // Create query
                RLMArray *v = [realm objects:[PerfObj className] where:[NSPredicate predicateWithFormat:@"age == %i", i]];
                count += v.count;
            }

        NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
        rlmTime = stop - start;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"   RLM in %.2f s (%lu)", rlmTime, (unsigned long)count]];
        });
    }

    // Sqlite
    NSTimeInterval sqlTime = 0;
    {
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

        int rc = sqlite3_open([_utils pathForDataFile:@"perfemployees.sqlite"].UTF8String, &db);

        int result = 0;
        for (size_t i = 0; i < _rounds; i++) {
            // Prepare query statement
            char *zErrMsg = NULL;
            sqlite3_stmt *qStmt = NULL;
            rc = sqlite3_prepare(db, "SELECT count(*) FROM t1 WHERE age = ?1;", -1, &qStmt, NULL);
            if (rc != SQLITE_OK) {
                fprintf(stderr, "SQL error3: %s\n", sqlite3_errmsg(db));
            }
            sqlite3_bind_int(qStmt, 1, (int)i);

            rc = sqlite3_step(qStmt);
            if (rc != SQLITE_ROW) {
                fprintf(stderr, "SQL error4: %s\n", zErrMsg);
                sqlite3_free(zErrMsg);
            }
            result += sqlite3_column_int(qStmt, 0);

            sqlite3_finalize(qStmt); // Cleanup
        }

        sqlite3_close(db);
        db = NULL;

        NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
        sqlTime = stop - start;

        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"   SQL in %.2f s (%u)", sqlTime, result]];
        });
    }

    double diff = sqlTime / rlmTime;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"   = RLM is %.2f faster than SQL", diff]];
    });
}

- (void)testLinearString
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Linear search on string column:"]];
    });

    // Realm
    NSTimeInterval rlmTime = 0;
    {
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

        int count __block = 0;
        RLMRealm *realm = [RLMRealm realmWithPath:[_utils pathForDataFile:@"perfemployees.realm"]];

            for (size_t i = 0; i < _rounds; i++) {
                // Create query
                RLMArray *v = [realm objects:[PerfObj className] where:[NSPredicate predicateWithFormat:@"name == %@", @"Sparse"]];
                count += v.count;
            }

        NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
        rlmTime = stop - start;

        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"   RLM in %.2f s (%lu)", rlmTime, (unsigned long)count]];
        });
    }

    // Sqlite
    NSTimeInterval sqlTime = 0;
    {
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

        int rc = sqlite3_open([_utils pathForDataFile:@"perfemployees.sqlite"].UTF8String, &db);

        int result = 0;
        for (size_t i = 0; i < _rounds; i++) {
            // Prepare query statement
            char *zErrMsg = NULL;
            sqlite3_stmt *qStmt = NULL;
            rc = sqlite3_prepare(db, "SELECT count(*) FROM t1 WHERE name = ?1;", -1, &qStmt, NULL);
            if (rc != SQLITE_OK) {
                fprintf(stderr, "SQL error3: %s\n", sqlite3_errmsg(db));
            }
            sqlite3_bind_text(qStmt, 1, [@"Sparse" UTF8String], -1, NULL);

            rc = sqlite3_step(qStmt);
            if (rc != SQLITE_ROW) {
                fprintf(stderr, "SQL error4: %s\n", zErrMsg);
                sqlite3_free(zErrMsg);
            }
            result += sqlite3_column_int(qStmt, 0);

            sqlite3_finalize(qStmt); // Cleanup
        }

        sqlite3_close(db);
        db = NULL;

        NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
        sqlTime = stop - start;

        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"   SQL in %.2f s (%u)", sqlTime, result]];
        });
    }

    double diff = sqlTime / rlmTime;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"   = RLM is %.2f faster than SQL", diff]];
    });
}


- (void)testMultipleConditions
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Search with multiple conditions:"]];
    });

    // Realm
    NSTimeInterval rlmTime = 0;
    {
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

        int count __block = 0;
        RLMRealm *realm = [RLMRealm realmWithPath:[_utils pathForDataFile:@"perfemployees.realm"]];

            for (size_t i = 0; i < _rounds; i++) {
                // Create query
                BOOL hired = i % 2;
                RLMArray *v = [realm objects:[PerfObj className] where:[NSPredicate predicateWithFormat:@"age between %@ && hired == %@", @[@20, @30], [NSNumber numberWithBool:hired]]];
                count += v.count;
            }

        NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
        rlmTime = stop - start;

        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"   RLM in %.2f s (%lu)", rlmTime, (unsigned long)count]];
        });
    }

    // Sqlite
    NSTimeInterval sqlTime = 0;
    {
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

        int rc = sqlite3_open([_utils pathForDataFile:@"perfemployees.sqlite"].UTF8String, &db);

        int result = 0;
        for (size_t i = 0; i < _rounds; i++) {
            // Prepare query statement
            char *zErrMsg = NULL;
            sqlite3_stmt *qStmt = NULL;
            rc = sqlite3_prepare(db, "SELECT count(*) FROM t1 WHERE hired = ?1 AND age >= 20 AND age <= 30;", -1, &qStmt, NULL);
            if (rc != SQLITE_OK) {
                fprintf(stderr, "SQL error3: %s\n", sqlite3_errmsg(db));
            }

            int hired = i % 2;
            sqlite3_bind_int(qStmt, 1, hired);

            rc = sqlite3_step(qStmt);
            if (rc != SQLITE_ROW) {
                fprintf(stderr, "SQL error4: %s\n", zErrMsg);
                sqlite3_free(zErrMsg);
            }
            result += sqlite3_column_int(qStmt, 0);

            sqlite3_finalize(qStmt); // Cleanup
        }

        sqlite3_close(db);
        db = NULL;

        NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
        sqlTime = stop - start;

        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"   SQL in %.2f s (%u)", sqlTime, result]];
        });
    }

    double diff = sqlTime / rlmTime;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"   = RLM is %.2f faster than SQL", diff]];
    });
}

- (void)testFetchAndIterate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Search and iterate over results:"]];
    });

    // Realm (iterate using fastenumeration)
    NSTimeInterval rlmTime = 0;
    {
        __block int counter = 0;
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

        RLMRealm *realm = [RLMRealm realmWithPath:[_utils pathForDataFile:@"perfemployees.realm"]];
            // Create query (current employees between 20 and 30 years old)
        RLMArray *res = [realm objects:[PerfObj className] where:[NSPredicate predicateWithFormat:@"age between %@ && hired == %@", @[@20, @30], [NSNumber numberWithBool:YES]]];


            int agesum = 0;
            for (PerfObj *row in res) {
                agesum += row.age;
                counter++;
            }
       

        NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
        rlmTime = stop - start;

        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"  RLM in %.2f s %d", rlmTime, counter]];
        });
    }

    // Realm (iterate using loop with manual lookup)
    NSTimeInterval rlmTime2 = 0;
    {
        __block int counter = 0;
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

        RLMRealm *realm = [RLMRealm realmWithPath:[_utils pathForDataFile:@"perfemployees.realm"]];

            // Create query (current employees between 20 and 30 years old)
        RLMArray *res = [realm objects:[PerfObj className] where:[NSPredicate predicateWithFormat:@"age between %@ && hired == %@", @[@20, @30], [NSNumber numberWithBool:YES]]];

            // Manually optimized loop to avoid row creation
            int agesum = 0;
            size_t count = res.count;
            for (size_t i = 0; i < count; ++i) {
                PerfObj *po = res[i];
                agesum += po.age;
                counter++;
            }

        NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
        rlmTime2 = stop - start;

        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"  RLM (manual opt) in %.2f s %d", rlmTime2, counter]];
        });
    }

    // Sqlite
    NSTimeInterval sqlTime = 0;
    {
        int counter = 0;
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

        int rc = sqlite3_open([_utils pathForDataFile:@"perfemployees.sqlite"].UTF8String, &db);

        // Prepare query statement
        sqlite3_stmt *qStmt = NULL;
        rc = sqlite3_prepare(db, "SELECT * FROM t1 WHERE hired = 1 AND age >= 20 AND age <= 30;", -1, &qStmt, NULL);
        if (rc != SQLITE_OK) {
            fprintf(stderr, "SQL error3: %s\n", sqlite3_errmsg(db));
        }

        int agesum = 0;
        while (sqlite3_step(qStmt) == SQLITE_ROW) {
            const int result = sqlite3_column_int(qStmt, 0);

            agesum += result;
            counter++;
        }

        sqlite3_finalize(qStmt); // Cleanup
        sqlite3_close(db);
        db = NULL;

        NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
        sqlTime = stop - start;

        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"  SQL in %.2f s %d", sqlTime, counter]];
        });
    }

    double diff = sqlTime / rlmTime;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"   = RLM is %.2f faster than SQL", diff]];
    });
}


- (void)testUnqualifiedFetchAndIterate
{

    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];

    RLMRealm *realm = [RLMRealm realmWithPath:[_utils pathForDataFile:@"perfemployees.realm"]];
    
    RLMArray *allObjects = [realm allObjects:[PerfObj className]];
        
        int agesum = 0;
        for (PerfObj *row in allObjects) {
            agesum += row.age;
        }
        NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"RLM Read and Unq.iterate in %.2f s", stop-start]];
        });
    
    

}

- (void)testWriteToDisk
{

//TODO: Support writeToRealm
/*
    NSString *realmDBPath = [_utils pathForDataFile:@"testemployees.realm"];
    RLMTransactionManager *manager = [RLMTransactionManager managerForRealmWithPath:realmDBPath error:nil];
    [manager readUsingBlock:^(RLMRealm *fromDisk) {
        
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
        [[NSFileManager defaultManager] removeItemAtPath:realmDBPath error:nil];
        [fromDisk writeRealmToFile:realmDBPath error:nil];
        
        NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"RLM Write in %.2f s", stop-start]];
        });
    }];

*/
}

-(void)testWriteTransaction
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    RLMRealm *realm = [RLMRealm realmWithPath:[_utils pathForDataFile:@"perfemployees.realm"]];

    [realm beginWriteTransaction];
        
        // Add some rows
        NSUInteger count = _size;
        for (NSUInteger i = 0; i < count; i++) {
            PerfObj *perf = [[PerfObj alloc] init];
            perf.name = @"Foo";
            perf.age = (25 + (int)(drand48() * 4));
            perf.hired = YES;
            perf.spare = 0;
            [realm addObject:perf];
        }
        
        PerfObj *perf = [[PerfObj alloc] init];
        perf.name = @"Sparse";
        perf.age = 41;
        perf.hired = NO;
        perf.spare = 2;
    [realm addObject:perf];
        
    [realm commitWriteTransaction];
    
    NSTimeInterval stop = [NSDate timeIntervalSinceReferenceDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_utils OutGroup:GROUP_RUN msg:[NSString stringWithFormat:@"Transaction Write %.2f s", stop-start]];
    });
}



@end
