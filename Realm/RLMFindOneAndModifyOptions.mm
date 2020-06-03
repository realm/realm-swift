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

@interface RLMFindOneAndModifyOptions() {
    realm::app::RemoteMongoCollection::RemoteFindOneAndModifyOptions _options;
};
@end

@implementation RLMFindOneAndModifyOptions

- (instancetype)initWithProjection:(id<RLMBSON> _Nullable)projection
                              sort:(id<RLMBSON> _Nullable)sort
                            upsert:(BOOL)upsert
                 returnNewDocument:(BOOL)returnNewDocument {
    if (self = [super init]) {
        [self setUpsert: upsert];
        [self setReturnNewDocument: returnNewDocument];
        [self setProjection:projection];
        [self setSort:sort];
    }
    return self;
}

- (realm::app::RemoteMongoCollection::RemoteFindOneAndModifyOptions)_findOneAndModifyOptions {
    return _options;
}

- (id<RLMBSON>)projection {
    if (_options.projection_bson) {
        return RLMConvertBsonToRLMBSON(*_options.projection_bson);
    }
    
    return nil;
}

- (id<RLMBSON>)sort {
    if (_options.sort_bson) {
        return RLMConvertBsonToRLMBSON(*_options.sort_bson);
    }
    
    return nil;
}

- (BOOL)upsert {
    return _options.upsert;
}

- (BOOL)returnNewDocument {
    return _options.return_new_document;
}

- (void)setProjection:(id<RLMBSON>)projection {
    if (projection) {
        auto bson = realm::bson::BsonDocument(RLMConvertRLMBSONToBson(projection));
        _options.projection_bson = realm::util::Optional<realm::bson::BsonDocument>(bson);
    }
}

- (void)setSort:(id<RLMBSON>)sort {
    if (sort) {
        auto bson = realm::bson::BsonDocument(RLMConvertRLMBSONToBson(sort));
        _options.sort_bson = realm::util::Optional<realm::bson::BsonDocument>(bson);
    }
}

- (void)setUpsert:(BOOL)upsert {
    _options.upsert = upsert;
}

- (void)setReturnNewDocument:(BOOL)returnNewDocument {
    _options.return_new_document = returnNewDocument;
}

@end
