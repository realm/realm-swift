//
//  TAppDelegate.h
//  TodoApp
//
//  Created by Morten Kjaer on 21/02/14.
//  Copyright (c) 2014 tightdb. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Tightdb/Tightdb.h>

@interface TAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) TightdbSharedGroup *sharedGroup;

@end
