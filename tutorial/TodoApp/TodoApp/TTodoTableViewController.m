#import "TTodoTableViewController.h"
#import "TAppDelegate.h"

@interface TTodoTableViewController ()

@end

@implementation TTodoTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
     self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    
    
}

// Implement this method, so that when add todo modal disappears, the todolist will be updated
-(void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    __block NSInteger rows = 0;
    TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    [delegate.sharedGroup readWithBlock:^(TightdbGroup *tnx) {
        
        TightdbTable *todoTable = [tnx getTable:@"todos" error:nil];
        
        size_t count = [todoTable count];
        
        rows = count;
    }];
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Todo";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.textLabel.text = [self getTodoNameForRow:indexPath.row];
    
    _Bool completed = [self getTodoCompletedStatus:indexPath.row];
    
    if(completed) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;

    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;

    }
    
    return cell;
}

// When a row is selected, either checkout the row or uncheck
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath   *)indexPath
{
    
    BOOL isCompletedBeforeClicking = [self getTodoCompletedStatus:indexPath.row];
    
    TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    [delegate.sharedGroup writeWithBlock:^(TightdbGroup *tnx) {
        TightdbTable *todoTable = [tnx getTable:@"todos" error:nil];
        [todoTable setBool:!isCompletedBeforeClicking inColumn:1 atRow:indexPath.row];
        
        return YES;
    } withError:nil];
    
    // Check the completed status before the row was clicked
    if(isCompletedBeforeClicking) {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
    } else {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// Method handling when a row is deleted
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView beginUpdates];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Update the model
        [self deleteTodo:indexPath.row];
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationRight ];
    }

    // Exit edit mode
    [tableView endUpdates];
    [self setEditing:NO animated:NO];
}

// Delete a particular row
-(void) deleteTodo:(NSInteger)rowIndex
{
    TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    [delegate.sharedGroup writeWithBlock:^(TightdbGroup *tnx) {
        TightdbTable *todoTable = [tnx getTable:@"todos" error:nil];
        [todoTable removeRowAtIndex:rowIndex];
        
        return YES;
    } withError:nil];
}


// Returns the name of specific row
-(NSString *) getTodoNameForRow:(NSInteger)rowIndex
{
    __block NSString *todoName = nil;
    TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    [delegate.sharedGroup readWithBlock:^(TightdbGroup *tnx) {
        TightdbTable *todoTable = [tnx getTable:@"todos" error:nil];
        todoName = [todoTable getStringInColumn:0 atRow:rowIndex];
    }];
    
    return todoName;
}

// Get the status of a particular todo completed status
-(BOOL) getTodoCompletedStatus:(NSInteger)rowIndex
{
    __block  BOOL completed = NO;
    TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    [delegate.sharedGroup readWithBlock:^(TightdbGroup *tnx) {
        TightdbTable *todoTable = [tnx getTable:@"todos" error:nil];
        completed = [todoTable getBoolInColumn:1 atRow:rowIndex];
    }];
    
    return completed;
}


@end
