//
//  RLMResultsNode.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 19/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMResultsNode.h"
#import "RLMSidebarTableCellView.h"

@implementation RLMResultsNode {
    RLMResults *displayedResults;
    NSString *name;
}

- (instancetype)initWithQuery:(NSString *)searchText result:(RLMResults *)result andParent:(RLMTypeNode *)classNode
{
    if (self = [super initWithSchema:classNode.schema inRealm:classNode.realm]) {
        displayedResults = result;
        name = searchText;
    }
    
    return self;
}

- (NSView *)cellViewForTableView:(NSTableView *)tableView
{
    RLMSidebarTableCellView *cellView = [tableView makeViewWithIdentifier:@"MainCell" owner:self];
    if (name) {
        cellView.textField.stringValue = [NSString stringWithFormat:@"\"%@\"", name];
    }
    
    cellView.button.title = [NSString stringWithFormat:@"%lu", [self instanceCount]];
    [[cellView.button cell] setHighlightsBy:0];
    cellView.button.hidden = NO;
    
    return cellView;
}

- (NSUInteger)instanceCount
{
    return displayedResults.count;
}

- (RLMObject *)instanceAtIndex:(NSUInteger)index
{
    return displayedResults[index];
}


@end
