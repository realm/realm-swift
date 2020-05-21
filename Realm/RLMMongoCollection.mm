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

#import "RLMMongoCollection.h"
#import "RLMMongoCollection_Private.hpp"
#import "RLMApp_Private.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMObjectId_Private.hpp"

#import "RLMFindOptions.h"
#import "RLMFindOptions_Private.hpp"

#import "RLMFindOneAndModifyOptions.h"
#import "RLMFindOneAndModifyOptions_Private.hpp"

#import "RLMUpdateResult_Private.hpp"

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
    [self collection:self.name].find(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(document)),
                                     [options toRemoteFindOptions],
                                     [=](realm::util::Optional<realm::bson::BsonArray> documents, realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion((NSArray<id> *)RLMConvertBsonToRLMBSON(*documents), nil);
    });
}

- (void)find:(id<RLMBSON>)document
  completion:(RLMFindBlock)completion {
    [self find:document options:[[RLMFindOptions alloc] init] completion:completion];
}

- (void)findOneDocument:(id<RLMBSON>)document
                options:(RLMFindOptions *)options
             completion:(RLMFindOneBlock)completion {
    [self collection:self.name].find_one(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(document)),
                                         [options toRemoteFindOptions],
                                         [=](realm::util::Optional<realm::bson::BsonDocument> document, realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion((NSDictionary *)RLMConvertBsonToRLMBSON(*document), nil);
    });
}

- (void)findOneDocument:(id<RLMBSON>)document
             completion:(RLMFindOneBlock)completion {
    [self findOneDocument:document options:[[RLMFindOptions alloc] init] completion:completion];
}

- (void)insertOneDocument:(id<RLMBSON>)document
               completion:(RLMInsertBlock)completion {
    [self collection:self.name].insert_one(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(document)),
                                           [=](realm::util::Optional<realm::ObjectId> objectId, realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion([[RLMObjectId alloc] initWithValue:*objectId], nil);
    });
}

- (void)insertManyDocuments:(NSArray<id<RLMBSON>> *)documents
               completion:(RLMInsertManyBlock)completion {
    [self collection:self.name].insert_many(static_cast<realm::bson::BsonArray>(RLMConvertRLMBSONToBson(documents)),
                                           [=](std::vector<realm::ObjectId> insertedIds, realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        NSMutableArray *insertedArr = [[NSMutableArray alloc]  init];
        for (auto& objectId : insertedIds) {
            [insertedArr addObject:[[RLMObjectId alloc] initWithValue:objectId]];
        }
        completion(insertedArr, nil);
    });
}

- (void)aggregate:(NSArray<id<RLMBSON>> *)pipeline
               completion:(RLMFindBlock)completion {
    [self collection:self.name].aggregate(static_cast<realm::bson::BsonArray>(RLMConvertRLMBSONToBson(pipeline)),
                                           [=](realm::util::Optional<realm::bson::BsonArray> documents, realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion((NSArray<id> *)RLMConvertBsonToRLMBSON(*documents), nil);
    });
}

- (void)count:(id<RLMBSON>)document
        limit:(NSNumber *)limit
   completion:(RLMCountBlock)completion {
    [self collection:self.name].count(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(document)),
                                      limit.longLongValue,
                                      [=] (uint64_t count, realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(0, RLMAppErrorToNSError(*error));
        }
        completion([NSNumber numberWithUnsignedLongLong:count], nil);
    });
}

- (void)count:(id<RLMBSON>)document
   completion:(RLMCountBlock)completion {
    [self count:document limit:@0 completion:completion];
}

- (void)deleteOneDocument:(id<RLMBSON>)document
               completion:(RLMCountBlock)completion {
    [self collection:self.name].delete_one(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(document)),
                                           [=](uint64_t count, realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(0, RLMAppErrorToNSError(*error));
        }
        completion([NSNumber numberWithUnsignedLongLong:count], nil);
    });
}

- (void)deleteManyDocuments:(id<RLMBSON>)document
               completion:(RLMCountBlock)completion {
    [self collection:self.name].delete_many(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(document)),
                                            [=](uint64_t count, realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(0, RLMAppErrorToNSError(*error));
        }
        completion([NSNumber numberWithUnsignedLongLong:count], nil);
    });
}

- (void)updateOneDocument:(id<RLMBSON>)filterDocument
           updateDocument:(id<RLMBSON>)updateDocument
                   upsert:(BOOL)upsert
               completion:(RLMUpdateBlock)completion {
    [self collection:self.name].update_one(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(filterDocument)),                 static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(updateDocument)),
                                           upsert,
                                           [=](realm::app::RemoteMongoCollection::RemoteUpdateResult result,
                                               realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion([[RLMUpdateResult alloc] initWithRemoteUpdateResult:result], nil);
    });
}

- (void)updateOneDocument:(id<RLMBSON>)filterDocument
           updateDocument:(id<RLMBSON>)updateDocument
               completion:(RLMUpdateBlock)completion {
    [self updateOneDocument:filterDocument updateDocument:updateDocument upsert:NO completion:completion];
}

- (void)updateManyDocuments:(id<RLMBSON>)filterDocument
             updateDocument:(id<RLMBSON>)updateDocument
                     upsert:(BOOL)upsert
                 completion:(RLMUpdateBlock)completion {
    [self collection:self.name].update_many(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(filterDocument)),                 static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(updateDocument)),
                                            upsert,
                                            [=](realm::app::RemoteMongoCollection::RemoteUpdateResult result,
                                                realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion([[RLMUpdateResult alloc] initWithRemoteUpdateResult:result], nil);
    });
}

- (void)updateManyDocuments:(id<RLMBSON>)filterDocument
             updateDocument:(id<RLMBSON>)updateDocument
                 completion:(RLMUpdateBlock)completion {
    [self updateManyDocuments:filterDocument
               updateDocument:updateDocument
                       upsert:NO
                   completion:completion];
}

- (void)findOneAndUpdate:(id<RLMBSON>)filterDocument
             updateDocument:(id<RLMBSON>)updateDocument
                    options:(RLMFindOneAndModifyOptions *)options
                 completion:(RLMFindOneBlock)completion {
    [self collection:self.name].find_one_and_update(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(filterDocument)), static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(updateDocument)),
                                                    [options toRemoteFindOneAndModifyOptions],
                                                    [=](realm::util::Optional<realm::bson::BsonDocument> document,
                                                        realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        
        if (document) {
            return completion((NSDictionary *)RLMConvertBsonToRLMBSON(*document), nil);
        }
        // no docs where found
        completion(nil, nil);
    });
}

- (void)findOneAndUpdate:(id<RLMBSON>)filterDocument
          updateDocument:(id<RLMBSON>)updateDocument
              completion:(RLMFindOneBlock)completion {
    [self findOneAndUpdate:filterDocument
            updateDocument:updateDocument
                   options:[[RLMFindOneAndModifyOptions alloc] init]
                completion:completion];
}

- (void)findOneAndReplace:(id<RLMBSON>)filterDocument
      replacementDocument:(id<RLMBSON>)replacementDocument
                  options:(RLMFindOneAndModifyOptions *)options
               completion:(RLMFindOneBlock)completion {
    [self collection:self.name].find_one_and_replace(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(filterDocument)), static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(replacementDocument)),
                                                     [options toRemoteFindOneAndModifyOptions],
                                                     [=](realm::util::Optional<realm::bson::BsonDocument> document,
                                                         realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        
        if (document) {
            return completion((NSDictionary *)RLMConvertBsonToRLMBSON(*document), nil);
        }
        // no docs where found
        completion(nil, nil);
    });
}

- (void)findOneAndReplace:(id<RLMBSON>)filterDocument
      replacementDocument:(id<RLMBSON>)replacementDocument
               completion:(RLMFindOneBlock)completion {
    [self findOneAndReplace:filterDocument
        replacementDocument:replacementDocument
                    options:[[RLMFindOneAndModifyOptions alloc] init]
                 completion:completion];
}

- (void)findOneAndDelete:(id<RLMBSON>)filterDocument
                 options:(RLMFindOneAndModifyOptions *)options
              completion:(RLMDeleteBlock)completion {
    [self collection:self.name].find_one_and_delete(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(filterDocument)),
                                                     [options toRemoteFindOneAndModifyOptions],
                                                     [=](realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(RLMAppErrorToNSError(*error));
        }
        completion(nil);
    });
}

- (void)findOneAndDelete:(id<RLMBSON>)filterDocument
              completion:(RLMDeleteBlock)completion {
    [self findOneAndDelete:filterDocument
                   options:[[RLMFindOneAndModifyOptions alloc] init]
                completion:completion];
}

@end
