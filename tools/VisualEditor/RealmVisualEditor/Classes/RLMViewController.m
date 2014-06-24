//
//  RLMViewController.m
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 23/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMViewController.h"

@implementation RLMViewController

- (void)viewWillLoad
{
    
}

- (void)viewDidLoad
{
    
}

- (void)setView:(NSView *)newValue
{
    [self viewWillLoad];
    [super setView:newValue];
    [self viewDidLoad];
}

- (void)loadView
{
    [self viewWillLoad];
    [super loadView];
    [self viewDidLoad];
}

@end
