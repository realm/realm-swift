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

#import <Foundation/Foundation.h>
#import <Realm/Realm.h> // FIXME

NSString *const kRLMBGutterColumnIdentifier;
NSString *const kRLMBGutterCellId;
NSString *const kRLMBBasicCellId;
NSString *const kRLMBLinkCellId;
NSString *const kRLMBBoolCellId;
NSString *const kRLMBNumberCellId;

@class RLMBPaneViewController;
@interface RLMBViewModel : NSObject

- (instancetype)initWithOwner:(RLMBPaneViewController *)owner;

- (NSTableCellView *)cellViewForGutter:(NSTableView *)tableView row:(NSUInteger)row;
- (NSTableCellView *)tableView:(NSTableView *)tableView cellViewForValue:(id)value type:(RLMPropertyType)type;
+ (NSString *)typeNameForProperty:(RLMProperty *)property;

@end
