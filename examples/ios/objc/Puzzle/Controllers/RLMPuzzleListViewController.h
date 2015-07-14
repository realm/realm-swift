//
//  RLMPuzzleListViewController.h
//  RealmExamples
//
//  Created by Tim Oliver on 7/14/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RLMPuzzle;

@interface RLMPuzzleListViewController : UITableViewController

@property (nonatomic, copy) void (^puzzleChosenHandler)(RLMPuzzle *puzzle);

@end
