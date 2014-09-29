//
//  RLMPopupViewController.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 29/09/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RLMArrayNode;

@interface RLMPopupViewController : NSViewController

- (void)setupColumnsWithArrayNode:(RLMArrayNode *)arrayNode fromWindow:(NSWindow *)window;

@end
