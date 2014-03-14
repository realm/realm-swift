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
       
        // Add a row to the table
        [table appendRow:@[@"Jill", @21]];

        // Add a new column
        int const HIRED = [table addColumnWithName:@"Hired" andType:TDBBoolType];

        // Add another row
        [table appendRow:@[@"Mary", @40, @NO]];

        // Change value in row
        TDBRow *row = [table rowAtIndex:0];
        [row setBool:YES inColumnWithIndex:HIRED];

        // Remove row from table
        [table removeRowAtIndex:0];

        // Print out info on iPhone screen
        self.tableColumnCountOutlet.text = [NSString stringWithFormat:@"# of columns: %i", table.columnCount];
        self.tableSizeOutlet.text = [NSString stringWithFormat:@"# of rows: %i", table.rowCount];

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
