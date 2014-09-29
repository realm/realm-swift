//
//  RLMPopupViewController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 29/09/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMPopupViewController.h"
#import "RLMDescriptions.h"

#import "RLMPopupWindow.h"

#import "RLMTableColumn.h"
#import "RLMArrayNode.h"

#import "RLMBadgeTableCellView.h"
#import "RLMBasicTableCellView.h"
#import "RLMBoolTableCellView.h"
#import "RLMNumberTableCellView.h"
#import "RLMImageTableCellView.h"

@interface RLMPopupViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic) RLMDescriptions *realmDescriptions;
@property (nonatomic) IBOutlet NSTableView *tableView;
@property (nonatomic) RLMArrayNode *arrayNode;

@end


@implementation RLMPopupViewController

-(void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setupColumnsWithArrayNode:(RLMArrayNode *)arrayNode fromWindow:(NSWindow *)window
{
    [self loadView];
    self.arrayNode = arrayNode;

    while (self.tableView.numberOfColumns > 0) {
        [self.tableView removeTableColumn:[self.tableView.tableColumns lastObject]];
    }
    
    [self.tableView beginUpdates];
    self.realmDescriptions = [[RLMDescriptions alloc] init];

    // If array, add extra first column with numbers
    RLMTableColumn *tableColumn = [[RLMTableColumn alloc] initWithIdentifier:@"#"];
    tableColumn.propertyType = RLMPropertyTypeInt;
    [self.tableView addTableColumn:tableColumn];
    [tableColumn.headerCell setStringValue:@"#"];
    
    // ... and add new columns matching the structure of the new realm table.
    NSArray *propertyColumns = arrayNode.propertyColumns;
    
    for (NSUInteger index = 0; index < propertyColumns.count; index++) {
        RLMClassProperty *propertyColumn = propertyColumns[index];

        RLMTableColumn *tableColumn = [[RLMTableColumn alloc] initWithIdentifier:propertyColumn.name];
        tableColumn.propertyType = propertyColumn.type;
        [self.tableView addTableColumn:tableColumn];
        [tableColumn.headerCell setStringValue:propertyColumn.name];
    }
    
    [self.tableView endUpdates];

    RLMPopupWindow *popupWindow = [[RLMPopupWindow alloc] initWithView:self.view
                                                               atPoint:NSMakePoint(200, 200)
                                                              inWindow:self.tableView.window];
    [window addChildWindow:popupWindow ordered:NSWindowAbove];
}

#pragma mark - NSTableView Delegate

-(CGFloat)tableView:(NSTableView *)tableView sizeToFitWidthOfColumn:(NSInteger)column
{
    RLMTableColumn *tableColumn = self.tableView.tableColumns[column];
    return [tableColumn sizeThatFitsWithLimit:NO];
}

#pragma mark - NSTableView Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.arrayNode.instanceCount;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    NSUInteger column = [tableView.tableColumns indexOfObject:tableColumn];
    NSInteger propertyIndex = column - 1;
    
    // Array gutter
    if (propertyIndex == -1) {
        RLMBasicTableCellView *basicCellView = [tableView makeViewWithIdentifier:@"IndexCell" owner:self];
        basicCellView.textField.stringValue = [@(rowIndex) stringValue];
        basicCellView.textField.editable = NO;
        
        return basicCellView;
    }
    
    RLMClassProperty *classProperty = self.arrayNode.propertyColumns[propertyIndex];
    RLMObject *selectedInstance = [self.arrayNode instanceAtIndex:rowIndex];
    id propertyValue = selectedInstance[classProperty.name];
    RLMPropertyType type = classProperty.type;
    
    switch (type) {
        case RLMPropertyTypeArray: {
            RLMBadgeTableCellView *badgeCellView = [tableView makeViewWithIdentifier:@"BadgeCell" owner:self];
            badgeCellView.textField.stringValue = [self.realmDescriptions printablePropertyValue:propertyValue ofType:type];
            badgeCellView.textField.editable = NO;
            badgeCellView.badge.hidden = NO;
            badgeCellView.badge.title = [NSString stringWithFormat:@"%lu", [(RLMArray *)propertyValue count]];
            
            return badgeCellView;
        }
        case RLMPropertyTypeBool: {
            RLMBoolTableCellView *boolCellView = [tableView makeViewWithIdentifier:@"BoolCell" owner:self];
            boolCellView.checkBox.state = [(NSNumber *)propertyValue boolValue] ? NSOnState : NSOffState;
            [boolCellView.checkBox setEnabled:NO];
            
            return boolCellView;
        }
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble: {
            RLMNumberTableCellView *numberCellView = [tableView makeViewWithIdentifier:@"NumberCell" owner:self];
            numberCellView.textField.stringValue = [self.realmDescriptions printablePropertyValue:propertyValue ofType:type];
            numberCellView.textField.editable = NO;
            
            return numberCellView;
        }
        case RLMPropertyTypeObject: {
            RLMLinkTableCellView *linkCellView = [tableView makeViewWithIdentifier:@"LinkCell" owner:self];
            linkCellView.textField.stringValue = [self.realmDescriptions printablePropertyValue:propertyValue ofType:type];
            linkCellView.textField.editable = NO;
            
            return linkCellView;
        }
        case RLMPropertyTypeData:
        case RLMPropertyTypeAny:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeString: {
            RLMBasicTableCellView *basicCellView = [tableView makeViewWithIdentifier:@"BasicCell" owner:self];
            basicCellView.textField.stringValue = [self.realmDescriptions printablePropertyValue:propertyValue ofType:type];
            basicCellView.textField.editable = NO;
            
            return basicCellView;
        }
        default:
            return nil;
    }
}


@end
