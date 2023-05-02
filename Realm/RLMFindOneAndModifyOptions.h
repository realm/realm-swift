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
@protocol RLMBSON;
@class RLMSortDescriptor;

/// Options to use when executing a `findOneAndUpdate`, `findOneAndReplace`,
/// or `findOneAndDelete` command on a `RLMMongoCollection`.
@interface RLMFindOneAndModifyOptions : NSObject

/// Limits the fields to return for all matching documents.
@property (nonatomic, nullable) id<RLMBSON> projection NS_REFINED_FOR_SWIFT;

/// The order in which to return matching documents.
@property (nonatomic, nullable) id<RLMBSON> sort NS_REFINED_FOR_SWIFT
__attribute__((deprecated("Use `sorting` instead, which correctly sort more than one sort attribute", "sorting")));

/// The order in which to return matching documents.
@property (nonatomic) NSArray<id<RLMBSON>> *sorting NS_REFINED_FOR_SWIFT;


/// Whether or not to perform an upsert, default is false
/// (only available for find_one_and_replace and find_one_and_update)
@property (nonatomic) BOOL upsert;

/// When true then the new document is returned,
/// Otherwise the old document is returned (default)
/// (only available for findOneAndReplace and findOneAndUpdate)
@property (nonatomic) BOOL shouldReturnNewDocument;

/// Options to use when executing a `findOneAndUpdate`, `findOneAndReplace`,
/// or `findOneAndDelete` command on a `RLMMongoCollection`.
/// @param projection Limits the fields to return for all matching documents.
/// @param sort The order in which to return matching documents.
/// @param upsert Whether or not to perform an upsert, default is false
/// (only available for findOneAndReplace and findOneAndUpdate)
/// @param shouldReturnNewDocument When true then the new document is returned,
/// Otherwise the old document is returned (default),
/// (only available for findOneAndReplace and findOneAndUpdate)
- (instancetype)initWithProjection:(id<RLMBSON> _Nullable)projection
                              sort:(id<RLMBSON> _Nullable)sort
                            upsert:(BOOL)upsert
           shouldReturnNewDocument:(BOOL)shouldReturnNewDocument
__attribute__((deprecated("Please use `initWithProjection:sorting:upsert:shouldReturnNewDocument:`")))
     NS_SWIFT_UNAVAILABLE("Please see FindOneAndModifyOptions");

/// Options to use when executing a `findOneAndUpdate`, `findOneAndReplace`,
/// or `findOneAndDelete` command on a `RLMMongoCollection`.
/// @param projection Limits the fields to return for all matching documents.
/// @param sorting The order in which to return matching documents.
/// @param upsert Whether or not to perform an upsert, default is false
/// (only available for findOneAndReplace and findOneAndUpdate)
/// @param shouldReturnNewDocument When true then the new document is returned,
/// Otherwise the old document is returned (default),
/// (only available for findOneAndReplace and findOneAndUpdate)
- (instancetype)initWithProjection:(id<RLMBSON> _Nullable)projection
                           sorting:(NSArray<id<RLMBSON>> *)sorting
                            upsert:(BOOL)upsert
           shouldReturnNewDocument:(BOOL)shouldReturnNewDocument;
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
