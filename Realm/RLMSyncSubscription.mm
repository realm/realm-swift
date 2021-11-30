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
    realm::sync::Subscription _subscription;
    RLMSyncSubscriptionSet *_subscriptionSet;
}
@end

@implementation RLMSyncSubscription

- (instancetype)initWithSubscription:(realm::sync::Subscription)subscription subscriptionSet:(RLMSyncSubscriptionSet *)subscriptionSet {
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

- (NSString *)objectClassName {
    return [NSString stringWithCString:std::string(_subscription.object_class_name()).c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (void)updateSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    [self updateSubscriptionWithClassName:objectClassName
                                    where:predicateFormat
                                     args:args];
}

- (void)updateSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat
                                   args:(va_list)args {
    [self updateSubscriptionWithClassName:objectClassName
                                predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];

}

- (void)updateSubscriptionWithClassName:(NSString *)objectClassName
                              predicate:(NSPredicate *)predicate {
    [_subscriptionSet verifyInWriteTransaction];
    [_subscriptionSet addSubscriptionWithClassName:objectClassName
                                  subscriptionName:self.name
                                         predicate:predicate
                                    updateExisting:true];
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

- (BOOL)write:(__attribute__((noescape)) void(^)(void))block {
    [self write:block error:nil];
}

- (BOOL)write:(__attribute__((noescape)) void(^)(void))block error:(NSError **)error {
    [self secureWrite];
    auto mutableSubscriptionSet = _subscriptionSet.make_mutable_copy();
    _mutableSubscriptionSet = mutableSubscriptionSet;
    self->isInWriteTransaction = true;
    block();
    try {
        mutableSubscriptionSet.commit();
        self->isInWriteTransaction = false;
        _subscriptionSet = _mutableSubscriptionSet;
        return YES;
    }
    catch (...) {
        RLMRealmTranslateException(error);
        return NO;
    }
    return YES;
}

- (BOOL)writeAsync:(__attribute__((noescape)) void(^)(void))block
          callback:(RLMSyncSubscriptionCallback)callback {
    [NSException raise:@"NotImplemented" format:@"Needs Implementation"];
    return NULL;
}

#pragma mark - Check Subscription State

typedef void(^RLMSyncSubscriptionStateBlock)(RLMSyncSubscriptionState state);

- (void)observe:(RLMSyncSubscriptionStateBlock)block {

}

#pragma mark - Find subscription

- (nullable RLMSyncSubscription *)subscriptionWithName:(NSString *)name {
    std::string str = std::string([name UTF8String]);
    auto iterator = _subscriptionSet.find(str);
    if (iterator != _subscriptionSet.end()) {
        return [[RLMSyncSubscription alloc] initWithSubscription:*iterator
                                                 subscriptionSet:self];
    }
    return NULL;
}

- (nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                      where:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    return [self subscriptionWithClassName:objectClassName
                                     where:predicateFormat
                                      args:args];

}

- (nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                      where:(NSString *)predicateFormat
                                                       args:(va_list)args {
    return [self subscriptionWithClassName:objectClassName
                                 predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                  predicate:(NSPredicate *)predicate {
    RLMClassInfo& info = _realm->_info[objectClassName];
    auto query = RLMPredicateToQuery(predicate, info.rlmObjectSchema, _realm.schema, _realm.group);
    auto iterator = _subscriptionSet.find(query);
    if (iterator != _subscriptionSet.end()) {
        return [[RLMSyncSubscription alloc] initWithSubscription:*iterator
                                                 subscriptionSet:self];
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

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                           predicate:(NSPredicate *)predicate {
    return [self addSubscriptionWithClassName:objectClassName
                             subscriptionName:nil
                                    predicate:predicate];
}

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                    subscriptionName:(nullable NSString *)name
                           predicate:(NSPredicate *)predicate {
    return [self addSubscriptionWithClassName:objectClassName
                             subscriptionName:name
                                    predicate:predicate
                               updateExisting:false];
}

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                    subscriptionName:(nullable NSString *)name
                           predicate:(NSPredicate *)predicate
                      updateExisting:(BOOL)updateExisting {
    [self verifyInWriteTransaction];

    RLMClassInfo& info = _realm->_info[objectClassName];
    auto query = RLMPredicateToQuery(predicate, info.rlmObjectSchema, _realm.schema, _realm.group);

    if (name != nil) {
        std::string str = std::string([name UTF8String]);
        auto iterator = _subscriptionSet.find(str);

        if (iterator == _subscriptionSet.end() || updateExisting) {
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

#pragma mark - Remove Subscription

- (void)removeSubscriptionWithName:(NSString *)name {
    [self verifyInWriteTransaction];

    std::string str = std::string([name UTF8String]);
    auto iterator = _subscriptionSet.find(str);
    if (iterator != _subscriptionSet.end()) {
        _mutableSubscriptionSet.erase(iterator);
    }
}

- (void)removeSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    [self removeSubscriptionWithClassName:objectClassName
                                    where: predicateFormat
                                     args: args];
}

- (void)removeSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat
                                   args:(va_list)args {
    [self removeSubscriptionWithClassName:objectClassName
                                predicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (void)removeSubscriptionWithClassName:(NSString *)objectClassName
                              predicate:(NSPredicate *)predicate {
    [self verifyInWriteTransaction];

    RLMClassInfo& info = _realm->_info[objectClassName];
    auto query = RLMPredicateToQuery(predicate, info.rlmObjectSchema, _realm.schema, _realm.group);
    auto iterator = _subscriptionSet.find(query);
    if (iterator != _subscriptionSet.end()) {
        _mutableSubscriptionSet.erase(iterator);
    }
}

- (void)removeSubscription:(RLMSyncSubscription *)subscription {
    [self verifyInWriteTransaction];

    if ([subscription.name length] == 0) {
        RLMClassInfo& info = _realm->_info[subscription.objectClassName];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:subscription.queryString];
        auto query = RLMPredicateToQuery(predicate, info.rlmObjectSchema, _realm.schema, _realm.group);
        auto iterator = _subscriptionSet.find(query);
        if (iterator != _subscriptionSet.end()) {
            _mutableSubscriptionSet.erase(iterator);
        }
    }
    else {
        std::string nameStr = std::string([subscription.name UTF8String]);
        auto iterator = _subscriptionSet.find(nameStr);
        if (iterator != _subscriptionSet.end()) {
            _mutableSubscriptionSet.erase(iterator);
        }
    }
}

#pragma mark - Remove Subscriptions

- (void)removeAllSubscriptions {
    [self verifyInWriteTransaction];
    _mutableSubscriptionSet.clear();
}

- (void)removeAllSubscriptionsWithClassName:(NSString *)className {
    [self verifyInWriteTransaction];

    auto iterator = _subscriptionSet.begin();
    while(iterator != _subscriptionSet.end()) {
        RLMSyncSubscription *subscription = [[RLMSyncSubscription alloc] initWithSubscription:*iterator
                                                                              subscriptionSet:self];
        if (subscription.objectClassName == className) {
            _mutableSubscriptionSet.erase(iterator);
        }
        iterator++;
    }
}

#pragma mark - Private
- (void)verifyInWriteTransaction {
    if (!self->isInWriteTransaction) {
        @throw RLMException(@"Can only add, remove, or update subscriptions within a write subscription block.");
    }
}

- (void)secureWrite {
    if (self->isInWriteTransaction) {
        @throw RLMException(@"Cannot initiate a write transaction on subscription set that is already been updated.");
    }
}

@end
