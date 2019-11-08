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

#import "RLMSyncPermission.h"

#import "RLMArray.h"
#import "RLMObjectSchema.h"
#import "RLMRealm_Dynamic.h"
#import "RLMResults.h"
#import "RLMSyncUser.h"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUtil.hpp"

using namespace realm;

static void verifyInWriteTransaction(__unsafe_unretained RLMRealm *const realm, SEL sel) {
    if (!realm) {
        @throw RLMException(@"Cannot call %@ on an unmanaged object.", NSStringFromSelector(sel));
    }
    if (!realm.inWriteTransaction) {
        @throw RLMException(@"Cannot call %@ outside of a write transaction.", NSStringFromSelector(sel));
    }
}

id RLMPermissionForRole(RLMArray *array, id role) {
    RLMResults *filtered = [array objectsWhere:@"role.name = %@", [role name]];
    RLMPermission *permission;
    for (RLMPermission *p in filtered) {
        if (permission == nil) {
            permission = p;
        }
        // If there's more than one permission for the role, merge it into the first
        // one and then delete it as otherwise revoking permissions won't actually work
        else {
            if (p.canRead && !permission.canRead) {
                permission.canRead = true;
            }
            if (p.canUpdate && !permission.canUpdate) {
                permission.canUpdate = true;
            }
            if (p.canDelete && !permission.canDelete) {
                permission.canDelete = true;
            }
            if (p.canSetPermissions && !permission.canSetPermissions) {
                permission.canSetPermissions = true;
            }
            if (p.canQuery && !permission.canQuery) {
                permission.canQuery = true;
            }
            if (p.canCreate && !permission.canCreate) {
                permission.canCreate = true;
            }
            if (p.canModifySchema && !permission.canModifySchema) {
                permission.canModifySchema = true;
            }
            [array.realm deleteObject:p];
        }
    }
    if (!permission) {
        // Use the dynamic API to create the appropriate Permission class for the array
        permission = (id)[array.realm createObject:array.objectClassName withValue:@[role]];
        [array addObject:permission];
    }
    return permission;
}

@implementation RLMPermissionRole
+ (NSString *)_realmObjectName {
    return @"__Role";
}
+ (NSString *)primaryKey {
    return @"name";
}
+ (NSArray *)requiredProperties {
    return @[@"name"];
}
+ (NSDictionary *)_realmColumnNames {
    return @{@"users": @"members"};
}
@end

@implementation RLMPermissionUser
+ (NSString *)_realmObjectName {
    return @"__User";
}
+ (NSString *)primaryKey {
    return @"identity";
}
+ (NSArray *)requiredProperties {
    return @[@"identity"];
}
+ (NSDictionary *)_realmColumnNames {
    return @{@"identity": @"id", @"role": @"role"};
}
+ (NSDictionary *)linkingObjectsProperties {
    return @{@"roles": [RLMPropertyDescriptor descriptorWithClass:RLMPermissionRole.class propertyName:@"users"]};
}

+ (RLMPermissionUser *)userInRealm:(RLMRealm *)realm withIdentity:(NSString *)identity {
    return [self createOrUpdateInRealm:realm withValue:@[identity]];
}
@end

@implementation RLMPermission
+ (NSString *)_realmObjectName {
    return @"__Permission";
}
+ (NSDictionary *)defaultPropertyValues {
    return @{@"canRead": @NO,
             @"canUpdate": @NO,
             @"canDelete": @NO,
             @"canSetPermissions": @NO,
             @"canQuery": @NO,
             @"canCreate": @NO,
             @"canModifySchema": @NO};
}

+ (RLMPermission *)permissionForRole:(RLMPermissionRole *)role inArray:(RLMArray<RLMPermission *><RLMPermission> *)array {
    verifyInWriteTransaction(array.realm, _cmd);
    auto index = [array indexOfObjectWhere:@"role = %@", role];
    if (index != NSNotFound) {
        return array[index];
    }
    RLMPermission *permission = [RLMPermission createInRealm:role.realm withValue:@[role]];
    [array addObject:permission];
    return permission;
}

+ (RLMPermission *)permissionForRoleNamed:(NSString *)roleName inArray:(RLMArray<RLMPermission *><RLMPermission> *)array {
    verifyInWriteTransaction(array.realm, _cmd);
    return RLMPermissionForRole(array, [RLMPermissionRole createOrUpdateInRealm:array.realm withValue:@{@"name": roleName}]);
}

+ (RLMPermission *)permissionForRoleNamed:(NSString *)roleName onRealm:(RLMRealm *)realm {
    verifyInWriteTransaction(realm, _cmd);
    return [self permissionForRoleNamed:roleName
                                inArray:[RLMRealmPermission objectInRealm:realm].permissions];

}

+ (RLMPermission *)permissionForRoleNamed:(NSString *)roleName onClass:(Class)cls realm:(RLMRealm *)realm {
    verifyInWriteTransaction(realm, _cmd);
    return [self permissionForRoleNamed:roleName
                                inArray:[RLMClassPermission objectInRealm:realm forClass:cls].permissions];
}

+ (RLMPermission *)permissionForRoleNamed:(NSString *)roleName onClassNamed:(NSString *)className realm:(RLMRealm *)realm {
    verifyInWriteTransaction(realm, _cmd);
    return [self permissionForRoleNamed:roleName
                                inArray:[RLMClassPermission objectInRealm:realm forClassNamed:className].permissions];
}

+ (RLMPermission *)permissionForRoleNamed:(NSString *)roleName onObject:(RLMObject *)object {
    verifyInWriteTransaction(object.realm, _cmd);
    for (RLMProperty *prop in object.objectSchema.properties) {
        if (prop.array && [prop.objectClassName isEqualToString:@"RLMPermission"]) {
            return [self permissionForRoleNamed:roleName
                                        inArray:[object valueForKey:prop.name]];
        }
    }
    @throw RLMException(@"Object %@ does not have a RLMArray<RLMPermission *> property.", object);
}
@end

@implementation RLMClassPermission
+ (NSString *)_realmObjectName {
    return @"__Class";
}
+ (NSString *)primaryKey {
    return @"name";
}
+ (NSArray *)requiredProperties {
    return @[@"name"];
}

+ (instancetype)objectInRealm:(RLMRealm *)realm forClassNamed:(NSString *)name {
    return [RLMClassPermission objectInRealm:realm forPrimaryKey:name];
}
+ (instancetype)objectInRealm:(RLMRealm *)realm forClass:(Class)cls {
    return [RLMClassPermission objectInRealm:realm forPrimaryKey:[cls _realmObjectName] ?: [cls className]];
}
@end

@interface RLMRealmPermission ()
@property (nonatomic) int pk;
@end

@implementation RLMRealmPermission
+ (NSString *)_realmObjectName {
    return @"__Realm";
}
+ (NSDictionary *)_realmColumnNames {
    return @{@"pk": @"id"};
}
+ (NSString *)primaryKey {
    return @"pk";
}

+ (instancetype)objectInRealm:(RLMRealm *)realm {
    return [RLMRealmPermission objectInRealm:realm forPrimaryKey:@0];
}
@end

#pragma mark - Permission

@implementation RLMSyncPermission

- (instancetype)initWithRealmPath:(NSString *)path
                         identity:(NSString *)identity
                      accessLevel:(RLMSyncAccessLevel)accessLevel {
    if (self = [super init]) {
        _accessLevel = accessLevel;
        _path = path;
        _identity = identity;
        if (!identity) {
            @throw RLMException(@"A permission value cannot be created without a valid user ID");
        }
        _updatedAt = [NSDate date];
    }
    return self;
}

- (instancetype)initWithRealmPath:(NSString *)path
                         username:(NSString *)username
                      accessLevel:(RLMSyncAccessLevel)accessLevel {
    if (self = [super init]) {
        _accessLevel = accessLevel;
        _path = path;
        _identity = nil;
        _key = @"email";
        _value = username;
        _updatedAt = [NSDate date];
    }
    return self;
}

+ (BOOL)accessInstanceVariablesDirectly {
    return NO;
}

- (BOOL)mayRead {
    return self.accessLevel > RLMSyncAccessLevelNone;
}

- (BOOL)mayWrite {
    return self.accessLevel > RLMSyncAccessLevelRead;
}

- (BOOL)mayManage {
    return self.accessLevel == RLMSyncAccessLevelAdmin;
}

- (NSUInteger)hash {
    return self.identity.hash ^ self.accessLevel ^ self.path.hash ^ self.key.hash ^ self.value.hash;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[RLMSyncPermission class]]) {
        return NO;
    }

    RLMSyncPermission *that = (RLMSyncPermission *)object;
    if (self.accessLevel != that.accessLevel) {
        return NO;
    }
    if (![self.path isEqualToString:that.path]) {
        return NO;
    }
    if (self.identity) {
        if (!that.identity || ![self.identity isEqualToString:that.identity]) {
            return NO;
        }
    }
    else {
        if (that.identity || ![self.key isEqualToString:that.key] || ![self.value isEqualToString:that.value]) {
            return NO;
        }
    }
    return YES;
}

- (RLMSyncPermission *)tildeExpandedSyncPermissionForUser:(RLMSyncUser *)user {
    if (![self.path hasPrefix:@"/~/"]) {
        return self;
    }
    NSString *path = [self.path stringByReplacingCharactersInRange:{1, 1} withString:user.identity];
    if (_identity) {
        return [[RLMSyncPermission alloc] initWithRealmPath:path identity:_identity accessLevel:_accessLevel];
    }
    return [[RLMSyncPermission alloc] initWithRealmPath:path username:_value accessLevel:_accessLevel];
}

- (NSString *)description {
    NSString *typeDescription = nil;
    if (self.identity) {
        typeDescription = [NSString stringWithFormat:@"identity: %@", self.identity];
    } else {
        typeDescription = [NSString stringWithFormat:@"key: %@, value: %@", self.key, self.value];
    }
    return [NSString stringWithFormat:@"<RLMSyncPermission> %@, path: %@, access level: %@",
            typeDescription, self.path, RLMSyncAccessLevelToString(self.accessLevel)];
}

NSString *RLMSyncAccessLevelToString(RLMSyncAccessLevel level) {
    switch (level) {
        case RLMSyncAccessLevelNone:  return @"none";
        case RLMSyncAccessLevelRead:  return @"read";
        case RLMSyncAccessLevelWrite: return @"write";
        case RLMSyncAccessLevelAdmin: return @"admin";
    }
    return @"unknown";
}

RLMSyncAccessLevel RLMSyncAccessLevelFromString(NSString *level) {
    if ([level isEqualToString:@"none"]) {
        return RLMSyncAccessLevelNone;
    }
    if ([level isEqualToString:@"read"]) {
        return RLMSyncAccessLevelRead;
    }
    if ([level isEqualToString:@"write"]) {
        return RLMSyncAccessLevelWrite;
    }
    if ([level isEqualToString:@"admin"]) {
        return RLMSyncAccessLevelAdmin;
    }
    @throw RLMException(@"Invalid access level %@", level);
}

@end

@implementation RLMSyncPermissionOffer
- (instancetype)initWithRealmPath:(NSString *)path
                            token:(NSString *)token
                        expiresAt:(NSDate *)expiresAt
                        createdAt:(NSDate *)createdAt
                      accessLevel:(RLMSyncAccessLevel)accessLevel {
    if (self = [super init]) {
        _realmPath = path;
        _token = token;
        _expiresAt = expiresAt;
        _createdAt = createdAt;
        _accessLevel = accessLevel;
    }
    return self;
}

+ (BOOL)accessInstanceVariablesDirectly {
    return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RLMSyncPermissionOffer: %p> path: %@, access level: %@, token: %@, createdAt: %@, expiresAt: %@",
            self, _realmPath, RLMSyncAccessLevelToString(_accessLevel),
            _token, _createdAt, _expiresAt];
}
@end
