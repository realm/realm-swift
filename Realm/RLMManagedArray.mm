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
#import "RLMCollection_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.hpp"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMSchema.h"
#import "RLMSectionedResults_Private.hpp"
#import "RLMThreadSafeReference_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/mixed.hpp>
#import <realm/object-store/list.hpp>
#import <realm/object-store/results.hpp>
#import <realm/object-store/shared_realm.hpp>
#import <realm/table_view.hpp>

#import <objc/runtime.h>

@interface RLMManagedArrayHandoverMetadata : NSObject
@property (nonatomic) NSString *parentClassName;
@property (nonatomic) NSString *key;
@end

@implementation RLMManagedArrayHandoverMetadata
@end

@interface RLMManagedArray () <RLMThreadConfined_Private>
@end

//
// RLMArray implementation
//
@implementation RLMManagedArray {
@public
    realm::List _backingList;
    RLMRealm *_realm;
    RLMClassInfo *_objectInfo;
    RLMClassInfo *_ownerInfo;
    std::unique_ptr<RLMObservationInfo> _observationInfo;
}

- (RLMManagedArray *)initWithBackingCollection:(realm::List)list
                                    parentInfo:(RLMClassInfo *)parentInfo
                                      property:(__unsafe_unretained RLMProperty *const)property {
    if (property.type == RLMPropertyTypeObject)
        self = [self initWithObjectClassName:property.objectClassName];
    else
        self = [self initWithObjectType:property.type
                               optional:property.optional];
    if (self) {
        _realm = parentInfo->realm;
        REALM_ASSERT(list.get_realm() == _realm->_realm);
        _backingList = std::move(list);
        _ownerInfo = parentInfo;
        _property = property;
        if (property.type == RLMPropertyTypeObject)
            _objectInfo = &parentInfo->linkTargetType(property.index);
        else
            _objectInfo = _ownerInfo;
    }
    return self;
}

- (RLMManagedArray *)initWithParent:(realm::Obj)parent
                           property:(__unsafe_unretained RLMProperty *const)property
                         parentInfo:(RLMClassInfo&)info {
    auto col = info.tableColumn(property);
    return [self initWithBackingCollection:realm::List(info.realm->_realm, parent, col)
                                parentInfo:&info
                                  property:property];
}

- (RLMManagedArray *)initWithParent:(__unsafe_unretained RLMObjectBase *const)parentObject
                           property:(__unsafe_unretained RLMProperty *const)property {
    return [self initWithParent:parentObject->_row
                       property:property
                     parentInfo:*parentObject->_info];
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
    if (!info && array.class == [RLMManagedArray class]) {
        auto lv = static_cast<RLMManagedArray *>(array);
        info = std::make_unique<RLMObservationInfo>(*lv->_ownerInfo,
                                                    lv->_backingList.get_parent_object_key(),
                                                    observed);
    }
}

template<typename Function>
__attribute__((always_inline))
static auto translateErrors(Function&& f) {
    return translateCollectionError(static_cast<Function&&>(f), @"List");
}

template<typename IndexSetFactory>
static void changeArray(__unsafe_unretained RLMManagedArray *const ar,
                        NSKeyValueChange kind, dispatch_block_t f, IndexSetFactory&& is) {
    translateErrors([&] { ar->_backingList.verify_in_transaction(); });

    RLMObservationTracker tracker(ar->_realm);
    tracker.trackDeletions();
    auto obsInfo = RLMGetObservationInfo(ar->_observationInfo.get(),
                                         ar->_backingList.get_parent_object_key(),
                                         *ar->_ownerInfo);
    if (obsInfo) {
        tracker.willChange(obsInfo, ar->_property.name, kind, is());
    }

    translateErrors(f);
}

static void changeArray(__unsafe_unretained RLMManagedArray *const ar, NSKeyValueChange kind, NSUInteger index, dispatch_block_t f) {
    changeArray(ar, kind, f, [=] { return [NSIndexSet indexSetWithIndex:index]; });
}

static void changeArray(__unsafe_unretained RLMManagedArray *const ar, NSKeyValueChange kind, NSRange range, dispatch_block_t f) {
    changeArray(ar, kind, f, [=] { return [NSIndexSet indexSetWithIndexesInRange:range]; });
}

static void changeArray(__unsafe_unretained RLMManagedArray *const ar, NSKeyValueChange kind, NSIndexSet *is, dispatch_block_t f) {
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


- (bool)isBackedByList:(realm::List const&)list {
    return _backingList == list;
}

- (BOOL)isEqual:(id)object {
    return [object respondsToSelector:@selector(isBackedByList:)] && [object isBackedByList:_backingList];
}

- (NSUInteger)hash {
    return std::hash<realm::List>()(_backingList);
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    return RLMFastEnumerate(state, len, self);
}

- (id)objectAtIndex:(NSUInteger)index {
    return translateErrors([&]() -> id {
        RLMAccessorContext context(*_ownerInfo, *_objectInfo, _property);
        return _backingList.get(context, index);
    });
}

static void RLMInsertObject(RLMManagedArray *ar, id object, NSUInteger index) {
    RLMArrayValidateMatchingObjectType(ar, object);
    if (index == NSUIntegerMax) {
        index = translateErrors([&] { return ar->_backingList.size(); });
    }

    changeArray(ar, NSKeyValueChangeInsertion, index, ^{
        RLMAccessorContext context(*ar->_ownerInfo, *ar->_objectInfo, ar->_property);
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
        RLMAccessorContext context(*_ownerInfo, *_objectInfo, _property);
        for (id obj in objects) {
            RLMArrayValidateMatchingObjectType(self, obj);
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
        RLMAccessorContext context(*_ownerInfo, *_objectInfo, _property);
        for (id obj in array) {
            RLMArrayValidateMatchingObjectType(self, obj);
            _backingList.add(context, obj);
        }
    });
}

- (void)removeAllObjects {
    changeArray(self, NSKeyValueChangeRemoval, NSMakeRange(0, self.count), ^{
        _backingList.remove_all();
    });
}

- (void)replaceAllObjectsWithObjects:(NSArray *)objects {
    if (auto count = self.count) {
        changeArray(self, NSKeyValueChangeRemoval, NSMakeRange(0, count), ^{
            _backingList.remove_all();
        });
    }
    if (![objects respondsToSelector:@selector(count)] || !objects.count) {
        return;
    }
    changeArray(self, NSKeyValueChangeInsertion, NSMakeRange(0, objects.count), ^{
        RLMAccessorContext context(*_ownerInfo, *_objectInfo, _property);
        _backingList.assign(context, objects);
    });
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object {
    RLMArrayValidateMatchingObjectType(self, object);
    changeArray(self, NSKeyValueChangeReplacement, index, ^{
        RLMAccessorContext context(*_ownerInfo, *_objectInfo, _property);
        if (index >= _backingList.size()) {
            @throw RLMException(@"Index %llu is out of bounds (must be less than %llu).",
                                (unsigned long long)index, (unsigned long long)_backingList.size());
        }
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
    RLMArrayValidateMatchingObjectType(self, object);
    return translateErrors([&] {
        RLMAccessorContext context(*_ownerInfo, *_objectInfo, _property);
        return RLMConvertNotFound(_backingList.find(context, object));
    });
}

- (id)valueForKeyPath:(NSString *)keyPath {
    if ([keyPath hasPrefix:@"@"]) {
        // Delegate KVC collection operators to RLMResults
        return translateErrors([&] {
            auto results = [RLMResults resultsWithObjectInfo:*_objectInfo results:_backingList.as_results()];
            return [results valueForKeyPath:keyPath];
        });
    }
    return [super valueForKeyPath:keyPath];
}

- (id)valueForKey:(NSString *)key {
    // Ideally we'd use "@invalidated" for this so that "invalidated" would use
    // normal array KVC semantics, but observing @things works very oddly (when
    // it's part of a key path, it's triggered automatically when array index
    // changes occur, and can't be sent explicitly, but works normally when it's
    // the entire key path), and an RLMManagedArray *can't* have objects where
    // invalidated is true, so we're not losing much.
    return translateErrors([&]() -> id {
        if ([key isEqualToString:RLMInvalidatedKey]) {
            return @(!_backingList.is_valid());
        }

        _backingList.verify_attached();
        return RLMCollectionValueForKey(_backingList, key, *_objectInfo);
    });
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"self"]) {
        RLMArrayValidateMatchingObjectType(self, value);
        RLMAccessorContext context(*_ownerInfo, *_objectInfo, _property);
        translateErrors([&] {
            for (size_t i = 0, count = _backingList.size(); i < count; ++i) {
                _backingList.set(context, i, value);
            }
        });
        return;
    }
    else if (_property->_type == RLMPropertyTypeObject) {
        RLMArrayValidateMatchingObjectType(self, value);
        translateErrors([&] { _backingList.verify_in_transaction(); });
        RLMCollectionSetValueForKey(self, key, value);
    }
    else {
        [self setValue:value forUndefinedKey:key];
    }
}

- (id)minOfProperty:(NSString *)property {
    auto column = columnForProperty(property, _backingList, _objectInfo, _property->_type, RLMCollectionTypeArray);
    auto value = translateErrors([&] { return _backingList.min(column); });
    return value ? RLMMixedToObjc(*value) : nil;
}

- (id)maxOfProperty:(NSString *)property {
    auto column = columnForProperty(property, _backingList, _objectInfo, _property->_type, RLMCollectionTypeArray);
    auto value = translateErrors([&] { return _backingList.max(column); });
    return value ? RLMMixedToObjc(*value) : nil;
}

- (id)sumOfProperty:(NSString *)property {
    auto column = columnForProperty(property, _backingList, _objectInfo, _property->_type, RLMCollectionTypeArray);
    return RLMMixedToObjc(translateErrors([&] { return _backingList.sum(column); }));
}

- (id)averageOfProperty:(NSString *)property {
    auto column = columnForProperty(property, _backingList, _objectInfo, _property->_type, RLMCollectionTypeArray);
    auto value = translateErrors([&] { return _backingList.average(column); });
    return value ? RLMMixedToObjc(*value) : nil;
}

- (void)deleteObjectsFromRealm {
    auto type = _property->_type;
    if (type != RLMPropertyTypeObject) {
        @throw RLMException(@"Cannot delete objects from RLMArray<%@>: only RLMObjects can be deleted.", RLMTypeToString(type));
    }
    // delete all target rows from the realm
    RLMObservationTracker tracker(_realm, true);
    translateErrors([&] { _backingList.delete_all(); });
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray<RLMSortDescriptor *> *)properties {
    return translateErrors([&] {
        return [RLMResults resultsWithObjectInfo:*_objectInfo
                                         results:_backingList.sort(RLMSortDescriptorsToKeypathArray(properties))];
    });
}

- (RLMResults *)distinctResultsUsingKeyPaths:(NSArray<NSString *> *)keyPaths {
    return translateErrors([&] {
        auto results = [RLMResults resultsWithObjectInfo:*_objectInfo results:_backingList.as_results()];
        return [results distinctResultsUsingKeyPaths:keyPaths];
    });
}

- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate {
    if (_property->_type != RLMPropertyTypeObject) {
        @throw RLMException(@"Querying is currently only implemented for arrays of Realm Objects");
    }
    auto query = RLMPredicateToQuery(predicate, _objectInfo->rlmObjectSchema, _realm.schema, _realm.group);
    auto results = translateErrors([&] { return _backingList.filter(std::move(query)); });
    return [RLMResults resultsWithObjectInfo:*_objectInfo results:std::move(results)];
}

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate {
    if (_property->_type != RLMPropertyTypeObject) {
        @throw RLMException(@"Querying is currently only implemented for arrays of Realm Objects");
    }
    realm::Query query = RLMPredicateToQuery(predicate, _objectInfo->rlmObjectSchema,
                                             _realm.schema, _realm.group);

    return translateErrors([&] {
        return RLMConvertNotFound(_backingList.find(std::move(query)));
    });
}

- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes {
    size_t c = self.count;
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:indexes.count];
    NSUInteger i = [indexes firstIndex];
    RLMAccessorContext context(*_ownerInfo, *_objectInfo, _property);
    while (i != NSNotFound) {
        // Given KVO relies on `objectsAtIndexes` we need to make sure
        // that no out of bounds exceptions are generated. This disallows us to mirror
        // the exception logic in Foundation, but it is better than nothing.
        if (i >= 0 && i < c) {
            [result addObject:_backingList.get(context, i)];
        } else {
            // silently abort.
            return nil;
        }
        i = [indexes indexGreaterThanIndex:i];
    }
    return result;
}

- (RLMSectionedResults *)sectionedResultsSortedUsingKeyPath:(NSString *)keyPath
                                                  ascending:(BOOL)ascending
                                                   keyBlock:(RLMSectionedResultsKeyBlock)keyBlock {
    return [[RLMSectionedResults alloc] initWithResults:[self sortedResultsUsingKeyPath:keyPath ascending:ascending]
                                               keyBlock:keyBlock];
}

- (RLMSectionedResults *)sectionedResultsUsingSortDescriptors:(NSArray<RLMSortDescriptor *> *)sortDescriptors
                                                     keyBlock:(RLMSectionedResultsKeyBlock)keyBlock {
    return [[RLMSectionedResults alloc] initWithResults:[self sortedResultsUsingDescriptors:sortDescriptors]
                                               keyBlock:keyBlock];
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
            context:(void *)context {
    RLMEnsureArrayObservationInfo(_observationInfo, keyPath, self, self);
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (realm::TableView)tableView {
    return translateErrors([&] { return _backingList.get_query(); }).find_all();
}

- (RLMFastEnumerator *)fastEnumerator {
    return translateErrors([&] {
        return [[RLMFastEnumerator alloc] initWithBackingCollection:_backingList
                                                         collection:self
                                                          classInfo:_objectInfo
                                                         parentInfo:_ownerInfo
                                                           property:_property];
    });
}

- (BOOL)isFrozen {
    return _realm.isFrozen;
}

- (instancetype)resolveInRealm:(RLMRealm *)realm {
    auto& parentInfo = _ownerInfo->resolve(realm);
    return translateErrors([&] {
        return [[self.class alloc] initWithBackingCollection:_backingList.freeze(realm->_realm)
                                                  parentInfo:&parentInfo
                                                    property:parentInfo.rlmObjectSchema[_property.name]];
    });
}

- (instancetype)freeze {
    if (self.frozen) {
        return self;
    }
    return [self resolveInRealm:_realm.freeze];
}

- (instancetype)thaw {
    if (!self.frozen) {
        return self;
    }
    return [self resolveInRealm:_realm.thaw];
}

- (realm::NotificationToken)addNotificationCallback:(id)block
keyPaths:(std::optional<std::vector<std::vector<std::pair<realm::TableKey, realm::ColKey>>>>&&)keyPaths {
    return _backingList.add_notification_callback(RLMWrapCollectionChangeCallback(block, self, false), std::move(keyPaths));
}

#pragma mark - Thread Confined Protocol Conformance

- (realm::ThreadSafeReference)makeThreadSafeReference {
    return _backingList;
}

- (RLMManagedArrayHandoverMetadata *)objectiveCMetadata {
    RLMManagedArrayHandoverMetadata *metadata = [[RLMManagedArrayHandoverMetadata alloc] init];
    metadata.parentClassName = _ownerInfo->rlmObjectSchema.className;
    metadata.key = _property.name;
    return metadata;
}

+ (instancetype)objectWithThreadSafeReference:(realm::ThreadSafeReference)reference
                                     metadata:(RLMManagedArrayHandoverMetadata *)metadata
                                        realm:(RLMRealm *)realm {
    auto list = reference.resolve<realm::List>(realm->_realm);
    if (!list.is_valid()) {
        return nil;
    }
    RLMClassInfo *parentInfo = &realm->_info[metadata.parentClassName];
    return [[RLMManagedArray alloc] initWithBackingCollection:std::move(list)
                                                   parentInfo:parentInfo
                                                     property:parentInfo->rlmObjectSchema[metadata.key]];
}

@end
