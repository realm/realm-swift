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

#import "RLMSyncManager_Private.hpp"

#import "RLMApp_Private.hpp"
#import "RLMRealmConfiguration+Sync.h"
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMSyncSession_Private.hpp"
#import "RLMUser_Private.hpp"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/sync/config.hpp>
#import <realm/object-store/sync/sync_manager.hpp>
#import <realm/object-store/sync/sync_session.hpp>

#if !defined(REALM_COCOA_VERSION)
#import "RLMVersion.h"
#endif

using namespace realm;

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

RLMSyncLogLevel logLevelForLevel(Level logLevel) {
    switch (logLevel) {
        case Level::off:    return RLMSyncLogLevelOff;
        case Level::fatal:  return RLMSyncLogLevelFatal;
        case Level::error:  return RLMSyncLogLevelError;
        case Level::warn:   return RLMSyncLogLevelWarn;
        case Level::info:   return RLMSyncLogLevelInfo;
        case Level::detail: return RLMSyncLogLevelDetail;
        case Level::debug:  return RLMSyncLogLevelDebug;
        case Level::trace:  return RLMSyncLogLevelTrace;
        case Level::all:    return RLMSyncLogLevelAll;
    }
    REALM_UNREACHABLE();    // Unrecognized log level.
}

#pragma mark - Loggers

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

struct CallbackLogger : public realm::util::RootLogger {
    RLMSyncLogFunction logFn;
    void do_log(Level level, std::string message) override {
        @autoreleasepool {
            logFn(logLevelForLevel(level), RLMStringDataToNSString(message));
        }
    }
};
struct CallbackLoggerFactory : public realm::SyncLoggerFactory {
    RLMSyncLogFunction logFn;
    std::unique_ptr<realm::util::Logger> make_logger(realm::util::Logger::Level level) override {
        auto logger = std::make_unique<CallbackLogger>();
        logger->logFn = logFn;
        logger->set_level_threshold(level);
        return std::move(logger); // not a redundant move because it's a different type
    }

    CallbackLoggerFactory(RLMSyncLogFunction logFn) : logFn(logFn) { }
};

} // anonymous namespace

#pragma mark - RLMSyncManager

@interface RLMSyncTimeoutOptions () {
    @public
    realm::SyncClientTimeouts _options;
}
@end

@implementation RLMSyncManager {
    std::unique_ptr<CallbackLoggerFactory> _loggerFactory;
    std::shared_ptr<SyncManager> _syncManager;
}

- (instancetype)initWithSyncManager:(std::shared_ptr<realm::SyncManager>)syncManager {
    if (self = [super init]) {
        [RLMUser _setUpBindingContextFactory];
        _syncManager = syncManager;
        return self;
    }
    return nil;
}

+ (SyncClientConfig)configurationWithRootDirectory:(NSURL *)rootDirectory appId:(NSString *)appId {
    SyncClientConfig config;
    bool should_encrypt = !getenv("REALM_DISABLE_METADATA_ENCRYPTION") && !RLMIsRunningInPlayground();
    config.logger_factory = &s_syncLoggerFactory;
    config.metadata_mode = should_encrypt ? SyncManager::MetadataMode::Encryption
                                          : SyncManager::MetadataMode::NoEncryption;
    @autoreleasepool {
        rootDirectory = rootDirectory ?: [NSURL fileURLWithPath:RLMDefaultDirectoryForBundleIdentifier(nil)];
        config.base_file_path = rootDirectory.path.UTF8String;

        bool isSwift = !!NSClassFromString(@"RealmSwiftObjectUtil");
        config.user_agent_binding_info =
            util::format("Realm%1/%2", isSwift ? "Swift" : "ObjectiveC",
                         RLMStringDataWithNSString(REALM_COCOA_VERSION));
        config.user_agent_application_info = RLMStringDataWithNSString(appId);
    }

    return config;
}

- (std::weak_ptr<realm::app::App>)app {
    return _syncManager->app();
}

- (NSString *)appID {
    if (!_appID) {
        _appID = [[NSBundle mainBundle] bundleIdentifier] ?: @"(none)";
    }
    return _appID;
}

- (void)setUserAgent:(NSString *)userAgent {
    _syncManager->set_user_agent(RLMStringDataWithNSString(userAgent));
    _userAgent = userAgent;
}

- (void)setCustomRequestHeaders:(NSDictionary<NSString *,NSString *> *)customRequestHeaders {
    _customRequestHeaders = customRequestHeaders.copy;

    for (auto&& user : _syncManager->all_users()) {
        for (auto&& session : user->all_sessions()) {
            auto config = session->config();
            config.custom_http_headers.clear();;
            for (NSString *key in customRequestHeaders) {
                config.custom_http_headers.emplace(key.UTF8String, customRequestHeaders[key].UTF8String);
            }
            session->update_configuration(std::move(config));
        }
    }
}

- (void)setLogger:(RLMSyncLogFunction)logFn {
    _logger = logFn;
    if (_logger) {
        _loggerFactory = std::make_unique<CallbackLoggerFactory>(logFn);
        _syncManager->set_logger_factory(*_loggerFactory);
    }
    else {
        _loggerFactory = nullptr;
        _syncManager->set_logger_factory(s_syncLoggerFactory);
    }
}

- (void)setTimeoutOptions:(RLMSyncTimeoutOptions *)timeoutOptions {
    _timeoutOptions = timeoutOptions;
    _syncManager->set_timeouts(timeoutOptions->_options);
}

#pragma mark - Passthrough properties

- (RLMSyncLogLevel)logLevel {
    return logLevelForLevel(_syncManager->log_level());
}

- (void)setLogLevel:(RLMSyncLogLevel)logLevel {
    _syncManager->set_log_level(levelForSyncLogLevel(logLevel));
}

#pragma mark - Private API

- (void)_fireError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.errorHandler) {
            self.errorHandler(error, nil);
        }
    });
}

- (void)resetForTesting {
    _errorHandler = nil;
    _appID = nil;
    _userAgent = nil;
    _logger = nil;
    _authorizationHeaderName = nil;
    _customRequestHeaders = nil;
    _timeoutOptions = nil;
    _syncManager->reset_for_testing();
}

- (std::shared_ptr<realm::SyncManager>)syncManager {
    return _syncManager;
}
@end

#pragma mark - RLMSyncTimeoutOptions

@implementation RLMSyncTimeoutOptions
- (NSUInteger)connectTimeout {
    return static_cast<NSUInteger>(_options.connect_timeout);
}
- (void)setConnectTimeout:(NSUInteger)connectTimeout {
    _options.connect_timeout = connectTimeout;
}

- (NSUInteger)connectLingerTime {
    return static_cast<NSUInteger>(_options.connection_linger_time);
}
- (void)setConnectionLingerTime:(NSUInteger)connectionLingerTime {
    _options.connection_linger_time = connectionLingerTime;
}

- (NSUInteger)pingKeepalivePeriod {
    return static_cast<NSUInteger>(_options.ping_keepalive_period);
}
- (void)setPingKeepalivePeriod:(NSUInteger)pingKeepalivePeriod {
    _options.ping_keepalive_period = pingKeepalivePeriod;
}

- (NSUInteger)pongKeepaliveTimeout {
    return static_cast<NSUInteger>(_options.pong_keepalive_timeout);
}
- (void)setPongKeepaliveTimeout:(NSUInteger)pongKeepaliveTimeout {
    _options.pong_keepalive_timeout = pongKeepaliveTimeout;
}

- (NSUInteger)fastReconnectLimit {
    return static_cast<NSUInteger>(_options.fast_reconnect_limit);
}
- (void)setFastReconnectLimit:(NSUInteger)fastReconnectLimit {
    _options.fast_reconnect_limit = fastReconnectLimit;
}

@end
