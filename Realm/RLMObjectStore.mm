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

// Schema used to created generated accessors
static NSMutableArray * const s_accessorSchema = [NSMutableArray new];

void RLMRealmCreateAccessors(RLMSchema *schema) {
    // create accessors for non-dynamic realms
    RLMSchema *matchingSchema = nil;
    for (RLMSchema *accessorSchema in s_accessorSchema) {
        if ([schema isEqualToSchema:accessorSchema]) {
            matchingSchema = accessorSchema;
            break;
        }
    }

    if (matchingSchema) {
        // reuse accessors
        for (RLMObjectSchema *objectSchema in schema.objectSchema) {
            objectSchema.accessorClass = matchingSchema[objectSchema.className].accessorClass;
        }
    }
    else {
        // create accessors and cache in s_accessorSchema
        for (RLMObjectSchema *objectSchema in schema.objectSchema) {
            if (objectSchema.table) {
                NSString *prefix = [NSString stringWithFormat:@"RLMAccessor_v%lu_",
                                    (unsigned long)s_accessorSchema.count];
                objectSchema.accessorClass = RLMAccessorClassForObjectClass(objectSchema.objectClass, objectSchema, prefix);
            }
        }
        [s_accessorSchema addObject:schema];
    }
}

void RLMClearAccessorCache() {
    [s_accessorSchema removeAllObjects];
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
    if (!object || !object->_row || !object->_objectSchema.isSwiftClass) {
        return;
    }

    static Class s_swiftObjectClass = NSClassFromString(@"RealmSwiftObject");
    if (![object isKindOfClass:s_swiftObjectClass]) {
        return; // Is a Swift class using the obj-c API
    }

    for (RLMProperty *prop in object->_objectSchema.properties) {
        if (prop.type == RLMPropertyTypeArray) {
            RLMArray *array = [RLMArrayLinkView arrayWithObjectClassName:prop.objectClassName
                                                                    view:object->_row.get_linklist(prop.column)
                                                                   realm:object->_realm
                                                                     key:prop.name
                                                            parentSchema:object->_objectSchema];
            [RLMObjectUtilClass(YES) initializeListProperty:object property:prop array:array];
        } else if (prop.swiftIvar) {
            [RLMObjectUtilClass(YES) initializeOptionalProperty:object property:prop];
        }
    }

    for (RLMProperty *prop in object->_objectSchema.computedProperties) {
        if (prop.type == RLMPropertyTypeLinkingObjects) {
            RLMResults *results = RLMDynamicGet(object, prop);
            [RLMObjectUtilClass(YES) initializeLinkingObjectsProperty:object property:prop results:results];
        }
    }
}

template<typename F>
static inline NSUInteger RLMCreateOrGetRowForObject(__unsafe_unretained RLMObjectSchema *const schema, F primaryValueGetter, bool createOrUpdate, bool &created) {
    // try to get existing row if updating
    size_t rowIndex = realm::not_found;
    realm::Table &table = *schema.table;
    RLMProperty *primaryProperty = schema.primaryKeyProperty;
    if (createOrUpdate && primaryProperty) {
        // get primary value
        id primaryValue = primaryValueGetter(primaryProperty);
        if (primaryValue == NSNull.null) {
            primaryValue = nil;
        }
        
        // search for existing object based on primary key type
        if (primaryProperty.type == RLMPropertyTypeString) {
            rowIndex = table.find_first_string(primaryProperty.column, RLMStringDataWithNSString(primaryValue));
        }
        else {
            rowIndex = table.find_first_int(primaryProperty.column, [primaryValue longLongValue]);
        }
    }

    // if no existing, create row
    created = NO;
    if (rowIndex == realm::not_found) {
        rowIndex = table.add_empty_row();
        created = YES;
    }

    // get accessor
    return rowIndex;
}

void RLMAddObjectToRealm(__unsafe_unretained RLMObjectBase *const object,
                         __unsafe_unretained RLMRealm *const realm, 
                         bool createOrUpdate) {
    RLMVerifyInWriteTransaction(realm);

    // verify that object is standalone
    if (object.invalidated) {
        @throw RLMException(@"Adding a deleted or invalidated object to a Realm is not permitted");
    }
    if (object->_realm) {
        if (object->_realm == realm) {
            // no-op
            return;
        }
        // for differing realms users must explicitly create the object in the second realm
        @throw RLMException(@"Object is already persisted in a Realm");
    }
    if (object->_observationInfo && object->_observationInfo->hasObservers()) {
        @throw RLMException(@"Cannot add an object with observers to a Realm");
    }

    // set the realm and schema
    NSString *objectClassName = object->_objectSchema.className;
    RLMObjectSchema *schema = [realm.schema schemaForClassName:objectClassName];
    if (!schema) {
        @throw RLMException(@"Object type '%@' is not persisted in the Realm. "
                            @"If using a custom `objectClasses` / `objectTypes` array in your configuration, "
                            @"add `%@` to the list of `objectClasses` / `objectTypes`.",
                            objectClassName, objectClassName);
    }
    object->_objectSchema = schema;
    object->_realm = realm;

    // get or create row
    bool created;
    auto primaryGetter = [=](__unsafe_unretained RLMProperty *const p) { return [object valueForKey:p.getterName]; };
    object->_row = (*schema.table)[RLMCreateOrGetRowForObject(schema, primaryGetter, createOrUpdate, created)];

    RLMCreationOptions creationOptions = RLMCreationOptionsPromoteStandalone;
    if (createOrUpdate) {
        creationOptions |= RLMCreationOptionsCreateOrUpdate;
    }

    // populate all properties
    for (RLMProperty *prop in schema.properties) {
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

        // FIXME: Add condition to check for Mixed once it can support a nil value.
        if (!value && !prop.optional) {
            @throw RLMException(@"No value or default value specified for property '%@' in '%@'",
                                prop.name, schema.className);
        }

        // set in table with out validation
        // skip primary key when updating since it doesn't change
        if (created || !prop.isPrimary) {
            RLMDynamicSet(object, prop, RLMCoerceToNil(value), creationOptions);
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
    }

    // set to proper accessor class
    object_setClass(object, schema.accessorClass);

    RLMInitializeSwiftAccessorGenerics(object);
}

static void RLMValidateValueForProperty(__unsafe_unretained id const obj,
                                        __unsafe_unretained RLMProperty *const prop,
                                        __unsafe_unretained RLMSchema *const schema,
                                        bool validateNested,
                                        bool allowMissing);

static void RLMValidateValueForObjectSchema(__unsafe_unretained id const value,
                                            __unsafe_unretained RLMObjectSchema *const objectSchema,
                                            __unsafe_unretained RLMSchema *const schema,
                                            bool validateNested,
                                            bool allowMissing);

static void RLMValidateNestedObject(__unsafe_unretained id const obj,
                                    __unsafe_unretained NSString *const className,
                                    __unsafe_unretained RLMSchema *const schema,
                                    bool validateNested,
                                    bool allowMissing) {
    if (obj != nil && obj != NSNull.null) {
        if (RLMObjectBase *objBase = RLMDynamicCast<RLMObjectBase>(obj)) {
            RLMObjectSchema *objectSchema = objBase->_objectSchema;
            if (![className isEqualToString:objectSchema.className]) {
                // if not the right object class treat as literal
                RLMValidateValueForObjectSchema(objBase, schema[className], schema, validateNested, allowMissing);
            }
            if (objBase.isInvalidated) {
                @throw RLMException(@"Adding a deleted or invalidated object to a Realm is not permitted");
            }
        }
        else {
            RLMValidateValueForObjectSchema(obj, schema[className], schema, validateNested, allowMissing);
        }
    }
}

static void RLMValidateValueForProperty(__unsafe_unretained id const obj,
                                        __unsafe_unretained RLMProperty *const prop,
                                        __unsafe_unretained RLMSchema *const schema,
                                        bool validateNested,
                                        bool allowMissing) {
    switch (prop.type) {
        case RLMPropertyTypeString:
        case RLMPropertyTypeBool:
        case RLMPropertyTypeDate:
        case RLMPropertyTypeInt:
        case RLMPropertyTypeFloat:
        case RLMPropertyTypeDouble:
        case RLMPropertyTypeData:
        case RLMPropertyTypeAny:
            if (!RLMIsObjectValidForProperty(obj, prop)) {
                @throw RLMException(@"Invalid value '%@' for property '%@'", obj, prop.name);
            }
            break;
        case RLMPropertyTypeObject:
            if (validateNested) {
                RLMValidateNestedObject(obj, prop.objectClassName, schema, validateNested, allowMissing);
            }
            break;
        case RLMPropertyTypeArray: {
            if (obj != nil && obj != NSNull.null) {
                if (![obj conformsToProtocol:@protocol(NSFastEnumeration)]) {
                    @throw  RLMException(@"Array property value (%@) is not enumerable.", obj);
                }
                if (validateNested) {
                    id<NSFastEnumeration> array = obj;
                    for (id el in array) {
                        RLMValidateNestedObject(el, prop.objectClassName, schema, validateNested, allowMissing);
                    }
                }
            }
            break;
        }
        case RLMPropertyTypeLinkingObjects:
            @throw RLMException(@"Invalid value '%@' for property '%@'", obj, prop.name);
    }
}

static void RLMValidateValueForObjectSchema(__unsafe_unretained id const value,
                                            __unsafe_unretained RLMObjectSchema *const objectSchema,
                                            __unsafe_unretained RLMSchema *const schema,
                                            bool validateNested,
                                            bool allowMissing) {
    NSArray *props = objectSchema.properties;
    if (NSArray *array = RLMDynamicCast<NSArray>(value)) {
        if (array.count != props.count) {
            @throw RLMException(@"Invalid array input. Number of array elements does not match number of properties.");
        }
        for (NSUInteger i = 0; i < array.count; i++) {
            RLMProperty *prop = props[i];
            RLMValidateValueForProperty(array[i], prop, schema, validateNested, allowMissing);
        }
    }
    else {
        NSDictionary *defaults;
        for (RLMProperty *prop in props) {
            id obj = [value valueForKey:prop.name];

            // get default for nil object
            if (!obj) {
                if (!defaults) {
                    defaults = RLMDefaultValuesForObjectSchema(objectSchema);
                }
                obj = defaults[prop.name];
            }
            if (obj || prop.isPrimary || !allowMissing) {
                RLMValidateValueForProperty(obj, prop, schema, true, allowMissing);
            }
        }
    }
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
    RLMSchema *schema = realm.schema;
    RLMObjectSchema *objectSchema = [realm.schema schemaForClassName:className];
    if (!objectSchema) {
        @throw RLMException(@"Object type '%@' is not persisted in the Realm. "
                             @"If using a custom `objectClasses` / `objectTypes` array in your configuration, "
                             @"add `%@` to the list of `objectClasses` / `objectTypes`.",
                             className, className);
    }
    RLMObjectBase *object = [[objectSchema.accessorClass alloc] initWithRealm:realm schema:objectSchema];

    RLMCreationOptions creationOptions = createOrUpdate ? RLMCreationOptionsCreateOrUpdate : RLMCreationOptionsNone;

    // create row, and populate
    if (NSArray *array = RLMDynamicCast<NSArray>(value)) {
        // get or create our accessor
        bool created;
        auto primaryGetter = [=](__unsafe_unretained RLMProperty *const p) { return array[p.column]; };
        object->_row = (*objectSchema.table)[RLMCreateOrGetRowForObject(objectSchema, primaryGetter, createOrUpdate, created)];

        // populate
        NSArray *props = objectSchema.propertiesInDeclaredOrder;
        for (NSUInteger i = 0; i < array.count; i++) {
            RLMProperty *prop = props[i];
            // skip primary key when updating since it doesn't change
            if (created || !prop.isPrimary) {
                id val = array[i];
                RLMValidateValueForProperty(val, prop, schema, false, false);
                RLMDynamicSet(object, prop, RLMCoerceToNil(val), creationOptions);
            }
        }
    }
    else {
        // get or create our accessor
        bool created;
        auto primaryGetter = [=](RLMProperty *p) { return [value valueForKey:p.name]; };
        object->_row = (*objectSchema.table)[RLMCreateOrGetRowForObject(objectSchema, primaryGetter, createOrUpdate, created)];

        // populate
        NSDictionary *defaultValues = nil;
        for (RLMProperty *prop in objectSchema.properties) {
            id propValue = RLMValidatedValueForProperty(value, prop.name, objectSchema.className);

            if (!propValue && created) {
                if (!defaultValues) {
                    defaultValues = RLMDefaultValuesForObjectSchema(objectSchema);
                }
                propValue = defaultValues[prop.name];
                if (!propValue && (prop.type == RLMPropertyTypeObject || prop.type == RLMPropertyTypeArray)) {
                    propValue = NSNull.null;
                }
            }

            if (propValue) {
                if (created || !prop.isPrimary) {
                    // skip missing properties and primary key when updating since it doesn't change
                    RLMValidateValueForProperty(propValue, prop, schema, false, false);
                    RLMDynamicSet(object, prop, RLMCoerceToNil(propValue), creationOptions);
                }
            }
            else if (created && !prop.optional) {
                @throw RLMException(@"Property '%@' of object of type '%@' cannot be nil.", prop.name, objectSchema.className);
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
    for (RLMObjectSchema *objectSchema in realm.schema.objectSchema) {
        RLMClearTable(objectSchema);
    }
}

RLMResults *RLMGetObjects(RLMRealm *realm, NSString *objectClassName, NSPredicate *predicate) {
    RLMVerifyRealmRead(realm);

    // create view from table and predicate
    RLMObjectSchema *objectSchema = realm.schema[objectClassName];
    if (!objectSchema.table) {
        // read-only realms may be missing tables since we can't add any
        // missing ones on init
        return [RLMResults resultsWithObjectSchema:objectSchema results:{}];
    }

    if (predicate) {
        realm::Query query = objectSchema.table->where();
        RLMUpdateQueryWithPredicate(&query, predicate, realm.schema, objectSchema);

        // create and populate array
        return [RLMResults resultsWithObjectSchema:objectSchema
                                           results:realm::Results(realm->_realm, std::move(query))];
    }

    return [RLMResults resultsWithObjectSchema:objectSchema
                                       results:realm::Results(realm->_realm, *objectSchema.table)];
}

id RLMGetObject(RLMRealm *realm, NSString *objectClassName, id key) {
    RLMVerifyRealmRead(realm);

    RLMObjectSchema *objectSchema = realm.schema[objectClassName];

    RLMProperty *primaryProperty = objectSchema.primaryKeyProperty;
    if (!primaryProperty) {
        @throw RLMException(@"%@ does not have a primary key", objectClassName);
    }

    if (!objectSchema.table) {
        // read-only realms may be missing tables since we can't add any
        // missing ones on init
        return nil;
    }

    key = RLMCoerceToNil(key);

    size_t row = realm::not_found;
    if (primaryProperty.type == RLMPropertyTypeString) {
        NSString *str = RLMDynamicCast<NSString>(key);
        if (str || (!key && primaryProperty.optional)) {
            row = objectSchema.table->find_first_string(primaryProperty.column, RLMStringDataWithNSString(str));
        }
        else {
            @throw RLMException(@"Invalid value '%@' for primary key", key);
        }
    }
    else {
        NSNumber *number = RLMDynamicCast<NSNumber>(key);
        if (number) {
            row = objectSchema.table->find_first_int(primaryProperty.column, number.longLongValue);
        }
        else if (!key && primaryProperty.optional) {
            row = objectSchema.table->find_first_null(primaryProperty.column);
        }
        else {
            @throw RLMException(@"Invalid value '%@' for primary key", key);
        }
    }

    if (row == realm::not_found) {
        return nil;
    }

    return RLMCreateObjectAccessor(realm, objectSchema, row);
}

RLMObjectBase *RLMCreateObjectAccessor(__unsafe_unretained RLMRealm *const realm,
                                       __unsafe_unretained RLMObjectSchema *const objectSchema,
                                       NSUInteger index) {
    return RLMCreateObjectAccessor(realm, objectSchema, (*objectSchema.table)[index]);
}

// Create accessor and register with realm
RLMObjectBase *RLMCreateObjectAccessor(__unsafe_unretained RLMRealm *const realm,
                                       __unsafe_unretained RLMObjectSchema *const objectSchema,
                                       realm::RowExpr row) {
    RLMObjectBase *accessor = [[objectSchema.accessorClass alloc] initWithRealm:realm schema:objectSchema];
    accessor->_row = row;
    RLMInitializeSwiftAccessorGenerics(accessor);
    return accessor;
}
