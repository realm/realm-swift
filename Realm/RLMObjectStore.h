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

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

@class RLMRealm, RLMSchema, RLMObjectBase, RLMResults, RLMProperty;

typedef NS_ENUM(NSUInteger, RLMUpdatePolicy) {
    RLMUpdatePolicyError = 1,
    RLMUpdatePolicyUpdateChanged = 3,
    RLMUpdatePolicyUpdateAll = 2,
};

NS_ASSUME_NONNULL_BEGIN

void RLMVerifyHasPrimaryKey(Class cls);

void RLMVerifyInWriteTransaction(RLMRealm *const realm);

//
// Accessor Creation
//

// create or get cached accessors for the given schema
void RLMRealmCreateAccessors(RLMSchema *schema);


//
// Adding, Removing, Getting Objects
//

// add an object to the given realm
void RLMAddObjectToRealm(RLMObjectBase *object, RLMRealm *realm, RLMUpdatePolicy);

// delete an object from its realm
void RLMDeleteObjectFromRealm(RLMObjectBase *object, RLMRealm *realm);

// deletes all objects from a realm
void RLMDeleteAllObjectsFromRealm(RLMRealm *realm);

// get objects of a given class
RLMResults *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate * _Nullable predicate)
NS_RETURNS_RETAINED;

// get an object with the given primary key
id _Nullable RLMGetObject(RLMRealm *realm, NSString *objectClassName, id _Nullable key) NS_RETURNS_RETAINED;

// create object from array or dictionary
RLMObjectBase *RLMCreateObjectInRealmWithValue(RLMRealm *realm, NSString *className,
                                               id _Nullable value, RLMUpdatePolicy updatePolicy)
NS_RETURNS_RETAINED;

//
// Accessor Creation
//


// Perform the per-property accessor initialization for a managed RealmSwiftObject
// promotingExisting should be true if the object was previously used as an
// unmanaged object, and false if it is a newly created object.
void RLMInitializeSwiftAccessor(RLMObjectBase *object, bool promotingExisting);

#ifdef __cplusplus
}

namespace realm {
    class Table;
    class Obj;
    struct ObjLink;
}
class RLMClassInfo;

// get an object with a given table & object key
RLMObjectBase *RLMObjectFromObjLink(RLMRealm *realm,
                                    realm::ObjLink&& objLink,
                                    bool parentIsSwiftObject) NS_RETURNS_RETAINED;

// Create accessors
RLMObjectBase *RLMCreateObjectAccessor(RLMClassInfo& info, int64_t key) NS_RETURNS_RETAINED;
RLMObjectBase *RLMCreateObjectAccessor(RLMClassInfo& info, realm::Obj&& obj) NS_RETURNS_RETAINED;
#endif

NS_ASSUME_NONNULL_END
