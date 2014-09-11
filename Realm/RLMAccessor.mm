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
#import "RLMProperty_Private.h"
#import "RLMArray_Private.hpp"
#import "RLMUtil.hpp"
#import "RLMObjectSchema_Private.hpp"
#import "RLMObjectStore.hpp"

#import <objc/runtime.h>

// verify attached
static inline void RLMVerifyAttached(__unsafe_unretained RLMObject *obj) {
    if (!obj->_row.is_attached()) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Object has been deleted and is no longer valid."
                                     userInfo:nil];
    }
    RLMCheckThread(obj->_realm);
}

// verify writable
static inline void RLMVerifyInWriteTransaction(__unsafe_unretained RLMObject *obj) {
    // first verify is attached
    RLMVerifyAttached(obj);

    if (!obj->_realm->_inWriteTransaction) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Attempting to modify object outside of a write transaction - call beginWriteTransaction on a RLMRealm instance first."
                                     userInfo:nil];
    }
}

// long getter/setter
static inline long long RLMGetLong(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return obj->_row.get_int(colIndex);
}
static inline void RLMSetValue(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, long long val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_int(colIndex, val);
}
static inline void RLMSetValueUnique(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, NSString *propName, long long val) {
    RLMVerifyInWriteTransaction(obj);
    size_t row = obj->_row.get_table()->find_first_int(colIndex, val);
    if (row == obj->_row.get_index()) {
        return;
    }
    if (row != tightdb::not_found) {
        NSString *reason = [NSString stringWithFormat:@"Setting primary key with existing value '%lld' for property '%@'",
                            val, propName];
        @throw [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];
    }
    obj->_row.set_int(colIndex, val);
}

// float getter/setter
static inline float RLMGetFloat(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return obj->_row.get_float(colIndex);
}
static inline void RLMSetValue(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, float val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_float(colIndex, val);
}

// double getter/setter
static inline double RLMGetDouble(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return obj->_row.get_double(colIndex);
}
static inline void RLMSetValue(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, double val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_double(colIndex, val);
}

// bool getter/setter
static inline bool RLMGetBool(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return obj->_row.get_bool(colIndex);
}
static inline void RLMSetValue(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, bool val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_bool(colIndex, val);
}

// string getter/setter
static inline NSString *RLMGetString(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return RLMStringDataToNSString(obj->_row.get_string(colIndex));
}
static inline void RLMSetValue(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained NSString *val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_string(colIndex, RLMStringDataWithNSString(val));
}
static inline void RLMSetValueUnique(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, NSString *propName,
                                      __unsafe_unretained NSString *val) {
    RLMVerifyInWriteTransaction(obj);
    tightdb::StringData str = RLMStringDataWithNSString(val);
    size_t row = obj->_row.get_table()->find_first_string(colIndex, str);
    if (row == obj->_row.get_index()) {
        return;
    }
    if (row != tightdb::not_found) {
        NSString *reason = [NSString stringWithFormat:@"Setting unique property '%@' with existing value '%@'",
                            val, propName];
        @throw [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];
    }
    obj->_row.set_string(colIndex, str);
}

// date getter/setter
static inline NSDate *RLMGetDate(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    tightdb::DateTime dt = obj->_row.get_datetime(colIndex);
    return [NSDate dateWithTimeIntervalSince1970:dt.get_datetime()];
}
static inline void RLMSetValue(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained NSDate *date) {
    RLMVerifyInWriteTransaction(obj);
    std::time_t time = date.timeIntervalSince1970;
    obj->_row.set_datetime(colIndex, tightdb::DateTime(time));
}

// data getter/setter
static inline NSData *RLMGetData(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    tightdb::BinaryData data = obj->_row.get_binary(colIndex);
    return [NSData dataWithBytes:data.data() length:data.size()];
}
static inline void RLMSetValue(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained NSData *data) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_binary(colIndex, RLMBinaryDataForNSData(data));
}

// link getter/setter
static inline RLMObject *RLMGetLink(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained NSString *objectClassName) {
    RLMVerifyAttached(obj);

    if (obj->_row.is_null_link(colIndex)) {
        return nil;
    }
    NSUInteger index = obj->_row.get_link(colIndex);
    return RLMCreateObjectAccessor(obj.realm, objectClassName, index);
}
static inline void RLMSetValue(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained RLMObject *val, bool tryUpdate = false) {
    RLMVerifyInWriteTransaction(obj);

    if (!val || (id)val == NSNull.null) {
        // if null
        obj->_row.nullify_link(colIndex);
    }
    else {
        // add to Realm if not in it.
        RLMObject *link = val;
        if (link.realm != obj.realm) {
            // only try to update if link object has primary key
            if (tryUpdate && link.objectSchema.primaryKeyProperty) {
                [obj.realm addOrUpdateObject:link];
            }
            else {
                [obj.realm addObject:link];
            }
        }
        // set link
        obj->_row.set_link(colIndex, link->_row.get_index());
    }
}

// array getter/setter
static inline RLMArray *RLMGetArray(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained NSString *objectClassName) {
    RLMVerifyAttached(obj);

    tightdb::LinkViewRef linkView = obj->_row.get_linklist(colIndex);
    RLMArrayLinkView *ar = [RLMArrayLinkView arrayWithObjectClassName:objectClassName
                                                                 view:linkView
                                                                realm:obj.realm];
    return ar;
}
static inline void RLMSetValue(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained id<NSFastEnumeration> val, bool tryUpdate = false) {
    RLMVerifyInWriteTransaction(obj);

    tightdb::LinkViewRef linkView = obj->_row.get_linklist(colIndex);
    // remove all old
    // FIXME: make sure delete rules don't purge objects
    linkView->clear();
    for (RLMObject *link in val) {
        // add to realm if needed
        if (link.realm != obj.realm) {
            // only try to update if link object has primary key
            if (tryUpdate && link.objectSchema.primaryKeyProperty) {
                [obj.realm addOrUpdateObject:link];
            }
            else {
                [obj.realm addObject:link];
            }
        }
        // set in link view
        linkView->add(link->_row.get_index());
    }
}

// any getter/setter
static inline id RLMGetAnyProperty(__unsafe_unretained RLMObject *obj, NSUInteger col_ndx) {
    RLMVerifyAttached(obj);

    tightdb::Mixed mixed = obj->_row.get_mixed(col_ndx);
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
            tightdb::BinaryData bd = mixed.get_binary();
            NSData *d = [NSData dataWithBytes:bd.data() length:bd.size()];
            return d;
        }
        case RLMPropertyTypeArray:
            @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                           reason:@"RLMArray not yet supported" userInfo:nil];

            // for links and other unsupported types throw
        case RLMPropertyTypeObject:
        default:
            @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid data type for RLMPropertyTypeAny property." userInfo:nil];
        }
    }
}
static inline void RLMSetValue(__unsafe_unretained RLMObject *obj, NSUInteger col_ndx, __unsafe_unretained id val) {
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
        obj->_row.set_mixed(col_ndx, tightdb::DateTime(time_t([date timeIntervalSince1970])));
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
    @throw [NSException exceptionWithName:@"RLMException" reason:@"Inserting invalid object for RLMPropertyTypeAny property" userInfo:nil];
}

// dynamic getter with column closure
static IMP RLMAccessorGetter(RLMProperty *prop, char accessorCode, NSString *objectClassName) {
    NSUInteger colIndex = prop.column;
    switch (accessorCode) {
        case 's':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return (short)RLMGetLong(obj, colIndex);
            });
        case 'i':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return (int)RLMGetLong(obj, colIndex);
            });
        case 'q':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return RLMGetLong(obj, colIndex);
            });
        case 'l':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return (long)RLMGetLong(obj, colIndex);
            });
        case 'f':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return RLMGetFloat(obj, colIndex);
            });
        case 'd':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return RLMGetDouble(obj, colIndex);
            });
        case 'B':
        case 'c':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return RLMGetBool(obj, colIndex);
            });
        case 'S':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return RLMGetString(obj, colIndex);
            });
        case 'a':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return RLMGetDate(obj, colIndex);
            });
        case 'e':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return RLMGetData(obj, colIndex);
            });
        case 'k':
            return imp_implementationWithBlock(^id(RLMObject *obj) {
                return RLMGetLink(obj, colIndex, objectClassName);
            });
        case 't':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return RLMGetArray(obj, colIndex, objectClassName);
            });
        case '@':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return RLMGetAnyProperty(obj, colIndex);
            });
        default:
            @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid accessor code" userInfo:nil];
    }
}

template<typename ArgType, typename StorageType=ArgType>
static IMP RLMMakeSetter(NSUInteger colIndex, bool isPrimary) {
    if (isPrimary) {
        return imp_implementationWithBlock(^(__unused RLMObject *obj, __unused ArgType val) {
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Primary key can't be changed after an object is inserted."
                                         userInfo:nil];
        });
    }
    return imp_implementationWithBlock(^(RLMObject *obj, ArgType val) {
        RLMSetValue(obj, colIndex, static_cast<StorageType>(val));
    });
}

// dynamic setter with column closure
static IMP RLMAccessorSetter(RLMProperty *prop, char accessorCode) {
    NSUInteger colIndex = prop.column;
    switch (accessorCode) {
        case 's': return RLMMakeSetter<short, long long>(colIndex, prop.isPrimary);
        case 'i': return RLMMakeSetter<int, long long>(colIndex, prop.isPrimary);
        case 'l': return RLMMakeSetter<long, long long>(colIndex, prop.isPrimary);
        case 'q': return RLMMakeSetter<long long>(colIndex, prop.isPrimary);
        case 'f': return RLMMakeSetter<float>(colIndex, prop.isPrimary);
        case 'd': return RLMMakeSetter<double>(colIndex, prop.isPrimary);
        case 'B': return RLMMakeSetter<bool>(colIndex, prop.isPrimary);
        case 'c': return RLMMakeSetter<BOOL, bool>(colIndex, prop.isPrimary);
        case 'S': return RLMMakeSetter<NSString *>(colIndex, prop.isPrimary);
        case 'a': return RLMMakeSetter<NSDate *>(colIndex, prop.isPrimary);
        case 'e': return RLMMakeSetter<NSData *>(colIndex, prop.isPrimary);
        case 'k': return RLMMakeSetter<RLMObject *>(colIndex, prop.isPrimary);
        case 't': return RLMMakeSetter<RLMArray *>(colIndex, prop.isPrimary);
        case '@': return RLMMakeSetter<id>(colIndex, prop.isPrimary);
        default:
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Invalid accessor code"
                                         userInfo:nil];
    }
}

// call getter for superclass for property at colIndex
static id RLMSuperGet(RLMObject *obj, NSString *propName) {
    typedef id (*getter_type)(RLMObject *, SEL);
    RLMProperty *prop = obj.objectSchema[propName];
    Class superClass = class_getSuperclass(obj.class);
    SEL selector = NSSelectorFromString(prop.getterName);
    getter_type superGetter = (getter_type)[superClass instanceMethodForSelector:selector];
    return superGetter(obj, selector);
}

// call setter for superclass for property at colIndex
static void RLMSuperSet(RLMObject *obj, NSString *propName, id val) {
    typedef id (*setter_type)(RLMObject *, SEL, RLMArray *ar);
    RLMProperty *prop = obj.objectSchema[propName];
    Class superClass = class_getSuperclass(obj.class);
    SEL selector = NSSelectorFromString(prop.setterName);
    setter_type superSetter = (setter_type)[superClass instanceMethodForSelector:selector];
    superSetter(obj, selector, val);
}

// getter/setter for standalone
static IMP RLMAccessorStandaloneGetter(RLMProperty *prop, char accessorCode, NSString *objectClassName) {
    // only override getters for RLMArray properties
    if (accessorCode == 't') {
        NSString *propName = prop.name;
        return imp_implementationWithBlock(^(RLMObject *obj) {
            id val = RLMSuperGet(obj, propName);
            if (!val) {
                val = [RLMArray standaloneArrayWithObjectClassName:objectClassName];
                RLMSuperSet(obj, propName, val);
            }
            return val;
        });
    }
    return nil;
}
static IMP RLMAccessorStandaloneSetter(RLMProperty *prop, char accessorCode) {
    // only override getters for RLMArray properties
    if (accessorCode == 't') {
        NSString *propName = prop.name;
        NSString *objectClassName = prop.objectClassName;
        return imp_implementationWithBlock(^(RLMObject *obj, id<NSFastEnumeration> ar) {
            // make copy when setting (as is the case for all other variants)
            RLMArray *standaloneAr = [RLMArray standaloneArrayWithObjectClassName:objectClassName];
            [standaloneAr addObjectsFromArray:ar];
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
//       the @ type maps to multiple tightdb types (string, date, array, mixed, any which are id in objc)
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
        default: @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid accessor code" userInfo:nil];
    }
}

// setter type strings
// NOTE: this typecode is really the the first charachter of the objc/runtime.h type
//       the @ type maps to multiple tightdb types (string, date, array, mixed, any which are id in objc)
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
        default: @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid accessor code" userInfo:nil];
    }
}

// get accessor lookup code based on objc type and rlm type
static char accessorCodeForType(char objcTypeCode, RLMPropertyType rlmType) {
    switch (objcTypeCode) {
        case '@':               // custom accessors for strings and subtables
            switch (rlmType) {  // custom accessor codes for types that map to objc objects
                case RLMPropertyTypeObject: return 'k';
                case RLMPropertyTypeString: return 'S';
                case RLMPropertyTypeArray: return 't';
                case RLMPropertyTypeDate: return 'a';
                case RLMPropertyTypeData: return 'e';
                case RLMPropertyTypeAny: return '@';
                    
                // throw for all primitive types
                case RLMPropertyTypeBool:
                case RLMPropertyTypeDouble:
                case RLMPropertyTypeFloat:
                case RLMPropertyTypeInt:
                    @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid type for objc typecode" userInfo:nil];
            }
        default:
            return objcTypeCode;
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
                                    IMP (*getterGetter)(RLMProperty *, char, NSString *),
                                    IMP (*setterGetter)(RLMProperty *, char)) {

    // if objectClass is RLMObject then don't create custom accessor (only supports dynamic interface)
    if (objectClass == RLMObject.class) {
        return objectClass;
    }
    
    // throw if no schema, prefix, or object class
    if (!objectClass || !schema || !accessorClassPrefix) {
        @throw [NSException exceptionWithName:@"RLMInternalException" reason:@"Missing arguments" userInfo:nil];
    }
    
    // if objectClass is a dicrect RLMSubclass use it, otherwise use proxy class
    if (class_getSuperclass(objectClass) != RLMObject.class) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"objectClass must derive from RLMObject" userInfo:nil];
    }
    
    // create and register proxy class which derives from object class
    NSString *objectClassName = [objectClass className];
    NSString *accessorClassName = [accessorClassPrefix stringByAppendingString:objectClassName];
    Class accClass = objc_getClass(accessorClassName.UTF8String);
    if (!accClass) {
        accClass = objc_allocateClassPair(objectClass, accessorClassName.UTF8String, 0);
        objc_registerClassPair(accClass);
    }
    
    // override getters/setters for each propery
    for (unsigned int propNum = 0; propNum < schema.properties.count; propNum++) {
        RLMProperty *prop = schema.properties[propNum];
        char accessorCode = accessorCodeForType(prop.objcType, prop.type);
        if (getterGetter) {
            SEL getterSel = NSSelectorFromString(prop.getterName);
            IMP getterImp = getterGetter(prop, accessorCode, prop.objectClassName);
            if (getterImp) {
                class_replaceMethod(accClass, getterSel, getterImp, getterTypeStringForObjcCode(prop.objcType));
            }
        }
        if (setterGetter) {
            SEL setterSel = NSSelectorFromString(prop.setterName);
            IMP setterImp = setterGetter(prop, accessorCode);
            if (setterImp) {
                class_replaceMethod(accClass, setterSel, setterImp, setterTypeStringForObjcCode(prop.objcType));
            }
        }
    }
    
    // implement className for accessor to return base className
    RLMReplaceClassNameMethod(accClass, schema.className);

    return accClass;
}

Class RLMAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema) {
    return RLMCreateAccessorClass(objectClass, schema, @"RLMAccessor_",
                                  RLMAccessorGetter, RLMAccessorSetter);
}

Class RLMStandaloneAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema) {
    return RLMCreateAccessorClass(objectClass, schema, @"RLMStandalone_",
                                  RLMAccessorStandaloneGetter, RLMAccessorStandaloneSetter);
}

void RLMDynamicValidatedSet(RLMObject *obj, NSString *propName, id val) {
    RLMObjectSchema *schema = obj.objectSchema;
    RLMProperty *prop = schema[propName];
    if (!prop) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Invalid property name"
                                     userInfo:@{@"Property name:" : propName ?: @"nil",
                                                @"Class name": [obj.class className]}];
    }
    if (!RLMIsObjectValidForProperty(val, prop)) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Invalid value for property"
                                     userInfo:@{@"Property name:" : propName ?: @"nil",
                                                @"Value": val ? [val description] : @"nil"}];
    }
    RLMDynamicSet(obj, prop, val, prop.isPrimary, false);
}

void RLMDynamicSet(__unsafe_unretained RLMObject *obj, __unsafe_unretained RLMProperty *prop, __unsafe_unretained id val,
                   bool enforceUnique, bool tryUpdate) {
    NSUInteger col = prop.column;
    switch (accessorCodeForType(prop.objcType, prop.type)) {
        case 's':
        case 'i':
        case 'l':
        case 'q':
            if (enforceUnique) {
                RLMSetValueUnique(obj, col, prop.name, [val longLongValue]);
            }
            else {
                RLMSetValue(obj, col, [val longLongValue]);
            }
            break;
        case 'f':
            RLMSetValue(obj, col, [val floatValue]);
            break;
        case 'd':
            RLMSetValue(obj, col, [val doubleValue]);
            break;
        case 'B':
        case 'c':
            RLMSetValue(obj, col, (bool)[val boolValue]);
            break;
        case 'S':
            if (enforceUnique) {
                RLMSetValueUnique(obj, col, prop.name, (NSString *)val);
            }
            else {
                RLMSetValue(obj, col, (NSString *)val);
            }
            break;
        case 'a':
            RLMSetValue(obj, col, (NSDate *)val);
            break;
        case 'e':
            RLMSetValue(obj, col, (NSData *)val);
            break;
        case 'k':
            RLMSetValue(obj, col, (RLMObject *)val, tryUpdate);
            break;
        case 't':
            RLMSetValue(obj, col, (RLMArray *)val, tryUpdate);
            break;
        case '@':
            RLMSetValue(obj, col, val);
            break;
        default:
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Invalid accessor code"
                                         userInfo:nil];
    }
}

id RLMDynamicGet(__unsafe_unretained RLMObject *obj, __unsafe_unretained NSString *propName) {
    RLMProperty *prop = obj.objectSchema[propName];
    if (!prop) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Invalid property name"
                                     userInfo:@{@"Property name:" : propName ?: @"nil",
                                                @"Class name": [obj.class className]}];
    }
    NSUInteger col = prop.column;
    switch (accessorCodeForType(prop.objcType, prop.type)) {
        case 's': return @((short)RLMGetLong(obj, col));
        case 'i': return @((int)RLMGetLong(obj, col));
        case 'l': return @((long)RLMGetLong(obj, col));
        case 'q': return @(RLMGetLong(obj, col));
        case 'f': return @(RLMGetFloat(obj, col));
        case 'd': return @(RLMGetDouble(obj, col));
        case 'B': return @(RLMGetBool(obj, col));
        case 'c': return @(RLMGetBool(obj, col));
        case 'S': return RLMGetString(obj, col);
        case 'a': return RLMGetDate(obj, col);
        case 'e': return RLMGetData(obj, col);
        case 'k': return RLMGetLink(obj, col, prop.objectClassName);
        case 't': return RLMGetArray(obj, col, prop.objectClassName);
        case '@': return RLMGetAnyProperty(obj, col);
        default:
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Invalid accessor code"
                                         userInfo:nil];
    }
}
