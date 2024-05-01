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
/// A custom base URL to request against. If not set or set to nil, the default base url for app services will be returned.
@property (nonatomic, readonly) NSString *baseURL;
/// Returns all currently cached Apps
+ (NSArray<RLMApp *> *)allApps;
/// Subscribe to notifications for this RLMApp.
- (RLMAppSubscriptionToken *)subscribe:(RLMAppNotificationBlock)block;

+ (instancetype)appWithConfiguration:(RLMAppConfiguration *)configuration;
+ (RLMApp *_Nullable)cachedAppWithId:(NSString *)appId;

+ (void)resetAppCache;

/// Updates the base url used by Atlas device sync, in case the need to roam between servers (cloud and/or edge server).
/// @param baseURL The new base url to connect to. Setting `nil` will reset the base url to the default url.
/// @note Updating the base URL would trigger a client reset.
- (void)updateBaseURL:(NSString *_Nullable)baseURL
           completion:(RLMOptionalErrorBlock)completionHandler NS_REFINED_FOR_SWIFT;

@end

@interface RLMAppConfiguration ()
@property (nonatomic) NSString *appId;
@property (nonatomic) BOOL encryptMetadata;
@property (nonatomic) NSURL *rootDirectory;
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
