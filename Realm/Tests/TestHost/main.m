//
//  main.m
//  TestHost
//
//  Created by Thomas Goyne on 8/6/14.
//  Copyright (c) 2014 Realm. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_WATCH

// watchOS doesn't support testing at this time.
int main(int argc, const char *argv[]) {
}

#elif TARGET_OS_IPHONE || TARGET_OS_TV || TARGET_OS_MACCATALYST

#import <UIKit/UIKit.h>

@interface RLMAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation RLMAppDelegate
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, NSStringFromClass([UIApplication class]), NSStringFromClass([RLMAppDelegate class]));
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
