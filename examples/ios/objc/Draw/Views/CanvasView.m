////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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
#import "UIColor+Realm.h"

@implementation CanvasView

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    self.backgroundColor = [UIColor whiteColor];
}

- (void)drawPath:(DrawPath *)path withContext:(CGContextRef)context {
    UIColor *swatchColor = [UIColor realmColors][path.color];
    CGContextSetStrokeColorWithColor(context, [swatchColor CGColor]);
    CGContextSetLineWidth(context, path.path.lineWidth);
    CGContextAddPath(context, [path.path CGPath]);
    CGContextStrokePath(context);
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (DrawPath *path in self.paths) {
        [self drawPath:path withContext:context];
    }
}

- (void)clearCanvas {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, self.bounds);
    [self setNeedsDisplay];
}

@end
