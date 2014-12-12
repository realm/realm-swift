//
//  RLMBMainWindowController.h
//  RealmBrowser
//
//  Created by Gustaf Kugelberg on 20/11/14.
//  Copyright (c) 2014 Realm inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RLMRealm;
@class RLMObject;

@interface RLMBMainWindowController : NSWindowController

- (void)setupWithRealm:(RLMRealm *)realm;

@end
