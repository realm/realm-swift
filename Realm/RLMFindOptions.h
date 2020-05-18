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

@protocol RLMBSON;

@interface RLMFindOptions : NSObject

/// The maximum number of documents to return.
@property (nonatomic, nullable) NSNumber *limit;

/// Limits the fields to return for all matching documents.
@property (nonatomic, nullable) id<RLMBSON> projectionBson;

/// The order in which to return matching documents.
@property (nonatomic, nullable) id<RLMBSON> sortBson;

- (instancetype)initWithLimit:(NSNumber * _Nullable)limit
               projectionBson:(id<RLMBSON> _Nullable)projectionBson
                     sortBson:(id<RLMBSON> _Nullable)sortBson;

@end

NS_ASSUME_NONNULL_END
