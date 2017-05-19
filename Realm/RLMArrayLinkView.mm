////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#import "RLMArray_Private.hpp"

#import "RLMAccessor.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSchema.h"
#import "RLMThreadSafeReference_Private.hpp"
#import "RLMUtil.hpp"

#import "list.hpp"
#import "results.hpp"
#import "shared_realm.hpp"

#import <realm/table_view.hpp>
#import <objc/runtime.h>

@interface RLMArrayLinkViewHandoverMetadata : NSObject
@property (nonatomic) NSString *parentClassName;
@property (nonatomic) NSString *key;
@end

@implementation RLMArrayLinkViewHandoverMetadata
@end

@interface RLMArrayLinkView () <RLMThreadConfined_Private>
@end

//
// RLMArray implementation
//
@implementation RLMArrayLinkView {
@public
    realm::List _backingList;
    RLMRealm *_realm;
    RLMClassInfo *_objectInfo;
    RLMClassInfo *_ownerInfo;
    std::unique_ptr<RLMObservationInfo> _observationInfo;
}

- (RLMArrayLinkView *)initWithList:(realm::List)list
                             realm:(__unsafe_unretained RLMRealm *const)realm
                        parentInfo:(RLMClassInfo *)parentInfo
                          property:(__unsafe_unretained RLMProperty *const)property {
    self = [self initWithObjectClassName:property.objectClassName];
    if (self) {
        _realm = realm;
        REALM_ASSERT(list.get_realm() == realm->_realm);
        _backingList = std::move(list);
        _objectInfo = &parentInfo->linkTargetType(property.index);
        _ownerInfo = parentInfo;
        _key = property.name;
    }
    return self;
}

- (RLMArrayLinkView *)initWithParent:(__unsafe_unretained RLMObjectBase *const)parentObject
                            property:(__unsafe_unretained RLMProperty *const)property {
    __unsafe_unretained RLMRealm *const realm = parentObject->_realm;
    auto col = parentObject->_info->tableColumn(property);
    realm::List list(realm->_realm, parentObject->_row.get_linklist(col));
    return [self initWithList:std::move(list)
                        realm:realm
                   parentInfo:parentObject->_info
                     property:property];
}

void RLMValidateArrayObservationKey(__unsafe_unretained NSString *const keyPath,
                                    __unsafe_unretained RLMArray *const array) {
    if (![keyPath isEqualToString:RLMInvalidatedKey]) {
        @throw RLMException(@"[<%@ %p> addObserver:forKeyPath:options:context:] is not supported. Key path: %@",
                            [array class], array, keyPath);
    }
}

void RLMEnsureArrayObservationInfo(std::unique_ptr<RLMObservationInfo>& info,
                                   __unsafe_unretained NSString *const keyPath,
                                   __unsafe_unretained RLMArray *const array,
                                   __unsafe_unretained id const observed) {
    RLMValidateArrayObservationKey(keyPath, array);
    if (!info && array.class == [RLMArrayLinkView class]) {
        RLMArrayLinkView *lv = static_cast<RLMArrayLinkView *>(array);
        info = std::make_unique<RLMObservationInfo>(*lv->_ownerInfo,
                                                    lv->_backingList.get_origin_row_index(),
                                                    observed);
    }
}

//
// validation helpers
//
[[gnu::noinline]]
[[noreturn]]
static void throwError(NSString *aggregateMethod) {
    try {
        throw;
    }
    catch (realm::InvalidTransactionException const&) {
        @throw RLMException(@"Cannot modify managed RLMArray outside of a write transaction");
    }
    catch (realm::IncorrectThreadException const&) {
        @throw RLMException(@"Realm accessed from incorrect thread");
    }
    catch (realm::List::InvalidatedException const&) {
        @throw RLMException(@"RLMArray has been invalidated or the containing object has been deleted");
    }
    catch (realm::List::OutOfBoundsIndexException const& e) {
        @throw RLMException(@"Index %zu is out of bounds (must be less than %zu)",
                            e.requested, e.valid_count);
    }
    catch (realm::Results::UnsupportedColumnTypeException const& e) {
        @throw RLMException(@"%@ is not supported for %@ property '%s'",
                            aggregateMethod,
                            RLMTypeToString((RLMPropertyType)e.column_type),
                            e.column_name.data());
    }
    catch (std::logic_error const& e) {
        @throw RLMException(e);
    }
}

template<typename Function>
static auto translateErrors(Function&& f, NSString *aggregateMethod=nil) {
    try {
        return f();
    }
    catch (...) {
        throwError(aggregateMethod);
    }
}

template<typename IndexSetFactory>
static void changeArray(__unsafe_unretained RLMArrayLinkView *const ar,
                        NSKeyValueChange kind, dispatch_block_t f, IndexSetFactory&& is) {
    translateErrors([&] { ar->_backingList.verify_in_transaction(); });
    RLMObservationInfo *info = RLMGetObservationInfo(ar->_observationInfo.get(),
                                                     ar->_backingList.get_origin_row_index(),
                                                     *ar->_ownerInfo);
    if (info) {
        NSIndexSet *indexes = is();
        info->willChange(ar->_key, kind, indexes);
        try {
            f();
        }
        catch (...) {
            info->didChange(ar->_key, kind, indexes);
            throwError(nil);
        }
        info->didChange(ar->_key, kind, indexes);
    }
    else {
        translateErrors([&] { f(); });
    }
}

static void changeArray(__unsafe_unretained RLMArrayLinkView *const ar, NSKeyValueChange kind, NSUInteger index, dispatch_block_t f) {
    changeArray(ar, kind, f, [=] { return [NSIndexSet indexSetWithIndex:index]; });
}

static void changeArray(__unsafe_unretained RLMArrayLinkView *const ar, NSKeyValueChange kind, NSRange range, dispatch_block_t f) {
    changeArray(ar, kind, f, [=] { return [NSIndexSet indexSetWithIndexesInRange:range]; });
}

static void changeArray(__unsafe_unretained RLMArrayLinkView *const ar, NSKeyValueChange kind, NSIndexSet *is, dispatch_block_t f) {
    changeArray(ar, kind, f, [=] { return is; });
}

//
// public method implementations
//
- (RLMRealm *)realm {
    return _realm;
}

- (NSUInteger)count {
    return translateErrors([&] { return _backingList.size(); });
}

- (BOOL)isInvalidated {
    return translateErrors([&] { return !_backingList.is_valid(); });
}

- (RLMClassInfo *)objectInfo {
    return _objectInfo;
}

- (BOOL)isEqual:(id)object {
    if (RLMArrayLinkView *linkView = RLMDynamicCast<RLMArrayLinkView>(object)) {
        return linkView->_backingList == _backingList;
    }
    return NO;
}

- (NSUInteger)hash {
    return std::hash<realm::List>()(_backingList);
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    __autoreleasing RLMFastEnumerator *enumerator;
    if (state->state == 0) {
        translateErrors([&] { _backingList.verify_attached(); });

        enumerator = [[RLMFastEnumerator alloc] initWithCollection:self objectSchema:*_objectInfo];
        state->extra[0] = (long)enumerator;
        state->extra[1] = self.count;
    }
    else {
        enumerator = (__bridge id)(void *)state->extra[0];
    }

    return [enumerator countByEnumeratingWithState:state count:len];
}

- (id)objectAtIndex:(NSUInteger)index {
    return translateErrors([&] {
        RLMAccessorContext context(_realm, *_objectInfo);
        return _backingList.get(context, index);
    });
}

static void RLMInsertObject(RLMArrayLinkView *ar, id object, NSUInteger index) {
    if (index == NSUIntegerMax) {
        index = translateErrors([&] { return ar->_backingList.size(); });
    }

    changeArray(ar, NSKeyValueChangeInsertion, index, ^{
        RLMAccessorContext context(ar->_realm, *ar->_objectInfo);
        ar->_backingList.insert(context, index, object);
    });
}

- (void)addObject:(id)object {
    RLMInsertObject(self, object, NSUIntegerMax);
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index {
    RLMInsertObject(self, object, index);
}

- (void)insertObjects:(id<NSFastEnumeration>)objects atIndexes:(NSIndexSet *)indexes {
    changeArray(self, NSKeyValueChangeInsertion, indexes, ^{
        NSUInteger index = [indexes firstIndex];
        RLMAccessorContext context(_realm, *_objectInfo);
        for (id obj in objects) {
            _backingList.insert(context, index, obj);
            index = [indexes indexGreaterThanIndex:index];
        }
    });
}


- (void)removeObjectAtIndex:(NSUInteger)index {
    changeArray(self, NSKeyValueChangeRemoval, index, ^{
        _backingList.remove(index);
    });
}

- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes {
    changeArray(self, NSKeyValueChangeRemoval, indexes, ^{
        [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *) {
            _backingList.remove(idx);
        }];
    });
}

- (void)addObjectsFromArray:(NSArray *)array {
    changeArray(self, NSKeyValueChangeInsertion, NSMakeRange(self.count, array.count), ^{
        RLMAccessorContext context(_realm, *_objectInfo);
        for (id obj in array) {
            _backingList.add(context, obj);
        }
    });
}

- (void)removeAllObjects {
    changeArray(self, NSKeyValueChangeRemoval, NSMakeRange(0, self.count), ^{
        _backingList.remove_all();
    });
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object {
    changeArray(self, NSKeyValueChangeReplacement, index, ^{
        RLMAccessorContext context(_realm, *_objectInfo);
        _backingList.set(context, index, object);
    });
}

- (void)moveObjectAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex {
    auto start = std::min(sourceIndex, destinationIndex);
    auto len = std::max(sourceIndex, destinationIndex) - start + 1;
    changeArray(self, NSKeyValueChangeReplacement, {start, len}, ^{
        _backingList.move(sourceIndex, destinationIndex);
    });
}

- (void)exchangeObjectAtIndex:(NSUInteger)index1 withObjectAtIndex:(NSUInteger)index2 {
    changeArray(self, NSKeyValueChangeReplacement, ^{
        _backingList.swap(index1, index2);
    }, [=] {
        NSMutableIndexSet *set = [[NSMutableIndexSet alloc] initWithIndex:index1];
        [set addIndex:index2];
        return set;
    });
}

- (NSUInteger)indexOfObject:(id)object {
    return translateErrors([&] {
        RLMAccessorContext context(_realm, *_objectInfo);
        return RLMConvertNotFound(_backingList.find(context, object));
    });
}

- (id)valueForKeyPath:(NSString *)keyPath {
    if ([keyPath hasPrefix:@"@"]) {
        // Delegate KVC collection operators to RLMResults
        auto query = translateErrors([&] { return _backingList.get_query(); });
        RLMResults *results = [RLMResults resultsWithObjectInfo:*_objectInfo
                                                        results:realm::Results(_realm->_realm, std::move(query))];
        return [results valueForKeyPath:keyPath];
    }
    return [super valueForKeyPath:keyPath];
}

- (id)valueForKey:(NSString *)key {
    // Ideally we'd use "@invalidated" for this so that "invalidated" would use
    // normal array KVC semantics, but observing @things works very oddly (when
    // it's part of a key path, it's triggered automatically when array index
    // changes occur, and can't be sent explicitly, but works normally when it's
    // the entire key path), and an RLMArrayLinkView *can't* have objects where
    // invalidated is true, so we're not losing much.
    if ([key isEqualToString:RLMInvalidatedKey]) {
        return @(!_backingList.is_valid());
    }

    translateErrors([&] { _backingList.verify_attached(); });
    return RLMCollectionValueForKey(self, key);
}

- (void)setValue:(id)value forKey:(NSString *)key {
    translateErrors([&] { _backingList.verify_in_transaction(); });
    RLMCollectionSetValueForKey(self, key, value);
}

- (id)aggregate:(NSString *)property
         method:(realm::util::Optional<realm::Mixed> (realm::List::*)(size_t))method
     methodName:(NSString *)methodName {
    size_t column = _objectInfo->tableColumn(property);
    auto value = translateErrors([&] { return (_backingList.*method)(column); }, methodName);
    if (!value) {
        return nil;
    }
    return RLMMixedToObjc(*value);
}

- (id)minOfProperty:(NSString *)property {
    return [self aggregate:property method:&realm::List::min methodName:@"minOfProperty"];
}

- (id)maxOfProperty:(NSString *)property {
    return [self aggregate:property method:&realm::List::max methodName:@"maxOfProperty"];
}

- (id)sumOfProperty:(NSString *)property {
    return [self aggregate:property method:&realm::List::sum methodName:@"sumOfProperty"];
}

- (id)averageOfProperty:(NSString *)property {
    return [self aggregate:property method:&realm::List::average methodName:@"averageOfProperty"];
}

- (void)deleteObjectsFromRealm {
    // delete all target rows from the realm
    RLMTrackDeletions(_realm, ^{
        translateErrors([&] { _backingList.delete_all(); });
    });
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray<RLMSortDescriptor *> *)properties {
    if (properties.count == 0) {
        auto results = translateErrors([&] { return _backingList.filter({}); });
        return [RLMResults resultsWithObjectInfo:*_objectInfo results:std::move(results)];
    }

    auto order = RLMSortDescriptorFromDescriptors(*_objectInfo, properties);
    auto results = translateErrors([&] { return _backingList.sort(std::move(order)); });
    return [RLMResults resultsWithObjectInfo:*_objectInfo results:std::move(results)];
}

- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate {
    auto query = RLMPredicateToQuery(predicate, _objectInfo->rlmObjectSchema, _realm.schema, _realm.group);
    auto results = translateErrors([&] { return _backingList.filter(std::move(query)); });
    return [RLMResults resultsWithObjectInfo:*_objectInfo results:std::move(results)];
}

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate {
    auto query = translateErrors([&] { return _backingList.get_query(); });
    query.and_query(RLMPredicateToQuery(predicate, _objectInfo->rlmObjectSchema,
                                        _realm.schema, _realm.group));

    auto indexInTable = query.find();
    if (indexInTable == realm::not_found) {
        return NSNotFound;
    }
    auto row = query.get_table()->get(indexInTable);
    return _backingList.find(row);
}

- (NSArray *)objectsAtIndexes:(__unused NSIndexSet *)indexes {
    // FIXME: this is called by KVO when array changes are made. It's not clear
    // why, and returning nil seems to work fine.
    return nil;
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
            context:(void *)context {
    RLMEnsureArrayObservationInfo(_observationInfo, keyPath, self, self);
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (NSUInteger)indexInSource:(NSUInteger)index {
    return _backingList.get_unchecked(index);
}

- (realm::TableView)tableView {
    return translateErrors([&] { return _backingList.get_query(); }).find_all();
}

// The compiler complains about the method's argument type not matching due to
// it not having the generic type attached, but it doesn't seem to be possible
// to actually include the generic type
// http://www.openradar.me/radar?id=6135653276319744
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMArray *, RLMCollectionChange *, NSError *))block {
    [_realm verifyNotificationsAreSupported];
    return RLMAddNotificationBlock(self, _backingList, block);
}
#pragma clang diagnostic pop

#pragma mark - Thread Confined Protocol Conformance

- (std::unique_ptr<realm::ThreadSafeReferenceBase>)makeThreadSafeReference {
    auto list_reference = _realm->_realm->obtain_thread_safe_reference(_backingList);
    return std::make_unique<realm::ThreadSafeReference<realm::List>>(std::move(list_reference));
}

- (RLMArrayLinkViewHandoverMetadata *)objectiveCMetadata {
    RLMArrayLinkViewHandoverMetadata *metadata = [[RLMArrayLinkViewHandoverMetadata alloc] init];
    metadata.parentClassName = _ownerInfo->rlmObjectSchema.className;
    metadata.key = _key;
    return metadata;
}

+ (instancetype)objectWithThreadSafeReference:(std::unique_ptr<realm::ThreadSafeReferenceBase>)reference
                                     metadata:(RLMArrayLinkViewHandoverMetadata *)metadata
                                        realm:(RLMRealm *)realm {
    REALM_ASSERT_DEBUG(dynamic_cast<realm::ThreadSafeReference<realm::List> *>(reference.get()));
    auto list_reference = static_cast<realm::ThreadSafeReference<realm::List> *>(reference.get());

    auto list = realm->_realm->resolve_thread_safe_reference(std::move(*list_reference));
    if (!list.is_valid()) {
        return nil;
    }
    RLMClassInfo *parentInfo = &realm->_info[metadata.parentClassName];
    return [[RLMArrayLinkView alloc] initWithList:std::move(list)
                                            realm:realm
                                       parentInfo:parentInfo
                                         property:parentInfo->rlmObjectSchema[metadata.key]];
}

@end
