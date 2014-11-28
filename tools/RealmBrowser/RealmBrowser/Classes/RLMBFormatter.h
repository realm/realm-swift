//
//  RLMBFormatter.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 28/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h> // FIXME

@interface RLMBFormatter : NSObject

- (NSTableCellView *)tableView:(NSTableView *)tableView cellViewForValue:(id)value type:(RLMPropertyType)type;
- (NSString *)typeNameForProperty:(RLMProperty *)property;

@end
