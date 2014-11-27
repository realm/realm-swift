//
//  RLMBRootPaneViewController.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 27/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBPaneViewController.h"

@class RLMResults;
@interface RLMBRootPaneViewController : RLMBPaneViewController

@property (nonatomic) RLMResults *objects;

- (void)updateWithRealm:(RLMRealm *)realm objectSchema:(RLMObjectSchema *)objectSchema;

@end
