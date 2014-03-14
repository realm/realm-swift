#import "TViewController.h"
#import <Tightdb/Tightdb.h>

@interface TViewController ()
@end

@implementation TViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Remove old file
    NSString *filename = [self writeablePathForFile: @"MyDatabase.db"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:filename error:&error];

    // Create data file
    TDBSharedGroup *sharedGroup = [TDBSharedGroup sharedGroupWithFile:filename withError:nil];

    // Perform a write transaction
    [sharedGroup writeWithBlock:^(TDBGroup *group) {

        // Access table from group
        TDBTable *table = [group getOrCreateTableWithName:@"myTable" error:nil];

        // Add columns to the table
        [table addColumnWithName:@"Name" andType:TDBStringType];
        [table addColumnWithName:@"Age" andType:TDBIntType];
       
        // Add a row to the table using a NSDictionary
        [table appendRow:@{@"Name": @"Jill", @"Age": @21}];

        // Add a new column dynamically
        int const HIRED = [table addColumnWithName:@"Hired" andType:TDBBoolType];

        // Add another row using a NSArray
        [table appendRow:@[@"Mary", @40, @NO]];

        // Change value in row
        TDBRow *row = [table rowAtIndex:0];
        [row setBool:YES inColumnWithIndex:HIRED];

        // Remove row from table
        [table removeRowAtIndex:0];

        // Print out info on iPhone screen
        self.columnCountOutlet.text = [NSString stringWithFormat:@"# of columns: %i", table.columnCount];
        self.sizeOutlet.text = [NSString stringWithFormat:@"# of rows: %i", table.rowCount];

        return YES;
    } withError:nil];
}

- (NSString*)writeablePathForFile:(NSString*)fileName
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}


@end
