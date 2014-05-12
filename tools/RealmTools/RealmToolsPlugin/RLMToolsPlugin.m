//
//  RLMToolsPlugin.m
//  RealmTools
//
//  Created by Fiel Guhit on 5/12/14.
//  Copyright (c) 2014 Realm.io. All rights reserved.
//

#import "RLMToolsPlugin.h"

@interface RLMToolsPlugin ()

@property (strong, nonatomic) NSBundle *plugin;

@end

@implementation RLMToolsPlugin

+(void)pluginDidLoad:(NSBundle *)plugin
{
	NSLog(@"    Realm Plugin Loaded");
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc] initWithBundle:plugin];
    });
}

- (id)initWithBundle:(NSBundle *)plugin
{
    self = [super init];
    if (self) {
        _plugin = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSLog(@"    Application Did Finish Launching");
}

@end
