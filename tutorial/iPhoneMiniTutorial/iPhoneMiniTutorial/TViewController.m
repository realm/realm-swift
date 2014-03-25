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
    TDBContext *context = [TDBContext contextWithPersistenceToFile:filename error:nil];

    // Perform a write transaction
    [context writeWithBlock:^(TDBTransaction *transaction) {

        // Access table from group
        TDBTable *table = [transaction createTableWithName:@"myTable"];

        // Add columns to the table
        [table addColumnWithName:@"Name" andType:TDBStringType];
        [table addColumnWithName:@"Age" andType:TDBIntType];
       
        // Add a row to the table using a NSDictionary
        [table addRow:@{@"Name": @"Jill", @"Age": @21}];

        // Add a new column dynamically
        int const HIRED = [table addColumnWithName:@"Hired" andType:TDBBoolType];

        // Add another row using a NSArray
        [table addRow:@[@"Mary", @40, @NO]];

        // Change value in row
        TDBRow *row = [table rowAtIndex:0];
        [row setBool:YES inColumnWithIndex:HIRED];

        // Remove row from table
        [table removeRowAtIndex:0];

        // Print out info on iPhone screen
        self.columnCountOutlet.text = [NSString stringWithFormat:@"# of columns: %i", table.columnCount];
        self.sizeOutlet.text = [NSString stringWithFormat:@"# of rows: %i", table.rowCount];

        return YES;
    } error:nil];
}

- (NSString*)writeablePathForFile:(NSString*)fileName
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}


@end
