//
//  RLMBMainWindowController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 20/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBMainWindowController.h"
#import <Realm/Realm.h>
#import "RLMBPaneViewController.h"
#import "RLMBSidebarCellView.h"

@interface RLMBMainWindowController () <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSOutlineView *sideBar;

@property (weak) IBOutlet NSScrollView *scrollView;

@property (nonatomic) NSView *canvas;

@property (nonatomic) NSMutableArray *panes;
@property (nonatomic) NSLayoutConstraint *rightMostMarginConstraint;

@end

@implementation RLMBMainWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.window.titleVisibility = NSWindowTitleHidden;
    self.panes = [NSMutableArray array];
    
    self.canvas = [[NSView alloc] init];
    self.canvas.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.scrollView.documentView = self.canvas;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_canvas);
    NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_canvas]"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:views];
    
    NSArray *vConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_canvas]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:views];
    
    [self.scrollView.contentView addConstraints:hConstraints];
    [self.scrollView.contentView addConstraints:vConstraints];
    
    [self addPane];
    [self addPane];
    [self addPane];
}

- (void)addPane
{
    RLMBPaneViewController *paneVC = [[RLMBPaneViewController alloc] initWithNibName:@"RLMBPaneViewController" bundle:nil];
    [self.canvas addSubview:paneVC.view];
    
    paneVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [paneVC.view addConstraint:[NSLayoutConstraint constraintWithItem:paneVC.view
                                                            attribute:NSLayoutAttributeHeight
                                                            relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                               toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                           multiplier:1
                                                             constant:200]];
    
    [paneVC.view addConstraint:[NSLayoutConstraint constraintWithItem:paneVC.view
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                           multiplier:1
                                                             constant:300]];
    
    
    [self.canvas addConstraint:[NSLayoutConstraint constraintWithItem:paneVC.view
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.canvas
                                                            attribute:NSLayoutAttributeTop
                                                           multiplier:1
                                                             constant:50]];
    
    [self.canvas addConstraint:[NSLayoutConstraint constraintWithItem:self.canvas
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:paneVC.view
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1
                                                             constant:50]];
    
    RLMBPaneViewController *previousPane = self.panes.lastObject;
    
    if (previousPane.view) {
        [self.canvas addConstraint:[NSLayoutConstraint constraintWithItem:paneVC.view
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:previousPane.view
                                                                attribute:NSLayoutAttributeRight
                                                               multiplier:1
                                                                 constant:50]];
        
        [self.canvas removeConstraint:self.rightMostMarginConstraint];
    }
    else {
        [self.canvas addConstraint:[NSLayoutConstraint constraintWithItem:paneVC.view
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.canvas
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1
                                                                 constant:50]];
    }
    
    NSLayoutConstraint *rightMargin = [NSLayoutConstraint constraintWithItem:self.canvas
                                                                   attribute:NSLayoutAttributeRight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:paneVC.view
                                                                   attribute:NSLayoutAttributeRight
                                                                  multiplier:1
                                                                    constant:50];
    
    [self.canvas addConstraint:rightMargin];
    self.rightMostMarginConstraint = rightMargin;
    
    [self.panes addObject:paneVC];
}

#pragma mark - Table View Datasource - Sidebar

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSLog(@"number of rows: %lu", self.realm.schema.objectSchema.count);

    return self.realm.schema.objectSchema.count;
}

#pragma mark - Table View Delegate - Sidebar

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    RLMBSidebarCellView *cellview = [tableView makeViewWithIdentifier:@"ClassCell" owner:self.owner];
    RLMObjectSchema *objectSchema = self.realm.schema.objectSchema[row];
    cellview.textField.stringValue = objectSchema.className;
    cellview.badge.stringValue = @"12";
    
    NSLog(@"row %lu: %@", row, objectSchema.className);
    
    return cellview;
}

#pragma mark - Public methods - Property Setters



@end
