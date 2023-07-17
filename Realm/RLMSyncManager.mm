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

#include <os/lock.h>

using namespace realm;

// NEXT-MAJOR: All the code associated to the logger from sync manager should be removed.
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

struct CocoaSyncLogger : public realm::util::Logger {
    void do_log(Level, const std::string& message) override {
        NSLog(@"Sync: %@", RLMStringDataToNSString(message));
    }
};

static std::unique_ptr<realm::util::Logger> defaultSyncLogger(realm::util::Logger::Level level) {
    auto logger = std::make_unique<CocoaSyncLogger>();
    logger->set_level_threshold(level);
    return std::move(logger);
}

struct CallbackLogger : public realm::util::Logger {
    RLMSyncLogFunction logFn;
    void do_log(Level level, const std::string& message) override {
        @autoreleasepool {
            logFn(logLevelForLevel(level), RLMStringDataToNSString(message));
        }
    }
};

} // anonymous namespace

std::shared_ptr<realm::util::Logger> RLMWrapLogFunction(RLMSyncLogFunction fn) {
    auto logger = std::make_shared<CallbackLogger>();
    logger->logFn = fn;
    logger->set_level_threshold(Level::all);
    return logger;
}

#pragma mark - RLMSyncManager

@implementation RLMSyncManager {
    RLMUnfairMutex _mutex;
    std::shared_ptr<SyncManager> _syncManager;
    NSDictionary<NSString *,NSString *> *_customRequestHeaders;
    RLMSyncLogFunction _logger;
}

- (instancetype)initWithSyncManager:(std::shared_ptr<realm::SyncManager>)syncManager {
    if (self = [super init]) {
        [RLMUser _setUpBindingContextFactory];
        _syncManager = syncManager;
        return self;
    }
    return nil;
}

- (std::weak_ptr<realm::app::App>)app {
    return _syncManager->app();
}

- (NSDictionary<NSString *,NSString *> *)customRequestHeaders {
    std::lock_guard lock(_mutex);
    return _customRequestHeaders;
}

- (void)setCustomRequestHeaders:(NSDictionary<NSString *,NSString *> *)customRequestHeaders {
    {
        std::lock_guard lock(_mutex);
        _customRequestHeaders = customRequestHeaders.copy;
    }

    for (auto&& user : _syncManager->all_users()) {
        for (auto&& session : user->all_sessions()) {
            auto config = session->config();
            config.custom_http_headers.clear();
            for (NSString *key in customRequestHeaders) {
                config.custom_http_headers.emplace(key.UTF8String, customRequestHeaders[key].UTF8String);
            }
            session->update_configuration(std::move(config));
        }
    }
}

- (RLMSyncLogFunction)logger {
    std::lock_guard lock(_mutex);
    return _logger;
}

- (void)setLogger:(RLMSyncLogFunction)logFn {
    {
        std::lock_guard lock(_mutex);
        _logger = logFn;
    }
    if (logFn) {
        _syncManager->set_logger_factory([logFn](realm::util::Logger::Level level) {
            auto logger = std::make_unique<CallbackLogger>();
            logger->logFn = logFn;
            logger->set_level_threshold(level);
            return logger;
        });
    }
    else {
        _syncManager->set_logger_factory(defaultSyncLogger);
    }
}

#pragma mark - Passthrough properties

- (NSString *)userAgent {
    return @(_syncManager->config().user_agent_application_info.c_str());
}

- (void)setUserAgent:(NSString *)userAgent {
    _syncManager->set_user_agent(RLMStringDataWithNSString(userAgent));
}

- (RLMSyncTimeoutOptions *)timeoutOptions {
    return [[RLMSyncTimeoutOptions alloc] initWithOptions:_syncManager->config().timeouts];
}

- (void)setTimeoutOptions:(RLMSyncTimeoutOptions *)timeoutOptions {
    _syncManager->set_timeouts(timeoutOptions->_options);
}

- (RLMSyncLogLevel)logLevel {
    return logLevelForLevel(_syncManager->log_level());
}

- (void)setLogLevel:(RLMSyncLogLevel)logLevel {
    _syncManager->set_log_level(levelForSyncLogLevel(logLevel));
}

#pragma mark - Private API

- (void)resetForTesting {
    _errorHandler = nil;
    _logger = nil;
    _authorizationHeaderName = nil;
    _customRequestHeaders = nil;
    _syncManager->reset_for_testing();
}

- (std::shared_ptr<realm::SyncManager>)syncManager {
    return _syncManager;
}

- (void)waitForSessionTermination {
    _syncManager->wait_for_sessions_to_terminate();
}

- (void)populateConfig:(realm::SyncConfig&)config {
    @synchronized (self) {
        if (_authorizationHeaderName) {
            config.authorization_header_name.emplace(_authorizationHeaderName.UTF8String);
        }
        [_customRequestHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *header, BOOL *) {
            config.custom_http_headers.emplace(key.UTF8String, header.UTF8String);
        }];
    }
}
@end

#pragma mark - RLMSyncTimeoutOptions

@implementation RLMSyncTimeoutOptions
- (instancetype)initWithOptions:(realm::SyncClientTimeouts)options {
    if (self = [super init]) {
        _options = options;
    }
    return self;
}

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
