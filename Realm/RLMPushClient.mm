//
//  RLMPushClient.m
//  Realm
//
//  Created by mdb on 6/3/20.
//  Copyright © 2020 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLMPushClient_Private.hpp"
#import "sync/push_client.hpp"

// QQ: Explain why doesn't doesn't work

//@interface RLMPushClient () {
//    realm::app::PushClient _pushClient;
//}
//@end
//...
//_pushClient = pushClient;
// "No matching constructor for initialization of 'realm::app::PushClient'"
// Check PushClient, the overloaded= init has to take an lvalue or rvalue

@interface RLMPushClient () {
    realm::app::PushClient *_pushClient;
}
@end

@implementation RLMPushClient

- (instancetype)initWithPushClient:(realm::app::PushClient)pushClient {
    if (self = [super/* should this be super? */ init]) {
        _pushClient = &pushClient;
        return self;
    }
    return nil;
}

- (void)registerDeviceWithToken:(NSString *)token syncUser:(RLMSyncUser *)syncUser completion:(RLMOptionalErrorBlock)completion {
    return;
}


- (void)deregisterDeviceWithToken:(NSString *)token syncUser:(RLMSyncUser *)syncUser completion:(RLMOptionalErrorBlock)completion {
    return;
}

- (realm::app::PushClient*)_pushClient {
    return _pushClient;
}

@end
