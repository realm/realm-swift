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
#import "RLMTestDataGenerator.h"

#import "TestClasses.h"

NSString *const kRealmFileExension = @"realm";

const NSUInteger kTopTipDelay = 250;

@interface RLMApplicationDelegate ()

@property (nonatomic) BOOL didLoadFile;

@end

@implementation RLMApplicationDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [[NSUserDefaults standardUserDefaults] setObject:@(kTopTipDelay) forKey:@"NSInitialToolTipDelay"];
    
    if (!self.didLoadFile) {
        NSInteger openFileIndex = [self.fileMenu indexOfItem:self.openMenuItem];
        [self.fileMenu performActionForItemAtIndex:openFileIndex];
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
            
            NSArray *testClassNames = @[[RealmTestClass0 className], [RealmTestClass1 className], [RealmTestClass2 className]];
            BOOL success = [RLMTestDataGenerator createRealmAtUrl:selectedFile withClassesNamed:testClassNames elementCount:1000];
            
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

