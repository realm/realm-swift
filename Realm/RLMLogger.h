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

@class RLMLoggerToken;

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
 Setting the log level for a parent category automatically sets the same level for all child categories.
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
    RLMLogCategorySDK,
    /// Log category for all App related logs.
    RLMLogCategoryApp,
    /// Log category for all database related logs.
    RLMLogCategoryStorage,
    /// Log category for all database transaction related logs.
    RLMLogCategoryStorageTransaction,
    /// Log category for all database queries related logs.
    RLMLogCategoryStorageQuery,
    /// Log category for all database object related logs.
    RLMLogCategoryStorageObject,
    /// Log category for all database notification related logs.
    RLMLogCategoryStorageNotification,
    /// Log category for all sync related logs.
    RLMLogCategorySync,
    /// Log category for all sync client related logs.
    RLMLogCategorySyncClient,
    /// Log category for all sync client session related logs.
    RLMLogCategorySyncClientSession,
    /// Log category for all sync client changeset related logs.
    RLMLogCategorySyncClientChangeset,
    /// Log category for all sync client network related logs.
    RLMLogCategorySyncClientNetwork,
    /// Log category for all sync client reset related logs.
    RLMLogCategorySyncClientReset,
    /// Log category for all sync server related logs.
    RLMLogCategorySyncServer
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
typedef void (^RLMLogCategoryFunction)(RLMLogLevel level, RLMLogCategory category, NSString *message);

/**
 Global logger class used by all Realm components.

 By default messages are logged to NSLog(), with a log level of
 `RLMLogLevelInfo`. You can register an additional callback by calling
 `+[RLMLogger addLogFunction:]`:

    [RLMLogger addLogFunction:^(RLMLogLevel level, NSString *category, NSString *message) {
         NSLog(@"Realm Log - %lu, %@, %@", (unsigned long)level, category, message);
     }];

 To remove the default NSLog-logger, call `[RLMLogger removeAll];` first.

 To change the log level, call `[RLMLogger setLevel:forCategory:]`. The
 `RLMLogCategoryRealm` will update all log categories at once. All log
 callbacks share the same log levels and are called for every category.
*/
@interface RLMLogger : NSObject

/// :nodoc:
- (instancetype)init NS_UNAVAILABLE;

#pragma mark Category-based API

/**
 Registers a new logger callback function.

 The logger callback function will be invoked each time a message is logged
 with a log level greater than or equal to the current log level set for the
 message's category. The log function may be concurrently invoked from multiple
 threads.

 This function is thread-safe and can be called at any time, including from
 within other logger callbacks. It is guaranteed to work even if called
 concurrently with logging operations on another thread, but whether or not
 those operations are reported to the callback is left unspecified.

 This method returns a token which can be used to unregister the callback.
 Unlike notification tokens, storing this token is optional. If the token is
 destroyed without `invalidate` being called, it will be impossible to
 unregister the callback other than with `removeAll` or `resetToDefault`.
 */
+ (RLMLoggerToken *)addLogFunction:(RLMLogCategoryFunction)function NS_REFINED_FOR_SWIFT;

/**
 Removes all registered callbacks.

 This function is thread-safe. If called concurrently with logging operations
 on other threads, the registered callbacks may be invoked one more time after
 this function returns.

 This is the only way to remove the default NSLog logging.
 */
+ (void)removeAll;

/**
 Resets all of the global logger state to the default.

 This removes all callbacks, adds the default NSLog callback, sets the log
 level to Info, and undoes the effects of calling `setDefaultLogger:`.
 */
+ (void)resetToDefault;

/**
 Sets the log level for a given category.

 Some categories will also update the log level for child categories. See the
 documentation for RLMLogCategory for more details.
*/
+ (void)setLevel:(RLMLogLevel)level forCategory:(RLMLogCategory)category NS_REFINED_FOR_SWIFT;

/**
 Gets the log level for the specified category.
*/
+ (RLMLogLevel)levelForCategory:(RLMLogCategory)category NS_REFINED_FOR_SWIFT;


#pragma mark Deprecated API

/**
  Gets the logging threshold level used by the logger.
 */
@property (nonatomic) RLMLogLevel level
__attribute__((deprecated("Use `setLevel(level:category)` or `setLevel:category` instead.")));

/**
 Creates a logger with the associated log level and the logic function to define your own logging logic.

 @param level The log level to be set for the logger.
 @param logFunction The log function which will be invoked whenever there is a log message.

 @note This will set the log level for the log category `RLMLogCategoryRealm`.
*/
- (instancetype)initWithLevel:(RLMLogLevel)level logFunction:(RLMLogFunction)logFunction
__attribute__((deprecated("Use `+[Logger addLogFunction:]` instead.")));

/**
 The current default logger. When setting a logger as default, this logger will
 replace the current default logger and will be used whenever information must
 be logged.

 Overriding the default logger will result in callbacks registered with
 `addLogFunction:` never being invoked.
 */
@property (class) RLMLogger *defaultLogger NS_SWIFT_NAME(shared)
__attribute__((deprecated("Use `+[Logger addLogFunction:]` instead.")));
@end

/**
 A token which can be used to remove logger callbacks.

 This token only needs to be stored if you wish to be able to remove individual
 callbacks. If the token is destroyed without `invalidate` being called the
 callback will not be removed.
 */
RLM_SWIFT_SENDABLE RLM_FINAL
@interface RLMLoggerToken : NSObject
/**
 Removes the associated logger callback.

 This function is thread-safe and idempotent. Calling it multiple times or from
 multiple threads at once is not an error. If called concurrently with logging
 operations on another thread, the associated callback may be called one more
 time per thread after this function returns.
 */
- (void)invalidate;
@end

RLM_HEADER_AUDIT_END(nullability)
