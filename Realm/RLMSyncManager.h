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

#import <Foundation/Foundation.h>

#import <Realm/RLMSyncUtil.h>

@class RLMSyncSession, RLMSyncTimeoutOptions, RLMAppConfiguration;

NS_ASSUME_NONNULL_BEGIN

/// An enum representing different levels of sync-related logging that can be configured.
typedef RLM_CLOSED_ENUM(NSUInteger, RLMSyncLogLevel) {
    /// Nothing will ever be logged.
    RLMSyncLogLevelOff,
    /// Only fatal errors will be logged.
    RLMSyncLogLevelFatal,
    /// Only errors will be logged.
    RLMSyncLogLevelError,
    /// Warnings and errors will be logged.
    RLMSyncLogLevelWarn,
    /// Information about sync events will be logged. Fewer events will be logged in order to avoid overhead.
    RLMSyncLogLevelInfo,
    /// Information about sync events will be logged. More events will be logged than with `RLMSyncLogLevelInfo`.
    RLMSyncLogLevelDetail,
    /// Log information that can aid in debugging.
    ///
    /// - warning: Will incur a measurable performance impact.
    RLMSyncLogLevelDebug,
    /// Log information that can aid in debugging. More events will be logged than with `RLMSyncLogLevelDebug`.
    ///
    /// - warning: Will incur a measurable performance impact.
    RLMSyncLogLevelTrace,
    /// Log information that can aid in debugging. More events will be logged than with `RLMSyncLogLevelTrace`.
    ///
    /// - warning: Will incur a measurable performance impact.
    RLMSyncLogLevelAll
};

/// A log callback function which can be set on RLMSyncManager.
///
/// The log function may be called from multiple threads simultaneously, and is
/// responsible for performing its own synchronization if any is required.
typedef void (^RLMSyncLogFunction)(RLMSyncLogLevel level, NSString *message);

/// A block type representing a block which can be used to report a sync-related error to the application. If the error
/// pertains to a specific session, that session will also be passed into the block.
typedef void(^RLMSyncErrorReportingBlock)(NSError *, RLMSyncSession * _Nullable);

/**
 A manager which serves as a central point for sync-related configuration.
 */
@interface RLMSyncManager : NSObject

/**
 A block which can optionally be set to report sync-related errors to your application.

 Any error reported through this block will be of the `RLMSyncError` type, and marked
 with the `RLMSyncErrorDomain` domain.

 Errors reported through this mechanism are fatal, with several exceptions. Please consult
 `RLMSyncError` for information about the types of errors that can be reported through
 the block, and for for suggestions on handling recoverable error codes.

 @see `RLMSyncError`
 */
@property (nullable, atomic, copy) RLMSyncErrorReportingBlock errorHandler;

/**
 A reverse-DNS string uniquely identifying this application. In most cases this
 is automatically set by the SDK, and does not have to be explicitly configured.
 */
@property (nonatomic, copy) NSString *appID;

/**
 A string identifying this application which is included in the User-Agent
 header of sync connections. By default, this will be the application's bundle
 identifier.

 This property must be set prior to opening a synchronized Realm for the first
 time. Any modifications made after opening a Realm will be ignored.
 */
@property (nonatomic, copy) NSString *userAgent;

/**
 The logging threshold which newly opened synced Realms will use. Defaults to
 `RLMSyncLogLevelInfo`.

 By default logging strings are output to Apple System Logger. Set `logger` to
 perform custom logging logic instead.

 @warning This property must be set before any synced Realms are opened. Setting it after
          opening any synced Realm will do nothing.
 */
@property (nonatomic) RLMSyncLogLevel logLevel;

/**
 The function which will be invoked whenever the sync client has a log message.

 If nil, log strings are output to Apple System Logger instead.

 @warning This property must be set before any synced Realms are opened. Setting
 it after opening any synced Realm will do nothing.
 */
@property (nonatomic, nullable) RLMSyncLogFunction logger;

/**
 The name of the HTTP header to send authorization data in when making requests to Atlas App Services which has
 been configured to expect a custom authorization header.
 */
@property (nullable, nonatomic, copy) NSString *authorizationHeaderName;

/**
 Extra HTTP headers to append to every request to Atlas App Services.

 Modifying this property while sync sessions are active will result in all
 sessions disconnecting and reconnecting using the new headers.
 */
@property (nullable, nonatomic, copy) NSDictionary<NSString *, NSString *> *customRequestHeaders;

/**
 Options for the assorted types of connection timeouts for sync connections.

 If nil default values for all timeouts are used instead.

 @warning This property must be set before any synced Realms are opened. Setting
 it after opening any synced Realm will do nothing.
 */
@property (nullable, nonatomic, copy) RLMSyncTimeoutOptions *timeoutOptions;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMSyncManager cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMSyncManager cannot be created directly")));

@end

/**
  Options for configuring timeouts and intervals in the sync client.
 */
@interface RLMSyncTimeoutOptions : NSObject
/// The maximum number of milliseconds to allow for a connection to
/// become fully established. This includes the time to resolve the
/// network address, the TCP connect operation, the SSL handshake, and
/// the WebSocket handshake.
///
/// Defaults to 2 minutes.
@property (nonatomic) NSUInteger connectTimeout;

/// The number of milliseconds to keep a connection open after all
/// sessions have been abandoned.
///
/// After all synchronized Realms have been closed for a given server, the
/// connection is kept open until the linger time has expire to avoid the
/// overhead of reestablishing the connection when Realms are being closed and
/// reopened.
///
/// Defaults to 30 seconds.
@property (nonatomic) NSUInteger connectionLingerTime;

/// The number of milliseconds between each heartbeat ping message.
///
/// The client periodically sends ping messages to the server to check if the
/// connection is still alive. Shorter periods make connection state change
/// notifications more responsive at the cost of battery life (as the antenna
/// will have to wake up more often).
///
/// Defaults to 1 minute.
@property (nonatomic) NSUInteger pingKeepalivePeriod;

/// How long in milliseconds to wait for a reponse to a heartbeat ping before
/// concluding that the connection has dropped.
///
/// Shorter values will make connection state change notifications more
/// responsive as it will only change to `disconnected` after this much time has
/// elapsed, but overly short values may result in spurious disconnection
/// notifications when the server is simply taking a long time to respond.
///
/// Defaults to 2 minutes.
@property (nonatomic) NSUInteger pongKeepaliveTimeout;

/// The maximum amount of time, in milliseconds, since the loss of a
/// prior connection, for a new connection to be considered a "fast
/// reconnect".
///
/// When a client first connects to the server, it defers uploading any local
/// changes until it has downloaded all changesets from the server. This
/// typically reduces the total amount of merging that has to be done, and is
/// particularly beneficial the first time that a specific client ever connects
/// to the server.
///
/// When an existing client disconnects and then reconnects within the "fact
/// reconnect" time this is skipped and any local changes are uploaded
/// immediately without waiting for downloads, just as if the client was online
/// the whole time.
///
/// Defaults to 1 minute.
@property (nonatomic) NSUInteger fastReconnectLimit;

/// The app configuration that has initialized this SyncManager.
/// This can be set multiple times. This gives the SyncManager
/// access to necessary app functionality.
@property (nonatomic, readonly) RLMAppConfiguration *appConfiguration;
@end

NS_ASSUME_NONNULL_END
