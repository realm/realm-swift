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

#import <realm/link_view.hpp> // required by row.hpp
#import <realm/row.hpp>

@class RLMObjectSchema, RLMObjectBase, RLMRealm, RLMSchema, RLMProperty;

namespace realm {
    class History;
    class SharedGroup;
}

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

    void prepareForInvalidation();

    bool isForRow(size_t ndx) const {
        return row && row.get_index() == ndx;
    }

    void recordObserver(realm::Row& row, RLMObjectSchema *objectSchema, NSString *keyPath);
    void removeObserver();
    bool hasObservers() const { return observerCount > 0; }

    id valueForKey(NSString *key);

private:
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

public:
    bool skipUnregisteringObservers = false;
    // storage for the observationInfo property on RLMObjectBase
    void *kvoInfo = nullptr;
};

RLMObservationInfo *RLMGetObservationInfo(std::unique_ptr<RLMObservationInfo> const& info, size_t row, RLMObjectSchema *objectSchema);

// Call the appropriate SharedGroup member function, with change notifications
void RLMAdvanceRead(realm::SharedGroup &sg, realm::History &history, RLMSchema *schema);
void RLMRollbackAndContinueAsRead(realm::SharedGroup &sg, realm::History &history, RLMSchema *schema);
void RLMPromoteToWrite(realm::SharedGroup &sg, realm::History &history, RLMSchema *schema);

// invoke the block, sending notifications for cascading deletes/link nullifications
void RLMTrackDeletions(RLMRealm *realm, dispatch_block_t block);
