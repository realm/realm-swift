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
        TightdbTable *table = [group getTable:@"myTable" error:nil];

        // Add columns to the table
        [table addColumnWithType:tightdb_String andName:@"Name"];
        [table addColumnWithType:tightdb_Int    andName:@"Age"];
       
        // Add a row to the table
        [table appendRow:@[@"Jill", @21]];

        // Add a new column
        int const HIRED = [table addColumnWithType:tightdb_Bool andName:@"Hired"];

        // Add another row
        [table appendRow:@[@"Mary", @40, @NO]];

        // Change value in row
        TightdbCursor *cursor = [table cursorAtIndex:0];
        [cursor setBool:YES inColumn:HIRED];

        // Remove row from table
        [table removeRowAtIndex:0];

        // Print out info on iPhone screen
        self.tableColumnCountOutlet.text = [NSString stringWithFormat:@"# of columns: %zu", [table getColumnCount]];
        self.tableSizeOutlet.text = [NSString stringWithFormat:@"# of rows: %zu", [table count]];

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
