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

#import "RLMRealmBrowserWindowController.h"
#import "RLMNavigationStack.h"
#import "RLMModelExporter.h"
#import "Realm_Private.h"

NSString * const kRealmLockedImage = @"RealmLocked";
NSString * const kRealmUnlockedImage = @"RealmUnlocked";
NSString * const kRealmLockedTooltip = @"Unlock to enable editing";
NSString * const kRealmUnlockedTooltip = @"Lock to prevent editing";
NSString * const kRealmKeyIsLockedForRealm = @"LockedRealm:%@";

NSString * const kRealmKeyWindowFrameForRealm = @"WindowFrameForRealm:%@";
NSString * const kRealmKeyOutlineWidthForRealm = @"OutlineWidthForRealm:%@";

@interface RLMRealmBrowserWindowController()<NSWindowDelegate>

@property (atomic, weak) IBOutlet NSSplitView *splitView;
@property (nonatomic, strong) IBOutlet NSSegmentedControl *navigationButtons;
@property (atomic, weak) IBOutlet NSToolbarItem *lockRealmButton;
@property (nonatomic, strong) IBOutlet NSSearchField *searchField;

@end

@implementation RLMRealmBrowserWindowController {
    RLMNavigationStack *navigationStack;
}

#pragma mark - NSViewController Overrides

- (void)windowDidLoad
{
    navigationStack = [[RLMNavigationStack alloc] init];
    self.window.alphaValue = 0.0;
}

#pragma mark - RLMViewController Overrides

-(void)realmDidLoad
{
    [self.outlineViewController realmDidLoad];
    [self.tableViewController realmDidLoad];
    
    [self updateNavigationButtons];
    
    id firstItem = self.modelDocument.presentedRealm.topLevelClasses.firstObject;
    if (firstItem != nil) {
        RLMNavigationState *initState = [[RLMNavigationState alloc] initWithSelectedType:firstItem index:0];
        [self addNavigationState:initState fromViewController:nil];
    }

    NSString *realmPath = self.modelDocument.presentedRealm.realm.path;
    [self setWindowFrameAutosaveName:[NSString stringWithFormat:kRealmKeyWindowFrameForRealm, realmPath]];
    [self.splitView setAutosaveName:[NSString stringWithFormat:kRealmKeyOutlineWidthForRealm, realmPath]];
    
    [self reloadAfterEdit];
    self.window.alphaValue = 1.0;
}

#pragma mark - Public methods - Accessors

- (RLMNavigationState *)currentState
{
    return navigationStack.currentState;
}

#pragma mark - Public methods - Menu items

- (IBAction)saveJavaModels:(id)sender
{
    NSArray *objectSchemas = self.modelDocument.presentedRealm.realm.schema.objectSchema;
    [RLMModelExporter saveModelsForSchemas:objectSchemas inLanguage:kLanguageJava];
}

- (IBAction)saveObjcModels:(id)sender
{
    NSArray *objectSchemas = self.modelDocument.presentedRealm.realm.schema.objectSchema;
    [RLMModelExporter saveModelsForSchemas:objectSchemas inLanguage:kLanguageObjC];
}

#pragma mark - Public methods - User Actions

- (void)reloadAllWindows
{
    NSArray *windowControllers = [self.modelDocument windowControllers];
    
    for (RLMRealmBrowserWindowController *wc in windowControllers) {
        [wc reloadAfterEdit];
    }
}

- (void)reloadAfterEdit
{
    [self.outlineViewController.tableView reloadData];
    
    NSString *realmPath = self.modelDocument.presentedRealm.realm.path;
    NSString *key = [NSString stringWithFormat:kRealmKeyIsLockedForRealm, realmPath];
    
    BOOL realmIsLocked = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    self.tableViewController.realmIsLocked = realmIsLocked;
    self.lockRealmButton.image = [NSImage imageNamed:realmIsLocked ? kRealmLockedImage : kRealmUnlockedImage];
    self.lockRealmButton.toolTip = realmIsLocked ? kRealmLockedTooltip : kRealmUnlockedTooltip;
    
    [self.tableViewController.tableView reloadData];
}

#pragma mark - Public methods - Rearranging arrays

- (void)removeRowsInTableViewForArrayNode:(RLMArrayNode *)arrayNode at:(NSIndexSet *)rowIndexes
{
    for (RLMRealmBrowserWindowController *wc in [self.modelDocument windowControllers]) {
        if ([arrayNode isEqualTo:wc.tableViewController.displayedType]) {
            [wc.tableViewController removeRowsInTableViewAt:rowIndexes];
        }
        [wc.outlineViewController.tableView reloadData];
    }
}

- (void)deleteRowsInTableViewForArrayNode:(RLMArrayNode *)arrayNode at:(NSIndexSet *)rowIndexes
{
    for (RLMRealmBrowserWindowController *wc in [self.modelDocument windowControllers]) {
        if ([arrayNode isEqualTo:wc.tableViewController.displayedType]) {
            [wc.tableViewController deleteRowsInTableViewAt:rowIndexes];
        }
        else {
            [wc reloadAfterEdit];
        }
        [wc.outlineViewController.tableView reloadData];
    }
}

- (void)insertNewRowsInTableViewForArrayNode:(RLMArrayNode *)arrayNode at:(NSIndexSet *)rowIndexes
{
    for (RLMRealmBrowserWindowController *wc in [self.modelDocument windowControllers]) {
        if ([arrayNode isEqualTo:wc.tableViewController.displayedType]) {
            [wc.tableViewController insertNewRowsInTableViewAt:rowIndexes];
        }
        else {
            [wc reloadAfterEdit];
        }
        [wc.outlineViewController.tableView reloadData];
    }
}

- (void)moveRowsInTableViewForArrayNode:(RLMArrayNode *)arrayNode from:(NSIndexSet *)sourceIndexes to:(NSUInteger)destination
{
    for (RLMRealmBrowserWindowController *wc in [self.modelDocument windowControllers]) {
        if ([arrayNode isEqualTo:wc.tableViewController.displayedType]) {
            [wc.tableViewController moveRowsInTableViewFrom:sourceIndexes to:destination];
        }
    }
}

#pragma mark - Public methods - Navigation

- (void)addNavigationState:(RLMNavigationState *)state fromViewController:(RLMViewController *)controller
{
    if (!controller.navigationFromHistory) {
        RLMNavigationState *oldState = navigationStack.currentState;
        
        [navigationStack pushState:state];
        [self updateNavigationButtons];
        
        if (controller == self.tableViewController || controller == nil) {
            [self.outlineViewController updateUsingState:state oldState:oldState];
        }
        
        [self.tableViewController updateUsingState:state oldState:oldState];
    }

    // Searching is not implemented for link arrays yet
    BOOL isArray = [state isMemberOfClass:[RLMArrayNavigationState class]];
    [self.searchField setEnabled:!isArray];
}

- (void)newWindowWithNavigationState:(RLMNavigationState *)state
{
    RLMRealmBrowserWindowController *wc = [[RLMRealmBrowserWindowController alloc] initWithWindowNibName:self.windowNibName];
    wc.modelDocument = self.modelDocument;
    wc.window.alphaValue = 1.0;
    [wc.outlineViewController realmDidLoad];
    [self.modelDocument addWindowController:wc];
    [self.modelDocument showWindows];
    [wc addNavigationState:state fromViewController:wc.tableViewController];
}

- (IBAction)userClicksOnNavigationButtons:(NSSegmentedControl *)buttons
{
    RLMNavigationState *oldState = navigationStack.currentState;
    
    switch (buttons.selectedSegment) {
        case 0: { // Navigate backwards
            RLMNavigationState *state = [navigationStack navigateBackward];
            if (state != nil) {
                [self.outlineViewController updateUsingState:state oldState:oldState];
                [self.tableViewController updateUsingState:state oldState:oldState];
            }
            break;
        }
        case 1: { // Navigate forwards
            RLMNavigationState *state = [navigationStack navigateForward];
            if (state != nil) {
                [self.outlineViewController updateUsingState:state oldState:oldState];
                [self.tableViewController updateUsingState:state oldState:oldState];
            }
            break;
        }
        default:
            break;
    }
    
    [self updateNavigationButtons];
}

- (IBAction)userClickedLockRealm:(id)sender
{
    NSString *realmPath = self.modelDocument.presentedRealm.realm.path;
    NSString *key = [NSString stringWithFormat:kRealmKeyIsLockedForRealm, realmPath];

    BOOL currentlyLocked = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    [self setRealmLocked:!currentlyLocked];
}

-(void)setRealmLocked:(BOOL)locked
{
    NSString *realmPath = self.modelDocument.presentedRealm.realm.path;
    NSString *key = [NSString stringWithFormat:kRealmKeyIsLockedForRealm, realmPath];
    [[NSUserDefaults standardUserDefaults] setBool:locked forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self reloadAllWindows];
}

- (IBAction)searchAction:(NSSearchFieldCell *)searchCell
{
    NSString *searchText = searchCell.stringValue;
    RLMTypeNode *typeNode = navigationStack.currentState.selectedType;

    // Return to parent class (showing all objects) when the user clears the search text
    if (searchText.length == 0) {
        if ([navigationStack.currentState isMemberOfClass:[RLMQueryNavigationState class]]) {
            RLMNavigationState *state = [[RLMNavigationState alloc] initWithSelectedType:typeNode index:0];
            [self addNavigationState:state fromViewController:self.tableViewController];
        }
        return;
    }

    NSArray *columns = typeNode.propertyColumns;
    NSUInteger columnCount = columns.count;
    RLMRealm *realm = self.modelDocument.presentedRealm.realm;

    NSString *predicate = @"";

    for (NSUInteger index = 0; index < columnCount; index++) {

        RLMClassProperty *property = columns[index];
        NSString *columnName = property.name;

        switch (property.type) {
            case RLMPropertyTypeBool: {
                if ([searchText caseInsensitiveCompare:@"true"] == NSOrderedSame ||
                    [searchText caseInsensitiveCompare:@"YES"] == NSOrderedSame) {
                    if (predicate.length != 0) {
                        predicate = [predicate stringByAppendingString:@" OR "];
                    }
                    predicate = [predicate stringByAppendingFormat:@"%@ = YES", columnName];
                }
                else if ([searchText caseInsensitiveCompare:@"false"] == NSOrderedSame ||
                         [searchText caseInsensitiveCompare:@"NO"] == NSOrderedSame) {
                    if (predicate.length != 0) {
                        predicate = [predicate stringByAppendingString:@" OR "];
                    }
                    predicate = [predicate stringByAppendingFormat:@"%@ = NO", columnName];
                }
                break;
            }
            case RLMPropertyTypeInt: {
                int value;
                if ([searchText isEqualToString:@"0"]) {
                    value = 0;
                }
                else {
                    value = [searchText intValue];
                    if (value == 0)
                        break;
                }

                if (predicate.length != 0) {
                    predicate = [predicate stringByAppendingString:@" OR "];
                }
                predicate = [predicate stringByAppendingFormat:@"%@ = %d", columnName, (int)value];
                break;
            }
            case RLMPropertyTypeString: {
                if (predicate.length != 0) {
                    predicate = [predicate stringByAppendingString:@" OR "];
                }
                predicate = [predicate stringByAppendingFormat:@"%@ CONTAINS '%@'", columnName, searchText];
                break;
            }
            //case RLMPropertyTypeFloat: // search on float columns disabled until bug is fixed in binding
            case RLMPropertyTypeDouble: {
                double value;

                if ([searchText isEqualToString:@"0"] ||
                    [searchText isEqualToString:@"0.0"]) {
                    value = 0.0;
                }
                else {
                    value = [searchText doubleValue];
                    if (value == 0.0)
                        break;
                }

                if (predicate.length != 0) {
                    predicate = [predicate stringByAppendingString:@" OR "];
                }
                predicate = [predicate stringByAppendingFormat:@"%@ = %f", columnName, value];
                break;
            }
            default:
                break;
        }
    }

    RLMResults *result;
    
    if (predicate.length != 0) {
        result = [realm objects:typeNode.name where:predicate];
    }

    RLMQueryNavigationState *state = [[RLMQueryNavigationState alloc] initWithQuery:searchText type:typeNode results:result];
    [self addNavigationState:state fromViewController:self.tableViewController];
}

#pragma mark - Private methods

- (void)updateNavigationButtons
{
    [self.navigationButtons setEnabled:[navigationStack canNavigateBackward] forSegment:0];
    [self.navigationButtons setEnabled:[navigationStack canNavigateForward] forSegment:1];
}


@end
