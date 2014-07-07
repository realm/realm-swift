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

#import "RLMRealmBrowserWindowController.h"

#import "RLMObject+ResolvedClass.h"
#import "NSTableColumn+Resize.h"
#import "RLMNavigationStack.h"

const NSUInteger kMaxNumberOfArrayEntriesInToolTip = 5;
NSString *const RLMNewTypeNodeHasBeenSelectedNotification = @"RLMNewTypeNodeHasBeenSelectedNotification";
NSString *const RLMNotificationInfoTypeNode = @"RLMNotificationInfoTypeNode";
NSString *const RLMNotificationInfoIndex = @"RLMNotificationInfoIndex";

@implementation RLMRealmBrowserWindowController {

    RLMNavigationStack *navigationStack;
}

#pragma mark - NSViewController overrides

- (void)windowDidLoad
{
    navigationStack = [[RLMNavigationStack alloc] init];
    [self updateNavigationButtons];
    
    id firstItem = self.modelDocument.presentedRealm.topLevelClazzes.firstObject;
    if (firstItem != nil) {
        [self updateSelectedTypeNode:firstItem];
    }
    
}

#pragma mark - Public methods

- (void)updateSelectedTypeNode:(RLMTypeNode *)typeNode
{
    [self updateSelectedTypeNode:typeNode
            withSelectionAtIndex:0];
}

- (void)updateSelectedTypeNode:(RLMTypeNode *)typeNode withSelectionAtIndex:(NSUInteger)selectionIndex;
{
    // Only update and notify if we really have changed the selection!!!
    if (_selectedTypeNode != typeNode) {
        
        [navigationStack pushStateWithTypeNode:typeNode
                                         index:selectionIndex];
        [self updateNavigationButtons];
        
        [self performUpdateOfSelectedTypeNode:typeNode
                         withSelectionAtIndex:selectionIndex];
    }
}

- (void)addArray:(RLMArray *)array fromProperty:(RLMProperty *)property object:(RLMObject *)object
{
    RLMClazzNode *selectedClassNode = (RLMClazzNode *)self.selectedTypeNode;
    
    RLMArrayNode *arrayNode = [selectedClassNode displayChildArray:array
                                                      fromProperty:property
                                                            object:object];
    
    NSOutlineView *outlineView = (NSOutlineView *)self.outlineViewController.view;
    [outlineView reloadData];
    
    [outlineView expandItem:selectedClassNode];
    
    NSInteger index = [outlineView rowForItem:arrayNode];
    if (index != NSNotFound) {
        [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                 byExtendingSelection:NO];
    }    
}

- (IBAction)userClicksOnNavigationButtons:(NSSegmentedControl *)buttons
{
    switch (buttons.selectedSegment) {
        case 0: { // Navigate backwards
            RLMNavigationState *state = [navigationStack navigateBackward];
            if (state != nil) {
                [self performUpdateOfSelectedTypeNode:state.selectedType
                                 withSelectionAtIndex:state.selectionIndex];
            }
            break;
        }
        case 1: { // Navigate backwards
            RLMNavigationState *state = [navigationStack navigateForward];
            if (state != nil) {
                [self performUpdateOfSelectedTypeNode:state.selectedType
                                 withSelectionAtIndex:state.selectionIndex];
            }
            break;
        }
        default:
            break;
    }
    
    [self updateNavigationButtons];    
}

#pragma mark - Private methods

- (void)updateNavigationButtons
{
    [self.navigationButtons setEnabled:[navigationStack canNavigateBackward]
                            forSegment:0];
    [self.navigationButtons setEnabled:[navigationStack canNavigateForward]
                            forSegment:1];
}

- (void)performUpdateOfSelectedTypeNode:(RLMTypeNode *)typeNode withSelectionAtIndex:(NSUInteger)selectionIndex;
{
    _selectedTypeNode = typeNode;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RLMNewTypeNodeHasBeenSelectedNotification
                                                        object:self
                                                      userInfo:@{RLMNotificationInfoTypeNode:typeNode,
                                                                 RLMNotificationInfoIndex:@(selectionIndex)}];
}

@end
