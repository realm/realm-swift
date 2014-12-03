//
//  RLMClipView.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 23/10/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMClipView.h"
#import <QuartzCore/QuartzCore.h>

@implementation RLMClipView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer = [CAScrollLayer layer];
        self.wantsLayer = YES;
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
    }
    
    return self;
}

@end
