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

#import <Foundation/Foundation.h>

@class RLMObjectId;

#pragma mark - Subscription States

typedef NS_ENUM(NSUInteger, RLMSyncSubscriptionState) {
    RLMSubscriptionStateComplete,

    RLMSubscriptionStatePending,

    RLMSubscriptionStateError
};

NS_ASSUME_NONNULL_BEGIN

@interface RLMSyncSubscription : NSObject

@property (nonatomic, readonly) RLMObjectId *identifier;

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) NSDate *createdAt;

@property (nonatomic, readonly) NSDate *updatedAt;

- (void)updateSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat, ...;

- (void)updateSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat
                                   args:(va_list)args;

- (void)updateSubscriptionWithClassName:(NSString *)objectClassName
                              predicate:(NSPredicate *)predicate;

@end

@interface RLMSyncSubscriptionSet : NSObject <NSFastEnumeration>

#pragma mark - Batch Update subscriptions

- (BOOL)write:(__attribute__((noescape)) void(^)(void))block;

- (BOOL)write:(__attribute__((noescape)) void(^)(void))block error:(NSError **)error;

#pragma mark - Check Subscription State

typedef void(^RLMSyncSubscriptionStateBlock)(RLMSyncSubscriptionState state);

- (void)observe:(RLMSyncSubscriptionStateBlock)block;

#pragma mark - Find subscription

- (nullable RLMSyncSubscription *)subscriptionWithName:(NSString *)name;

- (nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                      where:(NSString *)predicateFormat, ...;

- (nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                      where:(NSString *)predicateFormat
                                                       args:(va_list)args;

- (nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                  predicate:(NSPredicate *)predicate;

#pragma mark - Add a Subscription

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                               where:(NSString *)predicateFormat, ...;

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                               where:(NSString *)predicateFormat
                                args:(va_list)args;

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                    subscriptionName:(NSString *)name
                               where:(NSString *)predicateFormat, ...;

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                    subscriptionName:(NSString *)name
                               where:(NSString *)predicateFormat
                                args:(va_list)args;

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                           predicate:(NSPredicate *)predicate;

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                    subscriptionName:(nullable NSString *)name
                           predicate:(NSPredicate *)predicate;

#pragma mark - Remove Subscription

- (void)removeSubscriptionWithName:(NSString *)name;

- (void)removeSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat, ...;

- (void)removeSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat
                                   args:(va_list)args;

- (void)removeSubscriptionWithClassName:(NSString *)objectClassName
                              predicate:(NSPredicate *)predicate;

- (void)removeSubscription:(RLMSyncSubscription *)subscription;

#pragma mark - Remove Subscriptions

- (void)removeAllSubscriptions;

- (void)removeAllSubscriptionsWithClassName:(NSString *)className;

#pragma mark - Subscription transactions

typedef void(^RLMSyncSubscriptionStateBlock)(RLMSyncSubscriptionState state);

//- (void)observe:(RLMSyncSubscriptionStateBlock)block;

#pragma mark - SubscriptionSet Collection

- (RLMSyncSubscription *)objectAtIndex:(NSUInteger)index;

- (RLMSyncSubscription *)firstObject;

- (RLMSyncSubscription *)lastObject;

#pragma mark - Subscript

- (id)objectAtIndexedSubscript:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
