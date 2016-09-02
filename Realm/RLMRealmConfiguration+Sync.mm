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

#import "RLMUser_Private.hpp"
#import "RLMSyncFileManager.h"
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
    if (!user.isValid) {
        @throw RLMException(@"Cannot set a sync configuration which has an invalid user.");
    }

    NSURL *realmURL = syncConfiguration.realmURL;
    // Ensure sync manager is initialized, if it hasn't already been.
    [RLMSyncManager sharedManager];
    NSAssert(user.identity, @"Cannot call this method on a user that doesn't have an identity.");
    std::string identity = [user.identity UTF8String];
    std::string rawURLString = [[realmURL absoluteString] UTF8String];

    // Automatically configure the per-Realm error handler.
    auto error_handler = [=](int error_code, std::string message, realm::SyncSessionError error_type) {
        RLMSyncSession *session = [user.sessions objectForKey:realmURL];
        [[RLMSyncManager sharedManager] _fireErrorWithCode:error_code
                                                   message:@(message.c_str())
                                                   session:session
                                                errorClass:error_type];
    };

    NSURL *localFileURL = [RLMSyncFileManager fileURLForRawRealmURL:realmURL user:user];
    realm::SyncConfig syncConfig { std::move(identity), std::move(rawURLString), std::move(error_handler) };

    self.config.path = [[localFileURL path] UTF8String];
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

@end
