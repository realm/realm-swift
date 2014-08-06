//
//  RLMBadgeTableCellView.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 05/08/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBadgeTableCellView.h"

@implementation RLMBadgeTableCellView

- (void)awakeFromNib {
    // We want it to appear "inline"
    [self.badge.cell setBezelStyle:NSInlineBezelStyle];
}

// The standard rowSizeStyle does some specific layout for us. To customize layout for our button, we first call super and then modify things
- (void)viewWillDraw {
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

@end
