//
//  RLMNavigationState.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 07/07/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RLMTypeNode.h"

@interface RLMNavigationState : NSObject

@property (nonatomic, readonly) RLMTypeNode *selectedType;
@property (nonatomic, readonly) NSInteger selectionIndex;

- (instancetype)initWithSelectedType:(RLMTypeNode *)type index:(NSInteger)index;

@end
