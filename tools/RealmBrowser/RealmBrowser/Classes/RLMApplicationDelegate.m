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

#import "RLMApplicationDelegate.h"

#import <Realm/Realm.h>

#import "TestClasses.h"

NSString *const kRealmFileExension = @"realm";

const NSUInteger kTestDatabaseSizeMultiplicatorFactor = 2000;
const NSUInteger kTopTipDelay = 250;

@interface RLMApplicationDelegate ()

@property (nonatomic) BOOL didLoadFile;

@property (nonatomic) NSMetadataQuery *query;

@property (nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation RLMApplicationDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [[NSUserDefaults standardUserDefaults] setObject:@(kTopTipDelay) forKey:@"NSInitialToolTipDelay"];
    
    if (!self.didLoadFile) {
        NSInteger openFileIndex = [self.fileMenu indexOfItem:self.openMenuItem];
        [self.fileMenu performActionForItemAtIndex:openFileIndex];
        
        self.query = [[NSMetadataQuery alloc] init];
        [self.query setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:(id)kMDItemContentModificationDate ascending:NO]]];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(kMDItemFSName like[c] %@)", @"*.realm"];
        [self.query setPredicate:predicate];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryNote:) name:nil object:self.query];
        
        [self.query startQuery];
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)filename
{
    [self openFileAtURL:[NSURL fileURLWithPath:filename]];
    self.didLoadFile = YES;

    return YES;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)application
{
    return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)application hasVisibleWindows:(BOOL)flag
{
    return NO;
}

#pragma mark - Event handling

- (void)queryNote:(NSNotification *)note {
    if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
        [self updateFileItems];
    } else if ([[note name] isEqualToString:NSMetadataQueryDidUpdateNotification]) {
        [self updateFileItems];
    }
}

-(void)menuNeedsUpdate:(NSMenu *)menu
{
    if (menu == self.openAnyRealmMenu) {
        [menu removeAllItems];
        NSArray *allItems = [self.groupedFileItems valueForKeyPath:@"Items.@unionOfArrays.self"];
        [self updateMenu:menu withItems:allItems indented:YES];
    }
}

-(void)updateMenu:(NSMenu *)menu withItems:(NSArray *)items indented:(BOOL)indented
{
    NSImage *image = [NSImage imageNamed:@"AppIcon"];
    image.size = NSMakeSize(kMenuImageSize, kMenuImageSize);
    
    for (id item in items) {
        // Category heading, create disabled menu item with corresponding name
        if ([item isKindOfClass:[NSString class]]) {
            NSMenuItem *categoryItem = [[NSMenuItem alloc] init];
            categoryItem.title = (NSString *)item;
            [categoryItem setEnabled:NO];
            [menu addItem:categoryItem];
        }
        // Array of items, create cubmenu and set them up there by calling this method recursively
        else if ([item isKindOfClass:[NSArray class]]) {
            NSMenuItem *submenuItem = [[NSMenuItem alloc] init];
            submenuItem.title = @"More";
            submenuItem.indentationLevel = 1;
            [menu addItem:submenuItem];
            
            NSMenu *submenu = [[NSMenu alloc] initWithTitle:@"More"];
            NSArray *subitems = item;
            [self updateMenu:submenu withItems:subitems indented:NO];
            [menu setSubmenu:submenu forItem:submenuItem];
        }
        // Normal file item, just create a menu item for it and wire it up
        else if ([item isMemberOfClass:[NSMetadataItem class]]) {
            NSMetadataItem *metadataItem = (NSMetadataItem *)item;
            
            NSMenuItem *menuItem = [[NSMenuItem alloc] init];
            menuItem.title = [metadataItem valueForAttribute:NSMetadataItemFSNameKey];
            NSString *filePath = [metadataItem valueForAttribute:NSMetadataItemPathKey];
            menuItem.representedObject = [NSURL fileURLWithPath:filePath];
            
            menuItem.target = self;
            menuItem.action = @selector(openFileWithMenuItem:);
            menuItem.image = image;
            menuItem.indentationLevel = indented ? 1 : 0;
            
            NSDate *date = [metadataItem valueForAttribute:NSMetadataItemFSContentChangeDateKey];
            NSString *dateString = [self.dateFormatter stringFromDate:date];
            menuItem.toolTip = [NSString stringWithFormat:@"%@\n\nModified: %@", filePath, dateString];
            
            [menu addItem:menuItem];
        }
    }
}

-(void)updateFileItems
{
    NSString *homeDir = NSHomeDirectory();
    
    NSString *kPrefix = @"Prefix";
    NSString *kItems = @"Items";
    
    NSString *simPrefix = [homeDir stringByAppendingString:@"/Library/Application Support/iPhone Simulator/"];
    NSDictionary *simDict = @{kPrefix : simPrefix, kItems : [NSMutableArray arrayWithObject:@"iPhone Simulator"]};
    
    NSString *devPrefix = [homeDir stringByAppendingString:@"/Developer/"];
    NSDictionary *devDict = @{kPrefix : devPrefix, kItems : [NSMutableArray arrayWithObject:@"Developer"]};
    
    NSString *desktopPrefix = [homeDir stringByAppendingString:@"/Desktop/"];
    NSDictionary *desktopDict = @{kPrefix : desktopPrefix, kItems : [NSMutableArray arrayWithObject:@"Desktop"]};
    
    NSString *downloadPrefix = [homeDir stringByAppendingString:@"/Download/"];
    NSDictionary *downloadDict = @{kPrefix : downloadPrefix, kItems : [NSMutableArray arrayWithObject:@"Download"]};
    
    NSString *documentsPrefix = [homeDir stringByAppendingString:@"/Documents/"];
    NSDictionary *documentsdDict = @{kPrefix : documentsPrefix, kItems : [NSMutableArray arrayWithObject:@"Documents"]};
    
    NSString *allPrefix = @"/";
    NSDictionary *otherDict = @{kPrefix : allPrefix, kItems : [NSMutableArray arrayWithObject:@"Other"]};
    
    // Create array of dictionaries, each corresponding to search folders
    self.groupedFileItems = @[simDict, devDict, desktopDict, documentsdDict, downloadDict, otherDict];
    
    // Iterate through the all
    for (NSMetadataItem *fileItem in self.query.results) {
        //Iterate through the different prefixes and add item to corresponding array within dictionary
        for (NSDictionary *dict in self.groupedFileItems) {
            if ([[fileItem valueForAttribute:NSMetadataItemPathKey] hasPrefix:dict[kPrefix]]) {
                NSMutableArray *items = dict[kItems];
                // The first few items are just added
                if (items.count - 1 < kMaxFilesPerCategory) {
                    [items addObject:fileItem];
                }
                // When we reach the maximum number of files to show in the overview we create an array...
                else if (items.count - 1 == kMaxFilesPerCategory) {
                    NSMutableArray *moreFileItems = [NSMutableArray arrayWithObject:fileItem];
                    [items addObject:moreFileItems];
                }
                // ... and henceforth we put fileItems here instead - the menu method will create a submenu.
                else {
                    NSMutableArray *moreFileItems = [items lastObject];
                    [moreFileItems addObject:fileItem];
                }
                // We have already found a matching prefix, we can stop considering this item
                break;
            }
        }
    }
}

- (IBAction)generatedDemoDatabase:(id)sender
{
    // Find the document directory using it as default location for realm file.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *directories = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *url = [directories firstObject];
    
    // Prompt the user for location af new realm file.
    [self showSavePanelStringFromDirectory:url completionHandler:^(BOOL userSelectesFile, NSURL *selectedFile) {
        // If the user has selected a file url for storing the demo database, we first check if the
        // file already exists (and is actually a file) we delete the old file before creating the
        // new demo file.
        if (userSelectesFile) {
            NSString *path = selectedFile.path;
            BOOL isDirectory = NO;
            
            if ([fileManager fileExistsAtPath:path isDirectory:&isDirectory]) {
                if (!isDirectory) {
                    NSError *error;
                    [fileManager removeItemAtURL:selectedFile error:&error];
                }
            }
            
            BOOL success = [self createAndPopulateDemoDatabaseAtUrl:selectedFile];
            
            if (success) {
                NSAlert *alert = [[NSAlert alloc] init];
                
                alert.alertStyle = NSInformationalAlertStyle;
                alert.showsHelp = NO;
                alert.informativeText = @"A new demo database has been generated. Do you want to open the new database?";
                alert.messageText = @"Open demo database?";
                [alert addButtonWithTitle:@"Ok"];
                [alert addButtonWithTitle:@"Cancel"];
                
                NSUInteger response = [alert runModal];
                if (response == NSAlertFirstButtonReturn) {
                    [self openFileAtURL:selectedFile];
                }
            }
        }
    }];
}

#pragma mark - Private methods

-(void)openFileWithMenuItem:(NSMenuItem *)menuItem
{
    [self openFileAtURL:menuItem.representedObject];
}

-(void)openFileAtURL:(NSURL *)url
{
    NSDocumentController *documentController = [[NSDocumentController alloc] init];
    [documentController openDocumentWithContentsOfURL:url
                                              display:YES
                                    completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error){
                                    }];
}

- (BOOL)createAndPopulateDemoDatabaseAtUrl:(NSURL *)url
{
    NSError *error;
    RLMRealm *realm = [RLMRealm realmWithPath:url.path readOnly:NO error:&error];
    
    if (error == nil) {
        [realm beginWriteTransaction];
        for (NSUInteger index = 0; index < kTestDatabaseSizeMultiplicatorFactor; index++) {
            RealmTestClass0 *tc0_0 = [RealmTestClass0 createInRealm:realm withObject:@[@45, @"John"]];
            RealmTestClass0 *tc0_1 = [RealmTestClass0 createInRealm:realm withObject:@[@23, @"Mary"]];
            RealmTestClass0 *tc0_2 = [RealmTestClass0 createInRealm:realm withObject:@[@38, @"Peter"]];
            RealmTestClass0 *tc0_3 = [RealmTestClass0 createInRealm:realm withObject:@[@12, @"Susan"]];
            RealmTestClass0 *tc0_4 = [RealmTestClass0 createInRealm:realm withObject:@[@34, @"John"]];
            RealmTestClass0 *tc0_5 = [RealmTestClass0 createInRealm:realm withObject:@[@75, @"James"]];
            RealmTestClass0 *tc0_6 = [RealmTestClass0 createInRealm:realm withObject:@[@45, @"Gilbert"]];
            RealmTestClass0 *tc0_7 = [RealmTestClass0 createInRealm:realm withObject:@[@45, @"Ann"]];
            
            RealmTestClass1 *tc1_0 = [RealmTestClass1 createInRealm:realm withObject:@[@1,      @YES,   @123.456f, @123456.789, @"ten",      [NSDate date],                                                      @[]]];
            RealmTestClass1 *tc1_1 = [RealmTestClass1 createInRealm:realm withObject:@[@20,     @NO,    @23.4561f, @987654.321, @"twenty",   [NSDate distantPast],                                               @[]]];
            RealmTestClass1 *tc1_2 = [RealmTestClass1 createInRealm:realm withObject:@[@30,     @YES,   @3.45612f, @1234.56789, @"thirty",   [NSDate distantFuture],                                             @[]]];
            RealmTestClass1 *tc1_3 = [RealmTestClass1 createInRealm:realm withObject:@[@40,     @NO,    @.456123f, @9876.54321, @"fourty",   [[NSDate date] dateByAddingTimeInterval:-60.0 * 60.0 * 24.0 * 7.0], @[]]];
            RealmTestClass1 *tc1_4 = [RealmTestClass1 createInRealm:realm withObject:@[@50,     @YES,   @654.321f, @123.456789, @"fifty",    [[NSDate date] dateByAddingTimeInterval:+60.0 * 60.0 * 24.0 * 7.0], @[]]];
            RealmTestClass1 *tc1_5 = [RealmTestClass1 createInRealm:realm withObject:@[@60,     @NO,    @6543.21f, @987.654321, @"sixty",    [[NSDate date] dateByAddingTimeInterval:-60.0 * 60.0 * 24.0 * 1.0], @[]]];
            RealmTestClass1 *tc1_6 = [RealmTestClass1 createInRealm:realm withObject:@[@70,     @YES,   @65432.1f, @12.3456789, @"seventy",  [[NSDate date] dateByAddingTimeInterval:+60.0 * 60.0 * 24.0 * 1.0], @[]]];
            RealmTestClass1 *tc1_7 = [RealmTestClass1 createInRealm:realm withObject:@[@80,     @NO,    @654321.f, @98.7654321, @"eighty",   [[NSDate date] dateByAddingTimeInterval:-60.0 * 60.0 * 12.0 * 1.0], @[]]];
            RealmTestClass1 *tc1_8 = [RealmTestClass1 createInRealm:realm withObject:@[@90,     @YES,   @123.456f, @1.23456789, @"ninety",   [[NSDate date] dateByAddingTimeInterval:+60.0 * 60.0 * 12.0 * 1.0], @[]]];
            RealmTestClass1 *tc1_9 = [RealmTestClass1 createInRealm:realm withObject:@[@100,    @NO,    @123.456f, @9.87654321, @"hundred",  [[NSDate date] dateByAddingTimeInterval:+60.0 *  5.0 *  1.0 * 1.0], @[]]];
            
            [tc1_0.arrayReference addObjectsFromArray:@[tc0_0, tc0_1, tc0_3]];
            [tc1_1.arrayReference addObjectsFromArray:@[tc0_2]];
            [tc1_2.arrayReference addObjectsFromArray:@[tc0_0, tc0_4]];
            [tc1_4.arrayReference addObjectsFromArray:@[tc0_5]];
            [tc1_5.arrayReference addObjectsFromArray:@[tc0_1, tc0_2, tc0_3, tc0_4, tc0_5, tc0_6, tc0_7]];
            [tc1_6.arrayReference addObjectsFromArray:@[tc0_6, tc0_7]];
            [tc1_7.arrayReference addObjectsFromArray:@[tc0_7, tc0_6]];
            [tc1_9.arrayReference addObjectsFromArray:@[tc0_0]];
            
            [RealmTestClass2 createInRealm:realm withObject:@[@1111, @YES, tc1_0]];
            [RealmTestClass2 createInRealm:realm withObject:@[@2211, @YES, tc1_2]];
            [RealmTestClass2 createInRealm:realm withObject:@[@3322, @YES, tc1_4]];
            [RealmTestClass2 createInRealm:realm withObject:@[@007,  @YES, [NSNull null]]];
            [RealmTestClass2 createInRealm:realm withObject:@[@4433, @NO,  tc1_6]];
            [RealmTestClass2 createInRealm:realm withObject:@[@5544, @YES, tc1_8]];
            [RealmTestClass2 createInRealm:realm withObject:@[@003,  @YES, [NSNull null]]];
            [RealmTestClass2 createInRealm:realm withObject:@[@7766, @NO,  tc1_0]];
            [RealmTestClass2 createInRealm:realm withObject:@[@9876, @NO,  tc1_3]];
        }
        
        [realm commitWriteTransaction];
        
        return YES;
    }
    
    return NO;
}

- (void)showSavePanelStringFromDirectory:(NSURL *)directoryUrl completionHandler:(void(^)(BOOL userSelectesFile, NSURL *selectedFile))completion
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    // Restrict the file type to whatever you like
    savePanel.allowedFileTypes = @[kRealmFileExension];
    
    // Set the starting directory
    savePanel.directoryURL = directoryUrl;
    
    // And show another dialog headline than "Save"
    savePanel.title = @"Generate";
    savePanel.prompt = @"Generate";
    
    // Perform other setup
    // Use a completion handler -- this is a block which takes one argument
    // which corresponds to the button that was clicked
    [savePanel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            
            // Close panel before handling errors
            [savePanel orderOut:self];
            
            // Notify caller about the file selected
            completion(YES, savePanel.URL);
        }
        else {
            completion(NO, nil);
        }
    }];
}

@end

