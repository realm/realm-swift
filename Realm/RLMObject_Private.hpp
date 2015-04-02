////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

#import "RLMObject_Private.h"

#import "RLMRealm_Private.hpp"

#import <realm/link_view.hpp> // required by row.hpp
#import <realm/row.hpp>

struct RLMObservationInfo2 {
    RLMObservationInfo2 *next = nullptr;
    RLMObservationInfo2 *prev = nullptr;
    realm::Row row;
    __unsafe_unretained id object;
    RLMObjectSchema *objectSchema;
    void *kvoInfo = nullptr;
    bool returnNil = false;

    RLMObservationInfo2(RLMObjectSchema *objectSchema, std::size_t row, id object);
    ~RLMObservationInfo2();

    void setReturnNil(bool value) {
        for (auto info = this; info; info = info->next)
            info->returnNil = value;
    }

    void setRow(size_t newRow);
};

template<typename F>
void for_each(const RLMObservationInfo2 *info, F&& f) {
    for (; info; info = info->next)
        f(info->object);
}

// RLMObject accessor and read/write realm
@interface RLMObjectBase () {
    @public
    realm::Row _row;
    NSMutableArray *_standaloneObservers;
}

+ (BOOL)shouldPersistToRealm;

@end

// throw an exception if the object is invalidated or on the wrong thread
static inline void RLMVerifyAttached(__unsafe_unretained RLMObjectBase *const obj) {
    if (!obj->_row.is_attached()) {
        @throw RLMException(@"Object has been deleted or invalidated.");
    }
    RLMCheckThread(obj->_realm);
}

// throw an exception if the object can't be modified for any reason
static inline void RLMVerifyInWriteTransaction(__unsafe_unretained RLMObjectBase *const obj) {
    // first verify is attached
    RLMVerifyAttached(obj);

    if (!obj->_realm->_inWriteTransaction) {
        @throw RLMException(@"Attempting to modify object outside of a write transaction - call beginWriteTransaction on an RLMRealm instance first.");
    }
}


void RLMOverrideStandaloneMethods(Class cls);

void RLMForEachObserver(RLMObjectBase *obj, void (^block)(RLMObjectBase*));
void RLMTrackDeletions(RLMRealm *realm, dispatch_block_t block);
