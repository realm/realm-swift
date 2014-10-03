//
//  RLMPopupWindow.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 29/09/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMPopupWindow.h"
#import "RLMArrayNode.h"

const CGFloat triangleHeight = 30.0;
const CGFloat triangleWidth = 50.0;

const CGFloat viewMargin = 25.0;
const CGFloat windowMargin = 40.0;
const CGFloat borderWidth = 2.0;
const CGFloat cornerRadius = 25.0;

@interface RLMPopupWindow ()

@property (nonatomic, weak) NSWindow *parentWindow;
@property (nonatomic, weak) NSView *view;

@property (nonatomic) CGFloat borderWidth;
@property (nonatomic) NSColor *borderColor;

@property (nonatomic) NSPoint displayPoint;
@property (nonatomic) BOOL displayAtLeft;

@end


@implementation RLMPopupWindow

-(instancetype)initWithView:(NSView *)view inWindow:(NSWindow *)window
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
        
        self.borderColor = [NSColor grayColor];
        self.backgroundColor = [NSColor whiteColor];
    }
    
    return self;
}

- (void)updateGeometryAtPoint:(NSPoint)displayPoint
{
    NSLog(@"updating geomtry for point: %@", NSStringFromPoint(displayPoint));

    NSSize screenSize = self.screen.frame.size;
    NSSize windowSize = self.frame.size;
    NSPoint origin = displayPoint;
    
    // Put the window on the right of the displayPoint if possible, if not, on the left
    if (displayPoint.x + triangleWidth + windowSize.width + windowMargin > screenSize.width) {
        self.displayAtLeft = YES;
        origin.x = displayPoint.x - triangleWidth - windowSize.width;
    }
    else {
        self.displayAtLeft = NO;
        origin.x = displayPoint.x + triangleWidth;
    }
    
    // Try to center vertically if displayPoint is not too close to top or bottom of the screen
    CGFloat innerMargin = triangleHeight/2.0 + cornerRadius;
    if (displayPoint.y + innerMargin > screenSize.height/2.0 + windowSize.height/2.0) {
        origin.y = displayPoint.y + innerMargin - windowSize.height;
    }
    else if (displayPoint.y - innerMargin < screenSize.height/2.0 - windowSize.height/2.0) {
        origin.y = displayPoint.y - innerMargin;
    }
    else {
        origin.y = screenSize.height/2.0 - windowSize.height/2.0;
    }
    
    NSLog(@"%@ self.view.frame BEFORE: %@", self, NSStringFromRect(self.view.frame));
    NSLog(@"%@ self.frame BEFORE: %@", self, NSStringFromRect(self.frame));
    
    NSRect contentRect = NSInsetRect(self.view.frame, -viewMargin, -viewMargin);
    contentRect.origin = origin;
    [self setFrame:contentRect display:NO];
    
    NSLog(@"%@ self.view.frame MID: %@", self, NSStringFromRect(self.view.frame));
    NSLog(@"%@ self.frame MID: %@", self, NSStringFromRect(self.frame));

    NSRect viewFrame = self.view.frame;
    viewFrame.origin = NSMakePoint(viewMargin, viewMargin);
    self.view.frame = viewFrame;
    
    NSLog(@"%@ self.view.frame AFTER: %@", self, NSStringFromRect(self.view.frame));
    NSLog(@"%@ self.frame AFTER: %@", self, NSStringFromRect(self.frame));
    
    [self updateBackground];
}

- (void)updateBackground
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
    NSRect frame = NSInsetRect(self.view.frame, -viewMargin, -viewMargin);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frame xRadius:cornerRadius yRadius:cornerRadius];
    [path setLineJoinStyle:NSRoundLineJoinStyle];
    
    return path;
}

@end



