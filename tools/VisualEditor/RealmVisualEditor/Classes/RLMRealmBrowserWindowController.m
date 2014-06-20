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

const NSUInteger kMaxNumberOfArrayEntriesInToolTip = 5;

@implementation RLMRealmBrowserWindowController

#pragma mark - NSWindowsController overrides

- (void)windowDidLoad
{
    [self.tableViewController viewDidLoad];
    
    // We want the class outline to be expandedas default
    [self.outlineViewController.classesOutlineView expandItem:nil
                         expandChildren:YES];
    
    // ... and the first class to be selected so something is displayed in the property pane.
    id firstItem = self.modelDocument.presentedRealm.topLevelClazzes.firstObject;
    if (firstItem != nil) {
        NSInteger index = [self.outlineViewController.classesOutlineView rowForItem:firstItem];
        [self.outlineViewController.classesOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:index]
                                                   byExtendingSelection:NO];
    }
}

- (void)updateSelectedObjectNode:(RLMObjectNode *)outlineNode
{
    [self.tableViewController updateSelectedObjectNode:outlineNode];
}

@end
