//
//  RLMClassOutlineViewController.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "RLMViewController.h"
#import "RLMClazzNode.h"

@class RLMRealmBrowserWindowController;

@interface RLMClassOutlineViewController : RLMViewController <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, weak) RLMRealmBrowserWindowController IBOutlet *parentWindowController;

- (void)selectClassNode:(RLMClazzNode *)classNode;

@end
