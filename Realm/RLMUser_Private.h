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

#import <Realm/RLMUser.h>

NS_ASSUME_NONNULL_BEGIN

/// Observer block for user notifications.
typedef void(^RLMUserNotificationBlock)(RLMUser *);

/// Token that identifies an observer. Unsubscribes when deconstructed to
/// avoid dangling observers, therefore this must be retained to hold
/// onto a subscription.
@interface RLMUserSubscriptionToken : NSObject

/// The underlying value of the subscription token.
@property (nonatomic, readonly) NSUInteger value;

@end

@interface RLMUser ()

/// Subscribe to notifications for this RLMUser.
- (RLMUserSubscriptionToken *)subscribe:(RLMUserNotificationBlock)block;
/// Unsubscribe to notifications for this RLMUser.
- (void)unsubscribe:(RLMUserSubscriptionToken *)token;

@end

NS_ASSUME_NONNULL_END
