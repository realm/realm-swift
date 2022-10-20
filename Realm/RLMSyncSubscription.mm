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

#import "RLMError_Private.hpp"
#import "RLMObjectId_Private.hpp"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMUtil.hpp"

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
    return nil;
}

- (RLMObjectId *)identifier {
    return [[RLMObjectId alloc] initWithValue:_subscription->id];
}

- (nullable NSString *)name {
    auto name = _subscription->name;
    if (name) {
        return @(name->c_str());
    }
    return nil;
}

- (NSDate *)createdAt {
    return RLMTimestampToNSDate(_subscription->created_at);
}

- (NSDate *)updatedAt {
    return RLMTimestampToNSDate(_subscription->updated_at);
}

- (NSString *)queryString {
    return @(_subscription->query_string.c_str());
}

- (NSString *)objectClassName {
    return @(_subscription->object_class_name.c_str());
}

- (void)updateSubscriptionWhere:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    [self updateSubscriptionWhere:predicateFormat
                             args:args];
    va_end(args);
}

- (void)updateSubscriptionWhere:(NSString *)predicateFormat
                           args:(va_list)args {
    [self updateSubscriptionWithPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args]];
}

- (void)updateSubscriptionWithPredicate:(NSPredicate *)predicate {
    if (self.name != nil) {
        [_subscriptionSet addSubscriptionWithClassName:self.objectClassName
                                      subscriptionName:self.name
                                             predicate:predicate
                                        updateExisting:true];
    }
    else {
        RLMSyncSubscription *foundSubscription = [_subscriptionSet subscriptionWithClassName:self.objectClassName where:self.queryString];
        if (foundSubscription) {
            [_subscriptionSet removeSubscription:foundSubscription];
            [_subscriptionSet addSubscriptionWithClassName:self.objectClassName
                                                 predicate:predicate];
        } else {
            @throw RLMException(@"Cannot update a non-existent subscription.");
        }
    }
}

@end

#pragma mark - SubscriptionSet

@interface RLMSyncSubscriptionSet () {
    std::unique_ptr<realm::sync::SubscriptionSet> _subscriptionSet;
    std::unique_ptr<realm::sync::MutableSubscriptionSet> _mutableSubscriptionSet;
    NSHashTable<RLMSyncSubscriptionEnumerator *> *_enumerators;
}
@end

@interface RLMSyncSubscriptionEnumerator() {
    // The buffer supplied by fast enumeration does not retain the objects given
    // to it, but because we create objects on-demand and don't want them
    // autoreleased (a table can have more rows than the device has memory for
    // accessor objects) we need a thing to retain them.
    id _strongBuffer[16];
}
@end

@implementation RLMSyncSubscriptionEnumerator

- (instancetype)initWithSubscriptionSet:(RLMSyncSubscriptionSet *)subscriptionSet {
    if (self = [super init]) {
        _subscriptionSet = subscriptionSet;
        return self;
    }
    return nil;
}
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                    count:(NSUInteger)len {
    NSUInteger batchCount = 0, count = [_subscriptionSet count];
    for (NSUInteger index = state->state; index < count && batchCount < len; ++index) {
        auto subscription = [_subscriptionSet objectAtIndex:index];
        _strongBuffer[batchCount] = subscription;
        batchCount++;
    }

    for (NSUInteger i = batchCount; i < len; ++i) {
        _strongBuffer[i] = nil;
    }

    if (batchCount == 0) {
        // Release our data if we're done, as we're autoreleased and so may
        // stick around for a while
        if (_subscriptionSet) {
            _subscriptionSet = nil;
        }
    }


    state->itemsPtr = (__unsafe_unretained id *)(void *)_strongBuffer;
    state->state += batchCount;
    state->mutationsPtr = state->extra+1;

    return batchCount;
}

@end

NSUInteger RLMFastEnumerate(NSFastEnumerationState *state,
                            NSUInteger len,
                            RLMSyncSubscriptionSet *collection) {
    __autoreleasing RLMSyncSubscriptionEnumerator *enumerator;
    if (state->state == 0) {
        enumerator = collection.fastEnumerator;
        state->extra[0] = (long)enumerator;
        state->extra[1] = collection.count;
    }
    else {
        enumerator = (__bridge id)(void *)state->extra[0];
    }

    return [enumerator countByEnumeratingWithState:state count:len];
}

@implementation RLMSyncSubscriptionSet {
    std::mutex _collectionEnumeratorMutex;
    RLMRealm *_realm;
}

- (instancetype)initWithSubscriptionSet:(realm::sync::SubscriptionSet)subscriptionSet
                                  realm:(RLMRealm *)realm {
    if (self = [super init]) {
        _subscriptionSet = std::make_unique<realm::sync::SubscriptionSet>(subscriptionSet);
        _realm = realm;
        return self;
    }
    return nil;
}

- (RLMSyncSubscriptionEnumerator *)fastEnumerator {
    return [[RLMSyncSubscriptionEnumerator alloc] initWithSubscriptionSet:self];
}

- (NSUInteger)count {
    return _subscriptionSet->size();
}

- (nullable NSError *)error {
    _subscriptionSet->refresh();
    NSString *errorMessage = RLMStringDataToNSString(_subscriptionSet->error_str());
    if (errorMessage.length == 0) {
        return nil;
    }
    return [[NSError alloc] initWithDomain:RLMSyncErrorDomain
                                      code:RLMSyncErrorInvalidFlexibleSyncSubscriptions
                                  userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
}

- (RLMSyncSubscriptionState)state {
    _subscriptionSet->refresh();
    switch (_subscriptionSet->state()) {
        case realm::sync::SubscriptionSet::State::Uncommitted:
        case realm::sync::SubscriptionSet::State::Pending:
        case realm::sync::SubscriptionSet::State::Bootstrapping:
        case realm::sync::SubscriptionSet::State::AwaitingMark:
            return RLMSyncSubscriptionStatePending;
        case realm::sync::SubscriptionSet::State::Complete:
            return RLMSyncSubscriptionStateComplete;
        case realm::sync::SubscriptionSet::State::Error:
            return RLMSyncSubscriptionStateError;
        case realm::sync::SubscriptionSet::State::Superseded:
            return RLMSyncSubscriptionStateSuperseded;
    }
}

#pragma mark - Batch Update subscriptions

- (void)update:(__attribute__((noescape)) void(^)(void))block {
    return [self update:block onComplete:nil];
}

- (void)update:(__attribute__((noescape)) void(^)(void))block onComplete:(void(^)(NSError *))completionBlock {
    if (_mutableSubscriptionSet) {
        @throw RLMException(@"Cannot initiate a write transaction on subscription set that is already being updated.");
    }
    _mutableSubscriptionSet = std::make_unique<realm::sync::MutableSubscriptionSet>(_subscriptionSet->make_mutable_copy());
    realm::util::ScopeExit cleanup([&]() noexcept {
        if (_mutableSubscriptionSet) {
            _mutableSubscriptionSet = nullptr;
            _subscriptionSet->refresh();
        }
    });

    block();

    try {
        _subscriptionSet = std::make_unique<realm::sync::SubscriptionSet>(std::move(*_mutableSubscriptionSet).commit());
        _mutableSubscriptionSet = nullptr;
    }
    catch (realm::Exception const& ex) {
        @throw RLMException(ex);
    }
    catch (std::exception const& ex) {
        @throw RLMException(ex);
    }

    if (completionBlock) {
        [self waitForSynchronizationOnQueue:nil completionBlock:completionBlock];
    }
}

- (void)waitForSynchronizationOnQueue:(nullable dispatch_queue_t)queue
                      completionBlock:(void(^)(NSError *))completionBlock {
    _subscriptionSet->get_state_change_notification(realm::sync::SubscriptionSet::State::Complete)
        .get_async([completionBlock, queue](realm::StatusWith<realm::sync::SubscriptionSet::State> state) noexcept {
            if (queue) {
                return dispatch_async(queue, ^{
                    completionBlock(makeError(state));
                });
            }
            return completionBlock(makeError(state));
        });
}

#pragma mark - Find subscription

- (nullable RLMSyncSubscription *)subscriptionWithName:(NSString *)name {
    auto subscription = _subscriptionSet->find([name UTF8String]);
    if (subscription) {
        return [[RLMSyncSubscription alloc] initWithSubscription:*subscription
                                                 subscriptionSet:self];
    }
    return nil;
}

- (nullable RLMSyncSubscription *)subscriptionWithClassName:(NSString *)objectClassName
                                                      where:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    return [self subscriptionWithClassName:objectClassName
                                     where:predicateFormat
                                      args:args];
    va_end(args);
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
    auto subscription = _subscriptionSet->find(query);
    if (subscription) {
        return [[RLMSyncSubscription alloc] initWithSubscription:*subscription
                                                 subscriptionSet:self];
    }
    return nil;
}


#pragma mark - Add a Subscription

- (void)addSubscriptionWithClassName:(NSString *)objectClassName
                               where:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    return [self addSubscriptionWithClassName:objectClassName
                                        where:predicateFormat
                                         args:args];
    va_end(args);
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
    va_end(args);
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
    
    if (name) {
        if (updateExisting || !_mutableSubscriptionSet->find(name.UTF8String)) {
            _mutableSubscriptionSet->insert_or_assign(name.UTF8String, query);
        }
        else {
            @throw RLMException(@"A subscription named '%@' already exists. If you meant to update the existing subscription please use the `update` method.", name);
        }
    }
    else {
        _mutableSubscriptionSet->insert_or_assign(query);
    }
}

#pragma mark - Remove Subscription

- (void)removeSubscriptionWithName:(NSString *)name {
    [self verifyInWriteTransaction];

    auto subscription = _subscriptionSet->find([name UTF8String]);
    if (subscription) {
        _mutableSubscriptionSet->erase(subscription->name);
    }
}

- (void)removeSubscriptionWithClassName:(NSString *)objectClassName
                                  where:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    [self removeSubscriptionWithClassName:objectClassName
                                    where:predicateFormat
                                     args:args];
    va_end(args);
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
    auto subscription = _subscriptionSet->find(query);
    if (subscription) {
        _mutableSubscriptionSet->erase(query);
    }
}

- (void)removeSubscription:(RLMSyncSubscription *)subscription {
    [self verifyInWriteTransaction];

    for (auto it = _mutableSubscriptionSet->begin(); it != _mutableSubscriptionSet->end();) {
        if (it->id == subscription.identifier.value) {
            it = _mutableSubscriptionSet->erase(it);
            return;
        }
        it++;
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
        if (it->object_class_name == [className UTF8String]) {
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
    return RLMFastEnumerate(state, len, self);
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
        return nil;
    }
    return [[RLMSyncSubscription alloc]initWithSubscription:_subscriptionSet->at(size_t(0))
                                            subscriptionSet:self];
}

- (RLMSyncSubscription *)lastObject {
    if (_subscriptionSet->size() < 1) {
        return nil;
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
    if (_mutableSubscriptionSet == nil) {
        @throw RLMException(@"Can only add, remove, or update subscriptions within a write subscription block.");
    }
}

@end
