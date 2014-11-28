//
//  RLMBPaneViewController.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 21/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Realm/Realm.h>
#import "RLMBFormatter.h" // FIXME: inheritance/exposing

@class RLMBPaneViewController;
@protocol RLMBCanvasDelegate <NSObject>

- (RLMBPaneViewController *)addPaneAfterPane:(RLMBPaneViewController *)pane;

@end


@interface RLMBPaneViewController : NSViewController

@property (weak, nonatomic) id<RLMBCanvasDelegate> canvasDelegate;

@property (weak) IBOutlet NSTextField *classNameLabel;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSTableView *tableView;

@property (nonatomic) RLMBFormatter *formatter;
@property (nonatomic) RLMObjectSchema *objectSchema;

@property (nonatomic) id<RLMCollection> objects;

- (void)setupColumnsWithProperties:(NSArray *)properties;
- (void)updateWithObjects:(id<RLMCollection>)objects objectSchema:(RLMObjectSchema *)objectSchema;

@end
