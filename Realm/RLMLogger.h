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

/**
An enum representing different categories of sync-related logging that can be configured.
Category hierarchy:
```
 Realm
 ├─► Storage
 │   ├─► Transaction
 │   ├─► Query
 │   ├─► Object
 │   └─► Notification
 ├─► Sync
 │   ├─► Client
 │   │   ├─► Session
 │   │   ├─► Changeset
 │   │   ├─► Network
 │   │   └─► Reset
 │   └─► Server
 ├─► App
 └─► Sdk
```
*/
typedef NS_ENUM(NSUInteger, RLMLogCategory) {
    ///  Top level log category for Realm, updating this category level would set all other subcategories too.
    RLMLogCategoryRealm,
    /// Log category for all sdk related logs.
    RLMLogCategoryRealmSDK,
    /// Log category for all app related logs.
    RLMLogCategoryRealmApp,
    /// Log category for all database related logs.
    RLMLogCategoryRealmStorage,
    /// Log category for all database transaction related logs.
    RLMLogCategoryRealmStorageTransaction,
    /// Log category for all database queries related logs.
    RLMLogCategoryRealmStorageQuery,
    /// Log category for all database object related logs.
    RLMLogCategoryRealmStorageObject,
    /// Log category for all database notification related logs.
    RLMLogCategoryRealmStorageNotification,
    /// Log category for all sync related logs.
    RLMLogCategoryRealmSync,
    /// Log category for all sync client related logs.
    RLMLogCategoryRealmSyncClient,
    /// Log category for all sync client session related logs.
    RLMLogCategoryRealmSyncClientSession,
    /// Log category for all sync client changeset related logs.
    RLMLogCategoryRealmSyncClientChangeset,
    /// Log category for all sync client network related logs.
    RLMLogCategoryRealmSyncClientNetwork,
    /// Log category for all sync client reset related logs.
    RLMLogCategoryRealmSyncClientReset,
    /// Log category for all sync server related logs.
    RLMLogCategoryRealmSyncServer
};

/// A log callback function which can be set on RLMLogger.
///
/// The log function may be called from multiple threads simultaneously, and is
/// responsible for performing its own synchronization if any is required.
RLM_SWIFT_SENDABLE // invoked on a background thread
typedef void (^RLMLogFunction)(RLMLogLevel level, NSString *message);

/// A log callback function which can be set on RLMLogger.
///
/// The log function may be called from multiple threads simultaneously, and is
/// responsible for performing its own synchronization if any is required.
RLM_SWIFT_SENDABLE // invoked on a background thread
typedef void (^RLMLogCategoryFunction)(RLMLogLevel level, RLMLogCategory category, NSString *message) NS_REFINED_FOR_SWIFT;
/**
 Global logger class used by all Realm components.

 You can define your own logger creating an instance of `RLMLogger` and define the log function which will be
 invoked whenever there is a log message.
 Set this custom logger as you default logger using `setDefaultLogger`.

     RLMLogger.defaultLogger = [[RLMLogger alloc] initWithLogFunction:^(RLMLogLevel level, NSString *category, NSString *message) {
         NSLog(@"Realm Log - %lu, %@, %@", (unsigned long)level, category, message);
     }];

 @note By default default log threshold level is `RLMLogLevelInfo`, and logging strings are output to Apple System Logger.
*/
@interface RLMLogger : NSObject

/**
  Gets the logging threshold level used by the logger.
 */
@property (nonatomic) RLMLogLevel level
__attribute__((deprecated("Use `setLevel(level:category)` or `setLevel:category` instead.")));

/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

/**
 Creates a logger with the associated log level and the logic function to define your own logging logic.

 @param level The log level to be set for the logger.
 @param logFunction The log function which will be invoked whenever there is a log message.

 @note This will set the log level for the log category `RLMLogCategoryRealm`.
*/
- (instancetype)initWithLevel:(RLMLogLevel)level logFunction:(RLMLogFunction)logFunction
__attribute__((deprecated("Use `initWithLogFunction:` instead.")));

/**
 Creates a logger with a callback, which will be invoked whenever there is a log message.

 @param logFunction The log function which will be invoked whenever there is a log message.
*/
- (instancetype)initWithLogFunction:(RLMLogCategoryFunction)logFunction;

#pragma mark RLMLogger Default Logger API

/**
 The current default logger. When setting a logger as default, this logger will replace the current default logger and will
 be used whenever information must be logged.

 @note By default the logger
 */
@property (class) RLMLogger *defaultLogger NS_SWIFT_NAME(shared);

/**
 Log a message to the supplied level.

 @param logLevel The log level for the message.
 @param category The log category for the message.
 @param message The message to log.
 */
- (void)logWithLevel:(RLMLogLevel)logLevel category:(RLMLogCategory)category message:(NSString *)message;

/**
 Sets the gobal log level for a given category.

 @param level The log level to be set for the logger.
 @param category The log function which will be invoked whenever there is a log message.
*/
+ (void)setLevel:(RLMLogLevel)level forCategory:(RLMLogCategory)category NS_REFINED_FOR_SWIFT;

/**
 Gets the global log level for the specified category.

 @param category The log category which we need the level.
 @returns The log level for the specified category
*/
+ (RLMLogLevel)levelForCategory:(RLMLogCategory)category NS_REFINED_FOR_SWIFT;

@end

RLM_HEADER_AUDIT_END(nullability)
