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
    /// Information about sync events will be logged. More events will be logged than with `RLMLogLevelInfo`.
    RLMLogLevelDetail,
    /// Log information that can aid in debugging.
    ///
    /// - warning: Will incur a measurable performance impact.
    RLMLogLevelDebug,
    /// Log information that can aid in debugging. More events will be logged than with `RLMLogLevelDebug`.
    ///
    /// - warning: Will incur a measurable performance impact.
    RLMLogLevelTrace,
    /// Log information that can aid in debugging. More events will be logged than with `RLMLogLevelTrace`.
    ///
    /// - warning: Will incur a measurable performance impact.
    RLMLogLevelAll
} NS_SWIFT_NAME(LogLevel);

/// A log callback function which can be set on RLMLogger.
///
/// The log function may be called from multiple threads simultaneously, and is
/// responsible for performing its own synchronization if any is required.
RLM_SWIFT_SENDABLE // invoked on a background thread
typedef void (^RLMLogFunction)(RLMLogLevel level, NSString *message);

/**
 `RLMLogger` is used for creating your own custom logging logic.

 You can define your own logger creating an instance of `RLMLogger` and define the log function which will be
 invoked whenever there is a log message.
 Set this custom logger as you default logger using `setDefaultLogger`.

     RLMLogger.defaultLogger = [[RLMLogger alloc] initWithLevel:RLMLogLevelDebug
                                                logFunction:^(RLMLogLevel level, NSString * message) {
         NSLog(@"Realm Log - %lu, %@", (unsigned long)level, message);
     }];

 @note By default default log threshold level is `RLMLogLevelInfo`, and logging strings are output to Apple System Logger.
*/
@interface RLMLogger : NSObject

/**
  Gets the logging threshold level used by the logger.
 */
@property (nonatomic) RLMLogLevel level;

/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

/**
 Creates a logger with the associated log level and the logic function to define your own logging logic.

 @param level The log level to be set for the logger.
 @param logFunction The log function which will be invoked whenever there is a log message.
*/
- (instancetype)initWithLevel:(RLMLogLevel)level logFunction:(RLMLogFunction)logFunction;

#pragma mark RLMLogger Default Logger API

/**
 The current default logger. When setting a logger as default, this logger will be used whenever information must be logged.
 */
@property (class) RLMLogger *defaultLogger NS_SWIFT_NAME(shared);

@end

RLM_HEADER_AUDIT_END(nullability)
