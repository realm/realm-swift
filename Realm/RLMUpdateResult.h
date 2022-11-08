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

#import <Realm/RLMConstants.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@class RLMObjectId;
@protocol RLMBSON;

/// The result of an `updateOne` or `updateMany` operation a `RLMMongoCollection`.
RLM_SWIFT_SENDABLE RLM_FINAL // immutable final class
@interface RLMUpdateResult : NSObject

/// The number of documents that matched the filter.
@property (nonatomic, readonly) NSUInteger matchedCount;

/// The number of documents modified.
@property (nonatomic, readonly) NSUInteger modifiedCount;

/// The identifier of the inserted document if an upsert took place and the document's primary key is an `ObjectId`.
@property (nonatomic, nullable, readonly) RLMObjectId *objectId
__attribute__((deprecated("Use documentId instead, which support all BSON types", "documentId")));

/// The identifier of the inserted document if an upsert took place.
@property (nonatomic, nullable, readonly) id<RLMBSON> documentId;

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
