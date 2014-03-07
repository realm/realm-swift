#import "TViewController.h"
#import <Tightdb/Tightdb.h>

@interface TViewController ()
@end

@implementation TViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create a data file
    TightdbSharedGroup *sharedGroup = [TightdbSharedGroup sharedGroupWithFile:[self writeablePathForFile: @"MyDatabase.db"] withError:nil];

    // Perform a write transaction
    [sharedGroup writeWithBlock:^(TightdbGroup *group) {
        
        // Access table from group
        TightdbTable *table = [group getTable:@"myTable" error:nil];
        
        // Add columns to the table
        int const NAME  = [table addColumnWithType:tightdb_String andName:@"Name"];
        int const AGE   = [table addColumnWithType:tightdb_Int    andName:@"Age"];
        int const HIRED = [table addColumnWithType:tightdb_Bool   andName:@"Hired"];
        
        // Add two rows to the table
        [table appendRow:@[@"Jill", @21, @YES]];
        [table appendRow:@[@"Mary", @40, @NO]];
      
        // Change value in row
        TightdbCursor *cursor = [table cursorAtIndex:0];
        [cursor setBool:NO inColumn:HIRED];
        
        // Remove row from table
        [table removeRowAtIndex:1];

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
