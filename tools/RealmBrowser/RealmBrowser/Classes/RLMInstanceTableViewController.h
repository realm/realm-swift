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

#import "RLMViewController.h"
#import "RLMTableView.h"
#import "RLMTextField.h"

@class RLMRealmBrowserWindowController;
@class RLMArrayNode;

@interface RLMInstanceTableViewController : RLMViewController <RLMTextFieldDelegate, RLMTableViewDelegate, RLMTableViewDataSource>

@property (nonatomic, readonly) RLMTableView *realmTableView;

@property (nonatomic) BOOL realmIsLocked;
@property (nonatomic) BOOL displaysArray;

- (void)removeRowsInTableViewAt:(NSIndexSet *)rowIndexes;
- (void)deleteRowsInTableViewAt:(NSIndexSet *)rowIndexes;
- (void)insertNewRowsInTableViewAt:(NSIndexSet *)rowIndexes;
- (void)moveRowsInTableViewFrom:(NSIndexSet *)sourceIndexes to:(NSUInteger)destination;

@end
