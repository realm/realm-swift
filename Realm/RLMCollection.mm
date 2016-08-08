////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

#import "RLMCollection_Private.hpp"

#import "RLMArray_Private.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"

#import "collection_notifications.hpp"
#import "list.hpp"
#import "results.hpp"

#import <realm/table_view.hpp>

static const int RLMEnumerationBufferSize = 16;

@implementation RLMFastEnumerator {
    // The buffer supplied by fast enumeration does not retain the objects given
    // to it, but because we create objects on-demand and don't want them
    // autoreleased (a table can have more rows than the device has memory for
    // accessor objects) we need a thing to retain them.
    id _strongBuffer[RLMEnumerationBufferSize];

    RLMRealm *_realm;
    RLMClassInfo *_info;

    // Collection being enumerated. Only one of these two will be valid: when
    // possible we enumerate the collection directly, but when in a write
    // transaction we instead create a frozen TableView and enumerate that
    // instead so that mutating the collection during enumeration works.
    id<RLMFastEnumerable> _collection;
    realm::TableView _tableView;
}

- (instancetype)initWithCollection:(id<RLMFastEnumerable>)collection objectSchema:(RLMClassInfo&)info {
    self = [super init];
    if (self) {
        _realm = collection.realm;
        _info = &info;

        if (_realm.inWriteTransaction) {
            _tableView = [collection tableView];
        }
        else {
            _collection = collection;
            [_realm registerEnumerator:self];
        }
    }
    return self;
}

- (void)dealloc {
    if (_collection) {
        [_realm unregisterEnumerator:self];
    }
}

- (void)detach {
    _tableView = [_collection tableView];
    _collection = nil;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                    count:(NSUInteger)len {
    [_realm verifyThread];
    if (!_tableView.is_attached() && !_collection) {
        @throw RLMException(@"Collection is no longer valid");
    }
    // The fast enumeration buffer size is currently a hardcoded number in the
    // compiler so this can't actually happen, but just in case it changes in
    // the future...
    if (len > RLMEnumerationBufferSize) {
        len = RLMEnumerationBufferSize;
    }

    NSUInteger batchCount = 0, count = state->extra[1];

    Class accessorClass = _info->rlmObjectSchema.accessorClass;
    for (NSUInteger index = state->state; index < count && batchCount < len; ++index) {
        RLMObject *accessor = RLMCreateManagedAccessor(accessorClass, _realm, _info);
        if (_collection) {
            accessor->_row = (*_info->table())[[_collection indexInSource:index]];
        }
        else if (_tableView.is_row_attached(index)) {
            accessor->_row = (*_info->table())[_tableView.get_source_ndx(index)];
        }
        RLMInitializeSwiftAccessorGenerics(accessor);
        _strongBuffer[batchCount] = accessor;
        batchCount++;
    }

    for (NSUInteger i = batchCount; i < len; ++i) {
        _strongBuffer[i] = nil;
    }

    if (batchCount == 0) {
        // Release our data if we're done, as we're autoreleased and so may
        // stick around for a while
        _collection = nil;
        if (_tableView.is_attached()) {
            _tableView = {};
        }
        else {
            [_realm unregisterEnumerator:self];
        }
    }

    state->itemsPtr = (__unsafe_unretained id *)(void *)_strongBuffer;
    state->state += batchCount;
    state->mutationsPtr = state->extra+1;

    return batchCount;
}
@end


NSArray *RLMCollectionValueForKey(id<RLMFastEnumerable> collection, NSString *key) {
    size_t count = collection.count;
    if (count == 0) {
        return @[];
    }

    RLMRealm *realm = collection.realm;
    RLMClassInfo *info = collection.objectInfo;

    NSMutableArray *results = [NSMutableArray arrayWithCapacity:count];
    if ([key isEqualToString:@"self"]) {
        for (size_t i = 0; i < count; i++) {
            size_t rowIndex = [collection indexInSource:i];
            [results addObject:RLMCreateObjectAccessor(realm, *info, rowIndex) ?: NSNull.null];
        }
        return results;
    }

    RLMObject *accessor = RLMCreateManagedAccessor(info->rlmObjectSchema.accessorClass, realm, info);
    realm::Table *table = info->table();
    for (size_t i = 0; i < count; i++) {
        size_t rowIndex = [collection indexInSource:i];
        accessor->_row = (*table)[rowIndex];
        RLMInitializeSwiftAccessorGenerics(accessor);
        [results addObject:[accessor valueForKey:key] ?: NSNull.null];
    }

    return results;
}

void RLMCollectionSetValueForKey(id<RLMFastEnumerable> collection, NSString *key, id value) {
    realm::TableView tv = [collection tableView];
    if (tv.size() == 0) {
        return;
    }

    RLMRealm *realm = collection.realm;
    RLMClassInfo *info = collection.objectInfo;
    RLMObject *accessor = RLMCreateManagedAccessor(info->rlmObjectSchema.accessorClass, realm, info);
    for (size_t i = 0; i < tv.size(); i++) {
        accessor->_row = tv[i];
        RLMInitializeSwiftAccessorGenerics(accessor);
        [accessor setValue:value forKey:key];
    }
}

NSString *RLMDescriptionWithMaxDepth(NSString *name,
                                     id<RLMCollection> collection,
                                     NSUInteger depth) {
    if (depth == 0) {
        return @"<Maximum depth exceeded>";
    }

    const NSUInteger maxObjects = 100;
    auto str = [NSMutableString stringWithFormat:@"%@ <%p> (\n", name, (void *)collection];
    size_t index = 0, skipped = 0;
    for (id obj in collection) {
        NSString *sub;
        if ([obj respondsToSelector:@selector(descriptionWithMaxDepth:)]) {
            sub = [obj descriptionWithMaxDepth:depth - 1];
        }
        else {
            sub = [obj description];
        }

        // Indent child objects
        NSString *objDescription = [sub stringByReplacingOccurrencesOfString:@"\n"
                                                                  withString:@"\n\t"];
        [str appendFormat:@"\t[%zu] %@,\n", index++, objDescription];
        if (index >= maxObjects) {
            skipped = collection.count - maxObjects;
            break;
        }
    }

    // Remove last comma and newline characters
    if (collection.count > 0) {
        [str deleteCharactersInRange:NSMakeRange(str.length-2, 2)];
    }
    if (skipped) {
        [str appendFormat:@"\n\t... %zu objects skipped.", skipped];
    }
    [str appendFormat:@"\n)"];
    return str;
}

@implementation RLMCancellationToken {
    realm::NotificationToken _token;
}
- (instancetype)initWithToken:(realm::NotificationToken)token {
    self = [super init];
    if (self) {
        _token = std::move(token);
    }
    return self;
}

- (void)stop {
    _token = {};
}

@end

@implementation RLMCollectionChange {
    realm::CollectionChangeSet _indices;
}

- (instancetype)initWithChanges:(realm::CollectionChangeSet)indices {
    self = [super init];
    if (self) {
        _indices = std::move(indices);
    }
    return self;
}

static NSArray *toArray(realm::IndexSet const& set) {
    NSMutableArray *ret = [NSMutableArray new];
    for (auto index : set.as_indexes()) {
        [ret addObject:@(index)];
    }
    return ret;
}

- (NSArray *)insertions {
    return toArray(_indices.insertions);
}

- (NSArray *)deletions {
    return toArray(_indices.deletions);
}

- (NSArray *)modifications {
    return toArray(_indices.modifications);
}

static NSArray *toIndexPathArray(realm::IndexSet const& set, NSUInteger section) {
    NSMutableArray *ret = [NSMutableArray new];
    NSUInteger path[2] = {section, 0};
    for (auto index : set.as_indexes()) {
        path[1] = index;
        [ret addObject:[NSIndexPath indexPathWithIndexes:path length:2]];
    }
    return ret;
}

- (NSArray<NSIndexPath *> *)deletionsInSection:(NSUInteger)section {
    return toIndexPathArray(_indices.deletions, section);
}

- (NSArray<NSIndexPath *> *)insertionsInSection:(NSUInteger)section {
    return toIndexPathArray(_indices.insertions, section);

}

- (NSArray<NSIndexPath *> *)modificationsInSection:(NSUInteger)section {
    return toIndexPathArray(_indices.modifications, section);

}
@end

template<typename Collection>
RLMNotificationToken *RLMAddNotificationBlock(id objcCollection,
                                              Collection& collection,
                                              void (^block)(id, RLMCollectionChange *, NSError *),
                                              bool suppressInitialChange) {
    struct IsValid {
        static bool call(realm::List const& list) {
            return list.is_valid();
        }
        static bool call(realm::Results const&) {
            return true;
        }
    };

    auto skip = suppressInitialChange ? std::make_shared<bool>(true) : nullptr;
    auto cb = [=, &collection](realm::CollectionChangeSet const& changes,
                               std::exception_ptr err) {
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

        if (!IsValid::call(collection)) {
            return;
        }

        if (skip && *skip) {
            *skip = false;
            block(objcCollection, nil, nil);
        }
        else if (changes.empty()) {
            block(objcCollection, nil, nil);
        }
        else {
            block(objcCollection, [[RLMCollectionChange alloc] initWithChanges:changes], nil);
        }
    };

    return [[RLMCancellationToken alloc] initWithToken:collection.add_notification_callback(cb)];
}

// Explicitly instantiate the templated function for the two types we'll use it on
template RLMNotificationToken *RLMAddNotificationBlock<realm::List>(id, realm::List&, void (^)(id, RLMCollectionChange *, NSError *), bool);
template RLMNotificationToken *RLMAddNotificationBlock<realm::Results>(id, realm::Results&, void (^)(id, RLMCollectionChange *, NSError *), bool);
