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

#import "RLMAccessor.h"

#import "RLMArray_Private.hpp"
#import "RLMListBase.h"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMObservation.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMResults_Private.h"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"
#import "results.hpp"
#import "property.hpp"

#import <objc/runtime.h>
#import <realm/descriptor.hpp>

template<typename T>
static inline T get(__unsafe_unretained RLMObjectBase *const obj, NSUInteger index) {
    RLMVerifyAttached(obj);
    return obj->_row.get_table()->get<T>(obj->_info->objectSchema->persisted_properties[index].table_column,
                                         obj->_row.get_index());
}

template<typename T>
static NSNumber *getBoxed(__unsafe_unretained RLMObjectBase *const obj, NSUInteger index) {
    RLMVerifyAttached(obj);
    auto col = obj->_info->objectSchema->persisted_properties[index].table_column;
    if (obj->_row.is_null(col)) {
        return nil;
    }
    return @(obj->_row.get_table()->get<T>(col, obj->_row.get_index()));
}

// long getter/setter
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, long long val, bool setDefault) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.get_table()->set_int(colIndex, obj->_row.get_index(), val, setDefault);
}

// float getter/setter
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, float val, bool setDefault) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.get_table()->set_float(colIndex, obj->_row.get_index(), val, setDefault);
}

// double getter/setter
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, double val, bool setDefault) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.get_table()->set_double(colIndex, obj->_row.get_index(), val, setDefault);
}

// bool getter/setter
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, BOOL val, bool setDefault) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.get_table()->set_bool(colIndex, obj->_row.get_index(), val, setDefault);
}

// string getter/setter
static inline NSString *RLMGetString(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    return RLMStringDataToNSString(get<realm::StringData>(obj, colIndex));
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, __unsafe_unretained NSString *const val, bool setDefault) {
    RLMVerifyInWriteTransaction(obj);
    try {
        obj->_row.get_table()->set_string(colIndex, obj->_row.get_index(), RLMStringDataWithNSString(val), setDefault);
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
}

static inline void setNull(realm::Table& table, size_t colIndex, size_t rowIndex, bool setDefault) {
    try {
        table.set_null(colIndex, rowIndex, setDefault);
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
}

// date getter/setter
static inline NSDate *RLMGetDate(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    return RLMTimestampToNSDate(get<realm::Timestamp>(obj, colIndex));
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained NSDate *const date, bool setDefault) {
    RLMVerifyInWriteTransaction(obj);
    if (date) {
        obj->_row.get_table()->set_timestamp(colIndex, obj->_row.get_index(), RLMTimestampForNSDate(date), setDefault);
    }
    else {
        setNull(*obj->_row.get_table(), colIndex, obj->_row.get_index(), setDefault);
    }
}

// data getter/setter
static inline NSData *RLMGetData(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    return RLMBinaryDataToNSData(get<realm::BinaryData>(obj, colIndex));
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, __unsafe_unretained NSData *const data, bool setDefault) {
    RLMVerifyInWriteTransaction(obj);

    try {
        obj->_row.get_table()->set_binary(colIndex, obj->_row.get_index(), RLMBinaryDataForNSData(data), setDefault);
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
}

static inline RLMObjectBase *RLMGetLinkedObjectForValue(__unsafe_unretained RLMRealm *const realm,
                                                        __unsafe_unretained NSString *const className,
                                                        __unsafe_unretained id const value,
                                                        RLMCreationOptions creationOptions) NS_RETURNS_RETAINED;
static inline RLMObjectBase *RLMGetLinkedObjectForValue(__unsafe_unretained RLMRealm *const realm,
                                                        __unsafe_unretained NSString *const className,
                                                        __unsafe_unretained id const value,
                                                        RLMCreationOptions creationOptions) {
    RLMObjectBase *link = RLMDynamicCast<RLMObjectBase>(value);
    if (!link || ![link->_objectSchema.className isEqualToString:className]) {
        // create from non-rlmobject
        return RLMCreateObjectInRealmWithValue(realm, className, value, creationOptions & RLMCreationOptionsCreateOrUpdate);
    }

    if (link.isInvalidated) {
        @throw RLMException(@"Adding a deleted or invalidated object to a Realm is not permitted");
    }

    if (link->_realm == realm) {
        return link;
    }

    if (creationOptions & RLMCreationOptionsPromoteUnmanaged) {
        if (!link->_realm) {
            RLMAddObjectToRealm(link, realm, creationOptions & RLMCreationOptionsCreateOrUpdate);
            return link;
        }
        @throw RLMException(@"Can not add objects from a different Realm");
    }

    // copy from another realm or copy from unmanaged
    return RLMCreateObjectInRealmWithValue(realm, className, link, creationOptions & RLMCreationOptionsCreateOrUpdate);
}

// link getter/setter
static inline RLMObjectBase *RLMGetLink(__unsafe_unretained RLMObjectBase *const obj, NSUInteger propertyIndex) {
    RLMVerifyAttached(obj);
    auto colIndex = obj->_info->objectSchema->persisted_properties[propertyIndex].table_column;

    if (obj->_row.is_null_link(colIndex)) {
        return nil;
    }
    NSUInteger index = obj->_row.get_link(colIndex);
    return RLMCreateObjectAccessor(obj->_realm, obj->_info->linkTargetType(propertyIndex), index);
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained RLMObjectBase *const val, bool setDefault) {
    RLMVerifyInWriteTransaction(obj);
    if (!val) {
        obj->_row.nullify_link(colIndex);
        return;
    }

    RLMObjectBase *link = RLMGetLinkedObjectForValue(obj->_realm, val->_objectSchema.className,
                                                     val, RLMCreationOptionsPromoteUnmanaged);

    // make sure it is the correct type
    if (link->_row.get_table() != obj->_row.get_table()->get_link_target(colIndex)) {
        @throw RLMException(@"Can't set object of type '%@' to property of type '%@'",
                            val->_objectSchema.className,
                            obj->_info->propertyForTableColumn(colIndex).objectClassName);
    }
    obj->_row.get_table()->set_link(colIndex, obj->_row.get_index(), link->_row.get_index(), setDefault);
}

// array getter/setter
static inline RLMArray *RLMGetArray(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    auto prop = obj->_info->rlmObjectSchema.properties[colIndex];
    return [[RLMArrayLinkView alloc] initWithParent:obj property:prop];
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained id<NSFastEnumeration> const array, __unused bool setDefault) {
    RLMVerifyInWriteTransaction(obj);

    realm::LinkViewRef linkView = obj->_row.get_linklist(colIndex);
    // remove all old
    // FIXME: make sure delete rules don't purge objects
    linkView->clear();
    for (RLMObjectBase *link in array) {
        RLMObjectBase * addedLink = RLMGetLinkedObjectForValue(obj->_realm, link->_objectSchema.className, link, RLMCreationOptionsPromoteUnmanaged);
        linkView->add(addedLink->_row.get_index());
    }
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained NSNumber<RLMInt> *const intObject, bool setDefault) {
    RLMVerifyInWriteTransaction(obj);

    if (intObject) {
        obj->_row.get_table()->set_int(colIndex, obj->_row.get_index(), intObject.longLongValue, setDefault);
    }
    else {
        setNull(*obj->_row.get_table(), colIndex, obj->_row.get_index(), setDefault);
    }
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained NSNumber<RLMFloat> *const floatObject, bool setDefault) {
    RLMVerifyInWriteTransaction(obj);

    if (floatObject) {
        obj->_row.get_table()->set_float(colIndex, obj->_row.get_index(), floatObject.floatValue, setDefault);
    }
    else {
        setNull(*obj->_row.get_table(), colIndex, obj->_row.get_index(), setDefault);
    }
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained NSNumber<RLMDouble> *const doubleObject, bool setDefault) {
    RLMVerifyInWriteTransaction(obj);

    if (doubleObject) {
        obj->_row.get_table()->set_double(colIndex, obj->_row.get_index(), doubleObject.doubleValue, setDefault);
    }
    else {
        setNull(*obj->_row.get_table(), colIndex, obj->_row.get_index(), setDefault);
    }
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained NSNumber<RLMBool> *const boolObject, bool setDefault) {
    RLMVerifyInWriteTransaction(obj);

    if (boolObject) {
        obj->_row.get_table()->set_bool(colIndex, obj->_row.get_index(), boolObject.boolValue, setDefault);
    }
    else {
        setNull(*obj->_row.get_table(), colIndex, obj->_row.get_index(), setDefault);
    }
}

static inline RLMLinkingObjects *RLMGetLinkingObjects(__unsafe_unretained RLMObjectBase *const obj,
                                                      __unsafe_unretained RLMProperty *const property) {
    auto& objectInfo = obj->_realm->_info[property.objectClassName];
    auto linkingProperty = objectInfo.objectSchema->property_for_name(property.linkOriginPropertyName.UTF8String);
    auto backlinkView = obj->_row.get_table()->get_backlink_view(obj->_row.get_index(), objectInfo.table(), linkingProperty->table_column);
    realm::Results results(obj->_realm->_realm, std::move(backlinkView));
    return [RLMLinkingObjects resultsWithObjectInfo:objectInfo results:std::move(results)];
}

// any getter/setter
static inline id RLMGetAnyProperty(__unsafe_unretained RLMObjectBase *const obj, NSUInteger col_ndx) {
    RLMVerifyAttached(obj);
    return RLMMixedToObjc(obj->_row.get_mixed(col_ndx));
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger, __unsafe_unretained id, bool) {
    RLMVerifyInWriteTransaction(obj);
    @throw RLMException(@"Modifying Mixed properties is not supported");
}

// dynamic getter with column closure
static id RLMAccessorGetter(RLMProperty *prop, const char *type) {
    NSUInteger index = prop.index;
    bool boxed = prop.optional || *type == '@';
    switch (prop.type) {
        case RLMPropertyTypeInt:
            if (boxed) {
                return ^(__unsafe_unretained RLMObjectBase *const obj) {
                    return getBoxed<long long>(obj, index);
                };
            }
            switch (*type) {
                case 'c':
                    return ^(__unsafe_unretained RLMObjectBase *const obj) {
                        return static_cast<char>(get<int64_t>(obj, index));
                    };
                case 's':
                    return ^(__unsafe_unretained RLMObjectBase *const obj) {
                        return static_cast<short>(get<int64_t>(obj, index));
                    };
                case 'i':
                    return ^(__unsafe_unretained RLMObjectBase *const obj) {
                        return static_cast<int>(get<int64_t>(obj, index));
                    };
                case 'l':
                    return ^(__unsafe_unretained RLMObjectBase *const obj) {
                        return static_cast<long>(get<int64_t>(obj, index));
                    };
                case 'q':
                    return ^(__unsafe_unretained RLMObjectBase *const obj) {
                        return static_cast<long long>(get<int64_t>(obj, index));
                    };
                default:
                    @throw RLMException(@"Unexpected property type for Objective-C type code");
            }
        case RLMPropertyTypeFloat:
            if (boxed) {
                return ^(__unsafe_unretained RLMObjectBase *const obj) {
                    return getBoxed<float>(obj, index);
                };
            }
            return ^(__unsafe_unretained RLMObjectBase *const obj) {
                return get<float>(obj, index);
            };
        case RLMPropertyTypeDouble:
            if (boxed) {
                return ^(__unsafe_unretained RLMObjectBase *const obj) {
                    return getBoxed<double>(obj, index);
                };
            }
            return ^(__unsafe_unretained RLMObjectBase *const obj) {
                return get<double>(obj, index);
            };
        case RLMPropertyTypeBool:
            if (boxed) {
                return ^(__unsafe_unretained RLMObjectBase *const obj) {
                    return getBoxed<bool>(obj, index);
                };
            }
            return ^(__unsafe_unretained RLMObjectBase *const obj) {
                return get<bool>(obj, index);
            };
        case RLMPropertyTypeString:
            return ^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetString(obj, index);
            };
        case RLMPropertyTypeDate:
            return ^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetDate(obj, index);
            };
        case RLMPropertyTypeData:
            return ^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetData(obj, index);
            };
        case RLMPropertyTypeObject:
            return ^id(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetLink(obj, index);
            };
        case RLMPropertyTypeArray:
            return ^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetArray(obj, index);
            };
        case RLMPropertyTypeAny:
            @throw RLMException(@"Cannot create accessor class for schema with Mixed properties");
        case RLMPropertyTypeLinkingObjects:
            return ^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetLinkingObjects(obj, prop);
            };
    }
}

template<typename Function>
static void RLMWrapSetter(__unsafe_unretained RLMObjectBase *const obj, __unsafe_unretained NSString *const name, Function&& f) {
    if (RLMObservationInfo *info = RLMGetObservationInfo(obj->_observationInfo, obj->_row.get_index(), *obj->_info)) {
        info->willChange(name);
        f();
        info->didChange(name);
    }
    else {
        f();
    }
}

template<typename ArgType, typename StorageType=ArgType>
static id makeSetter(__unsafe_unretained RLMProperty *const prop) {
    NSUInteger index = prop.index;
    NSString *name = prop.name;
    if (prop.isPrimary) {
        return ^(__unused RLMObjectBase *obj, __unused ArgType val) {
            @throw RLMException(@"Primary key can't be changed after an object is inserted.");
        };
    }
    return ^(__unsafe_unretained RLMObjectBase *const obj, ArgType val) {
        RLMWrapSetter(obj, name, [&] {
            RLMSetValue(obj, obj->_info->objectSchema->persisted_properties[index].table_column,
                        static_cast<StorageType>(val), false);
        });
    };
}

// dynamic setter with column closure
static id RLMAccessorSetter(RLMProperty *prop, const char *type) {
    bool boxed = prop.optional || *type == '@';
    switch (prop.type) {
        case RLMPropertyTypeInt:
            if (boxed) {
                return makeSetter<NSNumber<RLMInt> *>(prop);
            }
            switch (*type) {
                case 'c': return makeSetter<char, long long>(prop);
                case 's': return makeSetter<short, long long>(prop);
                case 'i': return makeSetter<int, long long>(prop);
                case 'l': return makeSetter<long, long long>(prop);
                case 'q': return makeSetter<long long>(prop);
                default:
                    @throw RLMException(@"Unexpected property type for Objective-C type code");
            }
        case RLMPropertyTypeFloat:
            return boxed ? makeSetter<NSNumber<RLMFloat> *>(prop) : makeSetter<float>(prop);
        case RLMPropertyTypeDouble:
            return boxed ? makeSetter<NSNumber<RLMDouble> *>(prop) : makeSetter<double>(prop);
        case RLMPropertyTypeBool:
            return boxed ? makeSetter<NSNumber<RLMBool> *>(prop) : makeSetter<BOOL>(prop);
        case RLMPropertyTypeString:         return makeSetter<NSString *>(prop);
        case RLMPropertyTypeDate:           return makeSetter<NSDate *>(prop);
        case RLMPropertyTypeData:           return makeSetter<NSData *>(prop);
        case RLMPropertyTypeObject:         return makeSetter<RLMObjectBase *>(prop);
        case RLMPropertyTypeArray:          return makeSetter<RLMArray *>(prop);
        case RLMPropertyTypeAny:            return makeSetter<id>(prop);
        case RLMPropertyTypeLinkingObjects: return nil;
    }
}

// call getter for superclass for property at colIndex
static id RLMSuperGet(RLMObjectBase *obj, NSString *propName) {
    typedef id (*getter_type)(RLMObjectBase *, SEL);
    RLMProperty *prop = obj->_objectSchema[propName];
    Class superClass = class_getSuperclass(obj.class);
    getter_type superGetter = (getter_type)[superClass instanceMethodForSelector:prop.getterSel];
    return superGetter(obj, prop.getterSel);
}

// call setter for superclass for property at colIndex
static void RLMSuperSet(RLMObjectBase *obj, NSString *propName, id val) {
    typedef void (*setter_type)(RLMObjectBase *, SEL, RLMArray *ar);
    RLMProperty *prop = obj->_objectSchema[propName];
    Class superClass = class_getSuperclass(obj.class);
    setter_type superSetter = (setter_type)[superClass instanceMethodForSelector:prop.setterSel];
    superSetter(obj, prop.setterSel, val);
}

// getter/setter for unmanaged object
static id RLMAccessorUnmanagedGetter(RLMProperty *prop, const char *) {
    // only override getters for RLMArray and linking objects properties
    if (prop.type == RLMPropertyTypeArray) {
        NSString *objectClassName = prop.objectClassName;
        NSString *propName = prop.name;

        return ^(RLMObjectBase *obj) {
            id val = RLMSuperGet(obj, propName);
            if (!val) {
                val = [[RLMArray alloc] initWithObjectClassName:objectClassName];
                RLMSuperSet(obj, propName, val);
            }
            return val;
        };
    }
    else if (prop.type == RLMPropertyTypeLinkingObjects) {
        return ^(RLMObjectBase *){
            return [RLMResults emptyDetachedResults];
        };
    }
    return nil;
}
static id RLMAccessorUnmanagedSetter(RLMProperty *prop, const char *) {
    if (prop.type != RLMPropertyTypeArray) {
        return nil;
    }

    NSString *propName = prop.name;
    NSString *objectClassName = prop.objectClassName;
    return ^(RLMObjectBase *obj, id<NSFastEnumeration> ar) {
        // make copy when setting (as is the case for all other variants)
        RLMArray *standaloneAr = [[RLMArray alloc] initWithObjectClassName:objectClassName];
        [standaloneAr addObjects:ar];
        RLMSuperSet(obj, propName, standaloneAr);
    };
}

// implement the class method className on accessors to return the className of the
// base object
void RLMReplaceClassNameMethod(Class accessorClass, NSString *className) {
    Class metaClass = object_getClass(accessorClass);
    IMP imp = imp_implementationWithBlock(^(Class){ return className; });
    class_addMethod(metaClass, @selector(className), imp, "@@:");
}

// implement the shared schema method
void RLMReplaceSharedSchemaMethod(Class accessorClass, RLMObjectSchema *schema) {
    Class metaClass = object_getClass(accessorClass);
    IMP imp = imp_implementationWithBlock(^(Class cls) {
        if (cls == accessorClass) {
            return schema;
        }

        // If we aren't being called directly on the class this was overriden
        // for, the class is either a subclass which we haven't initialized yet,
        // or it's a runtime-generated class which should use the parent's
        // schema. We check for the latter by checking if the immediate
        // descendent of the desired class is a class generated by us (there
        // may be further subclasses not generated by us for things like KVO).
        Class parent = class_getSuperclass(cls);
        while (parent != accessorClass) {
            cls = parent;
            parent = class_getSuperclass(cls);
        }

        static const char accessorClassPrefix[] = "RLM:";
        if (!strncmp(class_getName(cls), accessorClassPrefix, sizeof(accessorClassPrefix) - 1)) {
            return schema;
        }

        return [RLMSchema sharedSchemaForClass:cls];
    });
    class_addMethod(metaClass, @selector(sharedSchema), imp, "@@:");
}

static void addMethod(Class cls, __unsafe_unretained RLMProperty *const prop,
                      id (*getter)(RLMProperty *, const char *),
                      id (*setter)(RLMProperty *, const char *)) {
    SEL sel = prop.getterSel;
    auto getterMethod = class_getInstanceMethod(cls, sel);
    if (!getterMethod) {
        return;
    }

    const char *getterType = method_getTypeEncoding(getterMethod);
    if (id block = getter(prop, getterType)) {
        class_addMethod(cls, sel, imp_implementationWithBlock(block), getterType);
    }

    if (!(sel = prop.setterSel)) {
        return;
    }
    auto setterMethod = class_getInstanceMethod(cls, sel);
    if (!setterMethod) {
        return;
    }
    if (id block = setter(prop, getterType)) { // note: deliberately getterType as it's easier to grab the relevant type from
        class_addMethod(cls, sel, imp_implementationWithBlock(block), method_getTypeEncoding(setterMethod));
    }
}

static Class RLMCreateAccessorClass(Class objectClass,
                                    RLMObjectSchema *schema,
                                    const char *accessorClassName,
                                    id (*getterGetter)(RLMProperty *, const char *),
                                    id (*setterGetter)(RLMProperty *, const char *)) {
    REALM_ASSERT_DEBUG(RLMIsObjectOrSubclass(objectClass));

    // create and register proxy class which derives from object class
    Class accClass = objc_allocateClassPair(objectClass, accessorClassName, 0);
    if (!accClass) {
        // Class with that name already exists, so just return the pre-existing one
        // This should only happen for our standalone "accessors"
        return objc_lookUpClass(accessorClassName);
    }

    // override getters/setters for each propery
    for (RLMProperty *prop in schema.properties) {
        addMethod(accClass, prop, getterGetter, setterGetter);
    }
    for (RLMProperty *prop in schema.computedProperties) {
        addMethod(accClass, prop, getterGetter, setterGetter);
    }

    objc_registerClassPair(accClass);

    return accClass;
}

Class RLMManagedAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema, const char *name) {
    return RLMCreateAccessorClass(objectClass, schema, name, RLMAccessorGetter, RLMAccessorSetter);
}

Class RLMUnmanagedAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema) {
    return RLMCreateAccessorClass(objectClass, schema, [@"RLM:Unmanaged " stringByAppendingString:schema.className].UTF8String,
                                  RLMAccessorUnmanagedGetter, RLMAccessorUnmanagedSetter);
}

void RLMDynamicValidatedSet(RLMObjectBase *obj, NSString *propName, id val) {
    RLMObjectSchema *schema = obj->_objectSchema;
    RLMProperty *prop = schema[propName];
    if (!prop) {
        @throw RLMException(@"Invalid property name '%@' for class '%@'.",
                            propName, obj->_objectSchema.className);
    }
    if (prop.isPrimary) {
        @throw RLMException(@"Primary key can't be changed to '%@' after an object is inserted.", val);
    }
    if (!RLMIsObjectValidForProperty(val, prop)) {
        @throw RLMException(@"Invalid property value '%@' for property '%@' of class '%@'",
                            val, propName, obj->_objectSchema.className);
    }

    RLMDynamicSet(obj, prop, RLMCoerceToNil(val), RLMCreationOptionsPromoteUnmanaged);
}

// Precondition: the property is not a primary key
void RLMDynamicSet(__unsafe_unretained RLMObjectBase *const obj, __unsafe_unretained RLMProperty *const prop,
                   __unsafe_unretained id const val, RLMCreationOptions creationOptions) {
    REALM_ASSERT_DEBUG(!prop.isPrimary);
    bool setDefault = creationOptions & RLMCreationOptionsSetDefault;

    auto col = obj->_info->tableColumn(prop);
    RLMWrapSetter(obj, prop.name, [&] {
        switch (prop.type) {
            case RLMPropertyTypeInt:    RLMSetValue(obj, col, (NSNumber<RLMInt> *)val, setDefault); break;
            case RLMPropertyTypeFloat:  RLMSetValue(obj, col, (NSNumber<RLMFloat> *)val, setDefault); break;
            case RLMPropertyTypeDouble: RLMSetValue(obj, col, (NSNumber<RLMDouble> *)val, setDefault); break;
            case RLMPropertyTypeBool:   RLMSetValue(obj, col, (NSNumber<RLMBool> *)val, setDefault); break;
            case RLMPropertyTypeString: RLMSetValue(obj, col, (NSString *)val, setDefault); break;
            case RLMPropertyTypeDate:   RLMSetValue(obj, col, (NSDate *)val, setDefault); break;
            case RLMPropertyTypeData:   RLMSetValue(obj, col, (NSData *)val, setDefault); break;
            case RLMPropertyTypeObject: {
                if (!val || val == NSNull.null) {
                    RLMSetValue(obj, col, (RLMObjectBase *)nil, setDefault);
                }
                else {
                    auto linkedObj = RLMGetLinkedObjectForValue(obj->_realm, prop.objectClassName, val, creationOptions);
                    RLMSetValue(obj, col, linkedObj, setDefault);
                }
                break;
            }
            case RLMPropertyTypeArray:
                if (!val || val == NSNull.null) {
                    RLMSetValue(obj, col, (id<NSFastEnumeration>)nil, setDefault);
                }
                else {
                    id<NSFastEnumeration> rawLinks = val;
                    NSMutableArray *links = [NSMutableArray array];
                    for (id rawLink in rawLinks) {
                        [links addObject:RLMGetLinkedObjectForValue(obj->_realm, prop.objectClassName, rawLink, creationOptions)];
                    }
                    RLMSetValue(obj, col, links, setDefault);
                }
                break;
            case RLMPropertyTypeAny:
                RLMSetValue(obj, col, val, setDefault);
                break;
            case RLMPropertyTypeLinkingObjects:
                @throw RLMException(@"Linking objects properties are read-only");
        }
    });
}

id RLMDynamicGet(__unsafe_unretained RLMObjectBase *const obj, __unsafe_unretained RLMProperty *const prop) {
    NSUInteger index = prop.index;
    switch (prop.type) {
        case RLMPropertyTypeInt:            return getBoxed<long long>(obj, index);
        case RLMPropertyTypeFloat:          return getBoxed<float>(obj, index);
        case RLMPropertyTypeDouble:         return getBoxed<double>(obj, index);
        case RLMPropertyTypeBool:           return getBoxed<bool>(obj, index);
        case RLMPropertyTypeString:         return RLMGetString(obj, index);
        case RLMPropertyTypeDate:           return RLMGetDate(obj, index);
        case RLMPropertyTypeData:           return RLMGetData(obj, index);
        case RLMPropertyTypeObject:         return RLMGetLink(obj, index);
        case RLMPropertyTypeArray:          return RLMGetArray(obj, index);
        case RLMPropertyTypeAny:            return RLMGetAnyProperty(obj, index);
        case RLMPropertyTypeLinkingObjects: return RLMGetLinkingObjects(obj, prop);
    }
}

id RLMDynamicGetByName(__unsafe_unretained RLMObjectBase *const obj, __unsafe_unretained NSString *const propName, bool asList) {
    RLMProperty *prop = obj->_objectSchema[propName];
    if (!prop) {
        @throw RLMException(@"Invalid property name '%@' for class '%@'.", propName, obj->_objectSchema.className);
    }
    if (asList && prop.type == RLMPropertyTypeArray && prop.swiftIvar) {
        RLMListBase *list = object_getIvar(obj, prop.swiftIvar);
        if (!list._rlmArray) {
            list._rlmArray = RLMDynamicGet(obj, prop);
        }
        return list;
    }

    return RLMDynamicGet(obj, prop);
}
