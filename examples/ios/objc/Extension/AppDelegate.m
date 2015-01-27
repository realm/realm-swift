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

@property (nonatomic, strong) UIButton *button;
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
    [RLMRealm setDefaultRealmPath:[[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.io.realm.examples.extension"] URLByAppendingPathComponent:@"extension.realm"].path];
    self.tick = [Tick allObjects].firstObject;
    if (!self.tick) {
        [[RLMRealm defaultRealm] transactionWithBlock:^{
            self.tick = [Tick createInDefaultRealmWithObject:@[@"", @0]];
        }];
    }
    self.notificationToken = [self.tick.realm addNotificationBlock:^(NSString *notification, RLMRealm *realm) {
        if (self.tick.count % 13 == 0) {
            [self tock];
        }
        [self updateLabel];
    }];
    self.button = [UIButton buttonWithType:UIButtonTypeSystem];
    self.button.frame = self.view.bounds;
    [self.button addTarget:self action:@selector(tock) forControlEvents:UIControlEventTouchUpInside];
    self.button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:self.button];
    self.view.backgroundColor = [UIColor purpleColor];
    [self updateLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.button.frame = self.view.bounds;
    [self updateLabel];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self tock];
    [self updateLabel];
}

- (void)updateLabel {
    [self.button setTitle:[NSString stringWithFormat:@"%ld", (long)self.tick.count] forState:UIControlStateNormal];
}

- (void)tock {
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        self.tick.count++;
    }];
}

@end
