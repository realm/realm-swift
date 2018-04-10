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
 Whether SSL certificate validation is enabled for the connection associated
 with this configuration value. SSL certificate validation is ON by default.

 @warning NEVER disable certificate validation for clients and servers in production.
 */
@property (nonatomic) BOOL enableSSLValidation;

/**
 Whether this Realm should be opened in 'partial synchronization' mode.
 Partial synchronization mode means that no objects are synchronized from the remote Realm
 except those matching queries that the user explicitly specifies.

 @warning Partial synchronization is a tech preview. Its APIs are subject to change.
*/
@property (nonatomic) BOOL isPartial;

/**
 The prefix that is prepended to the path in the HTTP request
 that initiates a sync connection. The value specified must match with the server's expectation.
 Changing the value of `urlPrefix` should be matched with a corresponding
 change of the server's configuration.
 If no value is specified here then the default `/realm-sync` path is used.
*/
@property (nonatomic, nullable, copy) NSString *urlPrefix;

/**
 Create a sync configuration instance.

 @param user    A `RLMSyncUser` that owns the Realm at the given URL.
 @param url     The unresolved absolute URL to the Realm on the Realm Object Server, e.g.
                `realm://example.org/~/path/to/realm`. "Unresolved" means the path should
                contain the wildcard marker `~`, which will automatically be filled in with
                the user identity by the Realm Object Server.
 */
- (instancetype)initWithUser:(RLMSyncUser *)user realmURL:(NSURL *)url;

/**
Return a Realm configuration for syncing with the default Realm of the currently logged-in sync user.

Partial synchronization is enabled in the returned configuration.
 */
+ (RLMRealmConfiguration *)automaticConfiguration;

/**
 Return a Realm configuration for syncing with the default Realm of the given sync user.

 Partial synchronization is enabled in the returned configuration.
 */
+ (RLMRealmConfiguration *)automaticConfigurationForUser:(RLMSyncUser *)user;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("This type cannot be created directly")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("This type cannot be created directly")));

@end

NS_ASSUME_NONNULL_END
