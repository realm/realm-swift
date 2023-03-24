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

#import <Realm/RLMApp.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

/// Observer block for app notifications.
typedef void(^RLMAppNotificationBlock)(RLMApp *);

/// Token that identifies an observer. Unsubscribes when deconstructed to
/// avoid dangling observers, therefore this must be retained to hold
/// onto a subscription.
@interface RLMAppSubscriptionToken : NSObject
- (void)unsubscribe;
@end

@interface RLMApp ()
/// Returns all currently cached Apps
+ (NSArray<RLMApp *> *)allApps;
/// Subscribe to notifications for this RLMApp.
- (RLMAppSubscriptionToken *)subscribe:(RLMAppNotificationBlock)block;

+ (instancetype)appWithId:(NSString *)appId
            configuration:(nullable RLMAppConfiguration *)configuration
            rootDirectory:(nullable NSURL *)rootDirectory;

+ (instancetype)uncachedAppWithId:(NSString *)appId
                    configuration:(RLMAppConfiguration *)configuration
                    rootDirectory:(nullable NSURL *)rootDirectory;

+ (void)resetAppCache;
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
