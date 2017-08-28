////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

/**
 Access levels which can be granted to Realm Mobile Platform users
 for specific synchronized Realms, using the permissions APIs.

 Note that each access level guarantees all allowed actions provided
 by less permissive access levels. Specifically, users with write
 access to a Realm can always read from that Realm, and users with
 administrative access can always read or write from the Realm.
 */
typedef NS_ENUM(NSUInteger, RLMSyncAccessLevel) {
    /// No access whatsoever.
    RLMSyncAccessLevelNone          = 0,
    /**
     User can only read the contents of the Realm.

     @warning Users who have read-only access to a Realm should open the
              Realm using `+[RLMRealm asyncOpenWithConfiguration:callbackQueue:callback:]`.
              Attempting to directly open the Realm is an error; in this
              case the Realm must be deleted and re-opened.
     */
    RLMSyncAccessLevelRead          = 1,
    /// User can read and write the contents of the Realm.
    RLMSyncAccessLevelWrite         = 2,
    /// User can read, write, and administer the Realm, including
    /// granting permissions to other users.
    RLMSyncAccessLevelAdmin         = 3,
};

NS_ASSUME_NONNULL_BEGIN

/**
 A property on which a `RLMResults<RLMSyncPermission *>` can be queried or filtered.

 @warning If building `NSPredicate`s using format strings including these string
          constants, use %K instead of %@ as the substitution parameter.
 */
typedef NSString * RLMSyncPermissionSortProperty NS_STRING_ENUM;

/// Sort by the Realm Object Server path to the Realm to which the permission applies.
extern RLMSyncPermissionSortProperty const RLMSyncPermissionSortPropertyPath;
/// Sort by the identity of the user to whom the permission applies.
extern RLMSyncPermissionSortProperty const RLMSyncPermissionSortPropertyUserID;
/// Sort by the date the permissions were last updated.
extern RLMSyncPermissionSortProperty const RLMSyncPermissionSortPropertyUpdated;

/**
 A value representing a permission granted to the specified user(s) to access the specified Realm(s).

 `RLMSyncPermission` is immutable and can be accessed from any thread.

 See https://realm.io/docs/realm-object-server/#permissions for general documentation.
 */
@interface RLMSyncPermission : NSObject

/**
 The Realm Object Server path to the Realm to which this permission applies (e.g. "/path/to/realm").

 Specify "*" if this permission applies to all Realms managed by the server.
 */
@property (nonatomic, readonly) NSString *path;

/**
 The access level described by this permission.
 */
@property (nonatomic, readonly) RLMSyncAccessLevel accessLevel;

/// Whether the access level allows the user to read from the Realm.
@property (nonatomic, readonly) BOOL mayRead;

/// Whether the access level allows the user to write to the Realm.
@property (nonatomic, readonly) BOOL mayWrite;

/// Whether the access level allows the user to administer the Realm.
@property (nonatomic, readonly) BOOL mayManage;

/**
 Create a new sync permission value, for use with permission APIs.

 @param path        The Realm Object Server path to the Realm whose permission should be modified
                    (e.g. "/path/to/realm"). Pass "*" to apply to all Realms managed by the user.
 @param identity    The Realm Object Server identity of the user who should be granted access to
                    the Realm at `path`.
                    Pass "*" to apply to all users managed by the server.
 @param accessLevel The access level to grant.
 */
- (instancetype)initWithRealmPath:(NSString *)path
                         identity:(NSString *)identity
                      accessLevel:(RLMSyncAccessLevel)accessLevel;

/**
 Create a new sync permission value, for use with permission APIs.

 @param path        The Realm Object Server path to the Realm whose permission should be modified
                    (e.g. "/path/to/realm"). Pass "*" to apply to all Realms managed by the user.
 @param username    The username (often an email address) of the user who should be granted access
                    to the Realm at `path`.
 @param accessLevel The access level to grant.
 */
- (instancetype)initWithRealmPath:(NSString *)path
                         username:(NSString *)username
                      accessLevel:(RLMSyncAccessLevel)accessLevel;

/**
 The identity of the user to whom this permission is granted, or "*"
 if all users are granted this permission. Nil if the permission is
 defined in terms of a key-value pair.
 */
@property (nullable, nonatomic, readonly) NSString *identity;

/**
 If the permission is defined in terms of a key-value pair, the key
 describing the type of criterion used to determine what users the
 permission applies to. Otherwise, nil.
 */
@property (nullable, nonatomic, readonly) NSString *key;

/**
 If the permission is defined in terms of a key-value pair, a string
 describing the criterion value used to determine what users the
 permission applies to. Otherwise, nil.
 */
@property (nullable, nonatomic, readonly) NSString *value;

/**
 When this permission was last updated.
 */
@property (nonatomic, readonly) NSDate *updatedAt;

/// :nodoc:
- (instancetype)init __attribute__((unavailable("Use the designated initializer")));

/// :nodoc:
+ (instancetype)new __attribute__((unavailable("Use the designated initializer")));

// MARK: - Migration assistance

/// :nodoc:
@property (nullable, nonatomic, readonly) NSString *userId __attribute__((unavailable("Renamed to `identity`")));

/// :nodoc:
- (instancetype)initWithRealmPath:(NSString *)path
                           userID:(NSString *)identity
                      accessLevel:(RLMSyncAccessLevel)accessLevel
__attribute__((unavailable("Renamed to `-initWithRealmPath:identity:accessLevel:`")));

@end

NS_ASSUME_NONNULL_END
