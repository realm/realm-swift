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
    application.applicationSupportsShakeToEdit = YES;
    
    // Setup Global Error Handler
    RLMSyncErrorReportingBlock globalErrorHandler = ^(NSError *error, RLMSyncSession *session) {
        NSLog(@"A global error has occurred! %@", error);
    };
    
    [RLMSyncManager sharedManager].errorHandler = globalErrorHandler;
    
    if ([RLMSyncUser all].count > 0) {
        NSURL *syncURL = [NSURL URLWithString:@"realm://127.0.0.1:9080/~/Draw"];
        RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithUser:[RLMSyncUser all].firstObject realmURL:syncURL];
        RLMRealmConfiguration *defaultConfig = [RLMRealmConfiguration defaultConfiguration];
        defaultConfig.syncConfiguration = syncConfig;
        [RLMRealmConfiguration setDefaultConfiguration:defaultConfig];
    }
    else {
        // The base server path
        // Set to connect to local or online host
        NSURL *authURL = [NSURL URLWithString:@"http://127.0.0.1:9080"];
        
        // Creating a debug credential since this demo is just using the generated access token
        // produced when running the Realm Object Server via the `start-object-server.command`
        RLMSyncCredential *credential = [RLMSyncCredential credentialWithUsername:@"demo@realm.io"
                                                                         password:@"demo"
                                                                          actions:RLMAuthenticationActionsUseExistingAccount];
        
        // Log the user in (async, the Realm will start syncing once the user is logged in automatically)
        [RLMSyncUser authenticateWithCredential:credential
                                  authServerURL:authURL
                                   onCompletion:^(RLMSyncUser *user, NSError *error) {
                                       if (error) {
                                           NSLog(@"A login error has occurred! %@", error);
                                       }
                                       else { // Logged in setup the default Realm
                                           // The Realm virtual path on the server.
                                           // The `~` represents the Realm user ID. Since the user ID is not known until you
                                           // log in, the ~ is used as short-hand to represent this.
                                           NSURL *syncURL = [NSURL URLWithString:@"realm://127.0.0.1:9080/~/Draw"];
                                           RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:syncURL];
                                           RLMRealmConfiguration *defaultConfig = [RLMRealmConfiguration defaultConfiguration];
                                           defaultConfig.syncConfiguration = syncConfig;
                                           [RLMRealmConfiguration setDefaultConfiguration:defaultConfig];
                                       }
        }];
    }

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] init];
    self.window.rootViewController.view = [DrawView new];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
