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

@class RLMObjectSchema, RLMObjectBase, RLMRealm, RLMSchema;

namespace realm {
    class History;
    class SharedGroup;
}

// A copy of all of the parameters used when adding an observer to an object,
// used for unregistering and reregistering observers when adding a standalone
// object to a Realm.
struct RLMRecordedObservation {
    __unsafe_unretained id observer;
    NSKeyValueObservingOptions options;
    void *context;
    NSString *key;
};

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

    void willChange(NSString *key, NSKeyValueChange kind=NSKeyValueChangeSetting, NSIndexSet *indexes=nil) const {
        if (indexes) {
            forEach([=](__unsafe_unretained auto o) {
                [o willChange:kind valuesAtIndexes:indexes forKey:key];
            });
        }
        else {
            forEach([=](__unsafe_unretained auto o) {
                [o willChangeValueForKey:key];
            });
        }
    }

    void didChange(NSString *key, NSKeyValueChange kind=NSKeyValueChangeSetting, NSIndexSet *indexes=nil) const {
        if (indexes) {
            forEach([=](__unsafe_unretained auto o) {
                [o didChange:kind valuesAtIndexes:indexes forKey:key];
            });
        }
        else {
            forEach([=](__unsafe_unretained auto o) {
                [o didChangeValueForKey:key];
            });
        }
    }

    void setReturnNil(bool value) {
        REALM_ASSERT(objectSchema);
        for (auto info = this; info; info = info->next)
            info->returnNil = value;
    }

    void setRow(size_t newRow);
    bool isForRow(size_t ndx) const {
        return row && row.get_index() == ndx;
    }

    void recordObserver(realm::Row& row, RLMObjectSchema *objectSchema,
                        id observer, NSString *keyPath,
                        NSKeyValueObservingOptions options, void *context);
    void removeObserver(id observer, NSString *keyPath);
    void removeObserver(id observer, NSString *keyPath, void *context);


    // remove all recorded observers from the object
    // used when adding standalone objects to a realm
    void removeObservers();
    // re-add the observers removed with removeObservers
    void restoreObservers();

    id valueForKey(NSString *key, id (^value)());

private:
    RLMObservationInfo *next = nullptr;
    RLMObservationInfo *prev = nullptr;

    // Row being observed
    realm::Row row;
    RLMObjectSchema *objectSchema;

    // Object doing the observing
    __unsafe_unretained id object;

    // valueForKey: hack
    bool returnNil = false;
    // Recorded observers for a standalone RLMObject; unused for persisted objects
    std::vector<RLMRecordedObservation> standaloneObservers;

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

// Call the appropriate SharedGroup member function, with change notifications
void RLMAdvanceRead(realm::SharedGroup &sg, realm::History &history, RLMSchema *schema);
void RLMRollbackAndContinueAsRead(realm::SharedGroup &sg, realm::History &history, RLMSchema *schema);
void RLMPromoteToWrite(realm::SharedGroup &sg, realm::History &history, RLMSchema *schema);

// invoke the block, sending notifications for cascading deletes/link nullifications
void RLMTrackDeletions(RLMRealm *realm, dispatch_block_t block);

RLMObservationInfo *RLMGetObservationInfo(std::unique_ptr<RLMObservationInfo> const& info, size_t row, RLMObjectSchema *objectSchema);
