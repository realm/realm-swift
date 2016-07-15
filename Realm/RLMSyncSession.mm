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

#import "shared_realm.hpp"
#import "RLMUtil.hpp"

#import "RLMSyncNetworkClient.h"
#import "RLMSyncManager_Private.h"
#import "RLMSyncRefreshDataModel.h"
#import "RLMSyncRenewalTokenModel.h"
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
@property (nonatomic) NSTimeInterval accessTokenExpiry;

@property (nonatomic) RLMSyncToken refreshToken;
@property (nonatomic) NSTimeInterval refreshTokenExpiry;

@end

@implementation RLMSyncSession

// MARK: Public API

- (void)refreshWithCompletion:(RLMSyncCompletionBlock)completionBlock {
    if (![self canMakeAPICallWithCompletionBlock:completionBlock]) {
        return;
    }
    RLMSyncCompletionBlock block = completionBlock ?: ^(NSError *, NSDictionary *){ };

    // Make sure refresh token hasn't yet expired
    NSTimeInterval now = [NSDate date].timeIntervalSince1970;
    if (now > self.refreshTokenExpiry) {
        block([NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorInvalidSession userInfo:nil], nil);
        self.valid = NO;
        return;
    }

    NSDictionary *json = @{
                           kRLMSyncProviderKey: @"realm",
                           kRLMSyncDataKey: self.refreshToken,
                           kRLMSyncRealmIDKey: self.realmID,
                           kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                           };

    __weak RLMSyncSession *weakSelf = self;
    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        // Extract and save the updated tokens.
        RLMSyncSession *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (error) {
            // Bad response
            strongSelf.valid = NO;
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
        [strongSelf updateTokenStateWithModel:model];
        block(error, json);
    };

    [RLMSyncNetworkClient postSyncRequestToEndpoint:RLMSyncServerEndpointRefresh
                                             server:self.serverURL
                                               JSON:json
                                         completion:handler];
}

- (void)destroy {
    if (![self canMakeAPICallWithCompletionBlock:nil]) {
        return;
    }

    // TODO
    NSAssert(NO, @"Implement me!");
}

- (void)addCredential:(RLMSyncCredential)credential
             userInfo:(NSDictionary *)userInfo
          forProvider:(RLMSyncIdentityProvider)provider
         onCompletion:(RLMSyncCompletionBlock)completionBlock {
    if (![self canMakeAPICallWithCompletionBlock:completionBlock]) {
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
    self.accessTokenExpiry = model.accessTokenExpiry;

    [self scheduleRefreshWithToken:model.renewalTokenModel currentTokenExpiration:model.accessTokenExpiry];

    self.valid = YES;
}

- (void)updateTokenStateWithModel:(RLMSyncRefreshDataModel *)model {
    self.accessToken = model.accessToken;
    self.accessTokenExpiry = model.accessTokenExpiry;

    // Pass the updated access token to the Realm.
    std::string new_token{self.accessToken.UTF8String};
    bool wasRefreshed = realm::Realm::refresh_sync_access_token(std::move(new_token),
                                                                RLMStringDataWithNSString(self.path));
    if (!wasRefreshed) {
        self.valid = NO;
        return;
    }

    [self scheduleRefreshWithToken:model.renewalTokenModel currentTokenExpiration:model.accessTokenExpiry];
}

/**
 Check whether the session object is in a state where it should be allowed to make an API call to the server.
 */
- (BOOL)canMakeAPICallWithCompletionBlock:(RLMSyncCompletionBlock)completionBlock {
    RLMSyncCompletionBlock block = completionBlock ?: ^(NSError *, NSDictionary *){ };

    if (![RLMSyncManager sharedManager].configured) {
        block([NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorManagerNotConfigured userInfo:nil],
              nil);
        return NO;
    }
    if (!self.valid) {
        block([NSError errorWithDomain:RLMSyncErrorDomain code:RLMSyncErrorInvalidSession userInfo:nil], nil);
        return NO;
    }
    return YES;
}

// MARK: Other

- (void)scheduleRefreshWithToken:(RLMSyncRenewalTokenModel *)token
          currentTokenExpiration:(NSTimeInterval)expiration {
    self.refreshToken = token.renewalToken;
    self.refreshTokenExpiry = token.tokenExpiry;

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
                                           selector:@selector(performTokenRefresh:)
                                           userInfo:nil
                                            repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)performTokenRefresh:(__attribute__((unused)) NSTimer *)timer {
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;

    if (!self.valid) {
        return;
    }

    // Force a refresh
    // TODO: pass in a completion block that'll inform the app if something goes wrong (through the general
    //  purpose callback)
    [self refreshWithCompletion:nil];
}

- (instancetype)init {
    if (self = [super init]) {
        self.valid = NO;
    }
    return self;
}

@end
