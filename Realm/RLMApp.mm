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

#import "RLMApp.h"
#import "RLMAuth.h"
#import "RLMAuth_Private.h"
#import "RLMFunctions.h"
#import "RLMFunctions_Private.h"
#import "RLMRealmConfiguration.h"
#import "RLMNetworkClient.hpp"
#import "RLMSyncCredentials_Private.hpp"
#import "RLMSyncUser_Private.hpp"

#import "app.hpp"

@implementation RLMApp {
    realm::RealmApp *_app;
}

- (instancetype)initWithAppID:(NSString *)appID {
    if (!(self = [super init]))
        return nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        std::unique_ptr<realm::GenericNetworkClient> (*factory)() = []{
            return std::unique_ptr<realm::GenericNetworkClient>(new RLMAppNetworkClient);
        };
        realm::GenericNetworkClient::set_network_client_factory(factory);
    });

    _app = realm::RealmApp::app(appID.UTF8String);

    return self;
}

+ (instancetype)app:(NSString *)appID {
    return [[RLMApp alloc] initWithAppID: appID];
}

- (void)logInWithCredentials:(RLMSyncCredentials *)credentials
                     timeout:(NSTimeInterval)timeout
               callbackQueue:(dispatch_queue_t)callbackQueue
                onCompletion:(RLMUserCompletionBlock)completion {
    _app->loginWithCredential(*credentials.appCredentials,
                              timeout,
                              ^(realm::GenericNetworkError error, std::shared_ptr<realm::SyncUser> user){
        dispatch_async(callbackQueue, ^{
            completion([[RLMSyncUser alloc] initWithSyncUser: std::move(user)],
                       [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:error.code userInfo:nil]);
        });
    });
}

@end
