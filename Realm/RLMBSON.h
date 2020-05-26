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

#import "RLMObjectId.h"
#import "RLMDecimal128.h"

#pragma mark RLMBSONType

/**
 Allowed BSON types.
 */
typedef NS_ENUM(NSUInteger, RLMBSONType) {
    /// BSON Null type
    RLMBSONTypeNull,
    /// BSON Int32 type
    RLMBSONTypeInt32,
    /// BSON Int64 type
    RLMBSONTypeInt64,
    /// BSON Bool type
    RLMBSONTypeBool,
    /// BSON Double type
    RLMBSONTypeDouble,
    /// BSON String type
    RLMBSONTypeString,
    /// BSON Binary type
    RLMBSONTypeBinary,
    /// BSON Timestamp type
    RLMBSONTypeTimestamp,
    /// BSON Datetime type
    RLMBSONTypeDatetime,
    /// BSON ObjectId type
    RLMBSONTypeObjectId,
    /// BSON Decimal128 type
    RLMBSONTypeDecimal128,
    /// BSON RegularExpression type
    RLMBSONTypeRegularExpression,
    /// BSON MaxKey type
    RLMBSONTypeMaxKey,
    /// BSON MinKey type
    RLMBSONTypeMinKey,
    /// BSON Document type
    RLMBSONTypeDocument,
    /// BSON Array type
    RLMBSONTypeArray
};

#pragma mark RLMBSON

/**
 Protocol representing a BSON value.
 @see RLMBSONType
 @see bsonspec.org
 */
@protocol RLMBSON <NSObject>

/**
 The BSON type for the conforming interface.
 */
@property (readonly) RLMBSONType bsonType NS_REFINED_FOR_SWIFT;

/**
 Whether or not this BSON is equal to another.

 @param other The BSON to compare to
 */
- (BOOL)isEqual:(_Nullable id)other;

@end

/**
`RLMBSON` category for `RLMBSONTypeNull`.
*/
@interface NSNull (RLMBSON)<RLMBSON>
@end

/**
 `RLMBSON` category for `RLMBSONTypeInt32`, `RLMBSONTypeInt64`, `RLMBSONTypeBool`,
 and `RLMBSONTypeDouble` conformance.
 */
@interface NSNumber (RLMBSON)<RLMBSON>
@end

/**
 `RLMBSON` category for `RLMBSONTypeString` conformance.
 */
@interface NSString (RLMBSON)<RLMBSON>
@end

/**
 `RLMBSON` category for `RLMBSONTypeBinary` conformance.
 */
@interface NSData (RLMBSON)<RLMBSON>
@end

/**
 `RLMBSON` category for  `RLMBSONTypeTimestamp` conformance.
 */
@interface NSDateInterval (RLMBSON)<RLMBSON>
@end

/**
 `RLMBSON` category for `RLMBSONTypeDatetime` conformance.
 */
@interface NSDate (RLMBSON)<RLMBSON>
@end

/**
`RLMBSON` category for `RLMBSONTypeObjectId` conformance.
*/
@interface RLMObjectId (RLMBSON)<RLMBSON>
@end

/**
`RLMBSON` category for `RLMBSONTypeDecimal128` conformance.
*/
@interface RLMDecimal128 (RLMBSON)<RLMBSON>
@end

/**
`RLMBSON` category for `RLMBSONTypeRegularExpression` conformance.
*/
@interface NSRegularExpression (RLMBSON)<RLMBSON>
@end

/// MaxKey will always be the greatest value when comparing to other BSON types
@interface RLMMaxKey : NSObject
@end

/// MinKey will always be the smallest value when comparing to other BSON types
@interface RLMMinKey : NSObject
@end

/**
`RLMBSON` category for `RLMBSONTypeMaxKey` conformance.
*/
@interface RLMMaxKey (RLMBSON)<RLMBSON>
@end

/**
`RLMBSON` category for `RLMBSONTypeMinKey` conformance.
*/
@interface RLMMinKey (RLMBSON)<RLMBSON>
@end

/**
`RLMBSON` category for `RLMBSONTypeDocument` conformance.
*/
@interface NSDictionary (RLMBSON)<RLMBSON>
@end

/**
`RLMBSON` category for `RLMBSONTypeArray` conformance.
*/
@interface NSMutableArray (RLMBSON)<RLMBSON>
@end

/**
`RLMBSON` category for `RLMBSONTypeArray` conformance.
*/
@interface NSArray (RLMBSON)<RLMBSON>
@end
