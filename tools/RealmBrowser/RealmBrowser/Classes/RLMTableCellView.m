//
//  RLMTableCellView.m
//  Realm
//
//  Created by Gustaf Kugelberg on 08/08/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMTableCellView.h"

@implementation RLMTableCellView

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewWillDraw
{
    [super viewWillDraw];
    self.textField.frame = self.bounds;
}

- (NSSize)sizeThatFits
{
    [self.textField sizeToFit];
    
    return self.textField.bounds.size;
}

@end
