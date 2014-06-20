//
//  RLMClassOutlineViewController.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 20/06/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RLMRealmBrowserWindowController;

@interface RLMClassOutlineViewController : NSViewController <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, weak) RLMRealmBrowserWindowController IBOutlet *parentWindowController;
@property (nonatomic, strong) IBOutlet NSOutlineView *classesOutlineView;

@end
