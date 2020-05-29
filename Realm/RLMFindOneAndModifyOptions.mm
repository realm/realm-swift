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

#import "RLMFindOneAndModifyOptions.h"
#import "RLMFindOneAndModifyOptions_Private.hpp"
#import "RLMBSON_Private.hpp"

@implementation RLMFindOneAndModifyOptions

- (instancetype)initWithProjectionBson:(id<RLMBSON> _Nullable)projectionBson
                              sortBson:(id<RLMBSON> _Nullable)sortBson
                                upsert:(BOOL)upsert
                     returnNewDocument:(BOOL)returnNewDocument {
    if (self) {
        _upsert = upsert;
        _returnNewDocument = returnNewDocument;
        _projectionBson = projectionBson;
        _sortBson = sortBson;
    }
    return self;
}

- (realm::app::RemoteMongoCollection::RemoteFindOneAndModifyOptions)toRemoteFindOneAndModifyOptions {
    realm::app::RemoteMongoCollection::RemoteFindOneAndModifyOptions options;
    
    if (self.upsert) {
        options.upsert = true;
    }
    if (self.returnNewDocument) {
        options.return_new_document = true;
    }
    if (self.projectionBson) {
        auto bson = realm::bson::BsonDocument(RLMConvertRLMBSONToBson(self.projectionBson));
        options.projection_bson = realm::util::Optional<realm::bson::BsonDocument>(bson);
    }
    if (self.sortBson) {
        auto bson = realm::bson::BsonDocument(RLMConvertRLMBSONToBson(self.sortBson));
        options.sort_bson = realm::util::Optional<realm::bson::BsonDocument>(bson);
    }
    
    return options;
}

@end
