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

@implementation RLMViewController

#pragma mark - NSObject overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newTypeNodeHasBeenSelectedNotificationListener:)
                                                 name:RLMNewTypeNodeHasBeenSelectedNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)updateViewWithState:(RLMNavigationState *)state
{
    // No action - should be overridden by subclasses.
}

- (void)clearSelection
{
    id<NSTableViewDelegate> tempDelegate = self.tableView.delegate;
    self.tableView.delegate = nil;
    
    [self.tableView selectRowIndexes:nil
                byExtendingSelection:NO];
    
    self.tableView.delegate = tempDelegate;
}

- (void)setSelectionIndex:(NSUInteger)newIndex
{
    id<NSTableViewDelegate> tempDelegate = self.tableView.delegate;
    self.tableView.delegate = nil;
    
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newIndex]
                byExtendingSelection:NO];
    
    self.tableView.delegate = tempDelegate;
}

#pragma mark - Private methods

- (void)newTypeNodeHasBeenSelectedNotificationListener:(NSNotification *)notification
{
    RLMNavigationState *navigationState = notification.userInfo[RLMNotificationInfoNavigationState];
    _currentState = navigationState;
    [self updateViewWithState:navigationState];
}

@end
