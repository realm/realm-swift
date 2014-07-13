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

#import <Cocoa/Cocoa.h>

#import "RLMNavigationState.h"

@class RLMRealmBrowserWindowController;

@interface RLMViewController : NSViewController

@property (nonatomic, readonly) NSTableView *tableView;
@property (nonatomic, readonly) BOOL navigationFromHistory;
@property (nonatomic, strong) RLMTypeNode *displayedType;
@property (nonatomic, weak) IBOutlet RLMRealmBrowserWindowController *parentWindowController;

- (void)updateUsingState:(RLMNavigationState *)newState oldState:(RLMNavigationState *)oldState;

- (void)performUpdateUsingState:(RLMNavigationState *)newState oldState:(RLMNavigationState *)oldState;

- (void)clearSelection;

- (void)setSelectionIndex:(NSUInteger)newIndex;

@end
