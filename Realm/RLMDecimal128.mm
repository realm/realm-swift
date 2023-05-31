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
// visible only to the obj-c runtime and not the linker, which means that it'll
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

- (instancetype)initWithString:(NSString *)string error:(__unused NSError **)error {
    if ((self = [self init])) {
        _value = realm::Decimal128(string.UTF8String);
    }
    return self;
}

+ (instancetype)decimalWithNumber:(NSNumber *)number {
    return [[self alloc] initWithNumber:number];
}

+ (instancetype)decimalWithNSDecimal:(NSDecimalNumber *)number {
    return [[self alloc] initWithString:number.stringValue error:nil];
}

- (id)copyWithZone:(NSZone *)zone {
    RLMDecimal128 *copy = [[self.class allocWithZone:zone] init];
    copy->_value = _value;
    return copy;
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
    return @(self.doubleValue).hash;
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
    auto str = _value.to_string();
    // If there's a decimal point, trim trailing zeroes
    auto decimal_pos = str.find('.');
    if (decimal_pos != std::string::npos) {
        // Look specifically at the range between the decimal point and the E
        // if it's present, and the rest of the string if not
        std::string_view sv = str;
        auto e_pos = str.find('E', decimal_pos);
        if (e_pos != std::string::npos) {
            sv = sv.substr(0, e_pos);
        }

        // Remove everything between the character after the final non-zero
        // and the end of the string (or the E)
        auto final_non_zero = sv.find_last_not_of('0');
        REALM_ASSERT(final_non_zero != std::string::npos);
        if (final_non_zero == decimal_pos) {
            // Also drop the decimal if there's no non-zero digits after it
            --final_non_zero;
        }
        str.erase(final_non_zero + 1, sv.size() - final_non_zero - 1);
    }
    return @(str.c_str());
}

- (BOOL)isNaN {
    return _value.is_nan();
}

- (RLMDecimal128 *)magnitude {
    auto result = realm::Decimal128(abs(self.doubleValue));
    return [[RLMDecimal128 alloc] initWithDecimal128:result];
}

- (void)negate {
    _value = realm::Decimal128(-self.doubleValue);
}

+ (RLMDecimal128 *)minimumDecimalNumber {
    return [[RLMDecimal128 alloc] initWithDecimal128:std::numeric_limits<realm::Decimal128>::lowest()];
}

+ (RLMDecimal128 *)maximumDecimalNumber {
    return [[RLMDecimal128 alloc] initWithDecimal128:std::numeric_limits<realm::Decimal128>::max()];
}

- (RLMDecimal128 *)decimalNumberByAdding:(RLMDecimal128 *)decimalNumber {
    auto rhs = RLMObjcToDecimal128(decimalNumber);
    return [[RLMDecimal128 alloc] initWithDecimal128:_value+rhs];
}

- (RLMDecimal128 *)decimalNumberByDividingBy:(RLMDecimal128 *)decimalNumber {
    auto rhs = RLMObjcToDecimal128(decimalNumber);
    return [[RLMDecimal128 alloc] initWithDecimal128:_value/rhs];
}

- (RLMDecimal128 *)decimalNumberBySubtracting:(RLMDecimal128 *)decimalNumber {
    auto rhs = RLMObjcToDecimal128(decimalNumber);
    return [[RLMDecimal128 alloc] initWithDecimal128:_value-rhs];
}

- (RLMDecimal128 *)decimalNumberByMultiplyingBy:(RLMDecimal128 *)decimalNumber {
    auto rhs = RLMObjcToDecimal128(decimalNumber);
    return [[RLMDecimal128 alloc] initWithDecimal128:_value*rhs];
}

- (BOOL)isGreaterThan:(RLMDecimal128 *)decimalNumber {
    auto rhs = RLMObjcToDecimal128(decimalNumber);
    return _value > rhs;
}

- (BOOL)isGreaterThanOrEqualTo:(RLMDecimal128 *)decimalNumber {
    auto rhs = RLMObjcToDecimal128(decimalNumber);
    return _value >= rhs;
}

- (BOOL)isLessThan:(RLMDecimal128 *)decimalNumber {
    auto rhs = RLMObjcToDecimal128(decimalNumber);
    return _value < rhs;
}

- (BOOL)isLessThanOrEqualTo:(RLMDecimal128 *)decimalNumber {
    auto rhs = RLMObjcToDecimal128(decimalNumber);
    return _value <= rhs;
}

@end
