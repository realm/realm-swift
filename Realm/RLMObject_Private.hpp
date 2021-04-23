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
#import "RLMUtil.hpp"

#import <realm/obj.hpp>

class RLMObservationInfo;

// RLMObject accessor and read/write realm
@interface RLMObjectBase () {
    @public
    realm::Obj _row;
    RLMObservationInfo *_observationInfo;
    RLMClassInfo *_info;
}
@end

id RLMCreateManagedAccessor(Class cls, RLMClassInfo *info) NS_RETURNS_RETAINED;

// throw an exception if the object is invalidated or on the wrong thread
static inline void RLMVerifyAttached(__unsafe_unretained RLMObjectBase *const obj) {
    if (!obj->_row.is_valid()) {
        @throw RLMException(@"Object has been deleted or invalidated.");
    }
    [obj->_realm verifyThread];
}

// throw an exception if the object can't be modified for any reason
static inline void RLMVerifyInWriteTransaction(__unsafe_unretained RLMObjectBase *const obj) {
    // first verify is attached
    RLMVerifyAttached(obj);

    if (!obj->_realm.inWriteTransaction) {
        @throw RLMException(@"Attempting to modify object outside of a write transaction - call beginWriteTransaction on an RLMRealm instance first.");
    }
}

[[clang::objc_runtime_visible]]
@interface RealmSwiftDynamicObject : RealmSwiftObject
@end
