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

static NSString *const kRLMSyncProviderKey = @"provider";
static NSString *const kRLMSyncDataKey = @"data";
static NSString *const kRLMSyncAppIDKey = @"app_id";
static NSString *const kRLMSyncPathKey = @"path";

static RLMSyncToken accessTokenForJSON(NSDictionary *json) {
    id token = json[@"token"];
    if (![token isKindOfClass:[NSString class]]) {
        return nil;
    }
    return token;
}

static RLMSyncToken refreshTokenForJSON(NSDictionary *json) {
    id token = json[@"renew"][@"token"];
    if (![token isKindOfClass:[NSString class]]) {
        return nil;
    }
    return token;
}

static RLMSyncAccountID accountForJSON(NSDictionary *json) {
    id accountID = json[@"account"];
    if (![accountID isKindOfClass:[NSString class]]) {
        return nil;
    }
    return accountID;
}

@implementation RLMRealm (Sync)

- (void)createSessionForToken:(RLMSyncToken)token
                     provider:(RLMSyncIdentityProvider)provider
                        appID:(RLMSyncAppID)appID
                     userInfo:(NSDictionary *)userInfo
             shouldCreateUser:(BOOL)shouldCreateUser
                        error:(NSError **)error
                 onCompletion:(RLMSyncCompletionBlock)completionBlock {

    if (!self.configuration.fileURL) {
        if (error) {
            *error = [NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorBadRealmPath userInfo:nil];
        }
        return;
    }
    RLMSyncRealmPath path = self.configuration.fileURL.path;
    NSString *host = self.configuration.syncServerURL.host;

    NSMutableDictionary *json = [@{
                                   kRLMSyncProviderKey: getProviderName(provider),
                                   kRLMSyncDataKey: token,
                                   kRLMSyncAppIDKey: appID,
                                   kRLMSyncPathKey: path,
                                   } mutableCopy];
    if (shouldCreateUser) {
        // FIXME: fix this key
//        json[@"should_create"] = @(shouldCreateUser);
    }
    if (userInfo) {
        // FIXME: fix this key
//        json[@"user_info"] = userInfo;
    }

    [RLMSyncNetworkClient postSyncRequestToEndpoint:RLMSyncServerEndpointSessions
                                               host:host
                                               JSON:json
                                              error:error
                                         completion:^(NSError *error, NSDictionary *data) {
                                             if (data && !error) {
                                                 RLMSyncToken accessToken = accessTokenForJSON(data);
                                                 RLMSyncToken refreshToken = refreshTokenForJSON(data);
                                                 RLMSyncAccountID accountID = accountForJSON(data);
                                                 if (!accessToken || !refreshToken || !accountID) {
                                                     error = [NSError errorWithDomain:RLMSyncErrorDomain
                                                                                 code:RLMSyncErrorBadResponse
                                                                             userInfo:nil];
                                                     completionBlock(error, nil);
                                                 }
                                                 // Pass the token to the underlying Realm
                                                 [self passAccessTokenToRealm:accessToken];

                                                 // Prepare the session object for the newly-created session
                                                 RLMSyncSession *session = [[RLMSyncManager sharedManager] syncSessionForRealm:path];
                                                 [session configureWithHost:host account:accountID];
                                                 [session updateWithJSON:data];

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
