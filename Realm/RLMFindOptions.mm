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

#import "RLMFindOptions.h"
#import "RLMFindOptions_Private.hpp"
#import "RLMBSON_Private.hpp"

@implementation RLMFindOptions

- (instancetype)initWithLimit:(NSNumber * _Nullable)limit
               projectionBson:(id<RLMBSON> _Nullable)projectionBson
                     sortBson:(id<RLMBSON> _Nullable)sortBson {
    self = [super init];
    if (self) {
        _limit = limit;
        _projectionBson = projectionBson;
        _sortBson = sortBson;
    }
    return self;
}

- (realm::app::RemoteMongoCollection::RemoteFindOptions)toRemoteFindOptions {
    realm::app::RemoteMongoCollection::RemoteFindOptions options;
    if (self.limit) {
        options.limit = self.limit.longValue;
    }
    if (self.projectionBson) {
        auto bson = realm::bson::BsonDocument(RLMRLMBSONToBson(self.projectionBson));
        options.projection_bson = realm::util::Optional<realm::bson::BsonDocument>(bson);
    }
    if (self.sortBson) {
        auto bson = realm::bson::BsonDocument(RLMRLMBSONToBson(self.sortBson));
        options.sort_bson = realm::util::Optional<realm::bson::BsonDocument>(bson);
    }
    
    return options;
}

@end
