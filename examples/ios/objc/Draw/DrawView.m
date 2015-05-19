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

#import "DrawView.h"
#import "DrawPath.h"
#import "SwatchesView.h"
#import "SwatchColor.h"
#import <Realm/Realm.h>

@interface DrawView ()

@property NSString *pathID;
@property NSMutableSet *drawnPathIDs;
@property RLMResults *paths;
@property RLMNotificationToken *notificationToken;
@property NSString *vendorID;
@property SwatchesView *swatchesView;
@property SwatchColor *currentColor;
@property CGContextRef onscreenContext;
@property CGLayerRef offscreenLayer;
@property CGContextRef offscreenContext;

@end

@implementation DrawView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.notificationToken = [[RLMRealm defaultRealm] addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
            self.paths = [DrawPath allObjects];
            [self setNeedsDisplay];
        }];
        self.vendorID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        self.paths = [DrawPath allObjects];
        self.swatchesView = [[SwatchesView alloc] initWithFrame:CGRectZero];
        [self addSubview:self.swatchesView];
        
        __block typeof(self) blockSelf = self;
        self.swatchesView.swatchColorChangedHandler = ^{
            blockSelf.currentColor = blockSelf.swatchesView.selectedColor;
        };
        self.drawnPathIDs = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.swatchesView.frame;
    frame.size.width = CGRectGetWidth(self.frame);
    frame.origin.y = CGRectGetHeight(self.frame) - CGRectGetHeight(frame);
    self.swatchesView.frame = frame;
    [self.swatchesView setNeedsLayout];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.pathID = [[NSUUID UUID] UUIDString];
    CGPoint point = [[touches anyObject] locationInView:self];
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        NSString *colorName = self.currentColor ? self.currentColor.name : @"Black";
        [DrawPath createInDefaultRealmWithObject:@[self.pathID, self.vendorID, colorName]];
        [DrawPoint createInDefaultRealmWithObject:@[[[NSUUID UUID] UUIDString], self.pathID, @(point.x), @(point.y)]];
    }];
}

- (void)addPoint:(CGPoint)point
{
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        DrawPath *currentPath = [DrawPath objectForPrimaryKey:self.pathID];
        [DrawPoint createInDefaultRealmWithObject:@[[[NSUUID UUID] UUIDString], currentPath.pathID, @(point.x), @(point.y)]];
    }];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self];
    [self addPoint:point];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint point = [[touches anyObject] locationInView:self];
    [self addPoint:point];
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        DrawPath *currentPath = [DrawPath objectForPrimaryKey:self.pathID];
        currentPath.drawerID = @""; // mark this path as ended
    }];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

- (void)drawPath:(DrawPath*)path withContext:(CGContextRef)context
{
    SwatchColor *swatchColor = [SwatchColor swatchColorForName:path.color];
    CGContextSetStrokeColorWithColor(context, [swatchColor.color CGColor]);
    CGContextSetLineWidth(context, path.path.lineWidth);
    CGContextAddPath(context, [path.path CGPath]);
    CGContextStrokePath(context);
}

- (void)drawRect:(CGRect)rect
{
    // create offscreen context just once (must be done here)
    if (self.offscreenContext == nil) {
        self.onscreenContext = UIGraphicsGetCurrentContext();

        float contentScaleFactor = [self contentScaleFactor];
        CGSize size = CGSizeMake(self.bounds.size.width * contentScaleFactor, self.bounds.size.height * contentScaleFactor);

        self.offscreenLayer = CGLayerCreateWithContext(self.onscreenContext, size, NULL);
        self.offscreenContext = CGLayerGetContext(self.offscreenLayer);
        CGContextScaleCTM(self.offscreenContext, contentScaleFactor, contentScaleFactor);

        CGContextSetFillColorWithColor(self.offscreenContext, [[UIColor whiteColor] CGColor]);
        CGContextFillRect(self.offscreenContext, self.bounds);
    }

    // draw new "inactive" paths to the offscreen image
    NSMutableArray* activePaths = [[NSMutableArray alloc] init];

    for (DrawPath *path in self.paths) {
        BOOL pathAlreadyDrawn = [self.drawnPathIDs containsObject:path.pathID];
        if (pathAlreadyDrawn) {
            continue;
        }
        BOOL pathEnded = [path.drawerID isEqualToString:@""];
        if (pathEnded) {
            [self drawPath:path withContext:self.offscreenContext];
            [self.drawnPathIDs addObject:path.pathID];
        } else {
            [activePaths addObject:path];
        }
    }

    // copy offscreen image to screen
    CGContextDrawLayerInRect(self.onscreenContext, self.bounds, self.offscreenLayer);

    // lastly draw the currently active paths
    for (DrawPath *path in activePaths) {
        [self drawPath:path withContext:self.onscreenContext];
    }
    NSLog(@"Inactive paths: %lu", (unsigned long)self.drawnPathIDs.count);
    NSLog(@"Active paths: %lu", (unsigned long)activePaths.count);
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if ( event.subtype == UIEventSubtypeMotionShake )
    {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm transactionWithBlock:^{
            [realm deleteAllObjects];
        }];
    }

    if ( [super respondsToSelector:@selector(motionEnded:withEvent:)] )
        [super motionEnded:motion withEvent:event];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
