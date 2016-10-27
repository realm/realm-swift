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

#import "CanvasView.h"
#import "DrawPath.h"
#import "SwatchColor.h"

@interface CanvasView ()

@property CGContextRef onscreenContext;
@property CGLayerRef offscreenLayer;
@property CGContextRef offscreenContext;

@end

@implementation CanvasView

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
        BOOL pathEnded = [path.drawerID isEqualToString:@""];
        if (pathEnded) {
            [self drawPath:path withContext:self.offscreenContext];
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
}

- (void)clearCanvas
{
    //Clear the onscreen context
    CGContextSetFillColorWithColor(self.onscreenContext, [UIColor whiteColor].CGColor);
    CGContextFillRect(self.onscreenContext, self.bounds);
    
    //Clear the offscreen context
    CGContextSetFillColorWithColor(self.offscreenContext, [UIColor whiteColor].CGColor);
    CGContextFillRect(self.offscreenContext, self.bounds);
    
    [self setNeedsDisplay];
}

@end
