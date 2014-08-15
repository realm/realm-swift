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

@implementation RLMApplicationDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [[NSUserDefaults standardUserDefaults] setObject:@(kTopTipDelay) forKey:@"NSInitialToolTipDelay"];
    NSInteger openFileIndex = [self.fileMenu indexOfItem:self.openMenuItem];
    [self.fileMenu performActionForItemAtIndex:openFileIndex];
}

- (BOOL)application:(NSApplication *)application openFile:(NSString *)filename
{
    [self openFileAtURL:[NSURL fileURLWithPath:filename]];

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
