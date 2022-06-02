////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

#import <Realm/RLMSyncSubscription.h>

#import <Realm/RLMRealm.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Subscription

@interface RLMSyncSubscription ()

@property (nonatomic, readonly) RLMObjectId *identifier;

@property (nonatomic, readonly) NSString *queryString;

@property (nonatomic, readonly) NSString *objectClassName;

@end

#pragma mark - SubscriptionSet

@interface RLMSyncSubscriptionEnumerator : NSObject

@property (nonatomic, readonly) RLMSyncSubscriptionSet *subscriptionSet;

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                    count:(NSUInteger)len;

- (instancetype)initWithSubscriptionSet:(RLMSyncSubscriptionSet *)subscriptionSet;

@end

@interface RLMSyncSubscriptionSet ()

@property (readonly) uint64_t version;

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                    subscriptionName:(nullable NSString *)name
                           predicate:(NSPredicate *)predicate
                      updateExisting:(BOOL)updateExisting;

- (void)waitForSynchronizationOnQueue:(nullable dispatch_queue_t)queue
                      completionBlock:(void(^)(NSError *))completionBlock;

- (RLMSyncSubscriptionEnumerator *)fastEnumerator;

NSUInteger RLMFastEnumerate(NSFastEnumerationState *state,
                            NSUInteger len,
                            RLMSyncSubscriptionSet *collection);

@end

NS_ASSUME_NONNULL_END
