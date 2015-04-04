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

struct RLMObservationInfo {
    RLMObservationInfo *next = nullptr;
    RLMObservationInfo *prev = nullptr;

    // Row being observed
    realm::Row row;
    RLMObjectSchema *objectSchema;

    // Object doing the observing
    __unsafe_unretained id object;
    // storage for the observationInfo property on RLMObjectBase
    void *kvoInfo = nullptr;

    // valueForKey: hack
    bool returnNil = false;
    // Recorded observers for a standalone RLMObject; unused for persisted objects
    std::vector<RLMRecordedObservation> standaloneObservers;
    bool skipUnregisteringObservers = false;

    RLMObservationInfo(id object);
    RLMObservationInfo(RLMObjectSchema *objectSchema, std::size_t row, id object);
    ~RLMObservationInfo();

    void setReturnNil(bool value) {
        for (auto info = this; info; info = info->next)
            info->returnNil = value;
    }

    void setRow(size_t newRow);
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

private:
    void setRow(realm::Table &table, size_t newRow);
};

template<typename F>
void for_each(const RLMObservationInfo *info, F&& f) {
    for (; info; info = info->next)
        f(info->object);
}

// Call the appropriate SharedGroup member function, with change notifications
void RLMAdvanceRead(realm::SharedGroup &sg, realm::History &history, RLMSchema *schema);
void RLMRollbackAndContinueAsRead(realm::SharedGroup &sg, realm::History &history, RLMSchema *schema);
void RLMPromoteToWrite(realm::SharedGroup &sg, realm::History &history, RLMSchema *schema);

// call the given block on each observer of the given row
void RLMForEachObserver(RLMObjectBase *obj, void (^block)(RLMObjectBase*));
// invoke the block, sending notifications for cascading deletes/link nullifications
void RLMTrackDeletions(RLMRealm *realm, dispatch_block_t block);

RLMObservationInfo *RLMGetObservationInfo(std::unique_ptr<RLMObservationInfo> const& info, size_t row, RLMObjectSchema *objectSchema);
