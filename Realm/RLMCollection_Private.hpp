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

#import <Realm/RLMCollection.h>

#import <Realm/RLMRealm.h>

namespace realm {
    class List;
    class Results;
    class TableView;
    struct CollectionChangeSet;
    struct NotificationToken;
}
class RLMClassInfo;

@protocol RLMFastEnumerable
@property (nonatomic, readonly) RLMRealm *realm;
@property (nonatomic, readonly) RLMClassInfo *objectInfo;
@property (nonatomic, readonly) NSUInteger count;

- (NSUInteger)indexInSource:(NSUInteger)index;
- (realm::TableView)tableView;
@end

// An object which encapulates the shared logic for fast-enumerating RLMArray
// and RLMResults, and has a buffer to store strong references to the current
// set of enumerated items
@interface RLMFastEnumerator : NSObject
- (instancetype)initWithCollection:(id<RLMFastEnumerable>)collection
                      objectSchema:(RLMClassInfo&)objectSchema;

// Detach this enumerator from the source collection. Must be called before the
// source collection is changed.
- (void)detach;

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                    count:(NSUInteger)len;
@end

@interface RLMNotificationToken ()
- (void)suppressNextNotification;
- (RLMRealm *)realm;
@end

@interface RLMCancellationToken : RLMNotificationToken
- (instancetype)initWithToken:(realm::NotificationToken)token realm:(RLMRealm *)realm;
@end

@interface RLMCollectionChange ()
- (instancetype)initWithChanges:(realm::CollectionChangeSet)indices;
@end

template<typename Collection>
RLMNotificationToken *RLMAddNotificationBlock(id objcCollection,
                                              Collection& collection,
                                              void (^block)(id, RLMCollectionChange *, NSError *),
                                              bool suppressInitialChange=false);

NSArray *RLMCollectionValueForKey(id<RLMFastEnumerable> collection, NSString *key);
void RLMCollectionSetValueForKey(id<RLMFastEnumerable> collection, NSString *key, id value);
NSString *RLMDescriptionWithMaxDepth(NSString *name, id<RLMCollection> collection, NSUInteger depth);
