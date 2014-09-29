//
//  RLMPopupWindow.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 29/09/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMPopupWindow.h"
#import "RLMArrayNode.h"

@interface RLMPopupWindow ()

@property (nonatomic) NSWindow *parentWindow;

@end


@implementation RLMPopupWindow

-(instancetype)initWithView:(NSView *)view atPoint:(NSPoint)point inWindow:(NSWindow *)window
{
    NSRect contentRect = NSZeroRect;
    contentRect.size = NSMakeSize(800, 800);
    contentRect.origin = point;
    
    self = [super initWithContentRect:contentRect
                            styleMask:NSBorderlessWindowMask
                              backing:NSBackingStoreBuffered
                                defer:NO];
    
    if (self) {
        self.backgroundColor = [NSColor clearColor];
        self.movableByWindowBackground = NO;
        self.excludedFromWindowsMenu = YES;
        self.alphaValue = 1.0;
        self.opaque = NO;
        self.hasShadow = YES;
        [self useOptimizedDrawing:YES];
        
        self.parentWindow = window;

        [self.contentView addSubview:view];
    }
    
    return self;
}

@end
