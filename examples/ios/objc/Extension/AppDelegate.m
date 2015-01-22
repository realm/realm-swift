//
//  AppDelegate.m
//  Extension
//
//  Created by Samuel Giddins on 1/21/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import "AppDelegate.h"
#import "Tick.h"

@interface TickViewController : UIViewController

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) Tick *tick;
@property (nonatomic, strong) RLMNotificationToken *notificationToken;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [RLMRealm setDefaultRealmPath:[[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.io.realm.examples.extension"] URLByAppendingPathComponent:@"extension.realm"].path];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[TickViewController alloc] init];
    [self.window makeKeyAndVisible];
    return YES;
}

@end

@implementation TickViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tick = [Tick allObjects].firstObject;
    if (!self.tick) {
        [[RLMRealm defaultRealm] transactionWithBlock:^{
            self.tick = [Tick createInDefaultRealmWithObject:@[@"", @0]];
        }];
    }
    self.notificationToken = [self.tick.realm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        if (self.tick.count % 2 == 0) {
            [realm transactionWithBlock:^{
                self.tick.count++;
            }];
        }
        [self updateLabel];
    }];
    self.label = [[UILabel alloc] initWithFrame:self.view.bounds];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.label];
    [self updateLabel];
}

- (void)updateLabel {
    self.label.text = [NSString stringWithFormat:@"%ld", (long)self.tick.count];
}

@end
