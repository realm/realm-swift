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

#import "RLMSyncPermissions_Private.hpp"

#import "RLMUtil.hpp"

using namespace realm;
using ConditionType = Permission::Condition::Type;

namespace {

Permission::AccessLevel accessLevelForObjcAccessLevel(RLMSyncAccessLevel level) {
    switch (level) {
        case RLMSyncAccessLevelNone:
            return Permission::AccessLevel::None;
        case RLMSyncAccessLevelRead:
            return Permission::AccessLevel::Read;
        case RLMSyncAccessLevelWrite:
            return Permission::AccessLevel::Write;
        case RLMSyncAccessLevelAdmin:
            return Permission::AccessLevel::Admin;
    }
    REALM_UNREACHABLE();
}

RLMSyncAccessLevel objCAccessLevelForAccessLevel(Permission::AccessLevel level) {
    switch (level) {
        case Permission::AccessLevel::None:
            return RLMSyncAccessLevelNone;
        case Permission::AccessLevel::Read:
            return RLMSyncAccessLevelRead;
        case Permission::AccessLevel::Write:
            return RLMSyncAccessLevelWrite;
        case Permission::AccessLevel::Admin:
            return RLMSyncAccessLevelAdmin;
    }
    REALM_UNREACHABLE();
}

NSString *descriptionForAccessLevel(RLMSyncAccessLevel level) {
    switch (level) {
        case RLMSyncAccessLevelNone:
            return @"none";
        case RLMSyncAccessLevelRead:
            return @"read";
        case RLMSyncAccessLevelWrite:
            return @"write";
        case RLMSyncAccessLevelAdmin:
            return @"admin";
    }
    REALM_UNREACHABLE();
}

// Returns true if the paths are literally equal, or if one path can be translated
// into the other path via user-ID substitution.
BOOL pathsAreEquivalent(NSString *thisPath, NSString *thatPath, NSString *thisUserID, NSString *thatUserID)
{
    if ([thisPath isEqualToString:thatPath]) {
        return YES;
    }
    NSRange tildeRange = [thisPath rangeOfString:@"~"];
    if (tildeRange.length > 0) {
        // Substitute in the user ID for the `/~/` portion of the path, if applicable.
        return [[thisPath stringByReplacingCharactersInRange:tildeRange
                                                  withString:thisUserID] isEqualToString:thatPath];
    }
    tildeRange = [thatPath rangeOfString:@"~"];
    if (tildeRange.length > 0) {
        return [[thatPath stringByReplacingCharactersInRange:tildeRange
                                                  withString:thatUserID] isEqualToString:thisPath];
    }
    return NO;
}

}

#pragma mark - Permission

@interface RLMSyncPermissionValue () {
@protected
    util::Optional<Permission> _underlying;
    RLMSyncAccessLevel _accessLevel;
    NSString *_path;
}
@end

@implementation RLMSyncPermissionValue

// Private
- (instancetype)initWithAccessLevel:(RLMSyncAccessLevel)accessLevel
                               path:(NSString *)path {
    if (self = [super init]) {
        _accessLevel = accessLevel;
        _path = path;
    }
    return self;
}

- (instancetype)initWithRealmPath:(NSString *)path
                           userID:(NSString *)userID
                      accessLevel:(RLMSyncAccessLevel)accessLevel {
    return [[RLMSyncUserIDPermissionValue alloc] initWithRealmPath:path userID:userID accessLevel:accessLevel];
}

- (instancetype)initPrivate {
    self = [super init];
    return self;
}

- (instancetype)initWithPermission:(Permission)permission {
    switch (permission.condition.type) {
        case ConditionType::UserId:
            self = [[RLMSyncUserIDPermissionValue alloc] initPrivate];
            break;
        case ConditionType::KeyValue:
            @throw RLMException(@"Key-value permissions are not yet supported in Realm Objective-C or Realm Swift.");
            break;
    }
    _underlying = util::make_optional<Permission>(std::move(permission));
    return self;
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

- (realm::Permission)rawPermission {
    REALM_TERMINATE("Subclasses must override this method.");
}

- (NSString *)key {
    return nil;
}

- (NSString *)value {
    return nil;
}

- (NSString *)userID {
    return nil;
}

@end

#pragma mark - User ID permission

@interface RLMSyncUserIDPermissionValue () {
    NSString *_userID;
}
@end

@implementation RLMSyncUserIDPermissionValue

- (instancetype)initPrivate {
    self = [super initPrivate];
    return self;
}

- (instancetype)initWithRealmPath:(NSString *)path
                           userID:(NSString *)userID
                      accessLevel:(RLMSyncAccessLevel)accessLevel {
    if (self = [super initWithAccessLevel:accessLevel path:path]) {
        _userID = userID;
    }
    return self;
}

- (NSString *)userID {
    if (!_underlying) {
        return _userID;
    }
    REALM_ASSERT(_underlying->condition.type == ConditionType::UserId);
    return @(_underlying->condition.user_id.c_str());

}

- (realm::Permission)rawPermission {
    if (_underlying) {
        return *_underlying;
    }
    return Permission{
        [_path UTF8String],
        accessLevelForObjcAccessLevel(_accessLevel),
        Permission::Condition([_userID UTF8String])
    };
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[RLMSyncUserIDPermissionValue class]]) {
        RLMSyncUserIDPermissionValue *that = (RLMSyncUserIDPermissionValue *)object;
        return (self.accessLevel == that.accessLevel
                && pathsAreEquivalent(self.path, that.path, self.userID, that.userID)
                && [self.userID isEqualToString:that.userID]);
    }
    return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RLMSyncUserIDPermissionValue> user ID: %@, path: %@, access level: %@",
            self.userID,
            self.path,
            descriptionForAccessLevel(self.accessLevel)];
}

@end
