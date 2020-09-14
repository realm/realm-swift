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

#import "RLMMongoCollection_Private.hpp"
#import "RLMApp_Private.hpp"
#import "RLMBSON_Private.hpp"
#import "RLMObjectId_Private.hpp"
#import "RLMFindOptions_Private.hpp"
#import "RLMFindOneAndModifyOptions_Private.hpp"
#import "RLMUpdateResult_Private.hpp"
#import "RLMBSON_Private.hpp"

#import "sync/remote_mongo_database.hpp"
#import "sync/remote_mongo_collection.hpp"

@implementation RLMChangeStream {
    realm::app::WatchStream _watchStream;
    id<RLMChangeEventDelegate> _subscriber;
    __weak NSURLSession *_session;
    _Nonnull dispatch_queue_t _queue;
}

- (instancetype)initWithChangeEventSubscriber:(id<RLMChangeEventDelegate>)subscriber
                                delegateQueue:(nullable dispatch_queue_t)queue {
    if (self = [super init]) {
        _subscriber = subscriber;
        _queue = queue ?: dispatch_get_main_queue();
        return self;
    }
    return nil;
}

- (void)didCloseWithError:(NSError *)error {
    dispatch_async(_queue, ^{
        [_subscriber changeStreamDidCloseWithError:error];
    });
}

- (void)didOpen {
    dispatch_async(_queue, ^{
        [_subscriber changeStreamDidOpen:self];
    });
}

- (void)didReceiveError:(nonnull NSError *)error {
    dispatch_async(_queue, ^{
        [_subscriber changeStreamDidReceiveError:error];
    });
}

- (void)didReceiveEvent:(nonnull NSData *)event {
    std::string_view str = [[NSString alloc] initWithData:event encoding:NSUTF8StringEncoding].UTF8String;
    if (!str.empty() && _watchStream.state() == realm::app::WatchStream::State::NEED_DATA) {
        _watchStream.feed_buffer(str);
    }

    while (_watchStream.state() == realm::app::WatchStream::State::HAVE_EVENT) {
        id<RLMBSON> event = RLMConvertBsonToRLMBSON(_watchStream.next_event());
        dispatch_async(_queue, ^{
            [_subscriber changeStreamDidReceiveChangeEvent:event];
        });
    }

    if (_watchStream.state() == realm::app::WatchStream::State::HAVE_ERROR) {
        [self didReceiveError:RLMAppErrorToNSError(_watchStream.error())];
    }
}

- (void)attachURLSession:(NSURLSession *)urlSession {
    _session = urlSession;
}

- (void)close {
    [_session invalidateAndCancel];
}

@end

@implementation RLMMongoCollection

- (instancetype)initWithApp:(RLMApp *)app
                serviceName:(NSString *)serviceName
               databaseName:(NSString *)databaseName
             collectionName:(NSString *)collectionName {
    if (self = [super init]) {
        _app = app;
        _serviceName = serviceName;
        _databaseName = databaseName;
        _name = collectionName;
    }
    return self;
}

- (realm::app::RemoteMongoCollection)collection:(NSString *)name {
    return self.app._realmApp->remote_mongo_client(self.serviceName.UTF8String)
        .db(self.databaseName.UTF8String).collection(name.UTF8String);
}

- (void)findWhere:(NSDictionary<NSString *, id<RLMBSON>> *)document
          options:(RLMFindOptions *)options
       completion:(RLMMongoFindBlock)completion {
    [self collection:self.name].find(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(document)),
                                     [options _findOptions],
                                     [completion](realm::util::Optional<realm::bson::BsonArray> documents,
                                                  realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion((NSArray<NSDictionary<NSString *, id<RLMBSON>> *> *)RLMConvertBsonToRLMBSON(*documents), nil);
    });
}

- (void)findWhere:(NSDictionary<NSString *, id<RLMBSON>> *)document
       completion:(RLMMongoFindBlock)completion {
    [self findWhere:document options:[[RLMFindOptions alloc] init] completion:completion];
}

- (void)findOneDocumentWhere:(NSDictionary<NSString *, id<RLMBSON>> *)document
                     options:(RLMFindOptions *)options
                  completion:(RLMMongoFindOneBlock)completion {
    [self collection:self.name].find_one(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(document)),
                                         [options _findOptions],
                                         [completion](realm::util::Optional<realm::bson::BsonDocument> document,
                                                      realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion((NSDictionary<NSString *, id<RLMBSON>> *)RLMConvertBsonToRLMBSON(*document), nil);
    });
}

- (void)findOneDocumentWhere:(NSDictionary<NSString *, id<RLMBSON>> *)document
                  completion:(RLMMongoFindOneBlock)completion {
    [self findOneDocumentWhere:document options:[[RLMFindOptions alloc] init] completion:completion];
}

- (void)insertOneDocument:(NSDictionary<NSString *, id<RLMBSON>> *)document
               completion:(RLMMongoInsertBlock)completion {
    [self collection:self.name].insert_one(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(document)),
                                           [completion](realm::util::Optional<realm::ObjectId> objectId,
                                                        realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion([[RLMObjectId alloc] initWithValue:*objectId], nil);
    });
}

- (void)insertManyDocuments:(NSArray<NSDictionary<NSString *, id<RLMBSON>> *> *)documents
                 completion:(RLMMongoInsertManyBlock)completion {
    [self collection:self.name].insert_many(static_cast<realm::bson::BsonArray>(RLMConvertRLMBSONToBson(documents)),
                                            [completion](std::vector<realm::ObjectId> insertedIds,
                                                         realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        NSMutableArray *insertedArr = [[NSMutableArray alloc] initWithCapacity:insertedIds.size()];
        for (auto& objectId : insertedIds) {
            [insertedArr addObject:[[RLMObjectId alloc] initWithValue:objectId]];
        }
        completion(insertedArr, nil);
    });
}

- (void)aggregateWithPipeline:(NSArray<NSDictionary<NSString *, id<RLMBSON>> *> *)pipeline
                   completion:(RLMMongoFindBlock)completion {
    [self collection:self.name].aggregate(static_cast<realm::bson::BsonArray>(RLMConvertRLMBSONToBson(pipeline)),
                                          [completion](realm::util::Optional<realm::bson::BsonArray> documents,
                                                       realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion((NSArray<id> *)RLMConvertBsonToRLMBSON(*documents), nil);
    });
}

- (void)countWhere:(NSDictionary<NSString *, id<RLMBSON>> *)document
             limit:(NSInteger)limit
        completion:(RLMMongoCountBlock)completion {
    [self collection:self.name].count(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(document)),
                                      limit,
                                      [completion](uint64_t count,
                                                   realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(0, RLMAppErrorToNSError(*error));
        }
        completion(static_cast<NSInteger>(count), nil);
    });
}

- (void)countWhere:(NSDictionary<NSString *, id<RLMBSON>> *)document
        completion:(RLMMongoCountBlock)completion {
    [self countWhere:document limit:0 completion:completion];
}

- (void)deleteOneDocumentWhere:(NSDictionary<NSString *, id<RLMBSON>> *)document
                    completion:(RLMMongoCountBlock)completion {
    [self collection:self.name].delete_one(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(document)),
                                           [completion](uint64_t count,
                                                        realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(0, RLMAppErrorToNSError(*error));
        }
        completion(static_cast<NSInteger>(count), nil);
    });
}

- (void)deleteManyDocumentsWhere:(NSDictionary<NSString *, id<RLMBSON>> *)document
                      completion:(RLMMongoCountBlock)completion {
    [self collection:self.name].delete_many(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(document)),
                                            [completion](uint64_t count,
                                                         realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(0, RLMAppErrorToNSError(*error));
        }
        completion(static_cast<NSInteger>(count), nil);
    });
}

- (void)updateOneDocumentWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                updateDocument:(NSDictionary<NSString *, id<RLMBSON>> *)updateDocument
                        upsert:(BOOL)upsert
                    completion:(RLMMongoUpdateBlock)completion {
    [self collection:self.name].update_one(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(filterDocument)),                 static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(updateDocument)),
                                           upsert,
                                           [completion](realm::app::RemoteMongoCollection::RemoteUpdateResult result,
                                                        realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion([[RLMUpdateResult alloc] initWithRemoteUpdateResult:result], nil);
    });
}

- (void)updateOneDocumentWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                updateDocument:(NSDictionary<NSString *, id<RLMBSON>> *)updateDocument
                    completion:(RLMMongoUpdateBlock)completion {
    [self updateOneDocumentWhere:filterDocument
                  updateDocument:updateDocument
                          upsert:NO
                      completion:completion];
}

- (void)updateManyDocumentsWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                  updateDocument:(NSDictionary<NSString *, id<RLMBSON>> *)updateDocument
                          upsert:(BOOL)upsert
                      completion:(RLMMongoUpdateBlock)completion {
    [self collection:self.name].update_many(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(filterDocument)),                 static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(updateDocument)),
                                            upsert,
                                            [completion](realm::app::RemoteMongoCollection::RemoteUpdateResult result,
                                                         realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }
        completion([[RLMUpdateResult alloc] initWithRemoteUpdateResult:result], nil);
    });
}

- (void)updateManyDocumentsWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                  updateDocument:(NSDictionary<NSString *, id<RLMBSON>> *)updateDocument
                      completion:(RLMMongoUpdateBlock)completion {
    [self updateManyDocumentsWhere:filterDocument
                    updateDocument:updateDocument
                            upsert:NO
                        completion:completion];
}

- (void)findOneAndUpdateWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
               updateDocument:(NSDictionary<NSString *, id<RLMBSON>> *)updateDocument
                      options:(RLMFindOneAndModifyOptions *)options
                   completion:(RLMMongoFindOneBlock)completion {
    [self collection:self.name].find_one_and_update(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(filterDocument)), static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(updateDocument)),
                                                    [options _findOneAndModifyOptions],
                                                    [completion](realm::util::Optional<realm::bson::BsonDocument> document,
                                                                 realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }

        return completion((NSDictionary *)RLMConvertBsonDocumentToRLMBSON(document), nil);
    });
}

- (void)findOneAndUpdateWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
               updateDocument:(NSDictionary<NSString *, id<RLMBSON>> *)updateDocument
                   completion:(RLMMongoFindOneBlock)completion {
    [self findOneAndUpdateWhere:filterDocument
                 updateDocument:updateDocument
                        options:[[RLMFindOneAndModifyOptions alloc] init]
                     completion:completion];
}

- (void)findOneAndReplaceWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
           replacementDocument:(NSDictionary<NSString *, id<RLMBSON>> *)replacementDocument
                       options:(RLMFindOneAndModifyOptions *)options
                    completion:(RLMMongoFindOneBlock)completion {
    [self collection:self.name].find_one_and_replace(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(filterDocument)), static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(replacementDocument)),
                                                     [options _findOneAndModifyOptions],
                                                     [completion](realm::util::Optional<realm::bson::BsonDocument> document,
                                                                  realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }

        return completion((NSDictionary *)RLMConvertBsonDocumentToRLMBSON(document), nil);
    });
}

- (void)findOneAndReplaceWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
           replacementDocument:(NSDictionary<NSString *, id<RLMBSON>> *)replacementDocument
                    completion:(RLMMongoFindOneBlock)completion {
    [self findOneAndReplaceWhere:filterDocument
             replacementDocument:replacementDocument
                         options:[[RLMFindOneAndModifyOptions alloc] init]
                      completion:completion];
}

- (void)findOneAndDeleteWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                      options:(RLMFindOneAndModifyOptions *)options
                   completion:(RLMMongoDeleteBlock)completion {
    [self collection:self.name].find_one_and_delete(static_cast<realm::bson::BsonDocument>(RLMConvertRLMBSONToBson(filterDocument)),
                                                    [options _findOneAndModifyOptions],
                                                    [completion](realm::util::Optional<realm::bson::BsonDocument> document,
                                                                 realm::util::Optional<realm::app::AppError> error) {
        if (error) {
            return completion(nil, RLMAppErrorToNSError(*error));
        }

        return completion((NSDictionary *)RLMConvertBsonDocumentToRLMBSON(document), nil);
    });
}

- (void)findOneAndDeleteWhere:(NSDictionary<NSString *, id<RLMBSON>> *)filterDocument
                   completion:(RLMMongoDeleteBlock)completion {
    [self findOneAndDeleteWhere:filterDocument
                        options:[[RLMFindOneAndModifyOptions alloc] init]
                     completion:completion];
}

- (RLMChangeStream *)watchWithDelegate:(id<RLMChangeEventDelegate>)delegate
                         delegateQueue:(nullable dispatch_queue_t)delegateQueue {
    return [self watchWithMatchFilter:nil
                             idFilter:nil
                             delegate:delegate
                        delegateQueue:delegateQueue];
}

- (RLMChangeStream *)watchWithFilterIds:(NSArray<RLMObjectId *> *)filterIds
                               delegate:(id<RLMChangeEventDelegate>)delegate
                          delegateQueue:(nullable dispatch_queue_t)delegateQueue {
    return [self watchWithMatchFilter:nil
                             idFilter:filterIds
                             delegate:delegate
                        delegateQueue:delegateQueue];
}

- (RLMChangeStream *)watchWithMatchFilter:(NSDictionary<NSString *, id<RLMBSON>> *)matchFilter
                                 delegate:(id<RLMChangeEventDelegate>)delegate
                            delegateQueue:(nullable dispatch_queue_t)delegateQueue {
    return [self watchWithMatchFilter:matchFilter
                             idFilter:nil
                             delegate:delegate
                        delegateQueue:delegateQueue];
}

- (RLMChangeStream *)watchWithMatchFilter:(nullable id<RLMBSON>)matchFilter
                                 idFilter:(nullable id<RLMBSON>)idFilter
                                 delegate:(id<RLMChangeEventDelegate>)delegate
                            delegateQueue:(nullable dispatch_queue_t)queue {
    realm::bson::BsonDocument baseArgs = {
        {"database", self.databaseName.UTF8String},
        {"collection", self.name.UTF8String}
    };

    if (matchFilter) {
        baseArgs["filter"] = RLMConvertRLMBSONToBson(matchFilter);
    }
    if (idFilter) {
        baseArgs["ids"] = RLMConvertRLMBSONToBson(idFilter);
    }
    auto args = realm::bson::BsonArray {
        baseArgs
    };

    auto request = self.app._realmApp->make_streaming_request(self.app._realmApp->current_user(),
                                                              "watch",
                                                              args,
                                                              realm::util::Optional<std::string>(self.serviceName.UTF8String));
    RLMChangeStream *changeStream = [[RLMChangeStream alloc] initWithChangeEventSubscriber:delegate delegateQueue:queue];
    RLMNetworkTransport *transport = self.app.configuration.transport;
    RLMRequest *rlmRequest = [transport RLMRequestFromRequest:request];
    NSURLSession *watchSession = [transport doStreamRequest:rlmRequest
                                            eventSubscriber:changeStream];
    [changeStream attachURLSession:watchSession];
    return changeStream;
}

@end
