////////////////////////////////////////////////////////////////////////////
//
// Copyright 2024 Realm Inc.
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
#import <Realm/RLMRealm.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

/**
 A block which receives a subscription set instance, that can be used to add an initial set of subscriptions which will be executed
 when the Realm is first opened.
 */
RLM_SWIFT_SENDABLE
typedef void(^RLMFlexibleSyncInitialSubscriptionsBlock)(RLMSyncSubscriptionSet * _Nonnull subscriptions);

/**
 A configuration controlling how the initial subscriptions are populated when a Realm file is first opened.

 @see `RLMSubscriptionSet`
 */
RLM_SWIFT_SENDABLE RLM_FINAL // immutable final class
@interface RLMInitialSubscriptionsConfiguration : NSObject

/**
 A callback that's executed in an update block to populate the initial subscriptions for that Realm.

 This callback will only be executed when the Realm is first created, unless `rerunOnOpen` is `true`, in which case it will be executed every time
 the Realm is opened.
 */
@property (nonatomic, readonly) RLMFlexibleSyncInitialSubscriptionsBlock callback;

/**
 Controls whether to re-run the `callback` every time the Realm is opened.
 */
@property (nonatomic, readonly) BOOL rerunOnOpen;

/**
 Create a new initial subscriptions configuration.

 @param callback Callback that will be invoked to update the subscriptions for this Realm file when it's first created or every time it's opened if `rerunOnOpen` is `true`.
 @param rerunOnOpen A flag controlling whether to run the subscription callback every time the Realm is opened or only the first time.
 */
- (instancetype)initWithCallback:(RLMFlexibleSyncInitialSubscriptionsBlock)callback rerunOnOpen:(BOOL)rerunOnOpen;


/**
 Create a new initial subscriptions configuration.

 @param callback Callback that will be invoked to update the subscriptions for this Realm file when it's first created.
 */
- (instancetype)initWithCallback:(RLMFlexibleSyncInitialSubscriptionsBlock)callback;

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
