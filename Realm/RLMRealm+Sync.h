//
//  RLMRealm+RLMRealmSync.h
//  Realm
//
//  Created by Simon Ask Ulsnes on 10/06/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

#import <Realm/RLMRealm.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RLMRealmSyncIdentityProvider) {
    RLMRealmSyncIdentityProviderRealmRefresh,
    RLMRealmSyncIdentityProviderFacebook,
    RLMRealmSyncIdentityProviderDebug,
    // FIXME: TODO: Add more identity providers (Google, iCloud, ...)
};

@interface RLMRealm (Sync)
/**
 Indicate to Realm Sync that a new set of credentials have been acquired through the
 given provider. Realm Sync will use the new credentials to initiate synchronization
 for this Realm.

 FIXME: Maybe the token should be NSData instead of NSString.
 */
-(void)refreshCredendialsWithProvider:(RLMRealmSyncIdentityProvider)provider andToken:(NSString *)token withAppID:(NSString *)appID;

/**
 FIXME: Implement this.
 */
-(void)scheduleRefreshAccessToken:(NSString *)refreshToken inRunLoop:(NSRunLoop *)runloop;
@end

NS_ASSUME_NONNULL_END
