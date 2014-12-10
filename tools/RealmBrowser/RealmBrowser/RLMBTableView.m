//
//  RLMBTableView.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 10/12/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBTableView.h"

@implementation RLMBTableView

-(void)awakeFromNib
{
    [super awakeFromNib];
    NSLog(@"table awoke");
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
