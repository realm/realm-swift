////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMBPaneViewController.h"

#import "RLMBViewModel.h"
#import "RLMBBoolCellView.h"
#import "RLMBLinkCellView.h"

NSString *const kRLMBGutterColumnIdentifier = @" #";
NSString *const kRLMBGutterCellId = @"RLMBGutterCellView";
NSString *const kRLMBBasicCellId = @"RLMBBasicCellView";
NSString *const kRLMBLinkCellId = @"RLMBLinkCellView";
NSString *const kRLMBBoolCellId = @"RLMBBoolCellView";

@interface RLMBPaneViewController () <RLMBTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic) NSDictionary *properties;

@property (weak) IBOutlet NSTextField *classNameLabel;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic) RLMBViewModel *viewModel;

@property (nonatomic) NSTableColumn *openColumn;
@property (nonatomic) NSUInteger openRow;

@end


@implementation RLMBPaneViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.viewModel = [[RLMBViewModel alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *cellNibNames = @[kRLMBGutterCellId, kRLMBBasicCellId, kRLMBLinkCellId, kRLMBBoolCellId];
    [self registerCellNibsNamed:cellNibNames inTableView:self.tableView];
}

#pragma mark - Public Methods

- (void)updateWithObjects:(id<RLMCollection>)objects objectSchema:(RLMObjectSchema *)objectSchema
{
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

    [self.realmDelegate setProperty:tableColumn.identifier ofObject:self.objects[row] toValue:value];
}

#pragma mark - RLMB Text Field Delegate

-(void)textFieldWasSelected:(NSTextField *)textField
{
    NSLog(@"textFieldWasSelected: %@", textField);

    NSInteger row = [self.tableView rowForView:textField];
    NSInteger column = [self.tableView columnForView:textField];
    NSTableColumn *tableColumn = self.tableView.tableColumns[column];
    
    RLMProperty *property = self.properties[tableColumn.identifier];
    id value = self.objects[row][tableColumn.identifier];
    
    NSString *editableString = [self.viewModel editablePropertyValue:value type:property.type];
    if (editableString) {
        textField.stringValue = editableString;
    }
}

-(void)textFieldDidCancelEditing:(NSTextField *)textField
{
    NSLog(@"textFieldDidCancelEditing: %@", textField);
    
    [self.tableView reloadData];
}

-(IBAction)textFieldDidEndEditing:(NSTextField *)textField
{
    NSLog(@"textFieldDidEndEditing: %@", textField);
    NSInteger row = [self.tableView rowForView:textField];
    NSInteger column = [self.tableView columnForView:textField];
    
    NSTableColumn *tableColumn = self.tableView.tableColumns[column];
    RLMProperty *property = self.properties[tableColumn.identifier];
    
    id value = [self.viewModel valueForString:textField.stringValue type:property.type];

    if (value) {
        [self.realmDelegate setProperty:property.name ofObject:self.objects[row] toValue:value];
    }
    
    [self.tableView reloadData];
}

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
    if (self.isArrayPane) {
        gutterColumn.headerToolTip = @"Order of object within array";
        [gutterColumn.headerCell setStringValue:@"#"];
        gutterColumn.width = 20;
    }
    else {
        [gutterColumn.headerCell setStringValue:@""];
        gutterColumn.width = 0;
    }

    [self.tableView addTableColumn:gutterColumn];
    
    for (RLMProperty *property in properties) {
        NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:property.name];
        tableColumn.identifier = property.name;
        [tableColumn.headerCell setAttributedStringValue:[RLMBViewModel headerStringForProperty:property]];
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
        NSTableCellView *gutterCellView = [self.tableView makeViewWithIdentifier:kRLMBGutterCellId owner:self];
        gutterCellView.textField.stringValue = self.isArrayPane ? @(row).stringValue : @"";
        
        return gutterCellView;
    }
    
    id value = self.objects[row][tableColumn.identifier];
    RLMProperty *property = self.properties[tableColumn.identifier];
    
    switch (property.type) {
        case RLMPropertyTypeArray: {
            RLMBLinkCellView *badgeCellView = [self.tableView makeViewWithIdentifier:kRLMBLinkCellId owner:self];
            badgeCellView.textField.stringValue = [self.viewModel printableArray:value];
            badgeCellView.isOpen = (tableColumn == self.openColumn && row == self.openRow);

            //            badgeCellView.badge.hidden = NO;
            //            badgeCellView.badge.title = [NSString stringWithFormat:@"%lu", [(RLMArray *)propertyValue count]];
            //            [badgeCellView.badge.cell setHighlightsBy:0];
            //            [badgeCellView sizeToFit];
            
            return badgeCellView;
        }
        case RLMPropertyTypeObject: {
            RLMBLinkCellView *linkCellView = [self.tableView makeViewWithIdentifier:kRLMBLinkCellId owner:self];
            //            linkCellView.dragType = [self dragTypeForClassName:classProperty.property.objectClassName];
            //            linkCellView.delegate = self;
            
            linkCellView.isOpen = (tableColumn == self.openColumn && row == self.openRow);
            linkCellView.textField.stringValue = [self.viewModel printableObject:value];
            
            return linkCellView;
        }
        case RLMPropertyTypeBool: {
            RLMBBoolCellView *boolCellView = [self.tableView makeViewWithIdentifier:kRLMBBoolCellId owner:self];
            boolCellView.checkBox.state = [(NSNumber *)value boolValue] ? NSOnState : NSOffState;
            
            return boolCellView;
        }
        case RLMPropertyTypeData:
        case RLMPropertyTypeAny:
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeString: {
            NSTableCellView *basicCellView = [self.tableView makeViewWithIdentifier:kRLMBBasicCellId owner:self];
            basicCellView.textField.stringValue = [self.viewModel printablePropertyValue:value type:property.type];
            if (property.type == RLMPropertyTypeData || property.type == RLMPropertyTypeArray) {
                basicCellView.textField.editable = NO;
            }
            
            return basicCellView;
        }
    }
}

#pragma mark - User Actions

- (IBAction)toggleWidthAction:(NSButton *)sender {
    [self minusRows:self.tableView.selectedRowIndexes];
    [self.tableView reloadData];

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
    if (column == 0 || column > self.properties.count) {
        return;
    }
    
    NSTableColumn *tableColumn = self.tableView.tableColumns[column];
    RLMProperty *property = self.properties[tableColumn.identifier];
    
    id propertyValue = self.objects[row][property.name];
    
    if (property.type == RLMPropertyTypeObject) {
        [self.canvasDelegate addPaneWithObject:propertyValue afterPane:self];
    }
    else if (property.type == RLMPropertyTypeArray) {
        [self.canvasDelegate addPaneWithArray:propertyValue afterPane:self];
    }
    
    if (property.type == RLMPropertyTypeObject || property.type == RLMPropertyTypeArray) {
        self.openColumn = tableColumn;
        self.openRow = row;
        [self.tableView reloadData];
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

- (void)minusRows:(NSIndexSet *)rowIndexes
{
    // Implemented in subclass according to type of pane
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    NSLog(@"validateToolbarItem: %ld", theItem.tag);

    return theItem.tag % 2;
}

- (IBAction)editAction:(id)sender
{
    NSLog(@"sender: %@", sender);

}

#pragma mark - Public Methods - Getters

- (BOOL)isWide
{
    return self.widthConstraint.multiplier > 0.75;
}

- (BOOL)isRootPane
{
    return NO;
}

- (BOOL)isArrayPane
{
    return NO;
}

- (BOOL)isObjectPane
{
    return NO;
}

@end













