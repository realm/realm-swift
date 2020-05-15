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

#import "sync/remote_mongo_database.hpp"
#import "sync/remote_mongo_collection.hpp"

@implementation RLMMongoCollection

- (instancetype)initWithApp:(RLMApp *)app serviceName:(NSString *)serviceName databaseName:(NSString *)databaseName {
    self = [super init];
    if (self) {
        _app = app;
        _serviceName = serviceName;
        _databaseName = serviceName;
    }
    return self;
}

- (realm::app::RemoteMongoCollection)collection:(NSString *)name {
    return self.app._realmApp->remote_mongo_client(self.serviceName.UTF8String)
    .db(self.databaseName.UTF8String)
    .collection(name.UTF8String);
}

- (void)insertOneDocument:(id<RLMBSON>)document completion:(RLMInsertBlock)completion {
    [self collection:@"Person"].insert_one(static_cast<realm::bson::BsonDocument>(RLMRLMBSONToBson(document)),
                                           [=](realm::util::Optional<realm::ObjectId> objectId, realm::util::Optional<realm::app::AppError> error) {

        completion([[RLMObjectId alloc] initWithValue:*objectId], RLMAppErrorToNSError(*error));
    });
}

@end
