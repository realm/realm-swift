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
#import "RLMSyncPrivateUtil.h"
#import "RLMSyncUser.h"

static RLMSyncRealmPath pathForServerURL(NSURL *serverURL) {
    NSMutableArray<NSString *> *components = [serverURL.pathComponents mutableCopy];
    // Path must contain at least 3 components: beginning slash, 'public'/'private', and path to Realm.
    assert(components.count >= 3);
    assert([components[0] isEqualToString:@"/"]);
    BOOL isPrivate = [components[1] isEqualToString:@"private"];
    // Remove the 'public'/'private' modifier
    [components removeObjectAtIndex:1];
    if (isPrivate) {
        // Private paths are interpreted as relative; public ones as absolute.
        [components removeObjectAtIndex:0];
    }
    return [components componentsJoinedByString:@"/"];
}

/// Given a server URL (e.g. `realms://example.com:7800/private/blah`), return the corresponding auth URL (e.g.
/// `https://example.com:3001/`.
static NSURL *authURLForServerURL(NSURL *serverURL) {
    BOOL isSSL = [serverURL.scheme isEqualToString:@"realms"];
    NSString *scheme = (isSSL ? @"https" : @"http");
    // FIXME: should this be customizable eventually?
    NSInteger port = (isSSL ? 3001 : 3000);
    NSString *raw = [NSString stringWithFormat:@"%@://%@:%@", scheme, serverURL.host, @(port)];
    return [NSURL URLWithString:raw];
}

/// Return whether or not the server URL is valid (proper scheme and path structure)
static BOOL serverURLIsValid(NSURL *serverURL) {
    NSString *scheme = serverURL.scheme;
    if (![scheme isEqualToString:@"realm"] && ![scheme isEqualToString:@"realms"]) {
        return NO;
    }
    NSArray<NSString *> *pathComponents = serverURL.pathComponents;
    if (pathComponents.count < 3) {
        return NO;
    }
    NSString *accessLevel = pathComponents[1];
    if (![accessLevel isEqualToString:@"public"] && ![accessLevel isEqualToString:@"private"]) {
        return NO;
    }
    return YES;
}

@implementation RLMRealm (Sync)

- (void)openForSyncUser:(RLMSyncUser *)user
           onCompletion:(RLMSyncLoginCompletionBlock)completionBlock {
    RLMRealmConfiguration *configuration = self.configuration;

    if (!configuration.syncServerURL || !serverURLIsValid(configuration.syncServerURL)) {
        completionBlock([NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorBadRemoteRealmPath
                                        userInfo:nil], nil);
        return;
    }
    if (![RLMSyncManager sharedManager].configured) {
        completionBlock([NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorManagerNotConfigured
                                        userInfo:nil], nil);
        return;
    }

    NSString *localIdentifier = [configuration.fileURL path];
    if (!localIdentifier) {
        // Realm Sync only supports on-disk Realms.
        completionBlock([NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorBadLocalRealmPath
                                        userInfo:nil], nil);
        return;
    }

    NSURL *serverURL = configuration.syncServerURL;
    NSURL *authURL = authURLForServerURL(serverURL);
    RLMSyncRealmPath remotePath = pathForServerURL(serverURL);

    NSMutableDictionary *json = [@{
                                   kRLMSyncProviderKey: user.provider,
                                   kRLMSyncDataKey: user.credential,
                                   kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                                   kRLMSyncPathKey: remotePath,
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
            RLMSyncSession *session = [[RLMSyncManager sharedManager] syncSessionForRealm:localIdentifier];
            [session configureWithAuthServerURL:authURL
                                     remotePath:remotePath
                               sessionDataModel:model];

            // Inform the client
            completionBlock(nil, session);
        } else {
            // Something went wrong
            completionBlock(error, nil);
        }
    };

    [RLMSyncNetworkClient postSyncRequestToEndpoint:RLMSyncServerEndpointSessions
                                             server:authURL
                                               JSON:json
                                         completion:handler];
}

- (void)openWithSyncToken:(RLMSyncToken)token {
    self->_realm->refresh_sync_access_token(token.UTF8String);
}

@end
