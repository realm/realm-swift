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

namespace {
struct CollectionCallbackWrapper {
    void (^block)(id, RLMSectionedResultsChange *);
    id collection;
    bool ignoreChangesInInitialNotification = true;

    void operator()(realm::SectionedResultsChangeSet const& changes) {
        if (ignoreChangesInInitialNotification) {
            ignoreChangesInInitialNotification = false;
            return block(collection, nil);
        }

        block(collection, [[RLMSectionedResultsChange alloc] initWithChanges:changes]);
    }
};

template<typename Function>
__attribute__((always_inline))
auto translateErrors(Function&& f) {
    return translateCollectionError(static_cast<Function&&>(f), @"SectionedResults");
}
} // anonymous namespace

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

- (NSArray<NSIndexPath *> *)indexesFromIndexMap:(std::map<size_t, realm::IndexSet> const&)indexMap {
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
    return RLMToIndexPathArray(_indices.deletions[section], section);
}

/// Returns the index paths of the insertion indices in the given section.
- (NSArray<NSIndexPath *> *)insertionsInSection:(NSUInteger)section {
    return RLMToIndexPathArray(_indices.insertions[section], section);
}

/// Returns the index paths of the modification indices in the given section.
- (NSArray<NSIndexPath *> *)modificationsInSection:(NSUInteger)section {
    return RLMToIndexPathArray(_indices.modifications[section], section);
}

static NSString *indexPathToString(NSArray<NSIndexPath *> *indexes) {
    if (indexes.count == 0) {
        return @"[]";
    }
    return [NSString stringWithFormat:@"[\n\t%@\n\t]", [indexes componentsJoinedByString:@"\n\t\t"]];
};

static NSString *indexSetToString(NSIndexSet *sections) {
    if (sections.count == 0) {
        return @"[]";
    }
    return [NSString stringWithFormat:@"[\n\t%@\n\t]", sections];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RLMSectionedResultsChange: %p> {\n\tinsertions: %@,\n\tdeletions: %@,\n\tmodifications: %@,\n\tsectionsToInsert: %@,\n\tsectionsToRemove: %@\n}",
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
    id<RLMSectionedResult> _sectionedResult;
}
@end

@implementation RLMSectionedResultsEnumerator

- (instancetype)initWithSectionedResults:(RLMSectionedResults *)sectionedResults {
    if (self = [super init]) {
        _sectionedResult = [sectionedResults snapshot];
        return self;
    }
    return nil;
}

- (instancetype)initWithResultsSection:(RLMSection *)resultsSection {
    if (self = [super init]) {
        _sectionedResult = resultsSection;
        return self;
    }
    return nil;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                    count:(NSUInteger)len {
    NSUInteger batchCount = 0, count = [_sectionedResult count];
    for (NSUInteger index = state->state; index < count && batchCount < len; ++index) {
        id<RLMSectionedResult> sectionedResults = [_sectionedResult objectAtIndex:index];
        _strongBuffer[batchCount] = sectionedResults;
        batchCount++;
    }

    for (NSUInteger i = batchCount; i < len; ++i) {
        _strongBuffer[i] = nil;
    }

    if (batchCount == 0) {
        // Release our data if we're done, as we're autoreleased and so may
        // stick around for a while
        if (_sectionedResult) {
            _sectionedResult = nil;
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
    @public
    realm::SectionedResults _sectionedResults;
    RLMSectionedResultsKeyBlock _keyBlock;
    // We need to hold an instance to the parent
    // `Results` so we can obtain a ThreadSafeReference
    // for notifications.
    realm::Results _results;
    @private
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
        _results = std::move(results);
        _sectionedResults = _results.sectioned_results(SectionedResultsKeyProjection{_info, _keyBlock});
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
                       keyBlock:(RLMSectionedResultsKeyBlock)keyBlock {
    if (self = [super init]) {
        _info = results.objectInfo;
        _realm = results.realm;
        _keyBlock = keyBlock;
        _results = results->_results;
        _sectionedResults = results->_results.sectioned_results(SectionedResultsKeyProjection{_info, _keyBlock});
    }
    return self;
}

- (NSArray *)allKeys {
    return translateErrors([&] {
        NSUInteger count = [self count];
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger i = 0; i < count; i++) {
            [arr addObject:RLMMixedToObjc(_sectionedResults[i].key())];
        }
        return arr;
    });
}

- (RLMSectionedResultsEnumerator *)fastEnumerator {
    return [[RLMSectionedResultsEnumerator alloc] initWithSectionedResults:self];
}

- (RLMRealm *)realm {
    return _realm;
}

- (NSUInteger)count {
    return translateErrors([&] {
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
                                               parent:self];
}

// The compiler complains about the method's argument type not matching due to
// it not having the generic type attached, but it doesn't seem to be possible
// to actually include the generic type
// http://www.openradar.me/radar?id=6135653276319744
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *))block {
    return RLMAddNotificationBlock(self, block, nil, nil);
}
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *))block queue:(dispatch_queue_t)queue {
    return RLMAddNotificationBlock(self, block, nil, queue);
}

- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *))block
                                      keyPaths:(NSArray<NSString *> *)keyPaths {
    return RLMAddNotificationBlock(self, block, keyPaths, nil);
}

- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *))block
                                      keyPaths:(NSArray<NSString *> *)keyPaths
                                         queue:(dispatch_queue_t)queue {
    return RLMAddNotificationBlock(self, block, keyPaths, queue);
}
#pragma clang diagnostic pop

- (realm::NotificationToken)addNotificationCallback:(id)block
keyPaths:(std::optional<std::vector<std::vector<std::pair<realm::TableKey, realm::ColKey>>>>&&)keyPaths {
    return _sectionedResults.add_notification_callback(CollectionCallbackWrapper{block, self}, std::move(keyPaths));
}

- (RLMClassInfo *)objectInfo {
    return _info;
}

- (instancetype)resolveInRealm:(RLMRealm *)realm {
     return translateErrors([&] {
        if (realm.isFrozen) {
            return [[RLMSectionedResults alloc] initWithSectionedResults:_sectionedResults.freeze(realm->_realm)
                                                              objectInfo:_info->resolve(realm)
                                                                keyBlock:_keyBlock];
        }
        else {
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
    return translateErrors([&] { return !_sectionedResults.is_valid(); });
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
    return translateErrors([&] { return _sectionedResults.is_frozen(); });
}

@end

/// Stores information about a given section during thread handover.
@interface RLMSectionMetadata : NSObject

@property (nonatomic, strong) RLMSectionedResultsKeyBlock keyBlock;
@property (nonatomic, copy) id<RLMValue> sectionKey;

- (instancetype)initWithKeyBlock:(RLMSectionedResultsKeyBlock)keyBlock
                      sectionKey:(id<RLMValue>)sectionKey;
@end

@implementation RLMSectionMetadata
- (instancetype)initWithKeyBlock:(RLMSectionedResultsKeyBlock)keyBlock
                      sectionKey:(id<RLMValue>)sectionKey {
    if (self = [super init]) {
        _keyBlock = keyBlock;
        _sectionKey = sectionKey;
    }
    return self;
}
@end

@interface RLMSection () <RLMThreadConfined_Private>
@end

@implementation RLMSection {
    RLMSectionedResults *_parent;
    realm::ResultsSection _resultsSection;
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
                                parent:(RLMSectionedResults *)parent
{
    if (self = [super init]) {
        _resultsSection = std::move(resultsSection);
        _parent = parent;
    }
    return self;
}

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return [self objectAtIndex:index];
}

- (id)objectAtIndex:(NSUInteger)index {
    RLMAccessorContext ctx(*_parent.objectInfo);
    return translateErrors([&] {
        return ctx.box(_resultsSection[index]);
    });
}

- (NSUInteger)count {
    return translateErrors([&] {
        return _resultsSection.size();
    });
}

- (id<RLMValue>)key {
    return translateErrors([&] {
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
    return _parent.realm;
}

- (RLMClassInfo *)objectInfo {
    return _parent.objectInfo;
}

- (BOOL)isInvalidated {
    return translateErrors([&] { return !_resultsSection.is_valid(); });
}

- (BOOL)isFrozen {
    return translateErrors([&] { return _parent.frozen; });
}

// The compiler complains about the method's argument type not matching due to
// it not having the generic type attached, but it doesn't seem to be possible
// to actually include the generic type
// http://www.openradar.me/radar?id=6135653276319744
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *))block {
    return RLMAddNotificationBlock(self, block, nil, nil);
}
- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *))block queue:(dispatch_queue_t)queue {
    return RLMAddNotificationBlock(self, block, nil, queue);
}

- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *))block keyPaths:(NSArray<NSString *> *)keyPaths {
    return RLMAddNotificationBlock(self, block, keyPaths, nil);
}

- (RLMNotificationToken *)addNotificationBlock:(void (^)(RLMResults *, RLMSectionedResultsChange *))block
                                      keyPaths:(NSArray<NSString *> *)keyPaths
                                         queue:(dispatch_queue_t)queue {
    return RLMAddNotificationBlock(self, block, keyPaths, queue);
}
#pragma clang diagnostic pop

- (realm::NotificationToken)addNotificationCallback:(id)block
keyPaths:(std::optional<std::vector<std::vector<std::pair<realm::TableKey, realm::ColKey>>>>&&)keyPaths {
    return _resultsSection.add_notification_callback(CollectionCallbackWrapper{block, self}, std::move(keyPaths));
}

#pragma mark - Thread Confined Protocol Conformance

- (realm::ThreadSafeReference)makeThreadSafeReference {
    return _parent->_results;
}

- (RLMSectionMetadata *)objectiveCMetadata {
    return [[RLMSectionMetadata alloc] initWithKeyBlock:_parent->_keyBlock
                                             sectionKey:self.key];
}

+ (instancetype)objectWithThreadSafeReference:(realm::ThreadSafeReference)reference
                                     metadata:(RLMSectionMetadata *)metadata
                                        realm:(RLMRealm *)realm {
    auto results = reference.resolve<realm::Results>(realm->_realm);
    auto objType = RLMStringDataToNSString(results.get_object_type());

    RLMSectionedResults *sr = [[RLMSectionedResults alloc] initWithResults:std::move(results)
                                                                     realm:realm
                                                                objectInfo:realm->_info[objType]
                                                                  keyBlock:metadata.keyBlock];
    return translateErrors([&] {
        return [[RLMSection alloc] initWithResultsSection:sr->_sectionedResults[RLMObjcToMixed(metadata.sectionKey)]
                                                   parent:sr];
    });
}

- (instancetype)resolveInRealm:(RLMRealm *)realm {
     return translateErrors([&] {
        RLMSectionedResults *sr = realm.isFrozen ? [_parent freeze] : [_parent thaw];
        return [[RLMSection alloc] initWithResultsSection:sr->_sectionedResults[RLMObjcToMixed(self.key)]
                                                   parent:sr];
    });
}

- (instancetype)freeze {
    if (self.frozen) {
        return self;
    }
    return [self resolveInRealm:_parent.realm.freeze];
}

- (instancetype)thaw {
    if (!self.frozen) {
        return self;
    }
    return [self resolveInRealm:_parent.realm.thaw];
}

@end
