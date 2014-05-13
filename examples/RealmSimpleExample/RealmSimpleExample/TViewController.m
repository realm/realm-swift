#import "TViewController.h"
#import <Realm/Realm.h>

@interface TViewController ()
@end

@implementation TViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Remove old file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [TViewController writeablePathForFile:@"default.realm"];
    [fileManager removeItemAtPath:path error:nil];
    
    // Create default realm
    RLMRealm *realm = [RLMRealm defaultRealm];

    // Perform a write transaction
    [realm writeUsingBlock:^(RLMRealm *realm) {

        // Access table from group
        RLMTable *table = [realm createTableWithName:@"myTable"];

        // Add columns to the table
        [table addColumnWithName:@"name" type:RLMTypeString];
        [table addColumnWithName:@"age" type:RLMTypeInt];
       
        // Add a row to the table using a NSDictionary
        [table addRow:@{@"Name": @"Jill", @"Age": @21}];

        // Add a new column dynamically
        [table addColumnWithName:@"hired" type:RLMTypeBool];

        // Add another row using a NSArray
        [table addRow:@[@"Mary", @40, @NO]];

        // Change value in row
        table[0][@"hired"] = @YES;

        // Remove row from table
        [table removeRowAtIndex:0];

        // Print out info on iPhone screen
        self.columnCountOutlet.text = [NSString stringWithFormat:@"Columns: %lu", (unsigned long)table.columnCount];
        self.rowCountOutlet.text = [NSString stringWithFormat:@"Rows: %lu", (unsigned long)table.rowCount];
    }];
}

+ (NSString *)writeablePathForFile:(NSString*)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

@end
