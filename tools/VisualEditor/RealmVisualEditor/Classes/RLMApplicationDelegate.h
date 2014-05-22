//
//  RLMApplicationDelegate.h
//  RealmVisualEditor
//
//  Created by Jesper Zuschlag on 22/05/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RLMApplicationDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, weak) IBOutlet NSMenu *fileMenu;
@property (nonatomic, weak) IBOutlet NSMenuItem *openMenuItem;

@end
