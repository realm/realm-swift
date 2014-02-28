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

-(void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    return [self todoCount];
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
- (IBAction)refresh:(id)sender {
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath   *)indexPath
{
    
    BOOL isCompletedBeforeClicking = [self getTodoCompletedStatus:indexPath.row];
    
    TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    [delegate.sharedGroup writeWithBlock:^(TightdbGroup *tnx) {
        
        TightdbTable *todoTable = [tnx getTable:@"todos" error:nil];
        
        [todoTable setBool:!isCompletedBeforeClicking inColumn:1 atRow:indexPath.row];
        
        return YES;
    } withError:nil];
    
    if(isCompletedBeforeClicking) {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;

    } else {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;

    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];


}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView beginUpdates];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"deleting row");
        // Do whatever data deletion you need to do...
        [self deleteTodo:indexPath.row];
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationRight ];
    }

    [tableView endUpdates];
}

-(void) deleteTodo:(NSInteger)rowIndex
{
    TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    [delegate.sharedGroup writeWithBlock:^(TightdbGroup *tnx) {
        
        TightdbTable *todoTable = [tnx getTable:@"todos" error:nil];
        
        [todoTable removeRowAtIndex:rowIndex];
        
        
        return YES;
    } withError:nil];
    
    [self setEditing:NO animated:NO];
    
    //[self.tableView setEditing:NO animated:YES];
    //self.navigationItem.leftBarButtonItem = nil;
    
}


-(NSString *) getTodoNameForRow:(NSInteger)rowIndex
{
    __block  NSString *todoName = nil;
    TAppDelegate* delegate = (TAppDelegate*)[[UIApplication sharedApplication]delegate];
    
    [delegate.sharedGroup readWithBlock:^(TightdbGroup *tnx) {
        
        TightdbTable *todoTable = [tnx getTable:@"todos" error:nil];
        
        todoName = [todoTable getStringInColumn:0 atRow:rowIndex];
    }];
    
    return todoName;
}

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


-(NSInteger) todoCount

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



@end
