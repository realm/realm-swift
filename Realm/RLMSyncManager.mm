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

#import "RLMSyncManager_Private.h"

#import "RLMSyncUtil.h"
#import "RLMUser_Private.h"
#import "RLMUtil.hpp"

#import <sync_config.hpp>
#import <sync_manager.hpp>

@interface RLMSyncManager ()

@property (nonnull, nonatomic) NSMutableDictionary<NSString *, RLMUser *> *activeUsers;

@end

@implementation RLMSyncManager

+ (instancetype)sharedManager {
    static RLMSyncManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[RLMSyncManager alloc] initPrivate];
    });
    return sharedManager;
}

- (instancetype)initPrivate {
    if (self = [super init]) {
        // Create the global error handler.
        auto errorLambda = [=](int error_code, std::string message) {
            NSString *nativeMessage = @(message.c_str());
            NSError *error = [NSError errorWithDomain:RLMSyncErrorDomain
                                                 code:RLMSyncInternalError
                                             userInfo:@{@"description": nativeMessage,
                                                        @"error": @(error_code)}];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.errorHandler) {
                    self.errorHandler(error, nil);
                }
            });
        };

        // Create the static login callback. This is called whenever any Realm wishes to BIND to the Realm Object Server
        // for the first time.
        realm::SyncLoginFunction loginLambda = [=](const realm::Realm::Config& config) {
            REALM_ASSERT(config.sync_config);   // Precondition for object store calling this function.
            NSString *userTag = @(config.sync_config->user_tag.c_str());
            NSString *rawURL = @(config.sync_config->realm_url.c_str());
            NSString *localFilePath = @(config.path.c_str());
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _handleBindRequestForTag:userTag rawURL:rawURL localFilePath:localFilePath];
            });
        };

        self.activeUsers = [NSMutableDictionary dictionary];

        // Initialize the sync engine.
        realm::SyncManager::shared().set_error_handler(errorLambda);
        realm::SyncManager::shared().set_login_function(loginLambda);
        return self;
    }
    return nil;
}

- (NSString *)appID {
    if (!_appID) {
        _appID = [[NSBundle mainBundle] bundleIdentifier] ?: @"(none)";
    }
    return _appID;
}

#pragma mark - Private API

- (void)_handleBindRequestForTag:(NSString *)tag
                          rawURL:(NSString *)urlString
                   localFilePath:(NSString *)filePathString {
    RLMUser *user = [self _userForIdentity:tag];
    if (!user) {
        // FIXME: should we throw an exception instead? report an error?
        return;
    }
    // FIXME: should the completion block actually do anything?
    [user _registerRealmForBindingWithFileURL:[NSURL fileURLWithPath:filePathString]
                                     realmURL:[NSURL URLWithString:urlString]
                                 onCompletion:nil];
}

- (void)_fireError:(NSError *)error forSession:(RLMSyncSession *)session {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.errorHandler) {
            self.errorHandler(error, session);
        }
    });
}

- (NSArray *)_allUsers {
    @synchronized (self) {
        return [self.activeUsers allValues];
    }
}

- (void)_registerUser:(RLMUser *)user {
    @synchronized(self) {
        NSString *identity = user.identity;
        if ([self.activeUsers objectForKey:identity]) {
            @throw RLMException(@"Cannot create a user whose tag is already used by another user.");
        }
        [self.activeUsers setObject:user forKey:identity];
    }
}

- (void)_deregisterUser:(RLMUser *)user {
    @synchronized(self) {
        [self.activeUsers removeObjectForKey:user.identity];
    }
}

- (RLMUser *)_userForIdentity:(NSString *)identity {
    @synchronized (self) {
        return [self.activeUsers objectForKey:identity];
    }
}

@end
