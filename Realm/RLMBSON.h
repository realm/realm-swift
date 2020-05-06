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

#ifndef RLMBson_h
#define RLMBson_h

#import "RLMObjectId.h"

///**
// The current state of the session represented by a session object.
// */
typedef NS_ENUM(NSUInteger, RLMBSONType) {
    RLMBSONTypeString,
    RLMBSONTypeInt32,
    RLMBSONTypeInt64,
    RLMBSONTypeDouble,
    RLMBSONTypeDecimal128,
    RLMBSONTypeBinary,
    RLMBSONTypeObjectId
};

@protocol RLMBSON <NSObject>

@property (readonly) RLMBSONType bsonType;

@end

@interface RLMObjectId (RLMBSON)<RLMBSON>
@end

@interface NSNumber (RLMBSON)<RLMBSON>
@end

@interface NSString (RLMBSON)<RLMBSON>
@end


#endif /* RLMBson_h */
