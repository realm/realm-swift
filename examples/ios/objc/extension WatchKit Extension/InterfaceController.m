//
//  InterfaceController.m
//  extension WatchKit Extension
//
//  Created by Samuel Giddins on 1/26/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

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

    [RLMRealm setDefaultRealmPath:[[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.io.realm.examples.extension"] URLByAppendingPathComponent:@"extension.realm"].path];
    self.tick = [Tick allObjects].firstObject;
    if (!self.tick) {
        [[RLMRealm defaultRealm] transactionWithBlock:^{
            self.tick = [Tick createInDefaultRealmWithObject:@[@"", @0]];
        }];
    }
    self.notificationToken = [self.tick.realm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
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
    [self.button setTitle:[NSString stringWithFormat:@"%ld", (long)self.tick.count]];
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



