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

#import "RLMDictionary_Private.hpp"

#import "RLMAccessor.hpp"
#import "RLMCollection_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMRealmConfiguration_Private.hpp"
#import "RLMSchema.h"
#import "RLMThreadSafeReference_Private.hpp"
#import "RLMUtil.hpp"

#import <realm/object-store/results.hpp>
#import <realm/object-store/shared_realm.hpp>
#import <realm/table_view.hpp>

@interface RLMManagedCollectionHandoverMetadata : NSObject
@property (nonatomic) NSString *parentClassName;
@property (nonatomic) NSString *key;
@end

@implementation RLMManagedCollectionHandoverMetadata
@end

@interface RLMManagedDictionary () <RLMThreadConfined_Private>
@end

@implementation RLMManagedDictionary {
@public
    realm::object_store::Dictionary _backingCollection;
    RLMRealm *_realm;
    RLMClassInfo *_objectInfo;
    RLMClassInfo *_ownerInfo;
    std::unique_ptr<RLMObservationInfo> _observationInfo;
}

- (RLMManagedDictionary *)initWithBackingCollection:(realm::object_store::Dictionary)dictionary
                                         parentInfo:(RLMClassInfo *)parentInfo
                                           property:(__unsafe_unretained RLMProperty *const)property {
    if (property.type == RLMPropertyTypeObject)
        self = [self initWithObjectClassName:property.objectClassName];
    else
        self = [self initWithObjectType:property.type optional:property.optional];
    if (self) {
        _realm = parentInfo->realm;
        REALM_ASSERT(dictionary.get_realm() == _realm->_realm);
        _backingCollection = std::move(dictionary);
        _ownerInfo = parentInfo;
        if (property.type == RLMPropertyTypeObject)
            _objectInfo = &parentInfo->linkTargetType(property.index);
        else
            _objectInfo = _ownerInfo;
        _key = property.name;
    }
    return self;
}

- (RLMManagedDictionary *)initWithParent:(__unsafe_unretained RLMObjectBase *const)parentObject
                                property:(__unsafe_unretained RLMProperty *const)property {
    __unsafe_unretained RLMRealm *const realm = parentObject->_realm;
    auto col = parentObject->_info->tableColumn(property);
    return [self initWithBackingCollection:realm::object_store::Dictionary(realm->_realm, parentObject->_row, col)
                                parentInfo:parentObject->_info
                                  property:property];
}

template<typename ObjcCollection>
void RLMCollectionValidateObservationKey(__unsafe_unretained NSString *const keyPath,
                                         __unsafe_unretained ObjcCollection *const collection) {
    if (![keyPath isEqualToString:RLMInvalidatedKey]) {
        @throw RLMException(@"[<%@ %p> addObserver:forKeyPath:options:context:] is not supported. Key path: %@",
                            [collection class], collection, keyPath);
    }
}

template<typename ObjcCollection, typename ManagedObjcCollection>
void RLMEnsureCollectionObservationInfo(std::unique_ptr<RLMObservationInfo>& info,
                                        __unsafe_unretained NSString *const keyPath,
                                        __unsafe_unretained ObjcCollection *const collection,
                                        __unsafe_unretained id const observed) {
    RLMCollectionValidateObservationKey<ObjcCollection>(keyPath, collection);
    if (!info && collection.class == [ManagedObjcCollection class]) {
        auto lv = static_cast<ManagedObjcCollection *>(collection);
        info = std::make_unique<RLMObservationInfo>(*lv->_ownerInfo,
                                                    lv->_backingCollection.get_parent_object_key(),
                                                    observed);
    }
}

//
// validation helpers
//
template<typename ObjcCollection>
[[gnu::noinline]]
[[noreturn]]
static void throwError(__unsafe_unretained ObjcCollection *const col, NSString *aggregateMethod) {
    try {
        throw;
    }
    // TODO: Fix up these exceptions
    catch (realm::InvalidTransactionException const&) {
        @throw RLMException(@"Cannot modify managed RLMArray outside of a write transaction.");
    }
    catch (realm::IncorrectThreadException const&) {
        @throw RLMException(@"Realm accessed from incorrect thread.");
    }
    catch (realm::List::InvalidatedException const&) {
        @throw RLMException(@"RLMArray has been invalidated or the containing object has been deleted.");
    }
    catch (realm::List::OutOfBoundsIndexException const& e) {
        @throw RLMException(@"Index %zu is out of bounds (must be less than %zu).",
                            e.requested, e.valid_count);
    }
    catch (realm::Results::UnsupportedColumnTypeException const& e) {
        if (col->_backingCollection.get_type() == realm::PropertyType::Object) {
            @throw RLMException(@"%@: is not supported for %s%s property '%s'.",
                                aggregateMethod,
                                string_for_property_type(e.property_type),
                                is_nullable(e.property_type) ? "?" : "",
                                e.column_name.data());
        }
        @throw RLMException(@"%@: is not supported for %s%s array '%@.%@'.",
                            aggregateMethod,
                            string_for_property_type(e.property_type),
                            is_nullable(e.property_type) ? "?" : "",
                            col->_ownerInfo->rlmObjectSchema.className, col->_key);
    }
    catch (std::logic_error const& e) {
        @throw RLMException(e);
    }
}

template<typename ObjcCollection, typename Function>
static auto translateErrors(__unsafe_unretained ObjcCollection *const collection,
                            Function&& f, NSString *aggregateMethod=nil) {
    try {
        return f();
    }
    catch (...) {
        throwError<ObjcCollection>(collection, aggregateMethod);
    }
}

template<typename ObjcCollection, typename Function>
static auto translateErrors(Function&& f) {
    try {
        return f();
    }
    catch (...) {
        throwError<ObjcCollection>(nil, nil);
    }
}

static void changeDictionary(__unsafe_unretained RLMManagedDictionary *const dict,
                             dispatch_block_t f) {
    translateErrors<RLMManagedDictionary>([&] { dict->_backingCollection.verify_in_transaction(); });

    RLMObservationTracker tracker(dict->_realm);
    tracker.trackDeletions();
    auto obsInfo = RLMGetObservationInfo(dict->_observationInfo.get(),
                                         dict->_backingCollection.get_parent_object_key(),
                                         *dict->_ownerInfo);
    if (obsInfo) {
        tracker.willChange(obsInfo, dict->_key);
    }

    translateErrors<RLMManagedDictionary>(f);
}

//
// public method implementations
//
- (RLMRealm *)realm {
    return _realm;
}

- (NSUInteger)count {
    return translateErrors<RLMManagedDictionary>([&] {
        return _backingCollection.size();
    });
}

- (NSArray *)allKeys {
    return translateErrors<RLMManagedDictionary>([&] {
        NSMutableArray<id<RLMDictionaryKey>> *keys = [NSMutableArray array];
        auto keyResult = _backingCollection.get_keys();
        for (size_t i=0; i<keyResult.size(); i++) {
            [keys addObject:RLMStringDataToNSString(keyResult.get<realm::StringData>(i))];
        }
        return keys;
    });
}

- (NSArray *)allValues {
    return translateErrors<RLMManagedDictionary>([&] {
        NSMutableArray *values = [NSMutableArray array];
        auto valueResult = _backingCollection.get_values();
        for (size_t i=0; i<valueResult.size(); i++) {
            RLMAccessorContext c(*_objectInfo);
            [values addObject:valueResult.get(c, i)];
        }
        return values;
    });
}

- (BOOL)isInvalidated {
    return translateErrors<RLMManagedDictionary>([&] { return !_backingCollection.is_valid(); });
}

- (RLMClassInfo *)objectInfo {
    return _objectInfo;
}

- (bool)isBackedByDictionary:(realm::object_store::Dictionary const&)dictionary {
    return _backingCollection == dictionary;
}

- (BOOL)isEqual:(id)object {
    return [object respondsToSelector:@selector(isBackedByDictionary:)] &&
           [object isBackedByDictionary:_backingCollection];
}

- (NSUInteger)hash {
    // TODO: implement hash
    //return std::hash<realm::object_store::Dictionary>()(_backingCollection);
    return 0;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    return RLMFastEnumerate(state, len, self);
}

#pragma mark - Object Retrieval

- (nullable id)objectForKey:(id<RLMDictionaryKey>)key {
    try {
        RLMAccessorContext context(*_objectInfo);
        return _backingCollection.get(context,
                                      keyFromRLMDictionaryKey(key, context));
    }
    catch (realm::KeyNotFound const&) {
        return nil;
    }
    catch (...) {
        throwError<RLMManagedDictionary>(nil, nil);
    }
}

- (nullable id)objectForKeyedSubscript:(id<RLMDictionaryKey>)key {
    return [self objectForKey:key];
}

- (nonnull id)objectAtIndex:(NSUInteger)index {
    return translateErrors<RLMManagedDictionary>([&] {
        auto key = _backingCollection.get_pair(index).first;
        return RLMStringDataToNSString(key);
    });
}

- (NSUInteger)indexOfObject:(id)value {
    return translateErrors<RLMManagedDictionary>([&] {
        return _backingCollection.find_any(value);
    });
}

- (void)setObject:(id)obj forKey:(id<RLMDictionaryKey>)key {
    RLMDictionaryValidateMatchingObjectType(self, key, obj);
    changeDictionary(self, ^{
        RLMAccessorContext context(*_objectInfo);
        _backingCollection.insert(context,
                                  keyFromRLMDictionaryKey(key, context),
                                  obj);
    });
}

- (void)setObject:(id)obj forKeyedSubscript:(id<RLMDictionaryKey>)key {
    // passing `nil` to the subscript should delete the object.
    if (!obj) {
        [self removeObjectForKey:key];
        return;
    }
    RLMDictionaryValidateMatchingObjectType(self, key, obj);
    changeDictionary(self, ^{
        RLMAccessorContext context(*_objectInfo);
        _backingCollection.insert(context,
                                  keyFromRLMDictionaryKey(key, context),
                                  obj);
    });
}

- (void)removeAllObjects {
    changeDictionary(self, ^{
        _backingCollection.remove_all();
    });
}

- (void)removeObjectsForKeys:(NSArray *)keyArray {
    changeDictionary(self, ^{
        RLMAccessorContext context(*_objectInfo);
        for (id key in keyArray) {
            _backingCollection.erase(keyFromRLMDictionaryKey(key, context));
        }
    });
}

- (void)removeObjectForKey:(id<RLMDictionaryKey>)key {
    changeDictionary(self, ^{
        RLMAccessorContext context(*_objectInfo);
        _backingCollection.erase(keyFromRLMDictionaryKey(key, context));
    });
}

inline realm::StringData keyFromRLMDictionaryKey(id<RLMDictionaryKey> key, RLMAccessorContext &context) {
    if (auto *k = RLMDynamicCast<NSString>(key)) {
        return context.unbox<realm::StringData>(k);
    } else {
        @throw RLMException(@"Unsupported key type %@ in key array", key);
    }
}

#pragma mark - KVC

- (id)valueForKeyPath:(NSString *)keyPath {
    if ([keyPath hasPrefix:@"@"]) {
        // Delegate KVC collection operators to RLMResults
        return translateErrors<RLMManagedDictionary>([&] {
            auto results = [RLMResults resultsWithObjectInfo:*_objectInfo
                                                     results:_backingCollection.as_results()];
            return [results valueForKeyPath:keyPath];
        });
    }
    return [super valueForKeyPath:keyPath];
}

- (id)valueForKey:(NSString *)key {
    return [super valueForKey:key];
}

- (void)setValue:(id)value forKey:(id)key {
    RLMDictionaryValidateMatchingObjectType(self, key, value);
    RLMAccessorContext context(*_objectInfo);
    translateErrors<RLMManagedDictionary>([&] {
        _backingCollection.insert(context, [key UTF8String], value);
    });
}

// TODO: this can be a common func
- (realm::ColKey)columnForProperty:(NSString *)propertyName {
    if (_backingCollection.get_type() == realm::PropertyType::Object) {
        return _objectInfo->tableColumn(propertyName);
    }
    if (![propertyName isEqualToString:@"self"]) {
        @throw RLMException(@"Dictionaries of '%@' can only be aggregated on \"self\"", RLMTypeToString(_type));
    }
    return {};
}

- (id)minOfProperty:(NSString *)property {
    auto column = [self columnForProperty:property];
    auto value = translateErrors<RLMManagedDictionary>(self, [&] {
        return _backingCollection.as_results().min(column);
    }, @"minOfProperty");
    return value ? RLMMixedToObjc(*value) : nil;
}

- (id)maxOfProperty:(NSString *)property {
    auto column = [self columnForProperty:property];
    auto value = translateErrors<RLMManagedDictionary>(self, [&] {
        return _backingCollection.as_results().max(column);
    }, @"maxOfProperty");
    return value ? RLMMixedToObjc(*value) : nil;
}

- (id)sumOfProperty:(NSString *)property {
    auto column = [self columnForProperty:property];
    auto value = translateErrors<RLMManagedDictionary>(self, [&] {
        return _backingCollection.as_results().sum(column);
    }, @"sumOfProperty");
    return value ? RLMMixedToObjc(*value) : nil;
}

- (id)averageOfProperty:(NSString *)property {
    auto column = [self columnForProperty:property];
    auto value = translateErrors<RLMManagedDictionary>(self, [&] {
        return _backingCollection.as_results().average(column);
    }, @"averageOfProperty");
    return value ? RLMMixedToObjc(*value) : nil;
}

- (void)deleteObjectsFromRealm {
    if (_type != RLMPropertyTypeObject) {
        @throw RLMException(@"Cannot delete objects from RLMManagedDictionary<RLMString, %@>: only RLMObjects can be deleted.", RLMTypeToString(_type));
    }
    // delete all target rows from the realm
    RLMObservationTracker tracker(_realm, true);
    translateErrors<RLMManagedDictionary>([&] { _backingCollection.remove_all(); });
}

- (RLMResults *)sortedResultsUsingDescriptors:(NSArray<RLMSortDescriptor *> *)properties {
    return translateErrors<RLMManagedDictionary>([&] {
        return [RLMResults resultsWithObjectInfo:*_objectInfo
                                         results:_backingCollection.as_results().sort(RLMSortDescriptorsToKeypathArray(properties))];
    });
}

- (RLMResults *)distinctResultsUsingKeyPaths:(NSArray<NSString *> *)keyPaths {
    return translateErrors<RLMManagedDictionary>([&] {
        auto results = [RLMResults resultsWithObjectInfo:*_objectInfo results:_backingCollection.as_results()];
        return [results distinctResultsUsingKeyPaths:keyPaths];
    });
}

- (RLMResults *)objectsWithPredicate:(NSPredicate *)predicate {
    if (_type != RLMPropertyTypeObject) {
        @throw RLMException(@"Querying is currently only implemented for dictionaries of Realm Objects");
    }
    auto query = RLMPredicateToQuery(predicate, _objectInfo->rlmObjectSchema, _realm.schema, _realm.group);
    auto results = translateErrors<RLMManagedDictionary>([&] {
        return _backingCollection.as_results().filter(std::move(query));
    });
    return [RLMResults resultsWithObjectInfo:*_objectInfo results:std::move(results)];
}

- (void)addObserver:(id)observer
         forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options
            context:(void *)context {
    RLMEnsureCollectionObservationInfo<RLMDictionary, RLMManagedDictionary>(_observationInfo, keyPath, self, self);
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (realm::TableView)tableView {
    return translateErrors<RLMManagedDictionary>([&] {
        return _backingCollection.as_results().get_query();
    }).find_all();
}

- (RLMFastEnumerator *)fastEnumerator {
    return translateErrors<RLMManagedDictionary>([&] {
        return [[RLMFastEnumerator alloc] initWithBackingCollection:_backingCollection
                                                         collection:self
                                                          classInfo:*_objectInfo];
    });
}

- (BOOL)isFrozen {
    return _realm.isFrozen;
}

- (instancetype)freeze {
    if (self.frozen) {
        return self;
    }

    RLMRealm *frozenRealm = [_realm freeze];
    auto& parentInfo = _ownerInfo->resolve(frozenRealm);
    return translateRLMResultsErrors([&] {
        return [[self.class alloc] initWithBackingCollection:_backingCollection.freeze(frozenRealm->_realm)
                                                  parentInfo:&parentInfo
                                                    property:parentInfo.rlmObjectSchema[_key]];
    });
}

- (instancetype)thaw {
    if (!self.frozen) {
        return self;
    }

    RLMRealm *liveRealm = [_realm thaw];
    auto& parentInfo = _ownerInfo->resolve(liveRealm);
    return translateRLMResultsErrors([&] {
        return [[self.class alloc] initWithBackingCollection:_backingCollection.freeze(liveRealm->_realm)
                                                  parentInfo:&parentInfo
                                                    property:parentInfo.rlmObjectSchema[_key]];
    });
}

// The compiler complains about the method's argument type not matching due to
// it not having the generic type attached, but it doesn't seem to be possible
// to actually include the generic type
// http://www.openradar.me/radar?id=6135653276319744
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMArray *, RLMCollectionChange *, NSError *))block {
    return RLMAddNotificationBlock(self, block, nil);
}
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMArray *, RLMCollectionChange *, NSError *))block queue:(dispatch_queue_t)queue {
    return RLMAddNotificationBlock(self, block, queue);
}
#pragma clang diagnostic pop

realm::object_store::Dictionary& RLMGetBackingCollection(RLMManagedDictionary *self) {
    return self->_backingCollection;
}

#pragma mark - Thread Confined Protocol Conformance

- (realm::ThreadSafeReference)makeThreadSafeReference {
    return _backingCollection;
}

- (RLMManagedCollectionHandoverMetadata *)objectiveCMetadata {
    RLMManagedCollectionHandoverMetadata *metadata = [[RLMManagedCollectionHandoverMetadata alloc] init];
    metadata.parentClassName = _ownerInfo->rlmObjectSchema.className;
    metadata.key = _key;
    return metadata;
}

+ (instancetype)objectWithThreadSafeReference:(realm::ThreadSafeReference)reference
                                     metadata:(RLMManagedCollectionHandoverMetadata *)metadata
                                        realm:(RLMRealm *)realm {
    auto dictionary = reference.resolve<realm::object_store::Dictionary>(realm->_realm);
    if (!dictionary.is_valid()) {
        return nil;
    }
    RLMClassInfo *parentInfo = &realm->_info[metadata.parentClassName];
    return [[RLMManagedDictionary alloc] initWithBackingCollection:std::move(dictionary)
                                                        parentInfo:parentInfo
                                                          property:parentInfo->rlmObjectSchema[metadata.key]];
}

@end
