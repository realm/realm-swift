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

#import "RLMAccessor.h"
#import "RLMArray_Private.hpp"
#import "RLMListBase.h"
#import "RLMObservation.hpp"
#import "RLMObject_Private.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMOptionalBase.h"
#import "RLMProperty_Private.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMSwiftSupport.h"
#import "RLMUtil.hpp"

#import "object_store.hpp"
#import "results.hpp"
#import "shared_realm.hpp"

#import <objc/message.h>

using namespace realm;

void RLMRealmCreateAccessors(RLMSchema *schema) {
    for (RLMObjectSchema *objectSchema in schema.objectSchema) {
        if (objectSchema.accessorClass != objectSchema.objectClass) {
            continue;
        }

        static unsigned long long count = 0;
        NSString *prefix = [NSString stringWithFormat:@"RLMAccessor_%llu_", count++];
        objectSchema.accessorClass = RLMAccessorClassForObjectClass(objectSchema.objectClass, objectSchema, prefix);
    }
}

static inline void RLMVerifyRealmRead(__unsafe_unretained RLMRealm *const realm) {
    if (!realm) {
        @throw RLMException(@"Realm must not be nil");
    }
    [realm verifyThread];
}

static inline void RLMVerifyInWriteTransaction(__unsafe_unretained RLMRealm *const realm) {
    RLMVerifyRealmRead(realm);
    // if realm is not writable throw
    if (!realm.inWriteTransaction) {
        @throw RLMException(@"Can only add, remove, or create objects in a Realm in a write transaction - call beginWriteTransaction on an RLMRealm instance first.");
    }
}

void RLMInitializeSwiftAccessorGenerics(__unsafe_unretained RLMObjectBase *const object) {
    if (!object || !object->_row || !object->_objectSchema->_isSwiftClass) {
        return;
    }
    if (![object isKindOfClass:object->_objectSchema.objectClass]) {
        // It can be a different class if it's a dynamic object, and those don't
        // require any init here (and would crash since they don't have the ivars)
        return;
    }

    for (RLMProperty *prop in object->_objectSchema.swiftGenericProperties) {
        if (prop->_type == RLMPropertyTypeArray) {
            RLMArray *array = [[RLMArrayLinkView alloc] initWithParent:object property:prop];
            [object_getIvar(object, prop.swiftIvar) set_rlmArray:array];
        }
        else if (prop.type == RLMPropertyTypeLinkingObjects) {
            id linkingObjects = object_getIvar(object, prop.swiftIvar);
            [linkingObjects setObject:(id)[[RLMWeakObjectHandle alloc] initWithObject:object]];
            [linkingObjects setProperty:prop];
        }
        else {
            RLMOptionalBase *optional = object_getIvar(object, prop.swiftIvar);
            optional.property = prop;
            optional.object = object;
        }
    }
}

static void validateValueForProperty(__unsafe_unretained id const obj,
                                     __unsafe_unretained RLMProperty *const prop) {
    switch (prop.type) {
        case RLMPropertyTypeString:
        case RLMPropertyTypeBool:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeData:
            if (!RLMIsObjectValidForProperty(obj, prop)) {
                @throw RLMException(@"Invalid value '%@' for property '%@'", obj, prop.name);
            }
            break;
        case RLMPropertyTypeObject:
            break;
        case RLMPropertyTypeArray: {
            if (obj != nil && obj != NSNull.null) {
                if (![obj conformsToProtocol:@protocol(NSFastEnumeration)]) {
                    @throw RLMException(@"Array property value (%@) is not enumerable.", obj);
                }
            }
            break;
        }
        case RLMPropertyTypeAny:
        case RLMPropertyTypeLinkingObjects:
            @throw RLMException(@"Invalid value '%@' for property '%@'", obj, prop.name);
    }
}

static NSUInteger createRowForObject(RLMClassInfo const& info) {
    try {
        return info.table()->add_empty_row();
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
}

/* If a row exists with the specified primary key value, return its index. Otherwise, return `realm::not_found`.
 *
 * Precondition: `info` must refer to a class which has a primary key property
 * Precondition: `primaryValue` is a validated property value that has been coerced to `nil`
 */
static NSUInteger getRowForObjectWithPrimaryKey(RLMClassInfo const& info, id primaryValue) {
    REALM_ASSERT_DEBUG(info.propertyForPrimaryKey());

    RLMProperty *const primaryProperty = info.propertyForPrimaryKey();
    const NSUInteger primaryPropertyColumn = info.tableColumn(primaryProperty);

    switch (primaryProperty.type) {
        case RLMPropertyTypeString:
            return info.table()->find_first_string(primaryPropertyColumn, RLMStringDataWithNSString(primaryValue));

        case RLMPropertyTypeInt:
            if (primaryValue) {
                return info.table()->find_first_int(primaryPropertyColumn, [primaryValue longLongValue]);
            } else {
                return info.table()->find_first_null(primaryPropertyColumn);
            }

        default:
            REALM_UNREACHABLE();
    }
}

/* Create a row with the specified primary key value and return its index.
 *
 * Precondition: `info` must refer to a class which has a valid primary key property
 * Precondition: a write transaction is in progress
 * Precondition: no row already exists with the specified `primaryValue` for this model
 */
static NSUInteger createRowForObjectWithPrimaryKey(RLMClassInfo const& info, id primaryValue) {
    REALM_ASSERT_DEBUG(info.propertyForPrimaryKey());
    REALM_ASSERT_DEBUG(info.realm.inWriteTransaction);
    REALM_ASSERT_DEBUG(getRowForObjectWithPrimaryKey(info, primaryValue) == realm::not_found);

    RLMProperty *const primaryProperty = info.propertyForPrimaryKey();
    const NSUInteger primaryColumnIndex = info.tableColumn(primaryProperty);

    // create row
    const NSUInteger rowIndex = createRowForObject(info);
    Row row = info.table()->get(rowIndex);

    // set value for primary key
    validateValueForProperty(primaryValue, primaryProperty);
    primaryValue = RLMCoerceToNil(primaryValue);

    try {
        switch (primaryProperty.type) {
            case RLMPropertyTypeString:
                REALM_ASSERT_DEBUG(!primaryValue || [primaryValue isKindOfClass:NSString.class]);
                row.set_string_unique(primaryColumnIndex, RLMStringDataWithNSString(primaryValue));
                break;

            case RLMPropertyTypeInt:
                if (primaryValue) {
                    REALM_ASSERT_DEBUG([primaryValue isKindOfClass:NSNumber.class]);
                    row.set_int_unique(primaryColumnIndex, [primaryValue longLongValue]);
                } else {
                    row.set_null(primaryColumnIndex); // FIXME: Use `set_null_unique` once Core supports it
                }
                break;
                
            default:
                REALM_UNREACHABLE();
        }
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
    return rowIndex;
}

/* If a row exists with the specified primary key value, returns its index. Otherwise, creates a new row with the
 * specified primary key value and returns its index. The out parameter `foundExisting` will be set to indicate
 * whether or not a new row was created.
 *
 * Precondition: `info` must refer to a class which has a valid primary key property
 * Precondition: a write transaction is in progress
 */
static NSUInteger createOrGetRowForObjectWithPrimaryKey(RLMClassInfo const& info, id primaryValue,
                                                        bool* foundExisting = nullptr) {
    REALM_ASSERT_DEBUG(info.propertyForPrimaryKey());
    REALM_ASSERT_DEBUG(info.realm.inWriteTransaction);

    const NSUInteger existingRow = getRowForObjectWithPrimaryKey(info, primaryValue);
    if (existingRow == realm::not_found) {
        *foundExisting = false;
        return createRowForObjectWithPrimaryKey(info, primaryValue);
    } else {
        *foundExisting = true;
        return existingRow;
    }
}

/* If the class has a primary key, calls `valueForProperty` with that key and creates or gets the row with
 * this primary key value. Otherwise if the class has no primary key, creates a new row. The out parameter
 * `foundExisting` will be set to indicate whether or not a new row was created.
 *
 * Precondition: a write transaction is in progress
 */
template<typename F>
static NSUInteger createOrGetRowForObject(RLMClassInfo const& info, F valueForProperty,
                                          bool createOrUpdate, bool* foundExisting) {
    // try to get existing row if this class has a primary key
    if (RLMProperty *primaryProperty = info.propertyForPrimaryKey()) {
        // get primary value
        const id primaryValue = valueForProperty(primaryProperty);

        // search for existing object based on primary key type, creating a new row if one does not exist
        NSUInteger rowIndex = createOrGetRowForObjectWithPrimaryKey(info, RLMCoerceToNil(primaryValue), foundExisting);

        // ensure that `createOrUpdate` is set if we found an existing row
        if (*foundExisting && !createOrUpdate) {
            @throw RLMException(@"Can't create object with existing primary key value '%@'.", primaryValue);
        }
        return rowIndex;
    }
    // if no existing, create row
    else {
        *foundExisting = false;
        return createRowForObject(info);
    }
}

void RLMAddObjectToRealm(__unsafe_unretained RLMObjectBase *const object,
                         __unsafe_unretained RLMRealm *const realm, 
                         bool createOrUpdate) {
    RLMVerifyInWriteTransaction(realm);

    // verify that object is unmanaged
    if (object.invalidated) {
        @throw RLMException(@"Adding a deleted or invalidated object to a Realm is not permitted");
    }
    if (object->_realm) {
        if (object->_realm == realm) {
            // no-op
            return;
        }
        // for differing realms users must explicitly create the object in the second realm
        @throw RLMException(@"Object is already managed by another Realm");
    }
    if (object->_observationInfo && object->_observationInfo->hasObservers()) {
        @throw RLMException(@"Cannot add an object with observers to a Realm");
    }

    // set the realm and schema
    NSString *objectClassName = object->_objectSchema.className;
    auto& info = realm->_info[objectClassName];
    object->_info = &info;
    object->_objectSchema = info.rlmObjectSchema;
    object->_realm = realm;

    // get or create row
    bool foundExisting;
    auto primaryGetter = [=](__unsafe_unretained RLMProperty *const p) { return [object valueForKey:p.name]; };
    object->_row = (*info.table())[createOrGetRowForObject(info, primaryGetter, createOrUpdate, &foundExisting)];

    RLMCreationOptions creationOptions = RLMCreationOptionsPromoteUnmanaged;
    if (createOrUpdate) {
        creationOptions |= RLMCreationOptionsCreateOrUpdate;
    }

    // populate all properties
    for (RLMProperty *prop in info.rlmObjectSchema.properties) {
        // skip primary key when updating since it doesn't change
        if (prop.isPrimary)
            continue;

        // get object from ivar using key value coding
        id value = nil;
        if (prop.swiftIvar) {
            if (prop.type == RLMPropertyTypeArray) {
                value = static_cast<RLMListBase *>(object_getIvar(object, prop.swiftIvar))._rlmArray;
            }
            else { // optional
                value = static_cast<RLMOptionalBase *>(object_getIvar(object, prop.swiftIvar)).underlyingValue;
            }
        }
        else if ([object respondsToSelector:prop.getterSel]) {
            value = [object valueForKey:prop.getterName];
        }

        if (!value && !prop.optional) {
            @throw RLMException(@"No value or default value specified for property '%@' in '%@'",
                                prop.name, info.rlmObjectSchema.className);
        }

        // set the ivars for object and array properties to nil as otherwise the
        // accessors retain objects that are no longer accessible via the properties
        // this is mainly an issue when the object graph being added has cycles,
        // as it's not obvious that the user has to set the *ivars* to nil to
        // avoid leaking memory
        if (prop.type == RLMPropertyTypeObject || prop.type == RLMPropertyTypeArray) {
            if (!prop.swiftIvar) {
                ((void(*)(id, SEL, id))objc_msgSend)(object, prop.setterSel, nil);
            }
        }

        // set in table with out validation
        RLMDynamicSet(object, prop, RLMCoerceToNil(value), creationOptions);
    }

    // set to proper accessor class
    object_setClass(object, info.rlmObjectSchema.accessorClass);

    RLMInitializeSwiftAccessorGenerics(object);
}

RLMObjectBase *RLMCreateObjectInRealmWithValue(RLMRealm *realm, NSString *className, id value, bool createOrUpdate = false) {
    if (createOrUpdate && RLMIsObjectSubclass([value class])) {
        RLMObjectBase *obj = value;
        if ([obj->_objectSchema.className isEqualToString:className] && obj->_realm == realm) {
            // This is a no-op if value is an RLMObject of the same type already backed by the target realm.
            return value;
        }
    }

    // verify writable
    RLMVerifyInWriteTransaction(realm);

    // create the object
    auto& info = realm->_info[className];
    RLMObjectBase *object = RLMCreateManagedAccessor(info.rlmObjectSchema.accessorClass, realm, &info);

    RLMCreationOptions creationOptions = createOrUpdate ? RLMCreationOptionsCreateOrUpdate : RLMCreationOptionsNone;

    // create row, and populate
    if (NSArray *array = RLMDynamicCast<NSArray>(value)) {
        // get or create our accessor
        bool foundExisting;
        NSArray *props = info.rlmObjectSchema.properties;
        auto primaryGetter = [=](__unsafe_unretained RLMProperty *const p) {
            return array[[props indexOfObject:p]];
        };
        object->_row = (*info.table())[createOrGetRowForObject(info, primaryGetter, createOrUpdate, &foundExisting)];

        // populate
        for (NSUInteger i = 0; i < array.count; i++) {
            RLMProperty *prop = props[i];

            // skip primary key when updating since it doesn't change
            if (prop.isPrimary)
                continue;

            id val = array[i];
            validateValueForProperty(val, prop);
            RLMDynamicSet(object, prop, RLMCoerceToNil(val), creationOptions);
        }
    }
    else {
        __block bool foundExisting = false;
        __block NSDictionary *defaultValues = nil;
        __block bool usedDefault = false;
        auto getValue = ^(RLMProperty *prop) {
            id propValue = RLMValidatedValueForProperty(value, prop.name, info.rlmObjectSchema.className);
            usedDefault = !propValue && !foundExisting;
            if (usedDefault) {
                if (!defaultValues) {
                    defaultValues = RLMDefaultValuesForObjectSchema(info.rlmObjectSchema);
                }
                propValue = defaultValues[prop.name];
                if (!propValue && (prop.type == RLMPropertyTypeObject || prop.type == RLMPropertyTypeArray)) {
                    propValue = NSNull.null;
                }
            }
            return propValue;
        };
        // get or create our accessor
        object->_row = (*info.table())[createOrGetRowForObject(info, getValue, createOrUpdate, &foundExisting)];

        // populate
        for (RLMProperty *prop in info.rlmObjectSchema.properties) {
            // skip primary key when updating since it doesn't change
            if (prop.isPrimary)
                continue;

            if (id propValue = getValue(prop)) {
                validateValueForProperty(propValue, prop);
                // add SetDefault to creationoptions
                RLMCreationOptions propertyCreationOptions = creationOptions;
                if (usedDefault) {
                    propertyCreationOptions |= RLMCreationOptionsSetDefault;
                }
                RLMDynamicSet(object, prop, RLMCoerceToNil(propValue), propertyCreationOptions);
            }
            else if (!foundExisting && !prop.optional) {
                @throw RLMException(@"Property '%@' of object of type '%@' cannot be nil.", prop.name, info.rlmObjectSchema.className);
            }
        }
    }

    RLMInitializeSwiftAccessorGenerics(object);
    return object;
}

void RLMDeleteObjectFromRealm(__unsafe_unretained RLMObjectBase *const object,
                              __unsafe_unretained RLMRealm *const realm) {
    if (realm != object->_realm) {
        @throw RLMException(@"Can only delete an object from the Realm it belongs to.");
    }

    RLMVerifyInWriteTransaction(object->_realm);

    // move last row to row we are deleting
    if (object->_row.is_attached()) {
        RLMTrackDeletions(realm, ^{
            object->_row.get_table()->move_last_over(object->_row.get_index());
        });
    }

    // set realm to nil
    object->_realm = nil;
}

void RLMDeleteAllObjectsFromRealm(RLMRealm *realm) {
    RLMVerifyInWriteTransaction(realm);

    // clear table for each object schema
    for (auto& info : realm->_info) {
        RLMClearTable(info.second);
    }
}

RLMResults *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate *predicate) {
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
                                     results:realm::Results(realm->_realm, *info.table())];
}

id RLMGetObject(RLMRealm *realm, NSString *objectClassName, id key) {
    RLMVerifyRealmRead(realm);

    RLMClassInfo& info = realm->_info[objectClassName];
    auto primaryProperty = info.objectSchema->primary_key_property();
    if (!primaryProperty) {
        @throw RLMException(@"%@ does not have a primary key", objectClassName);
    }

    auto table = info.table();
    if (!table) {
        // read-only realms may be missing tables since we can't add any
        // missing ones on init
        return nil;
    }

    key = RLMCoerceToNil(key);
    if (!key && !primaryProperty->is_nullable) {
        @throw RLMException(@"Invalid null value for non-nullable primary key.");
    }

    size_t row = realm::not_found;
    switch (primaryProperty->type) {
        case PropertyType::String: {
            NSString *string = RLMDynamicCast<NSString>(key);
            if (!key || string) {
                row = table->find_first_string(primaryProperty->table_column, RLMStringDataWithNSString(string));
            } else {
                @throw RLMException(@"Invalid value '%@' of type '%@' for string primary key.", key, [key class]);
            }
            break;
        }
        case PropertyType::Int:
            if (NSNumber *number = RLMDynamicCast<NSNumber>(key)) {
                row = table->find_first_int(primaryProperty->table_column, number.longLongValue);
            } else if (!key) {
                row = table->find_first_null(primaryProperty->table_column);
            } else {
                @throw RLMException(@"Invalid value '%@' of type '%@' for int primary key.", key, [key class]);
            }
            break;
        default:
            REALM_UNREACHABLE();
    }

    if (row == realm::not_found) {
        return nil;
    }

    return RLMCreateObjectAccessor(realm, info, row);
}

RLMObjectBase *RLMCreateObjectAccessor(__unsafe_unretained RLMRealm *const realm,
                                       RLMClassInfo& info,
                                       NSUInteger index) {
    return RLMCreateObjectAccessor(realm, info, (*info.table())[index]);
}

// Create accessor and register with realm
RLMObjectBase *RLMCreateObjectAccessor(__unsafe_unretained RLMRealm *const realm,
                                       RLMClassInfo& info,
                                       realm::RowExpr row) {
    RLMObjectBase *accessor = RLMCreateManagedAccessor(info.rlmObjectSchema.accessorClass, realm, &info);
    accessor->_row = row;
    RLMInitializeSwiftAccessorGenerics(accessor);
    return accessor;
}
