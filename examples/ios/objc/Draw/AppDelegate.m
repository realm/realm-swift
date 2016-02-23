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

static NSString* identity = @"ewogICAgImlkZW50aXR5IjogImRyYXdfZGVtbyIsCiAgICAiYWNjZXNzIjogWyJkb3dubG9hZCIsICJ1cGxvYWQiXSwKICAgICJhcHBfaWQiOiAiaW8ucmVhbG0uRHJhdyIsCiAgICAiZXhwaXJlcyI6IG51bGwsCiAgICAidGltZXN0YW1wIjogMTQ1NjE1NTQzNgp9Cg==";
static NSString* signature = @"WlgbZ5kRWddefABP/DnrK02s6xCTvl19L2eEuK1xQn106aVZxAea21I3Y7vA0umUkfjL2LHJmBU6Oh0peqyWOkLS/9EtWxc5GH5LFRtrhvRiL6WJR2+SIFWGIwtCspW+ChzTabU9+pOt3o2CwS68OWvEKW9ZLMiIvCiTZVq4Fe/Cb0NEmgcuc0sin41KveyRUD2EVQxFfASRdeUWPmLZgCzfn/olrrW+0nFBLMvN/MxkdownZzIeXp6tvI5LgAPlMXysmwAF2ORZtFLKghLJU/n92HxayPck2CPmWpXHIrETd4G2LYh18/kluVPdVbJVk7FegMZH2suuyXRb72cDvQ==";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    application.applicationSupportsShakeToEdit = YES;
    
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.syncServerURL = [NSURL URLWithString:@"realm://hydrogen.fr.sync.realm.io/draw/demo"];
    configuration.syncIdentity = identity;
    configuration.syncSignature = signature;
    [RLMRealmConfiguration setDefaultConfiguration:configuration];

    [RLMRealm setGlobalSynchronizationLoggingLevel:RLMSyncLogLevelVerbose];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] init];
    self.window.rootViewController.view = [DrawView new];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
