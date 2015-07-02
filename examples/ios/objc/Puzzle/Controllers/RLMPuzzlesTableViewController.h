//
//  RLMPuzzlesTableViewController.h
//  RealmExamples
//
//  Created by Tim Oliver on 7/2/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

@interface RLMPuzzlesTableViewController : UITableViewController

- (instancetype)initWithPuzzles:(RLMResults *)puzzles;

@end
