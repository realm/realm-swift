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

#import "RLMSyncPermission_Private.hpp"

#import "RLMArray.h"
#import "RLMObjectSchema.h"
#import "RLMRealm_Dynamic.h"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUtil.hpp"
#import "RLMResults.h"

using namespace realm;

using ConditionType = Permission::Condition::Type;

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

@interface RLMSyncPermission () {
@private
    NSString *_identity;
    NSString *_key;
    NSString *_value;
    util::Optional<Permission> _underlying;
    RLMSyncAccessLevel _accessLevel;
    NSString *_path;
    NSDate *_updatedAt;
}
@end

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

- (instancetype)initWithPermission:(Permission)permission {
    if (self = [super init]) {
        _underlying = util::make_optional<Permission>(std::move(permission));
        return self;
    }
    return nil;
}

- (NSString *)path {
    if (!_underlying) {
        REALM_ASSERT(_path);
        return _path;
    }
    return @(_underlying->path.c_str());
}

- (RLMSyncAccessLevel)accessLevel {
    if (!_underlying) {
        return _accessLevel;
    }
    return objCAccessLevelForAccessLevel(_underlying->access);
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

- (NSString *)identity {
    if (!_underlying) {
        return _identity;
    }
    if (_underlying->condition.type == ConditionType::UserId) {
        return @(_underlying->condition.user_id.c_str());
    }
    return nil;
}

- (NSString *)key {
    if (!_underlying) {
        return _key;
    }
    if (_underlying->condition.type == ConditionType::KeyValue) {
        return @(_underlying->condition.key_value.first.c_str());
    }
    return nil;
}

- (NSString *)value {
    if (!_underlying) {
        return _value;
    }
    if (_underlying->condition.type == ConditionType::KeyValue) {
        return @(_underlying->condition.key_value.second.c_str());
    }
    return nil;
}

- (NSDate *)updatedAt {
    if (!_underlying) {
        return _updatedAt;
    }
    return RLMTimestampToNSDate(_underlying->updated_at);
}

- (realm::Permission)rawPermission {
    if (_underlying) {
        return *_underlying;
    }
    auto condition = (_identity
                      ? Permission::Condition([_identity UTF8String])
                      : Permission::Condition([_key UTF8String], [_value UTF8String]));
    return Permission{
        [_path UTF8String],
        accessLevelForObjCAccessLevel(_accessLevel),
        std::move(condition)
    };
}

- (NSUInteger)hash {
    return [self.identity hash] ^ self.accessLevel;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[RLMSyncPermission class]]) {
        RLMSyncPermission *that = (RLMSyncPermission *)object;
        return (self.accessLevel == that.accessLevel
                && Permission::paths_are_equivalent([self.path UTF8String], [that.path UTF8String],
                                                    [self.identity UTF8String], [that.identity UTF8String])
                && [self.identity isEqualToString:that.identity]);
    }
    return NO;
}

- (NSString *)description {
    NSString *typeDescription = nil;
    if (self.identity) {
        typeDescription = [NSString stringWithFormat:@"identity: %@", self.identity];
    } else {
        typeDescription = [NSString stringWithFormat:@"key: %@, value: %@", self.key, self.value];
    }
    return [NSString stringWithFormat:@"<RLMSyncPermission> %@, path: %@, access level: %@",
            typeDescription,
            self.path,
            @(Permission::description_for_access_level(accessLevelForObjCAccessLevel(self.accessLevel)).c_str())];
}

@end
