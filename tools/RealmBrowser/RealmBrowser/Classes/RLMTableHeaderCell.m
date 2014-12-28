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

#import "RLMTableHeaderCell.h"

@implementation RLMTableHeaderCell

- (void)drawWithFrame:(CGRect)cellFrame inView:(NSView *)view
{
    CGRect fillRect, borderRect;
    CGRectDivide(cellFrame, &borderRect, &fillRect, 1.0, CGRectMaxYEdge);
    
    NSGradient *gradient = [[NSGradient alloc]
                            initWithStartingColor:[NSColor whiteColor]
                            endingColor:[NSColor whiteColor]];
    [gradient drawInRect:fillRect angle:90.0];
    
    [[NSColor colorWithDeviceWhite:0.0 alpha:1.0] set];
    NSRectFill(borderRect);
    
    [self drawInteriorWithFrame:cellFrame inView:view];
}

-(void)setFirstLine:(NSString *)firstLine
{
    _firstLine = firstLine;
    [self updateStringValue];
}

-(void)setSecondLine:(NSString *)secondLine
{
    _secondLine = secondLine;
    [self updateStringValue];
}

-(void)updateStringValue
{
    if (!self.firstLine || !self.secondLine) {
        return;
    }
    
    NSString *stringValue = [NSString stringWithFormat:@"%@\n%@", self.firstLine, self.secondLine];
    
    NSMutableAttributedString *attributedStringValue = [[NSMutableAttributedString alloc] initWithString:stringValue];
    NSRange firstStringRange = NSMakeRange(0, self.firstLine.length);
    NSRange secondStringRange = NSMakeRange(stringValue.length - self.secondLine.length, self.secondLine.length);
    
    [attributedStringValue addAttribute:NSFontAttributeName value:[NSFont boldSystemFontOfSize:12.0] range:firstStringRange];
    [attributedStringValue addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:secondStringRange];
    
    self.attributedStringValue = attributedStringValue;
}

@end




