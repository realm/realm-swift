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
NSString *const RLMNotificationInfoNavigationState = @"RLMNotificationInfoNavigationState";

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
        _selectedTypeNode = typeNode;
        
        RLMNavigationState *state = [navigationStack pushStateWithTypeNode:typeNode
                                         index:selectionIndex];
        [self updateNavigationButtons];

        [self performUpdateBasedOnNavigationState:state];
    }
}

- (void)updateSelectionAtIndex:(NSUInteger)selectionIndex
{
    // When making changes to the instance selection we only register the navigation changes in the
    // navigation stack but avoid notifying others as there is no changes to the selected type and
    // consequently no need for further updates.
    [navigationStack pushStateWithTypeNode:self.selectedTypeNode
                                     index:selectionIndex];
    [self updateNavigationButtons];

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
                [self performUpdateBasedOnNavigationState:state];
            }
            break;
        }
        case 1: { // Navigate backwards
            RLMNavigationState *state = [navigationStack navigateForward];
            if (state != nil) {
                [self performUpdateBasedOnNavigationState:state];
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

- (void)performUpdateBasedOnNavigationState:(RLMNavigationState *)state
{
    _selectedTypeNode = state.selectedType;
    [[NSNotificationCenter defaultCenter] postNotificationName:RLMNewTypeNodeHasBeenSelectedNotification
                                                        object:self
                                                      userInfo:@{RLMNotificationInfoNavigationState:state}];
}

@end
