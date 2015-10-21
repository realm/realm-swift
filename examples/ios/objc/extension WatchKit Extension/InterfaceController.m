////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import "InterfaceController.h"
#import <Realm/Realm.h>
#import "Tick.h"


@interface InterfaceController()

@property (nonatomic, strong, readwrite) IBOutlet WKInterfaceButton *button;
@property (nonatomic, strong) Tick *tick;
@property (nonatomic, strong) RLMNotificationToken *notificationToken;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    NSLog(@"%@ awakeWithContext", self);

    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.path = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.io.realm.examples.extension"] URLByAppendingPathComponent:@"extension.realm"].path;
    [RLMRealmConfiguration setDefaultConfiguration:configuration];
    self.tick = [Tick allObjects].firstObject;
    if (!self.tick) {
        [[RLMRealm defaultRealm] transactionWithBlock:^{
            self.tick = [Tick createInDefaultRealmWithValue:@[@"", @0]];
        }];
    }
    self.notificationToken = [self.tick.realm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        // Occasionally, respond immediately to the notification by triggering a new notification.
        if (self.tick.count % 17 == 0) {
            [self tock];
        }
        [self updateLabel];
    }];
    [self updateLabel];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    NSLog(@"%@ will activate", self);
    [self updateLabel];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    NSLog(@"%@ did deactivate", self);
}

- (void)updateLabel {
    [self.button setTitle:@(self.tick.count).stringValue];
}

- (void)tock {
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        self.tick.count++;
    }];
}

- (IBAction)buttonPressed:(id)sender {
    [self tock];
    [self updateLabel];
}

@end



