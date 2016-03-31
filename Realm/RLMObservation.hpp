////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

#import <Foundation/Foundation.h>

#import "binding_context.hpp"

#import <Realm/RLMDefines.h>

#import <realm/link_view.hpp> // required by row.hpp
#import <realm/row.hpp>

@class RLMObjectSchema, RLMObjectBase, RLMRealm, RLMSchema, RLMProperty;

namespace realm {
    class History;
    class SharedGroup;
}

// RLMObservationInfo stores all of the KVO-related data for RLMObjectBase and
// RLMArray. There is a one-to-one relationship between observed objects and
// RLMObservationInfo instances, so it could be folded into RLMObjectBase, and
// is a separate class mostly to avoid making all accessor objects far larger.
//
// RLMObjectSchema stores a vector of pointers to the first observation info
// created for each row. If there are multiple observation infos for a single
// row (such as if there are multiple observed objects backed by a single row,
// or if both an object and an array property of that object are observed),
// they're stored in an intrusive doubly-linked-list in the `next` and `prev`
// members. This is done primarily to make it simpler and faster to loop over
// all of the observed objects for a single row, as that needs to be done for
// every change.
class RLMObservationInfo {
public:
    RLMObservationInfo(id object);
    RLMObservationInfo(RLMObjectSchema *objectSchema, std::size_t row, id object);
    ~RLMObservationInfo();

    realm::Row const& getRow() const {
        return row;
    }

    RLMObjectSchema *getObjectSchema() const {
        return objectSchema;
    }

    // Send willChange/didChange notifications to all observers for this object/row
    // Sends the array versions if indexes is non-nil, normal versions otherwise
    void willChange(NSString *key, NSKeyValueChange kind=NSKeyValueChangeSetting, NSIndexSet *indexes=nil) const;
    void didChange(NSString *key, NSKeyValueChange kind=NSKeyValueChangeSetting, NSIndexSet *indexes=nil) const;

    bool isForRow(size_t ndx) const {
        return row && row.get_index() == ndx;
    }

    void recordObserver(realm::Row& row, RLMObjectSchema *objectSchema, NSString *keyPath);
    void removeObserver();
    bool hasObservers() const { return observerCount > 0; }

    // valueForKey: on observed object and array properties needs to return the
    // same object each time for KVO to work at all. Doing this all the time
    // requires some odd semantics to avoid reference cycles, so instead we do
    // it only to the extent specifically required by KVO. In addition, we
    // need to continue to return the same object even if this row is deleted,
    // or deleting an object with active observers will explode horribly.
    // Once prepareForInvalidation() is called, valueForKey() will always return
    // the cached value for object and array properties without checking the
    // backing row to verify it's up-to-date.
    //
    // prepareForInvalidation() must be called on the head of the linked list
    // (i.e. on the object pointed to directly by the object schema)
    id valueForKey(NSString *key);

    void prepareForInvalidation();

private:
    // Doubly-linked-list of observed objects for the same row as this
    RLMObservationInfo *next = nullptr;
    RLMObservationInfo *prev = nullptr;

    // Row being observed
    realm::Row row;
    RLMObjectSchema *objectSchema;

    // Object doing the observing
    __unsafe_unretained id object;

    // valueForKey: hack
    bool invalidated = false;
    size_t observerCount = 0;
    NSString *lastKey = nil;
    __unsafe_unretained RLMProperty *lastProp = nil;

    // objects returned from valueForKey() to keep them alive in case observers
    // are added and so that they can still be accessed after row is detached
    NSMutableDictionary *cachedObjects;

    void setRow(realm::Table &table, size_t newRow);

    template<typename F>
    void forEach(F&& f) const {
        for (auto info = prev; info; info = info->prev)
            f(info->object);
        for (auto info = this; info; info = info->next)
            f(info->object);
    }

    // Default move/copy constructors don't work due to the intrusive linked
    // list and we don't need them
    RLMObservationInfo(RLMObservationInfo const&) = delete;
    RLMObservationInfo(RLMObservationInfo&&) = delete;
    RLMObservationInfo& operator=(RLMObservationInfo const&) = delete;
    RLMObservationInfo& operator=(RLMObservationInfo&&) = delete;
};

// Get the the observation info chain for the given row
// Will simply return info if it's non-null, and will search ojectSchema's array
// for a matching one otherwise, and return null if there are none
RLMObservationInfo *RLMGetObservationInfo(RLMObservationInfo *info, size_t row, RLMObjectSchema *objectSchema);

// delete all objects from a single table with change notifications
void RLMClearTable(RLMObjectSchema *realm);

// invoke the block, sending notifications for cascading deletes/link nullifications
void RLMTrackDeletions(RLMRealm *realm, dispatch_block_t block);

std::vector<realm::BindingContext::ObserverState> RLMGetObservedRows(NSArray RLM_GENERIC(RLMObjectSchema *) *schema);
void RLMWillChange(std::vector<realm::BindingContext::ObserverState> const& observed, std::vector<void *> const& invalidated);
void RLMDidChange(std::vector<realm::BindingContext::ObserverState> const& observed, std::vector<void *> const& invalidated);
