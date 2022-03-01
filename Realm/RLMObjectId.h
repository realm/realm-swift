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
 A 12-byte (probably) unique object identifier.

 ObjectIds are similar to a GUID or a UUID, and can be used to uniquely identify
 objects without a centralized ID generator. An ObjectID consists of:

 1. A 4 byte timestamp measuring the creation time of the ObjectId in seconds
    since the Unix epoch.
 2. A 5 byte random value
 3. A 3 byte counter, initialized to a random value.

 ObjectIds are intended to be fast to generate. Sorting by an ObjectId field
 will typically result in the objects being sorted in creation order.
 */
@interface RLMObjectId : NSObject <NSCopying>
/// Creates a new randomly-initialized ObjectId.
+ (nonnull instancetype)objectId NS_SWIFT_NAME(generate());

/// Creates a new zero-initialized ObjectId.
- (instancetype)init;

/// Creates a new ObjectId from the given 24-byte hexadecimal string.
///
/// Returns `nil` and sets `error` if the string is not 24 characters long or
/// contains any characters other than 0-9a-fA-F.
///
/// @param string The string to parse.
- (nullable instancetype)initWithString:(NSString *)string
                                  error:(NSError **)error;

/// Creates a new ObjectId using the given date, machine identifier, process identifier.
///
/// @param timestamp A timestamp as NSDate.
/// @param machineIdentifier The machine identifier.
/// @param processIdentifier The process identifier.
- (instancetype)initWithTimestamp:(NSDate *)timestamp
                machineIdentifier:(int)machineIdentifier
                processIdentifier:(int)processIdentifier;

/// Comparision operator to check if the right hand side is greater than the current value.
- (BOOL)isGreaterThan:(nullable RLMObjectId *)objectId;
/// Comparision operator to check if the right hand side is greater than or equal to the current value.
- (BOOL)isGreaterThanOrEqualTo:(nullable RLMObjectId *)objectId;
/// Comparision operator to check if the right hand side is less than the current value.
- (BOOL)isLessThan:(nullable RLMObjectId *)objectId;
/// Comparision operator to check if the right hand side is less than or equal to the current value.
- (BOOL)isLessThanOrEqualTo:(nullable RLMObjectId *)objectId;

/// Get the ObjectId as a 24-character hexadecimal string.
@property (nonatomic, readonly) NSString *stringValue;
/// Get the timestamp for the RLMObjectId
@property (nonatomic, readonly) NSDate *timestamp;

@end

NS_ASSUME_NONNULL_END
