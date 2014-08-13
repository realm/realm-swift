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

#import "RLMViewController.h"

#import "RLMRealmBrowserWindowController.h"
#import "RLMArrayNavigationState.h"

@implementation RLMViewController {
    id delegate;
}

#pragma mark - NSObject overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    _navigationFromHistory = NO;
}

#pragma mark - Public methods - Accessors

- (NSTableView *)tableView
{
    if ([self.view isKindOfClass:[NSTableView class]]) {
        return (NSTableView *)self.view;
    }
        
    return nil;
}

#pragma mark - Public methods

- (void)updateUsingState:(RLMNavigationState *)newState oldState:(RLMNavigationState *)oldState
{
    _navigationFromHistory = YES;
    
    [self performUpdateUsingState:newState oldState:oldState];
    
    _navigationFromHistory = NO;
}

- (void)performUpdateUsingState:(RLMNavigationState *)newState oldState:(RLMNavigationState *)oldState
{
    // No action - should be implemented by subclasses.
}

- (void)clearSelection
{
    [self.tableView selectRowIndexes:nil byExtendingSelection:NO];
}

- (void)setSelectionIndex:(NSUInteger)newIndex
{
    NSUInteger oldIndex = self.tableView.selectedRow;
    if (oldIndex != newIndex) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newIndex] byExtendingSelection:NO];
        
        [self.tableView scrollRowToVisible:newIndex];
    }
}

@end




