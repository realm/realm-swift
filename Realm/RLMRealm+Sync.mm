//
//  RLMRealm+RLMRealmSync.m
//  Realm
//
//  Created by Simon Ask Ulsnes on 10/06/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

#import "RLMRealm+Sync.h"
#import "RLMRealm_Private.hpp"
#import "RLMRealmConfiguration.h"

static NSString* getProviderName(RLMRealmSyncIdentityProvider provider) {
    switch (provider) {
        case RLMRealmSyncIdentityProviderDebug:        return @"debug";
        case RLMRealmSyncIdentityProviderRealmRefresh: return @"realm";
        case RLMRealmSyncIdentityProviderFacebook:     return @"facebook";
    }
    assert(false); // Invalid identity provider
}

@implementation RLMRealm (Sync)

-(void)refreshCredendialsWithProvider:(RLMRealmSyncIdentityProvider)provider andToken:(NSString *)token withAppID:(NSString *)appID {
    // FIXME: Discover the Auth Server URL in a better way.
    NSURL *syncURL = self.configuration.syncServerURL;
    NSURL *authURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:3000/sessions", syncURL.host]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:authURL];
    request.HTTPMethod = @"POST";
    NSURLSession *session = [NSURLSession sharedSession];

    NSDictionary *json = @{@"provider": getProviderName(provider), @"data":token, @"app_id":appID};
    NSError *err;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:&err];
    if (err)
        @throw err; // FIXME: Is this the right thing to do?
    [request addValue:@"application/json;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];

    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error)
            NSLog(@"Error requesting access token from Realm Sync authentication service: %@", error);
        else {
            id response_json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                NSLog(@"Error parsing JSON: %@", error);
                return;
            }
            if (![response_json isKindOfClass:[NSDictionary class]]) {
                NSLog(@"Ill-formed JSON response: not a dictionary");
                return;
            }

            // FIXME: Check that response_json is actually a dictionary

            [self didObtainAccessToken:response_json];
        }
    }];
    [task resume];
}

-(void)didObtainRefreshToken:(NSDictionary*)tokenData {
    // FIXME: Store the refresh token for later use.
}

-(void)didObtainAccessToken:(NSDictionary*)tokenData {
    realm::SharedRealm shared_realm = self->_realm;
    NSString* token = tokenData[@"token"];
    if (token == nil || ![token isKindOfClass:[NSString class]]) {
        NSLog(@"Ill-formed JSON response: \"token\" field is not a string");
        return;
    }

    std::string access_token{token.UTF8String};
    shared_realm->refresh_sync_access_token(std::move(access_token));
}

@end
