//
//  RLMBasicTableCellView.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 06/08/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBasicTableCellView.h"

@implementation RLMBasicTableCellView

- (void)awakeFromNib {
}

- (void)viewWillDraw {
    [super viewWillDraw];
    self.textField.frame = self.bounds;
}

@end
