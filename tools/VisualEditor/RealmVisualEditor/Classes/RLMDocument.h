//
//  RLMDocument.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 13/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RLMDocument : NSDocument <NSOutlineViewDataSource, NSOutlineViewDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSOutlineView *classesOutlineView;
@property (nonatomic, strong) IBOutlet NSTableView *instancesTableView;

@end
