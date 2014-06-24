//
//  RLMClassOutlineViewController.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMClassOutlineViewController.h"

#import "RLMRealmBrowserWindowController.h"
#import "RLMRealmOutlineNode.h"

@interface RLMClassOutlineViewController ()

@property (nonatomic, strong) IBOutlet NSOutlineView *classesOutlineView;

@end

@implementation RLMClassOutlineViewController

#pragma mark - RLMViewController overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // We want the class outline to be expandedas default
    [self.classesOutlineView expandItem:nil
                         expandChildren:YES];
    
    // ... and the first class to be selected so something is displayed in the property pane.
    id firstItem = self.parentWindowController.modelDocument.presentedRealm.topLevelClazzes.firstObject;
    if (firstItem != nil) {
        NSInteger index = [self.classesOutlineView rowForItem:firstItem];
        [self.classesOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                             byExtendingSelection:NO];
        [self selectOutlineItem:firstItem];
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
    // There is always only one root node
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

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSUInteger columnIndex = [self.classesOutlineView.tableColumns indexOfObject:tableColumn];
    if (columnIndex != NSNotFound) {
        if (item == nil && columnIndex == 0) {
            return @"Realms";
        }
        else if ([item conformsToProtocol:@protocol(RLMRealmOutlineNode)]) {
            id<RLMRealmOutlineNode> outlineItem = item;
            return [outlineItem nodeElementForColumnWithIndex:columnIndex];
        }
    }
    
    return nil;
}

#pragma mark - NSOutlineViewDelegate implementation

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item
{
    // The top level node should not be collapsed.
    return item != self.parentWindowController.modelDocument.presentedRealm;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
    // The top level node should not display the toggle triangle.
    return item != self.parentWindowController.modelDocument.presentedRealm;
}

- (NSString *)outlineView:(NSOutlineView *)outlineView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation
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
        id selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];
        [self selectOutlineItem:selectedItem];
    }
    
    // NOTE: Remember to move the clearing of the row selection in the instance view
    //[self.parentWindowController updateSelectedObjectNode:nil];
}

#pragma mark - Public methods

- (void)selectClassNode:(RLMClazzNode *)classNode
{
    NSInteger index = [self.classesOutlineView rowForItem:classNode];
    
    [self.classesOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                         byExtendingSelection:NO];
}

#pragma mark - Private methods

- (void)selectOutlineItem:(id)item
{
    if ([item isKindOfClass:[RLMClazzNode class]]) {
        RLMClazzNode *classNode = (RLMClazzNode *)item;
        [self.parentWindowController updateSelectedObjectNode:classNode];
        return;
    }
    else if ([item isKindOfClass:[RLMArrayNode class]]) {
        RLMArrayNode *arrayNode = (RLMArrayNode *)item;
        [self.parentWindowController updateSelectedObjectNode:arrayNode];
        return;
    }
}

@end
