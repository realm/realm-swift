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

#import "RLMMongoClient_Private.hpp"
#import "RLMMongoDatabase_Private.hpp"
#import "RLMMongoCollection_Private.hpp"
#import "RLMApp_Private.hpp"

#import "sync/remote_mongo_client.hpp"
#import "sync/remote_mongo_database.hpp"

#import <realm/util/optional.hpp>

@implementation RLMMongoClient

- (instancetype)initWithApp:(RLMApp *)app serviceName:(NSString *)serviceName {
    if (self = [super init]) {
        _app = app;
        _name = serviceName;
    }
    return self;
}

- (RLMMongoDatabase *)databaseWithName:(NSString *)name {
    return [[RLMMongoDatabase alloc] initWithApp:self.app
                                     serviceName:self.name
                                    databaseName:name];
}

@end

@implementation RLMMongoDatabase

- (instancetype)initWithApp:(RLMApp *)app
                serviceName:(NSString *)serviceName
               databaseName:(NSString *)databaseName {
    if (self = [super init]) {
        _app = app;
        _serviceName = serviceName;
        _name = databaseName;
    }
    return self;
}

- (RLMMongoCollection *)collectionWithName:(NSString *)name {
    return [[RLMMongoCollection alloc] initWithApp:self.app
                                       serviceName:self.serviceName
                                      databaseName:self.name
                                    collectionName:name];
}

@end
