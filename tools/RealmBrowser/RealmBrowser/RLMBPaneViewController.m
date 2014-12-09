//
//  RLMBPaneViewController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 21/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBPaneViewController.h"

#define GUTTER_COLUMN -1

@interface RLMBPaneViewController () <NSTableViewDataSource, NSTableViewDelegate>

@end


@implementation RLMBPaneViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.formatter = [[RLMBFormatter alloc] initWithOwner:self];
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

    NSTableColumn *gutterColumn = [[NSTableColumn alloc] initWithIdentifier:@"#"];
    gutterColumn.width = 30;
    
//    NSTableHeaderCell *headerCell = gutterColumn.headerCell;
//    headerCell.wraps = YES;
//    headerCell.firstLine = @"";
//    headerCell.secondLine = @"#";
//    tableColumn.headerCell = headerCell;

//    gutterColumn.headerToolTip = @"Order of object within array";
    
    [self.tableView addTableColumn:gutterColumn];
    
    for (RLMProperty *property in properties) {
        NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:property.name];
        NSString *typeName = [self.formatter typeNameForProperty:property];
        [tableColumn.headerCell setStringValue:[NSString stringWithFormat:@"%@: %@", property.name, typeName]];
        [tableView addTableColumn:tableColumn];
    }
    
    [tableView endUpdates];
}

#pragma mark - Table View Datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.objects.count;
}

#pragma mark - Table View Delegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSUInteger column = [self indexOfColumn:tableColumn inTable:tableView];
    
    if (column == GUTTER_COLUMN) {
        return [self.formatter cellViewForGutter:tableView];
    }
    
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

-(NSUInteger)indexOfColumn:(NSTableColumn *)column inTable:(NSTableView *)tableView
{
    NSUInteger index = [tableView.tableColumns indexOfObject:column];

    return index - 1;
}

#pragma mark - User Actions

- (IBAction)toggleWidthAction:(NSButton *)sender {
//    [self.canvasDelegate toggleWidthOfPane:self];
}

- (IBAction)userClicked:(NSTableView *)sender
{
    if (self.tableView.selectedRowIndexes.count > 1) {
        return;
    }
    
    NSInteger row = self.tableView.clickedRow;
    if (row >= self.objects.count) {
        return;
    }
    
    NSInteger column = self.tableView.clickedColumn;
    if (column >= self.objectSchema.properties.count) {
        return;
    }

    NSInteger propertyIndex = column;
    
    RLMProperty *property = self.objectSchema.properties[propertyIndex];
    id propertyValue = self.objects[row][property.name];
    
    if (property.type == RLMPropertyTypeObject) {
//        RLMObject *linkedObject = (RLMObject *)propertyValue;
//        RLMObjectSchema *linkedObjectSchema = linkedObject.objectSchema;
    }
    else if (property.type == RLMPropertyTypeArray) {
        [self.canvasDelegate addPaneWithArray:propertyValue afterPane:self];
    }
}

#pragma mark - Public Methods - Getters

-(BOOL)isWide
{
    return self.widthConstraint.multiplier > 0.75;
}

@end













