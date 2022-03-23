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

#import "RLMFindOneAndModifyOptions_Private.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMCollection.h"

@interface RLMFindOneAndModifyOptions() {
    realm::app::MongoCollection::FindOneAndModifyOptions _options;
};
@end

@implementation RLMFindOneAndModifyOptions

- (instancetype)initWithProjection:(id<RLMBSON> _Nullable)projection
                              sort:(id<RLMBSON> _Nullable)sort
                            upsert:(BOOL)upsert
           shouldReturnNewDocument:(BOOL)shouldReturnNewDocument {
    if (self = [super init]) {
        self.upsert = upsert;
        self.shouldReturnNewDocument = shouldReturnNewDocument;
        self.projection = projection;
        self.sort = sort;
    }
    return self;
}

- (instancetype)initWithProjection:(id<RLMBSON> _Nullable)projection
                   sortDescriptors:(NSArray<RLMSortDescriptor *> *)sortDescriptors
                            upsert:(BOOL)upsert
           shouldReturnNewDocument:(BOOL)shouldReturnNewDocument {
    if (self = [super init]) {
        self.upsert = upsert;
        self.shouldReturnNewDocument = shouldReturnNewDocument;
        self.projection = projection;
        self.sortDescriptors = sortDescriptors;
    }
    return self;
}

- (realm::app::MongoCollection::FindOneAndModifyOptions)_findOneAndModifyOptions {
    return _options;
}

- (id<RLMBSON>)projection {
    return RLMConvertBsonDocumentToRLMBSON(_options.projection_bson);
}

- (id<RLMBSON>)sort {
    return RLMConvertBsonDocumentToRLMBSON(_options.sort_bson);
}

- (NSArray<RLMSortDescriptor *> *)sortDescriptors {
    NSMutableArray<RLMSortDescriptor *> *sortDescriptors = [[NSMutableArray alloc] init];
    for (auto it = _options.sort_bson->begin(); it != _options.sort_bson->end();) {
        auto entry = *it;
        RLMSortDescriptor *sortDescriptor = [RLMSortDescriptor sortDescriptorWithKeyPath:@(entry.first.c_str()) ascending:[(NSNumber *)RLMConvertBsonToRLMBSON(entry.second) boolValue]];
        [sortDescriptors addObject:sortDescriptor];
        it++;
    }

    return sortDescriptors;
}

- (BOOL)upsert {
    return _options.upsert;
}

- (BOOL)shouldReturnNewDocument {
    return _options.return_new_document;
}

- (void)setProjection:(id<RLMBSON>)projection {
    if (projection) {
        auto bson = realm::bson::BsonDocument(RLMConvertRLMBSONToBson(projection));
        _options.projection_bson = std::optional<realm::bson::BsonDocument>(bson);
    } else {
        _options.projection_bson = realm::util::none;
    }
}

- (void)setSort:(id<RLMBSON>)sort {
    if (sort) {
        auto bson = realm::bson::BsonDocument(RLMConvertRLMBSONToBson(sort));
        _options.sort_bson = std::optional<realm::bson::BsonDocument>(bson);
    } else {
        _options.sort_bson = realm::util::none;
    }
}

- (void)setSortDescriptors:(NSArray<RLMSortDescriptor *> *)sortDescriptors {
    auto bsonDocuments = realm::bson::BsonDocument{};
    for (RLMSortDescriptor *sortDescriptor in sortDescriptors) {
        NSNumber *ascending = sortDescriptor.ascending == TRUE ? [[NSNumber alloc]initWithInteger:1] :  [[NSNumber alloc]initWithInteger:-1];
        bsonDocuments[sortDescriptor.keyPath.UTF8String] = RLMConvertRLMBSONToBson(ascending);
    }
    _options.sort_bson = bsonDocuments;
}

- (void)setUpsert:(BOOL)upsert {
    _options.upsert = upsert;
}

- (void)setShouldReturnNewDocument:(BOOL)returnNewDocument {
    _options.return_new_document = returnNewDocument;
}

@end
