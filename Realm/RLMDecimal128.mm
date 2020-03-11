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

#import "RLMDecimal128_Private.hpp"

#import "RLMUtil.hpp"

#import <realm/decimal128.hpp>

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
@interface RealmSwiftDecimal128 : RLMDecimal128
@end

@implementation RLMDecimal128 {
    realm::Decimal128 _value;
}

- (instancetype)init {
    if (self = [super init]) {
        if (auto cls = [RealmSwiftDecimal128 class]; cls && cls != self.class) {
            object_setClass(self, cls);
        }
    }
     return self;
}

- (instancetype)initWithDecimal128:(realm::Decimal128)value {
    if ((self = [self init])) {
        _value = value;
    }
    return self;
}

- (instancetype)initWithValue:(id)value {
    if ((self = [self init])) {
        _value = RLMObjcToDecimal128(value);
    }
    return self;
}

- (instancetype)initWithNumber:(NSNumber *)number {
    if ((self = [self init])) {
        _value = RLMObjcToDecimal128(number);
    }
    return self;
}

- (instancetype)initWithString:(NSString *)string error:(NSError **)error {
    if ((self = [self init])) {
        try {
            _value = realm::Decimal128(string.UTF8String);
        }
        catch (std::exception const& e) {
            if (error) {
                *error = RLMMakeError(RLMErrorInvalidInput, e);
            }
            return nil;
        }
    }
    return self;
}

+ (instancetype)decimalWithNumber:(NSNumber *)number {
    return [[self alloc] initWithNumber:number];
}

+ (instancetype)decimalWithNSDecimal:(NSDecimalNumber *)number {
    return [[self alloc] initWithString:number.stringValue error:nil];
}

- (realm::Decimal128)decimal128Value {
    return _value;
}

- (BOOL)isEqual:(id)object {
    if (auto decimal128 = RLMDynamicCast<RLMDecimal128>(object)) {
        return _value == decimal128->_value;
    }
    if (auto number = RLMDynamicCast<NSNumber>(object)) {
        return _value == RLMObjcToDecimal128(number);
    }
    return NO;
}

- (NSUInteger)hash {
    return std::hash<realm::Decimal128>()(_value);
}

- (NSString *)description {
    return self.stringValue;
}

- (NSComparisonResult)compare:(RLMDecimal128 *)other {
    return static_cast<NSComparisonResult>(_value.compare(other->_value));
}

- (double)doubleValue {
    return [NSDecimalNumber decimalNumberWithDecimal:self.decimalValue].doubleValue;
}

- (NSDecimal)decimalValue {
    NSDecimal ret;
    [[[NSScanner alloc] initWithString:@(_value.to_string().c_str())] scanDecimal:&ret];
    return ret;
}

- (NSString *)stringValue {
    return @(_value.to_string().c_str());
}

- (BOOL)isNaN {
    return _value.is_nan();
}
@end
