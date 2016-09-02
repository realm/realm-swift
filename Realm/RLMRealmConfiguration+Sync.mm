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

#import "RLMRealmConfiguration+Sync.h"

#import "RLMRealmConfiguration_Private.hpp"

#import "RLMUser_Private.h"
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncUtil_Private.h"
#import "RLMUtil.hpp"

#import "sync_config.hpp"

static BOOL isValidRealmURL(NSURL *url) {
    NSString *scheme = [url scheme];
    if (![scheme isEqualToString:@"realm"] && ![scheme isEqualToString:@"realms"]) {
        return NO;
    }
    return YES;
}

@interface RLMSyncConfiguration ()

@property (nonatomic, readwrite) RLMUser *user;
@property (nonatomic, readwrite) NSURL *realmURL;

@end

@implementation RLMSyncConfiguration

- (instancetype)initWithUser:(RLMUser *)user realmURL:(NSURL *)url {
    if (self = [super init]) {
        self.user = user;
        if (!isValidRealmURL(url)) {
            @throw RLMException(@"The provided URL (%@) was not a valid Realm URL.", [url absoluteString]);
        }
        self.realmURL = url;
        return self;
    }
    return nil;
}

@end

@implementation RLMRealmConfiguration (Server)

#pragma mark - API

- (void)setSyncConfiguration:(RLMSyncConfiguration *)syncConfiguration {
    RLMUser *user = syncConfiguration.user;
    NSURL *realmURL = syncConfiguration.realmURL;
    // Ensure sync manager is initialized, if it hasn't already been.
    [RLMSyncManager sharedManager];
    NSAssert(user.identity, @"Cannot call this method on a user that doesn't have an identity.");
    std::string identity = [user.identity UTF8String];
    std::string rawURLString = [[realmURL absoluteString] UTF8String];

    // Automatically configure the per-Realm error handler.
    auto error_handler = [=](int error_code, std::string message, realm::SyncSessionError error_type) {
        RLMSyncSession *session = [user.sessions objectForKey:realmURL];
        [[RLMSyncManager sharedManager] _handleErrorWithCode:error_code
                                                     message:@(message.c_str())
                                                     session:session
                                                  errorClass:error_type];
    };

    NSURL *localFilePath = [RLMRealmConfiguration _filePathForRawRealmURL:realmURL
                                                                     user:user];
    realm::SyncConfig syncConfig { std::move(identity), std::move(rawURLString), std::move(error_handler) };

    self.config.path = [[localFilePath path] UTF8String];
    self.config.in_memory = false;
    self.config.sync_config = std::make_shared<realm::SyncConfig>(std::move(syncConfig));
    self.config.schema_mode = realm::SchemaMode::Additive;
}

- (RLMSyncConfiguration *)syncConfiguration {
    if (!self.config.sync_config) {
        return nil;
    }
    realm::SyncConfig& sync_config = *self.config.sync_config;
    // Try to get the user
    RLMUser *thisUser = [[RLMSyncManager sharedManager] _userForIdentity:@(sync_config.user_tag.c_str())];
    if (!thisUser) {
        @throw RLMException(@"Could not find the user this configuration refers to.");
    }
    return [[RLMSyncConfiguration alloc] initWithUser:thisUser
                                             realmURL:[NSURL URLWithString:@(sync_config.realm_url.c_str())]];
}

#pragma mark - Private

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

// Note that all synced Realms for a given user are stored together in the same directory.
// This means that we _should_ be able to just nuke a user's directory when they log out, rather than having to
// pick through all the Realms that have ever been opened.
+ (NSURL *)_filePathForRawRealmURL:(NSURL *)url user:(RLMUser *)user {
    NSAssert(user.identity, @"Cannot call this method on a user that doesn't yet have an identity...");

    NSFileManager *manager = [NSFileManager defaultManager];
    NSCharacterSet *alpha = [NSCharacterSet alphanumericCharacterSet];

    NSString *folder = [user.identity stringByAddingPercentEncodingWithAllowedCharacters:alpha];
    NSString *filename = [[url absoluteString] stringByAddingPercentEncodingWithAllowedCharacters:alpha];

    // Create and validate the user directory.
    NSURL *userDir = [[self _baseDirectory] URLByAppendingPathComponent:folder];
    [manager createDirectoryAtURL:userDir withIntermediateDirectories:YES attributes:nil error:nil];
    BOOL isDirectory = YES;
    BOOL fileExists = [manager fileExistsAtPath:[userDir path] isDirectory:&isDirectory];
    if (!fileExists || !isDirectory) {
        @throw RLMException(@"Could not prepare the directory for storing synchronized Realm files.");
    }
    return [userDir URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.realm", filename]];
}

@end
