////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMPopupWindow.h"
#import "RLMArrayNode.h"

const CGFloat arrowBase = 30.0;
const CGFloat arrowLength = 40.0;

const CGFloat viewMargin = -5.0;
const CGFloat windowMargin = 10.0;
const CGFloat borderWidth = 3.0;
const CGFloat cornerRadius = 30.0;

@interface RLMPopupWindow ()

@property (nonatomic, weak) NSWindow *parentWindow;
@property (nonatomic, weak) NSView *view;

@property (nonatomic) NSColor *borderColor;

@property (nonatomic) NSPoint displayPoint;
@property (nonatomic) BOOL displayAtLeft;

@end


@implementation RLMPopupWindow

-(instancetype)initWithView:(NSView *)view
{
    CGFloat commonMargin = viewMargin + cornerRadius;
    NSRect contentRect = NSInsetRect(view.bounds, -commonMargin, -commonMargin);
    contentRect.size.width += arrowLength;
    
    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    if (self) {
        self.movableByWindowBackground = NO;
        self.excludedFromWindowsMenu = YES;
        self.alphaValue = 1.0;
        self.opaque = NO;
        self.hasShadow = YES;
        [self useOptimizedDrawing:YES];
        
        [self.contentView addSubview:view];
        self.view = view;

        self.borderColor = [NSColor grayColor];
    }
    
    return self;
}

- (void)updateGeometryAtPoint:(NSPoint)displayPoint
{
    self.displayPoint = displayPoint;
    self.displayAtLeft = displayPoint.x + NSWidth(self.frame) + windowMargin > NSWidth(self.screen.frame);
    
    [self updateWindowPosition];
    [self updateBackground];
}

- (void)updateWindowPosition
{
    NSRect windowFrame = self.frame;
    NSRect viewFrame = self.view.frame;
    
    // Position view and window horizontally
    if (self.displayAtLeft) {
        windowFrame.origin.x = self.displayPoint.x - NSWidth(windowFrame);
        viewFrame.origin.x = viewMargin + cornerRadius;
    }
    else {
        windowFrame.origin.x = self.displayPoint.x;
        viewFrame.origin.x = viewMargin + cornerRadius + arrowLength;
    }
    
    // Position view vertically within the window
    viewFrame.origin.y = viewMargin + cornerRadius;
    
    // Try to center window vertically if displayPoint is not too close to top or bottom of the screen
    CGFloat arrowMargin = arrowBase/2.0 + cornerRadius;
    
    if (self.displayPoint.y + arrowMargin > NSHeight(self.screen.frame)/2.0 + NSHeight(windowFrame)/2.0) {
        windowFrame.origin.y = self.displayPoint.y + arrowMargin - NSHeight(windowFrame);
    }
    else if (self.displayPoint.y - arrowMargin < NSHeight(self.screen.frame)/2.0 - NSHeight(windowFrame)/2.0) {
        windowFrame.origin.y = self.displayPoint.y - arrowMargin;
    }
    else {
        windowFrame.origin.y = NSHeight(self.screen.frame)/2.0 - NSHeight(windowFrame)/2.0;
    }
    
    [self setFrame:windowFrame display:NO];
    self.view.frame = viewFrame;
}

- (void)updateBackground
{
    NSDisableScreenUpdates();
    [super setBackgroundColor:[self backgroundColorPatternImage]];
    [self display];
    [self invalidateShadow];
    NSEnableScreenUpdates();
}

- (NSColor *)backgroundColorPatternImage
{
    NSImage *bg = [[NSImage alloc] initWithSize:self.frame.size];
    [bg lockFocus];
    NSBezierPath *bgPath = [self backgroundPath];
    [NSGraphicsContext saveGraphicsState];
    [bgPath addClip];
    
    // Draw background
    [[NSColor whiteColor] set];
    [bgPath fill];
    
    // Draw border
    bgPath.lineWidth = borderWidth;
    [self.borderColor set];
    [bgPath stroke];
    
    [NSGraphicsContext restoreGraphicsState];
    [bg unlockFocus];
    
    return [NSColor colorWithPatternImage:bg];
}

- (NSBezierPath *)backgroundPath
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineJoinStyle:NSRoundLineJoinStyle];
    
    CGFloat arrowTipY = self.displayPoint.y - NSMinY(self.frame);
    
    // Set up the points
    CGFloat margin = viewMargin + cornerRadius;
    CGRect paddedFrame = NSInsetRect(self.view.frame, -margin, -margin);

    NSPoint rightUpperArrowBase = NSMakePoint(NSMaxX(paddedFrame), arrowTipY + arrowBase/2.0);
    NSPoint rightArrowTip       = NSMakePoint(NSWidth(self.frame), arrowTipY);
    NSPoint rightLowerArrowBase = NSMakePoint(NSMaxX(paddedFrame), arrowTipY - arrowBase/2.0);

    NSPoint lowerRight = NSMakePoint(NSMaxX(paddedFrame), NSMinY(paddedFrame));
    NSPoint lowerLeft  = NSMakePoint(NSMinX(paddedFrame), NSMinY(paddedFrame));
    
    NSPoint leftLowerArrowBase = NSMakePoint(NSMinX(paddedFrame), arrowTipY - arrowBase/2.0);
    NSPoint leftArrowTip       = NSMakePoint(0.0,                 arrowTipY);
    NSPoint leftUpperArrowBase = NSMakePoint(NSMinX(paddedFrame), arrowTipY + arrowBase/2.0);

    NSPoint upperLeft = NSMakePoint(NSMinX(paddedFrame), NSMaxY(paddedFrame));
    NSPoint upperRight = NSMakePoint(NSMaxX(paddedFrame), NSMaxY(paddedFrame));

    // Draw the path
    [path moveToPoint:rightUpperArrowBase];
    [path lineToPoint:rightArrowTip];
    [path lineToPoint:rightLowerArrowBase];

    [path appendBezierPathWithArcFromPoint:lowerRight toPoint:lowerLeft radius:cornerRadius];
    [path appendBezierPathWithArcFromPoint:lowerLeft toPoint:leftLowerArrowBase radius:cornerRadius];
    
    [path lineToPoint:leftLowerArrowBase];
    [path lineToPoint:leftArrowTip];
    [path lineToPoint:leftUpperArrowBase];

    [path appendBezierPathWithArcFromPoint:upperLeft toPoint:upperRight radius:cornerRadius];
    [path appendBezierPathWithArcFromPoint:upperRight toPoint:rightUpperArrowBase radius:cornerRadius];
    
    [path closePath];
    return path;
}

@end
