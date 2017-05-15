//
//  AppDelegate.h
//  RealmMemoryExample
//
//  Created by Morten Kjaer on 27/05/14.
//  Copyright (c) 2014 Tightdb Denmark ApS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


+ (NSString *)writeablePathForFile:(NSString*)fileName;


@end
