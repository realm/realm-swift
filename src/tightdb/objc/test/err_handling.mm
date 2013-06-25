//
//  err_handling.m
//  TightDB
//
// Demo code for short tutorial using Objective-C interface
//

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/tightdb.h>
#import <tightdb/objc/group.h>
#import <tightdb/objc/table.h>
#include <tightdb/binary_data.hpp>
#include <tightdb/table.hpp>
#import <tightdb/objc/table_priv.h>

TIGHTDB_TABLE_DEF_3(PeopleErrTable,
                    Name,  String,
                    Age,   Int,
                    Hired, Bool)

TIGHTDB_TABLE_IMPL_3(PeopleErrTable,
                     Name,  String,
                     Age,   Int,
                     Hired, Bool)

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
    PeopleErrTable *people = [group getTable:@"employees" withClass:[PeopleErrTable class]];

    // Add some rows
    [people addName:@"John" Age:20 Hired:YES];
    [people addName:@"Mary" Age:21 Hired:NO];
    [people addName:@"Lars" Age:21 Hired:YES];
    [people addName:@"Phil" Age:43 Hired:NO];
    [people addName:@"Anni" Age:54 Hired:YES];

    // Insert at specific position
    [people insertAtIndex:2 Name:@"Frank" Age:34 Hired:YES];

    // Getting the size of the table
    NSLog(@"PeopleErrTable Size: %lu - is %@.    [6 - not empty]", [people count],
        [people isEmpty] ? @"empty" : @"not empty");

    NSFileManager *fm = [NSFileManager defaultManager];

    // Write the group to disk
    [fm removeItemAtPath:@"peopleErr.tightdb" error:NULL];
    [group write:@"peopleErr.tightdb"];

    //------------------------------------------------------
    NSLog(@"--- Changing permissions ---");
    //------------------------------------------------------

    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setValue:[NSNumber numberWithShort:0444] forKey:NSFilePosixPermissions];

    NSError *error = nil;
    [fm setAttributes:attributes ofItemAtPath:@"peopleErr.tightdb" error:&error];
    if (error) {
        STFail(@"Failed to set readonly attributes");
    }

    //------------------------------------------------------
    NSLog(@"--- Reopen and manipulate ---");
    //------------------------------------------------------

    // Load a group from disk (and try to update, even though it is readonly)
    error = nil;
    TightdbGroup *fromDisk = [TightdbGroup groupWithFilename:@"peopleErr.tightdb" error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        STFail(@"Since file cannot be opened, we should have gotten an error here.");
    }

    //------------------------------------------------------
    NSLog(@"--- Make normal again ---");
    //------------------------------------------------------

    [attributes setValue:[NSNumber numberWithShort:0644] forKey:NSFilePosixPermissions];

    error = nil;
    [fm setAttributes:attributes ofItemAtPath:@"peopleErr.tightdb" error:&error];
    if (error) {
        STFail(@"Failed to set readonly attributes");
    }

    error = nil;
    fromDisk = [TightdbGroup groupWithFilename:@"peopleErr.tightdb" error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"File should have been possible to open");
    }

    PeopleErrTable *diskTable = [fromDisk getTable:@"employees" withClass:[PeopleErrTable class]];
    
    // Fake readonly.
    [((TightdbTable *)diskTable) setReadOnly:true];

    NSLog(@"Disktable size: %zu", [diskTable count]);

    [diskTable addName:@"Anni" Age:54 Hired:YES];

    NSLog(@"Disktable size: %zu", [diskTable count]);
}

@end
