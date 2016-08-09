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

#import "RLMSessionInfo_Private.h"

#import "RLMUser_Private.h"
#import "RLMServerUtil.h"
#import "RLMServerNetworkClient.h"
#import "RLMServer_Private.h"
#import "RLMUtil.hpp"
#import "RLMRefreshResponseModel.h"

@implementation RLMSessionInfo

- (instancetype)initWithFileURL:(NSURL *)fileURL path:(RLMServerPath)path {
    if (self = [super init]) {
        self.fileURL = fileURL;
        self.path = path;
        self.deferredBindingPackage = nil;
        self.isBound = NO;
        return self;
    }
    return nil;
}

#pragma mark - per-Realm access token API
// NOTE: much of this may disappear once we get a single access token for a user that works with multiple Realms

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

- (void)refresh {
    RLMUser *user = self.parentUser;
    if (!user) {
        return;
    }
    if (!user.isLoggedIn) {
        @throw RLMException(@"The user isn't logged in. The user must first log in before they can be refreshed.");
    }
    // TODO: what happens if the access token is expired, but the refresh token isn't?

    RLMServerToken refreshToken = user.refreshToken;

    NSDictionary *json = @{
                           kRLMServerProviderKey: @"realm",
                           kRLMServerPathKey: self.path,
                           kRLMServerDataKey: refreshToken,
                           kRLMServerAppIDKey: [RLMServer appID],
                           };

    RLMServerCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        if (json && !error) {
            RLMRefreshResponseModel *model = [[RLMRefreshResponseModel alloc] initWithJSON:json];
            if (!model) {
                // Malformed JSON
                [user _reportRefreshFailureForPath:self.path error:nil];
                // TODO: invalidate
                return;
            } else {
                // Success
                NSString *accessToken = model.accessToken;
                self.accessToken = accessToken;
                self.accessTokenExpiry = model.accessTokenExpiry;
                [self _scheduleRefreshTimer];

                realm::Realm::refresh_sync_access_token(std::string([accessToken UTF8String]),
                                                        RLMStringDataWithNSString([self.fileURL path]),
                                                        realm::util::none);
            }
        } else {
            // Something else went wrong
            [user _reportRefreshFailureForPath:self.path error:error];
            // TODO: invalidate
        }
    };
    [RLMServerNetworkClient postRequestToEndpoint:RLMServerEndpointAuth
                                           server:user.authURL
                                             JSON:json
                                       completion:handler];
}

- (void)setIsBound:(BOOL)isBound {
    _isBound = isBound;
    if (isBound) {
        self.deferredBindingPackage = nil;
    }
}

@end

@implementation RLMRealmBindingPackage

- (instancetype)initWithFileURL:(NSURL *)fileURL
                     remotePath:(NSString *)remotePath
                          block:(RLMErrorReportingBlock)block {
    if (self = [super init]) {
        self.fileURL = fileURL;
        self.remotePath = remotePath;
        self.block = block;
        return self;
    }
    return nil;
}

@end
