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

#import <Realm/RLMObject.h>

@protocol RLMPermission, RLMPermissionUser;
@class RLMPermission, RLMPermissionUser, RLMPermissionRole,
       RLMArray<RLMObjectType>, RLMLinkingObjects<RLMObjectType: RLMObject *>;

NS_ASSUME_NONNULL_BEGIN

/**
 A permission which can be applied to a Realm, Class, or specific Object.

 Permissions are applied by adding the permission to the RLMRealmPermission singleton
 object, the RLMClassPermission object for the desired class, or to a user-defined
 RLMArray<RLMPermission> property on a specific Object instance. The meaning of each of
 the properties of RLMPermission depend on what the permission is applied to, and so are
 left undocumented here. See `RLMRealmPrivileges`, `RLMClassPrivileges`, and
 `RLMObjectPrivileges` for details about what each of the properties mean when applied to
 that type.
 */
@interface RLMPermission : RLMObject
/// The Role which this Permission applies to. All users within the Role are
/// granted the permissions specified by the fields below any
/// objects/classes/realms which use this Permission.
///
/// This property cannot be modified once set.
@property (nonatomic) RLMPermissionRole *role;

/// Whether the user can read the object to which this Permission is attached.
@property (nonatomic) bool canRead;
/// Whether the user can modify the object to which this Permission is attached.
@property (nonatomic) bool canUpdate;
/// Whether the user can delete the object to which this Permission is attached.
///
/// This field is only applicable to Permissions attached to Objects, and not
/// to Realms or Classes.
@property (nonatomic) bool canDelete;
/// Whether the user can add or modify Permissions for the object which this
/// Permission is attached to.
@property (nonatomic) bool canSetPermissions;
/// Whether the user can subscribe to queries for this object type.
///
/// This field is only applicable to Permissions attached to Classes, and not
/// to Realms or Objects.
@property (nonatomic) bool canQuery;
/// Whether the user can create new objects of the type this Permission is attached to.
///
/// This field is only applicable to Permissions attached to Classes, and not
/// to Realms or Objects.
@property (nonatomic) bool canCreate;
/// Whether the user can modify the schema of the Realm which this
/// Permission is attached to.
///
/// This field is only applicable to Permissions attached to Realms, and not
/// to Realms or Objects.
@property (nonatomic) bool canModifySchema;

/**
 Returns the Permission object for the named Role in the array, creating it if needed.

 This function should be used in preference to manually querying the array for
 the applicable Permission as it ensures that there is exactly one Permission
 for the given Role in the array, merging duplicates or creating and adding new
 ones as needed.
*/
+ (RLMPermission *)permissionForRoleNamed:(NSString *)roleName inArray:(RLMArray<RLMPermission *><RLMPermission> *)array;

/**
 Returns the Permission object for the named Role on the Realm, creating it if needed.

 This function should be used in preference to manually querying for the
 applicable Permission as it ensures that there is exactly one Permission for
 the given Role on the Realm, merging duplicates or creating and adding new ones
 as needed.
*/
+ (RLMPermission *)permissionForRoleNamed:(NSString *)roleName onRealm:(RLMRealm *)realm;

/**
 Returns the Permission object for the named Role on the Class, creating it if needed.

 This function should be used in preference to manually querying for the
 applicable Permission as it ensures that there is exactly one Permission for
 the given Role on the Class, merging duplicates or creating and adding new ones
 as needed.
*/
+ (RLMPermission *)permissionForRoleNamed:(NSString *)roleName onClass:(Class)cls realm:(RLMRealm *)realm;

/**
 Returns the Permission object for the named Role on the named class, creating it if needed.

 This function should be used in preference to manually querying for the
 applicable Permission as it ensures that there is exactly one Permission for
 the given Role on the Class, merging duplicates or creating and adding new ones
 as needed.
*/
+ (RLMPermission *)permissionForRoleNamed:(NSString *)roleName onClassNamed:(NSString *)className realm:(RLMRealm *)realm;

/**
 Returns the Permission object for the named Role on the object, creating it if needed.

 This function should be used in preference to manually querying for the
 applicable Permission as it ensures that there is exactly one Permission for
 the given Role on the Realm, merging duplicates or creating and adding new ones
 as needed.

 The given object must have a RLMArray<RLMPermission> property defined on it. If
 more than one such property is present, the first will be used.
*/
+ (RLMPermission *)permissionForRoleNamed:(NSString *)roleName onObject:(RLMObject *)object;
@end

/**
 A Role within the permissions system.

 A Role consists of a name for the role and a list of users which are members of the role.
 Roles are granted privileges on Realms, Classes and Objects, and in turn grant those
 privileges to all users which are members of the role.

 A role named "everyone" is automatically created in new Realms, and all new users which
 connect to the Realm are automatically added to it. Any other roles you wish to use are
 managed as normal Realm objects.
 */
@interface RLMPermissionRole : RLMObject
/// The name of the Role
@property (nonatomic) NSString *name;
/// The users which belong to the role
@property (nonatomic) RLMArray<RLMPermissionUser *><RLMPermissionUser> *users;
@end

/**
 A representation of a sync user within the permissions system.

 RLMPermissionUser objects are created automatically for each sync user which connects to
 a Realm, and can also be created manually if you wish to grant permissions to a user
 which has not yet connected to this Realm.
 */
@interface RLMPermissionUser : RLMObject
/// The unique Realm Object Server user ID string identifying this user. This will have
/// the same value as `-[RLMSyncUser identity]`.
@property (nonatomic) NSString *identity;

/// The user's private role. This will be initialized to a role named for the user's
/// identity that contains this user as its only member.
@property (nonatomic) RLMPermissionRole *role;

/// Roles which this user belongs to.
@property (nonatomic, readonly) RLMLinkingObjects<RLMPermissionRole *> *roles;

/// Get the user object in the given Realm, creating it if needed.
+ (RLMPermissionUser *)userInRealm:(RLMRealm *)realm withIdentity:(NSString *)identity;
@end

/**
 A singleton object which describes Realm-wide permissions.

 An object of this type is automatically created in the Realm for you, and more objects
 cannot be created manually. Call `+[RLMRealmPermission objectInRealm:]` to obtain the
 instance for a specific Realm.

 See `RLMRealmPrivileges` for the meaning of permissions applied to a Realm.
 */
@interface RLMRealmPermission : RLMObject
/// The permissions for the Realm.
@property (nonatomic) RLMArray<RLMPermission *><RLMPermission> *permissions;

/// Retrieve the singleton object for the given Realm. This will return `nil`
/// for non-partial-sync Realms.
+ (nullable instancetype)objectInRealm:(RLMRealm *)realm;
@end

/**
 An object which describes class-wide permissions.

 An instance of this object is automatically created in the Realm for class in your schema,
 and should not be created manually. Call `+[RLMClassPermission objectInRealm:forClassNamed:]`
 or  `+[RLMClassPermission objectInRealm:forClass:]` to obtain the existing instance, or
 query `RLMClassPermission` as normal.
 */
@interface RLMClassPermission : RLMObject
/// The name of the class which these permissions apply to.
@property (nonatomic) NSString *name;
/// The permissions for this class.
@property (nonatomic) RLMArray<RLMPermission *><RLMPermission> *permissions;

/// Retrieve the object for the named RLMObject subclass. This will return `nil`
/// for non-partial-sync Realms.
+ (nullable instancetype)objectInRealm:(RLMRealm *)realm forClassNamed:(NSString *)className;
/// Retrieve the object for the given RLMObject subclass. This will return `nil`
/// for non-partial-sync Realms.
+ (nullable instancetype)objectInRealm:(RLMRealm *)realm forClass:(Class)cls;
@end

/**
 A description of the actual privileges which apply to a Realm.

 This is a combination of all of the privileges granted to all of the Roles which the
 current User is a member of, obtained by calling `-[RLMRealm privilegesForRealm]` on
 the Realm.

 By default, all operations are permitted, and each privilege field indicates an operation
 which may be forbidden.
 */
struct RLMRealmPrivileges {
    /// If `false`, the current User is not permitted to see the Realm at all. This can
    /// happen only if the Realm was created locally and has not yet been synchronized.
    bool read : 1;

    /// If `false`, no modifications to the Realm are permitted. Write transactions can
    /// be performed locally, but any changes made will be reverted by the server.
    /// `setPermissions` and `modifySchema` will always be `false` when this is `false`.
    bool update : 1;

    /// If `false`, no modifications to the permissions property of the RLMRealmPermissions
    /// object for are permitted. Write transactions can be performed locally, but any
    /// changes made will be reverted by the server.
    ///
    /// Note that if invalide privilege changes are made, `-[RLMRealm privilegesFor*:]`
    /// will return results reflecting those invalid changes until synchronization occurs.
    ///
    /// Even if this field is `true`, note that the user will be unable to grant
    /// privileges to a Role which they do not themselves have.
    ///
    /// Adding or removing Users from a Role is controlled by Update privileges on that
    /// Role, and not by this value.
    bool setPermissions : 1;

    /// If `false`, the user is not permitted to add new object types to the Realm or add
    /// new properties to existing objec types. Defining new RLMObject subclasses (and not
    /// excluding them from the schema with `-[RLMRealmConfiguration setObjectClasses:]`)
    /// will result in the application crashing if the object types are not first added on
    /// the server by a more privileged user.
    bool modifySchema : 1;
};

/**
 A description of the actual privileges which apply to a Class within a Realm.

 This is a combination of all of the privileges granted to all of the Roles which the
 current User is a member of, obtained by calling `-[RLMRealm privilegesForClass:]` or
 `-[RLMRealm privilegesForClassNamed:]` on the Realm.

 By default, all operations are permitted, and each privilege field indicates an operation
 which may be forbidden.
 */
struct RLMClassPrivileges {
    /// If `false`, the current User is not permitted to see objects of this type, and
    /// attempting to query this class will always return empty results.
    ///
    /// Note that Read permissions are transitive, and so it may be possible to read an
    /// object which the user does not directly have Read permissions for by following a
    /// link to it from an object they do have Read permissions for. This does not apply
    /// to any of the other permission types.
    bool read : 1;

    /// If `false`, creating new objects of this type is not permitted. Write transactions
    /// creating objects can be performed locally, but the objects will be deleted by the
    /// server when synchronization occurs.
    ///
    /// For objects with Primary Keys, it may not be locally determinable if Create or
    /// Update privileges are applicable. It may appear that you are creating a new object,
    /// but an object with that Primary Key may already exist and simply not be visible to
    /// you, in which case it is actually an Update operation.
    bool create : 1;

    /// If `false`, no modifications to objects of this type are permitted. Write
    /// transactions modifying the objects can be performed locally, but any changes made
    /// will be reverted by the server.
    ///
    /// Deleting an object is considered a modification, and is governed by this privilege.
    bool update : 1;

    /// If `false`, the User is not permitted to create new subscriptions for this class.
    /// Local queries against the objects within the Realm will work, but new
    /// subscriptions will never add objects to the Realm.
    bool subscribe : 1;

    /// If `false`, no modifications to the permissions property of the RLMClassPermissions
    /// object for this type are permitted. Write transactions can be performed locally,
    /// but any changes made will be reverted by the server.
    ///
    /// Note that if invalid privilege changes are made, `-[RLMRealm privilegesFor*:]`
    /// will return results reflecting those invalid changes until synchronization occurs.
    ///
    /// Even if this field is `true`, note that the user will be unable to grant
    /// privileges to a Role which they do not themselves have.
    bool setPermissions : 1;
};

/**
 A description of the actual privileges which apply to a specific RLMObject.

 This is a combination of all of the privileges granted to all of the Roles which the
 current User is a member of, obtained by calling `-[RLMRealm privilegesForObject:]` on
 the Realm.

 By default, all operations are permitted, and each privilege field indicates an operation
 which may be forbidden.
 */
struct RLMObjectPrivileges {
    /// If `false`, the current User is not permitted to read this object directly.
    ///
    /// Objects which cannot be read by a user will appear in a Realm due to that read
    /// permissions are transitive. All objects which a readable object links to are
    /// themselves implicitly readable. If the link to an object with `read=false` is
    /// removed, the object will be deleted from the local Realm.
    bool read : 1;

    /// If `false`, modifying the fields of this type is not permitted. Write
    /// transactions modifying the objects can be performed locally, but any changes made
    /// will be reverted by the server.
    ///
    /// Note that even if this is `true`, the user may not be able to modify the
    /// `RLMArray<RLMPermission> *` property of the object (if it exists), as that is
    /// governed by `setPermissions`.
    bool update : 1;

    /// If `false`, deleting this object is not permitted. Write transactions which delete
    /// the object can be performed locally, but the server will restore it.
    ///
    /// It is possible to have `update` but not `delete` privileges, or vice versa. For
    /// objects with primary keys, `delete` but not `update` is ill-advised, as an object
    /// can be updated by deleting and recreating it.
    bool del : 1;

    /// If `false`, modifying the privileges of this specific object is not permitted.
    ///
    /// Object-specific permissions are set by declaring a `RLMArray<RLMPermission> *`
    /// property on the `RLMObject` subclass. Modifications to this property are
    /// controlled by `setPermissions` rather than `update`.
    ///
    /// Even if this field is `true`, note that the user will be unable to grant
    /// privileges to a Role which they do not themselves have.
    bool setPermissions : 1;
};

/// :nodoc:
FOUNDATION_EXTERN id RLMPermissionForRole(RLMArray *array, id role);

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
