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

#import "RLMObjectStore.h"

#import "RLMAccessor.hpp"
#import "RLMArray_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMObject_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMSet_Private.hpp"
#import "RLMSwiftCollectionBase.h"
#import "RLMSwiftSupport.h"
#import "RLMUtil.hpp"
#import "RLMSwiftValueStorage.h"

#import <realm/object-store/object_store.hpp>
#import <realm/object-store/results.hpp>
#import <realm/object-store/shared_realm.hpp>
#import <realm/group.hpp>

#import <objc/message.h>

using namespace realm;

void RLMRealmCreateAccessors(RLMSchema *schema) {
    const size_t bufferSize = sizeof("RLM:Managed  ") // includes null terminator
                            + std::numeric_limits<unsigned long long>::digits10
                            + realm::Group::max_table_name_length;

    char className[bufferSize] = "RLM:Managed ";
    char *const start = className + strlen(className);

    for (RLMObjectSchema *objectSchema in schema.objectSchema) {
        if (objectSchema.accessorClass != objectSchema.objectClass) {
            continue;
        }

        static unsigned long long count = 0;
        sprintf(start, "%llu %s", count++, objectSchema.className.UTF8String);
        objectSchema.accessorClass = RLMManagedAccessorClassForObjectClass(objectSchema.objectClass, objectSchema, className);
    }
}

static inline void RLMVerifyRealmRead(__unsafe_unretained RLMRealm *const realm) {
    if (!realm) {
        @throw RLMException(@"Realm must not be nil");
    }
    [realm verifyThread];
    if (realm->_realm->is_closed()) {
        // This message may seem overly specific, but frozen Realms are currently
        // the only ones which we outright close.
        @throw RLMException(@"Cannot read from a frozen Realm which has been invalidated.");
    }
}

void RLMVerifyInWriteTransaction(__unsafe_unretained RLMRealm *const realm) {
    RLMVerifyRealmRead(realm);
    // if realm is not writable throw
    if (!realm.inWriteTransaction) {
        @throw RLMException(@"Can only add, remove, or create objects in a Realm in a write transaction - call beginWriteTransaction on an RLMRealm instance first.");
    }
}

void RLMInitializeSwiftAccessor(__unsafe_unretained RLMObjectBase *const object, bool promoteExisting) {
    if (!object || !object->_row || !object->_objectSchema->_isSwiftClass) {
        return;
    }
    if (![object isKindOfClass:object->_objectSchema.objectClass]) {
        // It can be a different class if it's a dynamic object, and those don't
        // require any init here (and would crash since they don't have the ivars)
        return;
    }

    if (promoteExisting) {
        for (RLMProperty *prop in object->_objectSchema.swiftGenericProperties) {
            [prop.swiftAccessor promote:prop on:object];
        }
    }
    else {
        for (RLMProperty *prop in object->_objectSchema.swiftGenericProperties) {
            [prop.swiftAccessor initialize:prop on:object];
        }
    }
}

void RLMVerifyHasPrimaryKey(Class cls) {
    RLMObjectSchema *schema = [cls sharedSchema];
    if (!schema.primaryKeyProperty) {
        NSString *reason = [NSString stringWithFormat:@"'%@' does not have a primary key and can not be updated", schema.className];
        @throw [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];
    }
}

static CreatePolicy updatePolicyToCreatePolicy(RLMUpdatePolicy policy) {
    CreatePolicy createPolicy = {.create = true, .copy = false, .diff = false, .update = false};
    switch (policy) {
        case RLMUpdatePolicyError:
            break;
        case RLMUpdatePolicyUpdateChanged:
            createPolicy.diff = true;
            [[clang::fallthrough]];
        case RLMUpdatePolicyUpdateAll:
            createPolicy.update = true;
            break;
    }
    return createPolicy;
}

void RLMAddObjectToRealm(__unsafe_unretained RLMObjectBase *const object,
                         __unsafe_unretained RLMRealm *const realm,
                         RLMUpdatePolicy updatePolicy) {
    RLMVerifyInWriteTransaction(realm);

    CreatePolicy createPolicy = updatePolicyToCreatePolicy(updatePolicy);
    createPolicy.copy = false;
    auto& info = realm->_info[object->_objectSchema.className];
    RLMAccessorContext c{info};
    c.createObject(object, createPolicy);
}

RLMObjectBase *RLMCreateObjectInRealmWithValue(RLMRealm *realm, NSString *className,
                                               id value, RLMUpdatePolicy updatePolicy) {
    RLMVerifyInWriteTransaction(realm);

    CreatePolicy createPolicy = updatePolicyToCreatePolicy(updatePolicy);
    createPolicy.copy = true;

    auto& info = realm->_info[className];
    RLMAccessorContext c{info};
    RLMObjectBase *object = RLMCreateManagedAccessor(info.rlmObjectSchema.accessorClass, &info);
    auto [obj, reuseExisting] = c.createObject(value, createPolicy, true);
    if (reuseExisting) {
        return value;
    }
    object->_row = std::move(obj);
    RLMInitializeSwiftAccessor(object, false);
    return object;
}

RLMObjectBase *RLMObjectFromObjLink(RLMRealm *realm, realm::ObjLink&& objLink, bool parentIsSwiftObject) {
    if (auto* tableInfo = realm->_info[objLink.get_table_key()]) {
        return RLMCreateObjectAccessor(*tableInfo, objLink.get_obj_key().value);
    } else {
        // Construct the object dynamically.
        // This code path should only be hit on first access of the object.
        Class cls = parentIsSwiftObject ? [RealmSwiftDynamicObject class] : [RLMDynamicObject class];
        auto& group = realm->_realm->read_group();
        auto schema = std::make_unique<realm::ObjectSchema>(group,
                                                            group.get_table_name(objLink.get_table_key()),
                                                            objLink.get_table_key());
        RLMObjectSchema *rlmObjectSchema = [RLMObjectSchema objectSchemaForObjectStoreSchema:*schema];
        rlmObjectSchema.accessorClass = cls;
        rlmObjectSchema.isSwiftClass = parentIsSwiftObject;
        realm->_info.appendDynamicObjectSchema(std::move(schema), rlmObjectSchema, realm);
        return RLMCreateObjectAccessor(realm->_info[rlmObjectSchema.className], objLink.get_obj_key().value);
    }
}

void RLMDeleteObjectFromRealm(__unsafe_unretained RLMObjectBase *const object,
                              __unsafe_unretained RLMRealm *const realm) {
    if (realm != object->_realm) {
        @throw RLMException(@"Can only delete an object from the Realm it belongs to.");
    }

    RLMVerifyInWriteTransaction(object->_realm);

    if (object->_row.is_valid()) {
        RLMObservationTracker tracker(realm, true);
        object->_row.remove();
    }
    object->_realm = nil;
}

void RLMDeleteAllObjectsFromRealm(RLMRealm *realm) {
    RLMVerifyInWriteTransaction(realm);

    // clear table for each object schema
    for (auto& info : realm->_info) {
        RLMClearTable(info.second);
    }
}

RLMResults *RLMGetObjects(__unsafe_unretained RLMRealm *const realm,
                          NSString *objectClassName,
                          NSPredicate *predicate) {
    RLMVerifyRealmRead(realm);

    // create view from table and predicate
    RLMClassInfo& info = realm->_info[objectClassName];
    if (!info.table()) {
        // read-only realms may be missing tables since we can't add any
        // missing ones on init
        return [RLMResults resultsWithObjectInfo:info results:{}];
    }

    if (predicate) {
        realm::Query query = RLMPredicateToQuery(predicate, info.rlmObjectSchema, realm.schema, realm.group);
        return [RLMResults resultsWithObjectInfo:info
                                         results:realm::Results(realm->_realm, std::move(query))];
    }

    return [RLMResults resultsWithObjectInfo:info
                                     results:realm::Results(realm->_realm, info.table())];
}

id RLMGetObject(RLMRealm *realm, NSString *objectClassName, id key) {
    RLMVerifyRealmRead(realm);

    auto& info = realm->_info[objectClassName];
    if (RLMProperty *prop = info.propertyForPrimaryKey()) {
        RLMValidateValueForProperty(key, info.rlmObjectSchema, prop);
    }
    try {
        RLMAccessorContext c{info};
        auto obj = realm::Object::get_for_primary_key(c, realm->_realm, *info.objectSchema,
                                                      key ?: NSNull.null);
        if (!obj.is_valid())
            return nil;
        return RLMCreateObjectAccessor(info, obj.obj());
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
}

RLMObjectBase *RLMCreateObjectAccessor(RLMClassInfo& info, int64_t key) {
    return RLMCreateObjectAccessor(info, info.table()->get_object(realm::ObjKey(key)));
}

// Create accessor and register with realm
RLMObjectBase *RLMCreateObjectAccessor(RLMClassInfo& info, realm::Obj&& obj) {
    RLMObjectBase *accessor = RLMCreateManagedAccessor(info.rlmObjectSchema.accessorClass, &info);
    accessor->_row = std::move(obj);
    RLMInitializeSwiftAccessor(accessor, false);
    return accessor;
}
