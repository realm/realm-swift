//
//  RLMBoolTableCellView.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 06/08/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBoolTableCellView.h"

@implementation RLMBoolTableCellView

- (void)viewWillDraw
{
    [super viewWillDraw];
    
    CGRect frame = self.checkBox.frame;
    CGRect bounds = self.bounds;
    
    frame.origin.x = (CGRectGetWidth(bounds) - CGRectGetWidth(frame))/2.0;
    frame.origin.y = (CGRectGetHeight(bounds) - CGRectGetHeight(frame))/2.0;
    
    self.checkBox.frame = frame;
}

-(NSSize)sizeThatFits
{
    return self.checkBox.bounds.size;
}

@end
