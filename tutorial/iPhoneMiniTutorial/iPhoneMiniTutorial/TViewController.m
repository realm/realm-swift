#import "TViewController.h"
#import <Tightdb/Tightdb.h>

@interface TViewController ()

@end

@implementation TViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Create a free-standing table
    TightdbTable *table = [[TightdbTable alloc] init];
    
    // Add columns to the table
    size_t const NAME = [table addColumnWithType:tightdb_String andName:@"Name"];
    size_t const AGE = [table addColumnWithType:tightdb_Int andName:@"Age"];
    size_t const HIRED = [table addColumnWithType:tightdb_Bool andName:@"Hired"];
  
    // Add new row to the table and set values
    TightdbCursor *cursor0 = [table addEmptyRow];
    [cursor0 setString:@"Jill" inColumn:NAME];
    [cursor0 setInt: 21 inColumn:AGE];
    [cursor0 setBool:YES inColumn:HIRED];
    
    // Add one more row and set values
    TightdbCursor *cursor1 = [table addEmptyRow];
    [cursor1 setString:@"Mary" inColumn:NAME];
    [cursor1 setInt: 40 inColumn:AGE];
    [cursor1 setBool:NO inColumn:HIRED];
    
    // Change value in row
    [cursor1 setBool:YES inColumn:HIRED];
    
    // Remove row from table
    [table removeRowAtIndex:cursor1.index];
    cursor1 = nil;
    
    // Print out info on iPhone screen
    self.tableColumnCountOutlet.text = [NSString stringWithFormat:@"Number of columns in table: %zu", [table getColumnCount]];
    self.tableSizeOutlet.text = [NSString stringWithFormat:@"Number of rows in table: %zu", [table count]];
}

@end
