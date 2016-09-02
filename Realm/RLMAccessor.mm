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

typedef NS_ENUM(char, RLMAccessorCode) {
    RLMAccessorCodeByte,
    RLMAccessorCodeShort,
    RLMAccessorCodeInt,
    RLMAccessorCodeLong,
    RLMAccessorCodeLongLong,
    RLMAccessorCodeFloat,
    RLMAccessorCodeDouble,
    RLMAccessorCodeBool,
    RLMAccessorCodeString,
    RLMAccessorCodeDate,
    RLMAccessorCodeData,
    RLMAccessorCodeLink,
    RLMAccessorCodeArray,
    RLMAccessorCodeLinkingObjects,
    RLMAccessorCodeAny,

    RLMAccessorCodeIntObject,
    RLMAccessorCodeFloatObject,
    RLMAccessorCodeDoubleObject,
    RLMAccessorCodeBoolObject,
};

template<typename T>
static T get(__unsafe_unretained RLMObjectBase *const obj, NSUInteger index) {
    RLMVerifyAttached(obj);
    return obj->_row.get_table()->get<T>(obj->_info->objectSchema->persisted_properties[index].table_column, obj->_row.get_index());
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
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, long long val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_int(colIndex, val);
}

// float getter/setter
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, float val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_float(colIndex, val);
}

// double getter/setter
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, double val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_double(colIndex, val);
}

// bool getter/setter
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, BOOL val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_bool(colIndex, val);
}

// string getter/setter
static inline NSString *RLMGetString(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    return RLMStringDataToNSString(get<realm::StringData>(obj, colIndex));
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, __unsafe_unretained NSString *const val) {
    RLMVerifyInWriteTransaction(obj);
    try {
        obj->_row.set_string(colIndex, RLMStringDataWithNSString(val));
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
}

// date getter/setter
static inline NSDate *RLMGetDate(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    return RLMTimestampToNSDate(get<realm::Timestamp>(obj, colIndex));
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, __unsafe_unretained NSDate *const date) {
    RLMVerifyInWriteTransaction(obj);
    if (date) {
        obj->_row.set_timestamp(colIndex, RLMTimestampForNSDate(date));
    }
    else {
        obj->_row.set_null(colIndex);
    }
}

// data getter/setter
static inline NSData *RLMGetData(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    return RLMBinaryDataToNSData(get<realm::BinaryData>(obj, colIndex));
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, __unsafe_unretained NSData *const data) {
    RLMVerifyInWriteTransaction(obj);

    try {
        obj->_row.set_binary(colIndex, RLMBinaryDataForNSData(data));
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
static inline RLMObjectBase *RLMGetLink(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    auto col = obj->_info->objectSchema->persisted_properties[colIndex].table_column;

    if (obj->_row.is_null_link(col)) {
        return nil;
    }
    NSUInteger index = obj->_row.get_link(col);
    return RLMCreateObjectAccessor(obj->_realm, obj->_info->linkTargetType(colIndex), index);
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained RLMObjectBase *const val) {
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
    obj->_row.set_link(colIndex, link->_row.get_index());
}

// array getter/setter
static inline RLMArray *RLMGetArray(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    auto prop = obj->_info->rlmObjectSchema.properties[colIndex];
    return [[RLMArrayLinkView alloc] initWithParent:obj property:prop];
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained id<NSFastEnumeration> const array) {
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
                               __unsafe_unretained NSNumber<RLMInt> *const intObject) {
    RLMVerifyInWriteTransaction(obj);

    if (intObject) {
        obj->_row.set_int(colIndex, intObject.longLongValue);
    }
    else {
        obj->_row.set_null(colIndex);
    }
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained NSNumber<RLMFloat> *const floatObject) {
    RLMVerifyInWriteTransaction(obj);

    if (floatObject) {
        obj->_row.set_float(colIndex, floatObject.floatValue);
    }
    else {
        obj->_row.set_null(colIndex);
    }
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained NSNumber<RLMDouble> *const doubleObject) {
    RLMVerifyInWriteTransaction(obj);

    if (doubleObject) {
        obj->_row.set_double(colIndex, doubleObject.doubleValue);
    }
    else {
        obj->_row.set_null(colIndex);
    }
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained NSNumber<RLMBool> *const boolObject) {
    RLMVerifyInWriteTransaction(obj);

    if (boolObject) {
        obj->_row.set_bool(colIndex, boolObject.boolValue);
    }
    else {
        obj->_row.set_null(colIndex);
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
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger, __unsafe_unretained id) {
    RLMVerifyInWriteTransaction(obj);
    @throw RLMException(@"Modifying Mixed properties is not supported");
}

// dynamic getter with column closure
static IMP RLMAccessorGetter(RLMProperty *prop, RLMAccessorCode accessorCode) {
    NSUInteger index = prop.index;
    switch (accessorCode) {
        case RLMAccessorCodeByte:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return (char)get<int64_t>(obj, index);
            });
        case RLMAccessorCodeShort:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return (short)get<int64_t>(obj, index);
            });
        case RLMAccessorCodeInt:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return (int)get<int64_t>(obj, index);
            });
        case RLMAccessorCodeLongLong:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return get<int64_t>(obj, index);
            });
        case RLMAccessorCodeLong:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return (long)get<int64_t>(obj, index);
            });
        case RLMAccessorCodeFloat:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return get<float>(obj, index);
            });
        case RLMAccessorCodeDouble:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return get<double>(obj, index);
            });
        case RLMAccessorCodeBool:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return get<bool>(obj, index);
            });
        case RLMAccessorCodeString:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetString(obj, index);
            });
        case RLMAccessorCodeDate:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetDate(obj, index);
            });
        case RLMAccessorCodeData:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetData(obj, index);
            });
        case RLMAccessorCodeLink:
            return imp_implementationWithBlock(^id(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetLink(obj, index);
            });
        case RLMAccessorCodeArray:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetArray(obj, index);
            });
        case RLMAccessorCodeAny:
            @throw RLMException(@"Cannot create accessor class for schema with Mixed properties");
        case RLMAccessorCodeIntObject:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return getBoxed<int64_t>(obj, index);
            });
        case RLMAccessorCodeFloatObject:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return getBoxed<float>(obj, index);
            });
        case RLMAccessorCodeDoubleObject:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return getBoxed<double>(obj, index);
            });
        case RLMAccessorCodeBoolObject:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return getBoxed<bool>(obj, index);
            });
        case RLMAccessorCodeLinkingObjects:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetLinkingObjects(obj, prop);
            });
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
static IMP RLMMakeSetter(RLMProperty *prop) {
    NSUInteger index = prop.index;
    NSString *name = prop.name;
    if (prop.isPrimary) {
        return imp_implementationWithBlock(^(__unused RLMObjectBase *obj, __unused ArgType val) {
            @throw RLMException(@"Primary key can't be changed after an object is inserted.");
        });
    }
    return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj, ArgType val) {
        RLMWrapSetter(obj, name, [&] {
            RLMSetValue(obj, obj->_info->objectSchema->persisted_properties[index].table_column, static_cast<StorageType>(val));
        });
    });
}

// dynamic setter with column closure
static IMP RLMAccessorSetter(RLMProperty *prop, RLMAccessorCode accessorCode) {
    switch (accessorCode) {
        case RLMAccessorCodeByte:         return RLMMakeSetter<char, long long>(prop);
        case RLMAccessorCodeShort:        return RLMMakeSetter<short, long long>(prop);
        case RLMAccessorCodeInt:          return RLMMakeSetter<int, long long>(prop);
        case RLMAccessorCodeLong:         return RLMMakeSetter<long, long long>(prop);
        case RLMAccessorCodeLongLong:     return RLMMakeSetter<long long>(prop);
        case RLMAccessorCodeFloat:        return RLMMakeSetter<float>(prop);
        case RLMAccessorCodeDouble:       return RLMMakeSetter<double>(prop);
        case RLMAccessorCodeBool:         return RLMMakeSetter<BOOL>(prop);
        case RLMAccessorCodeString:       return RLMMakeSetter<NSString *>(prop);
        case RLMAccessorCodeDate:         return RLMMakeSetter<NSDate *>(prop);
        case RLMAccessorCodeData:         return RLMMakeSetter<NSData *>(prop);
        case RLMAccessorCodeLink:         return RLMMakeSetter<RLMObjectBase *>(prop);
        case RLMAccessorCodeArray:        return RLMMakeSetter<RLMArray *>(prop);
        case RLMAccessorCodeAny:          return RLMMakeSetter<id>(prop);
        case RLMAccessorCodeIntObject:    return RLMMakeSetter<NSNumber<RLMInt> *>(prop);
        case RLMAccessorCodeFloatObject:  return RLMMakeSetter<NSNumber<RLMFloat> *>(prop);
        case RLMAccessorCodeDoubleObject: return RLMMakeSetter<NSNumber<RLMDouble> *>(prop);
        case RLMAccessorCodeBoolObject:   return RLMMakeSetter<NSNumber<RLMBool> *>(prop);
        case RLMAccessorCodeLinkingObjects: return nil;
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
static IMP RLMAccessorUnmanagedGetter(RLMProperty *prop, RLMAccessorCode accessorCode) {
    // only override getters for RLMArray and linking objects properties
    if (accessorCode == RLMAccessorCodeArray) {
        NSString *objectClassName = prop.objectClassName;
        NSString *propName = prop.name;

        return imp_implementationWithBlock(^(RLMObjectBase *obj) {
            id val = RLMSuperGet(obj, propName);
            if (!val) {
                val = [[RLMArray alloc] initWithObjectClassName:objectClassName];
                RLMSuperSet(obj, propName, val);
            }
            return val;
        });
    }
    else if (accessorCode == RLMAccessorCodeLinkingObjects) {
        return imp_implementationWithBlock(^(RLMObjectBase *){
            return [RLMResults emptyDetachedResults];
        });
    }
    return nil;
}
static IMP RLMAccessorUnmanagedSetter(RLMProperty *prop, RLMAccessorCode accessorCode) {
    // only override getters for RLMArray and linking objects properties
    if (accessorCode == RLMAccessorCodeArray) {
        NSString *propName = prop.name;
        NSString *objectClassName = prop.objectClassName;
        return imp_implementationWithBlock(^(RLMObjectBase *obj, id<NSFastEnumeration> ar) {
            // make copy when setting (as is the case for all other variants)
            RLMArray *unmanagedAr = [[RLMArray alloc] initWithObjectClassName:objectClassName];
            [unmanagedAr addObjects:ar];
            RLMSuperSet(obj, propName, unmanagedAr);
        });
    }
    return nil;
}

// macros/helpers to generate objc type strings for registering methods
#define GETTER_TYPES(C) C "@:"
#define SETTER_TYPES(C) "v@:" C

// getter type strings
// NOTE: this typecode is really the the first charachter of the objc/runtime.h type
//       the @ type maps to multiple core types (string, date, array, mixed, any which are id in objc)
static const char *getterTypeStringForObjcCode(char code) {
    switch (code) {
        case 's': return GETTER_TYPES("s");
        case 'i': return GETTER_TYPES("i");
        case 'l': return GETTER_TYPES("l");
        case 'q': return GETTER_TYPES("q");
        case 'f': return GETTER_TYPES("f");
        case 'd': return GETTER_TYPES("d");
        case 'B': return GETTER_TYPES("B");
        case 'c': return GETTER_TYPES("c");
        case '@': return GETTER_TYPES("@");
        default: @throw RLMException(@"Invalid accessor code");
    }
}

// setter type strings
// NOTE: this typecode is really the the first charachter of the objc/runtime.h type
//       the @ type maps to multiple core types (string, date, array, mixed, any which are id in objc)
static const char *setterTypeStringForObjcCode(char code) {
    switch (code) {
        case 's': return SETTER_TYPES("s");
        case 'i': return SETTER_TYPES("i");
        case 'l': return SETTER_TYPES("l");
        case 'q': return SETTER_TYPES("q");
        case 'f': return SETTER_TYPES("f");
        case 'd': return SETTER_TYPES("d");
        case 'B': return SETTER_TYPES("B");
        case 'c': return SETTER_TYPES("c");
        case '@': return SETTER_TYPES("@");
        default: @throw RLMException(@"Invalid accessor code");
    }
}

// get accessor lookup code based on objc type and rlm type
static RLMAccessorCode accessorCodeForType(char objcTypeCode, RLMPropertyType rlmType) {
    switch (objcTypeCode) {
        case 't': return RLMAccessorCodeArray;
        case '@':               // custom accessors for strings and subtables
            switch (rlmType) {  // custom accessor codes for types that map to objc objects
                case RLMPropertyTypeObject: return RLMAccessorCodeLink;
                case RLMPropertyTypeString: return RLMAccessorCodeString;
                case RLMPropertyTypeArray: return RLMAccessorCodeArray;
                case RLMPropertyTypeDate: return RLMAccessorCodeDate;
                case RLMPropertyTypeData: return RLMAccessorCodeData;
                case RLMPropertyTypeAny: return RLMAccessorCodeAny;

                case RLMPropertyTypeBool: return RLMAccessorCodeBoolObject;
                case RLMPropertyTypeDouble: return RLMAccessorCodeDoubleObject;
                case RLMPropertyTypeFloat: return RLMAccessorCodeFloatObject;
                case RLMPropertyTypeInt: return RLMAccessorCodeIntObject;

                case RLMPropertyTypeLinkingObjects: return RLMAccessorCodeLinkingObjects;
            }
        case 'c':
            switch (rlmType) {
                case RLMPropertyTypeInt: return RLMAccessorCodeByte;
                case RLMPropertyTypeBool: return RLMAccessorCodeBool;
                default:
                    @throw RLMException(@"Unexpected property type for Objective-C type code");
            }
        case 'B': return RLMAccessorCodeBool;
        case 's': return RLMAccessorCodeShort;
        case 'i': return RLMAccessorCodeInt;
        case 'l': return RLMAccessorCodeLong;
        case 'q': return RLMAccessorCodeLongLong;
        case 'f': return RLMAccessorCodeFloat;
        case 'd': return RLMAccessorCodeDouble;
        default:
            @throw RLMException(@"Invalid type for objc typecode");
    }
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
        if (RLMIsGeneratedClass(cls)) {
            return schema;
        }

        return [RLMSchema sharedSchemaForClass:cls];
    });
    class_addMethod(metaClass, @selector(sharedSchema), imp, "@@:");
}

static NSMutableSet *s_generatedClasses = [NSMutableSet new];
static void RLMMarkClassAsGenerated(Class cls) {
    @synchronized (s_generatedClasses) {
        [s_generatedClasses addObject:cls];
    }
}

bool RLMIsGeneratedClass(Class cls) {
    @synchronized (s_generatedClasses) {
        return [s_generatedClasses containsObject:cls];
    }
}

static Class RLMCreateAccessorClass(Class objectClass,
                                    RLMObjectSchema *schema,
                                    NSString *accessorClassPrefix,
                                    IMP (*getterGetter)(RLMProperty *, RLMAccessorCode),
                                    IMP (*setterGetter)(RLMProperty *, RLMAccessorCode)) {
    // throw if no schema, prefix, or object class
    if (!objectClass || !schema || !accessorClassPrefix) {
        @throw RLMException(@"Missing arguments");
    }
    if (!RLMIsObjectOrSubclass(objectClass)) {
        @throw RLMException(@"objectClass must derive from RLMObject or Object");
    }

    // create and register proxy class which derives from object class
    NSString *accessorClassName = [accessorClassPrefix stringByAppendingString:schema.className];
    Class accClass = objc_getClass(accessorClassName.UTF8String);
    if (!accClass) {
        accClass = objc_allocateClassPair(objectClass, accessorClassName.UTF8String, 0);
        objc_registerClassPair(accClass);
    }

    // override getters/setters for each propery
    NSArray *allProperties = [schema.properties arrayByAddingObjectsFromArray:schema.computedProperties];
    for (RLMProperty *prop in allProperties) {
        RLMAccessorCode accessorCode = accessorCodeForType(prop.objcType, prop.type);
        if (prop.getterSel && getterGetter) {
            IMP getterImp = getterGetter(prop, accessorCode);
            if (getterImp) {
                class_replaceMethod(accClass, prop.getterSel, getterImp, getterTypeStringForObjcCode(prop.objcType));
            }
        }
        if (prop.setterSel && setterGetter) {
            IMP setterImp = setterGetter(prop, accessorCode);
            if (setterImp) {
                class_replaceMethod(accClass, prop.setterSel, setterImp, setterTypeStringForObjcCode(prop.objcType));
            }
        }
    }

    RLMMarkClassAsGenerated(accClass);

    return accClass;
}

Class RLMAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema, NSString *prefix) {
    return RLMCreateAccessorClass(objectClass, schema, prefix, RLMAccessorGetter, RLMAccessorSetter);
}

Class RLMUnmanagedAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema) {
    return RLMCreateAccessorClass(objectClass, schema, @"RLMUnmanaged_",
                                  RLMAccessorUnmanagedGetter, RLMAccessorUnmanagedSetter);
}

void RLMDynamicValidatedSet(RLMObjectBase *obj, NSString *propName, id val) {
    RLMObjectSchema *schema = obj->_objectSchema;
    RLMProperty *prop = schema[propName];
    if (!prop) {
        @throw RLMException(@"Invalid property name '%@' for class '%@'.", propName, obj->_objectSchema.className);
    }
    if (prop.isPrimary) {
        @throw RLMException(@"Primary key can't be changed to '%@' after an object is inserted.", val);
    }
    if (!RLMIsObjectValidForProperty(val, prop)) {
        @throw RLMException(@"Invalid property value '%@' for property '%@' of class '%@'", val, propName, obj->_objectSchema.className);
    }

    RLMDynamicSet(obj, prop, RLMCoerceToNil(val), RLMCreationOptionsPromoteUnmanaged);
}

// Precondition: the property is not a primary key
void RLMDynamicSet(__unsafe_unretained RLMObjectBase *const obj, __unsafe_unretained RLMProperty *const prop,
                   __unsafe_unretained id const val, RLMCreationOptions creationOptions) {
    REALM_ASSERT_DEBUG(!prop.isPrimary);

    auto col = obj->_info->tableColumn(prop);
    RLMWrapSetter(obj, prop.name, [&] {
        switch (accessorCodeForType(prop.objcType, prop.type)) {
            case RLMAccessorCodeByte:
            case RLMAccessorCodeShort:
            case RLMAccessorCodeInt:
            case RLMAccessorCodeLong:
            case RLMAccessorCodeLongLong:
                RLMSetValue(obj, col, [val longLongValue]);
                break;
            case RLMAccessorCodeFloat:
                RLMSetValue(obj, col, [val floatValue]);
                break;
            case RLMAccessorCodeDouble:
                RLMSetValue(obj, col, [val doubleValue]);
                break;
            case RLMAccessorCodeBool:
                RLMSetValue(obj, col, [val boolValue]);
                break;
            case RLMAccessorCodeIntObject:
                RLMSetValue(obj, col, (NSNumber<RLMInt> *)val);
                break;
            case RLMAccessorCodeFloatObject:
                RLMSetValue(obj, col, (NSNumber<RLMFloat> *)val);
                break;
            case RLMAccessorCodeDoubleObject:
                RLMSetValue(obj, col, (NSNumber<RLMDouble> *)val);
                break;
            case RLMAccessorCodeBoolObject:
                RLMSetValue(obj, col, (NSNumber<RLMBool> *)val);
                break;
            case RLMAccessorCodeString:
                RLMSetValue(obj, col, (NSString *)val);
                break;
            case RLMAccessorCodeDate:
                RLMSetValue(obj, col, (NSDate *)val);
                break;
            case RLMAccessorCodeData:
                RLMSetValue(obj, col, (NSData *)val);
                break;
            case RLMAccessorCodeLink: {
                if (!val || val == NSNull.null) {
                    RLMSetValue(obj, col, (RLMObjectBase *)nil);
                }
                else {
                    RLMSetValue(obj, col, RLMGetLinkedObjectForValue(obj->_realm, prop.objectClassName, val, creationOptions));
                }
                break;
            }
            case RLMAccessorCodeArray:
                if (!val || val == NSNull.null) {
                    RLMSetValue(obj, col, (id<NSFastEnumeration>)nil);
                }
                else {
                    id<NSFastEnumeration> rawLinks = val;
                    NSMutableArray *links = [NSMutableArray array];
                    for (id rawLink in rawLinks) {
                        [links addObject:RLMGetLinkedObjectForValue(obj->_realm, prop.objectClassName, rawLink, creationOptions)];
                    }
                    RLMSetValue(obj, col, links);
                }
                break;
            case RLMAccessorCodeAny:
                RLMSetValue(obj, col, val);
                break;
            case RLMAccessorCodeLinkingObjects:
                @throw RLMException(@"Linking objects properties are read-only");
        }
    });
}

id RLMDynamicGet(__unsafe_unretained RLMObjectBase *const obj, __unsafe_unretained RLMProperty *const prop) {
    auto index = prop.index;
    switch (accessorCodeForType(prop.objcType, prop.type)) {
        case RLMAccessorCodeIntObject:
        case RLMAccessorCodeByte:
        case RLMAccessorCodeShort:
        case RLMAccessorCodeInt:
        case RLMAccessorCodeLong:
        case RLMAccessorCodeLongLong:     return getBoxed<int64_t>(obj, index);
        case RLMAccessorCodeFloatObject:
        case RLMAccessorCodeFloat:        return getBoxed<float>(obj, index);
        case RLMAccessorCodeDoubleObject:
        case RLMAccessorCodeDouble:       return getBoxed<double>(obj, index);
        case RLMAccessorCodeBoolObject:
        case RLMAccessorCodeBool:         return getBoxed<bool>(obj, index);
        case RLMAccessorCodeString:       return RLMGetString(obj, index);
        case RLMAccessorCodeDate:         return RLMGetDate(obj, index);
        case RLMAccessorCodeData:         return RLMGetData(obj, index);
        case RLMAccessorCodeLink:         return RLMGetLink(obj, index);
        case RLMAccessorCodeArray:        return RLMGetArray(obj, index);
        case RLMAccessorCodeAny:          return RLMGetAnyProperty(obj, index);
        case RLMAccessorCodeLinkingObjects: return RLMGetLinkingObjects(obj, prop);
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
