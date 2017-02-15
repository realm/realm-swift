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
#import "RLMUtil.hpp"

#import "sync/sync_session.hpp"

using namespace realm;

@interface RLMSyncSessionRefreshHandle () {
    std::weak_ptr<SyncSession> _session;
    std::shared_ptr<SyncSession> _strongSession;
}

@property (nonatomic, weak) RLMSyncUser *user;
@property (nonatomic, strong) NSString *pathToRealm;
@property (nonatomic) NSTimer *timer;

@property (nonatomic) NSURL *realmURL;
@property (nonatomic, copy) RLMSyncBasicErrorReportingBlock completionBlock;

@end

@implementation RLMSyncSessionRefreshHandle

- (instancetype)initWithRealmURL:(NSURL *)realmURL
                            user:(RLMSyncUser *)user
                         session:(std::shared_ptr<realm::SyncSession>)session
                 completionBlock:(RLMSyncBasicErrorReportingBlock)completionBlock {
    if (self = [super init]) {
        NSString *path = [realmURL path];
        self.pathToRealm = path;
        self.user = user;
        self.completionBlock = completionBlock;
        self.realmURL = realmURL;
        // For the initial bind, we want to prolong the session's lifetime.
        _strongSession = std::move(session);
        _session = _strongSession;
        // Immediately fire off the network request.
        [self _timerFired:nil];
        return self;
    }
    return nil;
}

- (void)dealloc {
    [self.timer invalidate];
}

- (void)invalidate {
    _strongSession = nullptr;
    [self.timer invalidate];
}

+ (NSDate *)fireDateForTokenExpirationDate:(NSDate *)date nowDate:(NSDate *)nowDate {
    static const NSTimeInterval refreshBuffer = 10;
    NSDate *fireDate = [date dateByAddingTimeInterval:-refreshBuffer];
    // Only fire times in the future are valid.
    return ([fireDate compare:nowDate] == NSOrderedDescending ? fireDate : nil);
}

- (void)scheduleRefreshTimer:(NSDate *)dateWhenTokenExpires {
    // Schedule the timer on the main queue.
    // It's very likely that this method will be run on a side thread, for example
    // on the thread that runs `NSURLSession`'s completion blocks. We can't be
    // guaranteed that there's an existing runloop on those threads, and we don't want
    // to create and start a new one if one doesn't already exist.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.timer invalidate];
        NSDate *fireDate = [RLMSyncSessionRefreshHandle fireDateForTokenExpirationDate:dateWhenTokenExpires
                                                                               nowDate:[NSDate date]];
        if (!fireDate) {
            [self.user _unregisterRefreshHandleForURLPath:self.pathToRealm];
            return;
        }
        self.timer = [[NSTimer alloc] initWithFireDate:fireDate
                                              interval:0
                                                target:self
                                              selector:@selector(_timerFired:)
                                              userInfo:nil
                                               repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    });
}

/// Handler for network requests whose responses successfully parse into an auth response model.
- (BOOL)_handleSuccessfulRequest:(RLMAuthResponseModel *)model strongUser:(RLMSyncUser *)user {
    // Success
    std::shared_ptr<SyncSession> session = _session.lock();
    if (!session) {
        // The session is dead or in a fatal error state.
        [user _unregisterRefreshHandleForURLPath:self.pathToRealm];
        [self invalidate];
        return NO;
    }
    bool success = session->state() != SyncSession::PublicState::Error;
    if (success) {
        // Calculate the resolved path.
        NSString *resolvedURLString = nil;
        RLMServerPath resolvedPath = model.accessToken.tokenData.path;
        // Munge the path back onto the original URL, because the `sync` API expects an entire URL.
        NSURLComponents *urlBuffer = [NSURLComponents componentsWithURL:self.realmURL
                                                resolvingAgainstBaseURL:YES];
        urlBuffer.path = resolvedPath;
        resolvedURLString = [[urlBuffer URL] absoluteString];
        if (!resolvedURLString) {
            @throw RLMException(@"Resolved path returned from the server was invalid (%@).", resolvedPath);
        }
        // Pass the token and resolved path to the underlying sync subsystem.
        session->refresh_access_token([model.accessToken.token UTF8String], {resolvedURLString.UTF8String});
        success = session->state() != SyncSession::PublicState::Error;
        if (success) {
            // Schedule a refresh. If we're successful we must already have `bind()`ed the session
            // initially, so we can null out the strong pointer.
            _strongSession = nullptr;
            NSDate *expires = [NSDate dateWithTimeIntervalSince1970:model.accessToken.tokenData.expires];
            [self scheduleRefreshTimer:expires];
        } else {
            // The session is dead or in a fatal error state.
            [user _unregisterRefreshHandleForURLPath:self.pathToRealm];
            [self invalidate];
        }
    }
    if (self.completionBlock) {
        self.completionBlock(success ? nil : [NSError errorWithDomain:RLMSyncErrorDomain
                                                                 code:RLMSyncErrorClientSessionError
                                                             userInfo:nil]);
    }
    return success;
}

/// Handler for network requests that failed before the JSON parsing stage.
- (BOOL)_handleFailedRequest:(NSError *)error strongUser:(RLMSyncUser *)user {
    NSError *syncError = [NSError errorWithDomain:RLMSyncErrorDomain
                                             code:RLMSyncErrorBadResponse
                                         userInfo:@{kRLMSyncUnderlyingErrorKey: error}];
    if (self.completionBlock) {
        self.completionBlock(syncError);
    }
    [[RLMSyncManager sharedManager] _fireError:syncError];
    // Certain errors related to network connectivity should trigger a retry.
    NSDate *nextTryDate = nil;
    if (error.domain == NSURLErrorDomain) {
        switch (error.code) {
            case NSURLErrorCannotConnectToHost:
            case NSURLErrorNotConnectedToInternet:
            case NSURLErrorNetworkConnectionLost:
            case NSURLErrorTimedOut:
            case NSURLErrorDNSLookupFailed:
            case NSURLErrorCannotFindHost:
                // FIXME: 10 seconds is an arbitrarily chosen value, consider rationalizing it.
                nextTryDate = [NSDate dateWithTimeIntervalSinceNow:10];
                break;
            default:
                break;
        }
    }
    if (!nextTryDate) {
        // This error isn't a network failure error. Just invalidate the refresh handle and stop.
        [user _unregisterRefreshHandleForURLPath:self.pathToRealm];
        [self invalidate];
        return NO;
    }
    // If we tried to initially bind the session and failed, we'll try again. However, each
    // subsequent attempt will use a weak pointer to avoid prolonging the session's lifetime
    // unnecessarily.
    _strongSession = nullptr;
    [self scheduleRefreshTimer:nextTryDate];
    return NO;
}

/// Callback handler for network requests.
- (BOOL)_onRefreshCompletionWithError:(NSError *)error json:(NSDictionary *)json {
    RLMSyncUser *user = self.user;
    if (!user) {
        return NO;
    }
    if (json && !error) {
        RLMAuthResponseModel *model = [[RLMAuthResponseModel alloc] initWithDictionary:json
                                                                    requireAccessToken:YES
                                                                   requireRefreshToken:NO];
        if (model) {
            return [self _handleSuccessfulRequest:model strongUser:user];
        }
        // Otherwise, malformed JSON
        error = [NSError errorWithDomain:RLMSyncErrorDomain
                                    code:RLMSyncErrorBadResponse
                                userInfo:@{kRLMSyncErrorJSONKey: json}];
        [user _unregisterRefreshHandleForURLPath:self.pathToRealm];
        [self.timer invalidate];
        if (self.completionBlock) {
            self.completionBlock(error);
        }
        [[RLMSyncManager sharedManager] _fireError:error];
        return NO;
    } else {
        REALM_ASSERT(error);
        return [self _handleFailedRequest:error strongUser:user];
    }
}

- (void)_timerFired:(__unused NSTimer *)timer {
    RLMSyncUser *user = self.user;
    if (!user) {
        return;
    }
    RLMServerToken refreshToken = user._refreshToken;
    if (!refreshToken) {
        [user _unregisterRefreshHandleForURLPath:self.pathToRealm];
        [self.timer invalidate];
        return;
    }

    NSDictionary *json = @{
                           kRLMSyncProviderKey: @"realm",
                           kRLMSyncPathKey: self.pathToRealm,
                           kRLMSyncDataKey: refreshToken,
                           kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                           };

    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        [self _onRefreshCompletionWithError:error json:json];
    };
    [RLMNetworkClient postRequestToEndpoint:RLMServerEndpointAuth
                                     server:user.authenticationServer
                                       JSON:json
                                 completion:handler];
}

@end
