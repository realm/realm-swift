////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import "RLMSyncPermissionResults_Private.hpp"

#import "collection_notifications.hpp"
#import "RLMCollection_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMQueryUtil.hpp"
#import "RLMSchema_Private.hpp"
#import "RLMSyncPermissionValue_Private.hpp"
#import "RLMSyncUser_Private.hpp"
#import "RLMUtil.hpp"

#import "object.hpp"

using namespace realm;

@interface RLMSyncPermissionResults () {
    Results _results;
}
@end

@implementation RLMSyncPermissionResults

- (NSInteger)count {
    return _results.size();
}

- (RLMNotificationToken *)addNotificationBlock:(RLMPermissionStatusBlock)block {
    auto token = _results.async(RLMWrapPermissionStatusCallback(block));
    return [[RLMCancellationToken alloc] initWithToken:std::move(token) realm:nil];
}

- (RLMSyncPermissionValue *)objectAtIndex:(NSInteger)index {
    try {
        Object permission(_results.get_realm(), _results.get_object_schema(), _results.get(index));
        return [[RLMSyncPermissionValue alloc] initWithPermission:Permission(permission)];
    } catch (std::exception const& ex) {
        @throw RLMException(ex);
    }
}

- (instancetype)initWithResults:(Results)results {
    if (self = [super init]) {
        _results = std::move(results);
    }
    return self;
}

- (RLMSyncPermissionValue *)firstObject {
    return self.count == 0 ? nil : [self objectAtIndex:0];
}

- (RLMSyncPermissionValue *)lastObject {
    return self.count == 0 ? nil : [self objectAtIndex:(self.count - 1)];
}

- (NSInteger)indexOfObject:(RLMSyncPermissionValue *)object {
    for (int i=0; i<self.count; i++) {
        if ([[self objectAtIndex:i] isEqual:object]) {
            return i;
        }
    }
    return NSNotFound;
}

- (RLMSyncPermissionResults *)objectsWithPredicate:(NSPredicate *)predicate {
    const auto& realm = _results.get_realm();
    auto query = RLMPredicateToQuery(predicate,
                                     [RLMObjectSchema objectSchemaForObjectStoreSchema:_results.get_object_schema()],
                                     [RLMSchema dynamicSchemaFromObjectStoreSchema:realm->schema()],
                                     realm->read_group());
    auto filtered_results = _results.filter(std::move(query));
    return [[RLMSyncPermissionResults alloc] initWithResults:std::move(filtered_results)];
}

- (RLMSyncPermissionResults *)sortedResultsUsingProperty:(RLMSyncPermissionResultsSortProperty)property
                                               ascending:(BOOL)ascending {
    std::string property_name;
    switch (property) {
        case RLMSyncPermissionResultsSortPropertyPath:
            property_name = "path";
            break;
        case RLMSyncPermissionResultsSortPropertyUserID:
            property_name = "userId";
            break;
        case RLMSyncPermissionResultsSortDateUpdated:
            property_name = "updatedAt";
            break;
    }
    const auto& table = _results.get_tableview().get_parent();
    size_t col_idx = table.get_descriptor()->get_column_index(property_name);
    REALM_ASSERT(col_idx != size_t(-1));
    auto sorted_results = _results.sort({
        table, {{ col_idx }}, { static_cast<bool>(ascending) }
    });
    return [[RLMSyncPermissionResults alloc] initWithResults:std::move(sorted_results)];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len {
    NSUInteger thisSize = self.count;
    if (state->state == 0) {
        state->extra[0] = 0;
        state->extra[1] = (long)thisSize;
        state->state = 1;
    }
    NSUInteger objectsInBuffer = 0;
    long idx = state->extra[0];
    if ((unsigned long)idx == thisSize) {
        // finished
        return 0;
    }
    state->itemsPtr = buffer;
    state->mutationsPtr = state->extra + 1;
    while (true) {
        if (objectsInBuffer == len) {
            // Buffer is full.
            state->extra[0] = idx;
            return objectsInBuffer;
        }
        if ((unsigned long)idx == thisSize) {
            // finished
            state->extra[0] = idx;
            return objectsInBuffer;
        }
        // Otherwise, add an object and advance the index pointer.
        RLMSyncPermissionValue * __autoreleasing thisPermission = [self objectAtIndex:idx];
        buffer[objectsInBuffer] = thisPermission;
        idx++;
        objectsInBuffer++;
    }
}

- (NSString *)objectClassName {
    return @"RLMSyncPermission";
}

- (NSString *)description {
    // FIXME: rather than force-casting to a protocol we don't formally implement,
    // we should change RLMDescriptionWithMaxDepth to take a less restrictive
    // collection type.
    return RLMDescriptionWithMaxDepth(@"RLMSyncPermissionResults", (id<RLMCollection>)self, 1);
}

@end
