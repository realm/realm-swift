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

#import <Realm/RLMMongoClient.h>
#import "sync/remote_mongo_client.hpp"

NS_ASSUME_NONNULL_BEGIN

@class RLMApp;

// Acts as a middleman and processes events with WatchStream
@interface RLMWatchStream: NSObject <RLMEventDelegate>
- (instancetype)initWithChangeEventSubscriber:(id<RLMChangeEventDelegate>)subscriber NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface RLMMongoCollection ()

@property (nonatomic, strong) RLMApp *app;
@property (nonatomic, strong) NSString *serviceName;
@property (nonatomic, strong) NSString *databaseName;
@property (nonatomic, strong) NSMutableArray<NSURLSession *> *watchSessions;

- (instancetype)initWithApp:(RLMApp *)app
                serviceName:(NSString *)serviceName
               databaseName:(NSString *)databaseName
             collectionName:(NSString *)collectionName;

@end

NS_ASSUME_NONNULL_END
