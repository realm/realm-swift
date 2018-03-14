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

#import "RLMSyncPermissionResults.h"

#import "RLMCollection_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMQueryUtil.hpp"
#import "RLMResults_Private.hpp"
#import "RLMSchema_Private.hpp"
#import "RLMSyncPermission_Private.hpp"
#import "RLMSyncUtil_Private.hpp"
#import "RLMUtil.hpp"

#import "object.hpp"

using namespace realm;

namespace {

bool keypath_is_valid(NSString *keypath)
{
    static auto valid = [NSSet setWithArray:@[RLMSyncPermissionSortPropertyPath,
                                              RLMSyncPermissionSortPropertyUserID,
                                              RLMSyncPermissionSortPropertyUpdated]];
    return [valid containsObject:keypath];
}

}

/// Sort by the Realm Object Server path to the Realm to which the permission applies.
RLMSyncPermissionSortProperty const RLMSyncPermissionSortPropertyPath       = @"path";
/// Sort by the identity of the user to whom the permission applies.
RLMSyncPermissionSortProperty const RLMSyncPermissionSortPropertyUserID     = @"userId";
/// Sort by the date the permissions were last updated.
RLMSyncPermissionSortProperty const RLMSyncPermissionSortPropertyUpdated    = @"updatedAt";

@interface RLMSyncPermissionResults ()
@property (nonatomic, strong) RLMSchema *schema;
@property (nonatomic, strong) RLMObjectSchema *objectSchema;
@end

@implementation RLMSyncPermissionResults

#pragma mark - Public API

- (RLMPropertyType)type {
    return RLMPropertyTypeObject;
}

- (NSString *)objectClassName {
    return NSStringFromClass([RLMSyncPermission class]);
}

- (RLMRealm *)realm {
    return nil;
}

- (RLMSyncPermission *)objectAtIndex:(NSUInteger)index {
    return translateRLMResultsErrors([&] {
        Object permission(_results.get_realm(), _results.get_object_schema(), _results.get(index));
        return [[RLMSyncPermission alloc] initWithPermission:Permission(permission)];
    });
}

- (RLMSyncPermission *)firstObject {
    return self.count == 0 ? nil : [self objectAtIndex:0];
}

- (RLMSyncPermission *)lastObject {
    return self.count == 0 ? nil : [self objectAtIndex:(self.count - 1)];
}

- (NSUInteger)indexOfObject:(RLMSyncPermission *)object {
    if (object.key) {
        // Key-value permissions are only used for setting; they are never returned.
        return NSNotFound;
    }
    // Canonicalize the path.
    NSString *path = object.path;
    if ([path rangeOfString:@"~"].location != NSNotFound) {
        path = [path stringByReplacingOccurrencesOfString:@"~" withString:object.identity];
    }
    NSString *topPrivilege;
    switch (object.accessLevel) {
        case RLMSyncAccessLevelNone:
            // Deleted permissions are removed from the permissions Realm by ROS.
            return NSNotFound;
        case RLMSyncAccessLevelRead:
            topPrivilege = @"mayRead";
            break;
        case RLMSyncAccessLevelWrite:
            topPrivilege = @"mayWrite";
            break;
        case RLMSyncAccessLevelAdmin:
            topPrivilege = @"mayManage";
            break;
    }
    // Build the predicate.
    NSPredicate *p = [NSPredicate predicateWithFormat:@"%K = %@ AND %K = %@ AND %K == YES",
                      RLMSyncPermissionSortPropertyPath, path,
                      RLMSyncPermissionSortPropertyUserID, object.identity,
                      topPrivilege];
    return [self indexOfObjectWithPredicate:p];
}

- (NSUInteger)indexOfObjectWithPredicate:(NSPredicate *)predicate {
    return translateRLMResultsErrors([&] {
        auto& group = _results.get_realm()->read_group();
        auto query = RLMPredicateToQuery(predicate, self.objectSchema, self.schema, group);
        return RLMConvertNotFound(_results.index_of(std::move(query)));
    });
}

- (RLMResults<RLMSyncPermission *> *)objectsWithPredicate:(NSPredicate *)predicate {
    return translateRLMResultsErrors([&] {
        auto query = RLMPredicateToQuery(predicate, self.objectSchema, self.schema, _results.get_realm()->read_group());
        return [[RLMSyncPermissionResults alloc] initWithResults:_results.filter(std::move(query))];
    });
}

- (RLMResults<RLMSyncPermission *> *)sortedResultsUsingDescriptors:(NSArray<RLMSortDescriptor *> *)properties {
    if (properties.count == 0) {
        return self;
    }
    for (RLMSortDescriptor *descriptor in properties) {
        if (!keypath_is_valid(descriptor.keyPath)) {
            @throw RLMException(@"Invalid keypath specified. Use one of the constants defined in "
                                @" `RLMSyncPermissionSortProperty`.");
        }
    }
    return translateRLMResultsErrors([&] {
        auto sorted = _results.sort(RLMSortDescriptorsToKeypathArray(properties));
        return [[RLMSyncPermissionResults alloc] initWithResults:std::move(sorted)];
    });
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
- (RLMNotificationToken *)addNotificationBlock:(void(^)(RLMSyncPermissionResults *results,
                                                        RLMCollectionChange *change,
                                                        NSError *error))block {
    auto cb = [=](const realm::CollectionChangeSet& changes, std::exception_ptr ptr) {
        if (ptr) {
            NSError *error = translateSyncExceptionPtrToError(std::move(ptr), RLMPermissionActionTypeGet);
            REALM_ASSERT(error);
            block(nil, nil, error);
        } else {
            // Finished successfully
            block(self, [[RLMCollectionChange alloc] initWithChanges:changes], nil);
        }
    };
    return [[RLMCancellationToken alloc] initWithToken:_results.add_notification_callback(std::move(cb)) realm:nil];
}
#pragma clang diagnostic pop

- (id)aggregate:(__unused NSString *)property
         method:(__unused util::Optional<Mixed> (Results::*)(size_t))method
     methodName:(__unused NSString *)methodName returnNilForEmpty:(__unused BOOL)returnNilForEmpty {
    // We don't support any of the min/max/average/sum APIs; they don't make sense for this collection type.
    return nil;
}

- (id)valueForKey:(NSString *)key {
    size_t count = self.count;
    if (count == 0) {
        return @[];
    }
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:count];
    if ([key isEqualToString:@"self"]) {
        for (size_t i = 0; i < count; i++) {
            [results addObject:[self objectAtIndex:i]];
        }
    } else {
        for (size_t i = 0; i < count; i++) {
            [results addObject:[[self objectAtIndex:i] valueForKey:key] ?: NSNull.null];
        }
    }
    return results;
}

- (void)setValue:(__unused id)value forKey:(__unused NSString *)key {
    @throw RLMException(@"Cannot set values for the read-only type `RLMSyncPermission`.");
}

#pragma mark - System

- (RLMSchema *)schema {
    if (!_schema) {
        _schema = [RLMSchema dynamicSchemaFromObjectStoreSchema:_results.get_realm()->schema()];
    }
    return _schema;
}

- (RLMObjectSchema *)objectSchema {
    if (!_objectSchema) {
        _objectSchema = [RLMObjectSchema objectSchemaForObjectStoreSchema:_results.get_object_schema()];
    }
    return _objectSchema;
}

- (NSString *)description {
    return RLMDescriptionWithMaxDepth(@"RLMSyncPermissionResults", self, 1);
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])buffer
                                    count:(NSUInteger)len {
    // FIXME: It would be nice to have a shared fast enumeration implementation for `realm::Results`-only RLMResults.
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
        RLMSyncPermission * __autoreleasing thisPermission = [self objectAtIndex:idx];
        buffer[objectsInBuffer] = thisPermission;
        idx++;
        objectsInBuffer++;
    }
}

@end
