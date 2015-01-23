////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMBMainWindowController.h"

#import <Realm/Realm.h>
#import "RLMBHeaders_Private.h"

#import "RLMBPaneViewController.h"
#import "RLMBRootPaneViewController.h"
#import "RLMBArrayPaneViewController.h"
#import "RLMBObjectPaneViewController.h"

#import "RLMBSidebarCellView.h"

NSString *const kRLMBRightMostConstraint = @"RLMBRightMostConstraint";
NSString *const kRLMBWidthConstraint = @"RLMBWidthConstraint";
NSString *const kRLMBRightContentsConstraint = @"RLMBRightContentsConstraint";
NSString *const kRLMBLeftContentsConstraint = @"RLMBLeftContentsConstraint";
CGFloat const kRLMBPaneMargin = 20;
CGFloat const kRLMBPaneMMinHeight = 200;
CGFloat const kRLMBPaneThinWidth = 300;

@interface RLMBMainWindowController () <RLMBCanvasDelegate, RLMBRealmDelegate, NSTableViewDataSource, NSTableViewDelegate>

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

#pragma mark - Realm Delegate

- (void)setProperty:(NSString *)propertyName ofObject:(RLMObject *)object toValue:(id)value
{
    [self.realm beginWriteTransaction];
    object[propertyName] = value;
    [self.realm commitWriteTransaction];
}

- (void)deleteObjects:(NSArray *)objects
{
    NSLog(@"deleteObjects: %@", objects);

    [self.realm beginWriteTransaction];
    [self.realm deleteObjects:objects];
    [self.realm commitWriteTransaction];
}

- (void)removeObjectsAtIndices:(NSIndexSet *)rowIndices fromArray:(RLMArray *)array
{
    NSLog(@"removeObjectsAtIndices: %@", rowIndices);
    [self.realm beginWriteTransaction];
    [rowIndices enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger index, BOOL *stop) {
        [array removeObjectAtIndex:index];
    }];
    [self.realm commitWriteTransaction];
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

#pragma mark - Canvas Delegate

- (void)addPaneWithArray:(RLMArray *)array afterPane:(RLMBPaneViewController *)pane;
{
    [self removePanesAfterPane:pane];
    
    RLMBArrayPaneViewController *newPane = [[RLMBArrayPaneViewController alloc] initWithNibName:@"RLMBPaneViewController" bundle:nil];
    [self addPane:newPane];
    
    RLMObjectSchema *linkedObjectSchema = [array.realm.schema schemaForClassName:array.objectClassName];
    [newPane updateWithObjects:array objectSchema:linkedObjectSchema];
}

- (void)addPaneWithObject:(RLMObject *)object afterPane:(RLMBPaneViewController *)pane
{
    [self removePanesAfterPane:pane];

    RLMBObjectPaneViewController *newPane = [[RLMBObjectPaneViewController alloc] initWithNibName:@"RLMBPaneViewController" bundle:nil];
    [self addPane:newPane];
    
    RLMObjectSchema *linkedObjectSchema = object.objectSchema;
    RLMArray *array = [[RLMArray alloc] initWithObjectClassName:linkedObjectSchema.className];
    [array addObject:object];
    [newPane updateWithObjects:array objectSchema:linkedObjectSchema];
}

- (void)toggleWidthOfPane:(RLMBPaneViewController *)pane toWide:(BOOL)wide
{
    if (pane.isWide != wide) {
        [self.scrollView.contentView removeConstraint:pane.widthConstraint];
        pane.widthConstraint = [self addWidthContentConstraintTo:pane.view within:self.scrollView.contentView fullWidth:wide];
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

#pragma mark - Private Methods - Pane Handling

- (void)showClassInRootPane:(NSUInteger)row
{
    [self removePanesAfterPane:self.rootPane];
    
    RLMResults *objects = self.objectClasses[row];
    RLMObjectSchema *objectSchema = self.realm.schema[objects.objectClassName];
    [self.rootPane updateWithObjects:objects objectSchema:objectSchema];

    [self focusOnPane:0];
}

- (void)addPane:(RLMBPaneViewController *)pane
{
    [self.canvas addSubview:pane.view];
    [self addVerticalConstraintsTo:pane.view within:self.canvas];
    
    BOOL isRoot = self.panes.count == 0;
    pane.widthConstraint = [self addWidthContentConstraintTo:pane.view within:self.scrollView.contentView fullWidth:isRoot];
    
    RLMBPaneViewController *lastPane = self.panes.lastObject;
    [self addLeftConstraintTo:pane.view after:lastPane.view within:self.canvas];
    
    [self removeConstraintWithIdentifier:kRLMBRightMostConstraint inView:self.canvas];
    [self addRightConstraintTo:pane.view within:self.canvas];
    
    pane.canvasDelegate = self;
    pane.realmDelegate = self;
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
    NSLog(@"focusOnPane: %lu", index);

    if (index < 0 || index > self.panes.count) {
        return;
    }
    else if (index == self.panes.count) {
        [self makePaneWide:self.panes.count - 1];
        self.focusedPane = self.panes.count;
        return;
    }
    else if (index == 0) {
        [self makePaneWide:0];
    }
    else {
        [self makePaneWide:NSNotFound];
    }
    
    self.focusedPane = index;

    NSView *contentView = self.scrollView.contentView;
    [self removeConstraintWithIdentifier:kRLMBRightContentsConstraint inView:contentView];

    RLMBPaneViewController *thisPane = self.panes[index];
    [self addRightContentConstraintsTo:thisPane.view within:contentView];
}

- (void)makePaneWide:(NSInteger)index
{
    for (NSInteger i = 0; i < self.panes.count; i++) {
        [self toggleWidthOfPane:self.panes[i] toWide:i == index];
    }
}

//- (void)scrollToPane:(NSUInteger)index
//{
//    NSView *pane = [self.panes[index] view];
//    
//    NSClipView *clipView = self.scrollView.contentView;
//    NSPoint corner;
//    corner.x = NSMaxX(pane.frame) + kRLMBPaneMargin - NSWidth(clipView.bounds);
//    
//    [NSAnimationContext beginGrouping];
//    [[NSAnimationContext currentContext] setDuration:0.5];
//    [clipView.animator setBoundsOrigin:corner];
//    [NSAnimationContext endGrouping];
//}

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

- (NSLayoutConstraint *)addWidthContentConstraintTo:(NSView *)pane within:(NSView *)contentView fullWidth:(BOOL)fullWidth
{
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:pane
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:contentView
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:fullWidth ? 1.0 : 0.5
                                                                        constant:-(fullWidth ? 2.0 : 1.5)*kRLMBPaneMargin];

    [contentView addConstraint:widthConstraint];

    return widthConstraint;
}

#pragma mark - Private methods - Constraint Helper Methods

- (void)removeConstraintWithIdentifier:(NSString *)identifier inView:(NSView *)view
{
    [view removeConstraint:[self constraintWithIdentifier:identifier inView:view]];
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
