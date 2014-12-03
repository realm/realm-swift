//
//  RLMScrollView.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 23/10/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMScrollView.h"
#import "RLMClipView.h"

@implementation RLMScrollView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self == nil) return nil;
    
    [self swapClipView];
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (![self.contentView isKindOfClass:[RLMClipView class]]) {
        [self swapClipView];
    }
}

- (void)swapClipView
{
    self.wantsLayer = YES;
    id documentView = self.documentView;
    RLMClipView *clipView = [[RLMClipView alloc] initWithFrame:self.contentView.frame];
    self.contentView = clipView;
    self.documentView = documentView;
}

@end
