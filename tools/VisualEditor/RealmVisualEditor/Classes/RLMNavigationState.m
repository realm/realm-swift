//
//  RLMNavigationState.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 07/07/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMNavigationState.h"

@implementation RLMNavigationState

- (instancetype)initWithSelectedType:(RLMTypeNode *)type index:(NSInteger)index
{
    if (self = [super init]) {
        _selectedType = type;
        _selectionIndex = index;
    }
    
    return self;
}

@end
