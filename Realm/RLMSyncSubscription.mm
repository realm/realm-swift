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

#import "RLMSyncSubscription_Private.h"

// TODO: Flexible Sync - Add docstrings

#pragma mark - Subscription

@implementation RLMSyncSubscription

- (NSDate *)createdAt {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
    return NULL;
}

- (NSDate *)updatedAt {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
    return NULL;
}

- (NSString *)name {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
    return NULL;
}

- (instancetype)initWithName:(nullable NSString *)name
                   predicate:(NSPredicate *)predicate {
    // TODO: Flexible Sync - Add initialiser implementation
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
    return NULL;
}

- (void)updateSubscriptionWithPredicate:(NSPredicate *)predicate
                                  error:(NSError **)error {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
}

@end

#pragma mark - Subscription Task

@implementation RLMSyncSubscriptionTask

- (void)observe:(RLMSyncSubscriptionStateBlock)block {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
}

@end

#pragma mark - SubscriptionSet

@implementation NSArray (SubscriptionSet)

- (NSError *)error {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
    return NULL;
}

#pragma mark - Batch Update subscriptions

-(RLMSyncSubscriptionTask *)write:(__attribute__((noescape)) void(^)(void))block {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
    return NULL;
}

-(RLMSyncSubscriptionTask *)writeAsync:(__attribute__((noescape)) void(^)(void))block
                              callback:(RLMSyncSubscriptionCallback)callback {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
    return NULL;
}

#pragma mark - Find subscription

-(nullable RLMSyncSubscription *)subscriptionWithPredicate:(NSPredicate *)predicate {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
    return NULL;
}

-(nullable RLMSyncSubscription *)subscriptionWithName:(NSString *)name {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
    return NULL;
}

#pragma mark - Subscription transactions

-(void)addSubscriptionWithName:(nullable NSString *)name
                     predicate:(NSPredicate *)predicate {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
}

-(void)removeSubscriptionWithName:(NSString *)name {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
}

-(void)removeSubscriptionWithPredicate:(NSPredicate *)predicate {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
}

-(void)removeSubscription:(RLMSyncSubscription *)subscription {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
}

-(void)removeAllSubscriptions {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
}

-(void)removeSubscriptionsWithClassName:(NSString *)className {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
}


@end
