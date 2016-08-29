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

using Level = realm::util::Logger::Level;

namespace {

Level levelForSyncLogLevel(RLMSyncLogLevel logLevel) {
    switch (logLevel) {
        case RLMSyncLogLevelOff:    return Level::off;
        case RLMSyncLogLevelFatal:  return Level::fatal;
        case RLMSyncLogLevelError:  return Level::error;
        case RLMSyncLogLevelWarn:   return Level::warn;
        case RLMSyncLogLevelInfo:   return Level::info;
        case RLMSyncLogLevelDetail: return Level::detail;
        case RLMSyncLogLevelDebug:  return Level::debug;
        case RLMSyncLogLevelTrace:  return Level::trace;
        case RLMSyncLogLevelAll:    return Level::all;
    }
    REALM_UNREACHABLE();    // Unrecognized log level.
}

struct CocoaSyncLogger : public realm::util::RootLogger {
    void do_log(Level, std::string message) override {
        NSLog(@"Sync: %@", RLMStringDataToNSString(message));
    }
};

struct CocoaSyncLoggerFactory : public realm::SyncLoggerFactory {
    std::unique_ptr<realm::util::Logger> make_logger(realm::util::Logger::Level level) override {
        auto logger = std::make_unique<CocoaSyncLogger>();
        logger->set_level_threshold(level);
        return std::move(logger);
    }
} s_syncLoggerFactory;

} // anonymous namespace

@interface RLMSyncManager ()

- (instancetype)initPrivate NS_DESIGNATED_INITIALIZER;

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

        self.logLevel = RLMSyncLogLevelInfo;
        realm::SyncManager::shared().set_logger_factory(s_syncLoggerFactory);

        self.activeUsers = [NSMutableDictionary dictionary];

        // Initialize the sync engine.
        realm::SyncManager::shared().set_error_handler(errorLambda);
        realm::SyncManager::shared().set_login_function(loginLambda);
        return self;
    }
    return nil;
}

- (void)setLogLevel:(RLMSyncLogLevel)logLevel {
    _logLevel = logLevel;
    realm::SyncManager::shared().set_log_level(levelForSyncLogLevel(logLevel));
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
