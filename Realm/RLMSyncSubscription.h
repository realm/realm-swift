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
    RLMSyncSubscriptionStateComplete,

    RLMSyncSubscriptionStatePending,

    RLMSyncSubscriptionStateError,

    RLMSyncSubscriptionStateSuperceded
};

NS_ASSUME_NONNULL_BEGIN

@interface RLMSyncSubscription : NSObject

@property (nonatomic, readonly) RLMObjectId *identifier;

@property (nonatomic, readonly, nullable) NSString *name;

@property (nonatomic, readonly) NSDate *createdAt;

@property (nonatomic, readonly) NSDate *updatedAt;

@property (nonatomic, readonly) NSString *errorMessage;

- (void)updateSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat, ...;

- (void)updateSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat
                                   args:(va_list)args;

- (void)updateSubscriptionWithClassName:(NSString *)objectClassName
                              predicate:(NSPredicate *)predicate;

@end

@interface RLMSyncSubscriptionSet : NSObject <NSFastEnumeration>

@property (readonly) NSUInteger count;

@property (readonly) RLMSyncSubscriptionState state;

#pragma mark - Batch Update subscriptions

- (BOOL)write:(__attribute__((noescape)) void(^)(void))block NS_SWIFT_UNAVAILABLE("");

- (BOOL)write:(__attribute__((noescape)) void(^)(void))block error:(NSError **)error;

typedef void(^RLMSyncSubscriptionCallback)(NSError * _Nullable error);

- (BOOL)writeAsync:(__attribute__((noescape)) void(^)(void))block
          callback:(RLMSyncSubscriptionCallback)callback;

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

#pragma mark - SubscriptionSet Collection

- (nullable RLMSyncSubscription *)objectAtIndex:(NSUInteger)index;

- (nullable RLMSyncSubscription *)firstObject;

- (nullable RLMSyncSubscription *)lastObject;

#pragma mark - Subscript

- (id)objectAtIndexedSubscript:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
