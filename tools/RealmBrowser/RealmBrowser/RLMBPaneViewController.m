//
//  RLMBPaneViewController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 21/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBPaneViewController.h"

@interface RLMBPaneViewController () <NSTableViewDataSource, NSTableViewDelegate>

@end


@implementation RLMBPaneViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.formatter = [RLMBFormatter new];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)updateWithObjects:(id<RLMCollection>)objects objectSchema:(RLMObjectSchema *)objectSchema
{
    self.objectSchema = objectSchema;
    self.objects = objects;
    self.classNameLabel.stringValue = objectSchema.className;
    [self setupColumnsWithProperties:objectSchema.properties];
    
    [self.tableView reloadData];
    NSLog(@"objects: %lu", [(id)self.objects count]);
}

#pragma mark - Table View Setup

- (void)setupColumnsWithProperties:(NSArray *)properties
{
    NSTableView *tableView = self.tableView;
    
    while (tableView.numberOfColumns > 0) {
        [tableView removeTableColumn:[tableView.tableColumns lastObject]];
    }
    
    [tableView reloadData];
    
    [tableView beginUpdates];
    // If array, add extra first column with numbers
    //    if ([typeNode isMemberOfClass:[RLMArrayNode class]]) {
    //        RLMTableColumn *tableColumn = [[RLMTableColumn alloc] initWithIdentifier:@"#"];
    //        tableColumn.propertyType = RLMPropertyTypeInt;
    //
    //        RLMTableHeaderCell *headerCell = [[RLMTableHeaderCell alloc] init];
    //        headerCell.wraps = YES;
    //        headerCell.firstLine = @"";
    //        headerCell.secondLine = @"#";
    //        tableColumn.headerCell = headerCell;
    //
    //        tableColumn.headerToolTip = @"Order of object within array";
    //
    //        [self addTableColumn:tableColumn];
    //    }
    
    // ... and add new columns matching the structure of the new realm table.
    
    for (RLMProperty *property in properties) {
        NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:property.name];
        NSString *typeName = [self.formatter typeNameForProperty:property];
        tableColumn.title = [NSString stringWithFormat:@"%@: %@", property.name, typeName];
        [tableView addTableColumn:tableColumn];
    }
    
    [tableView endUpdates];
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [(id)self.objects count];
}

#pragma mark - Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSUInteger column = [tableView.tableColumns indexOfObject:tableColumn];
    RLMObject *object = self.objects[row];
    RLMProperty *property = self.objectSchema.properties[column];
    
    return [self.formatter tableView:tableView cellViewForValue:object[property.name] type:property.type];
    
    //    NSInteger propertyIndex = [self propertyIndexForColumn:column];
    //
    //    // Array gutter
    //    if (propertyIndex == -1) {
    //        RLMBasicTableCellView *basicCellView = [tableView makeViewWithIdentifier:@"IndexCell" owner:self];
    //        basicCellView.textField.stringValue = [@(rowIndex) stringValue];
    //        basicCellView.textField.editable = NO;
    //
    //        return basicCellView;
    //    }
}
- (IBAction)userClicked:(NSTableView *)sender
{
    if (self.tableView.selectedRowIndexes.count > 1) {
        return;
    }
    
    NSInteger row = self.tableView.clickedRow;
    if (row >= [(id)self.objects count]) {
        return;
    }
    
    NSInteger column = self.tableView.clickedColumn;
    if (column >= self.objectSchema.properties.count) {
        return;
    }

    NSLog(@"clicked: %lu,%lu", row, column);
    
    NSInteger propertyIndex = column;
    
    RLMProperty *property = self.objectSchema.properties[propertyIndex];
    
    RLMObject *object = self.objects[row];
    id propertyValue = object[property.name];
    
    if (property.type == RLMPropertyTypeObject) {
        RLMObject *linkedObject = (RLMObject *)propertyValue;
        RLMObjectSchema *linkedObjectSchema = linkedObject.objectSchema;
        
        //            for (RLMClassNode *classNode in self.parentWindowController.modelDocument.presentedRealm.topLevelClasses) {
        //                if ([classNode.name isEqualToString:linkedObjectSchema.className]) {
        //                    RLMResults *allInstances = [linkedObject.realm allObjects:linkedObjectSchema.className];
        //                    NSUInteger objectIndex = [allInstances indexOfObject:linkedObject];
        //
        //                    RLMNavigationState *state = [[RLMNavigationState alloc] initWithSelectedType:classNode index:objectIndex];
        //                    [self.parentWindowController addNavigationState:state fromViewController:self];
        //
        //                    break;
        //                }
        //            }
    }
    else if (property.type == RLMPropertyTypeArray) {
        RLMArray *linkedArray = (RLMArray *)propertyValue;
        RLMObjectSchema *linkedObjectSchema = [linkedArray.realm.schema schemaForClassName:linkedArray.objectClassName];
        RLMBPaneViewController *pane = [self.canvasDelegate addPaneAfterPane:self];
        [pane updateWithObjects:linkedArray objectSchema:linkedObjectSchema];
    }
}

@end













