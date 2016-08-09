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
#import "RLMServer_Private.h"
#import "RLMServerNetworkClient.h"
#import "RLMServerUtil_Private.h"
#import "RLMUtil.hpp"

@interface RLMUser ()

@property (nonnull, nonatomic, readwrite) NSMutableDictionary<RLMServerPath, RLMSessionInfo *> *realms;

@property (nonatomic, readwrite) BOOL isLoggedIn;

@property (nonatomic, readwrite) RLMLocalIdentity localIdentity;

@end

@implementation RLMUser

@synthesize isLoggedIn = _isLoggedIn;

- (void)loginWithCredential:(RLMCredential *)credential
                 completion:(RLMErrorReportingBlock)completion {
    if (self.isLoggedIn) {
        @throw RLMException(@"The user is already logged in. Cannot log in again without logging out first.");
    }
    NSURL *objectServerURL = credential.objectServerURL;
    if (!objectServerURL) {
        @throw RLMException(@"An Realm Object Server URL is required to log in, but was missing, and there is no default.");
    }
    NSURL *authURL = RLMAuthURLForObjectServerURL(objectServerURL, credential.authServerPort);
    self.objectServerURL = objectServerURL;
    self.authURL = authURL;

    NSMutableDictionary *json = [@{
                                   kRLMServerProviderKey: credential.provider,
                                   kRLMServerDataKey: credential.credentialToken,
                                   kRLMServerAppIDKey: [RLMServer appID],
                                   } mutableCopy];
    if (credential.userInfo) {
        // Munge user info into the JSON request.
        json[@"user_info"] = credential.userInfo;
    }

    RLMErrorReportingBlock block = completion ?: ^(NSError *) { };

    RLMServerCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        if (json && !error) {
            RLMLoginResponseModel *model = [[RLMLoginResponseModel alloc] initWithJSON:json];
            if (!model) {
                // Malformed JSON
                error = [NSError errorWithDomain:RLMServerErrorDomain
                                            code:RLMServerErrorBadResponse
                                        userInfo:@{kRLMServerErrorJSONKey: json}];
                block(error);
                return;
            } else {
                // Success: store the tokens.
                self.refreshToken = model.renewalTokenModel.renewalToken;
                self.refreshTokenExpiry = model.renewalTokenModel.tokenExpiry;
                self.identity = model.identity;
                self.isLoggedIn = YES;
                [self _bindAllDeferredRealms];
                block(nil);
            }
        } else {
            // Something else went wrong
            block(error);
        }
    };
    [RLMServerNetworkClient postRequestToEndpoint:RLMServerEndpointAuth
                                           server:authURL
                                             JSON:json
                                       completion:handler];
}

- (void)refresh {
    if (!self.isLoggedIn) {
        @throw RLMException(@"The user isn't logged in. The user must first log in before they can be refreshed.");
    }
    for (RLMServerPath path in self.realms) {
        RLMSessionInfo *info = [self.realms objectForKey:path];
        if (info.isBound) {
            [info refresh];
        }
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

    RLMServerCompletionBlock handler = ^(NSError *error, NSDictionary *) {
        if (completion) {
            completion(error);
        }
    };
    [RLMServerNetworkClient postRequestToEndpoint:RLMServerEndpointLogout
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
                           kRLMServerProviderKey: credential.provider,
                           kRLMServerDataKey: credential.credentialToken,
                           };

    RLMServerCompletionBlock handler = ^(NSError *error, NSDictionary *) {
        if (completion) {
            completion(error);
        }
    };
    [RLMServerNetworkClient postRequestToEndpoint:RLMServerEndpointLogout
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
                           kRLMServerProviderKey: credential.provider,
                           kRLMServerDataKey: credential.credentialToken,
                           };

    RLMServerCompletionBlock handler = ^(NSError *error, NSDictionary *) {
        if (completion) {
            completion(error);
        }
    };
    [RLMServerNetworkClient postRequestToEndpoint:RLMServerEndpointLogout
                                           server:self.authURL
                                             JSON:json
                                       completion:handler];
}

- (instancetype)initWithLocalIdentity:(nullable RLMLocalIdentity)identity {
    if (self = [super init]) {
        self.localIdentity = identity ?: [[NSUUID UUID] UUIDString];
        self.isLoggedIn = NO;
        self.refreshTokenExpiry = 0;
        self.realms = [NSMutableDictionary dictionary];
    }
    return self;
}


#pragma mark - Private

// Upon successfully logging in, bind any Realm which was opened and registered to the user previously.
- (void)_bindAllDeferredRealms {
    NSAssert(self.isLoggedIn, @"Logic error: _bindAllDeferredRealms can't be called unless the User is logged in.");
    for (RLMServerPath key in self.realms) {
        RLMSessionInfo *info = self.realms[key];
        RLMRealmBindingPackage *package = info.deferredBindingPackage;
        if (!info.isBound && package) {
            [self _bindRealmWithLocalFileURL:package.fileURL remotePath:package.remotePath onCompletion:package.block];
        }
    }
}

// Immediately begin the handshake to get the resolved remote path and the access token.
- (void)_bindRealmWithLocalFileURL:(NSURL *)fileURL
                        remotePath:(NSString *)remotePath
                      onCompletion:(RLMErrorReportingBlock)completion {
    NSDictionary *json = @{
                           kRLMServerPathKey: remotePath,
                           kRLMServerProviderKey: @"realm",
                           kRLMServerDataKey: self.refreshToken,
                           kRLMServerAppIDKey: [RLMServer appID],
                           };

    RLMServerCompletionBlock handler = ^(NSError *error, NSDictionary *json) {
        if (json && !error) {
            RLMAddRealmResponseModel *model = [[RLMAddRealmResponseModel alloc] initWithJSON:json];
            if (!model) {
                // Malformed JSON
                error = [NSError errorWithDomain:RLMServerErrorDomain
                                            code:RLMServerErrorBadResponse
                                        userInfo:@{kRLMServerErrorJSONKey: json}];
                // TODO (az-ros): report global error
                return;
            } else {
                // Success
                NSString *accessToken = model.accessToken;

                // Register the Realm as being linked to this User.
                RLMServerPath fullPath = model.fullPath;
                RLMSessionInfo *info = [self.realms objectForKey:remotePath];
                NSAssert(info, @"Could not get a session info object for the path '%@', this is an error", remotePath);

                // Per-Realm access token stuff
                [info configureWithAccessToken:accessToken expiry:model.accessTokenExpiry user:self];

                // Bind the Realm
                NSURL *objcRealmURL = [NSURL URLWithString:fullPath relativeToURL:self.objectServerURL];
                auto full_realm_url = realm::util::Optional<std::string>([[objcRealmURL absoluteString] UTF8String]);
                auto file_url = RLMStringDataWithNSString([fileURL path]);
                bool success = realm::Realm::refresh_sync_access_token(std::string([accessToken UTF8String]),
                                                                       file_url,
                                                                       full_realm_url);
                info.isBound = success;
                info.deferredBindingPackage = nil;
                // TODO (az-ros): What to do about failed bindings? How can the user manually retry?
                if (completion) {
                    if (success) {
                        completion(nil);
                    } else {
                        completion([NSError errorWithDomain:RLMServerErrorDomain
                                                       code:RLMServerInternalError
                                                   userInfo:nil]);
                    }
                }
            }
        } else {
            // Something else went wrong
            // TODO (az-ros): report global error, and update self state
        }
    };
    [RLMServerNetworkClient postRequestToEndpoint:RLMServerEndpointAuth
                                           server:self.authURL
                                             JSON:json
                                       completion:handler];
}

// A callback handler for a Realm, used to get an updated access token which can then be used to bind the Realm.
- (void)_registerRealmForBindingWithFileURL:(const std::string&)fileURL
                            remoteServerURL:(NSURL *)remoteURL
                               onCompletion:(RLMErrorReportingBlock)completion {
    NSURL *objcFileURL = [NSURL fileURLWithPath:@(fileURL.c_str())];
    NSString *objcRemotePath = [remoteURL path];

    if ([self.realms objectForKey:objcRemotePath]) {
        // The Realm at this particular path has already been registered to this user.
        return;
    }

    RLMSessionInfo *info = [[RLMSessionInfo alloc] initWithFileURL:objcFileURL path:objcRemotePath];
    [self.realms setValue:info forKey:objcRemotePath];
    info.isBound = NO;

    if (!self.isLoggedIn) {
        // We will delay the path resolution/access token handshake until the user logs in
        info.deferredBindingPackage = [[RLMRealmBindingPackage alloc] initWithFileURL:objcFileURL
                                                                           remotePath:objcRemotePath
                                                                                block:completion];
    } else {
        // User is logged in, start the handshake immediately.
        [self _bindRealmWithLocalFileURL:objcFileURL remotePath:objcRemotePath onCompletion:completion];
    }
}

- (void)_reportRefreshFailureForPath:(RLMServerPath)path error:(NSError *)error {
    NSLog(@"Realm at path %@ could not be refreshed properly. Error: %@", path, error);
}

- (void)setIsLoggedIn:(BOOL)isLoggedIn {
    _isLoggedIn = isLoggedIn;
    if (!isLoggedIn) {
        self.authURL = nil;
        self.objectServerURL = nil;
        self.refreshToken = nil;
    }
}

@end
