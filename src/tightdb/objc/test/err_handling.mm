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
    NSError *error = nil;

    //------------------------------------------------------
    NSLog(@"--- Creating tables ---");
    //------------------------------------------------------

    TightdbGroup *group = [TightdbGroup group];
    // Create new table in group
    PeopleErrTable *people = [group getTable:@"employees" withClass:[PeopleErrTable class]];

    // Add some rows
    error = nil;
    if (![people addName:@"John" Age:20 Hired:YES error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"This should have worked");
    }
    error = nil;
    if (![people addName:@"Mary" Age:21 Hired:NO error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"This should have worked");
    }
    if (![people addName:@"Lars" Age:21 Hired:YES error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"This should have worked");
    }
    error = nil;
    if (![people addName:@"Phil" Age:43 Hired:NO error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"This should have worked");
    }
    error = nil;
    if (![people addName:@"Anni" Age:54 Hired:YES error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"This should have worked");
    }

    // Insert at specific position
    [people insertAtIndex:2 Name:@"Frank" Age:34 Hired:YES];

    // Getting the size of the table
    NSLog(@"PeopleErrTable Size: %lu - is %@.    [6 - not empty]", [people count],
        [people isEmpty] ? @"empty" : @"not empty");

    NSFileManager *fm = [NSFileManager defaultManager];

    // Write the group to disk
    [fm removeItemAtPath:@"peopleErr.tightdb" error:NULL];
    error = nil;
    if (![group write:@"peopleErr.tightdb" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"No error expected");        
    }

    //------------------------------------------------------
    NSLog(@"--- Changing permissions ---");
    //------------------------------------------------------

    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [attributes setValue:[NSNumber numberWithShort:0444] forKey:NSFilePosixPermissions];

    error = nil;
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

    error = nil;
    if (![diskTable addName:@"Anni" Age:54 Hired:YES error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        STFail(@"addName to readonly should have failed.");        
    }

    NSLog(@"Disktable size: %zu", [diskTable count]);
}

-(void)testErrorInsert
{
    NSError *error;
    
    // Create table with all column types
    TightdbTable *table = [[TightdbTable alloc] init];
    TightdbSpec *s = [table getSpec];
    if (![s addColumn:tightdb_Int name:@"int" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![s addColumn:tightdb_Bool name:@"bool" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }

    if (![s addColumn:tightdb_Date name:@"date" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![s addColumn:tightdb_String name:@"string" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![s addColumn:tightdb_String name:@"string_long" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![s addColumn:tightdb_String name:@"string_enum" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![s addColumn:tightdb_Binary name:@"binary" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![s addColumn:tightdb_Mixed name:@"mixed" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    TightdbSpec *sub;
    if (!(sub = [s addColumnTable:@"tables" error:&error])) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![sub addColumn:tightdb_Int name:@"sub_first" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![sub addColumn:tightdb_String name:@"sub_second" error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"addColumn failed.");
    }
    if (![table updateFromSpecWithError:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"UpdateFromSpec failed.");        
    }
    
    // Add some rows
    for (size_t i = 0; i < 15; ++i) {
        if (![table insertInt:0 ndx:i value:i error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        if (![table insertBool:1 ndx:i value:(i % 2 ? YES : NO) error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        if (![table insertDate:2 ndx:i value:12345 error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        if (![table insertString:3 ndx:i value:[NSString stringWithFormat:@"string %zu", i] error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        if (![table insertString:4 ndx:i value:@" Very long string.............." error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        
        switch (i % 3) {
            case 0:
                if (![table insertString:5 ndx:i value:@"test1" error:&error]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                break;
            case 1:
                if (![table insertString:5 ndx:i value:@"test2" error:&error]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                break;
            case 2:
                if (![table insertString:5 ndx:i value:@"test3" error:&error]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                break;
        }
        
        if (![table insertBinary:6 ndx:i data:"binary" size:7 error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        switch (i % 3) {
            case 0:
                if (![table insertMixed:7 ndx:i value:[TightdbMixed mixedWithBool:NO] error:&error]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                break;
            case 1:
                if (![table insertMixed:7 ndx:i value:[TightdbMixed mixedWithInt64:i] error:&error]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                break;
            case 2:
                if (![table insertMixed:7 ndx:i value:[TightdbMixed mixedWithString:@"string"] error:&error]) {
                    NSLog(@"%@", [error localizedDescription]);
                    STFail(@"Insert failed.");
                }
                break;
        }
        if (![table insertSubtable:8 ndx:i error:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"Insert failed.");
        }
        
        if (![table insertDoneWithError:&error]) {
            NSLog(@"%@", [error localizedDescription]);
            STFail(@"InsertDone failed.");
        }
        
        // Add sub-tables
        if (i == 2) {
            TightdbTable *subtable = [table getSubtable:8 ndx:i];
            if (![subtable insertInt:0 ndx:0 value:42 error:&error]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"Insert failed.");
            }
            if (![subtable insertString:1 ndx:0 value:@"meaning" error:&error]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"Insert failed.");
            }
            if (![subtable insertDoneWithError:&error]) {
                NSLog(@"%@", [error localizedDescription]);
                STFail(@"InsertDone failed.");
            }
        }
        
    }
    
    // We also want a ColumnStringEnum
    if (![table optimize]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"Insert failed.");
    }
    
    // Test Deletes
    if (![table remove:14 error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"Remove failed.");
    }
    if (![table remove:0 error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"Remove failed.");
    }
    if (![table remove:5 error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"Remove failed.");
    }
    
    STAssertEquals([table count], (size_t)12, @"Size should have been 12");
#ifdef TIGHTDB_DEBUG
    [table verify];
#endif
    
    // Test Clear
    if (![table clearWithError:&error]) {
        NSLog(@"%@", [error localizedDescription]);
        STFail(@"Clear failed.");
    }
    STAssertEquals([table count], (size_t)0, @"Size should have been zero");
    
#ifdef TIGHTDB_DEBUG
    [table verify];
#endif
}


@end
