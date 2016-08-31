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

#import "RLMUser_Private.h"

#import "RLMAuthResponseModel.h"
#import "RLMNetworkClient.h"
#import "RLMSyncManager_Private.h"
#import "RLMSyncSession_Private.h"
#import "RLMSyncUtil_Private.h"
#import "RLMTokenModels.h"
#import "RLMUtil.hpp"

@interface RLMUser ()

- (instancetype)initWithAuthServer:(nullable NSURL *)authServer NS_DESIGNATED_INITIALIZER;

@property (nonatomic) BOOL isAnonymous;
@property (nonatomic, readwrite) RLMIdentity identity;
@property (nonatomic, readwrite) NSURL *authenticationServer;

@property (nonatomic) NSMutableDictionary<NSURL *, RLMSyncSession *> *sessionsStorage;

@property (nonatomic) RLMServerToken directAccessToken;

@end

@implementation RLMUser

#pragma mark - static API

+ (NSArray *)all {
    return [[RLMSyncManager sharedManager] _allUsers];
}

#pragma mark - API

- (instancetype)initWithAuthServer:(nullable NSURL *)authServer {
    if (self = [super init]) {
        self.isAnonymous = YES;
        self.directAccessToken = nil;
        self.authenticationServer = authServer;
        self.sessionsStorage = [NSMutableDictionary dictionary];
        // NOTE: If we add support for anonymous users, we will need to register the user to the global user store
        // when the user is first created, versus when the user logs in.
        return self;
    }
    return nil;
}

+ (instancetype)userWithAccessToken:(RLMServerToken)accessToken identity:(nullable NSString *)identity {
    RLMUser *user = [[RLMUser alloc] initWithAuthServer:nil];
    user.directAccessToken = accessToken;
    user.isAnonymous = NO;
    user.identity = identity ?: [[NSUUID UUID] UUIDString];
    return user;
}

+ (void)authenticateWithCredential:(RLMCredential *)credential
                           actions:(RLMAuthenticationActions)actions
                     authServerURL:(NSURL *)authServerURL
                      onCompletion:(RLMUserCompletionBlock)completion {
    [self authenticateWithCredential:credential
                             actions:actions
                       authServerURL:authServerURL
                             timeout:30
                        onCompletion:completion];
}

+ (void)authenticateWithCredential:(RLMCredential *)credential
                            actions:(RLMAuthenticationActions)actions
                     authServerURL:(NSURL *)authServerURL
                           timeout:(NSTimeInterval)timeout
                      onCompletion:(RLMUserCompletionBlock)completion {
    RLMUser *user = [[RLMUser alloc] initWithAuthServer:authServerURL];
    [RLMUser _performLogInForUser:user
                       credential:credential
                          actions:actions
                    authServerURL:authServerURL
                          timeout:timeout
                  completionBlock:completion];

}

- (void)logOut {
    // TODO: (az-sync) move the file management stuff into its own class so we can nuke the user's folder
    [[RLMSyncManager sharedManager] _deregisterUser:self];
}

- (NSDictionary<NSURL *, RLMSyncSession *> *)sessions {
    return [self.sessionsStorage copy];
}


#pragma mark - Private API

+ (void)_performLogInForUser:(RLMUser *)user
                  credential:(RLMCredential *)credential
                     actions:(RLMAuthenticationActions)actions
               authServerURL:(NSURL *)authServerURL
                     timeout:(NSTimeInterval)timeout
             completionBlock:(RLMUserCompletionBlock)completion {
    // Wrap the completion block.
    RLMUserCompletionBlock theBlock = ^(RLMUser *user, NSError *error){
        if (!completion) { return; }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(user, error);
        });
    };

    // Prepare login network request
    NSMutableDictionary *json = [@{
                                   kRLMSyncProviderKey: credential.provider,
                                   kRLMSyncDataKey: credential.token,
                                   kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                                   } mutableCopy];
    NSMutableDictionary *info = [(credential.userInfo ?: @{}) mutableCopy];

    // FIXME: handle the 'actions' flag for the general case (not just username/password)
    if (credential.provider == RLMIdentityProviderUsernamePassword
        && (actions & RLMAuthenticationActionsCreateAccount)) {
        info[kRLMSyncRegisterKey] = @(YES);
    }

    if ([info count] > 0) {
        // Munge user info into the JSON request.
        json[@"user_info"] = info;
    }

    RLMServerCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        if (json && !error) {
            RLMAuthResponseModel *model = [[RLMAuthResponseModel alloc] initWithJSON:json
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
                [[RLMSyncManager sharedManager] _registerUser:user];
                user.isAnonymous = NO;
                [user _bindAllDeferredRealms];
                theBlock(user, nil);
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

// Upon successfully logging in, bind any Realm which was opened and registered to the user previously.
- (void)_bindAllDeferredRealms {
    NSAssert(!self.isAnonymous, @"Logic error: _bindAllDeferredRealms can't be called unless the User is logged in.");
    for (NSURL *key in self.sessionsStorage) {
        RLMSyncSession *info = self.sessionsStorage[key];
        RLMRealmBindingPackage *package = info.deferredBindingPackage;
        if (!info.isBound && package) {
            [self _bindRealmWithLocalFileURL:package.fileURL realmURL:package.realmURL onCompletion:package.block];
        }
    }
}

// Immediately begin the handshake to get the resolved remote path and the access token.
- (void)_bindRealmWithLocalFileURL:(NSURL *)fileURL
                          realmURL:(NSURL *)realmURL
                      onCompletion:(RLMErrorReportingBlock)completion {
    RLMServerPath unresolvedPath = [realmURL path];
    NSDictionary *json = @{
                           kRLMSyncPathKey: unresolvedPath,
                           kRLMSyncProviderKey: @"realm",
                           kRLMSyncDataKey: self.refreshToken,
                           kRLMSyncAppIDKey: [RLMSyncManager sharedManager].appID,
                           };

    RLMServerCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        if (json && !error) {
            RLMAuthResponseModel *model = [[RLMAuthResponseModel alloc] initWithJSON:json
                                                                  requireAccessToken:YES
                                                                 requireRefreshToken:NO];
            if (!model) {
                // Malformed JSON
                error = [NSError errorWithDomain:RLMSyncErrorDomain
                                            code:RLMSyncErrorBadResponse
                                        userInfo:@{kRLMSyncErrorJSONKey: json}];
                // TODO (az-ros): report global error
                return;
            } else {
                // Success
                // For now, assume just one access token.
                RLMTokenModel *tokenModel = model.accessToken;
                NSString *accessToken = tokenModel.token;

                // Register the Realm as being linked to this User.
                RLMServerPath resolvedPath = tokenModel.tokenData.path;
                RLMSyncSession *info = [self.sessionsStorage objectForKey:realmURL];
                info.resolvedPath = resolvedPath;
                NSAssert(info,
                         @"Could not get a session info object for the path '%@', this is an error",
                         unresolvedPath);

                [info configureWithAccessToken:accessToken expiry:tokenModel.tokenData.expires user:self];

                // Bind the Realm
                 NSURLComponents *urlBuffer = [NSURLComponents componentsWithURL:realmURL resolvingAgainstBaseURL:YES];
                urlBuffer.path = resolvedPath;
                NSURL *resolvedURL = [urlBuffer URL];
                if (!resolvedURL) {
                    @throw RLMException(@"Resolved path returned from the server was invalid (%@).", resolvedPath);
                }
                std::string resolved_realm_url = [[resolvedURL absoluteString] UTF8String];
                bool success = realm::Realm::refresh_sync_access_token([accessToken UTF8String],
                                                                       RLMStringDataWithNSString([fileURL path]),
                                                                       resolved_realm_url);
                info.isBound = success;
                info.deferredBindingPackage = nil;
                // TODO (az-ros): What to do about failed bindings? How can the user manually retry?
                if (completion) {
                    if (success) {
                        completion(nil);
                    } else {
                        completion([NSError errorWithDomain:RLMSyncErrorDomain
                                                       code:RLMSyncInternalError
                                                   userInfo:nil]);
                    }
                }
            }
        } else {
            // Something else went wrong
            // TODO (az-ros): report global error, and update self state
        }
    };
    [RLMNetworkClient postRequestToEndpoint:RLMServerEndpointAuth
                                     server:self.authenticationServer
                                       JSON:json
                                 completion:handler];
}

// A callback handler for a Realm, used to get an updated access token which can then be used to bind the Realm.
- (void)_registerRealmForBindingWithFileURL:(NSURL *)fileURL
                                   realmURL:(NSURL *)realmURL
                               onCompletion:(nullable RLMErrorReportingBlock)completion {
    if ([self.sessionsStorage objectForKey:realmURL]) {
        // The Realm at this particular path has already been registered to this user.
        return;
    }

    RLMSyncSession *info = [[RLMSyncSession alloc] initWithFileURL:fileURL];
    self.sessionsStorage[realmURL] = info;
    info.isBound = NO;

    if (self.directAccessToken) {
        // Special case for when the access token is provided by the host app.
        std::string realm_url = [[realmURL absoluteString] UTF8String];
        bool success = realm::Realm::refresh_sync_access_token(std::string([self.directAccessToken UTF8String]),
                                                               RLMStringDataWithNSString([fileURL path]),
                                                               realm_url);
        [info configureWithAccessToken:self.directAccessToken
                                expiry:[[NSDate distantFuture] timeIntervalSince1970]
                                  user:self];
        info.isBound = success;
        if (completion) {
            if (success) {
                completion(nil);
            } else {
                completion([NSError errorWithDomain:RLMSyncErrorDomain
                                               code:RLMSyncInternalError
                                           userInfo:nil]);
            }
        }
        return;
    }

    if (self.isAnonymous) {
        // We will delay the path resolution/access token handshake until the user logs in
        info.deferredBindingPackage = [[RLMRealmBindingPackage alloc] initWithFileURL:fileURL
                                                                             realmURL:realmURL
                                                                                block:completion];
    } else {
        // User is logged in, start the handshake immediately.
        [self _bindRealmWithLocalFileURL:fileURL realmURL:realmURL onCompletion:completion];
    }
}

#pragma mark - Temporary API

- (instancetype)initWithIdentity:(NSString *)identity
                    refreshToken:(RLMServerToken)refreshToken
                   authServerURL:(NSURL *)authServerURL {
    if (self = [self initWithAuthServer:authServerURL]) {
        self.refreshToken = refreshToken;
        self.identity = identity;
        self.isAnonymous = NO;
        [[RLMSyncManager sharedManager] _registerUser:self];
    }
    return self;
}

@end
