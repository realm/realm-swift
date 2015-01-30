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
#import <Realm/Realm.h>

NSString * const host = @"Alexanders-MacBook-Pro.local";

@interface DrawView ()

@property NSString *pathID;
@property RLMResults *paths;
@property RLMNotificationToken *notificationToken;
@property NSString *vendorID;

@end

@implementation DrawView


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    self.vendorID = host;
    if (self) {
        [[NSFileManager defaultManager] removeItemAtPath:[RLMRealm defaultRealmPath] error:nil];
        [RLMRealm enableServerSyncOnPath:[RLMRealm defaultRealmPath]
                           serverBaseURL:[NSString stringWithFormat:@"realm://%@/draw", host]];

        self.notificationToken = [[RLMRealm defaultRealm] addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
            self.paths = [DrawPath allObjects];
            [self setNeedsDisplay:YES];
        }];
        self.paths = [DrawPath allObjects];
    }
    return self;
}

- (void)mouseDown:(NSEvent *)theEvent {
    self.pathID = [[NSUUID UUID] UUIDString];
    NSBezierPath *path = [NSBezierPath bezierPath];
    path.lineWidth = 4.0f;
    CGPoint point = theEvent.locationInWindow;
    NSArray *pointArray = @[@(point.x), @(self.frame.size.height - point.y)];
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        [DrawPath createInDefaultRealmWithObject:@[self.pathID, self.vendorID, @[pointArray]]];
    }];
}

-(void)mouseDragged:(NSEvent *)theEvent {
    [self addPoint:theEvent.locationInWindow];
}

/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.pathID = [[NSUUID UUID] UUIDString];
    NSBezierPath *path = [NSBezierPath bezierPath];
    path.lineWidth = 4.0f;
    CGPoint point = [[touches anyObject] locationInView:self];
    NSArray *pointArray = @[@(point.x), @(point.y)];
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        [DrawPath createInDefaultRealmWithObject:@[self.pathID, self.vendorID, @[pointArray]]];
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
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
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

 */

- (void)addPoint:(CGPoint)point
{
    NSArray *pointArray = @[@(point.x), @(self.frame.size.height - point.y)];
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        DrawPath *currentPath = [DrawPath objectForPrimaryKey:self.pathID];
        [currentPath.points addObject:[[DrawPoint alloc] initWithObject:pointArray]];
    }];
}


- (void)drawRect:(CGRect)rect
{
    [[NSColor whiteColor] setFill];
    NSRectFill(rect);

    for (DrawPath *path in self.paths) {
        if ([path.drawerID isEqualToString:self.vendorID]) {
            [[NSColor redColor] setStroke];
        } else {
            [[NSColor blueColor] setStroke];
        }
        [path.path stroke];
    }

    [super drawRect:rect];
}

- (BOOL)isFlipped {
    return YES;
}

@end
