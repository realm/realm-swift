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

static NSString* levelPrefix(RLMLogLevel logLevel) {
    switch (logLevel) {
        case RLMLogLevelOff:    return @"";
        case RLMLogLevelAll:    return @"";
        case RLMLogLevelTrace:  return @"Trace";
        case RLMLogLevelDebug:  return @"Debug";
        case RLMLogLevelDetail: return @"Detail";
        case RLMLogLevelInfo:   return @"Info";
        case RLMLogLevelError:  return @"Error";
        case RLMLogLevelWarn:   return @"Warning";
        case RLMLogLevelFatal:  return @"Fatal";
    }
    REALM_UNREACHABLE();    // Unrecognized log level.
}

static LogCategory& categoryForLogCategory(RLMLogCategory logCategory) {
    switch (logCategory) {
        case RLMLogCategoryRealm:               return LogCategory::realm;
        case RLMLogCategorySDK:                 return LogCategory::sdk;
        case RLMLogCategoryApp:                 return LogCategory::app;
        case RLMLogCategoryStorage:             return LogCategory::storage;
        case RLMLogCategoryStorageTransaction:  return LogCategory::transaction;
        case RLMLogCategoryStorageQuery:        return LogCategory::query;
        case RLMLogCategoryStorageObject:       return LogCategory::object;
        case RLMLogCategoryStorageNotification: return LogCategory::notification;
        case RLMLogCategorySync:                return LogCategory::sync;
        case RLMLogCategorySyncClient:          return LogCategory::client;
        case RLMLogCategorySyncClientSession:   return LogCategory::session;
        case RLMLogCategorySyncClientChangeset: return LogCategory::changeset;
        case RLMLogCategorySyncClientNetwork:   return LogCategory::network;
        case RLMLogCategorySyncClientReset:     return LogCategory::reset;
        case RLMLogCategorySyncServer:          return LogCategory::server;
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

struct DynamicLogger : Logger {
    RLMUnfairMutex _mutex;
    NSArray<RLMLogCategoryFunction> *_logFunctions;

    void do_log(const LogCategory& category, Level level, const std::string& message) override {
        NSArray *loggers;
        {
            std::lock_guard lock(_mutex);
            loggers = _logFunctions;
        }
        if (loggers.count == 0) {
            return;
        }

        @autoreleasepool {
            NSString *nsMessage = RLMStringDataToNSString(message);
            RLMLogCategory rlmCategory = logCategoryForCategory(category);
            RLMLogLevel rlmLevel = logLevelForLevel(level);
            for (RLMLogCategoryFunction fn : loggers) {
                fn(rlmLevel, rlmCategory, nsMessage);
            }
        }
    }
};
std::optional<DynamicLogger> s_dynamic_logger;

class CustomLogger : public Logger {
public:
    RLMLogFunction function;
    void do_log(const LogCategory&, Level level, const std::string& message) override {
        @autoreleasepool {
            function(logLevelForLevel(level), RLMStringDataToNSString(message));
        }
    }
};
} // anonymous namespace

@implementation RLMLoggerToken {
    RLMLogCategoryFunction _function;
}

- (instancetype)initWithFunction:(RLMLogCategoryFunction)function {
    if (self = [super init]) {
        _function = function;
    }
    return self;
}

- (void)invalidate {
    std::lock_guard lock(s_dynamic_logger->_mutex);
    if (!_function) {
        return;
    }
    auto& functions = s_dynamic_logger->_logFunctions;
    functions = [functions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", _function]];
    _function = nil;
}

@end

@implementation RLMLogger {
    std::shared_ptr<Logger> _logger;
}

#pragma mark - Dynamic category-based API

+ (void)initialize {
    // Constructing the global logger is deferred slightly because constructing
    // a Logger references non-constinit global variables (the logger categories)
    // and so if the logger is a global variable it runs into the initialization
    // order fiasco.
    s_dynamic_logger.emplace();
    [self resetToDefault];
}

+ (void)resetToDefault {
    {
        std::lock_guard lock(s_dynamic_logger->_mutex);
        static RLMLogCategoryFunction defaultLogger = ^(RLMLogLevel level, RLMLogCategory category,
                                                        NSString *message) {
            NSLog(@"%@:%s %@", levelPrefix(level), categoryForLogCategory(category).get_name().c_str(), message);
        };
        s_dynamic_logger->_logFunctions = @[defaultLogger];
        s_dynamic_logger->set_level_threshold(LogCategory::realm, Level::info);
    }
    // Use a custom no-op deleter because our logger is statically allocated and
    // shouldn't actually be deleted when there's no references to it
    Logger::set_default_logger(std::shared_ptr<Logger>(&*s_dynamic_logger, [](Logger *) {}));
}

+ (RLMLoggerToken *)addLogFunction:(RLMLogCategoryFunction)function {
    {
        std::lock_guard lock(s_dynamic_logger->_mutex);
        // We construct a new array each time rather than using a mutable array
        // so that do_log() can just acquire the pointer under lock without
        // having to worry about the array being mutated on another thread
        auto& functions = s_dynamic_logger->_logFunctions;
        if (functions.count) {
            functions = [functions arrayByAddingObject:function];
        }
        else {
            functions = @[function];
        }
    }
    return [[RLMLoggerToken alloc] initWithFunction:function];
}

+ (void)removeAll {
    std::lock_guard lock(s_dynamic_logger->_mutex);
    s_dynamic_logger->_logFunctions = nil;
}

+ (void)setLevel:(RLMLogLevel)level forCategory:(RLMLogCategory)category {
    s_dynamic_logger->set_level_threshold(categoryForLogCategory(category), levelForLogLevel(level));
}

+ (RLMLogLevel)levelForCategory:(RLMLogCategory)category {
    return logLevelForLevel(s_dynamic_logger->get_level_threshold(categoryForLogCategory(category)));
}

#pragma mark - Deprecated API

- (RLMLogLevel)level {
    return logLevelForLevel(_logger->get_level_threshold());
}

- (void)setLevel:(RLMLogLevel)level {
    _logger->set_level_threshold(levelForLogLevel(level));
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
        logger->function = logFunction;
        self->_logger = logger;
    }
    return self;
}

+ (instancetype)defaultLogger {
    return [[RLMLogger alloc] initWithLogger:Logger::get_default_logger()];
}

+ (void)setDefaultLogger:(RLMLogger *)logger {
    Logger::set_default_logger(logger->_logger);
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

void RLMTestLog(RLMLogCategory category, RLMLogLevel level, const char *message) {
    Logger::get_default_logger()->log(categoryForLogCategory(category),
                                      levelForLogLevel(level),
                                      "%1", message);
}
@end

#pragma mark - Internal logging functions

void RLMLog(RLMLogLevel logLevel, NSString *format, ...) {
    auto level = levelForLogLevel(logLevel);
    auto logger = Logger::get_default_logger();
    if (logger->would_log(LogCategory::sdk, level)) {
        va_list args;
        va_start(args, format);
        logger->log(LogCategory::sdk, level, "%1",
                    [[NSString alloc] initWithFormat:format arguments:args].UTF8String);
        va_end(args);
    }
}

void RLMLogRaw(RLMLogLevel logLevel, NSString *message) {
    auto level = levelForLogLevel(logLevel);
    auto logger = Logger::get_default_logger();
    if (logger->would_log(LogCategory::sdk, level)) {
        logger->log(LogCategory::sdk, level, "%1", message.UTF8String);
    }
}
