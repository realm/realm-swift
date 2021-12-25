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
#import "RLMObjectId_Private.hpp"

#import <realm/sync/subscriptions.hpp>
#import <realm/status_with.hpp>
#import <realm/util/future.hpp>

#pragma mark - Subscription

@interface RLMSyncSubscription () {
    std::unique_ptr<realm::sync::Subscription> _subscription;
    RLMSyncSubscriptionSet *_subscriptionSet;
}
@end

@implementation RLMSyncSubscription

- (instancetype)initWithSubscription:(realm::sync::Subscription)subscription subscriptionSet:(RLMSyncSubscriptionSet *)subscriptionSet {
    if (self = [super init]) {
        _subscription = std::make_unique<realm::sync::Subscription>(subscription);
        _subscriptionSet = subscriptionSet;
        return self;
    }
}

- (RLMObjectId *)identifier {
    return [[RLMObjectId alloc]initWithValue:_subscription->id()];
}

- (nullable NSString *)name {
    const std::string_view str_view = _subscription->name();
    std::string str = std::string(str_view);
    const char * characters = str.c_str();
    return [NSString stringWithCString:characters
                              encoding:[NSString defaultCStringEncoding]];
}

- (NSDate *)createdAt {
    return RLMTimestampToNSDate(_subscription->created_at());
}

- (NSDate *)updatedAt {
    return RLMTimestampToNSDate(_subscription->updated_at());
}

- (NSString *)queryString {
    return [NSString stringWithCString:std::string(_subscription->query_string()).c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (NSString *)objectClassName {
    return [NSString stringWithCString:std::string(_subscription->object_class_name()).c_str()
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
    std::unique_ptr<realm::sync::SubscriptionSet> _subscriptionSet;
    std::unique_ptr<realm::sync::SubscriptionSet> _mutableSubscriptionSet;
}
@end

@implementation RLMSyncSubscriptionSet {
    BOOL isInWriteTransaction;
    RLMRealm *_realm;
    id _strongBuffer[16];
}

- (instancetype)initWithSubscriptionSet:(realm::sync::SubscriptionSet)subscriptionSet
                                  realm:(RLMRealm *)realm {
    if (self = [super init]) {
        _subscriptionSet = std::make_unique<realm::sync::SubscriptionSet>(subscriptionSet);
        _realm = realm;
        self->isInWriteTransaction = false;
        return self;
    }
    return nil;
}

- (NSUInteger)count {
    return _subscriptionSet->size();
}

- (NSString *)errorMessage {
    return RLMStringDataToNSString(_subscriptionSet->error_str());
}

- (RLMSyncSubscriptionState)state {
    return [self mapState:_subscriptionSet->state()];
}

#pragma mark - Batch Update subscriptions

- (BOOL)write:(__attribute__((noescape)) void(^)(void))block {
    [self write:block error:nil];
}

- (BOOL)write:(__attribute__((noescape)) void(^)(void))block error:(NSError **)error {
    [self secureWrite];
    _mutableSubscriptionSet = std::make_unique<realm::sync::SubscriptionSet>(_subscriptionSet->make_mutable_copy());
    self->isInWriteTransaction = true;
    block();
    try {
        _mutableSubscriptionSet->commit();
        _subscriptionSet = std::move(_mutableSubscriptionSet);
        _mutableSubscriptionSet = nullptr;
        self->isInWriteTransaction = false;
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

- (void)observe:(RLMSyncSubscriptionStateBlock)block {
    _subscriptionSet->get_state_change_notification(realm::sync::SubscriptionSet::State::Complete)
        .get_async([self, block](realm::StatusWith<realm::sync::SubscriptionSet::State> state) noexcept {
            if (state.is_ok()) {
                auto value = state.get_value();
                block([self mapState:value]);
            } else {
                block(RLMSyncSubscriptionStateError);
            }
        });
}

#pragma mark - Find subscription

- (nullable RLMSyncSubscription *)subscriptionWithName:(NSString *)name {
    std::string str = std::string([name UTF8String]);
    auto iterator = _subscriptionSet->find(str);
    if (iterator != _subscriptionSet->end()) {
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
    auto iterator = _subscriptionSet->find(query);
    if (iterator != _subscriptionSet->end()) {
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
        auto iterator = _mutableSubscriptionSet->find(str);
        
        if (iterator == _mutableSubscriptionSet->end() || updateExisting) {
            _mutableSubscriptionSet->insert_or_assign(str, query);
        }
        else {
            @throw RLMException(@"Cannot duplicate a subscription, if you meant to update the subscription please use the `update` method.");
        }
    }
    else {
        _mutableSubscriptionSet->insert_or_assign(query);
    }
}

#pragma mark - Remove Subscription

- (void)removeSubscriptionWithName:(NSString *)name {
    [self verifyInWriteTransaction];
    
    std::string str = std::string([name UTF8String]);
    auto iterator = _mutableSubscriptionSet->find(str);
    if (iterator != _mutableSubscriptionSet->end()) {
        _mutableSubscriptionSet->erase(iterator);
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
    auto iterator = _mutableSubscriptionSet->find(query);
    if (iterator != _mutableSubscriptionSet->end()) {
        _mutableSubscriptionSet->erase(iterator);
    }
}

- (void)removeSubscription:(RLMSyncSubscription *)subscription {
    [self verifyInWriteTransaction];

    for (auto it = _mutableSubscriptionSet->begin(); it != _mutableSubscriptionSet->end();) {
        if (it->id() == subscription.identifier.value) {
            it = _mutableSubscriptionSet->erase(it);
            return;
        }
        else {
            it++;
        }
    }
}

#pragma mark - Remove Subscriptions

- (void)removeAllSubscriptions {
    [self verifyInWriteTransaction];
    _mutableSubscriptionSet->clear();
}

- (void)removeAllSubscriptionsWithClassName:(NSString *)className {
    [self verifyInWriteTransaction];
    
    for (auto it = _mutableSubscriptionSet->begin(); it != _mutableSubscriptionSet->end();) {
        if (it->object_class_name() == std::string([className UTF8String])) {
            it = _mutableSubscriptionSet->erase(it);
        }
        else {
            it++;
        }
    }
}

#pragma mark - NSFastEnumerator

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    NSUInteger batchCount = 0, count = _subscriptionSet->size();
    for (NSUInteger index = state->state; index < count && batchCount < len; ++index) {
        auto iterator = _subscriptionSet->at(size_t(index));
        RLMSyncSubscription *subscription = [[RLMSyncSubscription alloc]initWithSubscription:iterator
                                                                             subscriptionSet:self];;
        _strongBuffer[batchCount] = subscription;
        batchCount++;
    }
    
    for (NSUInteger i = batchCount; i < len; ++i) {
        _strongBuffer[i] = nil;
    }
    
    state->itemsPtr = (__unsafe_unretained id *)(void *)_strongBuffer;
    state->state += batchCount;
    state->mutationsPtr = state->extra+1;
    
    return batchCount;
}

#pragma mark - SubscriptionSet Collection

- (RLMSyncSubscription *)objectAtIndex:(NSUInteger)index {
    auto size = _subscriptionSet->size();
    if (index >= size) {
        @throw RLMException(@"Index %llu is out of bounds (must be less than %llu).",
                            (unsigned long long)index, (unsigned long long)size);
    }
    
    return [[RLMSyncSubscription alloc]initWithSubscription:_subscriptionSet->at(size_t(index))
                                            subscriptionSet:self];
}

- (RLMSyncSubscription *)firstObject {
    if (_subscriptionSet->size() < 1) {
        return 0;
    }
    return [[RLMSyncSubscription alloc]initWithSubscription:_subscriptionSet->at(size_t(0))
                                            subscriptionSet:self];
}

- (RLMSyncSubscription *)lastObject {
    if (_subscriptionSet->size() < 1) {
        return 0;
    }
    
    return [[RLMSyncSubscription alloc]initWithSubscription:_subscriptionSet->at(_subscriptionSet->size()-1)
                                            subscriptionSet:self];
}

#pragma mark - Subscript

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

#pragma mark - Private API

- (uint64_t)version {
    return _subscriptionSet->version();
}

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

- (RLMSyncSubscriptionState)mapState:(realm::sync::SubscriptionSet::State)state {
    switch (state) {
        case realm::sync::SubscriptionSet::State::Uncommitted:
        case realm::sync::SubscriptionSet::State::Pending:
        case realm::sync::SubscriptionSet::State::Bootstrapping:
            return RLMSyncSubscriptionStatePending;
        case realm::sync::SubscriptionSet::State::Complete:
            return RLMSyncSubscriptionStateComplete;
        case realm::sync::SubscriptionSet::State::Error:
            return RLMSyncSubscriptionStateError;
        case realm::sync::SubscriptionSet::State::Superceded:
            return RLMSyncSubscriptionStateSuperceded;
    }
}
@end
