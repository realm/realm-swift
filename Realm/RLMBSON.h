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
    RLMBSONTypeNull,
    RLMBSONTypeInt32,
    RLMBSONTypeInt64,
    RLMBSONTypeBool,
    RLMBSONTypeDouble,
    RLMBSONTypeString,
    RLMBSONTypeBinary,
    RLMBSONTypeTimestamp,
    RLMBSONTypeDatetime,
    RLMBSONTypeObjectId,
    RLMBSONTypeDecimal128,
    RLMBSONTypeRegularExpression,
    RLMBSONTypeMaxKey,
    RLMBSONTypeMinKey,
    RLMBSONTypeDocument,
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

- (BOOL)isEqual:(_Nullable id)other;

@end

@interface NSNumber (RLMBSON)<RLMBSON>
@end

@interface NSString (RLMBSON)<RLMBSON>
@end

@interface NSData (RLMBSON)<RLMBSON>
@end

@interface NSDateInterval (RLMBSON)<RLMBSON>
@end

@interface NSDate (RLMBSON)<RLMBSON>
@end

@interface RLMObjectId (RLMBSON)<RLMBSON>
@end

@interface RLMDecimal128 (RLMBSON)<RLMBSON>
@end

@interface NSRegularExpression (RLMBSON)<RLMBSON>
@end

@interface RLMMaxKey : NSObject
@end

@interface RLMMinKey : NSObject
@end

@interface RLMMaxKey (RLMBSON)<RLMBSON>
@end

@interface RLMMinKey (RLMBSON)<RLMBSON>
@end

@interface NSDictionary (RLMBSON)<RLMBSON>
@end

@interface NSMutableArray (RLMBSON)<RLMBSON>
@end

@interface NSArray (RLMBSON)<RLMBSON>
@end
