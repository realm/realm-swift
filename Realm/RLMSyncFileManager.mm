////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMSyncFileManager.hpp"

#import "RLMUser_Private.h"
#import "RLMUtil.hpp"

@implementation RLMSyncFileManager

/**
 The directory within which all Realm Sync related Realm database and support files are stored. This directory is a
 subdirectory within the default directory within which normal on-disk Realms are stored.

 The directory will be created if it does not already exist, and then verified. If there was an error setting it up an
 exception will be thrown.
 */
+ (NSURL *)baseDirectory {
    static NSURL *s_syncBaseDirectory;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Create the path.
        NSFileManager *manager = [NSFileManager defaultManager];
        NSURL *base = [NSURL fileURLWithPath:defaultDirectoryForBundleIdentifier(nil)];
        s_syncBaseDirectory = [base URLByAppendingPathComponent:@".realm-sync" isDirectory:YES];

        // If the directory does not already exist, create it.
        [manager createDirectoryAtURL:s_syncBaseDirectory
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
        BOOL isDirectory;
        BOOL fileExists = [manager fileExistsAtPath:[s_syncBaseDirectory path] isDirectory:&isDirectory];
        if (!fileExists || !isDirectory) {
            @throw RLMException(@"Realm Sync was not able to prepare its directory for storing Realm files.");
        }
    });
    return s_syncBaseDirectory;
}

+ (NSURL *)filePathForSyncServerURL:(NSURL *)serverURL user:(RLMUser *)user {
    NSString *userID = user.userID;
    if (!userID) {
        @throw RLMException(@"Realm Sync cannot open local disk files for users configured without a user ID.");
        return nil;
    }

    NSCharacterSet *alpha = [NSCharacterSet alphanumericCharacterSet];
    NSString *escapedPath = [[serverURL path] stringByAddingPercentEncodingWithAllowedCharacters:alpha];
    NSString *escapedUserID = [userID stringByAddingPercentEncodingWithAllowedCharacters:alpha];
    NSString *escapedHost = [[serverURL host] stringByAddingPercentEncodingWithAllowedCharacters:alpha];
    NSString *realmFileName = [NSString stringWithFormat:@"%@-%@-%@.realm", escapedHost, escapedPath, escapedUserID];
    return [[self baseDirectory] URLByAppendingPathComponent:realmFileName];
}

@end
