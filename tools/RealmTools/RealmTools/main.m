//
//  main.m
//  RealmTools
//
//  Created by Fiel Guhit on 5/7/14.
//  Copyright (c) 2014 Realm.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GBCommandLineParser.h"

void import_csv(NSURL *fileName)
{
    //Importer importer;
    
}

void import_json(NSURL *fileName)
{
    NSLog(@"json filename: %@", [fileName absoluteString]);
}

int main(int argc, char **argv)
{
    @autoreleasepool {
        GBCommandLineParser *commandLineParser = [[GBCommandLineParser alloc] init];
        
        [commandLineParser parseOptionsWithArguments:argv count:argc block:^(GBParseFlags flags, NSString *argument, id value, BOOL *stop) {
            if ([value isKindOfClass:[NSString class]]) {
                NSURL *fileName = [NSURL fileURLWithPath:value];
                NSString *extension = fileName.pathExtension;
                
                if ([[extension lowercaseString] isEqualToString:@"csv"]) {
                    import_csv(fileName);
                }
                else if ([[extension lowercaseString] isEqualToString:@"json"]) {
                    import_json(fileName);
                }
            }
        }];
    }
    return 0;
}

