//
//  RLMRealmOutlineNode.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 21/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RLMRealmOutlineNode.h"

@protocol RLMRealmOutlineNode <NSObject>

- (BOOL)isRootNode;

- (BOOL)isExpandable;

- (NSUInteger)numberOfChildNodes;

- (id<RLMRealmOutlineNode>)childNodeAtIndex:(NSUInteger)index;

- (id)nodeElementForColumnWithIndex:(NSInteger)index;

@optional

- (NSString *)toolTipString;

@end
