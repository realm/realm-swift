//
//  RLMPopupViewController.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 29/09/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RLMArrayNode;

@interface RLMPopupViewController : NSViewController

@property (nonatomic) RLMArrayNode *arrayNode;
@property (nonatomic) NSPoint displayPoint;

@property (nonatomic) BOOL showingWindow;

- (void)setupFromWindow:(NSWindow *)parentWindow;

- (void)updateTableView;

- (void)showWindow;

- (void)hideWindow;

@end
