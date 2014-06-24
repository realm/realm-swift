//
//  RLMInstanceTableViewController.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "RLMObjectNode.h"
#import "RLMViewController.h"

@class RLMRealmBrowserWindowController;

@interface RLMInstanceTableViewController : RLMViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, weak) RLMRealmBrowserWindowController IBOutlet *parentWindowController;
@property (nonatomic, strong) IBOutlet NSTableView *instancesTableView;

- (void)viewDidLoad;

- (IBAction)userDoubleClicked:(id)sender;

- (void)updateTableView;

- (void)updateSelectedObjectNode:(RLMObjectNode *)outlineNode;

@end
