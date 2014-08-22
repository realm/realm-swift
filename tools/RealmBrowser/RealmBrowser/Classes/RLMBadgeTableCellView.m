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
