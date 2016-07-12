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

- (void)createSessionForToken:(RLMSyncToken)token
                     provider:(RLMSyncIdentityProvider)provider
                     userInfo:(NSDictionary *)userInfo
                        error:(NSError **)error
                 onCompletion:(RLMSyncCompletionBlock)completionBlock {

    if (!self.configuration.fileURL) {
        if (error) {
            *error = [NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorBadRealmPath userInfo:nil];
        }
        return;
    }
    RLMSYNC_CHECK_MANAGER(error);

    RLMSyncRealmPath path = self.configuration.fileURL.path;
    NSString *host = self.configuration.syncServerURL.host;

    NSMutableDictionary *json = [@{
                                   kRLMSyncProviderKey: getProviderName(provider),
                                   kRLMSyncDataKey: token,
                                   kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                                   kRLMSyncPathKey: path,
                                   } mutableCopy];
    if (userInfo) {
        // Munge user info into the JSON request.
        json[@"user_info"] = userInfo;
    }

    [RLMSyncNetworkClient postSyncRequestToEndpoint:RLMSyncServerEndpointSessions
                                               host:host
                                               JSON:json
                                              error:error
                                         completion:^(NSError *error, NSDictionary *data) {
                                             if (data && !error) {
                                                 RLMSyncToken accessToken = RLM_accessTokenForJSON(data);
                                                 RLMSyncToken refreshToken = RLM_refreshTokenForJSON(data);
                                                 RLMSyncAccountID accountID = RLM_accountForJSON(data);
                                                 NSString *realmID = RLM_realmIDForJSON(data);
                                                 NSString *remoteRealmURL = RLM_realmURLForJSON(data);
                                                 NSTimeInterval expiry = RLM_accessExpirationForJSON(data);
                                                 if (!accessToken
                                                     || !refreshToken
                                                     || !accountID
                                                     || !realmID
                                                     || !remoteRealmURL) {
                                                     error = [NSError errorWithDomain:RLMSyncErrorDomain
                                                                                 code:RLMSyncErrorBadResponse
                                                                             userInfo:nil];
                                                     completionBlock(error, nil);
                                                 }
                                                 // Pass the token to the underlying Realm
                                                 [self passAccessTokenToRealm:accessToken];

                                                 // Prepare the session object for the newly-created session
                                                 RLMSyncSession *session = [[RLMSyncManager sharedManager] syncSessionForRealm:path];
                                                 [session configureWithHost:host
                                                                    account:accountID
                                                                    realmID:realmID
                                                                   realmURL:remoteRealmURL];
                                                 [session updateWithAccessToken:accessToken
                                                                     expiration:expiry
                                                                   refreshToken:refreshToken];

                                                 // Inform the client
                                                 completionBlock(nil, data);
                                             } else {
                                                 // Something went wrong
                                                 completionBlock(error, nil);
                                             }
                                         }];
}

// MARK: Helpers

- (void)passAccessTokenToRealm:(RLMSyncToken)token {
    realm::SharedRealm shared_realm = self->_realm;
    std::string access_token{token.UTF8String};
    shared_realm->refresh_sync_access_token(std::move(access_token));
}

@end
