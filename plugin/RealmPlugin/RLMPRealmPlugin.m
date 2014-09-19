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

static RLMPRealmPlugin *sharedPlugin;

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
    
    return self;
}

- (void)openBrowser
{
    // This shouldn't be possible to call without having the Browser installed
    if (!self.browserUrl) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Please install the Realm Browser"
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"You need to install the Realm Browser in order to use it from this plugin. Please visit realm.io for more information."];
        [alert runModal];

        return;
    }

    NSArray *arguments = @[@"-xcode"];
    NSDictionary *configuration = @{NSWorkspaceLaunchConfigurationArguments : arguments};
    
    NSError *error;
    
    if (![[NSWorkspace sharedWorkspace] launchApplicationAtURL:self.browserUrl options:0 configuration:configuration error:&error]) {
        // This will happen if the Browser was present at Xcode launch and then was deleted
        NSAlert *alert = [NSAlert alertWithMessageText:@"Could not launch the Realm Browser"
                                         defaultButton:nil
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:@"Failed to launch the Realm Browser with error message:\n%@.", error];
        [alert runModal];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
