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

#import "AppDelegate.h"
#import <Realm/Realm.h>
#import "DrawView.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSFileManager defaultManager] removeItemAtPath:[RLMRealm defaultRealmPath] error:nil];
    [RLMRealm enableServerSyncOnPath:[RLMRealm defaultRealmPath]
                      serverBaseURL:@"realm://Alexanders-MacBook-Pro.local/draw"];
    [RLMRealm setServerSyncLogLevel:1]; // `level >= 2` means "everything"

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] init];
    self.window.rootViewController.view = [DrawView new];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
