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

#import "RLMAuth.h"
#import "RLMJSONModels.h"
#import "RLMNetworkClient.h"
#import "RLMSyncCredentials.h"
#import "RLMSyncManager_Private.h"
#import "RLMSyncUser.h"
#import "RLMSyncUtil.h"
#import "RLMSyncUtil_Private.hpp"
#import "RLMSyncUser_Private.hpp"

#import "sync/sync_manager.hpp"
#import "sync/sync_session.hpp"
#import "sync/sync_user.hpp"

@implementation RLMAuth {
    NSURL *_route;
}

- (instancetype) initWithRoute:(NSURL *)route {
    if (!(self = [super init]))
        return nil;

    _route = route;
    return self;
}

- (NSDictionary<NSString *, RLMSyncUser *>*)allUsers {
    NSArray *allUsers = [[RLMSyncManager sharedManager] _allUsers];
    return [NSDictionary dictionaryWithObjects:allUsers
                                       forKeys:[allUsers valueForKey:@"identity"]];
}

- (RLMSyncUser *)currentUser {
    return [[RLMSyncManager sharedManager] _currentUser];
}

- (void)logInWithCredentials:(RLMSyncCredentials *)credentials
                     timeout:(NSTimeInterval)timeout
               callbackQueue:(dispatch_queue_t)callbackQueue
                onCompletion:(RLMUserCompletionBlock)completion {
    // Prepare login network request
    NSMutableDictionary *json = [@{
        kRLMSyncProviderKey: credentials.provider
    } mutableCopy];


    if (credentials.userInfo.count) {
        // Munge user info into the JSON request.
        [json addEntriesFromDictionary:credentials.userInfo];
    }

    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        if (error) {
            return completion(nil, error);
        }

        RLMAuthResponseModel *model = [[RLMAuthResponseModel alloc] initWithDictionary:json
                                                                    requireAccessToken:YES
                                                                   requireRefreshToken:YES];
        if (!model) {
            // Malformed JSON
            return completion(nil, make_auth_error_bad_response(json));
        }

        realm::SyncUserIdentifier identity{
            ((NSString *)json[@"user_id"]).UTF8String,
            _route.absoluteString.UTF8String
        };
        auto sync_user = realm::SyncManager::shared().get_user(identity ,
                                                               [model.refreshToken.token UTF8String],
                                                               [model.accessToken.token UTF8String]);
        if (!sync_user) {
            return completion(nil, make_auth_error_client_issue());
        }
        sync_user->set_is_admin(model.refreshToken.tokenData.isAdmin);
        return completion([[RLMSyncUser alloc] initWithSyncUser:std::move(sync_user)], nil);
    };

    [RLMSyncAuthEndpoint sendRequestToServer:_route
                                        JSON:json
                                     timeout:timeout
                                  completion:^(NSError *error, NSDictionary *dictionary) {
        dispatch_async(callbackQueue, ^{
            handler(error, dictionary);
        });
    }];
}

- (void)switchUser:(NSString *)userId {

}

@end
