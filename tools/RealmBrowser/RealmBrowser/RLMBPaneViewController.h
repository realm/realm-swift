//
//  RLMBPaneViewController.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 21/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Realm/Realm.h>

@interface RLMBPaneViewController : NSViewController

@property (weak) IBOutlet NSTextField *classNameLabel;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSTableView *tableView;

@end
