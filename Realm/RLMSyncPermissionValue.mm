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

#import "RLMSyncPermissionValue_Private.hpp"

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

}

#pragma mark - Permission

@interface RLMSyncPermissionValue () {
@private
    NSString *_userID;
    NSString *_key;
    NSString *_value;
    util::Optional<Permission> _underlying;
    RLMSyncAccessLevel _accessLevel;
    NSString *_path;
    NSDate *_updatedAt;
}
@end

@implementation RLMSyncPermissionValue

- (instancetype)initWithRealmPath:(NSString *)path
                           userID:(NSString *)userID
                      accessLevel:(RLMSyncAccessLevel)accessLevel {
    if (self = [super init]) {
        _accessLevel = accessLevel;
        _path = path;
        _userID = userID;
        if (!_userID) {
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
        _userID = nil;
        // This is correct; we internally call this key 'email' even though it doesn't have to be...
        _key = @"email";
        // FIXME: this should be done on the server, not the client.
        _value = [username lowercaseString];
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

- (NSString *)userId {
    if (!_underlying) {
        return _userID;
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
    auto condition = (_userID
                      ? Permission::Condition([_userID UTF8String])
                      : Permission::Condition([_key UTF8String], [_value UTF8String]));
    return Permission{
        [_path UTF8String],
        accessLevelForObjcAccessLevel(_accessLevel),
        std::move(condition)
    };
}

- (NSUInteger)hash {
    return [self.userId hash] ^ self.accessLevel;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[RLMSyncPermissionValue class]]) {
        RLMSyncPermissionValue *that = (RLMSyncPermissionValue *)object;
        return (self.accessLevel == that.accessLevel
                && Permission::paths_are_equivalent([self.path UTF8String], [that.path UTF8String],
                                                    [self.userId UTF8String], [that.userId UTF8String])
                && [self.userId isEqualToString:that.userId]);
    }
    return NO;
}

- (NSString *)description {
    NSString *typeDescription = nil;
    if (self.userId) {
        typeDescription = [NSString stringWithFormat:@"user ID: %@", self.userId];
    } else {
        typeDescription = [NSString stringWithFormat:@"key: %@, value: %@", self.key, self.value];
    }
    return [NSString stringWithFormat:@"<RLMSyncPermissionValue> %@, path: %@, access level: %@",
            typeDescription,
            self.path,
            @(Permission::description_for_access_level(accessLevelForObjcAccessLevel(self.accessLevel)).c_str())];
}

@end
