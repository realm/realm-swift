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

#import "RLMSyncUser_Private.hpp"

#import "RLMAuthResponseModel.h"
#import "RLMNetworkClient.h"
#import "RLMSyncManager_Private.h"
#import "RLMSyncSession_Private.hpp"
#import "RLMSyncSessionRefreshHandle.hpp"
#import "RLMTokenModels.h"
#import "RLMUtil.hpp"

#import "sync/sync_manager.hpp"
#import "sync/sync_session.hpp"
#import "sync/sync_user.hpp"

using namespace realm;

@interface RLMSyncUser () {
    std::shared_ptr<SyncUser> _user;
}

- (instancetype)initWithAuthServer:(nullable NSURL *)authServer NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readwrite) NSURL *authenticationServer;
@property (nonatomic) NSMutableDictionary<NSString *, RLMSyncSessionRefreshHandle *> *refreshHandles;

@end

@implementation RLMSyncUser

#pragma mark - static API

+ (NSDictionary *)allUsers {
    NSArray *allUsers = [[RLMSyncManager sharedManager] _allUsers];
    return [NSDictionary dictionaryWithObjects:allUsers
                                       forKeys:[allUsers valueForKey:@"identity"]];
}

+ (RLMSyncUser *)currentUser {
    NSArray *allUsers = [[RLMSyncManager sharedManager] _allUsers];
    if (allUsers.count > 1) {
        @throw RLMException(@"+currentUser cannot be called if more that one valid, logged-in user exists.");
    }
    return allUsers.firstObject;
}

#pragma mark - API

- (instancetype)initWithAuthServer:(nullable NSURL *)authServer {
    if (self = [super init]) {
        self.authenticationServer = authServer;
        return self;
    }
    return nil;
}

- (instancetype)initWithSyncUser:(std::shared_ptr<SyncUser>)user {
    NSString *rawServerURL = @(user->server_url().c_str());
    if (self = [self initWithAuthServer:[NSURL URLWithString:rawServerURL]]) {
        _user = user;
        return self;
    }
    return nil;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[RLMSyncUser class]]) {
        return NO;
    }
    return _user == ((RLMSyncUser *)object)->_user;
}

+ (void)logInWithCredentials:(RLMSyncCredentials *)credential
               authServerURL:(NSURL *)authServerURL
                onCompletion:(RLMUserCompletionBlock)completion {
    [self logInWithCredentials:credential
                 authServerURL:authServerURL
                       timeout:30
                  onCompletion:completion];
}

+ (void)logInWithCredentials:(RLMSyncCredentials *)credential
               authServerURL:(NSURL *)authServerURL
                     timeout:(NSTimeInterval)timeout
                onCompletion:(RLMUserCompletionBlock)completion {
    RLMSyncUser *user = [[RLMSyncUser alloc] initWithAuthServer:authServerURL];
    [RLMSyncUser _performLogInForUser:user
                          credentials:credential
                        authServerURL:authServerURL
                              timeout:timeout
                      completionBlock:completion];
}

- (void)logOut {
    if (!_user) {
        return;
    }
    _user->log_out();
    for (id key in self.refreshHandles) {
        [self.refreshHandles[key] invalidate];
    }
    [self.refreshHandles removeAllObjects];
}

- (nullable RLMSyncSession *)sessionForURL:(NSURL *)url {
    if (!_user) {
        return nil;
    }
    return [[RLMSyncSession alloc] initWithSyncSession:_user->session_for_url([[url absoluteString] UTF8String])];
}

- (NSArray<RLMSyncSession *> *)allSessions {
    if (!_user) {
        return @[];
    }
    NSMutableArray<RLMSyncSession *> *buffer = [NSMutableArray array];
    auto sessions = _user->all_sessions();
    for (auto session : sessions) {
        [buffer addObject:[[RLMSyncSession alloc] initWithSyncSession:std::move(session)]];
    }
    return [buffer copy];
}

- (NSString *)identity {
    if (!_user) {
        return nil;
    }
    return @(_user->identity().c_str());
}

- (RLMSyncUserState)state {
    if (!_user) {
        return RLMSyncUserStateError;
    }
    switch (_user->state()) {
        case SyncUser::State::Active:
            return RLMSyncUserStateActive;
        case SyncUser::State::LoggedOut:
            return RLMSyncUserStateLoggedOut;
        case SyncUser::State::Error:
            return RLMSyncUserStateError;
    }
}

- (RLMRealm *)managementRealmWithError:(NSError **)error {
    return [RLMRealm realmWithConfiguration:[RLMRealmConfiguration managementConfigurationForUser:self] error:error];
}

#pragma mark - Private API

- (void)_unregisterRefreshHandleForURLPath:(NSString *)path {
    [self.refreshHandles removeObjectForKey:path];
}

- (NSString *)_refreshToken {
    if (!_user) {
        return nil;
    }
    return @(_user->refresh_token().c_str());
}

- (void)_bindSessionWithPath:(__unused const std::string&)path
                      config:(const SyncConfig&)config
                     session:(std::shared_ptr<SyncSession>)session
                  completion:(RLMSyncBasicErrorReportingBlock)completion
                isStandalone:(__unused BOOL)standalone {
    NSURL *realmURL = [NSURL URLWithString:@(config.realm_url.c_str())];
    RLMServerPath unresolvedURL = [realmURL path];
    NSDictionary *json = @{
                           kRLMSyncPathKey: unresolvedURL,
                           kRLMSyncProviderKey: @"realm",
                           kRLMSyncDataKey: @(_user->refresh_token().c_str()),
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
                if (completion) {
                    completion(error);
                }
                [[RLMSyncManager sharedManager] _fireError:error];
                return;
            }

            // SUCCESS
            NSString *accessToken = model.accessToken.token;
            RLMServerPath resolvedPath = model.accessToken.tokenData.path;
            // Munge the path onto the original URL, because reasons.
            NSURLComponents *urlBuffer = [NSURLComponents componentsWithURL:realmURL resolvingAgainstBaseURL:YES];
            urlBuffer.path = resolvedPath;
            NSString *resolvedURLString = [[urlBuffer URL] absoluteString];
            if (!resolvedURLString) {
                @throw RLMException(@"Resolved path returned from the server was invalid (%@).", resolvedPath);
            }
            // Refresh the access token.
            session->refresh_access_token([accessToken UTF8String], {resolvedURLString.UTF8String});
            bool success = session->state() != SyncSession::PublicState::Error;
            if (success) {
                // Schedule the session for automatic refreshing on a timer.
                auto handle = [[RLMSyncSessionRefreshHandle alloc] initWithFullURLPath:resolvedURLString
                                                                                  user:self
                                                                               session:session];
                [self.refreshHandles[resolvedURLString] invalidate];
                self.refreshHandles[resolvedURLString] = handle;
                [handle scheduleRefreshTimer:model.accessToken.tokenData.expires];
            }
            if (completion) {
                completion(success ? nil : [NSError errorWithDomain:RLMSyncErrorDomain
                                                               code:RLMSyncErrorClientSessionError
                                                           userInfo:nil]);
            }
            return;
        }

        // Something else went wrong
        NSError *syncError = [NSError errorWithDomain:RLMSyncErrorDomain
                                                 code:RLMSyncErrorBadResponse
                                             userInfo:@{kRLMSyncUnderlyingErrorKey: error}];
        if (completion) {
            completion(syncError);
        }
        [[RLMSyncManager sharedManager] _fireError:syncError];
    };
    [RLMNetworkClient postRequestToEndpoint:RLMServerEndpointAuth
                                     server:self.authenticationServer
                                       JSON:json
                                 completion:handler];
}

- (std::shared_ptr<SyncUser>)_syncUser {
    return _user;
}

+ (void)_performLogInForUser:(RLMSyncUser *)user
                 credentials:(RLMSyncCredentials *)credentials
               authServerURL:(NSURL *)authServerURL
                     timeout:(NSTimeInterval)timeout
             completionBlock:(RLMUserCompletionBlock)completion {
    // Wrap the completion block.
    RLMUserCompletionBlock theBlock = ^(RLMSyncUser *user, NSError *error){
        if (!completion) { return; }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(user, error);
        });
    };

    // Special credential login should be treated differently.
    if (credentials.provider == RLMIdentityProviderAccessToken) {
        [self _performLoginForDirectAccessTokenCredentials:credentials user:user completionBlock:theBlock];
        return;
    }

    // Prepare login network request
    NSMutableDictionary *json = [@{
                                   kRLMSyncProviderKey: credentials.provider,
                                   kRLMSyncDataKey: credentials.token,
                                   kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                                   } mutableCopy];
    NSMutableDictionary *info = [(credentials.userInfo ?: @{}) mutableCopy];

    if ([info count] > 0) {
        // Munge user info into the JSON request.
        json[@"user_info"] = info;
    }

    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        if (json && !error) {
            RLMAuthResponseModel *model = [[RLMAuthResponseModel alloc] initWithDictionary:json
                                                                        requireAccessToken:NO
                                                                       requireRefreshToken:YES];
            if (!model) {
                // Malformed JSON
                error = [NSError errorWithDomain:RLMSyncErrorDomain
                                            code:RLMSyncErrorBadResponse
                                        userInfo:@{kRLMSyncErrorJSONKey: json}];
                theBlock(nil, error);
                return;
            } else {
                std::string server_url = authServerURL.absoluteString.UTF8String;
                auto sync_user = SyncManager::shared().get_user([model.refreshToken.tokenData.identity UTF8String],
                                                                [model.refreshToken.token UTF8String],
                                                                std::move(server_url));
                if (!sync_user) {
                    completion(nil, [NSError errorWithDomain:RLMSyncErrorDomain
                                                        code:RLMSyncErrorClientSessionError
                                                    userInfo:nil]);
                    return;
                }
                user->_user = sync_user;
                completion(user, nil);
            }
        } else {
            // Something else went wrong
            theBlock(nil, error);
        }
    };
    [RLMNetworkClient postRequestToEndpoint:RLMServerEndpointAuth
                                     server:authServerURL
                                       JSON:json
                                    timeout:timeout
                                 completion:handler];
}

+ (void)_performLoginForDirectAccessTokenCredentials:(RLMSyncCredentials *)credentials
                                                user:(RLMSyncUser *)user
                                     completionBlock:(nonnull RLMUserCompletionBlock)completion {
    NSString *identity = credentials.userInfo[kRLMSyncIdentityKey];
    NSAssert(identity != nil, @"Improperly created direct access token credential.");
    auto sync_user = SyncManager::shared().get_user([identity UTF8String], [credentials.token UTF8String], none, true);
    if (!sync_user) {
        completion(nil, [NSError errorWithDomain:RLMSyncErrorDomain
                                            code:RLMSyncErrorClientSessionError
                                        userInfo:nil]);
        return;
    }
    user->_user = sync_user;
    completion(user, nil);
}

@end
