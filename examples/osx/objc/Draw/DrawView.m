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
#import "SwatchColor.h"
#import "SwatchesView.h"

#error Specify sync server URL
NSString * const serverURLString = @"realm://127.0.0.1:7800/draw";

#error Specify user identity
NSString * const identity = @"ewogICAgImlkZW50aXR5IjogImRyYXdhcHAiLAogICAgImFjY2VzcyI6IFsiZG93bmxvYWQiLCAidXBsb2FkIl0sCiAgICAiYXBwX2lkIjogImlvLnJlYWxtLkRyYXciLAogICAgImV4cGlyZXMiOiBudWxsLAogICAgInRpbWVzdGFtcCI6IDE0NTYxNTU0MzYKfQ==";

#error Specify user identity signature
NSString * const signature = @"GjYdXNtumU9FssnOn/Psf1S/KeF2H58yzWozbav/QPSL/b7BcYuxQFU+iHuSeQEzZD3jHLaJvmifilW0TzRg+KqMxZ+veOFCMPHScCSVApA6E0qdSn12LEehpKjJ9ewOypXuPlyrulFF51HFcSByIq2UlfYiv50bq7+X22/y0VCNuoRpsSn8n9NxOCPIQZcTxeRFgDMmClqbcUN6pSR4T10HzmHsoAQH3vP2+vIm9gfm9ZOW0wZn2Iw/mev+6YuDIXaOskssfNAB6CdzgUf7vOns87OPzxXNU1r3QmZR/AVZgN9G4ipeFmY6FYZN/T3gowikGOTFscRWhEkeTbZ1dg==";

@interface DrawView ()

@property DrawPath *drawPath;
@property RLMResults *paths;
@property RLMNotificationToken *notificationToken;
@property NSString *vendorID;
@property SwatchesView *swatchesView;
@property SwatchColor *currentColor;

@end

@implementation DrawView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    self.vendorID = [[NSHost currentHost] localizedName];

    if (self) {
        RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
        configuration.syncServerURL = [NSURL URLWithString:serverURLString];
        configuration.syncUserToken = [NSString stringWithFormat:@"%@:%@", identity, signature];
        [RLMRealmConfiguration setDefaultConfiguration:configuration];

        [RLMRealm setGlobalSynchronizationLoggingLevel:RLMSyncLogLevelVerbose];

        self.notificationToken = [[RLMRealm defaultRealm] addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
            self.paths = [DrawPath allObjects];
            [self setNeedsDisplay:YES];
        }];
        
        self.paths = [DrawPath allObjects];
        
        self.swatchesView = [[SwatchesView alloc] initWithFrame:CGRectZero];
        [self addSubview:self.swatchesView];
        
        __block typeof(self) blockSelf = self;
        self.swatchesView.swatchColorChangedHandler = ^{
            blockSelf.currentColor = blockSelf.swatchesView.selectedColor;
        };
        
        [self resizeSubviewsWithOldSize:self.frame.size];
    }
    
    return self;
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize
{
    [super resizeSubviewsWithOldSize:oldSize];
    
    CGRect frame = self.swatchesView.frame;
    frame.size.width = CGRectGetWidth(self.frame);
    frame.origin.y = CGRectGetHeight(self.frame) - CGRectGetHeight(frame);
    self.swatchesView.frame = frame;
    [self.swatchesView setNeedsLayout:YES];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSString *colorName = self.currentColor ? self.currentColor.name : @"Black";
    self.drawPath = [[DrawPath alloc] init];
    self.drawPath.color = colorName;
    
    CGPoint point = [self convertPoint:theEvent.locationInWindow fromView:nil];
    DrawPoint *drawPoint = [[DrawPoint alloc] init];
    drawPoint.x = point.x;
    drawPoint.y = point.y;
    
    [self.drawPath.points addObject:drawPoint];
    
    RLMRealm *defaultRealm = [RLMRealm defaultRealm];
    [defaultRealm transactionWithBlock:^{
        [defaultRealm addObject:self.drawPath];
    }];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint point = [self convertPoint:theEvent.locationInWindow fromView:nil];
    [self addPoint:point];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [self addPoint:[self convertPoint:theEvent.locationInWindow fromView:nil]];

    [[RLMRealm defaultRealm] transactionWithBlock:^{
        self.drawPath.drawerID = self.vendorID; // mark this path as ended
    }];
    
    self.drawPath = nil;
}

- (void)addPoint:(CGPoint)point
{
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        if (self.drawPath.isInvalidated) {
            self.drawPath = [[DrawPath alloc] init];
            self.drawPath.color = self.currentColor ? self.currentColor.name : @"Black";
            [[RLMRealm defaultRealm] addObject:self.drawPath];
        }
        
        DrawPoint *newPoint = [DrawPoint createInDefaultRealmWithValue:@[@(point.x), @(point.y)]];
        [self.drawPath.points addObject:newPoint];
    }];
}


- (void)drawRect:(CGRect)rect
{
    [[NSColor whiteColor] setFill];
    NSRectFill(rect);

    for (DrawPath *path in self.paths) {
        SwatchColor *swatchColor = [SwatchColor swatchColorForName:path.color];
        [swatchColor.color setStroke];
        [path.path stroke];
    }

    [super drawRect:rect];
}

- (BOOL)isFlipped
{
    return YES;
}

@end
