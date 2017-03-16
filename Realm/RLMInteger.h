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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RLMInt;

/**
 A protocol describing functionality common to nullable and non-nullable
 enhanced Realm integer properties.

 @see `RLMInteger`, `RLMNullableInteger`
 */
@protocol RLMIntegerProtocol

/**
 Increment the value of the integer. Both negative and positive values can
 be passed in.

 Prefer incrementing an integer value using this API over getting, locally
 incrementing, and setting the integer value. This API allows the value to
 be incremented in a way that guarantees that the change will not be lost,
 even if other clients are incrementing the value and pushing their changes
 to a Realm Object Server, as long as the value is not also being set using
 the `value` property.
 */
- (void)incrementValueBy:(NSInteger)delta;

/**
 Get the value of the number as a boxed `NSNumber`.
 */
- (nullable NSNumber<RLMInt> *)boxedValue;

@end

/**
 A `RLMInteger` represents an integer property on a `RLMObject` subclass
 that supports advanced Realm-specific functionality.

 `RLMInteger` properties are backed by integer columns within the underlying
 database, and are treated the same as normal non-nullable 64-bit integer
 properties. No migration is required to go change a property of `NSInteger`
 type into one of `RLMInteger` type, or vice versa.
 */
@interface RLMInteger : NSObject<RLMIntegerProtocol>

/**
 The value of the integer.

 Note that in the context of sync, setting the value of the integer may
 cause increment operations from other clients to be lost or ignored,
 depending on how any conflicts are resolved.
 */
@property (nonatomic) NSInteger value;

- (instancetype)initWithValue:(NSInteger)value;

@end

/**
 A `RLMNullableInteger` represents a nullable integer property on a `RLMObject`
 subclass that supports advanced Realm-specific functionality.

 `RLMNullableInteger` properties are backed by integer columns within the
 underlying database, and are treated the same as normal nullable 64-bit integer
 properties. No migration is required to go change a property of `NSNumber<RLMInt>`
 type into one of `RLMNullableInteger` type, or vice versa.
 */
@interface RLMNullableInteger : NSObject<RLMIntegerProtocol>

/**
 The boxed value of the integer, which can be nil.

 Note that in the context of sync, setting the value of the integer may
 cause increment operations from other clients to be lost or ignored,
 depending on how any conflicts are resolved.
 */
@property (nonatomic, nullable) NSNumber<RLMInt> *value;

- (instancetype)initWithValue:(nullable NSNumber<RLMInt> *)value;

@end

NS_ASSUME_NONNULL_END
