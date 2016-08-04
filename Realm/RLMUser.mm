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

#import "RLMAddRealmResponseModel.h"
#import "RLMCredential.h"
#import "RLMLoginResponseModel.h"
#import "RLMRefreshResponseModel.h"
#import "RLMSessionInfo_Private.h"
#import "RLMSync_Private.h"
#import "RLMSyncNetworkClient.h"
#import "RLMSyncPrivateUtil.h"
#import "RLMUtil.hpp"

@interface RLMUser ()

@property (nonnull, nonatomic, readwrite) NSMutableDictionary<RLMSyncPath, RLMSessionInfo *> *realms;

@property (nonatomic, readwrite) BOOL isAnonymous;
@property (nonatomic, readwrite) BOOL isLoggedIn;

@end

@implementation RLMUser

@synthesize isLoggedIn = _isLoggedIn;

+ (instancetype)defaultUser {
    static RLMUser *s_default_user;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_default_user = [[RLMUser alloc] init];
    });
    return s_default_user;
}

+ (instancetype)userForAnonymousAccount {
    RLMUser *user = [[RLMUser alloc] init];
    user.isAnonymous = YES;
    // TODO
    user.userID = @".anonymousUser";

    return user;
}

- (void)loginWithCredential:(RLMCredential *)credential
                 completion:(RLMErrorReportingBlock)completion {
    if (self.isAnonymous) {
        @throw RLMException(@"An anonymous user cannot log in. Add a credential first.");
    }
    if (self.isLoggedIn) {
        @throw RLMException(@"The user is already logged in. Cannot log in again without logging out first.");
    }
    NSURL *syncURL = credential.syncServerURL;
    if (!syncURL) {
        @throw RLMException(@"A sync server URL is required to log in, but was missing, and there is no default.");
    }
    NSURL *authURL = authURLForSyncURL(syncURL);
    self.syncURL = syncURL;
    self.authURL = authURL;

    NSMutableDictionary *json = [@{
                                   kRLMSyncProviderKey: credential.provider,
                                   kRLMSyncDataKey: credential.credentialToken,
                                   kRLMSyncAppIDKey: [RLMSync appID],
                                   } mutableCopy];
    if (credential.userInfo) {
        // Munge user info into the JSON request.
        json[@"user_info"] = credential.userInfo;
    }

    RLMErrorReportingBlock block = completion ?: ^(NSError *) { };

    __weak RLMUser *weakSelf = self;
    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        RLMUser *strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (json && !error) {
            RLMLoginResponseModel *model = [[RLMLoginResponseModel alloc] initWithJSON:json];
            if (!model) {
                // Malformed JSON
                error = [NSError errorWithDomain:RLMSyncErrorDomain
                                            code:RLMSyncErrorBadResponse
                                        userInfo:@{kRLMSyncErrorJSONKey: json}];
                block(error);
                return;
            } else {
                // Success: store the tokens.
                strongSelf.refreshToken = model.renewalTokenModel.renewalToken;
                strongSelf.refreshTokenExpiry = model.renewalTokenModel.tokenExpiry;
                strongSelf.userID = model.userID;
                strongSelf.isLoggedIn = YES;
                block(nil);
            }
        } else {
            // Something else went wrong
            block(error);
        }
    };
    [RLMSyncNetworkClient postSyncRequestToEndpoint:RLMSyncServerEndpointAuth
                                             server:authURL
                                               JSON:json
                                         completion:handler];
}

- (void)refresh {
    if (!self.isLoggedIn) {
        @throw RLMException(@"The user isn't logged in. The user must first log in before they can be refreshed.");
    }
    for (RLMSyncPath path in self.realms) {
        RLMSessionInfo *info = self.realms[path];
        [info refresh];
    }
}

- (void)logout:(BOOL)allDevices completion:(RLMErrorReportingBlock)completion {
    if (!self.isLoggedIn) {
        @throw RLMException(@"The user isn't logged in. The user must first log in before they log out.");
    }
    // TODO: api does not actually exist yet
    NSDictionary *json = @{
                           @"allDevices": @(allDevices),
                           };

    self.isLoggedIn = NO;
    // TODO: unbind all associated Realms

    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *) {
        if (completion) {
            completion(error);
        }
    };
    [RLMSyncNetworkClient postSyncRequestToEndpoint:RLMSyncServerEndpointLogout
                                             server:self.authURL
                                               JSON:json
                                         completion:handler];
}

- (void)addCredential:(RLMCredential *)credential
           completion:(RLMErrorReportingBlock)completion {
    if (!self.isLoggedIn) {
        @throw RLMException(@"The user isn't logged in. The user must first log in before they add a credential.");
    }
    // TODO: api does not actually exist yet
    NSDictionary *json = @{
                           kRLMSyncProviderKey: credential.provider,
                           kRLMSyncDataKey: credential.credentialToken,
                           };

    __weak RLMUser *weakSelf = self;
    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *) {
        RLMUser *strongSelf = weakSelf;
        if (!strongSelf) { return; }
        // TODO: if user is anonymous, promote to normal user.
        // TODO: if anonymous user was promoted, bind any Realms that were associated.
        if (completion) {
            completion(error);
        }
    };
    [RLMSyncNetworkClient postSyncRequestToEndpoint:RLMSyncServerEndpointLogout
                                             server:self.authURL
                                               JSON:json
                                         completion:handler];
}

- (void)removeCredential:(RLMCredential *)credential
              completion:(RLMErrorReportingBlock)completion {
    if (!self.isLoggedIn) {
        @throw RLMException(@"The user isn't logged in. The user must first log in before they remove a credential.");
    }
    // TODO: api does not actually exist yet
    NSDictionary *json = @{
                           kRLMSyncProviderKey: credential.provider,
                           kRLMSyncDataKey: credential.credentialToken,
                           };

    __weak RLMUser *weakSelf = self;
    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *) {
        RLMUser *strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (completion) {
            completion(error);
        }
    };
    [RLMSyncNetworkClient postSyncRequestToEndpoint:RLMSyncServerEndpointLogout
                                             server:self.authURL
                                               JSON:json
                                         completion:handler];
}

- (instancetype)init {
    if (self = [super init]) {
        self.isAnonymous = NO;
        self.isLoggedIn = NO;
        self.refreshTokenExpiry = 0;
        self.realms = [NSMutableDictionary dictionary];
    }
    return self;
}


#pragma mark - Private

// A callback handler for a Realm, used to get an updated access token which can then be used to bind the Realm.
- (void)_bindRealmWithLocalFileURL:(const std::string&)fileURL remoteSyncURL:(NSURL *)remoteURL {
    if (!self.isLoggedIn) {
        // TODO (az-sync): should this be more forgiving? Throwing an exception may be too extreme
        @throw RLMException(@"The user is no longer logged in. Cannot open the Realm");
    }
    if (self.isAnonymous /* && 'user has not yet added a credential' */) {
        // Anonymous accounts' Realms are not bound until they are converted to real accounts.
        return;
    }

    NSURL *objcFileURL = [NSURL fileURLWithPath:@(fileURL.c_str())];
    NSString *objcRemotePath = [remoteURL path];

    NSDictionary *json = @{
                           kRLMSyncPathKey: objcRemotePath,
                           kRLMSyncProviderKey: @"realm",
                           kRLMSyncDataKey: self.refreshToken,
                           kRLMSyncAppIDKey: [RLMSync appID],
                           };

    __weak RLMUser *weakSelf = self;
    RLMSyncCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        RLMUser *strongSelf = weakSelf;
        if (!strongSelf) { return; }
        if (json && !error) {
            RLMAddRealmResponseModel *model = [[RLMAddRealmResponseModel alloc] initWithJSON:json];
            if (!model) {
                // Malformed JSON
                error = [NSError errorWithDomain:RLMSyncErrorDomain
                                            code:RLMSyncErrorBadResponse
                                        userInfo:@{kRLMSyncErrorJSONKey: json}];
                // TODO (az-sync): report global error
                return;
            } else {
                // Success
                NSString *accessToken = model.accessToken;

                // Register the Realm as being linked to this User.
                RLMSyncPath fullPath = model.fullPath;
                RLMSessionInfo *info = [[RLMSessionInfo alloc] initWithFileURL:objcFileURL path:objcRemotePath];
                [strongSelf.realms setValue:info forKey:objcRemotePath];

                // Per-Realm access token stuff
                [info configureWithAccessToken:accessToken expiry:model.accessTokenExpiry user:self];

                // Bind the Realm
                NSURL *objcRealmURL = [NSURL URLWithString:fullPath relativeToURL:strongSelf.syncURL];
                auto full_realm_url = realm::util::Optional<std::string>([[objcRealmURL absoluteString] UTF8String]);
                realm::Realm::refresh_sync_access_token(std::string([accessToken UTF8String]),
                                                        fileURL,
                                                        full_realm_url);
            }
        } else {
            // Something else went wrong
            // TODO (az-sync): report global error, and update self state
        }
    };
    [RLMSyncNetworkClient postSyncRequestToEndpoint:RLMSyncServerEndpointAuth
                                             server:self.authURL
                                               JSON:json
                                         completion:handler];
}

- (void)_reportRefreshFailureForPath:(RLMSyncPath)path error:(NSError *)error {
    NSLog(@"Realm at path %@ could not be refreshed properly. Error: %@", path, error);
}

- (void)setIsLoggedIn:(BOOL)isLoggedIn {
    _isLoggedIn = isLoggedIn;
    if (!isLoggedIn) {
        self.authURL = nil;
        self.syncURL = nil;
        self.refreshToken = nil;
    }
}

@end
