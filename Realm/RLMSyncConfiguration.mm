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

#import "RLMSyncConfiguration_Private.hpp"

#import "RLMSyncManager_Private.hpp"
#import "RLMSyncUser.h"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUtil.hpp"

#import "sync_manager.hpp"
#import "sync_config.hpp"

static BOOL isValidRealmURL(NSURL *url) {
    NSString *scheme = [url scheme];
    if (![scheme isEqualToString:@"realm"] && ![scheme isEqualToString:@"realms"]) {
        return NO;
    }
    return YES;
}

@interface RLMSyncConfiguration () {
    std::function<realm::SyncSessionErrorHandler> _error_handler;
}

- (instancetype)initWithUser:(RLMSyncUser *)user
                    realmURL:(NSURL *)url
               customFileURL:(nullable NSURL *)customFileURL
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy
                errorHandler:(std::function<realm::SyncSessionErrorHandler>)errorHandler NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readwrite) RLMSyncUser *user;
@property (nonatomic, readwrite) NSURL *realmURL;

@end

@implementation RLMSyncConfiguration

- (instancetype)initWithRawConfig:(realm::SyncConfig)config {
    RLMSyncUser *user = [[RLMSyncManager sharedManager] _userForIdentity:@(config.user_tag.c_str())];
    // Note that `user` is allowed to be nil. Any code which uses this private API must ensure that a sync configuration
    // with a nil user is destroyed or gets a valid user before the configuration is exposed to application code.
    NSURL *realmURL = [NSURL URLWithString:@(config.realm_url.c_str())];
    RLMSyncStopPolicy stopPolicy = realm::translateStopPolicy(config.stop_policy);
    self = [self initWithUser:user
                     realmURL:realmURL
                customFileURL:nil
                   stopPolicy:stopPolicy
                 errorHandler:config.error_handler];
    return self;
}

- (realm::SyncConfig)rawConfiguration {
    std::string user_tag = [self.user.identity UTF8String];
    std::string realm_url = [[self.realmURL absoluteString] UTF8String];
    auto stop_policy = realm::translateStopPolicy(self.stopPolicy);

    // Create the static login callback. This is called whenever any Realm wishes to BIND to the Realm Object Server
    // for the first time.
    auto loginLambda = [=](const std::string& path, const realm::SyncConfig& config) {
        NSString *localFilePath = @(path.c_str());
        RLMSyncConfiguration *syncConfig = [[RLMSyncConfiguration alloc] initWithRawConfig:config];
        [[RLMSyncManager sharedManager] _handleBindRequestForSyncConfig:syncConfig
                                                          localFilePath:localFilePath];
    };

    return realm::SyncConfig(std::move(user_tag), std::move(realm_url), std::move(stop_policy), std::move(loginLambda), _error_handler);
}

- (instancetype)initWithUser:(RLMSyncUser *)user realmURL:(NSURL *)url {
    return [self initWithUser:user
                     realmURL:url
                customFileURL:nil
                   stopPolicy:RLMSyncStopPolicyAfterChangesUploaded
                 errorHandler:nullptr];
}

- (instancetype)initWithUser:(RLMSyncUser *)user
                    realmURL:(NSURL *)url
               customFileURL:(nullable NSURL *)customFileURL
                  stopPolicy:(RLMSyncStopPolicy)stopPolicy
                errorHandler:(std::function<realm::SyncSessionErrorHandler>)errorHandler {
    if (self = [super init]) {
        self.user = user;
        if (!isValidRealmURL(url)) {
            @throw RLMException(@"The provided URL (%@) was not a valid Realm URL.", [url absoluteString]);
        }
        self.customFileURL = customFileURL;
        self.stopPolicy = stopPolicy;
        self.realmURL = url;

        if (errorHandler) {
            _error_handler = std::move(errorHandler);
        } else {
            // Automatically configure the per-Realm error handler.
            _error_handler = [=](int error_code, std::string message, realm::SyncSessionError error_type) {
                RLMSyncSession *session = [user sessionForURL:url];
                [[RLMSyncManager sharedManager] _fireErrorWithCode:error_code
                                                           message:@(message.c_str())
                                                           session:session
                                                        errorClass:error_type];
            };
        }

        return self;
    }
    return nil;
}

@end
