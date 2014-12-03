//
//  RLMBMainWindowController.m
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 20/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import "RLMBMainWindowController.h"

#import <Realm/Realm.h>
#import "RLMBHeaders_Private.h"

#import "RLMBPaneViewController.h"
#import "RLMBRootPaneViewController.h"

#import "RLMBSidebarCellView.h"

NSString *const kRLMBRightMostConstraint = @"RLMBRightMostConstraint";
NSString *const kRLMBWidthConstraint = @"RLMBWidthConstraint";
NSString *const kRLMBRightContentsConstraint = @"RLMBRightContentsConstraint";
NSString *const kRLMBLeftContentsConstraint = @"RLMBLeftContentsConstraint";
CGFloat const kRLMBPaneMargin = 20;
CGFloat const kRLMBPaneMMinHeight = 200;
CGFloat const kRLMBPaneThinWidth = 300;

@interface RLMBMainWindowController () <RLMBCanvasDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic) RLMRealm *realm;
@property (nonatomic) NSMutableArray *objectClasses;

@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet NSTableView *sidebarTableView;

@property (nonatomic) NSView *canvas;

@property (nonatomic) NSMutableArray *panes;
@property (nonatomic) RLMBRootPaneViewController *rootPane;

@property (nonatomic) NSInteger focusedPane;

@end


@implementation RLMBMainWindowController

#pragma mark - Lifetime Methods

- (instancetype)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.panes = [NSMutableArray array];
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    if ([self.window respondsToSelector:@selector(setTitleVisibility:)]) {
        self.window.titleVisibility = NSWindowTitleHidden;
    }
    
    self.canvas = [[NSView alloc] init];
    self.canvas.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.scrollView.documentView = self.canvas;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_canvas);
//    [self.scrollView.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_canvas]"
//                                                                                        options:0
//                                                                                        metrics:nil
//                                                                                          views:views]];
    
    [self.scrollView.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_canvas]|"
                                                                                        options:0
                                                                                        metrics:nil
                                                                                          views:views]];
    
    if (self.objectClasses.count > 0) {
        [self setupSidebarHeader];
        [self setupRootPane];
        [self showClassInRootPane:0];
    }
}

#pragma mark - Navigation Action

- (IBAction)navigateAction:(NSSegmentedControl *)sender {
    switch (sender.selectedSegment) {
        case 0:
            [self focusOnPane:self.focusedPane - 1];
            break;
        case 1:
            [self focusOnPane:self.focusedPane + 1];
            break;
        default:
            break;
    }
}

#pragma mark - Table View View Datasource - Sidebar

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.objectClasses.count;
}

#pragma mark - Table View Delegate - Sidebar

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    RLMBSidebarCellView *cellView = [tableView makeViewWithIdentifier:@"SidebarClassCell" owner:self];
    RLMResults *objects = self.objectClasses[row];
    cellView.textField.stringValue = objects.objectClassName;
    cellView.badge.stringValue = @(objects.count).stringValue;
    //    cellView.badge.layer.cornerRadius = NSHeight(cellView.badge.frame)/2.0;
    //    cellView.badge.layer.cornerRadius = 10;
    //    cellView.badge.backgroundColor = [NSColor purpleColor];
    
    return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if (notification.object == self.sidebarTableView) {
        NSInteger row = self.sidebarTableView.selectedRow;
        
        if (row < self.objectClasses.count && row >= 0) {
            [self showClassInRootPane:row];
        }
    }
}

#pragma mark - Setup Methods

- (void)setupWithRealm:(RLMRealm *)realm
{
    self.realm = realm;

    NSMutableArray *objectClasses = [NSMutableArray array];
    for (RLMObjectSchema *objectSchema in self.realm.schema.objectSchema) {
        RLMResults *objects = [self.realm allObjects:objectSchema.className];
        [objectClasses addObject:objects];
    }
    self.objectClasses = objectClasses;
    
    if (self.objectClasses.count > 0 && self.canvas) {
        [self setupSidebarHeader];
        [self setupRootPane];
        [self showClassInRootPane:0];
    }
}

- (void)setupSidebarHeader
{
    NSString *fileName = [[self.realm.path pathComponents] lastObject];
    NSTableColumn *tableColumn = self.sidebarTableView.tableColumns.firstObject;
    NSTableHeaderCell *cell = tableColumn.headerCell;
    cell.stringValue = fileName;
}

- (void)setupRootPane
{
    if (!self.rootPane) {
        self.rootPane = [[RLMBRootPaneViewController alloc] initWithNibName:@"RLMBPaneViewController" bundle:nil];
        [self addPane:self.rootPane];
    }
}

#pragma mark - Private Methods - Pane Handling

- (void)showClassInRootPane:(NSUInteger)row
{
    [self removePanesAfterPane:self.rootPane];
    [self removeWidthConstraintFrom:self.rootPane.view];
    [self removeRightContentsConstraintFrom:self.scrollView.contentView];
    [self addRightContentConstraintsTo:self.rootPane.view within:self.scrollView.contentView];
    [self removeLeftContentsConstraintFrom:self.scrollView.contentView];
    [self addLeftContentConstraintsTo:self.rootPane.view within:self.scrollView.contentView];
    
    RLMResults *objects = self.objectClasses[row];
    RLMObjectSchema *objectSchema = self.realm.schema[objects.objectClassName];
    [self.rootPane updateWithObjects:objects objectSchema:objectSchema];
    self.focusedPane = 0;
}

- (RLMBPaneViewController *)addPaneAfterPane:(RLMBPaneViewController *)pane
{
    [self removePanesAfterPane:pane];
    
    RLMBPaneViewController *newPane = [[RLMBPaneViewController alloc] initWithNibName:@"RLMBPaneViewController" bundle:nil];
    [self addPane:newPane];
    return newPane;
}

- (void)addPane:(RLMBPaneViewController *)pane
{
    [self.canvas addSubview:pane.view];
    [self addVerticalConstraintsTo:pane.view within:self.canvas];
    
    RLMBPaneViewController *lastPane = self.panes.lastObject;
    [self addLeftConstraintTo:pane.view after:lastPane.view within:self.canvas];
    
    [self removeRightConstraintFrom:self.canvas];
    [self addRightConstraintTo:pane.view within:self.canvas];
    
    pane.canvasDelegate = self;
    [self.panes addObject:pane];
    [self focusOnPane:self.panes.count - 1];
}

- (void)removePanesAfterPane:(RLMBPaneViewController *)pane
{
    while (self.panes.lastObject != pane) {
        [self removeLastPane];
    }
}
    
- (void)removeLastPane
{
    RLMBPaneViewController *paneVC = self.panes.lastObject;
    [paneVC.view removeFromSuperview];
    [self.panes removeLastObject];
    [self addRightConstraintTo:[self.panes.lastObject view] within:self.canvas];
}

#pragma mark - Private Methods - Navigation

- (void)focusOnPane:(NSInteger)index
{
    if (index < 0 || index > self.panes.count - 1) {
        return;
    }
    
    NSView *contentView = self.scrollView.contentView;
    [self removeLeftContentsConstraintFrom:contentView];
    [self removeRightContentsConstraintFrom:contentView];
    
    RLMBPaneViewController *prevPane = self.panes[MAX(index - 1, 0)];
    RLMBPaneViewController *thisPane = self.panes[index];
    
    [self removeWidthConstraintFrom:thisPane.view];
    [self removeWidthConstraintFrom:prevPane.view];
    [self addLeftContentConstraintsTo:prevPane.view within:contentView];
    [self addRightContentConstraintsTo:thisPane.view within:contentView];
    
    if (prevPane != thisPane) {
        [self addWidthConstraintTo:prevPane.view];
    }
    self.focusedPane = index;
}

- (void)scrollToPane:(NSUInteger)index
{
    NSView *pane = [self.panes[index] view];
    
    NSClipView *clipView = self.scrollView.contentView;
    NSPoint corner;
    corner.x = NSMaxX(pane.frame) + kRLMBPaneMargin - NSWidth(clipView.bounds);
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.5];
    [clipView.animator setBoundsOrigin:corner];
    [NSAnimationContext endGrouping];
}

#pragma mark - Private Methods - Constraints

- (void)addVerticalConstraintsTo:(NSView *)pane within:(NSView *)canvas
{
    pane.translatesAutoresizingMaskIntoConstraints = NO;
    
    [pane addConstraint:[NSLayoutConstraint constraintWithItem:pane
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1
                                                      constant:kRLMBPaneMMinHeight]];
    
    [canvas addConstraint:[NSLayoutConstraint constraintWithItem:pane
                                                       attribute:NSLayoutAttributeTop
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:canvas
                                                       attribute:NSLayoutAttributeTop
                                                      multiplier:1
                                                        constant:kRLMBPaneMargin]];
    
    [canvas addConstraint:[NSLayoutConstraint constraintWithItem:canvas
                                                       attribute:NSLayoutAttributeBottom
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:pane
                                                       attribute:NSLayoutAttributeBottom
                                                      multiplier:1
                                                        constant:kRLMBPaneMargin]];
}

- (void)addLeftConstraintTo:(NSView *)pane after:(NSView *)previousPane within:(NSView *)canvas
{
    if (previousPane) {
        [canvas addConstraint:[NSLayoutConstraint constraintWithItem:pane
                                                           attribute:NSLayoutAttributeLeft
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:previousPane
                                                           attribute:NSLayoutAttributeRight
                                                          multiplier:1
                                                            constant:kRLMBPaneMargin]];
    }
    else {
        [canvas addConstraint:[NSLayoutConstraint constraintWithItem:pane
                                                           attribute:NSLayoutAttributeLeft
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:canvas
                                                           attribute:NSLayoutAttributeLeft
                                                          multiplier:1
                                                            constant:kRLMBPaneMargin]];
    }
}

- (void)addRightConstraintTo:(NSView *)pane within:(NSView *)canvas
{
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:canvas
                                                                       attribute:NSLayoutAttributeRight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:pane
                                                                       attribute:NSLayoutAttributeRight
                                                                      multiplier:1
                                                                        constant:kRLMBPaneMargin];
    rightConstraint.identifier = kRLMBRightMostConstraint;
    [canvas addConstraint:rightConstraint];
}

- (void)addLeftContentConstraintsTo:(NSView *)pane within:(NSView *)contentView
{
    if (!pane) {
        return;
    }
    
    NSLayoutConstraint *leftContentConstraint = [NSLayoutConstraint constraintWithItem:pane
                                                                             attribute:NSLayoutAttributeLeft
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:contentView
                                                                             attribute:NSLayoutAttributeLeft
                                                                            multiplier:1
                                                                              constant:kRLMBPaneMargin];
    leftContentConstraint.identifier = kRLMBLeftContentsConstraint;
    [contentView addConstraint:leftContentConstraint];
}

- (void)addRightContentConstraintsTo:(NSView *)pane within:(NSView *)contentView
{
    NSLayoutConstraint *rightContentConstraint = [NSLayoutConstraint constraintWithItem:contentView
                                                                              attribute:NSLayoutAttributeRight
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:pane
                                                                              attribute:NSLayoutAttributeRight
                                                                             multiplier:1
                                                                               constant:kRLMBPaneMargin];
    rightContentConstraint.identifier = kRLMBRightContentsConstraint;
    [contentView addConstraint:rightContentConstraint];
}

- (void)addWidthConstraintTo:(NSView *)pane
{
    if (!pane) {
        return;
    }
    
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:pane
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1
                                                                        constant:kRLMBPaneThinWidth];
    widthConstraint.identifier = kRLMBWidthConstraint;
    [pane addConstraint:widthConstraint];
}

- (void)removeRightConstraintFrom:(NSView *)view
{
    [view removeConstraint:[self constraintWithIdentifier:kRLMBRightMostConstraint inView:view]];
}

- (void)removeLeftContentsConstraintFrom:(NSView *)view
{
    [view removeConstraint:[self constraintWithIdentifier:kRLMBLeftContentsConstraint inView:view]];
}

- (void)removeRightContentsConstraintFrom:(NSView *)view
{
    [view removeConstraint:[self constraintWithIdentifier:kRLMBRightContentsConstraint inView:view]];
}

- (void)removeWidthConstraintFrom:(NSView *)view
{
    [view removeConstraint:[self constraintWithIdentifier:kRLMBWidthConstraint inView:view]];
}

- (NSLayoutConstraint *)constraintWithIdentifier:(NSString *)identifier inView:(NSView *)view
{
    for (NSLayoutConstraint *constraint in view.constraints) {
        if ([constraint.identifier isEqualToString:identifier]) {
            return constraint;
        }
    }
    return nil;
}

#pragma mark - Private methods - Accessors


@end
