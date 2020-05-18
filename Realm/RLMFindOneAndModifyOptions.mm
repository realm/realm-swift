//
//  RLMFindOneAndModifyOptions.m
//  Realm
//
//  Created by Lee Maguire on 15/05/2020.
//  Copyright © 2020 Realm. All rights reserved.
//

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

- (realm::app::RemoteMongoCollection::RemoteFindOneAndModifyOptions)RLMFindOneAndModifyOptionsToRemoteFindOneAndModifyOptions {
    realm::app::RemoteMongoCollection::RemoteFindOneAndModifyOptions options;
    
    if (self.upsert) {
        options.upsert = true;
    }
    if (self.returnNewDocument) {
        options.return_new_document = true;
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
