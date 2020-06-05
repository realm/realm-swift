//
//  RLMPushClient.m
//  Realm
//
//  Created by mdb on 6/3/20.
//  Copyright © 2020 Realm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RLMPushClient_Private.hpp"
#import "RLMSyncUser_Private.hpp"
// QQ: Is it safe to include the private header of RLMSyncUser here?
// The reason it's included here now is because realm::app::PushClient::register_device takes a shared_ptr<SyncUser>.
// The syncUser argument has a member shared_ptr<SyncUser> within the private, seemingly for this exact purpose.
#import "RLMApp_Private.hpp"
// QQ: Same question for RLMApp_Private.hpp
// Imported in order to use RLMAppErrorToNSError.
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

// For example, this happens in RLMApp.mm:
//- (RLMSyncUser *)switchToUser:(RLMSyncUser *)syncUser {
//    return [[RLMSyncUser alloc] initWithSyncUser:_app->switch_user(syncUser._syncUser) app:self];
//}
//
//- (void)removeUser:(RLMSyncUser *)syncUser completion:(RLMOptionalErrorBlock)completion {
//    _app->remove_user(syncUser._syncUser, ^(Optional<app::AppError> error) {
//        [self handleResponse:error completion:completion];
//    });
//}

@interface RLMPushClient () {
    std::unique_ptr<realm::app::PushClient> _pushClient;}
@end

@implementation RLMPushClient

- (instancetype)initWithPushClient:(realm::app::PushClient&&)pushClient {
    if (self = [super init]) {
        _pushClient = std::make_unique<realm::app::PushClient>(pushClient);
        return self;
    }
    return nil;
}

- (void)registerDeviceWithToken:(NSString *)token syncUser:(RLMSyncUser *)syncUser completion:(RLMOptionalErrorBlock)completion {
    self->_pushClient->register_device(token.UTF8String, syncUser._syncUser, ^(util::Optional<app::AppError> error) {
        if (error && error->error_code) {
            return completion(RLMAppErrorToNSError(*error));
        }
        completion(nil);
    });
}


- (void)deregisterDeviceWithToken:(NSString *)token syncUser:(RLMSyncUser *)syncUser completion:(RLMOptionalErrorBlock)completion {
    self->_pushClient->deregister_device(token.UTF8String, syncUser._syncUser, ^(util::Optional<app::AppError> error) {
        if (error && error->error_code) {
            return completion(RLMAppErrorToNSError(*error));
        }
        completion(nil);
    });
}

@end
