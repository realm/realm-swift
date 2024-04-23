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

#import "RLMAPIKeyAuth.h"
#import "RLMProviderClient_Private.hpp"

#import "RLMApp_Private.hpp"
#import "RLMUserAPIKey_Private.hpp"
#import "RLMObjectId_Private.hpp"

using namespace realm::app;

@implementation RLMAPIKeyAuth

- (App::UserAPIKeyProviderClient)client {
    return self.app._realmApp->provider_client<App::UserAPIKeyProviderClient>();
}

- (std::shared_ptr<realm::app::User>)currentUser {
    return self.app._realmApp->current_user();
}

static realm::util::UniqueFunction<void(App::UserAPIKey, std::optional<AppError>)>
wrapCompletion(RLMOptionalUserAPIKeyBlock completion) {
    return [completion](App::UserAPIKey userAPIKey, std::optional<AppError> error) {
        if (error) {
            return completion(nil, makeError(*error));
        }
        return completion([[RLMUserAPIKey alloc] initWithUserAPIKey:userAPIKey], nil);
    };
}

- (void)createAPIKeyWithName:(NSString *)name
                  completion:(RLMOptionalUserAPIKeyBlock)completion {
    self.client.create_api_key(name.UTF8String, self.currentUser, wrapCompletion(completion));
}

- (void)fetchAPIKey:(RLMObjectId *)objectId
         completion:(RLMOptionalUserAPIKeyBlock)completion {
    self.client.fetch_api_key(objectId.value, self.currentUser, wrapCompletion(completion));
}

- (void)fetchAPIKeysWithCompletion:(RLMUserAPIKeysBlock)completion {
    self.client.fetch_api_keys(self.currentUser,
                               ^(const std::vector<App::UserAPIKey>& userAPIKeys,
                                 std::optional<AppError> error) {
        if (error) {
            return completion(nil, makeError(*error));
        }
        
        NSMutableArray *apiKeys = [[NSMutableArray alloc] init];
        for (auto &userAPIKey : userAPIKeys) {
            [apiKeys addObject:[[RLMUserAPIKey alloc] initWithUserAPIKey:userAPIKey]];
        }
        
        return completion(apiKeys, nil);
    });
}

- (void)deleteAPIKey:(RLMObjectId *)objectId
          completion:(RLMAPIKeyAuthOptionalErrorBlock)completion {
    self.client.delete_api_key(objectId.value, self.currentUser, RLMWrapCompletion(completion));
}

- (void)enableAPIKey:(RLMObjectId *)objectId
          completion:(RLMAPIKeyAuthOptionalErrorBlock)completion {
    self.client.enable_api_key(objectId.value, self.currentUser, RLMWrapCompletion(completion));
}

- (void)disableAPIKey:(RLMObjectId *)objectId
           completion:(RLMAPIKeyAuthOptionalErrorBlock)completion {
    self.client.disable_api_key(objectId.value, self.currentUser, RLMWrapCompletion(completion));
}

@end
