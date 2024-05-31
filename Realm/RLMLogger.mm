////////////////////////////////////////////////////////////////////////////
//
// Copyright 2023 Realm Inc.
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

#import "RLMLogger_Private.h"

#import "RLMUtil.hpp"

#import <realm/util/logger.hpp>

typedef void (^RLMLoggerFunction)(RLMLogLevel level, RLMLogCategory category, NSString *message);

using namespace realm;
using Logger = realm::util::Logger;
using Level = Logger::Level;
using LogCategory = realm::util::LogCategory;

namespace {
static Level levelForLogLevel(RLMLogLevel logLevel) {
    switch (logLevel) {
        case RLMLogLevelOff:    return Level::off;
        case RLMLogLevelFatal:  return Level::fatal;
        case RLMLogLevelError:  return Level::error;
        case RLMLogLevelWarn:   return Level::warn;
        case RLMLogLevelInfo:   return Level::info;
        case RLMLogLevelDetail: return Level::detail;
        case RLMLogLevelDebug:  return Level::debug;
        case RLMLogLevelTrace:  return Level::trace;
        case RLMLogLevelAll:    return Level::all;
    }
    REALM_UNREACHABLE();    // Unrecognized log level.
}

static RLMLogLevel logLevelForLevel(Level logLevel) {
    switch (logLevel) {
        case Level::off:    return RLMLogLevelOff;
        case Level::fatal:  return RLMLogLevelFatal;
        case Level::error:  return RLMLogLevelError;
        case Level::warn:   return RLMLogLevelWarn;
        case Level::info:   return RLMLogLevelInfo;
        case Level::detail: return RLMLogLevelDetail;
        case Level::debug:  return RLMLogLevelDebug;
        case Level::trace:  return RLMLogLevelTrace;
        case Level::all:    return RLMLogLevelAll;
    }
    REALM_UNREACHABLE();    // Unrecognized log level.
}

static NSString* levelPrefix(Level logLevel) {
    switch (logLevel) {
        case Level::off:    return @"";
        case Level::all:    return @"";
        case Level::trace:  return @"Trace";
        case Level::debug:  return @"Debug";
        case Level::detail: return @"Detail";
        case Level::info:   return @"Info";
        case Level::error:  return @"Error";
        case Level::warn:   return @"Warning";
        case Level::fatal:  return @"Fatal";
    }
    REALM_UNREACHABLE();    // Unrecognized log level.
}

static NSArray<NSString *> *categories = [NSArray arrayWithObjects:
                                          @"Realm",
                                          @"Realm.SDK",
                                          @"Realm.App",
                                          @"Realm.Storage",
                                          @"Realm.Storage.Transaction",
                                          @"Realm.Storage.Query",
                                          @"Realm.Storage.Object",
                                          @"Realm.Storage.Notification",
                                          @"Realm.Sync",
                                          @"Realm.Sync.Client",
                                          @"Realm.Sync.Client.Session",
                                          @"Realm.Sync.Client.Changeset",
                                          @"Realm.Sync.Client.Network",
                                          @"Realm.Sync.Client.Reset",
                                          @"Realm.Sync.Server",
                                          nil];

static std::string categoryNameForLogCategory(RLMLogCategory logCategory) {
    if (logCategory < [categories count]) {
        if (auto categoryName = [categories objectAtIndex:logCategory]) {
            return categoryName.UTF8String;
        }
    }
    REALM_UNREACHABLE();
}

static RLMLogCategory logCategoryForCategoryName(std::string category) {
    auto index = [categories indexOfObject:RLMStringDataToNSString(category)];
    if (index != NSNotFound) {
        switch (index) {
            case 0: return RLMLogCategoryRealm;
            case 1: return RLMLogCategoryRealmSDK;
            case 2: return RLMLogCategoryRealmApp;
            case 3: return RLMLogCategoryRealmStorage;
            case 4: return RLMLogCategoryRealmStorageTransaction;
            case 5: return RLMLogCategoryRealmStorageQuery;
            case 6: return RLMLogCategoryRealmStorageObject;
            case 7: return RLMLogCategoryRealmStorageNotification;
            case 8: return RLMLogCategoryRealmSync;
            case 9: return RLMLogCategoryRealmSyncClient;
            case 10: return RLMLogCategoryRealmSyncClientSession;
            case 11: return RLMLogCategoryRealmSyncClientChangeset;
            case 12: return RLMLogCategoryRealmSyncClientNetwork;
            case 13: return RLMLogCategoryRealmSyncClientReset;
            case 14: return RLMLogCategoryRealmSyncServer;
        }
    }
    REALM_UNREACHABLE();
}

struct CocoaLogger : public Logger {
    void do_log(const LogCategory& category, Level level, const std::string& message) override {
        NSLog(@"%@:%@ %@", levelPrefix(level), RLMStringDataToNSString(category.get_name()), RLMStringDataToNSString(message));
    }
};

class CustomLogger : public Logger {
public:
    RLMLoggerFunction function;
    void do_log(const LogCategory& category, Level level, const std::string& message) override {
        @autoreleasepool {
            if (function) {
                function(logLevelForLevel(level), logCategoryForCategoryName(category.get_name()), RLMStringDataToNSString(message));
            }
        }
    }
};
} // anonymous namespace

@implementation RLMLogger {
    std::shared_ptr<Logger> _logger;
}

typedef void(^LoggerBlock)(RLMLogLevel level, NSString *message);

- (RLMLogLevel)level {
    return logLevelForLevel(_logger->get_level_threshold());
}

- (void)setLevel:(RLMLogLevel)level {
    _logger->set_level_threshold(levelForLogLevel(level));
}

+ (void)initialize {
    auto defaultLogger = std::make_shared<CocoaLogger>();
    defaultLogger->set_level_threshold(Level::info);
    Logger::set_default_logger(defaultLogger);
}

- (instancetype)initWithLogger:(std::shared_ptr<Logger>)logger {
    if (self = [self init]) {
        self->_logger = logger;
    }
    return self;
}

- (instancetype)initWithLevel:(RLMLogLevel)level
                  logFunction:(RLMLogFunction)logFunction {
    if (self = [super init]) {
        auto logger = std::make_shared<CustomLogger>();
        logger->set_level_threshold(levelForLogLevel(level));
        auto block = [logFunction](RLMLogLevel level, RLMLogCategory, NSString *message) {
            logFunction(level, message);
        };
        logger->function = block;
        self->_logger = logger;
    }
    return self;
}

- (instancetype)initWithLevel:(RLMLogLevel)level
                     category:(RLMLogCategory)category
                  logFunction:(RLMLogCategoryFunction)logFunction {
    if (self = [super init]) {
        auto logger = std::make_shared<CustomLogger>();
        logger->set_level_threshold(categoryNameForLogCategory(category), levelForLogLevel(level));
        logger->function = logFunction;
        self->_logger = logger;
    }
    return self;
}

- (void)logWithLevel:(RLMLogLevel)logLevel message:(NSString *)message, ... {
    auto level = levelForLogLevel(logLevel);
    if (_logger->would_log(level)) {
        va_list args;
        va_start(args, message);
        _logger->log(level, "%1", [[NSString alloc] initWithFormat:message arguments:args].UTF8String);
        va_end(args);
    }
}

- (void)logWithLevel:(RLMLogLevel)logLevel category:(RLMLogCategory)category message:(NSString *)message {
    auto level = levelForLogLevel(logLevel);
    if (_logger->would_log(level)) {
        _logger->log(LogCategory::get_category(categoryNameForLogCategory(category)), levelForLogLevel(logLevel), message.UTF8String);
    }
}

- (void)logWithLevel:(RLMLogLevel)logLevel categoryName:(NSString *)categoryName message:(NSString *)message {
    auto level = levelForLogLevel(logLevel);
    if (_logger->would_log(level)) {
        _logger->log(LogCategory::get_category(categoryName.UTF8String), levelForLogLevel(logLevel), message.UTF8String);
    }
}

- (void)setLevel:(RLMLogLevel)level category:(RLMLogCategory)category {
    _logger->set_level_threshold(categoryNameForLogCategory(category), levelForLogLevel(level));
}

- (RLMLogLevel)levelForCategory:(RLMLogCategory)category {
    return logLevelForLevel(_logger->get_level_threshold(categoryNameForLogCategory(category)));
}

#pragma mark Testing

+ (NSArray<NSString *> *)allCategories {
    NSMutableArray<NSString *> *a = [NSMutableArray new];
    auto categories = LogCategory::get_category_names();
    for (const auto& category : categories) {
        NSString *categoryName = RLMStringDataToNSString(category);
        [a addObject:categoryName];
    }
    return a;
}

+ (RLMLogCategory)categoryFromString:(NSString *)string {
    return logCategoryForCategoryName(string.UTF8String);
}

#pragma mark Global Logger Setter

+ (instancetype)defaultLogger {
    return [[RLMLogger alloc] initWithLogger:Logger::get_default_logger()];
}

+ (void)setDefaultLogger:(RLMLogger *)logger {
    Logger::set_default_logger(logger->_logger);
}
@end
