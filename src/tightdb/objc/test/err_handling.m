//
//  tutorial.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>

TIGHTDB_TABLE_DEF_3(PeopleTable,
                    Name,  String,
                    Age,   Int,
                    Hired, Bool)

TIGHTDB_TABLE_DEF_2(PeopleTable2,
                    Hired, Bool,
                    Age,   Int)

TIGHTDB_TABLE_IMPL_3(PeopleTable,
                     Name,  String,
                     Age,   Int,
                     Hired, Bool)

TIGHTDB_TABLE_IMPL_2(PeopleTable2,
                     Hired, Bool,
                     Age,   Int)

@interface MACTestErrHandling: SenTestCase
@end
@implementation MACTestErrHandling

- (void)testErrHandling
{
    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
    //------------------------------------------------------

    TightdbGroup *group = [TightdbGroup group];
    // Create new table in group
    PeopleTable *people = [group getTable:@"employees" withClass:[PeopleTable class]];

    // Add some rows
    [people addName:@"John" Age:20 Hired:YES];
    [people addName:@"Mary" Age:21 Hired:NO];
    [people addName:@"Lars" Age:21 Hired:YES];
    [people addName:@"Phil" Age:43 Hired:NO];
    [people addName:@"Anni" Age:54 Hired:YES];

    // Insert at specific position
    [people insertAtIndex:2 Name:@"Frank" Age:34 Hired:YES];

    // Getting the size of the table
    NSLog(@"PeopleTable Size: %lu - is %@.    [6 - not empty]", [people count],
        [people isEmpty] ? @"empty" : @"not empty");

    NSFileManager *fm = [NSFileManager defaultManager];

    // Write the group to disk
    [fm removeItemAtPath:@"people.tightdb" error:NULL];
    [group write:@"people.tightdb"];

    NSDictionary *attributes;
    [attributes setValue:[NSNumber numberWithShort:0444] 
             forKey:NSFilePosixPermissions];

    NSError *error = nil;
    [fileManager setAttributes:attributes ofItemAtPath:@"people.tightdb" error:error];
    if (error) {
        NSLog(@"Failed to set readonly attributes");
    }

    // Load a group from disk (and try to update, even though it is readonly)
    TightdbGroup *fromDisk = [TightdbGroup groupWithFilename:@"people.tightdb"];
    PeopleTable *diskTable = [fromDisk getTable:@"employees" withClass:[PeopleTable class]];

    [diskTable addName:@"Anni" Age:54 Hired:YES];

    NSLog(@"Disktable size: %zu", [diskTable count]);
}

@end
