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

#import "RLMSyncSubscription_Private.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMUtil.hpp"
#import "RLMQueryUtil.hpp"

#import <realm/sync/subscriptions.hpp>

#pragma mark - Subscription

@interface RLMSyncSubscription () {
    realm::sync::SubscriptionSet _subscriptionSet;
    realm::sync::Subscription _subscription;
}
@end

@implementation RLMSyncSubscription

- (instancetype)initWithSubscription:(realm::sync::Subscription)subscription subscriptionSet:(realm::sync::SubscriptionSet)subscriptionSet {
    if (self = [super init]) {
        _subscription = subscription;
        _subscriptionSet = subscriptionSet;
        return self;
    }
}

- (NSDate *)createdAt {
    return RLMTimestampToNSDate(_subscription.created_at());

}

- (NSDate *)updatedAt {
    return RLMTimestampToNSDate(_subscription.updated_at());
}

- (NSString *)name {
    const std::string_view str_view = _subscription.name();
    std::string str = std::string(str_view);
    const char * characters = str.c_str();
    return [NSString stringWithCString:characters
                              encoding:[NSString defaultCStringEncoding]];
}

- (NSString *)queryString {
    return [NSString stringWithCString:std::string(_subscription.query_string()).c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (void)updateSubscriptionWithPredicate:(NSPredicate *)predicate
                                  error:(NSError **)error {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
}

@end

#pragma mark - SubscriptionSet

@interface RLMSyncSubscriptionSet () {
    realm::sync::SubscriptionSet _subscriptionSet;
    realm::sync::SubscriptionSet _mutableSubscriptionSet;
}
@end

@implementation RLMSyncSubscriptionSet {
    BOOL isInWriteTransaction;
    RLMRealm *_realm;
}

- (uint64_t)version {
    return _subscriptionSet.version();
}

- (uint64_t)count {
    return _subscriptionSet.size();
}

- (instancetype)initWithSubscriptionSet:(realm::sync::SubscriptionSet)subscriptionSet
                                  realm:(RLMRealm *)realm {
    if (self = [super init]) {
        _subscriptionSet = std::move(subscriptionSet);
        _realm = realm;
        self->isInWriteTransaction = false;
        return self;
    }
    return nil;
}

- (NSError *)error {
//    return _subscriptionSet->error_str();
}

#pragma mark - Batch Update subscriptions

-(BOOL)write:(__attribute__((noescape)) void(^)(void))block {
    [self write:block error:nil];
}

-(BOOL)write:(__attribute__((noescape)) void(^)(void))block error:(NSError **)error {
    [self secureWrite];
    auto mutableSubscriptionSet = _subscriptionSet.make_mutable_copy();
    _mutableSubscriptionSet = mutableSubscriptionSet;
    self->isInWriteTransaction = true;
    block();
    try {
        mutableSubscriptionSet.commit();
        self->isInWriteTransaction = false;
        return YES;
    }
    catch (...) {
        RLMRealmTranslateException(error);
        return NO;
    }
    return YES;
}

-(BOOL)writeAsync:(__attribute__((noescape)) void(^)(void))block
                              callback:(RLMSyncSubscriptionCallback)callback {
    [NSException raise:@"NotImplemented" format:@"Needs Impmentation"];
    return NULL;
}

#pragma mark - Find subscription

-(nullable RLMSyncSubscription *)subscriptionWithName:(NSString *)name {
    std::string str = std::string([name UTF8String]);
    auto iterator = _subscriptionSet.find(str);

    if (iterator != _subscriptionSet.end()) {
        return [[RLMSyncSubscription alloc] initWithSubscription:*iterator
                                                 subscriptionSet:_subscriptionSet];
    }
    return NULL;
}

-(nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                     where:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    return [self subscriptionWithClassName:objectClassName
                                     where:predicateFormat
                                      args:args];

}

-(nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                     where:(NSString *)predicateFormat
                                                      args:(va_list)args {
    return [self subscriptionWithClassName:objectClassName
                                 predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

-(nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                 predicate:(NSPredicate *)predicate {
    RLMClassInfo& info = _realm->_info[objectClassName];
    auto query = RLMPredicateToQuery(predicate, info.rlmObjectSchema, _realm.schema, _realm.group);
    auto iterator = _subscriptionSet.find(query);
    if (iterator != _subscriptionSet.end()) {
        return [[RLMSyncSubscription alloc] initWithSubscription:*iterator
                                                 subscriptionSet:_subscriptionSet];
    }
    return NULL;
}


#pragma mark - Add a Subscription

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                               where:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    return [self addSubscriptionWithClassName:objectClassName
                                        where:predicateFormat
                                         args:args];
}

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                               where:(NSString *)predicateFormat
                                args:(va_list)args {
    [self addSubscriptionWithClassName:objectClassName
                      subscriptionName:nil
                             predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                    subscriptionName:(NSString *)name
                               where:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    return [self addSubscriptionWithClassName:objectClassName
                             subscriptionName:name
                                        where:predicateFormat
                                         args:args];
}

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                    subscriptionName:(NSString *)name
                               where:(NSString *)predicateFormat
                                args:(va_list)args {
    [self addSubscriptionWithClassName:objectClassName
                      subscriptionName:name
                             predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];

}

-(void)addSubscriptionWithClassName:(NSString *)objectClassName
                          predicate:(NSPredicate *)predicate {
    return [self addSubscriptionWithClassName:objectClassName
                             subscriptionName:nil
                                    predicate:predicate];
}

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                    subscriptionName:(nullable NSString *)name
                           predicate:(NSPredicate *)predicate {
    [self verifyInWriteTransaction];

    RLMClassInfo& info = _realm->_info[objectClassName];
    auto query = RLMPredicateToQuery(predicate, info.rlmObjectSchema, _realm.schema, _realm.group);

    if (name != nil) {
        std::string str = std::string([name UTF8String]);
        auto iterator = _subscriptionSet.find(str);

        if (iterator == _subscriptionSet.end()) {
            _mutableSubscriptionSet.insert_or_assign(str, query);
        }
        else {
            @throw RLMException(@"Cannot duplicate a subscription, if you meant to update the subscription please use the `update` method.");
        }
    }
    else {
        _mutableSubscriptionSet.insert_or_assign(query);
    }
}

-(void)removeSubscriptionWithName:(NSString *)name {
    [self verifyInWriteTransaction];

    std::string str = std::string([name UTF8String]);
    auto iterator = _subscriptionSet.find(str);

    if (iterator != _subscriptionSet.end()) {
        _subscriptionSet.erase(iterator);
    }
}

-(void)removeSubscriptionWithPredicate:(NSPredicate *)predicate {
    [self verifyInWriteTransaction];
}

-(void)removeSubscription:(RLMSyncSubscription *)subscription {
    [self verifyInWriteTransaction];
}

-(void)removeAllSubscriptions {
    [self verifyInWriteTransaction];
}

-(void)removeSubscriptionsWithClassName:(NSString *)className {
    [self verifyInWriteTransaction];
}

#pragma mark - Private
-(void)verifyInWriteTransaction {
    if (!self->isInWriteTransaction) {
        @throw RLMException(@"Can only add, remove, or update subscriptions within a write subscription block.");
    }
}

-(void)secureWrite {
    if (self->isInWriteTransaction) {
        @throw RLMException(@"Cannot initiate a write transaction on subscription set that is already been updated.");
    }
}

@end
