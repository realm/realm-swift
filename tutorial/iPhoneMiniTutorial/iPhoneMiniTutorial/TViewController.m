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
    TightdbSharedGroup *sharedGroup = [TightdbSharedGroup sharedGroupWithFile:filename withError:nil];

    // Perform a write transaction
    [sharedGroup writeWithBlock:^(TightdbGroup *group) {

        // Access table from group
        TightdbTable *table = [group getOrCreateTableWithName:@"myTable" error:nil];

        // Add columns to the table
        [table addColumnWithName:@"Name" andType:tightdb_String];
        [table addColumnWithName:@"Age" andType:tightdb_Int];
       
        // Add a row to the table
        [table appendRow:@[@"Jill", @21]];

        // Add a new column
        int const HIRED = [table addColumnWithName:@"Hired" andType:tightdb_Bool];

        // Add another row
        [table appendRow:@[@"Mary", @40, @NO]];

        // Change value in row
        TightdbCursor *row = [table rowAtIndex:0];
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
