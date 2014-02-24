//
//  TAppDelegate.m
//  TodoApp
//
//  Created by Morten Kjaer on 21/02/14.
//  Copyright (c) 2014 tightdb. All rights reserved.
//

#import "TAppDelegate.h"

@implementation TAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    self.sharedGroup = [TightdbSharedGroup groupWithFilename:[self pathForDataFile:@"todos.tightdb"]];
    
    return YES;
}

- (NSString *) pathForDataFile:(NSString *)filename {
        NSArray* documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                 NSString*   path = nil;
                            
                            if (documentDir) {
                                path = [documentDir objectAtIndex:0];
                            }
                            
                            return [NSString stringWithFormat:@"%@/%@", path, filename];
                        }

@end
