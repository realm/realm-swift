//
//  main.m
//  TestHost
//
//  Created by Thomas Goyne on 8/6/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

#else

#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        return NSApplicationMain(argc, argv);
    }
}

#endif
