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

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UIViewController alloc] init];

    // Setup Global Error Handler
    [RLMSyncManager sharedManager].errorHandler = ^(NSError *error, RLMSyncSession *session) {
        NSLog(@"A global error has occurred! %@", error);
    };

    if ([RLMSyncUser currentUser]) {
        NSURL *syncURL = [NSURL URLWithString:[NSString stringWithFormat:@"realm://%@:9080/~/Draw", kIPAddress]];
        RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithUser:[RLMSyncUser currentUser] realmURL:syncURL];
        RLMRealmConfiguration *defaultConfig = [RLMRealmConfiguration defaultConfiguration];
        defaultConfig.syncConfiguration = syncConfig;
        [RLMRealmConfiguration setDefaultConfiguration:defaultConfig];
        self.window.rootViewController.view = [DrawView new];
    }
    else {
        [self showActivityIndicator];
        NSURL *authURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:9080", kIPAddress]];
        [self logInWithAuthURL:authURL username:@"demo@realm.io" password:@"password" register:NO];
    }

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)logInWithAuthURL:(NSURL *)authURL username:(NSString *)username password:(NSString *)password register:(BOOL)reg
{
    RLMSyncCredentials *credential = [RLMSyncCredentials credentialsWithUsername:username
                                                                        password:password
                                                                        register:reg];

    self.activityIndicatorView.hidden = NO;

    // Log the user in (async, the Realm will start syncing once the user is logged in automatically)
    [RLMSyncUser logInWithCredentials:credential
                        authServerURL:authURL
                         onCompletion:^(RLMSyncUser *user, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.activityIndicatorView.hidden = YES;
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Login Failed"
                                                                                         message:error.localizedDescription
                                                                                  preferredStyle:UIAlertControllerStyleAlert];

                [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.placeholder = @"Email address";
                    textField.text = username;
                }];

                [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.placeholder = @"Password";
                    textField.text = password;
                    textField.secureTextEntry = YES;
                }];

                [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.placeholder = @"Server URL";
                    textField.text = authURL.absoluteString;
                }];

                void (^retryLogIn)(UIAlertAction *) = ^(UIAlertAction *action) {
                    NSString *username = alertController.textFields[0].text;
                    NSString *password = alertController.textFields[1].text;
                    NSURL *authURL = [NSURL URLWithString:alertController.textFields[2].text];
                    BOOL needRegister = [action.title isEqualToString:@"Register"];

                    [self logInWithAuthURL:authURL username:username password:password register:needRegister];
                };

                [alertController addAction:[UIAlertAction actionWithTitle:@"Register" style:UIAlertActionStyleDefault handler:retryLogIn]];
                [alertController addAction:[UIAlertAction actionWithTitle:@"Login" style:UIAlertActionStyleDefault handler:retryLogIn]];

                [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
            }
            else { // Logged in setup the default Realm
                // The Realm virtual path on the server.
                // The `~` represents the Realm user ID. Since the user ID is not known until you
                // log in, the ~ is used as short-hand to represent this.
                NSURL *syncURL = [NSURL URLWithString:[NSString stringWithFormat:@"realm://%@:%@/~/Draw", authURL.host, authURL.port]];
                RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithUser:user realmURL:syncURL];
                RLMRealmConfiguration *defaultConfig = [RLMRealmConfiguration defaultConfiguration];
                defaultConfig.syncConfiguration = syncConfig;
                [RLMRealmConfiguration setDefaultConfiguration:defaultConfig];

                dispatch_async(dispatch_get_main_queue(), ^{
                    self.window.rootViewController.view = [DrawView new];
                });
            }
        });
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
