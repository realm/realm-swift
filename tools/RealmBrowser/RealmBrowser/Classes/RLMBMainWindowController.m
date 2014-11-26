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

@interface RLMBMainWindowController () <NSOutlineViewDataSource, NSOutlineViewDelegate>

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

#pragma mark - Outline View Datasource - Sidebar

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        NSLog(@"number of children for nil: 1");
        return 1;
    }
    else if ([item isKindOfClass:[RLMSchema class]]) {
        NSLog(@"number of children for %@: %lu", [item className], ((RLMSchema *)item).objectSchema.count);
        return ((RLMSchema *)item).objectSchema.count;
    }

    NSLog(@"number of children for %@: 0", [item className]);
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        NSLog(@"child %lu of nil", index);
        return self.realm.schema;
    }
    else if ([item isKindOfClass:[RLMSchema class]]) {
        NSLog(@"child %lu of: %@", index, item);
        return ((RLMSchema *)item).objectSchema[index];
    }

    NSLog(@"?child %lu of: %@", index, item);

    return nil;
}

#pragma mark - Outline View Delegate - Sidebar

-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    NSLog(@"view for item: %@", item);
    
    if ([item isKindOfClass:[RLMSchema class]]) {
        NSTableCellView *headerCell = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        headerCell.textField.stringValue = @"CLASSES";
        NSLog(@"---view CLASSES: %@", headerCell);
        
        return headerCell;
    }
    else if ([item isKindOfClass:[RLMObjectSchema class]]) {
        RLMBSidebarCellView *cellView = [outlineView makeViewWithIdentifier:@"SidebarClassCell" owner:self];
        RLMObjectSchema *objectSchema = item;
        cellView.textField.stringValue = objectSchema.className;
        cellView.badge.stringValue = @"12";
        
        NSLog(@"---view %@", objectSchema.className);
        
        return cellView;
    }
    
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    NSLog(@"isItemExpandable yes: %@", item);
    return YES;

    
    if (item == nil) {
        NSLog(@"isItemExpandable yes: %@", item);
        return YES;
    }
    else {
        NSLog(@"isItemExpandable no: %@", item);
       return NO;
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
    return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
//    NSOutlineView *outlineView = notification.object;
//    if (outlineView == self.classesOutlineView) {
//        NSInteger row = [outlineView selectedRow];
//        
//        // The arrays we get from link views are ephemeral, so we
//        // remove them when any class node is selected
//        if (row != -1) {
//            [self selectedItem:[outlineView itemAtRow:row]];
//        }
//    }
}



#pragma mark - Public methods - Property Setters



@end
