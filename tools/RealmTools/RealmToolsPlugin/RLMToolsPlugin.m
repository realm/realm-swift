//
//  RLMToolsPlugin.m
//  RealmTools
//
//  Created by Fiel Guhit on 5/7/14.
//  Copyright (c) 2014 Realm.io. All rights reserved.
//

#import "RLMToolsPlugin.h"

@implementation RLMToolsPlugin

static RLMToolsPlugin *sharedPlugin = nil;

+ (void)pluginDidLoad:(NSBundle *)plugin
{
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc] init];
    });
}

+ (RLMToolsPlugin *)sharedPlugin
{
    return sharedPlugin;
}

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationListener:) name:nil object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)notificationListener:(NSNotification *)notification
{
//    if ([[notification name] length] >= 2 && [[[notification name] substringWithRange:NSMakeRange(0, 2)] isEqualTo:@"NS"])
//		return;
//	else
//		NSLog(@"  Notification: %@", [notification name]);
}

@end
