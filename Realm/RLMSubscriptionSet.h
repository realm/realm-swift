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

@class RLMSubscription;

// TODO: Flexible Sync - Add docstrings
typedef NS_ENUM(NSUInteger, RLMSubscriptionState) {

    RLMSubscriptionStateComplete,

    RLMSubscriptionStatePending,

    RLMSubscriptionStateError
};

@interface RLMSubscriptionTask : NSObject

typedef void(^RLMSubscriptionStateBlock)(RLMSubscriptionState state);

- (void)observe:(RLMSubscriptionStateBlock)block;

@end

@interface RLMSubscription : NSObject

#pragma mark - Properties

@property (nonatomic, readonly) RLMSubscriptionState state;

@property (nonatomic, readonly) NSError *error;

typedef void (^RLMSubscriptionSetHandler)(void);

-(RLMSubscriptionTask *)write:(__attribute__((noescape)) void(^)(void))block;

-(RLMSubscription *)subscriptionWithPredicate:(NSPredicate *)predicate;

-(RLMSubscription *)subscriptionWithName:(NSString *)name;

-(void)addSubscriptionWithName:(nullable NSString *)name
                     predicate:(NSPredicate *)predicate;

-(void)removeSubscriptionWithName:(NSString *)name;

-(void)removeSubscriptionWithPredicate:(NSPredicate *)predicate;

-(void)removeSubscription:(RLMSubscription *)subscription;

-(void)remove;

@end

NS_ASSUME_NONNULL_END
