//
//  RLMTableColumn.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 21/08/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RLMTypeNode.h"

@interface RLMTableColumn : NSTableColumn

@property (nonatomic) RLMPropertyType propertyType;

- (CGFloat)sizeThatFitsWithLimit:(BOOL)limited;

@end
