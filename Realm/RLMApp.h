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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class RLMSyncCredentials, RLMSyncUser, RLMRealmConfiguration, RLMFunctions, RLMAuth, RLMPush;

/**
 The `RLMApp` has the fundamental set of methods for communicating with a MongoDB
 Realm application backend.

 This protocol provides access to the `RLMAuth` for login and authentication.

 Using `serviceClient`, you can retrieve services, including the `RemoteMongoClient` for reading
 and writing on the database. To create a `RemoteMongoClient`, pass `remoteMongoClientFactory`
 into `serviceClient(fromFactory:withName)`.

 You can also use it to execute [Functions](https://docs.mongodb.com/stitch/functions/).

 Finally, its `RLMPush` object can register the current user for push notifications.

 - SeeAlso:
 `RLMAuth`,
 `RemoteMongoClient`,
 `RLMPush`,
 [Functions](https://docs.mongodb.com/stitch/functions/)
 */
@interface RLMApp<Functions: RLMFunctions*> : NSObject

/// All applications registered on this device
@property (class, nonatomic, readonly) NSDictionary<NSString*, RLMApp*> *allApps;

@property (nonatomic, readonly) RLMAuth *auth;
@property (nonatomic, readonly) Functions functions;
@property (nonatomic, readonly) RLMPush *push;

+ (instancetype)app:(NSString *)appID;

- (RLMRealmConfiguration *) configuration NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
