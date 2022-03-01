////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#import "RLMObjectId_Private.hpp"

#import "RLMUtil.hpp"

#import <realm/object_id.hpp>

// Swift's obj-c bridging does not support making an obj-c defined class conform
// to Decodable, so we need a Swift-defined subclass for that. This means that
// when Realm Swift is being used, we need to produce objects of that type rather
// than our obj-c defined type. objc_runtime_visible marks the type as being
// visbile only to the obj-c runtime and not the linker, which means that it'll
// be `nil` at runtime rather than being a linker error if it's not defined, and
// valid if it happens to be defined by some other library (i.e. Realm Swift).
//
// At the point where the objects are being allocated we generally don't have
// any good way of knowing whether or not it's going to end up being used by
// Swift, so we just switch to the subclass unconditionally if the subclass
// exists. This shouldn't have any impact on obj-c code other than a small
// performance hit.
[[clang::objc_runtime_visible]]
@interface RealmSwiftObjectId : RLMObjectId
@end

@implementation RLMObjectId
- (instancetype)init {
    if ((self = [super init])) {
        if (auto cls = [RealmSwiftObjectId class]; cls && cls != self.class) {
            object_setClass(self, cls);
        }
    }
    return self;
}

- (instancetype)initWithString:(NSString *)string error:(NSError **)error {
    if ((self = [self init])) {
        const char *str = string.UTF8String;
        if (!realm::ObjectId::is_valid_str(str)) {
            if (error) {
                NSString *msg = [NSString stringWithFormat:@"Invalid Object ID string '%@': must be 24 hex digits", string];
                *error = [NSError errorWithDomain:RLMErrorDomain
                                             code:RLMErrorInvalidInput
                                         userInfo:@{NSLocalizedDescriptionKey: msg}];
            }
            return nil;
        }
        _value = realm::ObjectId(str);
    }
    return self;
}

- (instancetype)initWithTimestamp:(NSDate *)timestamp
                machineIdentifier:(int)machineIdentifier
                processIdentifier:(int)processIdentifier {
    if ((self = [self init])) {
        _value = realm::ObjectId(RLMTimestampForNSDate(timestamp), machineIdentifier, processIdentifier);
    }
    return self;
}

- (instancetype)initWithValue:(realm::ObjectId)value {
    if ((self = [self init])) {
        _value = value;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    // RLMObjectID is immutable so we don't have to actually copy
    return self;
}

+ (instancetype)objectId {
    return [[RLMObjectId alloc] initWithValue:realm::ObjectId::gen()];
}

- (BOOL)isEqual:(id)object {
    if (RLMObjectId *objectId = RLMDynamicCast<RLMObjectId>(object)) {
        return objectId->_value == _value;
    }
    return NO;
}

- (BOOL)isGreaterThan:(nullable RLMObjectId *)objectId {
    return _value > objectId.value;
}

- (BOOL)isGreaterThanOrEqualTo:(nullable RLMObjectId *)objectId {
    return _value >= objectId.value;
}

- (BOOL)isLessThan:(nullable RLMObjectId *)objectId {
    return _value < objectId.value;
}

- (BOOL)isLessThanOrEqualTo:(nullable RLMObjectId *)objectId {
    return _value <= objectId.value;
}

- (NSUInteger)hash {
    return _value.hash();
}

- (NSString *)description {
    return self.stringValue;
}

- (NSString *)stringValue {
    return @(_value.to_string().c_str());
}

- (NSDate *)timestamp {
    return RLMTimestampToNSDate(_value.get_timestamp());
}

@end
