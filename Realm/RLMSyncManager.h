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

#import "RLMSyncUtil.h"

@class RLMSyncSession;

/// An enum representing different levels of sync-related logging that can be configured.
typedef NS_ENUM(NSUInteger, RLMSyncLogLevel) {
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

NS_ASSUME_NONNULL_BEGIN

/// A block type representing a block which can be used to report a sync-related error to the application. If the error
/// pertains to a specific session, that session will also be passed into the block.
typedef void(^RLMSyncErrorReportingBlock)(NSError *, RLMSyncSession * _Nullable);

/**
 A singleton manager which serves as a central point for sync-related configuration.
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
@property (nullable, nonatomic, copy) RLMSyncErrorReportingBlock errorHandler;

/**
 A reverse-DNS string uniquely identifying this application. In most cases this is automatically set by the SDK, and
 does not have to be explicitly configured.
 */
@property (nonatomic, copy) NSString *appID;

/**
 The logging threshold which newly opened synced Realms will use. Defaults to
 `RLMSyncLogLevelInfo`.

 Logging strings are output to Apple System Logger.

 @warning This property must be set before any synced Realms are opened. Setting it after
          opening any synced Realm will do nothing.
 */
@property (nonatomic) RLMSyncLogLevel logLevel;

/**
 The name of the HTTP header to send authorization data in when making requests to a Realm Object Server which has
 been configured to expect a custom authorization header.
 */
@property (nullable, nonatomic, copy) NSString *authorizationHeaderName;

/**
 Extra HTTP headers to append to every request to a Realm Object Server.
 */
@property (nullable, nonatomic, copy) NSDictionary<NSString *, NSString *> *customRequestHeaders;

/**
 A map of hostname to file URL for pinned certificates to use for HTTPS requests.

 When initiating a HTTPS connection to a server, if this dictionary contains an
 entry for the server's hostname, only the certificates stored in the file (or
 any certificates signed by it, if the file contains a CA cert) will be accepted
 when initiating a connection to a server. This prevents certain certain kinds
 of man-in-the-middle (MITM) attacks, and can also be used to trust a self-signed
 certificate which would otherwise be untrusted.

 On macOS, the certificate files may be in any of the formats supported by
 SecItemImport(), including PEM and .cer (see SecExternalFormat for a complete
 list of possible formats). On iOS and other platforms, only DER .cer files are
 supported.

 For example, to pin example.com to a .cer file included in your bundle:

 <pre>
 RLMSyncManager.sharedManager.pinnedCertificatePaths = @{
    @"example.com": [NSBundle.mainBundle pathForResource:@"example.com" ofType:@"cer"]
 };
 </pre>
 */
@property (nullable, nonatomic, copy) NSDictionary<NSString *, NSURL *> *pinnedCertificatePaths;

/// The sole instance of the singleton.
+ (instancetype)sharedManager NS_REFINED_FOR_SWIFT;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("RLMSyncManager cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("RLMSyncManager cannot be created directly")));

NS_ASSUME_NONNULL_END

@end
