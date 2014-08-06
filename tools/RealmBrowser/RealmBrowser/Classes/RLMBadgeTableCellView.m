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
    [[self.button cell] setBezelStyle:NSInlineBezelStyle];
}

// The standard rowSizeStyle does some specific layout for us. To customize layout for our button, we first call super and then modify things
- (void)viewWillDraw {
    [super viewWillDraw];
    
    if (![self.button isHidden]) {
        [self.button sizeToFit];
        
        NSRect textFrame = self.textField.frame;
        NSRect buttonFrame = self.button.frame;
        buttonFrame.origin.x = NSWidth(self.frame) - NSWidth(buttonFrame) - 10.0f;
        self.button.frame = buttonFrame;
        textFrame.size.width = NSMinX(buttonFrame) - NSMinX(textFrame);
        self.textField.frame = textFrame;
    }
}

@end
