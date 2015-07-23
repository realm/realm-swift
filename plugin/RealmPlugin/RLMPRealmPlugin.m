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

#import "RLMPRealmPlugin.h"

#import "RLMPSimulatorManager.h"

static RLMPRealmPlugin *sharedPlugin;

static NSString *const RootDeviceSimulatorPath = @"Library/Developer/CoreSimulator/Devices";
static NSString *const DeviceSimulatorApplicationPath = @"data/Containers/Data/Application";

static NSString *const RLMPErrorDomain = @"io.Realm.error";

static NSArray * RLMPGlobFilesAtDirectoryURLWithPredicate(NSFileManager *fileManager, NSURL *directoryURL, NSPredicate *filteredPredicate, BOOL (^handler)(NSURL *URL, NSError *error))
{
    NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtURL:directoryURL
                                            includingPropertiesForKeys:@[NSURLNameKey, NSURLIsDirectoryKey]
                                                               options:NSDirectoryEnumerationSkipsHiddenFiles
                                                          errorHandler:handler];
    NSMutableArray *fileURLs = [NSMutableArray array];
    for (NSURL *fileURL in directoryEnumerator) {
        NSString *fileName;
        [fileURL getResourceValue:&fileName forKey:NSURLNameKey error:nil];
        
        NSString *isDirectory;
        [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
        
        // Check whether it is a directory or not
        if (![isDirectory boolValue]) {
            [fileURLs addObject:fileURL];
        }
    }
    
    return [fileURLs filteredArrayUsingPredicate:filteredPredicate];
}

@interface RLMPRealmPlugin()

@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) NSURL *browserUrl;

@end

@implementation RLMPRealmPlugin

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // Save reference to plugin's bundle, for resource acccess
        self.bundle = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification *)notification
{
    // Look for the Realm Browser
    NSString *urlString = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Realm Browser"];
    if (urlString) {
        self.browserUrl = [NSURL fileURLWithPath:urlString];
        
        // Create menu item to open Browser under File:
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"File"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open Realm..."
                                                                    action:@selector(openBrowser)
                                                             keyEquivalent:@""];
            [actionMenuItem setTarget:self];
            [[menuItem submenu] addItem:actionMenuItem];
        }
    }
    else {
        NSLog(@"Realm Plugin: Couldn't find Realm Browser. Will not show 'Open Realm...' menu item.");
    }
}

- (void)openBrowser
{
    // This shouldn't be possible to call without having the Browser installed
    if (!self.browserUrl) {
        NSString *title = @"Please install the Realm Browser";
        NSString *message = @"You need to install the Realm Browser in order to use it from this plugin. Please visit realm.io for more information.";
        
        NSError *error = [NSError errorWithDomain:RLMPErrorDomain
                                             code:-1
                                         userInfo:@{ NSLocalizedDescriptionKey : title,
                                                     NSLocalizedRecoverySuggestionErrorKey : message }];
        [self showError:error];
        return;
    }
    
    // Find Device UUID
    NSString *bootedSimulatorUUID = [RLMPSimulatorManager bootedSimulatorUUID];
    
    // Find Realm File URL
    NSArray *realmFileURLs = [self realmFilesURLWithDeviceUUID:bootedSimulatorUUID];
    
    if (realmFileURLs.count == 0) {
        NSString *title = @"Unable to find Realm file";
        NSString *message = @"You must launch iOS Simulator with app that uses Realm";
        
        NSError *error = [NSError errorWithDomain:RLMPErrorDomain
                                             code:-1
                                         userInfo:@{ NSLocalizedDescriptionKey : title,
                                                     NSLocalizedRecoverySuggestionErrorKey : message }];
        [self showError:error];
        return;
    }
    
    NSMutableArray *arguments = [NSMutableArray array];
    for (NSURL *realmFileURL in realmFileURLs) {
        [arguments addObject:realmFileURL.path];
    }
    
    NSDictionary *configuration = @{ NSWorkspaceLaunchConfigurationArguments : arguments };
    
    // Show confirmation alert if 2 or more files are detected
    if (arguments.count > 1) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Realm Browser"];
        [alert setInformativeText:[NSString stringWithFormat:@"%ld Realm files are detected. Are you sure to open them at once?", arguments.count]];
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
                [self openRealmBrowserWithConfiguration:configuration];
            }
        }];
    } else {
        [self openRealmBrowserWithConfiguration:configuration];
    }
}

- (void)openRealmBrowserWithConfiguration:(NSDictionary *)configuration
{
    NSError *error;
    if (![[NSWorkspace sharedWorkspace] launchApplicationAtURL:self.browserUrl options:NSWorkspaceLaunchNewInstance configuration:configuration error:&error]) {
        // This will happen if the Browser was present at Xcode launch and then was deleted
        [self showError:error];
    }
}

- (NSArray *)realmFilesURLWithDeviceUUID:(NSString *)deviceUUID
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *homeURL = [NSURL URLWithString:NSHomeDirectory()];
    
    NSMutableString *fullPath = [NSMutableString string];
    [fullPath appendFormat:@"%@/%@/%@", RootDeviceSimulatorPath, deviceUUID, DeviceSimulatorApplicationPath];
    NSURL *bootedDeviceDirectoryURL = [homeURL URLByAppendingPathComponent:fullPath];
    
    NSArray* fileURLs = RLMPGlobFilesAtDirectoryURLWithPredicate(fileManager, bootedDeviceDirectoryURL, [NSPredicate predicateWithFormat:@"pathExtension == 'realm'"], ^BOOL(NSURL *URL, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
            return NO;
        }
        return YES;
    });
    
    return fileURLs;
}

- (void)showError:(NSError *)error
{
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert runModal];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
