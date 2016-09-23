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

#import "RLMSyncFileManager.h"

#import "RLMSyncUser.h"
#import "RLMUtil.hpp"

static NSString *const RLMSyncUtilityFolderName = @"io.realm.object-server-metadata";
static NSString *const RLMSyncMetadataRealmName = @"sync_metadata.realm";

@implementation RLMSyncFileManager

/**
 The directory within which all Realm Object Server related Realm database and support files are stored. This directory
 is a subdirectory within the default directory within which normal on-disk Realms are stored.

 The directory will be created if it does not already exist, and then verified. If there was an error setting it up an
 exception will be thrown.
 */
+ (NSURL *)_baseDirectory {
    static NSURL *s_baseDirectory;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Create the path.
        NSFileManager *manager = [NSFileManager defaultManager];
        NSURL *base = [NSURL fileURLWithPath:RLMDefaultDirectoryForBundleIdentifier(nil)];
        s_baseDirectory = [base URLByAppendingPathComponent:@"realm-object-server" isDirectory:YES];

        // If the directory does not already exist, create it.
        [manager createDirectoryAtURL:s_baseDirectory
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
        BOOL isDirectory = YES;
        BOOL fileExists = [manager fileExistsAtPath:[s_baseDirectory path] isDirectory:&isDirectory];
        if (!fileExists || !isDirectory) {
            @throw RLMException(@"Could not prepare the directory for storing synchronized Realm files.");
        }
    });
    return s_baseDirectory;
}

/**
 Return the file URL for a directory contained within the sync base directory. If the diretory does not already exist,
 it will automatically be created.
 */
+ (NSURL *)_folderPathForString:(nonnull NSString *)folderName {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *userDir = [[self _baseDirectory] URLByAppendingPathComponent:folderName];
    [manager createDirectoryAtURL:userDir withIntermediateDirectories:YES attributes:nil error:nil];
    BOOL isDirectory = YES;
    BOOL fileExists = [manager fileExistsAtPath:[userDir path] isDirectory:&isDirectory];
    if (!fileExists || !isDirectory) {
        @throw RLMException(@"Could not make a directory; a non-directory file already exists.");
    }
    return userDir;
}

/**
 Return the file URL for the directory storing a given Realm Sync user's state.
 */
+ (NSURL *)_folderPathForUserIdentity:(nonnull NSString *)identity {
    NSCharacterSet *alpha = [NSCharacterSet alphanumericCharacterSet];
    NSString *escapedName = [identity stringByAddingPercentEncodingWithAllowedCharacters:alpha];
    if ([escapedName isEqualToString:RLMSyncUtilityFolderName]) {
        @throw RLMException(@"Invalid user identity: cannot be a reserved term.");
    }
    return [self _folderPathForString:escapedName];
}

/**
 Return the file URL for the sync metadata Realm.
 */
+ (NSURL *)fileURLForMetadata {
    NSURL *utilityFolder = [self _folderPathForString:RLMSyncUtilityFolderName];
    return [utilityFolder URLByAppendingPathComponent:RLMSyncMetadataRealmName];
}

/**
 Return the file URL for a given combination of a Realm Object Server URL and Realm Sync user.
 */
+ (NSURL *)fileURLForRawRealmURL:(NSURL *)url user:(RLMSyncUser *)user {
    NSAssert(user.identity, @"Cannot call this method on a user that doesn't yet have an identity...");

    NSCharacterSet *alpha = [NSCharacterSet alphanumericCharacterSet];
    NSString *filename = [[url absoluteString] stringByAddingPercentEncodingWithAllowedCharacters:alpha];

    // Create and validate the user directory.
    NSURL *userDir = [self _folderPathForUserIdentity:user.identity];
    return [userDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.realm", filename]];
}

/**
 Remove all Realm state for a user.
 */
+ (BOOL)removeFilesForUserIdentity:(NSString *)identity error:(NSError **)error {
    NSURL *userDir = [self _folderPathForUserIdentity:identity];
    NSFileManager *manager = [NSFileManager defaultManager];
    return [manager removeItemAtURL:userDir error:error];
}

@end
