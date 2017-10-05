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
#import "RLMSyncUtil_Private.hpp"

#import "RLMUtil.hpp"

using namespace realm;
using ConditionType = Permission::Condition::Type;

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
