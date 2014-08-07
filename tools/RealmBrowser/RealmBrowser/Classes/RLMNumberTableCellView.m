//
//  RLMNumberTableCellView.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 07/08/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMNumberTableCellView.h"

@implementation RLMNumberTableCellView

- (void)awakeFromNib {
}

- (void)viewWillDraw {
    [super viewWillDraw];
    self.textField.frame = self.bounds;
}

@end
