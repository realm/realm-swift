//
//  RLMBPaneViewController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 21/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBPaneViewController.h"

@interface RLMBPaneViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic) NSDictionary *properties;

@property (weak) IBOutlet NSTextField *classNameLabel;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic) RLMBViewModel *formatter;

@property (nonatomic) RLMObjectSchema *objectSchema;

@end


@implementation RLMBPaneViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.formatter = [[RLMBViewModel alloc] initWithOwner:self];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *cellNibNames = @[kRLMBGutterCellId, kRLMBBasicCellId, kRLMBLinkCellId, kRLMBBoolCellId, kRLMBNumberCellId];
    [self registerCellNibsNamed:cellNibNames inTableView:self.tableView];
}

#pragma mark - Public Methods

- (void)updateWithObjects:(id<RLMCollection>)objects objectSchema:(RLMObjectSchema *)objectSchema
{
    self.objectSchema = objectSchema;
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    for (RLMProperty *property in objectSchema.properties) {
        properties[property.name] = property;
    }
    self.properties = properties;
    
    self.objects = objects;
    self.classNameLabel.stringValue = objectSchema.className;
    [self setupColumnsWithProperties:objectSchema.properties];
    
    [self.tableView reloadData];
}

#pragma mark - User Actions

- (IBAction)editedCheckBox:(NSButton *)sender
{
    NSInteger row = [self.tableView rowForView:sender];
    NSInteger column = [self.tableView columnForView:sender];
    
    NSTableColumn *tableColumn = self.tableView.tableColumns[column];
    NSNumber *value = @((BOOL)(sender.state == NSOnState));

    [self.realmDelegate changeProperty:tableColumn.identifier ofObject:self.objects[row] toValue:value];
}

#pragma mark - Text Field Delegate

-(BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
//    NSLog(@"text should begin editing: %@ -  %@", control, fieldEditor);
    return YES;
}

//-(void)controlDidBecomeFirstResponder {
//    NSLog(@"controlTextDidBeginEditing  %@", obj);
//}

#pragma mark - Public Methods - Table View Update

- (void)setupColumnsWithProperties:(NSArray *)properties
{
    NSTableView *tableView = self.tableView;
    
    while (tableView.numberOfColumns > 0) {
        [tableView removeTableColumn:[tableView.tableColumns lastObject]];
    }
    
    [tableView reloadData];
    
    [tableView beginUpdates];

    NSTableColumn *gutterColumn = [[NSTableColumn alloc] initWithIdentifier:kRLMBGutterColumnIdentifier];
    [gutterColumn.headerCell setStringValue:@"#"];
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
        tableColumn.identifier = property.name;
        NSString *typeName = [RLMBViewModel typeNameForProperty:property];
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
    if ([tableColumn.identifier isEqualToString:kRLMBGutterColumnIdentifier]) {
        return [self.formatter cellViewForGutter:tableView row:row];
    }
    
    id value = self.objects[row][tableColumn.identifier];
    RLMProperty *property = self.properties[tableColumn.identifier];
    
    return [self.formatter tableView:tableView cellViewForValue:value type:property.type];
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
    if (column > self.properties.count) {
        return;
    }
    
    NSTableColumn *tableColumn = self.tableView.tableColumns[column];
    RLMProperty *property = self.properties[tableColumn.identifier];
    id propertyValue = self.objects[row][property.name];
    
    if (property.type == RLMPropertyTypeObject) {
//        RLMObject *linkedObject = (RLMObject *)propertyValue;
//        RLMObjectSchema *linkedObjectSchema = linkedObject.objectSchema;
    }
    else if (property.type == RLMPropertyTypeArray) {
        [self.canvasDelegate addPaneWithArray:propertyValue afterPane:self];
    }
}

#pragma mark - Helper Methods - Table View Setup

- (void)registerCellNibsNamed:(NSArray *)cellNibNames inTableView:(NSTableView *)tableView
{
    for (NSString *cellNibName in cellNibNames) {
        NSNib *cellNib = [[NSNib alloc] initWithNibNamed:cellNibName bundle:nil];
        [tableView registerNib:cellNib forIdentifier:cellNibName];
    }
}

#pragma mark - Public Methods - Getters

-(BOOL)isWide
{
    return self.widthConstraint.multiplier > 0.75;
}

@end













