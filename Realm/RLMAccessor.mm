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
#import "RLMObject_Private.h"
#import "RLMArray_Private.hpp"
#import "RLMUtil.hpp"
#import "RLMObjectSchema.h"
#import "RLMObjectStore.h"

#import <objc/runtime.h>

// verify attached
inline void RLMVerifyAttached(__unsafe_unretained RLMObject *obj) {
    if (!obj->_row.is_attached()) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Object has been deleted and is no longer valid."
                                     userInfo:nil];
    }
}

// verify writable
inline void RLMVerifyInWriteTransaction(__unsafe_unretained RLMObject *obj) {
    // first verify is attached
    RLMVerifyAttached(obj);

    if (!obj->_realm->_inWriteTransaction) {
        @throw [NSException exceptionWithName:@"RLMException"
                                       reason:@"Attempting to modify object outside of a write transaction - call beginWriteTransaction on a RLMRealm instance first."
                                     userInfo:nil];
    }
}

// long getter/setter
inline long long RLMGetLong(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return obj->_row.get_int(colIndex);
}
inline void RLMSetLong(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, long long val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_int(colIndex, val);
}

// float getter/setter
inline float RLMGetFloat(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return obj->_row.get_float(colIndex);
}
inline void RLMSetFloat(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, float val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_float(colIndex, val);
}

// double getter/setter
inline double RLMGetDouble(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return obj->_row.get_double(colIndex);
}
inline void RLMSetDouble(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, double val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_double(colIndex, val);
}

// bool getter/setter
inline bool RLMGetBool(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return obj->_row.get_bool(colIndex);
}
inline void RLMSetBool(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, bool val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_bool(colIndex, val);
}

// string getter/setter
inline NSString *RLMGetString(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    return RLMStringDataToNSString(obj->_row.get_string(colIndex));
}
inline void RLMSetString(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained NSString *val) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_string(colIndex, RLMStringDataWithNSString(val));
}

// date getter/setter
inline NSDate *RLMGetDate(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    tightdb::DateTime dt = obj->_row.get_datetime(colIndex);
    return [NSDate dateWithTimeIntervalSince1970:dt.get_datetime()];
}
inline void RLMSetDate(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained NSDate *date) {
    RLMVerifyInWriteTransaction(obj);
    std::time_t time = date.timeIntervalSince1970;
    obj->_row.set_datetime(colIndex, tightdb::DateTime(time));
}

// data getter/setter
inline NSData *RLMGetData(__unsafe_unretained RLMObject *obj, NSUInteger colIndex) {
    RLMVerifyAttached(obj);
    tightdb::BinaryData data = obj->_row.get_binary(colIndex);
    return [NSData dataWithBytes:data.data() length:data.size()];
}
inline void RLMSetData(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained NSData *data) {
    RLMVerifyInWriteTransaction(obj);
    obj->_row.set_binary(colIndex, RLMBinaryDataForNSData(data));
}

// link getter/setter
inline RLMObject *RLMGetLink(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained NSString *objectClassName) {
    RLMVerifyAttached(obj);

    if (obj->_row.is_null_link(colIndex)) {
        return nil;
    }
    NSUInteger index = obj->_row.get_link(colIndex);
    return RLMCreateObjectAccessor(obj.realm, objectClassName, index);
}
inline void RLMSetLink(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained id val) {
    RLMVerifyInWriteTransaction(obj);

    if (!val || val == NSNull.null) {
        // if null
        obj->_row.nullify_link(colIndex);
    }
    else {
        // add to Realm if not in it.
        RLMObject *link = val;
        if (link.realm != obj.realm) {
            [obj.realm addObject:link];
        }
        // set link
        obj->_row.set_link(colIndex, link->_row.get_index());
    }
}

// array getter/setter
inline RLMArray *RLMGetArray(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained NSString *objectClassName) {
    RLMVerifyAttached(obj);

    tightdb::LinkViewRef linkView = obj->_row.get_linklist(colIndex);
    RLMArrayLinkView *ar = [RLMArrayLinkView arrayWithObjectClassName:objectClassName
                                                                 view:linkView
                                                                realm:obj.realm];
    return ar;
}
inline void RLMSetArray(__unsafe_unretained RLMObject *obj, NSUInteger colIndex, __unsafe_unretained id<NSFastEnumeration> val) {
    RLMVerifyInWriteTransaction(obj);

    tightdb::LinkViewRef linkView = obj->_row.get_linklist(colIndex);
    // remove all old
    // FIXME: make sure delete rules don't purge objects
    linkView->clear();
    for (RLMObject *link in val) {
        // add to realm if needed
        if (link.realm != obj.realm) {
            [obj.realm addObject:link];
        }
        // set in link view
        linkView->add(link->_row.get_index());
    }
}

// any getter/setter
inline id RLMGetAnyProperty(__unsafe_unretained RLMObject *obj, NSUInteger col_ndx) {
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
inline void RLMSetAnyProperty(__unsafe_unretained RLMObject *obj, NSUInteger col_ndx, __unsafe_unretained id val) {
    RLMVerifyInWriteTransaction(obj);

    // FIXME - enable when Any supports links
    //    if (obj == nil) {
    //        table.nullify_link(col_ndx, row_ndx);
    //        return;
    //    }
    if ([val isKindOfClass:[NSString class]]) {
        obj->_row.set_mixed(col_ndx, RLMStringDataWithNSString(val));
        return;
    }
    if ([val isKindOfClass:[NSDate class]]) {
        obj->_row.set_mixed(col_ndx, tightdb::DateTime(time_t([(NSDate *)val timeIntervalSince1970])));
        return;
    }
    if ([val isKindOfClass:[NSData class]]) {
        obj->_row.set_mixed(col_ndx, RLMBinaryDataForNSData(val));
        return;
    }
    if ([val isKindOfClass:[NSNumber class]]) {
        const char *data_type = [(NSNumber *)val objCType];
        const char dt = data_type[0];
        switch (dt) {
            case 'i':
            case 's':
            case 'l':
            case 'q':
                obj->_row.set_mixed(col_ndx, (int64_t)[(NSNumber *)val longValue]);
                return;
            case 'f':
                obj->_row.set_mixed(col_ndx, [(NSNumber *)val floatValue]);
                return;
            case 'd':
                obj->_row.set_mixed(col_ndx, [(NSNumber *)val doubleValue]);
                return;
            case 'B':
            case 'c':
                obj->_row.set_mixed(col_ndx, [(NSNumber *)val boolValue] == YES);
                return;
        }
    }
    @throw [NSException exceptionWithName:@"RLMException" reason:@"Inserting invalid object for RLMPropertyTypeAny property" userInfo:nil];
}

// dynamic getter with column closure
IMP RLMAccessorGetter(RLMProperty *prop, char accessorCode, NSString *objectClassName) {
    NSUInteger colIndex = prop.column;
    switch (accessorCode) {
        case 'i':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return (int)RLMGetLong(obj, colIndex);
            });
        case 'l':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return RLMGetLong(obj, colIndex);
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
        case 's':
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

// dynamic setter with column closure
IMP RLMAccessorSetter(RLMProperty *prop, char accessorCode) {
    NSUInteger colIndex = prop.column;
    switch (accessorCode) {
        case 'i':
            return imp_implementationWithBlock(^(RLMObject *obj, int val) {
                RLMSetLong(obj, colIndex, val);
            });
        case 'l':
            return imp_implementationWithBlock(^(RLMObject *obj, long val) {
                RLMSetLong(obj, colIndex, val);
            });
        case 'f':
            return imp_implementationWithBlock(^(RLMObject *obj, float val) {
                RLMSetFloat(obj, colIndex, val);
            });
        case 'd':
            return imp_implementationWithBlock(^(RLMObject *obj, double val) {
                RLMSetDouble(obj, colIndex, val);
            });
        case 'B':
            return imp_implementationWithBlock(^(RLMObject *obj, bool val) {
                RLMSetBool(obj, colIndex, val);
            });
        case 'c':
            return imp_implementationWithBlock(^(RLMObject *obj, BOOL val) {
                RLMSetBool(obj, colIndex, val);
            });
        case 's':
            return imp_implementationWithBlock(^(RLMObject *obj, NSString *val) {
                RLMSetString(obj, colIndex, val);
            });
        case 'a':
            return imp_implementationWithBlock(^(RLMObject *obj, NSDate *date) {
                RLMSetDate(obj, colIndex, date);
            });
        case 'e':
            return imp_implementationWithBlock(^(RLMObject *obj, NSData *data) {
                RLMSetData(obj, colIndex, data);
            });
        case 'k':
            return imp_implementationWithBlock(^(RLMObject *obj, RLMObject *link) {
                RLMSetLink(obj, colIndex, link);
            });
        case 't':
            return imp_implementationWithBlock(^(RLMObject *obj, RLMArray *val) {
                RLMSetArray(obj, colIndex, val);
            });
        case '@':
            return imp_implementationWithBlock(^(RLMObject *obj, id val) {
                RLMSetAnyProperty(obj, colIndex, val);
            });
        default:
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Invalid accessor code"
                                         userInfo:nil];
    }
}

// call getter for superclass for property at colIndex
id RLMSuperGet(RLMObject *obj, NSString *propName) {
    typedef id (*getter_type)(RLMObject *, SEL);
    RLMProperty *prop = obj.objectSchema[propName];
    Class superClass = class_getSuperclass(obj.class);
    SEL selector = NSSelectorFromString(prop.getterName);
    getter_type superGetter = (getter_type)[superClass instanceMethodForSelector:selector];
    return superGetter(obj, selector);
}

// call setter for superclass for property at colIndex
void RLMSuperSet(RLMObject *obj, NSString *propName, id val) {
    typedef id (*setter_type)(RLMObject *, SEL, RLMArray *ar);
    RLMProperty *prop = obj.objectSchema[propName];
    Class superClass = class_getSuperclass(obj.class);
    SEL selector = NSSelectorFromString(prop.setterName);
    setter_type superSetter = (setter_type)[superClass instanceMethodForSelector:selector];
    superSetter(obj, selector, val);
}

// getter/setter for standalone
IMP RLMAccessorStandaloneGetter(RLMProperty *prop, char accessorCode, NSString *objectClassName) {
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
IMP RLMAccessorStandaloneSetter(RLMProperty *prop, char accessorCode) {
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
const char * getterTypeStringForObjcCode(char code) {
    switch (code) {
        case 'i': return GETTER_TYPES("i");
        case 'l': return GETTER_TYPES("l");
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
const char * setterTypeStringForObjcCode(char code) {
    switch (code) {
        case 'i': return SETTER_TYPES("i");
        case 'l': return SETTER_TYPES("l");
        case 'f': return SETTER_TYPES("f");
        case 'd': return SETTER_TYPES("d");
        case 'B': return SETTER_TYPES("B");
        case 'c': return SETTER_TYPES("c");
        case '@': return SETTER_TYPES("@");
        default: @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid accessor code" userInfo:nil];
    }
}

// get accessor lookup code based on objc type and rlm type
char accessorCodeForType(char objcTypeCode, RLMPropertyType rlmType) {
    switch (objcTypeCode) {
        case 'q': return 'l';   // long long same as long
        case '@':               // custom accessors for strings and subtables
            switch (rlmType) {  // custom accessor codes for types that map to objc objects
                case RLMPropertyTypeObject: return 'k';
                case RLMPropertyTypeString: return 's';
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
    class_replaceMethod(metaClass, @selector(className), imp, "@:");
}

// implement the shared schema method
void RLMReplaceSharedSchemaMethod(Class accessorClass, RLMObjectSchema *schema) {
    Class metaClass = objc_getMetaClass(class_getName(accessorClass));
    IMP imp = imp_implementationWithBlock(^{ return schema; });
    class_replaceMethod(metaClass, @selector(sharedSchema), imp, "@:");
}

Class RLMCreateAccessorClass(Class objectClass,
                             RLMObjectSchema *schema,
                             NSString *accessorClassPrefix,
                             IMP (*getterGetter)(RLMProperty *, char, NSString *),
                             IMP (*setterGetter)(RLMProperty *, char)) {

    // if objectClass is RLMObject then don't create custom accessor (only supports dynamic interface)
    if (RLMIsObjectClass(objectClass)) {
        return objectClass;
    }
    
    // throw if no schema, prefix, or object class
    if (!objectClass || !schema || !accessorClassPrefix) {
        @throw [NSException exceptionWithName:@"RLMInternalException" reason:@"Missing arguments" userInfo:nil];
    }
    
    // if objectClass is a dicrect RLMSubclass use it, otherwise use proxy class
    if (!RLMIsObjectSubclass(objectClass)) {
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

// Dynamic accessor name for a classname
inline NSString *RLMDynamicClassName(NSString *className, NSUInteger version) {
    return [NSString stringWithFormat:@"RLMDynamic_%@_Version_%lu", className, (unsigned long)version];
}


void RLMDynamicValidatedSet(RLMObject *obj, NSString *propName, id val) {
    RLMProperty *prop = obj.objectSchema[propName];
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
    RLMDynamicSet(obj, (RLMProperty *)prop, val);
}

void RLMDynamicSet(__unsafe_unretained RLMObject *obj, __unsafe_unretained RLMProperty *prop, __unsafe_unretained id val) {
    NSUInteger col = prop.column;
    switch (accessorCodeForType(prop.objcType, prop.type)) {
        case 'i':
        case 'l':
            RLMSetLong(obj, col, [val longLongValue]);
            break;
        case 'f':
            RLMSetFloat(obj, col, [val floatValue]);
            break;
        case 'd':
            RLMSetDouble(obj, col, [val doubleValue]);
            break;
        case 'B':
        case 'c':
            RLMSetBool(obj, col, (bool)[val boolValue]);
            break;
        case 's':
            RLMSetString(obj, col, val);
            break;
        case 'a':
            RLMSetDate(obj, col, val);
            break;
        case 'e':
            RLMSetData(obj, col, val);
            break;
        case 'k':
            RLMSetLink(obj, col, val);
            break;
        case 't':
            RLMSetArray(obj, col, val);
            break;
        case '@':
            RLMSetAnyProperty(obj, col, val);
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
        case 'i': return @((int)RLMGetLong(obj, col));
        case 'l': return @(RLMGetLong(obj, col));
        case 'f': return @(RLMGetFloat(obj, col));
        case 'd': return @(RLMGetDouble(obj, col));
        case 'B': return @(RLMGetBool(obj, col));
        case 'c': return @(RLMGetBool(obj, col));
        case 's': return RLMGetString(obj, col);
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
