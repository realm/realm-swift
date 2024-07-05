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

static LogCategory& categoryForLogCategory(RLMLogCategory logCategory) {
    switch (logCategory) {
        case RLMLogCategoryRealm: return LogCategory::realm;
        case RLMLogCategorySDK: return LogCategory::sdk;
        case RLMLogCategoryApp: return LogCategory::app;
        case RLMLogCategoryStorage: return LogCategory::storage;
        case RLMLogCategoryStorageTransaction: return LogCategory::transaction;
        case RLMLogCategoryStorageQuery: return LogCategory::query;
        case RLMLogCategoryStorageObject: return LogCategory::object;
        case RLMLogCategoryStorageNotification: return LogCategory::notification;
        case RLMLogCategorySync:  return LogCategory::sync;
        case RLMLogCategorySyncClient: return LogCategory::client;
        case RLMLogCategorySyncClientSession: return LogCategory::session;
        case RLMLogCategorySyncClientChangeset: return LogCategory::changeset;
        case RLMLogCategorySyncClientNetwork: return LogCategory::network;
        case RLMLogCategorySyncClientReset: return LogCategory::reset;
        case RLMLogCategorySyncServer: return LogCategory::server;
    };
    REALM_UNREACHABLE();
}

static RLMLogCategory logCategoryForCategory(const LogCategory& category) {
    static constinit std::pair<const LogCategory*, RLMLogCategory> categories[] = {
        {&LogCategory::realm, RLMLogCategoryRealm},
        {&LogCategory::sdk, RLMLogCategorySDK},
        {&LogCategory::app, RLMLogCategoryApp},
        {&LogCategory::storage, RLMLogCategoryStorage},
        {&LogCategory::transaction, RLMLogCategoryStorageTransaction},
        {&LogCategory::query, RLMLogCategoryStorageQuery},
        {&LogCategory::object, RLMLogCategoryStorageObject},
        {&LogCategory::notification, RLMLogCategoryStorageNotification},
        {&LogCategory::sync, RLMLogCategorySync},
        {&LogCategory::client, RLMLogCategorySyncClient},
        {&LogCategory::session, RLMLogCategorySyncClientSession},
        {&LogCategory::changeset, RLMLogCategorySyncClientChangeset},
        {&LogCategory::network, RLMLogCategorySyncClientNetwork},
        {&LogCategory::reset, RLMLogCategorySyncClientReset},
        {&LogCategory::server, RLMLogCategorySyncServer},
    };

    auto find = [](const LogCategory& category) {
        for (auto& [core, objc] : categories) {
            if (core == &category)
                return objc;
        }
        REALM_UNREACHABLE();
    };

#if REALM_DEBUG
    // Validate that all of core's categories are present in the map
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        for (auto name : LogCategory::get_category_names()) {
            (void)find(LogCategory::get_category(name));
        }
    });
#endif

    return find(category);
}

struct CocoaLogger : public Logger {
    void do_log(const LogCategory& category, Level level, const std::string& message) override {
        NSLog(@"%@:%s %@", levelPrefix(level), category.get_name().c_str(), RLMStringDataToNSString(message));
    }
};

class CustomLogger : public Logger {
public:
    RLMLoggerFunction function;
    void do_log(const LogCategory& category, Level level, const std::string& message) override {
        @autoreleasepool {
            function(logLevelForLevel(level), logCategoryForCategory(category), RLMStringDataToNSString(message));
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
    defaultLogger->set_level_threshold(LogCategory::realm, Level::info);
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
        logger->function = ^(RLMLogLevel level, RLMLogCategory, NSString *message) {
            logFunction(level, message);
        };
        self->_logger = logger;
    }
    return self;
}

- (instancetype)initWithLogFunction:(RLMLogCategoryFunction)logFunction {
    if (self = [super init]) {
        auto logger = std::make_shared<CustomLogger>();
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
    LogCategory& cat = categoryForLogCategory(category);
    if (_logger->would_log(cat, level)) {
        _logger->log(cat, levelForLogLevel(logLevel), message.UTF8String);
    }
}

- (void)logWithLevel:(RLMLogLevel)logLevel categoryName:(NSString *)categoryName message:(NSString *)message {
    auto level = levelForLogLevel(logLevel);
    LogCategory& lcat = LogCategory::get_category(categoryName.UTF8String);
    if (_logger->would_log(lcat, level)) {
        _logger->log(lcat, levelForLogLevel(logLevel), message.UTF8String);
    }
}

+ (void)setLevel:(RLMLogLevel)level forCategory:(RLMLogCategory)category {
    auto defaultLogger = Logger::get_default_logger();
    defaultLogger->set_level_threshold(categoryForLogCategory(category).get_name(), levelForLogLevel(level));
}

+ (RLMLogLevel)levelForCategory:(RLMLogCategory)category {
    auto defaultLogger = Logger::get_default_logger();
    return logLevelForLevel(defaultLogger->get_level_threshold(categoryForLogCategory(category).get_name()));
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

#pragma mark Global Logger Setter

+ (instancetype)defaultLogger {
    return [[RLMLogger alloc] initWithLogger:Logger::get_default_logger()];
}

+ (void)setDefaultLogger:(RLMLogger *)logger {
    Logger::set_default_logger(logger->_logger);
}
@end
