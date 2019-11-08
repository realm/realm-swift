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

@class RLMRealmConfiguration;
@class RLMSyncUser;

NS_ASSUME_NONNULL_BEGIN

/**
 A configuration object representing configuration state for a Realm which is intended to sync with a Realm Object
 Server.
 */
@interface RLMSyncConfiguration : NSObject

/// The user to which the remote Realm belongs.
@property (nonatomic, readonly) RLMSyncUser *user;

/**
 The URL of the remote Realm upon the Realm Object Server.

 @warning The URL cannot end with `.realm`, `.realm.lock` or `.realm.management`.
 */
@property (nonatomic, readonly) NSURL *realmURL;

/**
 A local path to a file containing the trust anchors for SSL connections.

 Only the certificates stored in the PEM file (or any certificates signed by it,
 if the file contains a CA cert) will be accepted when initiating a connection
 to a server. This prevents certain certain kinds of man-in-the-middle (MITM)
 attacks, and can also be used to trust a self-signed certificate which would
 otherwise be untrusted.

 On macOS, the file may be in any of the formats supported by SecItemImport(),
 including PEM and .cer (see SecExternalFormat for a complete list of possible
 formats). On iOS and other platforms, only DER .cer files are supported.
 */
@property (nonatomic, nullable) NSURL *pinnedCertificateURL;

/**
 Whether SSL certificate validation is enabled for the connection associated
 with this configuration value. SSL certificate validation is ON by default.

 @warning NEVER disable certificate validation for clients and servers in production.
 */
@property (nonatomic) BOOL enableSSLValidation;

/// :nodoc:
@property (nonatomic) BOOL isPartial __attribute__((unavailable("Use 'fullSynchronization' instead.")));

/**
 Whether this Realm should be a fully synchronized Realm.
 
 Synchronized Realms comes in two flavors: Query-based and Fully synchronized.
 A fully synchronized Realm will automatically synchronize the entire Realm in
 the background while a query-based Realm will only synchronize the data being
 subscribed to. Synchronized realms are by default query-based unless this
 boolean is set.
 */
@property (nonatomic) BOOL fullSynchronization;

/**
 The prefix that is prepended to the path in the HTTP request that initiates a
 sync connection. The value specified must match with the server's expectation.
 Changing the value of `urlPrefix` should be matched with a corresponding
 change of the server's configuration.
 If no value is specified here then the default `/realm-sync` path is used.
*/
@property (nonatomic, nullable, copy) NSString *urlPrefix;

/// :nodoc:
- (instancetype)initWithUser:(RLMSyncUser *)user realmURL:(NSURL *)url __attribute__((unavailable("Use [RLMSyncUser configurationWithURL:] instead")));

/// :nodoc:
+ (RLMRealmConfiguration *)automaticConfiguration __attribute__((unavailable("Use [RLMSyncUser configuration] instead")));

/// :nodoc:
+ (RLMRealmConfiguration *)automaticConfigurationForUser:(RLMSyncUser *)user __attribute__((unavailable("Use [RLMSyncUser configuration] instead")));

/// :nodoc:
- (instancetype)init __attribute__((unavailable("This type cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("This type cannot be created directly")));

@end

NS_ASSUME_NONNULL_END
