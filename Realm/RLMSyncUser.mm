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
#import "RLMSyncConfiguration_Private.hpp"
#import "RLMSyncManager_Private.hpp"
#import "RLMSyncSession_Private.h"
#import "RLMSyncSessionHandle.hpp"
#import "RLMTokenModels.h"
#import "RLMUtil.hpp"

#import "sync_manager.hpp"
#import "sync_metadata.hpp"
#import "sync_session.hpp"

using namespace realm;

@interface RLMSyncUser ()

- (instancetype)initWithAuthServer:(nullable NSURL *)authServer NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readwrite) RLMSyncUserState state;

@property (nonatomic, readwrite) NSString *identity;
@property (nonatomic, readwrite) NSURL *authenticationServer;

@property (nonatomic) NSMutableDictionary<NSURL *, RLMSyncSession *> *sessionsStorage;
@property (nonatomic) NSDictionary<NSURL *, RLMSyncSession *> *loggedOutSessions;

@property (nonatomic) RLMServerToken directAccessToken;

@end

@implementation RLMSyncUser

#pragma mark - static API

+ (NSArray *)all {
    return [[RLMSyncManager sharedManager] _allUsers];
}

#pragma mark - API

- (instancetype)initWithAuthServer:(nullable NSURL *)authServer {
    if (self = [super init]) {
        self.state = RLMSyncUserStateLoggedOut;
        self.directAccessToken = nil;
        self.authenticationServer = authServer;
        self.sessionsStorage = [NSMutableDictionary dictionary];
        // NOTE: If we add support for anonymous users, we will need to register the user to the global user store
        // when the user is first created, versus when the user logs in.
        return self;
    }
    return nil;
}

+ (void)authenticateWithCredential:(RLMSyncCredential *)credential
                     authServerURL:(NSURL *)authServerURL
                      onCompletion:(RLMUserCompletionBlock)completion {
    [self authenticateWithCredential:credential
                       authServerURL:authServerURL
                             timeout:30
                        onCompletion:completion];
}

+ (void)authenticateWithCredential:(RLMSyncCredential *)credential
                     authServerURL:(NSURL *)authServerURL
                           timeout:(NSTimeInterval)timeout
                      onCompletion:(RLMUserCompletionBlock)completion {
    RLMSyncUser *user = [[RLMSyncUser alloc] initWithAuthServer:authServerURL];
    [RLMSyncUser _performLogInForUser:user
                           credential:credential
                        authServerURL:authServerURL
                              timeout:timeout
                      completionBlock:completion];
}

- (void)logOut {
    if (self.state != RLMSyncUserStateActive || !self.identity) {
        // FIXME: report a warning to the global error handler?
        return;
    }
    self.state = RLMSyncUserStateLoggedOut;
    for (NSURL *url in self.sessionsStorage) {
        [self.sessionsStorage[url] _logOut];
    }
    self.loggedOutSessions = [self.sessionsStorage copy];
    self.sessionsStorage = [NSMutableDictionary dictionary];
    [[RLMSyncManager sharedManager] _deregisterLoggedOutUser:self];
    auto metadata = SyncUserMetadata([[RLMSyncManager sharedManager] _metadataManager],
                                     [self.identity UTF8String],
                                     false);
    metadata.mark_for_removal();
}

- (nullable RLMSyncSession *)sessionForURL:(NSURL *)url {
    RLMSyncSession *session = [self.sessionsStorage objectForKey:url];
    RLMSyncSessionHandle *handle = [session sessionHandle];
    if (handle && ![handle sessionStillExists]) {
        [self.sessionsStorage removeObjectForKey:url];
        return nil;
    } else if ([handle sessionIsInErrorState]) {
        [session _invalidate];
        return nil;
    }
    return session;
}

- (NSArray<RLMSyncSession *> *)allSessions {
    NSMutableArray<RLMSyncSession *> *buffer = [NSMutableArray arrayWithCapacity:self.sessionsStorage.count];
    NSArray<NSURL *> *allURLs = [self.sessionsStorage allKeys];
    for (NSURL *url in allURLs) {
        RLMSyncSession *session = [self sessionForURL:url];
        if (session) {
            [buffer addObject:session];
        }
    }
    return [buffer copy];
}


#pragma mark - Private API

- (void)_enterErrorState {
    self.state = RLMSyncUserStateError;
}

- (void)_enterActiveState {
    self.state = RLMSyncUserStateActive;
}

- (void)_deregisterSessionWithRealmURL:(NSURL *)realmURL {
    [self.sessionsStorage removeObjectForKey:realmURL];
}
    
- (instancetype)initWithMetadata:(SyncUserMetadata)metadata {
    NSURL *url = nil;
    if (metadata.server_url()) {
        url = [NSURL URLWithString:@(metadata.server_url()->c_str())];
    }
    self = [self initWithAuthServer:url];
    self.identity = @(metadata.identity().c_str());
    if (auto user_token = metadata.user_token()) {
        // FIXME: Once the new auth system is enabled, rename "refreshToken" to "userToken" to reflect its new role.
        self.refreshToken = @(user_token->c_str());
        self.state = RLMSyncUserStateActive;
    } else {
        // For now, throw an exception. In the future we may want to allow for "anonymous" style users.
        @throw RLMException(@"Invalid persisted user: there must be a valid access token.");
    }
    return self;
}

- (void)_updatePersistedMetadata {
    if (!self.refreshToken) {
        // For now, throw an exception. In the future we may want to allow for "anonymous" style users.
        @throw RLMException(@"Invalid persisted user: there must be a valid access token.");
    }

    NSURL *authServer = self.authenticationServer;
    NSString *refreshToken = self.refreshToken;
    auto server = authServer ? util::Optional<std::string>([[authServer absoluteString] UTF8String]) : none;
    auto token = refreshToken ? util::Optional<std::string>([refreshToken UTF8String]) : none;
    auto metadata = SyncUserMetadata([[RLMSyncManager sharedManager] _metadataManager], [self.identity UTF8String]);
    metadata.set_state(server, token);
}

+ (void)_performLogInForUser:(RLMSyncUser *)user
                  credential:(RLMSyncCredential *)credential
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
    if (credential.provider == RLMIdentityProviderAccessToken) {
        [self _performLoginForDirectAccessTokenCredential:credential user:user completionBlock:theBlock];
        return;
    }

    // Prepare login network request
    NSMutableDictionary *json = [@{
                                   kRLMSyncProviderKey: credential.provider,
                                   kRLMSyncDataKey: credential.token,
                                   kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                                   } mutableCopy];
    NSMutableDictionary *info = [(credential.userInfo ?: @{}) mutableCopy];

    if (credential.provider == RLMIdentityProviderUsernamePassword) {
        RLMAuthenticationActions actions = [info[kRLMSyncActionsKey] integerValue];
        if (actions & RLMAuthenticationActionsCreateAccount) {
            info[kRLMSyncRegisterKey] = @(YES);
        }
    }

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
                // Success: store the tokens.
                user.identity = model.refreshToken.tokenData.identity;
                user.refreshToken = model.refreshToken.token;
                RLMSyncUser *existingUser = [[RLMSyncManager sharedManager] _registerUser:user];
                RLMSyncUser *actualUser = existingUser ?: user;
                if (existingUser) {
                    [actualUser _mergeDataFromDuplicateUser:user];
                }
                actualUser.state = RLMSyncUserStateActive;
                [actualUser _updatePersistedMetadata];
                [actualUser _bindAllDeferredRealms];
                theBlock(actualUser, nil);
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

+ (void)_performLoginForDirectAccessTokenCredential:(RLMSyncCredential *)credential
                                               user:(RLMSyncUser *)user
                                    completionBlock:(nonnull RLMUserCompletionBlock)completion {
    user.directAccessToken = credential.token;
    NSString *identity = credential.userInfo[kRLMSyncIdentityKey];
    NSAssert(identity != nil, @"Improperly created direct access token credential.");
    user.identity = identity;
    RLMSyncUser *existingUser = [[RLMSyncManager sharedManager] _registerUser:user];
    RLMSyncUser *actualUser = existingUser ?: user;
    if (existingUser) {
        [actualUser _mergeDataFromDuplicateUser:user];
    }
    actualUser.state = RLMSyncUserStateActive;
    [actualUser _bindAllDeferredRealms];
    completion(actualUser, nil);
}

/**
 The argument to this method represents a duplicate, not-yet-active user; the receiver is an existing user. Merge the
 state of the duplicate user into the existing user, including the most up-to-date tokens and any sessions that are
 waiting to be activated.
 */
- (void)_mergeDataFromDuplicateUser:(RLMSyncUser *)user {
    NSAssert(user.state != RLMSyncUserStateActive, @"Erroneous user-to-be-merged: user can't be active.");
    NSAssert([self.identity isEqualToString:user.identity], @"Logic error: can only merge two equivalent users.");

    self.directAccessToken = user.directAccessToken;
    self.refreshToken = user.refreshToken;
    // Move over any sessions that are waiting to be started up.
    for (NSURL *url in user.sessionsStorage) {
        RLMSyncSession *session = [user.sessionsStorage objectForKey:url];
        NSAssert(session.state != RLMSyncSessionStateActive,
                 @"Logic error: a newly-created user can't have active sessions.");
        if (session.state == RLMSyncSessionStateUnbound) {
            [self.sessionsStorage setObject:session forKey:url];
        }
    }
}

// Upon successfully logging in, bind any Realm which was opened and registered to the user previously.
- (void)_bindAllDeferredRealms {
    NSAssert(self.state == RLMSyncUserStateActive,
             @"_bindAllDeferredRealms can't be called unless the user is logged in.");
    for (NSURL *key in self.sessionsStorage) {
        RLMSyncSession *session = self.sessionsStorage[key];
        RLMSessionBindingPackage *package = session.deferredBindingPackage;
        if (session.state == RLMSyncSessionStateUnbound && package) {
            [self _bindSessionWithLocalFileURL:package.fileURL
                                    syncConfig:package.syncConfig
                                    standalone:package.isStandalone
                                  onCompletion:package.block];
        }
    }
    for (NSURL *key in self.loggedOutSessions) {
        RLMSyncSession *session = self.loggedOutSessions[key];
        RLMSyncSessionHandle *handle = session.sessionHandle;
        if ([handle sessionStillExists] && ![handle sessionIsInErrorState]) {
            // If the session still exists, there's at least one strong reference to it somewhere. Revive it.
            // This will start the login handshake if necessary.
            [handle revive];
        }
        self.sessionsStorage[key] = session;
    }
    self.loggedOutSessions = nil;
}

- (void)_bindSessionWithDirectAccessToken:(RLMServerToken)accessToken
                               syncConfig:(RLMSyncConfiguration *)syncConfig
                             localFileURL:(NSURL *)fileURL
                               standalone:(BOOL)isStandalone
                             onCompletion:(RLMSyncBasicErrorReportingBlock)completion {
    NSURL *realmURL = syncConfig.realmURL;
    RLMSyncSession *session = self.sessionsStorage[realmURL];
    std::string file_path = [[fileURL path] UTF8String];
    std::string realm_url = [[realmURL absoluteString] UTF8String];

    RLMSyncSessionHandle *sessionHandle;
    auto underlyingSession = SyncManager::shared().get_session(file_path, syncConfig.rawConfiguration);
    if (isStandalone) {
        sessionHandle = [RLMSyncSessionHandle syncSessionHandleForPointer:underlyingSession];
    } else {
        sessionHandle = [RLMSyncSessionHandle syncSessionHandleForWeakPointer:underlyingSession];
    }
    [session configureWithAccessToken:accessToken
                               expiry:[[NSDate distantFuture] timeIntervalSince1970]
                                 user:self
                               handle:sessionHandle];
    [session refreshAccessToken:accessToken serverURL:realmURL];

    if (completion) {
        bool success = session.state != RLMSyncSessionStateInvalid;
        completion(success ? nil : [NSError errorWithDomain:RLMSyncErrorDomain
                                                       code:RLMSyncErrorClientSessionError
                                                   userInfo:nil]);
    }
}

// Immediately begin the handshake to get the resolved remote path and the access token.
- (void)_bindSessionWithLocalFileURL:(NSURL *)fileURL
                          syncConfig:(RLMSyncConfiguration *)syncConfig
                          standalone:(BOOL)isStandalone
                        onCompletion:(RLMSyncBasicErrorReportingBlock)completion {
    if (self.directAccessToken) {
        /// Like with the normal authentication methods below, make binding asynchronous so we don't recursively
        /// try to acquire the session lock.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self _bindSessionWithDirectAccessToken:self.directAccessToken
                                         syncConfig:syncConfig
                                       localFileURL:fileURL
                                         standalone:isStandalone
                                       onCompletion:completion];
        });
        return;
    }

    NSURL *realmURL = syncConfig.realmURL;
    RLMServerPath unresolvedPath = [realmURL path];
    NSDictionary *json = @{
                           kRLMSyncPathKey: unresolvedPath,
                           kRLMSyncProviderKey: @"realm",
                           kRLMSyncDataKey: self.refreshToken,
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
            } else {
                // Success
                // For now, assume just one access token.
                std::string file_path = [[fileURL path] UTF8String];
                RLMTokenModel *tokenModel = model.accessToken;
                NSString *accessToken = tokenModel.token;

                // Register the Realm as being linked to this User.
                RLMServerPath resolvedPath = tokenModel.tokenData.path;
                RLMSyncSession *session = [self.sessionsStorage objectForKey:realmURL];
                session.resolvedPath = resolvedPath;
                NSAssert(session,
                         @"Could not get a sync session object for the path '%@', this is an error",
                         unresolvedPath);
                RLMSyncSessionHandle *sessionHandle;
                auto underlyingSession = SyncManager::shared().get_session(file_path, syncConfig.rawConfiguration);
                if (isStandalone) {
                    sessionHandle = [RLMSyncSessionHandle syncSessionHandleForPointer:underlyingSession];
                } else {
                    sessionHandle = [RLMSyncSessionHandle syncSessionHandleForWeakPointer:underlyingSession];
                }
                [session configureWithAccessToken:accessToken
                                           expiry:tokenModel.tokenData.expires
                                             user:self
                                           handle:sessionHandle];

                // Bind the Realm
                NSURLComponents *urlBuffer = [NSURLComponents componentsWithURL:realmURL resolvingAgainstBaseURL:YES];
                urlBuffer.path = resolvedPath;
                NSURL *resolvedURL = [urlBuffer URL];
                if (!resolvedURL) {
                    @throw RLMException(@"Resolved path returned from the server was invalid (%@).", resolvedPath);
                }
                [session refreshAccessToken:accessToken serverURL:resolvedURL];

                if (completion) {
                    bool success = session.state != RLMSyncSessionStateInvalid;
                    completion(success ? nil : [NSError errorWithDomain:RLMSyncErrorDomain
                                                                   code:RLMSyncErrorClientSessionError
                                                               userInfo:nil]);
                }
            }
        } else {
            // Something else went wrong
            NSError *syncError = [NSError errorWithDomain:RLMSyncErrorDomain
                                                     code:RLMSyncErrorBadResponse
                                                 userInfo:@{kRLMSyncUnderlyingErrorKey: error}];
            if (completion) {
                completion(syncError);
            }
            [[RLMSyncManager sharedManager] _fireError:syncError];
        }
    };
    [RLMNetworkClient postRequestToEndpoint:RLMServerEndpointAuth
                                     server:self.authenticationServer
                                       JSON:json
                                 completion:handler];
}

// A callback handler for a Realm, used to get an updated access token which can then be used to bind the Realm.
- (RLMSyncSession *)_registerSessionForBindingWithFileURL:(NSURL *)fileURL
                                               syncConfig:(RLMSyncConfiguration *)syncConfig
                                        standaloneSession:(BOOL)isStandalone
                                             onCompletion:(nullable RLMSyncBasicErrorReportingBlock)completion {
    NSURL *realmURL = syncConfig.realmURL;
    if (RLMSyncSession *session = [self.sessionsStorage objectForKey:realmURL]) {
        RLMSyncSessionHandle *handle = [session sessionHandle];
        // The Realm at this particular path has already been registered to this user.
        if ([handle sessionStillExists]) {
            [session _refresh];
            if (completion) {
                completion(nil);
            }
            return session;
        } else if ([handle sessionIsInErrorState]) {
            // Prohibit registering an invalid session.
            if (completion) {
                NSError *error = [NSError errorWithDomain:RLMSyncErrorDomain
                                                     code:RLMSyncErrorClientSessionError
                                                 userInfo:nil];
                completion(error);
            }
            return nil;
        }
    }

    RLMSyncSession *session = [[RLMSyncSession alloc] initWithFileURL:fileURL realmURL:realmURL];
    self.sessionsStorage[realmURL] = session;

    if (self.state == RLMSyncUserStateLoggedOut) {
        // We will delay the path resolution/access token handshake until the user logs in.
        session.deferredBindingPackage = [[RLMSessionBindingPackage alloc] initWithFileURL:fileURL
                                                                                syncConfig:syncConfig
                                                                                standalone:isStandalone
                                                                                     block:completion];
    } else {
        // User is logged in, start the handshake immediately.
        [self _bindSessionWithLocalFileURL:fileURL
                                syncConfig:syncConfig
                                standalone:isStandalone
                              onCompletion:completion];
    }
    return session;
}

@end
