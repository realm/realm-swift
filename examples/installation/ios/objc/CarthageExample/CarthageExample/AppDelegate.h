//
//  AppDelegate.h
//  CarthageExample
//
//  Created by JP Simard on 5/11/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

@interface MyModel : RLMObject
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
