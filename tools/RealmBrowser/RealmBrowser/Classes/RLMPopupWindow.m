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

@property (nonatomic, weak) NSWindow *parentWindow;
@property (nonatomic, weak) NSView *view;

@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) NSColor *borderColor;

@property (nonatomic) NSPoint displayPoint;
@property (nonatomic) CGFloat viewMargin;

@end


@implementation RLMPopupWindow

-(instancetype)initWithView:(NSView *)view atPoint:(NSPoint)point inWindow:(NSWindow *)window
{
    self = [super initWithContentRect:NSZeroRect
                            styleMask:NSBorderlessWindowMask
                              backing:NSBackingStoreBuffered
                                defer:NO];
    
    if (self) {
        self.movableByWindowBackground = NO;
        self.excludedFromWindowsMenu = YES;
        self.alphaValue = 1.0;
        self.opaque = NO;
        self.hasShadow = YES;
        [self useOptimizedDrawing:YES];
        
        [self.contentView addSubview:view];

        self.parentWindow = window;
        self.view = view;
        
        self.borderWidth = 2.0;
        self.viewMargin = 25.0;
        self.displayPoint = point;
        self.borderColor = [NSColor grayColor];
        self.backgroundColor = [NSColor whiteColor];
        
        [self setupGeometry];
        [self setupBackground];
    }
    
    return self;
}

- (void)setupGeometry
{
    NSRect contentRect = NSInsetRect(self.view.frame, -self.viewMargin, -self.viewMargin);
    contentRect.origin = NSMakePoint(100, 100);
    [self setFrame:contentRect display:NO];
    
    NSRect viewFrame = self.view.frame;
    viewFrame.origin = NSMakePoint(self.viewMargin, self.viewMargin);
    self.view.frame = viewFrame;
}

- (void)setupBackground
{
    // Call NSWindow's implementation of -setBackgroundColor: because we override
    // it in this class to let us set the entire background image of the window
    // as an NSColor patternImage.
    NSDisableScreenUpdates();
    [super setBackgroundColor:[self backgroundColorPatternImage]];
    if ([self isVisible]) {
        [self display];
        [self invalidateShadow];
    }
    NSEnableScreenUpdates();
}

- (NSColor *)backgroundColorPatternImage
{
    NSImage *bg = [[NSImage alloc] initWithSize:self.frame.size];
    NSRect bgRect = NSZeroRect;
    bgRect.size = bg.size;
    
    [bg lockFocus];
    NSBezierPath *bgPath = [self backgroundPath];
    [NSGraphicsContext saveGraphicsState];
    [bgPath addClip];
    
    // Draw background.
    [self.backgroundColor set];
    [bgPath fill];
    
    // Draw border if appropriate.
    bgPath.lineWidth = 2.0*self.borderWidth;
    [self.borderColor set];
    [bgPath stroke];
    
    [NSGraphicsContext restoreGraphicsState];
    [bg unlockFocus];
    
    return [NSColor colorWithPatternImage:bg];
}


- (NSBezierPath *)backgroundPath
{
    NSRect frame = NSInsetRect(self.view.frame, -self.viewMargin, -self.viewMargin);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:25.0 yRadius:25.0];
    [path setLineJoinStyle:NSRoundLineJoinStyle];
    
    return path;
}

@end



