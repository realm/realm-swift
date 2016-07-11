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

#import <Realm/RLMRealm.h>

@class RLMSyncSession;

typedef NS_ENUM(NSUInteger, RLMSyncIdentityProvider) {
    RLMRealmSyncIdentityProviderRealm,
    RLMRealmSyncIdentityProviderFacebook,
    RLMRealmSyncIdentityProviderTwitter,
    RLMRealmSyncIdentityProviderGoogle,
    RLMRealmSyncIdentityProviderICloud,
    RLMRealmSyncIdentityProviderDebug,
    // FIXME: add more providers as necessary...
};

typedef NSString* RLMSyncAccountID;
typedef NSString* RLMSyncToken;
typedef NSString* RLMSyncCredential;
typedef NSString* RLMSyncRealmPath;
typedef NSString* RLMSyncAppID;
typedef void(^RLMSyncCompletionBlock)(NSError * _Nullable, NSDictionary * _Nullable);

static NSString * _Nonnull const RLMSyncErrorDomain = @"io.realm.sync";

typedef NS_ENUM(NSInteger, RLMSyncError) {
    RLMSyncErrorBadResponse         = 1,
    RLMSyncErrorBadRealmPath        = 2,
};


NS_ASSUME_NONNULL_BEGIN

@interface RLMRealm (Sync)

/**
 Create a session based on a given user's identification token.
 */
- (void)createSessionForToken:(RLMSyncToken)token
                     provider:(RLMSyncIdentityProvider)provider
                        appID:(RLMSyncAppID)appID
                     userInfo:(NSDictionary *)userInfo
             shouldCreateUser:(BOOL)shouldCreateUser
                        error:(NSError **)error
                 onCompletion:(RLMSyncCompletionBlock)completionBlock;

/**
 FIXME: Implement this.
 */
-(void)scheduleRefreshAccessToken:(NSString *)refreshToken inRunLoop:(NSRunLoop *)runloop;
@end

NS_ASSUME_NONNULL_END
