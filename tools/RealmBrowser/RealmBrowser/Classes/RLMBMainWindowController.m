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

@property (weak) IBOutlet NSScrollView *scrollView;

@property (nonatomic) NSView *canvas;

@property (nonatomic) NSMutableArray *panes;
@property (nonatomic) NSUInteger currentPane;

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

#pragma mark - Navigation

- (IBAction)navigateAction:(NSSegmentedControl *)sender {
    switch (sender.selectedSegment) {
        case 0:
            [self scrollTo:self.currentPane - 1];
            break;
        case 1:
            [self scrollTo:self.currentPane + 1];
            break;
        default:
            break;
    }
}

-(void)scrollTo:(NSUInteger)pane
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:2.0];
    NSClipView *clipView = [self.scrollView contentView];
    
    NSPoint newOrigin = [clipView bounds].origin;
    newOrigin.x = 100*pane;
    [[clipView animator] setBoundsOrigin:newOrigin];
    [NSAnimationContext endGrouping];

    self.currentPane = pane;
}

#pragma mark - Table View View Datasource - Sidebar

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.realm.schema.objectSchema.count + 1;
}


#pragma mark - Table View Delegate - Sidebar

-(BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    return row == 0;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row == 0) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"SidebarHeaderCell" owner:self];
        NSString *fileName = [[self.realm.path pathComponents] lastObject];
        cellView.textField.stringValue = [[fileName stringByDeletingPathExtension] uppercaseString];
        
        return cellView;
    }

    RLMBSidebarCellView *cellView = [tableView makeViewWithIdentifier:@"SidebarClassCell" owner:self];
    RLMObjectSchema *objectSchema = self.realm.schema.objectSchema[row - 1];
    cellView.textField.stringValue = objectSchema.className;
    cellView.badge.stringValue = @"12";
    cellView.badge.layer.cornerRadius = NSHeight(cellView.badge.frame)/2.0;
    cellView.badge.layer.cornerRadius = 10;
    cellView.badge.backgroundColor = [NSColor purpleColor];
    
    return cellView;
}

#pragma mark - Public methods - Property Setters



@end
