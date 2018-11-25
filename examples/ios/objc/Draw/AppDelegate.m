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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    application.applicationSupportsShakeToEdit = YES;
    application.idleTimerDisabled = YES;

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] init];

    // Setup Global Error Handler
    [RLMSyncManager sharedManager].errorHandler = ^(NSError *error, RLMSyncSession *session) {
        NSLog(@"A global error has occurred! %@", error);
    };

    if ([RLMSyncUser currentUser]) {
        NSURL *syncURL = [NSURL URLWithString:[NSString stringWithFormat:@"realm://%@:9080/~/Draw", kIPAddress]];
        RLMRealmConfiguration.defaultConfiguration = [RLMSyncUser.currentUser configurationWithURL:syncURL fullSynchronization:YES];
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
    NSURL *authURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:9080", kIPAddress]];

    // Creating a debug credential since this demo is just using the generated access token
    // produced when running the Realm Object Server via the `start-object-server.command`
    RLMSyncCredentials *credential = [RLMSyncCredentials credentialsWithUsername:@"demo@realm.io"
                                                                        password:@"password"
                                                                        register:NO];

    // Log the user in (async, the Realm will start syncing once the user is logged in automatically)
    [RLMSyncUser logInWithCredentials:credential
                        authServerURL:authURL
                         onCompletion:^(RLMSyncUser *user, NSError *error) {
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
                                    // The Realm virtual path on the server.
                                    // The `~` represents the Realm user ID. Since the user ID is not known until you
                                    // log in, the ~ is used as short-hand to represent this.
                                 NSURL *syncURL = [NSURL URLWithString:[NSString stringWithFormat:@"realm://%@:9080/~/Draw", kIPAddress]];
                                 RLMRealmConfiguration.defaultConfiguration = [RLMSyncUser.currentUser configurationWithURL:syncURL fullSynchronization:YES];
                                 
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
