//
//  RLMAppDelegate.m
//  RLMDemo
//
//  Created by JP Simard on 4/16/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import "RLMAppDelegate.h"
#import "RLMTableViewController.h"

@implementation RLMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[RLMTableViewController alloc] initWithStyle:UITableViewStylePlain]];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
