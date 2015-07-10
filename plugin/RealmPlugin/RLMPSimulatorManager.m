////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMPSimulatorManager.h"

static NSString *const RLMPBootedSimulatorKey = @"Booted";

static NSTask *RLMPLaunchedTaskSynchonouslyWithProperty(NSString *path, NSArray *arguments, NSString *__autoreleasing *output)
{
    // Setup task with given parameters
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = path;
    task.arguments = arguments;

    // Setup output Pipe to created Task
    NSPipe *outputPipe = [NSPipe pipe];
    task.standardOutput = outputPipe;

    [task launch];
    [task waitUntilExit];

    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];

    *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    return task;
}

@interface RLMPSimulatorManager ()

@end

@implementation RLMPSimulatorManager

+ (NSString *)bootedSimulatorUUID
{
    NSString *deviceData = [self readDeviceData];

    __block NSString *bootedDeviceUUID;
    if (deviceData) {
        // Process output
        NSDictionary *deviceStatuses = [self processDeviceData:deviceData];

        [deviceStatuses enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            if ([value isEqualToString:RLMPBootedSimulatorKey]) {
                bootedDeviceUUID = key;
                // Stop when we found single booted device
                *stop = YES;
            }
        }];
    }

    return bootedDeviceUUID;
}

+ (NSString *)readDeviceData
{
    // Find out Xcode path from mainBundle
    NSURL *bundleURL = [[NSBundle mainBundle] infoDictionary][@"CFBundleInfoPlistURL"];

    // Append with xcrun path
    NSString *pathToXcrun = @"Contents/Developer/usr/bin/xcrun";
    NSURL *fullURL = [[NSURL alloc] initWithString:pathToXcrun relativeToURL:bundleURL.baseURL];

    // Set parameters to get device detail
    NSArray *args = @[@"simctl", @"list", @"devices"];

    NSString *output;
    RLMPLaunchedTaskSynchonouslyWithProperty(fullURL.path, args, &output);

    return output;
}

+ (NSDictionary *)processDeviceData:(NSString *)data
{
    NSMutableDictionary *device = [NSMutableDictionary dictionary];
    NSScanner *scanner = [NSScanner scannerWithString:data];

    // Skip punctuation ( ) as we only want status inside
    scanner.charactersToBeSkipped = [NSCharacterSet punctuationCharacterSet];
    while (![scanner isAtEnd]) {
        NSString *deviceKey;
        NSString *deviceStatus;
        // Scan up to (
        [scanner scanUpToString:@"(" intoString:nil];
        [scanner scanUpToString:@")" intoString:&deviceKey];

        // Scan up to (
        [scanner scanUpToString:@"(" intoString:nil];
        [scanner scanUpToString:@")" intoString:&deviceStatus];

        [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:nil];

        if (deviceKey && deviceStatus) {
            [device setValue:deviceStatus forKey:deviceKey];
        }
    }

    return device;
}

@end
