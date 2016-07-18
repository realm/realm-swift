////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import "RLMRealm+Sync.h"

#import "RLMRealm_Private.hpp"
#import "RLMRealmConfiguration.h"
#import "RLMSyncManager_Private.h"
#import "RLMSyncNetworkClient.h"
#import "RLMSyncSession_Private.h"
#import "RLMSyncSessionDataModel.h"
#import "RLMSyncUser.h"

static NSString* getProviderName(RLMSyncIdentityProvider provider) {
    switch (provider) {
        case RLMRealmSyncIdentityProviderDebug:        return @"debug";
        case RLMRealmSyncIdentityProviderRealm:        return @"realm";
        case RLMRealmSyncIdentityProviderFacebook:     return @"facebook";
        case RLMRealmSyncIdentityProviderTwitter:      return @"twitter";
        case RLMRealmSyncIdentityProviderGoogle:       return @"google";
        case RLMRealmSyncIdentityProviderICloud:       return @"icloud";
    }
    assert(false); // Invalid identity provider
}

@implementation RLMRealm (Sync)

- (void)openForSyncUser:(RLMSyncUser *)user
           onCompletion:(RLMSyncLoginCompletionBlock)completionBlock {
    RLMRealmConfiguration *configuration = self.configuration;

    if (!configuration.syncRealmPath) {
        completionBlock([NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorBadRealmPath userInfo:nil], nil);
        return;
    }
    if (![RLMSyncManager sharedManager].configured) {
        completionBlock([NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorManagerNotConfigured userInfo:nil],
                        nil);
        return;
    }

    RLMSyncRealmPath path = configuration.syncRealmPath.absoluteString;
    NSURL *serverURL = configuration.syncServerURL;

    NSMutableDictionary *json = [@{
                                   kRLMSyncProviderKey: getProviderName(user.provider),
                                   kRLMSyncDataKey: user.credential,
                                   kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                                   kRLMSyncPathKey: path,
                                   } mutableCopy];
    if (user.userInfo) {
        // Munge user info into the JSON request.
        json[@"user_info"] = user.userInfo;
    }

    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        if (json && !error) {
            RLMSyncSessionDataModel *model = [[RLMSyncSessionDataModel alloc] initWithJSON:json];
            if (!model) {
                error = [NSError errorWithDomain:RLMSyncErrorDomain
                                            code:RLMSyncErrorBadResponse
                                        userInfo:@{kRLMSyncErrorJSONKey: json}];
                completionBlock(error, nil);
                return;
            }
            // Pass the token to the underlying Realm
            self->_realm->refresh_sync_access_token(model.accessToken.UTF8String);

            // Prepare the session object for the newly-created session
            RLMSyncSession *session = [[RLMSyncManager sharedManager] syncSessionForRealm:path];
            [session configureWithServerURL:serverURL
                           sessionDataModel:model];

            // Inform the client
            completionBlock(nil, session);
        } else {
            // Something went wrong
            completionBlock(error, nil);
        }
    };

    [RLMSyncNetworkClient postSyncRequestToEndpoint:RLMSyncServerEndpointSessions
                                             server:serverURL
                                               JSON:json
                                         completion:handler];
}

- (void)openWithSyncToken:(RLMSyncToken)token {
    self->_realm->refresh_sync_access_token(token.UTF8String);
}

@end
