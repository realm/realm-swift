//
//  RLMBFormatter.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 28/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

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
