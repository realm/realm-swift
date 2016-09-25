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

#import "RLMAuthResponseModel.h"
#import "RLMNetworkClient.h"
#import "RLMRealmConfiguration+Sync.h"
#import "RLMSyncConfiguration.h"
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncSessionHandle.hpp"
#import "RLMSyncUser_Private.hpp"
#import "RLMSyncUtil.h"
#import "RLMTokenModels.h"
#import "RLMUtil.hpp"

#import "sync_manager.hpp"

@implementation RLMSessionBindingPackage

- (instancetype)initWithFileURL:(NSURL *)fileURL
                     syncConfig:(RLMSyncConfiguration *)syncConfig
                     standalone:(BOOL)isStandalone
                          block:(RLMSyncBasicErrorReportingBlock)block {
    if (self = [super init]) {
        self.fileURL = fileURL;
        self.syncConfig = syncConfig;
        self.isStandalone = isStandalone;
        self.block = block;
        return self;
    }
    return nil;
}

@end

@interface RLMSyncSession ()

@property (nonatomic, readwrite) RLMSyncSessionState state;
@property (nonatomic, readwrite) RLMSyncUser *parentUser;
@property (nonatomic, readwrite) NSURL *realmURL;

@property (nullable, nonatomic) RLMSyncSessionHandle *sessionHandle;

@end

@implementation RLMSyncSession

- (instancetype)initWithFileURL:(NSURL *)fileURL realmURL:(NSURL *)realmURL {
    if (self = [super init]) {
        self.fileURL = fileURL;
        self.realmURL = realmURL;
        self.resolvedPath = nil;
        self.deferredBindingPackage = nil;
        _state = RLMSyncSessionStateUnbound;
        return self;
    }
    return nil;
}

- (nullable RLMSyncConfiguration *)configuration {
    RLMSyncUser *user = self.parentUser;
    if (user && self.state != RLMSyncSessionStateInvalid) {
        return [[RLMSyncConfiguration alloc] initWithUser:user realmURL:self.realmURL];
    }
    return nil;
}

- (void)_logOut {
    [self.sessionHandle logOut];
    [self.refreshTimer invalidate];
    _state = RLMSyncSessionStateLoggedOut;
}

- (void)_invalidate {
    [self.refreshTimer invalidate];
    _state = RLMSyncSessionStateInvalid;
    self.sessionHandle = nil;
    [self.parentUser _deregisterSessionWithRealmURL:self.realmURL];
    self.parentUser = nil;
}

#pragma mark - per-Realm access token API

- (void)configureWithAccessToken:(RLMServerToken)token
                          expiry:(NSTimeInterval)expiry
                            user:(RLMSyncUser *)user
                          handle:(RLMSyncSessionHandle *)handle {
    self.parentUser = user;
    self.accessToken = token;
    self.accessTokenExpiry = expiry;
    self.sessionHandle = handle;
    [self _scheduleRefreshTimer];
}

- (void)_scheduleRefreshTimer {
    static NSTimeInterval const refreshBuffer = 10;

    [self.refreshTimer invalidate];
    NSTimeInterval refreshTime = self.accessTokenExpiry - refreshBuffer;
    NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSince1970:refreshTime]
                                              interval:1
                                                target:self
                                              selector:@selector(_refreshForTimer:)
                                              userInfo:nil
                                               repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    self.refreshTimer = timer;
}

- (void)_refreshForTimer:(__unused NSTimer *)timer {
    [self _refresh];
}

- (void)_refresh {
    RLMSyncUser *user = self.parentUser;
    if (!user || !self.resolvedPath) {
        return;
    }
    RLMServerToken refreshToken = user.refreshToken;

    NSDictionary *json = @{
                           kRLMSyncProviderKey: @"realm",
                           kRLMSyncPathKey: self.resolvedPath,
                           kRLMSyncDataKey: refreshToken,
                           kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                           };

    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        if (json && !error) {
            RLMAuthResponseModel *model = [[RLMAuthResponseModel alloc] initWithDictionary:json
                                                                        requireAccessToken:YES
                                                                       requireRefreshToken:NO];
            if (!model) {
                // Malformed JSON
                error = [NSError errorWithDomain:RLMSyncErrorDomain
                                            code:RLMSyncErrorBadResponse
                                        userInfo:@{kRLMSyncErrorJSONKey: json}];
                [[RLMSyncManager sharedManager] _fireError:error];
                return;
            } else {
                // Success
                // For now, assume just one access token.
                RLMTokenModel *tokenModel = model.accessToken;
                self.accessToken = model.accessToken.token;
                self.accessTokenExpiry = tokenModel.tokenData.expires;
                [self _scheduleRefreshTimer];

                [self refreshAccessToken:tokenModel.token serverURL:nil];
            }
        } else {
            // Something else went wrong
            NSError *syncError = [NSError errorWithDomain:RLMSyncErrorDomain
                                                     code:RLMSyncErrorBadResponse
                                                 userInfo:@{kRLMSyncUnderlyingErrorKey: error}];
            [[RLMSyncManager sharedManager] _fireError:syncError];
            // Certain errors should trigger a retry.
            if (error.domain == NSURLErrorDomain) {
                BOOL shouldRetry = NO;
                switch (error.code) {
                    case NSURLErrorCannotConnectToHost:
                        shouldRetry = YES;
                        // FIXME: 120 seconds is an arbitrarily chosen value, consider rationalizing it.
                        self.accessTokenExpiry = [[NSDate dateWithTimeIntervalSinceNow:120] timeIntervalSince1970];
                        break;
                    case NSURLErrorNotConnectedToInternet:
                    case NSURLErrorNetworkConnectionLost:
                    case NSURLErrorTimedOut:
                    case NSURLErrorDNSLookupFailed:
                    case NSURLErrorCannotFindHost:
                        shouldRetry = YES;
                        // FIXME: 30 seconds is an arbitrarily chosen value, consider rationalizing it.
                        self.accessTokenExpiry = [[NSDate dateWithTimeIntervalSinceNow:30] timeIntervalSince1970];
                        break;
                    default:
                        break;
                }
                if (shouldRetry) {
                    [self _scheduleRefreshTimer];
                }
            }
        }
    };
    [RLMNetworkClient postRequestToEndpoint:RLMServerEndpointAuth
                                     server:user.authenticationServer
                                       JSON:json
                                 completion:handler];
}

- (void)refreshAccessToken:(NSString *)token serverURL:(NSURL *)serverURL
{
    if ([self.sessionHandle refreshAccessToken:token serverURL:serverURL]) {
        self.state = RLMSyncSessionStateActive;
    }
    else {
        [self _invalidate];
    }
}

- (void)setState:(RLMSyncSessionState)state {
    // At all state transitions, check to see if the session should be invalidated.
    if ([self.sessionHandle sessionIsInErrorState]) {
        [self _invalidate];
        return;
    }
    _state = state;
    if (state == RLMSyncSessionStateActive) {
        self.deferredBindingPackage = nil;
    }
}

@end
