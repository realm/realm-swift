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

#import "RLMUserAPIKeyProviderClient.h"
#import "RLMApp_Private.hpp"
#import "RLMUserAPIKey_Private.hpp"

@implementation RLMUserAPIKeyProviderClient

static NSError* AppErrorToNSError(const realm::app::AppError& appError) {
    return [[NSError alloc] initWithDomain:@(appError.error_code.category().name())
                                      code:appError.error_code.value()
                                  userInfo:@{
                                      @(appError.error_code.category().name()) : @(appError.error_code.message().data())
                                  }];
}

- (void)createApiKey:(NSString *)name
   completionHandler:(RLMOptionalUserAPIKeyBlock)completionHandler {
    
    self.app._realmApp.provider_client<realm::app::App::UserAPIKeyProviderClient>()
    .create_api_key(name.UTF8String, ^(Optional<realm::app::App::UserAPIKey> userAPIKey,
                                       Optional<realm::app::AppError> error) {
        
        if (error && error->error_code) {
            return completionHandler(nil, AppErrorToNSError(*error));
        }
        
        if (userAPIKey) {
            return completionHandler([[RLMUserAPIKey alloc] initWithUserAPIKey:userAPIKey.value()], nil);
        }
        
        return completionHandler(nil, nil);
    });
}

- (void)fetchApiKey:(RLMObjectId)objectId
  completionHandler:(RLMOptionalUserAPIKeyBlock)completionHandler {
    self.app._realmApp.provider_client<realm::app::App::UserAPIKeyProviderClient>()
    .fetch_api_key(nil, ^(Optional<realm::app::App::UserAPIKey> userAPIKey,
                                       Optional<realm::app::AppError> error) {
        
        if (error && error->error_code) {
            return completionHandler(nil, AppErrorToNSError(*error));
        }
        
        if (userAPIKey) {
            return completionHandler([[RLMUserAPIKey alloc] initWithUserAPIKey:userAPIKey.value()], nil);
        }
        
        return completionHandler(nil, nil);
    });
}

- (void)fetchApiKeys:(RLMUserAPIKeysBlock)completionHandler {
    self.app._realmApp.provider_client<realm::app::App::UserAPIKeyProviderClient>()
    .fetch_api_keys(^(const std::vector<realm::app::App::UserAPIKey>& userAPIKeys,
                      Optional<realm::app::AppError> error) {
        
        if (error && error->error_code) {
            return completionHandler(@[], AppErrorToNSError(*error));
        }
        
        NSMutableArray *apiKeys = [[NSMutableArray alloc] init];
        for(auto &userAPIKey : userAPIKeys) {
            [apiKeys addObject:[[RLMUserAPIKey alloc] initWithUserAPIKey: userAPIKey]];
        }
                
        return completionHandler(apiKeys, nil);
    });
}

- (void)deleteApiKey:(RLMUserAPIKey *)apiKey
   completionHandler:(RLMOptionalErrorBlock)completionHandler {
    self.app._realmApp.provider_client<realm::app::App::UserAPIKeyProviderClient>()
    .delete_api_key(apiKey._apiKey, ^(Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(AppErrorToNSError(*error));
        }
        completionHandler(nil);
    });
}

- (void)enableApiKey:(RLMUserAPIKey *)apiKey
   completionHandler:(RLMOptionalErrorBlock)completionHandler {
    self.app._realmApp.provider_client<realm::app::App::UserAPIKeyProviderClient>()
    .enable_api_key(apiKey._apiKey, ^(Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(AppErrorToNSError(*error));
        }
        completionHandler(nil);
    });
}

- (void)disableApiKey:(RLMUserAPIKey *)apiKey
    completionHandler:(RLMOptionalErrorBlock)completionHandler {
    self.app._realmApp.provider_client<realm::app::App::UserAPIKeyProviderClient>()
    .disable_api_key(apiKey._apiKey, ^(Optional<realm::app::AppError> error) {
        if (error && error->error_code) {
            return completionHandler(AppErrorToNSError(*error));
        }
        completionHandler(nil);
    });
}

@end
