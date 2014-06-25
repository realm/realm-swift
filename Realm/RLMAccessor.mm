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
#import "RLMSchema_Private.h"

#import <objc/runtime.h>

enum RLMAccessorTypes {
    RLMAccessorTypeNormal = 0,
    RLMAccessorTypeInvalid,
    RLMAccessorTypeReadOnly,
    RLMAccessorTypeInsertion,
    RLMAccessorTypeStandalone,
    RLMNumAccessorTypes
};

// accessor caches by type
static NSMapTable *s_accessorCaches[RLMNumAccessorTypes];

// initialize statics
void RLMAccessorCacheInitialize() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        for (NSUInteger i = 0; i < RLMNumAccessorTypes; i++) {
            s_accessorCaches[i] = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaquePersonality
                                                        valueOptions:NSPointerFunctionsOpaquePersonality];
        }
    });
}

// dynamic getter with column closure
IMP RLMAccessorGetter(NSUInteger col, char accessorCode, NSString *objectClassName) {
    switch (accessorCode) {
        case 'i':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return (int)obj->_row.get_int(col);
            });
        case 'l':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return obj->_row.get_int(col);
            });
        case 'f':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return obj->_row.get_float(col);
            });
        case 'd':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return obj->_row.get_double(col);
            });
        case 'B':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return obj->_row.get_bool(col);
            });
        case 'c':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return obj->_row.get_bool(col);
            });
        case 's':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return RLMStringDataToNSString(obj->_row.get_string(col));
            });
        case 'a':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                tightdb::DateTime dt = obj->_row.get_datetime(col);
                return [NSDate dateWithTimeIntervalSince1970:dt.get_datetime()];
            });
        case 'e':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                tightdb::BinaryData data = obj->_row.get_binary(col);
                return [NSData dataWithBytes:data.data() length:data.size()];
            });
        case 'k':
            return imp_implementationWithBlock(^id(RLMObject *obj) {
                if (obj->_row.is_null_link(col)) {
                    return nil;
                }
                NSUInteger index = obj->_row.get_link(col);
                return RLMCreateObjectAccessor(obj.realm, objectClassName, index);
            });
        case 't':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                tightdb::LinkViewRef linkView = obj->_row.get_linklist(col);
                RLMArrayLinkView *ar = [RLMArrayLinkView arrayWithObjectClassName:objectClassName
                                                                             view:linkView
                                                                            realm:obj.realm];
                return ar;
            });
        case '@':
            return imp_implementationWithBlock(^(RLMObject *obj) {
                return RLMGetAnyProperty(obj->_row, col);
            });
        default:
            @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid accessor code" userInfo:nil];
    }
}

// dynamic setter with column closure
IMP RLMAccessorSetter(NSUInteger col, char accessorCode) {
    switch (accessorCode) {
        case 'i':
            return imp_implementationWithBlock(^(RLMObject *obj, int val) {
                obj->_row.set_int(col, val);
            });
        case 'l':
            return imp_implementationWithBlock(^(RLMObject *obj, long val) {
                obj->_row.set_int(col, val);
            });
        case 'f':
            return imp_implementationWithBlock(^(RLMObject *obj, float val) {
                obj->_row.set_float(col, val);
            });
        case 'd':
            return imp_implementationWithBlock(^(RLMObject *obj, double val) {
                obj->_row.set_double(col, val);
            });
        case 'B':
            return imp_implementationWithBlock(^(RLMObject *obj, bool val) {
                obj->_row.set_bool(col, val);
            });
        case 'c':
            return imp_implementationWithBlock(^(RLMObject *obj, BOOL val) {
                obj->_row.set_bool(col, val);
            });
        case 's':
            return imp_implementationWithBlock(^(RLMObject *obj, NSString *val) {
                obj->_row.set_string(col, RLMStringDataWithNSString(val));
            });
        case 'a':
            return imp_implementationWithBlock(^(RLMObject *obj, NSDate *date) {
                std::time_t time = date.timeIntervalSince1970;
                obj->_row.set_datetime(col, tightdb::DateTime(time));
            });
        case 'e':
            return imp_implementationWithBlock(^(RLMObject *obj, NSData *data) {
                obj->_row.set_binary(col, RLMBinaryDataForNSData(data));
            });
        case 'k':
            return imp_implementationWithBlock(^(RLMObject *obj, RLMObject *link) {
                if (!link || link.class == NSNull.class) {
                    // if null
                    obj->_row.nullify_link(col);
                }
                else {
                    // add to Realm if not in it.
                    if (link.realm != obj.realm) {
                        [obj.realm addObject:link];
                    }
                    // set link
                    obj->_row.set_link(col, link->_row.get_index());
                }
            });
        case 't':
            return imp_implementationWithBlock(^(RLMObject *obj, id<NSFastEnumeration> val) {
                tightdb::LinkViewRef linkView = obj->_row.get_linklist(col);
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
            });
        case '@':
            return imp_implementationWithBlock(^(RLMObject *obj, id val) {
                RLMSetAnyProperty(obj->_row, col, val);
            });
        default:
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Invalid accessor code"
                                         userInfo:nil];
    }
}


// setter which throws exception
IMP RLMAccessorExceptionSetter(NSUInteger, char accessorCode, NSString *message) {
    switch (accessorCode) {
        case 'i':
            return imp_implementationWithBlock(^(id<RLMAccessor>, int) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        case 'l':
            return imp_implementationWithBlock(^(id<RLMAccessor>, long) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        case 'f':
            return imp_implementationWithBlock(^(id<RLMAccessor>, float) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        case 'd':
            return imp_implementationWithBlock(^(id<RLMAccessor>, double) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        case 'B':
            return imp_implementationWithBlock(^(id<RLMAccessor>, bool) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        case 'c':
            return imp_implementationWithBlock(^(id<RLMAccessor>, BOOL) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        case 's':
        case 'a':
        case 'k':
        case 'e':
        case '@':
        case 't':
            return imp_implementationWithBlock(^(id<RLMAccessor>, id) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        default:
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Invalid accessor code"
                                         userInfo:nil];
    }
}

// getter for invalid objects
NSString *const c_invalidObjectMessage = @"Object is no longer valid.";
IMP RLMAccessorInvalidGetter(NSUInteger, char, NSString *) {
    return imp_implementationWithBlock(^(id<RLMAccessor>) {
        @throw [NSException exceptionWithName:@"RLMException" reason:c_invalidObjectMessage userInfo:nil];
    });
}

// setter for invalid objects
IMP RLMAccessorInvalidSetter(NSUInteger col, char accessorCode) {
    return RLMAccessorExceptionSetter(col, accessorCode, c_invalidObjectMessage);
}

// getter for standalone
IMP RLMAccessorStandaloneGetter(NSUInteger col, char accessorCode, NSString *objectClassName) {
    // only override getters for RLMArray properties
    if (accessorCode == 't') {
        return imp_implementationWithBlock(^(RLMObject *obj) {
            typedef id (*getter_type)(RLMObject *, SEL);
            RLMProperty *prop = obj.RLMObject_schema.properties[col];
            Class superClass = class_getSuperclass(obj.class);
            getter_type superGetter = (getter_type)class_getMethodImplementation(superClass, NSSelectorFromString(prop.getterName));
            id val = superGetter(obj, NSSelectorFromString(prop.getterName));
            if (!val) {
                SEL setterSel = NSSelectorFromString(prop.setterName);
                typedef void (*setter_type)(RLMObject *, SEL, id);
                setter_type setter = (setter_type)class_getMethodImplementation(obj.class, setterSel);
                val = [RLMArray standaloneArrayWithObjectClassName:objectClassName];
                setter(obj, setterSel, val);
            }
            return val;
        });
    }
    return nil;
}

// setter for readonly objects
IMP RLMAccessorReadOnlySetter(NSUInteger col, char accessorCode) {
    return RLMAccessorExceptionSetter(col, accessorCode, @"Trying to set a property on a read-only object.");
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
inline void RLMImplementClassNameMethod(Class accessorClass, NSString *className) {
    Class metaClass = objc_getMetaClass(class_getName(accessorClass));
    IMP imp = imp_implementationWithBlock(^{ return className; });
    class_replaceMethod(metaClass, @selector(className), imp, "@:");
}

Class RLMCreateAccessorClass(Class objectClass,
                             RLMObjectSchema *schema,
                             NSString *accessorClassPrefix,
                             IMP (*getterGetter)(NSUInteger, char, NSString *),
                             IMP (*setterGetter)(NSUInteger, char),
                             NSMapTable *cache) {
    // return cached
    if (Class cls = [cache objectForKey:objectClass]) {
        return cls;
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
    NSString *objectClassName = NSStringFromClass(objectClass);
    NSString *accessorClassName = [accessorClassPrefix stringByAppendingString:objectClassName];
    Class accClass = objc_allocateClassPair(objectClass, accessorClassName.UTF8String, 0);
    objc_registerClassPair(accClass);
    
    // override getters/setters for each propery
    for (unsigned int propNum = 0; propNum < schema.properties.count; propNum++) {
        RLMProperty *prop = schema.properties[propNum];
        char accessorCode = accessorCodeForType(prop.objcType, prop.type);
        if (getterGetter) {
            SEL getterSel = NSSelectorFromString(prop.getterName);
            IMP getterImp = getterGetter(prop.column, accessorCode, prop.objectClassName);
            if (getterImp) {
                class_replaceMethod(accClass, getterSel, getterImp, getterTypeStringForObjcCode(prop.objcType));
            }
        }
        if (setterGetter) {
            SEL setterSel = NSSelectorFromString(prop.setterName);
            IMP setterImp = setterGetter(prop.column, accessorCode);
            if (setterImp) {
                class_replaceMethod(accClass, setterSel, setterImp, setterTypeStringForObjcCode(prop.objcType));
            }
        }
    }
    
    // implement className for accessor to return base className
    RLMImplementClassNameMethod(accClass, schema.className);
    
    // cache and return
    [cache setObject:accClass forKey:objectClass];
    return accClass;
}

Class RLMAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema) {
    return RLMCreateAccessorClass(objectClass, schema, @"RLMAccessor_",
                                  RLMAccessorGetter, RLMAccessorSetter, s_accessorCaches[RLMAccessorTypeNormal]);
}

Class RLMReadOnlyAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema) {
    return RLMCreateAccessorClass(objectClass, schema, @"RLMReadOnly_",
                                  RLMAccessorGetter, RLMAccessorReadOnlySetter, s_accessorCaches[RLMAccessorTypeReadOnly]);
}

Class RLMInvalidAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema) {
    return RLMCreateAccessorClass(objectClass, schema, @"RLMInvalid_",
                                  RLMAccessorInvalidGetter, RLMAccessorInvalidSetter, s_accessorCaches[RLMAccessorTypeInvalid]);
}

Class RLMInsertionAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema) {
    return RLMCreateAccessorClass(objectClass, schema, @"RLMInserter_",
                                  NULL, RLMAccessorSetter, s_accessorCaches[RLMAccessorTypeInsertion]);
}

Class RLMStandaloneAccessorClassForObjectClass(Class objectClass, RLMObjectSchema *schema) {
    return RLMCreateAccessorClass(objectClass, schema, @"RLMStandalone_",
                                  RLMAccessorStandaloneGetter, NULL, s_accessorCaches[RLMAccessorTypeStandalone]);
}

// Dynamic accessor name for a classname
inline NSString *RLMDynamicClassName(NSString *className, NSUInteger version) {
    return [NSString stringWithFormat:@"RLMDynamic_%@_Version_%lu", className, (unsigned long)version];
}

// Get or generate a dynamic class from a table and classname
Class RLMDynamicClassForSchema(RLMObjectSchema *schema, NSUInteger version) {
    // generate our new classname, and check if it exists
    NSString *dynamicName = RLMDynamicClassName(schema.className, version);
    Class dynamicClass = RLMClassFromString(dynamicName);
    if (!dynamicClass) {
        // if we don't have this class, create a subclass or RLMObject
        dynamicClass = objc_allocateClassPair(RLMObject.class, dynamicName.UTF8String, 0);
        objc_registerClassPair(dynamicClass);
        
        // implement className for accessor to return base className
        RLMImplementClassNameMethod(dynamicClass, schema.className);
    }
    return dynamicClass;
}


