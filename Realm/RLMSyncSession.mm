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
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncUtil.h"
#import "RLMTokenModels.h"
#import "RLMUser_Private.h"
#import "RLMUtil.hpp"

@implementation RLMRealmBindingPackage

- (instancetype)initWithFileURL:(NSURL *)fileURL
                       realmURL:(NSURL *)realmURL
                          block:(RLMErrorReportingBlock)block {
    if (self = [super init]) {
        self.fileURL = fileURL;
        self.realmURL = realmURL;
        self.block = block;
        return self;
    }
    return nil;
}

@end

@interface RLMSyncSession ()

@property (nonatomic, readwrite) RLMSyncSessionState state;
@property (nonatomic, readwrite) RLMUser *parentUser;
@property (nonatomic, readwrite) NSURL *realmURL;

@end

@implementation RLMSyncSession

- (instancetype)initWithFileURL:(NSURL *)fileURL realmURL:(NSURL *)realmURL {
    if (self = [super init]) {
        self.fileURL = fileURL;
        self.realmURL = realmURL;
        self.resolvedPath = nil;
        self.deferredBindingPackage = nil;
        self.state = RLMSyncSessionStateUnbound;
        return self;
    }
    return nil;
}

- (nullable RLMSyncConfiguration *)configuration {
    RLMUser *user = self.parentUser;
    if (user && self.state != RLMSyncSessionStateInvalid) {
        return [[RLMSyncConfiguration alloc] initWithUser:user realmURL:self.realmURL];
    }
    return nil;
}

- (void)_invalidate {
    [self.refreshTimer invalidate];
    self.state = RLMSyncSessionStateInvalid;
    [self.parentUser _deregisterSessionWithRealmURL:self.realmURL];
    self.parentUser = nil;
}

#pragma mark - per-Realm access token API

- (void)configureWithAccessToken:(RLMServerToken)token expiry:(NSTimeInterval)expiry user:(RLMUser *)user {
    self.parentUser = user;
    self.accessToken = token;
    self.accessTokenExpiry = expiry;
    [self _scheduleRefreshTimer];
}

- (void)_scheduleRefreshTimer {
    static NSTimeInterval const refreshBuffer = 10;

    [self.refreshTimer invalidate];
    NSTimeInterval refreshTime = self.accessTokenExpiry - refreshBuffer;
    NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSince1970:refreshTime]
                                              interval:1
                                                target:self
                                              selector:@selector(refresh)
                                              userInfo:nil
                                               repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    self.refreshTimer = timer;
}

- (void)_refresh {
    RLMUser *user = self.parentUser;
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

    RLMServerCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        if (json && !error) {
            RLMAuthResponseModel *model = [[RLMAuthResponseModel alloc] initWithDictionary:json
                                                                        requireAccessToken:YES
                                                                       requireRefreshToken:NO];
            if (!model) {
                // Malformed JSON
//                [user _reportRefreshFailureForPath:self.path error:nil];
                // TODO: invalidate
                return;
            } else {
                // Success
                // For now, assume just one access token.
                RLMTokenModel *tokenModel = model.accessToken;
                self.accessToken = model.accessToken.token;
                self.accessTokenExpiry = tokenModel.tokenData.expires;
                [self _scheduleRefreshTimer];

                realm::Realm::refresh_sync_access_token(std::string([tokenModel.token UTF8String]),
                                                        RLMStringDataWithNSString([self.fileURL path]),
                                                        realm::util::none);
                self.state = RLMSyncSessionStateActive;
            }
        } else {
            // Something else went wrong
//            [user _reportRefreshFailureForPath:self.path error:error];
            // TODO: invalidate
        }
    };
    [RLMNetworkClient postRequestToEndpoint:RLMServerEndpointAuth
                                     server:user.authenticationServer
                                       JSON:json
                                 completion:handler];
}

- (void)setState:(RLMSyncSessionState)state {
    _state = state;
    if (state == RLMSyncSessionStateActive) {
        self.deferredBindingPackage = nil;
    }
}

@end
