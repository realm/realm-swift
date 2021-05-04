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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A 128-bit IEEE 754-2008 decimal floating point number.

 This type is similar to Swift's built-in Decimal type, but allocates bits
 differently, resulting in a different representable range. (NS)Decimal stores a
 significand of up to 38 digits long and an exponent from -128 to 127, while
 this type stores up to 34 digits of significand and an exponent from -6143 to
 6144.
 */
@interface RLMDecimal128 : NSObject
/// Creates a new zero-initialized decimal128.
- (instancetype)init;

/// Converts the given value to a RLMDecimal128.
///
/// The following types can be converted to RLMDecimal128:
/// - NSNumber
/// - NSString
/// - NSDecimalNumber
///
/// Passing a value with a type not in this list is a fatal error. Passing a
/// string which cannot be parsed as a valid Decimal128 is a fatal error.
- (instancetype)initWithValue:(id)value;

/// Converts the given number to a RLMDecimal128.
- (instancetype)initWithNumber:(NSNumber *)number;

/// Parses the given string to a RLMDecimal128.
///
/// Returns a decimal where `isNaN` is `YES` if the string cannot be parsed as a decimal. `error` is never set
/// and this will never actually return `nil`.
- (nullable instancetype)initWithString:(NSString *)string error:(NSError **)error;

/// Converts the given number to a RLMDecimal128.
+ (instancetype)decimalWithNumber:(NSNumber *)number;

/// The minimum value for RLMDecimal128.
@property (class, readonly, copy) RLMDecimal128 *minimumDecimalNumber NS_REFINED_FOR_SWIFT;

/// The maximum value for RLMDecimal128.
@property (class, readonly, copy) RLMDecimal128 *maximumDecimalNumber NS_REFINED_FOR_SWIFT;

/// Convert this value to a double. This is a lossy conversion.
@property (nonatomic, readonly) double doubleValue;

/// Convert this value to a NSDecimal. This may be a lossy conversion.
@property (nonatomic, readonly) NSDecimal decimalValue;

/// Convert this value to a string.
@property (nonatomic, readonly) NSString *stringValue;

/// Gets if this Decimal128 represents a NaN value.
@property (nonatomic, readonly) BOOL isNaN;

/// The magnitude of this RLMDecimal128.
@property (nonatomic, readonly) RLMDecimal128 *magnitude NS_REFINED_FOR_SWIFT;

/// Replaces this RLMDecimal128 value with its additive inverse.
- (void)negate;

/// Adds the right hand side to the current value and returns the result.
- (RLMDecimal128 *)decimalNumberByAdding:(RLMDecimal128 *)decimalNumber;

/// Divides the right hand side to the current value and returns the result.
- (RLMDecimal128 *)decimalNumberByDividingBy:(RLMDecimal128 *)decimalNumber;

/// Subtracts the right hand side to the current value and returns the result.
- (RLMDecimal128 *)decimalNumberBySubtracting:(RLMDecimal128 *)decimalNumber;

/// Multiply the right hand side to the current value and returns the result.
- (RLMDecimal128 *)decimalNumberByMultiplyingBy:(RLMDecimal128 *)decimalNumber;

/// Comparision operator to check if the right hand side is greater than the current value.
- (BOOL)isGreaterThan:(nullable RLMDecimal128 *)decimalNumber;

/// Comparision operator to check if the right hand side is greater than or equal to the current value.
- (BOOL)isGreaterThanOrEqualTo:(nullable RLMDecimal128 *)decimalNumber;

/// Comparision operator to check if the right hand side is less than the current value.
- (BOOL)isLessThan:(nullable RLMDecimal128 *)decimalNumber;

/// Comparision operator to check if the right hand side is less than or equal to the current value.
- (BOOL)isLessThanOrEqualTo:(nullable RLMDecimal128 *)decimalNumber;

@end

NS_ASSUME_NONNULL_END
