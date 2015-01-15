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

#import "RLMTypeOutlineViewController.h"

#import "RLMRealmBrowserWindowController.h"
#import "RLMRealmOutlineNode.h"
#import "RLMArrayNavigationState.h"
#import "RLMQueryNavigationState.h"
#import "RLMObjectNode.h"
#import "RLMResultsNode.h"
#import "RLMRealmOutlineNode.h"

@interface RLMTypeOutlineViewController ()

@property (nonatomic, strong) IBOutlet NSOutlineView *classesOutlineView;

@end

@implementation RLMTypeOutlineViewController

#pragma mark - RLMViewController overrides

-(void)realmDidLoad
{
    [self.classesOutlineView reloadData];
    // Expand the root item representing the selected realm.
    RLMRealmNode *firstItem = self.parentWindowController.modelDocument.presentedRealm;
    if (firstItem != nil) {
        // We want the class outline to be expanded as default
        [self.classesOutlineView expandItem:firstItem expandChildren:YES];
    }
}

#pragma mark - NSOutlineViewDataSource implementation

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return self.parentWindowController.modelDocument.presentedRealm;
    }
    // ... and second level nodes are all classes.
    else if ([item conformsToProtocol:@protocol(RLMRealmOutlineNode)]) {
        id<RLMRealmOutlineNode> outlineItem = item;
        
        return [outlineItem childNodeAtIndex:index];
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    // The root node is expandable if we are presenting a realm
    if (item == nil) {
        return self.parentWindowController.modelDocument.presentedRealm == nil;
    }
    // ... otherwise the exandability check is re-delegated to the node in question.
    else if ([item conformsToProtocol:@protocol(RLMRealmOutlineNode)]) {
        id<RLMRealmOutlineNode> outlineItem = item;
        return outlineItem.isExpandable;
    }
    
    return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    // There is never more than one root node
    if (item == nil) {
        return 1;
    }
    // ... otherwise the number of child nodes are defined by the node in question.
    else if ([item conformsToProtocol:@protocol(RLMRealmOutlineNode)]) {
        id<RLMRealmOutlineNode> outlineItem = item;
        return outlineItem.numberOfChildNodes;
    }
    
    return 0;
}

#pragma mark - NSOutlineViewDelegate implementation

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    // Group headers should not be selectable
    return ![item isKindOfClass:[RLMRealmNode class]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
    return NO;
}

- (NSString *)outlineView:(NSOutlineView *)outlineView
           toolTipForCell:(NSCell *)cell
                     rect:(NSRectPointer)rect
              tableColumn:(NSTableColumn *)tc
                     item:(id)item
            mouseLocation:(NSPoint)mouseLocation
{
    if ([item respondsToSelector:@selector(hasToolTip)]) {
        if ([item respondsToSelector:@selector(toolTipString)]) {
            return [item toolTipString];
        }
    }
    
    return nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSOutlineView *outlineView = notification.object;
    if (outlineView == self.classesOutlineView) {
        NSInteger row = [outlineView selectedRow];

        // The arrays we get from link views are ephemeral, so we
        // remove them when any class node is selected
        if (row != -1) {
            [self selectedItem:[outlineView itemAtRow:row]];
        }
    }
}

-(void)selectedItem:(id<RLMRealmOutlineNode>)item
{
    if ([item isKindOfClass:[RLMResultsNode class]]) {
        return;
    }

    id<RLMRealmOutlineNode> theItem = item;
    
    // If we didn't select an array, we should flatten the outline view
    if (![item isKindOfClass:[RLMArrayNode class]]) {
        [self removeAllChildArrays];
    }
    
    // If we clicked an object, collapse and then select its parent
    if ([item isKindOfClass:[RLMObjectNode class]]) {
        theItem = ((RLMObjectNode *)item).parentNode;
    }
    
    RLMNavigationState *state = [[RLMNavigationState alloc] initWithSelectedType:theItem index:0];
    [self.parentWindowController addNavigationState:state fromViewController:self];
    NSInteger typeIndex = [self.classesOutlineView rowForItem:theItem];
    [self setSelectionIndex:typeIndex];
}

- (void)outlineView:(NSOutlineView *)outlineView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    // No Action
}

- (void)outlineView:(NSOutlineView *)outlineView didRemoveRowView:(NSTableRowView *)rowView forRow:(NSInteger)row
{
    // No Action
}

- (NSTableRowView *)outlineView:(NSOutlineView *)outlineView rowViewForItem:(id)item
{
    return nil;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if (outlineView == self.classesOutlineView) {
        if ([item conformsToProtocol:@protocol(RLMRealmOutlineNode)]) {
            id<RLMRealmOutlineNode> outlineNode = item;
            return [outlineNode cellViewForTableView:self.tableView];
        }
    }
    
    return nil;
}

#pragma mark - Public methods - Accessors

- (NSOutlineView *)outlineView
{
    if ([self.view isKindOfClass:[NSOutlineView class]]) {
        return (NSOutlineView *)self.view;
    }
    
    return nil;
}

#pragma mark - Private methods

- (void)removeAllChildArrays
{
    for (RLMClassNode *node in self.parentWindowController.modelDocument.presentedRealm.topLevelClasses) {
        [node removeAllChildNodes];
        [self.classesOutlineView reloadItem:node];
    }
}

@end
