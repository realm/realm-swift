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

#import "RLMSyncSession_Private.hpp"

#import "realm_coordinator.hpp"
#import "RLMUtil.hpp"

#import "RLMSyncNetworkClient.h"
#import "RLMSyncManager_Private.h"
#import "RLMSyncRefreshDataModel.h"
#import "RLMSyncSessionDataModel.h"

// How many seconds before the access token expires to attempt a refresh.
static NSTimeInterval const RLMRefreshExpiryBuffer = 10;

@interface RLMSyncSession ()

@property (nonatomic) NSTimer *refreshTimer;

@property (nonatomic, readwrite) RLMSyncAccountID account;
@property (nonatomic, readwrite) BOOL valid;
@property (nonatomic, readwrite) NSURL *serverURL;

@property (nonatomic, readwrite) NSString *remoteURL;
@property (nonatomic, readwrite) NSString *realmID;

@property (nonatomic) RLMSyncToken accessToken;

@property (nonatomic) RLMSyncToken refreshToken;

@end

@implementation RLMSyncSession

// MARK: Public API

- (void)refreshWithError:(NSError **)error completion:(RLMSyncCompletionBlock)completionBlock {
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
                           kRLMSyncProviderKey: @"realm",
                           kRLMSyncDataKey: self.refreshToken,
                           kRLMSyncRealmIDKey: self.realmID,
                           kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                           };

    __weak RLMSyncSession *weakSelf = self;
    [RLMSyncNetworkClient postSyncRequestToEndpoint:RLMSyncServerEndpointRefresh
                                             server:self.serverURL
                                               JSON:json
                                              error:error
                                         completion:^(NSError *error, NSDictionary *json) {
                                             // Extract and save the updated tokens.
                                             RLMSyncSession *__self = weakSelf;
                                             if (!__self) {
                                                 return;
                                             }
                                             if (error) {
                                                 // Bad response
                                                 __self.valid = NO;
                                                 block(error, nil);
                                                 return;
                                             }
                                             RLMSyncRefreshDataModel *model = [[RLMSyncRefreshDataModel alloc] initWithJSON:json];
                                             if (!model) {
                                                 error = [NSError errorWithDomain:RLMSyncErrorDomain
                                                                             code:RLMSyncErrorBadResponse
                                                                         userInfo:nil];
                                                 block(error, nil);
                                                 return;
                                             }
                                             [__self refreshWithModel:model];
                                             block(error, json);
                                         }];
}

- (void)destroy {
    if (!self.valid) {
        return;
    }

    // TODO
    NSAssert(NO, @"Implement me!");
}

- (void)addCredential:(RLMSyncCredential)credential
             userInfo:(NSDictionary *)userInfo
          forProvider:(RLMSyncIdentityProvider)provider
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

// MARK: Private API

- (void)configureWithServerURL:(NSURL *)serverURL
              sessionDataModel:(RLMSyncSessionDataModel *)model {
    self.serverURL = serverURL;
    self.account = model.accountID;
    self.remoteURL = model.realmURL;
    self.realmID = model.realmID;
    self.accessToken = model.accessToken;

    [self scheduleRefreshWithToken:model.renewalTokenModel currentTokenExpiration:model.accessTokenExpiry];

    self.valid = YES;
}

- (void)refreshWithModel:(RLMSyncRefreshDataModel *)model {
    self.accessToken = model.accessToken;

    // Pass the updated access token to the Realm.
    auto coordinator = realm::_impl::RealmCoordinator::get_existing_coordinator(RLMStringDataWithNSString(self.path));
    if (coordinator) {
        std::string new_token{self.accessToken.UTF8String};
        coordinator->refresh_sync_access_token(std::move(new_token));
    } else {
        self.valid = NO;
        return;
    }

    [self scheduleRefreshWithToken:model.renewalTokenModel currentTokenExpiration:model.accessTokenExpiry];
}

// MARK: Other

- (void)scheduleRefreshWithToken:(RLMSyncRenewalTokenModel *)token
          currentTokenExpiration:(NSTimeInterval)expiration {
    self.refreshToken = token.renewalToken;

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
    [self refreshWithError:nil completion:nil];
}

- (instancetype)init {
    if (self = [super init]) {
        self.valid = NO;
    }
    return self;
}

@end
