//
//  RLMMongoCollection.m
//  Realm
//
//  Created by Lee Maguire on 14/05/2020.
//  Copyright © 2020 Realm. All rights reserved.
//

#import "RLMMongoCollection.h"
#import "RLMMongoCollection_Private.hpp"
#import "RLMApp_Private.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMObjectId_Private.hpp"

#import "RLMFindOptions.h"
#import "RLMFindOptions_Private.hpp"

#import "RLMFindOneAndModifyOptions.h"
#import "RLMFindOneAndModifyOptions_Private.hpp"

#import "RLMBSON_Private.hpp"

#import "sync/remote_mongo_database.hpp"
#import "sync/remote_mongo_collection.hpp"

@implementation RLMMongoCollection

- (instancetype)initWithApp:(RLMApp *)app
                serviceName:(NSString *)serviceName
               databaseName:(NSString *)databaseName
               collectionName:(NSString *)collectionName {
    self = [super init];
    if (self) {
        _app = app;
        _serviceName = serviceName;
        _databaseName = serviceName;
        _name = collectionName;
    }
    return self;
}

- (realm::app::RemoteMongoCollection)collection:(NSString *)name {
    return self.app._realmApp->remote_mongo_client(self.serviceName.UTF8String)
    .db(self.databaseName.UTF8String)
    .collection(name.UTF8String);
}

- (void)find:(id<RLMBSON>)document
     options:(RLMFindOptions *)options
  completion:(RLMFindBlock)completion {
    [self collection:self.name].find(static_cast<realm::bson::BsonDocument>(RLMRLMBSONToBson(document)),
                                     [options toRemoteFindOptions],
                                     [=](realm::util::Optional<realm::bson::BsonArray> documents, realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion((NSArray<id> *)RLMBsonToRLMBSON(*documents), nil);
    });
}

- (void)insertOneDocument:(id<RLMBSON>)document
               completion:(RLMInsertBlock)completion {
    [self collection:self.name].insert_one(static_cast<realm::bson::BsonDocument>(RLMRLMBSONToBson(document)),
                                           [=](realm::util::Optional<realm::ObjectId> objectId, realm::util::Optional<realm::app::AppError> error) {

        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion([[RLMObjectId alloc] initWithValue:*objectId], nil);
    });
}

/*
void find(const bson::BsonDocument& filter_bson,
          RemoteFindOptions options,
          std::function<void(util::Optional<bson::BsonArray>, util::Optional<AppError>)> completion_block);

void find(const bson::BsonDocument& filter_bson,
          std::function<void(util::Optional<bson::BsonArray>, util::Optional<AppError>)> completion_block);

void find_one(const bson::BsonDocument& filter_bson,
              RemoteFindOptions options,
              std::function<void(util::Optional<bson::BsonDocument>, util::Optional<AppError>)> completion_block);

void find_one(const bson::BsonDocument& filter_bson,
              std::function<void(util::Optional<bson::BsonDocument>, util::Optional<AppError>)> completion_block);
*/
@end
