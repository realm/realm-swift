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

#import <Foundation/Foundation.h>

#import "RLMSyncUtil.h"

NS_ASSUME_NONNULL_BEGIN

/**
 `RLMSyncUser` encapsulates login information for a single user and auth provider.

 The host application or helper library should create one of these objects once a user has successfully received a
 credential from an auth provider, and pass it into the appropriate API functions to open a Realm.
 */
@interface RLMCredential : NSObject

@property (nonatomic, readonly) RLMCredentialToken credentialToken;
@property (nonatomic, readonly) RLMSyncIdentityProvider provider;
@property (nullable, nonatomic, readonly) NSDictionary *userInfo;

@property (nullable, nonatomic) NSURL *syncServerURL;

+ (void)setDefaultSyncServerURL:(NSURL *)url;

- (instancetype)initWithCredentialToken:(RLMCredentialToken)credentialToken
                               provider:(RLMSyncIdentityProvider)provider
                               userInfo:(nullable NSDictionary *)userInfo NS_DESIGNATED_INITIALIZER;

// Convenience factory methods

+ (instancetype)credentialWithUsername:(NSString *)username
                              password:(NSString *)password
                      createNewAccount:(BOOL)isNewAccount;

+ (instancetype)credentialWithFacebookToken:(NSString *)facebookToken;

// Miscellaneous

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
