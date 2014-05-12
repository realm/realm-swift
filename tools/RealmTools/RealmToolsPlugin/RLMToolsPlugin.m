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

static const NSInteger RLMToolsPluginMenuItemTag = 12347177;

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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSLog(@"    Application Did Finish Launching");
    NSMenuItem* windowMenuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
    if (windowMenuItem) {
        [[windowMenuItem submenu] addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem* realmToolsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Realm Tools" action:@selector(realmToolsClicked:) keyEquivalent:@""];
        [realmToolsMenuItem setTarget:self];
        [realmToolsMenuItem setTag:RLMToolsPluginMenuItemTag];
        [[windowMenuItem submenu] addItem:realmToolsMenuItem];
    }
}

- (void)realmToolsClicked:(id)sender
{
    NSLog(@"    Realm Tools clicked");
}

@end
