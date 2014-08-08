//
//  RLMBadgeTableCellView.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 05/08/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBadgeTableCellView.h"

@implementation RLMBadgeTableCellView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.badge.cell setBezelStyle:NSInlineBezelStyle];
}

- (void)viewWillDraw
{
    [super viewWillDraw];
    
    if (![self.badge isHidden]) {
        [self.badge sizeToFit];
        
        NSRect textFrame = self.textField.frame;
        NSRect badgeFrame = self.badge.frame;
        badgeFrame.origin.x = NSWidth(self.frame) - NSWidth(badgeFrame) - 10.0f;
        self.badge.frame = badgeFrame;
        textFrame.size.width = NSMinX(badgeFrame) - NSMinX(textFrame);
        self.textField.frame = textFrame;
    }
}

-(NSSize)sizeThatFits
{
    [self.textField sizeToFit];
    CGFloat textWidth = self.textField.bounds.size.width;

    [self.badge sizeToFit];
    CGFloat badgeWidth = self.badge.bounds.size.width;
    
    return NSMakeSize(textWidth + badgeWidth, 20.0);
}

@end
