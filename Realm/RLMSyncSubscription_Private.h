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

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Subscription States

typedef NS_ENUM(NSUInteger, RLMSyncSubscriptionState) {
    RLMSubscriptionStateComplete,

    RLMSubscriptionStatePending,

    RLMSubscriptionStateError
};

@protocol RLMAnySyncSubscription
@end

#pragma mark - Subscription

@interface RLMSyncSubscription : NSObject <RLMAnySyncSubscription>

@property (nonatomic, readonly) NSDate *createdAt;

@property (nonatomic, readonly) NSDate *updatedAt;

@property (nonatomic, readonly) NSString *name;

- (instancetype)initWithName:(nullable NSString *)name
                   predicate:(NSPredicate *)predicate;

- (void)updateSubscriptionWithPredicate:(NSPredicate *)predicate
                                  error:(NSError **)error;

@end

#pragma mark - Subscription Task

@interface RLMSyncSubscriptionTask : NSObject

typedef void(^RLMSyncSubscriptionStateBlock)(RLMSyncSubscriptionState state);

- (void)observe:(RLMSyncSubscriptionStateBlock)block;

@end

#pragma mark - SubscriptionSet

@interface NSArray<RLMAnySyncSubscription> (SubscriptionSet)

#pragma mark - Properties

@property (nonatomic, readonly) NSError *error;

#pragma mark - Batch Update subscriptions

-(RLMSyncSubscriptionTask *)write:(__attribute__((noescape)) void(^)(void))block;

typedef void(^RLMSyncSubscriptionCallback)(NSError * _Nullable error);

-(RLMSyncSubscriptionTask *)writeAsync:(__attribute__((noescape)) void(^)(void))block
                              callback:(RLMSyncSubscriptionCallback)callback;

#pragma mark - Find subscription

-(nullable RLMSyncSubscription *)subscriptionWithPredicate:(NSPredicate *)predicate;

-(nullable RLMSyncSubscription *)subscriptionWithName:(NSString *)name;

#pragma mark - Subscription transactions

-(void)addSubscriptionWithName:(nullable NSString *)name
                     predicate:(NSPredicate *)predicate;

-(void)removeSubscriptionWithName:(NSString *)name;

-(void)removeSubscriptionWithPredicate:(NSPredicate *)predicate;

-(void)removeSubscription:(RLMSyncSubscription *)subscription;

-(void)removeAllSubscriptions;

-(void)removeSubscriptionsWithClassName:(NSString *)className;

@end

NS_ASSUME_NONNULL_END
