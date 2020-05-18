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

#import "RLMMongoDatabase.h"

#import "RLMApp_Private.hpp"
#import "RLMMongoDatabase_Private.hpp"
#import "RLMMongoCollection_Private.hpp"
#import "sync/app.hpp"
#import "sync/remote_mongo_client.hpp"
#import "sync/remote_mongo_database.hpp"

#import <realm/util/optional.hpp>

@implementation RLMMongoDatabase

- (instancetype)initWithApp:(RLMApp *)app
                serviceName:(NSString *)serviceName
               databaseName:(NSString *)databaseName {
    self = [super init];
    if (self) {
        _app = app;
        _serviceName = serviceName;
        _databaseName = databaseName;
    }
    return self;
}

- (RLMMongoCollection *)collection:(NSString *)name {
    return [[RLMMongoCollection alloc] initWithApp:self.app
                                       serviceName:self.serviceName
                                      databaseName:self.databaseName
                                    collectionName:name];
}

@end
