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
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.h"
#import "RLMObject_Private.hpp"
#import "RLMProperty_Private.h"
#import "RLMRealm_Private.hpp"
#import "RLMSchema_Private.h"
#import "RLMUtil.hpp"

#import <objc/runtime.h>

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
    RLMAccessorCodeAny,
};

// verify attached
static inline void RLMVerifyAttached(__unsafe_unretained RLMObjectBase *const obj) {
    if (!obj->_row.is_attached()) {
        @throw RLMException(@"Object has been deleted or invalidated.");
    }
    RLMCheckThread(obj->_realm);
}

// verify writable
static inline void RLMVerifyInWriteTransaction(__unsafe_unretained RLMObjectBase *const obj) {
    // first verify is attached
    RLMVerifyAttached(obj);

    if (!obj->_realm->_inWriteTransaction) {
        @throw RLMException(@"Attempting to modify object outside of a write transaction - call beginWriteTransaction on an RLMRealm instance first.");
    }
}

// long getter/setter
static inline long long RLMGetLong(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return obj->_row.get_int(colIndex);
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, long long val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_int(colIndex, val);
}
static inline void RLMSetValueUnique(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, NSString *propName, long long val) {
    RLMVerifyInWriteTransaction(obj);
    size_t row = obj->_row.get_table()->find_first_int(colIndex, val);
    if (row == obj->_row.get_index()) {
        return;
    }
    if (row != realm::not_found) {
        NSString *reason = [NSString stringWithFormat:@"Can't set primary key property '%@' to existing value '%lld'.", propName, val];
        @throw RLMException(reason);
    }
    obj->_row.set_int(colIndex, val);
}

// float getter/setter
static inline float RLMGetFloat(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return obj->_row.get_float(colIndex);
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, float val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_float(colIndex, val);
}

// double getter/setter
static inline double RLMGetDouble(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return obj->_row.get_double(colIndex);
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, double val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_double(colIndex, val);
}

// bool getter/setter
static inline bool RLMGetBool(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return obj->_row.get_bool(colIndex);
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, BOOL val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_bool(colIndex, val);
}

// string getter/setter
static inline NSString *RLMGetString(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return RLMStringDataToNSString(obj->_row.get_string(colIndex));
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
static inline void RLMSetValueUnique(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, NSString *propName,
                                     __unsafe_unretained NSString *const val) {
    RLMVerifyInWriteTransaction(obj);
    realm::StringData str = RLMStringDataWithNSString(val);
    size_t row = obj->_row.get_table()->find_first_string(colIndex, str);
    if (row == obj->_row.get_index()) {
        return;
    }
    if (row != realm::not_found) {
        NSString *reason = [NSString stringWithFormat:@"Can't set primary key property '%@' to existing value '%@'.", propName, val];
        @throw RLMException(reason);
    }
    try {
        obj->_row.set_string(colIndex, str);
    }
    catch (std::exception const& e) {
        @throw RLMException(e);
    }
}

// date getter/setter
static inline NSDate *RLMGetDate(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    realm::DateTime dt = obj->_row.get_datetime(colIndex);
    return [NSDate dateWithTimeIntervalSince1970:dt.get_datetime()];
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, __unsafe_unretained NSDate *const date) {
    RLMVerifyInWriteTransaction(obj);
    std::time_t time = date.timeIntervalSince1970;
    obj->_row.set_datetime(colIndex, realm::DateTime(time));
}

// data getter/setter
static inline NSData *RLMGetData(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    realm::BinaryData data = obj->_row.get_binary(colIndex);
    return [NSData dataWithBytes:data.data() length:data.size()];
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

static inline size_t RLMAddLinkedObject(RLMObjectBase *link,
                                        __unsafe_unretained RLMRealm *const realm,
                                        RLMCreationOptions options) {
    if (link.isInvalidated) {
        @throw RLMException(@"Adding a deleted or invalidated object to a Realm is not permitted");
    }
    else if (link->_realm != realm) {
        // only try to update if link object has primary key
        if ((options & RLMCreationOptionsUpdateOrCreate) && link->_objectSchema.primaryKeyProperty) {
            link = RLMCreateObjectInRealmWithValue(realm, link->_objectSchema.className, link, RLMCreationOptionsUpdateOrCreate | RLMCreationOptionsAllowCopy);
        }
        else if (options & RLMCreationOptionsAllowCopy) {
            link = RLMCreateObjectInRealmWithValue(realm, link->_objectSchema.className, link, RLMCreationOptionsAllowCopy);
        }
        else {
            RLMAddObjectToRealm(link, realm, options);
        }
    }
    return link->_row.get_index();
}

// link getter/setter
static inline RLMObjectBase *RLMGetLink(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, __unsafe_unretained NSString *const objectClassName) {
    RLMVerifyAttached(obj);

    if (obj->_row.is_null_link(colIndex)) {
        return nil;
    }
    NSUInteger index = obj->_row.get_link(colIndex);
    return RLMCreateObjectAccessor(obj->_realm, obj->_realm.schema[objectClassName], index);
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained RLMObjectBase *const val, RLMCreationOptions options=0) {
    RLMVerifyInWriteTransaction(obj);

    if (!val || (id)val == NSNull.null) {
        // if null
        obj->_row.nullify_link(colIndex);
    }
    else {
        // make sure it is the correct type
        RLMObjectSchema *valSchema = val->_objectSchema;
        RLMObjectSchema *objSchema = obj->_objectSchema;
        if (![[objSchema.properties[colIndex] objectClassName] isEqualToString:valSchema.className]) {
            NSString *reason = [NSString stringWithFormat:@"Can't set object of type '%@' to property of type '%@'",
                                valSchema.className, [objSchema.properties[colIndex] objectClassName]];
            @throw RLMException(reason);
        }

        obj->_row.set_link(colIndex, RLMAddLinkedObject(val, obj->_realm, options));
    }
}

// array getter/setter
static inline RLMArray *RLMGetArray(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex, __unsafe_unretained NSString *const objectClassName) {
    RLMVerifyAttached(obj);

    realm::LinkViewRef linkView = obj->_row.get_linklist(colIndex);
    RLMArrayLinkView *ar = [RLMArrayLinkView arrayWithObjectClassName:objectClassName
                                                                 view:linkView
                                                                realm:obj->_realm];
    return ar;
}

static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger colIndex,
                               __unsafe_unretained id<NSFastEnumeration> const val,
                               RLMCreationOptions options=0) {
    RLMVerifyInWriteTransaction(obj);

    realm::LinkViewRef linkView = obj->_row.get_linklist(colIndex);
    // remove all old
    // FIXME: make sure delete rules don't purge objects
    linkView->clear();
    if ((id)val != NSNull.null) {
        for (RLMObjectBase *link in val) {
            linkView->add(RLMAddLinkedObject(link, obj->_realm, options));
        }
    }
}

// any getter/setter
static inline id RLMGetAnyProperty(__unsafe_unretained RLMObjectBase *const obj, NSUInteger col_ndx) {
    RLMVerifyAttached(obj);

    realm::Mixed mixed = obj->_row.get_mixed(col_ndx);
    switch (mixed.get_type()) {
        case RLMPropertyTypeString:
            return RLMStringDataToNSString(mixed.get_string());
        case RLMPropertyTypeInt: {
            return @(mixed.get_int());
        case RLMPropertyTypeFloat:
            return @(mixed.get_float());
        case RLMPropertyTypeDouble:
            return @(mixed.get_double());
        case RLMPropertyTypeBool:
            return @(mixed.get_bool());
        case RLMPropertyTypeDate:
            return [NSDate dateWithTimeIntervalSince1970:mixed.get_datetime().get_datetime()];
        case RLMPropertyTypeData: {
            realm::BinaryData bd = mixed.get_binary();
            NSData *d = [NSData dataWithBytes:bd.data() length:bd.size()];
            return d;
        }
        case RLMPropertyTypeArray:
            @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                           reason:@"RLMArray not yet supported" userInfo:nil];

            // for links and other unsupported types throw
        case RLMPropertyTypeObject:
        default:
            @throw RLMException(@"Invalid data type for RLMPropertyTypeAny property.");
        }
    }
}
static inline void RLMSetValue(__unsafe_unretained RLMObjectBase *const obj, NSUInteger col_ndx, __unsafe_unretained id val) {
    RLMVerifyInWriteTransaction(obj);

    // FIXME - enable when Any supports links
    //    if (obj == nil) {
    //        table.nullify_link(col_ndx, row_ndx);
    //        return;
    //    }
    if (NSString *str = RLMDynamicCast<NSString>(val)) {
        obj->_row.set_mixed(col_ndx, RLMStringDataWithNSString(str));
        return;
    }
    if (NSDate *date = RLMDynamicCast<NSDate>(val)) {
        obj->_row.set_mixed(col_ndx, realm::DateTime(time_t([date timeIntervalSince1970])));
        return;
    }
    if (NSData *data = RLMDynamicCast<NSData>(val)) {
        obj->_row.set_mixed(col_ndx, RLMBinaryDataForNSData(data));
        return;
    }
    if (NSNumber *number = RLMDynamicCast<NSNumber>(val)) {
        switch (number.objCType[0]) {
            case 'i':
            case 's':
            case 'l':
            case 'q':
                obj->_row.set_mixed(col_ndx, number.longLongValue);
                return;
            case 'f':
                obj->_row.set_mixed(col_ndx, number.floatValue);
                return;
            case 'd':
                obj->_row.set_mixed(col_ndx, number.doubleValue);
                return;
            case 'B':
            case 'c':
                obj->_row.set_mixed(col_ndx, (bool)number.boolValue);
                return;
        }
    }
    @throw RLMException([NSString stringWithFormat:@"Inserting invalid object of class %@ for an RLMPropertyTypeAny property (%@).", [val class], [obj->_objectSchema.properties[col_ndx] name]]);
}

// dynamic getter with column closure
static IMP RLMAccessorGetter(RLMProperty *prop, RLMAccessorCode accessorCode, NSString *objectClassName) {
    NSUInteger colIndex = prop.column;
    switch (accessorCode) {
        case RLMAccessorCodeByte:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return (char)RLMGetLong(obj, colIndex);
            });
        case RLMAccessorCodeShort:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return (short)RLMGetLong(obj, colIndex);
            });
        case RLMAccessorCodeInt:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return (int)RLMGetLong(obj, colIndex);
            });
        case RLMAccessorCodeLongLong:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetLong(obj, colIndex);
            });
        case RLMAccessorCodeLong:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return (long)RLMGetLong(obj, colIndex);
            });
        case RLMAccessorCodeFloat:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetFloat(obj, colIndex);
            });
        case RLMAccessorCodeDouble:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetDouble(obj, colIndex);
            });
        case RLMAccessorCodeBool:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetBool(obj, colIndex);
            });
        case RLMAccessorCodeString:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetString(obj, colIndex);
            });
        case RLMAccessorCodeDate:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetDate(obj, colIndex);
            });
        case RLMAccessorCodeData:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetData(obj, colIndex);
            });
        case RLMAccessorCodeLink:
            return imp_implementationWithBlock(^id(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetLink(obj, colIndex, objectClassName);
            });
        case RLMAccessorCodeArray:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetArray(obj, colIndex, objectClassName);
            });
        case RLMAccessorCodeAny:
            return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj) {
                return RLMGetAnyProperty(obj, colIndex);
            });
    }
}

template<typename ArgType, typename StorageType=ArgType>
static IMP RLMMakeSetter(NSUInteger colIndex, bool isPrimary) {
    if (isPrimary) {
        return imp_implementationWithBlock(^(__unused RLMObjectBase *obj, __unused ArgType val) {
            @throw RLMException(@"Primary key can't be changed after an object is inserted.");
        });
    }
    return imp_implementationWithBlock(^(__unsafe_unretained RLMObjectBase *const obj, ArgType val) {
        RLMSetValue(obj, colIndex, static_cast<StorageType>(val));
    });
}

// dynamic setter with column closure
static IMP RLMAccessorSetter(RLMProperty *prop, RLMAccessorCode accessorCode) {
    NSUInteger colIndex = prop.column;
    switch (accessorCode) {
        case RLMAccessorCodeByte: return RLMMakeSetter<char, long long>(colIndex, prop.isPrimary);
        case RLMAccessorCodeShort: return RLMMakeSetter<short, long long>(colIndex, prop.isPrimary);
        case RLMAccessorCodeInt: return RLMMakeSetter<int, long long>(colIndex, prop.isPrimary);
        case RLMAccessorCodeLong: return RLMMakeSetter<long, long long>(colIndex, prop.isPrimary);
        case RLMAccessorCodeLongLong: return RLMMakeSetter<long long>(colIndex, prop.isPrimary);
        case RLMAccessorCodeFloat: return RLMMakeSetter<float>(colIndex, prop.isPrimary);
        case RLMAccessorCodeDouble: return RLMMakeSetter<double>(colIndex, prop.isPrimary);
        case RLMAccessorCodeBool: return RLMMakeSetter<BOOL>(colIndex, prop.isPrimary);
        case RLMAccessorCodeString: return RLMMakeSetter<NSString *>(colIndex, prop.isPrimary);
        case RLMAccessorCodeDate: return RLMMakeSetter<NSDate *>(colIndex, prop.isPrimary);
        case RLMAccessorCodeData: return RLMMakeSetter<NSData *>(colIndex, prop.isPrimary);
        case RLMAccessorCodeLink: return RLMMakeSetter<RLMObjectBase *>(colIndex, prop.isPrimary);
        case RLMAccessorCodeArray: return RLMMakeSetter<RLMArray *>(colIndex, prop.isPrimary);
        case RLMAccessorCodeAny: return RLMMakeSetter<id>(colIndex, prop.isPrimary);
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

// getter/setter for standalone
static IMP RLMAccessorStandaloneGetter(RLMProperty *prop, RLMAccessorCode accessorCode, NSString *objectClassName) {
    // only override getters for RLMArray properties
    if (accessorCode == RLMAccessorCodeArray) {
        NSString *propName = prop.name;
        return imp_implementationWithBlock(^(RLMObjectBase *obj) {
            id val = RLMSuperGet(obj, propName);
            if (!val) {
                val = [[RLMArray alloc] initWithObjectClassName:objectClassName standalone:YES];
                RLMSuperSet(obj, propName, val);
            }
            return val;
        });
    }
    return nil;
}
static IMP RLMAccessorStandaloneSetter(RLMProperty *prop, RLMAccessorCode accessorCode) {
    // only override getters for RLMArray properties
    if (accessorCode == RLMAccessorCodeArray) {
        NSString *propName = prop.name;
        NSString *objectClassName = prop.objectClassName;
        return imp_implementationWithBlock(^(RLMObjectBase *obj, id<NSFastEnumeration> ar) {
            // make copy when setting (as is the case for all other variants)
            RLMArray *standaloneAr = [[RLMArray alloc] initWithObjectClassName:objectClassName standalone:YES];
            if ((id)ar != NSNull.null) {
                [standaloneAr addObjects:ar];
            }
            RLMSuperSet(obj, propName, standaloneAr);
        });
    }
    return nil;
}

// macros/helpers to generate objc type strings for registering methods
#define GETTER_TYPES(C) C ":@"
#define SETTER_TYPES(C) "v:@" C

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
                    
                // throw for all primitive types
                case RLMPropertyTypeBool:
                case RLMPropertyTypeDouble:
                case RLMPropertyTypeFloat:
                case RLMPropertyTypeInt:
                    break;
            }
        case 'c':
            switch (rlmType) {
                case RLMPropertyTypeInt: return RLMAccessorCodeByte;
                case RLMPropertyTypeBool: return RLMAccessorCodeBool;
                default: break;
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
    Class metaClass = objc_getMetaClass(class_getName(accessorClass));
    IMP imp = imp_implementationWithBlock(^{ return className; });
    class_addMethod(metaClass, @selector(className), imp, "@:");
}

// implement the shared schema method
void RLMReplaceSharedSchemaMethod(Class accessorClass, RLMObjectSchema *schema) {
    Class metaClass = objc_getMetaClass(class_getName(accessorClass));
    IMP imp = imp_implementationWithBlock(^{ return schema; });
    class_replaceMethod(metaClass, @selector(sharedSchema), imp, "@:");
}

static Class RLMCreateAccessorClass(Class objectClass,
                                    RLMObjectSchema *schema,
                                    NSString *accessorClassPrefix,
                                    IMP (*getterGetter)(RLMProperty *, RLMAccessorCode, NSString *),
                                    IMP (*setterGetter)(RLMProperty *, RLMAccessorCode)) {
    // throw if no schema, prefix, or object class
    if (!objectClass || !schema || !accessorClassPrefix) {
        @throw RLMException(@"Missing arguments");
    }
    if (!RLMIsKindOfClass(objectClass, RLMObjectBase.class)) {
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
    for (unsigned int propNum = 0; propNum < schema.properties.count; propNum++) {
        RLMProperty *prop = schema.properties[propNum];
        RLMAccessorCode accessorCode = accessorCodeForType(prop.objcType, prop.type);
        if (prop.getterSel && getterGetter) {
            IMP getterImp = getterGetter(prop, accessorCode, prop.objectClassName);
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
    
    // implement className for accessor to return base className
    RLMReplaceClassNameMethod(accClass, schema.className);

    return accClass;
}

Class RLMAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema, NSString *prefix) {
    return RLMCreateAccessorClass(objectClass, schema, prefix, RLMAccessorGetter, RLMAccessorSetter);
}

Class RLMStandaloneAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema) {
    return RLMCreateAccessorClass(objectClass, schema, @"RLMStandalone_",
                                  RLMAccessorStandaloneGetter, RLMAccessorStandaloneSetter);
}

void RLMDynamicValidatedSet(RLMObjectBase *obj, NSString *propName, id val) {
    RLMObjectSchema *schema = obj->_objectSchema;
    RLMProperty *prop = schema[propName];
    if (!prop) {
        @throw RLMException(@"Invalid property name",
                            @{@"Property name:" : propName ?: @"nil",
                              @"Class name": obj->_objectSchema.className});
    }
    if (!RLMIsObjectValidForProperty(val, prop)) {
        @throw RLMException(@"Invalid property name",
                            @{@"Property name:" : propName ?: @"nil",
                              @"Value": val ? [val description] : @"nil"});
    }
    RLMDynamicSet(obj, prop, val, prop.isPrimary ? RLMCreationOptionsEnforceUnique : 0);
}

void RLMDynamicSet(__unsafe_unretained RLMObjectBase *const obj,
                   __unsafe_unretained RLMProperty *const prop,
                   __unsafe_unretained id val, RLMCreationOptions options) {
    NSUInteger col = prop.column;
    switch (accessorCodeForType(prop.objcType, prop.type)) {
        case RLMAccessorCodeByte:
        case RLMAccessorCodeShort:
        case RLMAccessorCodeInt:
        case RLMAccessorCodeLong:
        case RLMAccessorCodeLongLong:
            if (options & RLMCreationOptionsEnforceUnique) {
                RLMSetValueUnique(obj, col, prop.name, [val longLongValue]);
            }
            else {
                RLMSetValue(obj, col, [val longLongValue]);
            }
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
        case RLMAccessorCodeString:
            if (options & RLMCreationOptionsEnforceUnique) {
                RLMSetValueUnique(obj, col, prop.name, (NSString *)val);
            }
            else {
                RLMSetValue(obj, col, (NSString *)val);
            }
            break;
        case RLMAccessorCodeDate:
            RLMSetValue(obj, col, (NSDate *)val);
            break;
        case RLMAccessorCodeData:
            RLMSetValue(obj, col, (NSData *)val);
            break;
        case RLMAccessorCodeLink:
            RLMSetValue(obj, col, (RLMObjectBase *)val, options);
            break;
        case RLMAccessorCodeArray:
            RLMSetValue(obj, col, (RLMArray *)val, options);
            break;
        case RLMAccessorCodeAny:
            RLMSetValue(obj, col, val);
            break;
    }
}

id RLMDynamicGet(__unsafe_unretained RLMObjectBase *obj, __unsafe_unretained NSString *propName) {
    RLMProperty *prop = obj->_objectSchema[propName];
    if (!prop) {
        @throw RLMException(@"Invalid property name",
                            @{@"Property name:" : propName ?: @"nil",
                              @"Class name": obj->_objectSchema.className});
    }
    NSUInteger col = prop.column;
    switch (accessorCodeForType(prop.objcType, prop.type)) {
        case RLMAccessorCodeByte: return @((char)RLMGetLong(obj, col));
        case RLMAccessorCodeShort: return @((short)RLMGetLong(obj, col));
        case RLMAccessorCodeInt: return @((int)RLMGetLong(obj, col));
        case RLMAccessorCodeLong: return @((long)RLMGetLong(obj, col));
        case RLMAccessorCodeLongLong: return @(RLMGetLong(obj, col));
        case RLMAccessorCodeFloat: return @(RLMGetFloat(obj, col));
        case RLMAccessorCodeDouble: return @(RLMGetDouble(obj, col));
        case RLMAccessorCodeBool: return @(RLMGetBool(obj, col));
        case RLMAccessorCodeString: return RLMGetString(obj, col);
        case RLMAccessorCodeDate: return RLMGetDate(obj, col);
        case RLMAccessorCodeData: return RLMGetData(obj, col);
        case RLMAccessorCodeLink: return RLMGetLink(obj, col, prop.objectClassName);
        case RLMAccessorCodeArray: return RLMGetArray(obj, col, prop.objectClassName);
        case RLMAccessorCodeAny: return RLMGetAnyProperty(obj, col);
    }
}
