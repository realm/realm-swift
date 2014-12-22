//
//  RLMBLinkCellView.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 10/12/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBLinkCellView.h"
#import "NSColor+ByteSizeFactory.h"

@interface RLMBLinkCellView ()

@property (nonatomic) NSColor *borderColor;

@end

@implementation RLMBLinkCellView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (self.isOpen) {
        [NSGraphicsContext saveGraphicsState];

        [self.borderColor set];
        NSFrameRect([self bounds]);
    
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    [super setBackgroundStyle:backgroundStyle];
    self.textField.textColor = (backgroundStyle == NSBackgroundStyleLight ? [NSColor linkColor] : [NSColor whiteColor]);
    self.borderColor = (backgroundStyle == NSBackgroundStyleLight ? [NSColor linkColor] : [NSColor whiteColor]);
}

@end
