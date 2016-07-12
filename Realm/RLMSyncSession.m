////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMSyncSession_Private.h"
#import "RLMSyncNetworkClient.h"
#import "RLMSyncManager_Private.h"

// How many seconds before the access token expires to attempt a refresh.
static NSTimeInterval const RLMRefreshExpiryBuffer = 10;

@interface RLMSyncSession ()

@property (nonatomic) NSTimer *refreshTimer;

@end

@implementation RLMSyncSession

// MARK: Public API

- (void)refreshSessionWithError:(NSError **)error completion:(RLMSyncCompletionBlock)completionBlock {
    RLMSYNC_CHECK_MANAGER(error);
    if (!self.valid) {
        if (error) {
            *error = [NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorInvalidSession userInfo:nil];
        }
        return;
    }
    if (!self.refreshToken) {
        // Ensure correct internal state
        if (error) {
            *error = [NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorInvalidSession userInfo:nil];
        }
        self.valid = NO;
        return;
    }

    RLMSyncCompletionBlock block = completionBlock ?: ^(__attribute__((unused)) NSError *error,
                                                        __attribute__((unused)) NSDictionary *json){ };

    NSDictionary *json = @{
                           kRLMSyncDataKey: self.refreshToken,
                           kRLMSyncRealmIDKey: self.realmID,
                           kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                           };

    __weak typeof(self) weakSelf = self;
    [RLMSyncNetworkClient postSyncRequestToEndpoint:RLMSyncServerEndpointRefresh
                                               host:self.host
                                               JSON:json
                                              error:error
                                         completion:^(NSError *error, NSDictionary *json) {
                                             // Extract and save the updated tokens.
                                             typeof(self) __self = weakSelf;
                                             if (!__self) {
                                                 return;
                                             }
                                             if (error) {
                                                 // Bad response
                                                 __self.valid = NO;
                                                 block(error, nil);
                                                 return;
                                             }
                                             RLMSyncToken accessToken = RLM_accessTokenForJSON(json);
                                             RLMSyncToken refreshToken = RLM_refreshTokenForJSON(json);
                                             NSTimeInterval expiry = RLM_accessExpirationForJSON(json);
                                             if (!accessToken || !refreshToken) {
                                                 error = [NSError errorWithDomain:RLMSyncErrorDomain
                                                                             code:RLMSyncErrorBadResponse
                                                                         userInfo:nil];
                                                 block(error, nil);
                                                 return;
                                             }
                                             [__self updateWithAccessToken:accessToken
                                                                expiration:expiry
                                                              refreshToken:refreshToken];
                                             block(error, json);
                                         }];
}

- (void)destroySessionWithError:(NSError **)error completion:(RLMSyncCompletionBlock)completionBlock {
    RLMSYNC_CHECK_MANAGER(error);
    if (!self.valid) {
        if (error) {
            *error = [NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorInvalidSession userInfo:nil];
        }
        return;
    }

    // TODO
    NSAssert(NO, @"Implement me!");
}

- (void)addLoginForProvider:(RLMSyncIdentityProvider)provider
                 credential:(RLMSyncCredential)credential
                   userInfo:(nullable NSDictionary *)userInfo
                      error:(NSError **)error
               onCompletion:(RLMSyncCompletionBlock)completionBlock {
    RLMSYNC_CHECK_MANAGER(error);
    if (!self.valid) {
        if (error) {
            *error = [NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorInvalidSession userInfo:nil];
        }
        return;
    }

    // TODO
    NSAssert(NO, @"Implement me!");
}

// MARK: Other

- (void)updateWithAccessToken:(RLMSyncToken)accessToken
                   expiration:(NSTimeInterval)expiration
                 refreshToken:(RLMSyncToken)refreshToken {
    self.accessToken = accessToken;
    self.refreshToken = refreshToken;

    // Schedule next refresh
    NSTimeInterval timeToRefresh = expiration - [NSDate date].timeIntervalSince1970 - RLMRefreshExpiryBuffer;
    if (timeToRefresh < 0) {
        // TODO: signal an error of some sort
    }
    if (self.refreshTimer) {
        [self.refreshTimer invalidate];
    }
    NSTimer *timer = [NSTimer timerWithTimeInterval:timeToRefresh
                                             target:self
                                           selector:@selector(refreshTimerFired:)
                                           userInfo:nil
                                            repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)refreshTimerFired:(__attribute__((unused)) NSTimer *)timer {
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;

    if (!self.valid) {
        return;
    }

    // Force a refresh
    [self refreshSessionWithError:nil completion:nil];
}

- (void)configureWithHost:(NSString *)host
                  account:(RLMSyncAccountID)account
                  realmID:(NSString *)realmID
                 realmURL:(NSString *)realmURL {
    self.host = host;
    self.account = account;
    self.remoteURL = realmURL;
    self.realmID = realmID;
    self.valid = YES;
}

- (instancetype)init {
    if (self = [super init]) {
        self.valid = NO;
    }
    return self;
}

@end
