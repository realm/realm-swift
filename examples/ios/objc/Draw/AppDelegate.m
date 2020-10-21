////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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
#import "Constants.h"

@interface AppDelegate ()
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@end

@implementation AppDelegate

static RLMApp *app;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    application.applicationSupportsShakeToEdit = YES;
    application.idleTimerDisabled = YES;

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] init];


    app = [RLMApp appWithId:@"realm-draw"];

    // Setup Error Handler
    [app syncManager].errorHandler = ^(NSError *error, RLMSyncSession *session) {
        NSLog(@"A global error has occurred! %@", error);
    };

    if (app.currentUser) {
        RLMRealmConfiguration.defaultConfiguration = [app.currentUser configurationWithPartitionValue:@"foo"];
        self.window.rootViewController.view = [DrawView new];
    }
    else {
        [self showActivityIndicator];
        [self logIn];
    }

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)logIn
{
    // The base server path
    // Set to connect to local or online host

    // Creating a debug credential since this demo is just using the generated access token
    // produced when running the Realm Object Server via the `start-object-server.command`
    RLMCredentials *credential = [RLMCredentials credentialsWithEmail:@"demo@realm.io"
                                                             password:@"password"];

    // Log the user in (async, the Realm will start syncing once the user is logged in automatically)
    [app loginWithCredential:credential
                  completion:^(RLMUser *user, NSError *error) {
        if (error) {
            self.activityIndicatorView.hidden = YES;
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Login Failed" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self logIn];
                self.activityIndicatorView.hidden = NO;
            }]];
            [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        }
        else { // Logged in setup the default Realm
            RLMRealmConfiguration.defaultConfiguration = [app.currentUser configurationWithPartitionValue:@"foo"];

            self.window.rootViewController.view = [DrawView new];
        }
    }];
}

- (void)showActivityIndicator
{
    if (self.activityIndicatorView == nil) {
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    }

    [self.window.rootViewController.view addSubview:self.activityIndicatorView];
    self.activityIndicatorView.center = self.window.center;
    
    [self.activityIndicatorView startAnimating];
}

@end
