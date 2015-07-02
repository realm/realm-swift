//
//  RLMPuzzlesTableViewController.m
//  RealmExamples
//
//  Created by Tim Oliver on 7/2/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import "RLMPuzzlesTableViewController.h"

@interface RLMPuzzlesTableViewController ()

@property (nonatomic, strong) RLMResults *puzzles;

@end

@implementation RLMPuzzlesTableViewController

- (instancetype)initWithPuzzles:(RLMResults *)puzzles
{
    if (self = [super initWithStyle:UITableViewStyleGrouped]) {
        _puzzles = puzzles;
    }
    
    return self;
}

@end
