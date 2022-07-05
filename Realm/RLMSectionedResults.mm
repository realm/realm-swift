////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

#import "RLMSectionedResults_Private.hpp"
#import "RLMAccessor.hpp"
#import "RLMCollection_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMResults.h"
#import "RLMResults_Private.hpp"
#import "RLMThreadSafeReference_Private.hpp"

#include <map>

namespace {
struct CollectionCallbackWrapper {
    void (^block)(id, RLMSectionedResultsChange *, NSError *);
    id collection;
    bool ignoreChangesInInitialNotification = true;

    void operator()(realm::SectionedResultsChangeSet const& changes, std::exception_ptr err) {
        if (err) {
            try {
                rethrow_exception(err);
            }
            catch (...) {
                NSError *error = nil;
                RLMRealmTranslateException(&error);
                block(nil, nil, error);
                return;
            }
        }

        if (ignoreChangesInInitialNotification) {
            ignoreChangesInInitialNotification = false;
            return block(collection, nil, nil);
        }

        block(collection, [[RLMSectionedResultsChange alloc] initWithChanges:changes], nil);
    }
};
} // anonymous namespace

realm::SectionedResults& RLMGetBackingCollection(RLMSectionedResults *self) {
    return self->_sectionedResults;
}

RLMNotificationToken *RLMAddNotificationBlock(RLMSectionedResults *collection,
                                              void (^block)(id, RLMSectionedResultsChange *, NSError *),
                                              NSArray<NSString *> *keyPaths,
                                              dispatch_queue_t queue) {
    RLMRealm *realm = collection.realm;
    if (!realm) {
        @throw RLMException(@"Collection of Sectioned Results has been invalidated or deleted.");
    }
    auto token = [[RLMCancellationToken alloc] init];

    RLMClassInfo *info = collection.objectInfo;
    realm::KeyPathArray keyPathArray = RLMKeyPathArrayFromStringArray(realm, info, keyPaths);

    if (!queue) {
        [realm verifyNotificationsAreSupported:true];
        token->_realm = realm;
        token->_token = RLMGetBackingCollection(collection).add_notification_callback(CollectionCallbackWrapper{block, collection}, std::move(keyPathArray));
        return token;
    }

    RLMThreadSafeReference *tsr = [RLMThreadSafeReference referenceWithThreadConfined:collection];
    token->_realm = realm;
    RLMRealmConfiguration *config = realm.configuration;
    dispatch_async(queue, ^{
        std::lock_guard<std::mutex> lock(token->_mutex);
        if (!token->_realm) {
            return;
        }
        NSError *error;
        RLMRealm *realm = token->_realm = [RLMRealm realmWithConfiguration:config queue:queue error:&error];
        if (!realm) {
            block(nil, nil, error);
            return;
        }
        RLMSectionedResults *collection = [realm resolveThreadSafeReference:tsr];
        token->_token = RLMGetBackingCollection(collection).add_notification_callback(CollectionCallbackWrapper{block, collection}, std::move(keyPathArray));
    });
    return token;
}

@implementation RLMSectionedResultsChange {
    realm::SectionedResultsChangeSet _indices;
}

- (instancetype)initWithChanges:(realm::SectionedResultsChangeSet)indices {
    self = [super init];
    if (self) {
        _indices = std::move(indices);
    }
    return self;
}

- (NSArray<NSIndexPath *> *)indexesFromIndexMap:(std::map<size_t, realm::IndexSet>&)indexMap {
    NSMutableArray<NSIndexPath *> *a = [NSMutableArray new];
    for (auto& [section_idx, indices] : indexMap) {
        NSUInteger path[2] = {section_idx, 0};
        for(auto index : indices.as_indexes()) {
            path[1] = index;
            [a addObject:[NSIndexPath indexPathWithIndexes:path length:2]];
        }
    }
    return a;
}

- (NSArray<NSIndexPath *> *)insertions {
    return [self indexesFromIndexMap:_indices.insertions];
}

- (NSArray<NSIndexPath *> *)deletions {
    return [self indexesFromIndexMap:_indices.deletions];
}

- (NSArray<NSIndexPath *> *)modifications {
    return [self indexesFromIndexMap:_indices.modifications];
}

- (NSIndexSet *)sectionsToInsert {
    NSMutableIndexSet *indices = [NSMutableIndexSet new];
    for (auto i : _indices.sections_to_insert.as_indexes()) {
        [indices addIndex:i];
    }
    return indices;
}

- (NSIndexSet *)sectionsToRemove {
    NSMutableIndexSet *indices = [NSMutableIndexSet new];
    for (auto i : _indices.sections_to_delete.as_indexes()) {
        [indices addIndex:i];
    }
    return indices;
}


/// Returns the index paths of the deletion indices in the given section.
- (NSArray<NSIndexPath *> *)deletionsInSection:(NSUInteger)section {
    return toIndexPathArray(_indices.deletions[section], section);

}

/// Returns the index paths of the insertion indices in the given section.
- (NSArray<NSIndexPath *> *)insertionsInSection:(NSUInteger)section {
    return toIndexPathArray(_indices.insertions[section], section);
}

/// Returns the index paths of the modification indices in the given section.
- (NSArray<NSIndexPath *> *)modificationsInSection:(NSUInteger)section {
    return toIndexPathArray(_indices.modifications[section], section);
}

- (NSString *)description {
    NSString *(^indexPathToString)(NSArray<NSIndexPath *> *) = ^NSString*(NSArray<NSIndexPath *> * indexes) {
        NSMutableString *s = [NSMutableString new];
        [s appendString:@"["];
        BOOL hasItems = NO;
        for (NSIndexPath *i in indexes) {
            hasItems = YES;
            [s appendFormat:@"\n\t\t%@", i.description];
        }
        if (hasItems) {
            [s appendString:@"\n\t]"];
        } else {
            [s appendString:@"]"];
        }
        return s;
    };
    NSString *(^indexSetToString)(NSIndexSet *) = ^NSString*(NSIndexSet * sections) {
        NSMutableString *s = [NSMutableString new];
        [s appendString:@"["];
        __block BOOL hasRun = NO;
        [sections enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *) {
            if (hasRun) {
                [s appendFormat:@", %lu", (unsigned long)i];
            } else {
                [s appendFormat:@"%lu", i];
            }
            hasRun = YES;
        }];
        [s appendString:@"]"];
        return s;
    };
    return [NSString stringWithFormat:@"<RLMSectionedResultsChange: %p> {\n\tinsertions: %@,\n\tdeletions: %@,\n\tmodifications: %@,\n\tsectionsToInsert: %@, \n\tsectionsToRemove: %@\n}",
            (__bridge void *)self,
            indexPathToString(self.insertions),
            indexPathToString(self.deletions),
            indexPathToString(self.modifications),
            indexSetToString(self.sectionsToInsert), indexSetToString(self.sectionsToRemove)];
}

@end

struct SectionedResultsKeyProjection {
    RLMClassInfo *_info;
    RLMSectionedResultsKeyBlock _block;

    realm::Mixed operator()(realm::Mixed obj, realm::SharedRealm) {
        RLMAccessorContext context(*_info);
        id value = _block(context.box(obj));
        return context.unbox<realm::Mixed>(value);
    }
};

@interface RLMSectionedResultsEnumerator() {
    // The buffer supplied by fast enumeration does not retain the objects given
    // to it, but because we create objects on-demand and don't want them
    // autoreleased (a table can have more rows than the device has memory for
    // accessor objects) we need a thing to retain them.
    id _strongBuffer[16];
    BOOL _isSection;
}
@end

@implementation RLMSectionedResultsEnumerator

- (instancetype)initWithSectionedResults:(RLMSectionedResults *)sectionedResults {
    if (self = [super init]) {
        _sectionedResults = [sectionedResults snapshot];
        _isSection = NO;
        return self;
    }
    return nil;
}

- (instancetype)initWithResultsSection:(RLMSection *)resultsSection {
    if (self = [super init]) {
        _resultsSection = resultsSection;
        _isSection = YES;
        return self;
    }
    return nil;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                    count:(NSUInteger)len {
    NSUInteger batchCount = 0, count = _isSection ? [_resultsSection count] : [_sectionedResults count];
    for (NSUInteger index = state->state; index < count && batchCount < len; ++index) {
        if (_isSection) {
            RLMSectionedResults *sectionedResults = [_resultsSection objectAtIndex:index];
            _strongBuffer[batchCount] = sectionedResults;
        } else {
            RLMSection *section = [_sectionedResults objectAtIndex:index];
            _strongBuffer[batchCount] = section;
        }

        batchCount++;
    }

    for (NSUInteger i = batchCount; i < len; ++i) {
        _strongBuffer[i] = nil;
    }

    if (batchCount == 0) {
        // Release our data if we're done, as we're autoreleased and so may
        // stick around for a while
        if (_sectionedResults) {
            _sectionedResults = nil;
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
                            RLMSectionedResults *collection) {
    __autoreleasing RLMSectionedResultsEnumerator *enumerator;
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

NSUInteger RLMFastEnumerate(NSFastEnumerationState *state,
                            NSUInteger len,
                            RLMSection *collection) {
    __autoreleasing RLMSectionedResultsEnumerator *enumerator;
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

@interface RLMSectionedResults () <RLMThreadConfined_Private>
@end

@implementation RLMSectionedResults {
    RLMRealm *_realm;
    RLMClassInfo *_info;
}

- (instancetype)initWithResults:(realm::Results&&)results
                          realm:(RLMRealm *)realm
                     objectInfo:(RLMClassInfo&)objectInfo
                       keyBlock:(RLMSectionedResultsKeyBlock)keyBlock {
    if (self = [super init]) {
        _info = &objectInfo;
        _realm = realm;
        _keyBlock = keyBlock;
        _results = results;
        _sectionedResults = results.sectioned_results(SectionedResultsKeyProjection {_info, _keyBlock});
    }
    return self;
}

- (instancetype)initWithSectionedResults:(realm::SectionedResults&&)sectionedResults
                              objectInfo:(RLMClassInfo&)objectInfo
                                keyBlock:(RLMSectionedResultsKeyBlock)keyBlock{
    if (self = [super init]) {
        _info = &objectInfo;
        _realm = _info->realm;
        _sectionedResults = std::move(sectionedResults);
        _keyBlock = keyBlock;
    }
    return self;
}

- (instancetype)initWithResults:(RLMResults *)results
                     objectInfo:(RLMClassInfo&)objectInfo
                       keyBlock:(RLMSectionedResultsKeyBlock)keyBlock {
    if (self = [super init]) {
        _info = &objectInfo;
        _realm = results.realm;
        _keyBlock = keyBlock;
        _results = results->_results;
        _sectionedResults = results->_results.sectioned_results(SectionedResultsKeyProjection {_info, _keyBlock});
    }
    return self;
}

- (RLMSectionedResultsEnumerator *)fastEnumerator {
    return [[RLMSectionedResultsEnumerator alloc] initWithSectionedResults:self];
}

- (RLMRealm *)realm {
    return _realm;
}

- (instancetype)resolveInRealm:(RLMRealm *)realm {
     return translateRLMResultsErrors([&] {
        if (realm.isFrozen) {
            return [[RLMSectionedResults alloc] initWithSectionedResults:_sectionedResults.freeze(realm->_realm)
                                                              objectInfo:_info->resolve(realm)
                                                                keyBlock:_keyBlock];
        } else {
            auto sr = _sectionedResults.freeze(realm->_realm);
            sr.reset_section_callback(SectionedResultsKeyProjection {&_info->resolve(realm), _keyBlock});
            return [[RLMSectionedResults alloc] initWithSectionedResults:std::move(sr)
                                                              objectInfo:_info->resolve(realm)
                                                                keyBlock:_keyBlock];
        }
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

- (NSUInteger)count {
    return translateRLMResultsErrors([&] {
        return _sectionedResults.size();
    });
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    return RLMFastEnumerate(state, len, self);
}

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

- (id)objectAtIndex:(NSUInteger)index {
    return [[RLMSection alloc] initWithResultsSection:_sectionedResults[index]
                                                realm:self.realm
                                           objectInfo:*_info
                                             keyBlock:_keyBlock
                                               parent:self];
}

// The compiler complains about the method's argument type not matching due to
// it not having the generic type attached, but it doesn't seem to be possible
// to actually include the generic type
// http://www.openradar.me/radar?id=6135653276319744
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *, NSError *))block {
    return RLMAddNotificationBlock(self, block, nil, nil);
}
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *, NSError *))block queue:(dispatch_queue_t)queue {
    return RLMAddNotificationBlock(self, block, nil, queue);
}

- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *, NSError *))block keyPaths:(NSArray<NSString *> *)keyPaths {
    return RLMAddNotificationBlock(self, block, keyPaths, nil);
}

- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *, NSError *))block
                                      keyPaths:(NSArray<NSString *> *)keyPaths
                                         queue:(dispatch_queue_t)queue {
    return RLMAddNotificationBlock(self, block, keyPaths, queue);
}
#pragma clang diagnostic pop

- (RLMClassInfo *)objectInfo {
    return _info;
}

#pragma mark - Thread Confined Protocol Conformance

- (realm::ThreadSafeReference)makeThreadSafeReference {
    return _results;
}

- (id)objectiveCMetadata {
    return _keyBlock;
}

+ (instancetype)objectWithThreadSafeReference:(realm::ThreadSafeReference)reference
                                     metadata:(id)metadata
                                        realm:(RLMRealm *)realm {
    auto results = reference.resolve<realm::Results>(realm->_realm);
    auto objType = RLMStringDataToNSString(results.get_object_type());
    return [[RLMSectionedResults alloc] initWithResults:std::move(results)
                                                  realm:realm
                                             objectInfo:realm->_info[objType]
                                               keyBlock:(RLMSectionedResultsKeyBlock)metadata];
}

- (BOOL)isInvalidated {
    return translateRLMResultsErrors([&] { return !_sectionedResults.is_valid(); });
}

- (NSString *)description {
    NSString *objType = @"";
    if (_info) {
        objType = [NSString stringWithFormat:@"<%@>", _info->rlmObjectSchema.className];
    }
    const NSUInteger maxObjects = 100;
    auto str = [NSMutableString stringWithFormat:@"RLMSectionedResults%@ <%p> (\n", objType, (void *)self];
    size_t index = 0, skipped = 0;
    for (RLMSection *section in self) {
        NSString *sub = [section description];
        // Indent child objects
        NSString *objDescription = [sub stringByReplacingOccurrencesOfString:@"\n"
                                                                  withString:@"\n\t"];
        [str appendFormat:@"\t[%@] %@,\n", section.key, objDescription];
        index++;
        if (index >= maxObjects) {
            skipped = self.count - maxObjects;
            break;
        }
    }

    // Remove last comma and newline characters
    if (self.count > 0) {
        [str deleteCharactersInRange:NSMakeRange(str.length-2, 2)];
    }
    if (skipped) {
        [str appendFormat:@"\n\t... %zu objects skipped.", skipped];
    }
    [str appendFormat:@"\n)"];
    return str;
}

- (RLMSectionedResults *)snapshot {
    RLMSectionedResults *sr = [RLMSectionedResults new];
    sr->_sectionedResults = _sectionedResults.snapshot();
    sr->_info = _info;
    sr->_realm = _realm;
    return sr;
}

- (BOOL)isFrozen {
    return translateRLMResultsErrors([&] { return _sectionedResults.is_frozen(); });
}

@end

realm::ResultsSection& RLMGetBackingCollection(RLMSection *self) {
    return self->_resultsSection;
}

RLMNotificationToken *RLMAddNotificationBlock(RLMSection *collection,
                                              void (^block)(id, RLMSectionedResultsChange *, NSError *),
                                              NSArray<NSString *> *keyPaths,
                                              dispatch_queue_t queue) {
    RLMRealm *realm = collection.realm;
    if (!realm) {
        @throw RLMException(@"Collection of Sectioned Results has been invalidated or deleted.");
    }
    auto token = [[RLMCancellationToken alloc] init];

    RLMClassInfo *info = collection.objectInfo;
    realm::KeyPathArray keyPathArray = RLMKeyPathArrayFromStringArray(realm, info, keyPaths);

    if (!queue) {
        [realm verifyNotificationsAreSupported:true];
        token->_realm = realm;
        token->_token = collection->_resultsSection.add_notification_callback(CollectionCallbackWrapper{block, collection}, std::move(keyPathArray));
        return token;
    }

    RLMThreadSafeReference *tsr = [RLMThreadSafeReference referenceWithThreadConfined:collection];
    token->_realm = realm;
    RLMRealmConfiguration *config = realm.configuration;
    dispatch_async(queue, ^{
        std::lock_guard<std::mutex> lock(token->_mutex);
        if (!token->_realm) {
            return;
        }
        NSError *error;
        RLMRealm *realm = token->_realm = [RLMRealm realmWithConfiguration:config queue:queue error:&error];
        if (!realm) {
            block(nil, nil, error);
            return;
        }
        RLMSection *collection = [realm resolveThreadSafeReference:tsr];
        token->_token = RLMGetBackingCollection(collection).add_notification_callback(CollectionCallbackWrapper{block, collection}, std::move(keyPathArray));
    });
    return token;
}

@interface RLMSection () <RLMThreadConfined_Private>
@end

@implementation RLMSection {
    RLMRealm *_realm;
    RLMClassInfo *_info;
    RLMSectionedResultsKeyBlock _keyBlock;
    RLMSectionedResults *_parent;
}

- (NSString *)description {
    const NSUInteger maxObjects = 100;
    auto str = [NSMutableString stringWithFormat:@"RLMSection <%p> (\n", (void *)self];
    size_t index = 0, skipped = 0;
    for (id obj in self) {
        NSString *sub = [obj description];
        // Indent child objects
        NSString *objDescription = [sub stringByReplacingOccurrencesOfString:@"\n"
                                                                  withString:@"\n\t"];
        [str appendFormat:@"\t[%zu] %@,\n", index++, objDescription];
        if (index >= maxObjects) {
            skipped = self.count - maxObjects;
            break;
        }
    }

    // Remove last comma and newline characters
    if (self.count > 0) {
        [str deleteCharactersInRange:NSMakeRange(str.length-2, 2)];
    }
    if (skipped) {
        [str appendFormat:@"\n\t... %zu objects skipped.", skipped];
    }
    [str appendFormat:@"\n)"];
    return str;
}

- (instancetype)initWithResultsSection:(realm::ResultsSection&&)resultsSection
                                 realm:(RLMRealm *)realm
                            objectInfo:(RLMClassInfo&)objectInfo
                              keyBlock:(RLMSectionedResultsKeyBlock)keyBlock
                                parent:(RLMSectionedResults *)parent
{
    if (self = [super init]) {
        _realm = realm;
        _info = &objectInfo;
        _keyBlock = keyBlock;
        _resultsSection = std::move(resultsSection);
        _parent = parent;
    }
    return self;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

- (id)objectAtIndex:(NSUInteger)index {
    RLMAccessorContext ctx(*_info);
    return translateRLMResultsErrors([&] {
        return ctx.box(_resultsSection[index]);
    });
}

- (NSUInteger)count {
    return translateRLMResultsErrors([&] {
        return _resultsSection.size();
    });
}

- (id<RLMValue>)key {
    return translateRLMResultsErrors([&] {
        return RLMMixedToObjc(_resultsSection.key());
    });
}

- (RLMSectionedResultsEnumerator *)fastEnumerator {
    return [[RLMSectionedResultsEnumerator alloc] initWithResultsSection:self];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unused __unsafe_unretained id [])buffer
                                    count:(NSUInteger)len {
    return RLMFastEnumerate(state, len, self);
}

- (RLMRealm *)realm {
    return _realm;
}

- (RLMClassInfo *)objectInfo {
    return _info;
}

// The compiler complains about the method's argument type not matching due to
// it not having the generic type attached, but it doesn't seem to be possible
// to actually include the generic type
// http://www.openradar.me/radar?id=6135653276319744
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *, NSError *))block {
    return RLMAddNotificationBlock(self, block, nil, nil);
}
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *, NSError *))block queue:(dispatch_queue_t)queue {
    return RLMAddNotificationBlock(self, block, nil, queue);
}

- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *, NSError *))block keyPaths:(NSArray<NSString *> *)keyPaths {
    return RLMAddNotificationBlock(self, block, keyPaths, nil);
}

- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *, NSError *))block
                                      keyPaths:(NSArray<NSString *> *)keyPaths
                                         queue:(dispatch_queue_t)queue {
    return RLMAddNotificationBlock(self, block, keyPaths, queue);
}
#pragma clang diagnostic pop

#pragma mark - Thread Confined Protocol Conformance

- (realm::ThreadSafeReference)makeThreadSafeReference {
    return _parent->_results;
}

- (id)objectiveCMetadata {
    return @{
        @"keyBlock": _keyBlock,
        @"sectionKey": self.key
    };
}

+ (instancetype)objectWithThreadSafeReference:(realm::ThreadSafeReference)reference
                                     metadata:(id)metadata
                                        realm:(RLMRealm *)realm {
    auto results = reference.resolve<realm::Results>(realm->_realm);
    auto objType = RLMStringDataToNSString(results.get_object_type());

    RLMSectionedResults *sr = [[RLMSectionedResults alloc] initWithResults:std::move(results)
                                                                     realm:realm
                                                                objectInfo:realm->_info[objType]
                                                                  keyBlock:(RLMSectionedResultsKeyBlock)metadata[@"keyBlock"]];
    return translateRLMResultsErrors([&] {
        return [[RLMSection alloc] initWithResultsSection:sr->_sectionedResults[RLMObjcToMixed(metadata[@"sectionKey"])]
                                                    realm:realm
                                               objectInfo:realm->_info[objType]
                                                 keyBlock:(RLMSectionedResultsKeyBlock)metadata[@"keyBlock"]
                                                   parent:sr];
    });
}

- (BOOL)isInvalidated {
    return translateRLMResultsErrors([&] { return !_resultsSection.is_valid(); });
}

@end
