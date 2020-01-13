////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

NS_ASSUME_NONNULL_BEGIN

@interface RLMPushSendMessageRequest
@end

@interface RLMPushSendMessageResult
@end

/// A block type used for push APIs which asynchronously vend an `RLMPushSendMessageResult`.
typedef void(^RLMPushCompletionBlock)(RLMPushSendMessageResult * _Nullable, NSError * _Nullable);

/**
 `RLMPush` allows a user to register or deregister for push notifications,
 and send push messages to other users.
 */
@interface RLMPush: NSObject

/**
 Register this device for push notifications.

 - parameter token: the registration token to be registered for push
 */
- (void)register:(NSString *)token;

/**
 Deregister this device for push notifications.
 */
- (void)deregister;

/**
 Send a push message to a given target.
 */
- (void)sendMessage:(NSString *)target
            request:(id)request
       onCompletion:(RLMPushCompletionBlock)completion NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
