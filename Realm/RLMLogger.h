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

#import <Realm/RLMConstants.h>

RLM_HEADER_AUDIT_BEGIN(nullability)

/// An enum representing different levels of sync-related logging that can be configured.
typedef RLM_CLOSED_ENUM(NSUInteger, RLMLogLevel) {
    /// Nothing will ever be logged.
    RLMLogLevelOff,
    /// Only fatal errors will be logged.
    RLMLogLevelFatal,
    /// Only errors will be logged.
    RLMLogLevelError,
    /// Warnings and errors will be logged.
    RLMLogLevelWarn,
    /// Information about sync events will be logged. Fewer events will be logged in order to avoid overhead.
    RLMLogLevelInfo,
    /// Information about sync events will be logged. More events will be logged than with `RLMSyncLogLevelInfo`.
    RLMLogLevelDetail,
    /// Log information that can aid in debugging.
    ///
    /// - warning: Will incur a measurable performance impact.
    RLMLogLevelDebug,
    /// Log information that can aid in debugging. More events will be logged than with `RLMSyncLogLevelDebug`.
    ///
    /// - warning: Will incur a measurable performance impact.
    RLMLogLevelTrace,
    /// Log information that can aid in debugging. More events will be logged than with `RLMSyncLogLevelTrace`.
    ///
    /// - warning: Will incur a measurable performance impact.
    RLMLogLevelAll
} NS_SWIFT_NAME(LogLevel);

/**
 `RLMLogger` is a base class for creating your own custom logging logic.

 Define your custom logger by subclassing `RLMLogger` and override the `doLog`
 function to implement your custom logging logic.

     // InMemoryLogger.h
     @interface InMemoryLogger : RLMLogger
     @property (nonatomic, strong) NSString *logs;
     @end

     // InMemoryLogger.m
     @implementation InMemoryLogger
     - (void)doLog:(RLMLogLevel)logLevel message:(NSString *)message {
        NSString *newLogs = [_logs stringByAppendingFormat:@" %@ %lu %@", [NSDate now], logLevel, message];
        _logs = newLogs;
     }
     @end

 Set this custom logger as you default logger using `[RLMLogger setDefaultLogger:]`.
*/
@interface RLMLogger : NSObject

/**
  Gets the logging threshold level used by the current logger.
  Default log level is `RLMLogLevelOff`, if not set.

  @warning Setting a global log threshold level after setting a custom logger will override any level threshold set by any default logger.
 Logger will return log information, with associated log level, lower or equal to the global log level in that case.
 */
@property (nonatomic) RLMLogLevel level;

/// Creates a custom logger without any associated log level.
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 Log a message to the supplied level.

 @param logLevel The log level for the message.
 @param message The message to log.
 */
- (void)logWithLevel:(RLMLogLevel)logLevel message:(NSString *)message, ... NS_SWIFT_UNAVAILABLE("");

/**
 Override this method to implement your own custom logging logic. 

 @param logLevel The log level for the message returned.
 @param message The message logged.
 */
- (void)doLog:(RLMLogLevel)logLevel message:(NSString *)message NS_SWIFT_NAME(doLog(level:message:));

#pragma mark RLMLogger Static API

/// The logging threshold level used by the global logger.
+ (RLMLogLevel)logLevel;

/**
 Sets the global logger threshold level to the given value.

 @param logLevel The `RLMLogLevel` to be set.

 By default logging strings are output to Apple System Logger. Setting a default `RLMLogger` to
 perform custom logging logic instead.

 @warning Setting a global log threshold level after setting a custom logger will override any level threshold set by any default logger.
 Logger will return log information, with associated log level, lower or equal to the global log level in that case.
 */
+ (void)setLogLevel:(RLMLogLevel)logLevel;

/**
 Sets a custom logger implementation as default, that will be used whenever information must be logged.

 @param logger The `RLMLogger` to be configured as the default logger
 */
+ (void)setDefaultLogger:(RLMLogger *)logger NS_SWIFT_NAME(setDefaultLogger(_:));

@end

RLM_HEADER_AUDIT_END(nullability)
