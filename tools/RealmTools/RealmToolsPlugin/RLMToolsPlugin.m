//
//  RLMToolsPlugin.m
//  RealmTools
//
//  Created by Fiel Guhit on 5/7/14.
//  Copyright (c) 2014 Realm.io. All rights reserved.
//

#import "RLMToolsPlugin.h"

@interface RLMToolsPlugin ()

@property (strong, nonatomic) NSBundle *bundle;

@end


@implementation RLMToolsPlugin

static RLMToolsPlugin *sharedPlugin = nil;

+ (void)pluginDidLoad:(NSBundle *)plugin
{
	static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc] initWithBundle:plugin];
    });
}

+ (RLMToolsPlugin *)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationListener:) name:nil object:nil];
        
        _bundle = plugin;
        [self addRealmToolsToWindow];
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

- (void)addRealmToolsToWindow
{
    static NSString *const WindowMenuTitle = @"Window";
    static NSString *const RealmMenuTitle = @"Realm Tools";
    
    NSMenu *menu = [NSApp mainMenu];
    NSMenuItem *windowMenu = [menu itemWithTitle:WindowMenuTitle];
    if (windowMenu) {
        [windowMenu.submenu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *realmMenu = [[NSMenuItem alloc] initWithTitle:RealmMenuTitle action:@selector(realmToolsClicked:) keyEquivalent:@""];
        realmMenu.target = self;
        
        [windowMenu.submenu addItem:realmMenu];
    }
}

- (void)realmToolsClicked:(id)sender
{
    NSLog(@"Present UI");
}

@end
