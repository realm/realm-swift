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

#import "RLMSyncSessionRefreshHandle.hpp"

#import "RLMAuthResponseModel.h"
#import "RLMNetworkClient.h"
#import "RLMSyncManager_Private.h"
#import "RLMSyncUser_Private.hpp"
#import "RLMTokenModels.h"

#import "sync/sync_session.hpp"

using namespace realm;

@interface RLMSyncSessionRefreshHandle () {
    std::weak_ptr<SyncSession> _session;
}

@property (nonatomic, weak) RLMSyncUser *user;
@property (nonatomic, strong) NSString *fullURLPath;
@property (nonatomic) NSTimer *timer;

@end

@implementation RLMSyncSessionRefreshHandle

- (instancetype)initWithFullURLPath:(NSString *)urlPath
                               user:(RLMSyncUser *)user
                            session:(std::shared_ptr<realm::SyncSession>)session {
    if (self = [super init]) {
        self.fullURLPath = urlPath;
        self.user = user;
        _session = session;
        return self;
    }
    return nil;
}

- (void)invalidate {
    [self.timer invalidate];
    self.user = nil;
}

- (void)scheduleRefreshTimer:(NSTimeInterval)fireTime {
    static const NSInteger refreshBuffer = 10;
    [self.timer invalidate];
    self.timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSince1970:(fireTime - refreshBuffer)]
                                          interval:0
                                            target:self
                                          selector:@selector(timerFired:)
                                          userInfo:nil
                                           repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)timerFired:(__unused NSTimer *)timer {
    RLMSyncUser *user = self.user;
    if (!user) {
        return;
    }
    RLMServerToken refreshToken = user._refreshToken;
    if (!refreshToken) {
        [user _unregisterRefreshHandleForURLPath:self.fullURLPath];
        [self.timer invalidate];
        return;
    }

    NSDictionary *json = @{
                           kRLMSyncProviderKey: @"realm",
                           kRLMSyncPathKey: self.fullURLPath,
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
                [user _unregisterRefreshHandleForURLPath:self.fullURLPath];
                [self.timer invalidate];
                [[RLMSyncManager sharedManager] _fireError:error];
                return;
            }

            // Success
            if (auto session = _session.lock()) {
                if (session->state() != SyncSession::PublicState::Error) {
                    session->refresh_access_token([model.accessToken.token UTF8String], none);
                    [self scheduleRefreshTimer:model.accessToken.tokenData.expires];
                    return;
                }
            }
            // The session is dead or in a fatal error state.
            [user _unregisterRefreshHandleForURLPath:self.fullURLPath];
            [self.timer invalidate];
            return;
        }

        // Something else went wrong
        NSError *syncError = [NSError errorWithDomain:RLMSyncErrorDomain
                                                 code:RLMSyncErrorBadResponse
                                             userInfo:@{kRLMSyncUnderlyingErrorKey: error}];
        [[RLMSyncManager sharedManager] _fireError:syncError];
        NSTimeInterval nextFireDate = 0;
        // Certain errors should trigger a retry.
        if (error.domain == NSURLErrorDomain) {
            switch (error.code) {
                case NSURLErrorCannotConnectToHost:
                    // FIXME: 120 seconds is an arbitrarily chosen value, consider rationalizing it.
                    nextFireDate = [[NSDate dateWithTimeIntervalSinceNow:120] timeIntervalSince1970];
                    break;
                case NSURLErrorNotConnectedToInternet:
                case NSURLErrorNetworkConnectionLost:
                case NSURLErrorTimedOut:
                case NSURLErrorDNSLookupFailed:
                case NSURLErrorCannotFindHost:
                    // FIXME: 30 seconds is an arbitrarily chosen value, consider rationalizing it.
                    nextFireDate = [[NSDate dateWithTimeIntervalSinceNow:30] timeIntervalSince1970];
                    break;
                default:
                    break;
            }
            if (nextFireDate > 0) {
                [self scheduleRefreshTimer:nextFireDate];
            } else {
                [user _unregisterRefreshHandleForURLPath:self.fullURLPath];
                [self.timer invalidate];
            }
        }
    };
    [RLMNetworkClient postRequestToEndpoint:RLMServerEndpointAuth
                                     server:user.authenticationServer
                                       JSON:json
                                 completion:handler];
}

@end
