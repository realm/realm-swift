////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMAccesor.h"
#import "RLMPrivate.hpp"
#import "RLMUtil.h"
#import "RLMProperty.h"
#import "RLMObjectDescriptor.h"

#import <objc/runtime.h>

static NSMapTable *s_accessorCache;
static NSMapTable *s_readOnlyAccessorCache;
static NSMapTable *s_invalidAccessorCache;

// initialize statics
void RLMAccessorCacheInitialize() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_accessorCache = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaquePersonality
                                                valueOptions:NSPointerFunctionsOpaquePersonality];
        s_readOnlyAccessorCache = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaquePersonality
                                                        valueOptions:NSPointerFunctionsOpaquePersonality];
        s_invalidAccessorCache = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaquePersonality
                                                       valueOptions:NSPointerFunctionsOpaquePersonality];
    });
}

// dynamic getter with column closure
IMP RLMAccessorGetter(NSUInteger col, char accessorCode) {
    switch (accessorCode) {
        case 'i':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
                return (int)obj.backingTable->get_int(col, obj.objectIndex);
            });
        case 'l':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
                return obj.backingTable->get_int(col, obj.objectIndex);
            });
        case 'f':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
                return obj.backingTable->get_float(col, obj.objectIndex);
            });
        case 'd':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
                return obj.backingTable->get_double(col, obj.objectIndex);
            });
        case 'B':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
                return obj.backingTable->get_bool(col, obj.objectIndex);
            });
        case 'c':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
                return obj.backingTable->get_bool(col, obj.objectIndex);
            });
        case 's':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
                tightdb::StringData strData = obj.backingTable->get_string(col, obj.objectIndex);
                return [[NSString alloc] initWithBytes:strData.data()
                                                length:strData.size()
                                              encoding:NSUTF8StringEncoding];
            });
        case 'a':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
                tightdb::DateTime dt = obj.backingTable->get_datetime(col, obj.objectIndex);
                return [NSDate dateWithTimeIntervalSince1970:dt.get_datetime()];
            });
        case 'k':
            //            return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
            //                NSUInteger index = obj.backingTable->get_link(col, obj.objectIndex);
            //                return RLMCreateAccessor(linkClass, obj, index);
            //            });
            @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                           reason:@"Links not yest supported" userInfo:nil];
        case '@':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
                return obj[col];
            });
        case 't':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
                RLMArray *array = obj[col];
                return array;
            });
        default:
            @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid accessor code" userInfo:nil];
    }
}

// dynamic setter with column closure
IMP RLMAccessorSetter(NSUInteger col, char accessorCode) {
    switch (accessorCode) {
        case 'i':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, int val) {
                obj.backingTable->set_int(col, obj.objectIndex, val);
            });
        case 'l':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, long val) {
                obj.backingTable->set_int(col, obj.objectIndex, val);
            });
        case 'f':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, float val) {
                obj.backingTable->set_float(col, obj.objectIndex, val);
            });
        case 'd':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, double val) {
                obj.backingTable->set_double(col, obj.objectIndex, val);
            });
        case 'B':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, bool val) {
                obj.backingTable->set_bool(col, obj.objectIndex, val);
            });
        case 'c':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, BOOL val) {
                obj.backingTable->set_bool(col, obj.objectIndex, val);
            });
        case 's':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, NSString *val) {
                tightdb::StringData strData = tightdb::StringData(val.UTF8String, val.length);
                obj.backingTable->set_string(col, obj.objectIndex, strData);
            });
        case 'a':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, NSDate *date) {
                std::time_t time = date.timeIntervalSince1970;
                obj.backingTable->set_datetime(col, obj.objectIndex, tightdb::DateTime(time));
            });
        case 'k':
            //            return imp_implementationWithBlock(^(id<RLMAccessor> obj, RLMObject *link) {
            //                // add to Realm if not it it.
            //                if (link && link.realm != obj.realm) {
            //                    [obj.realm addObject:link];
            //                }
            //                obj.backingTable->set_link(col, obj.objectIndex, link.objectIndex);
            //            });
            @throw [NSException exceptionWithName:@"RLMNotImplementedException"
                                           reason:@"Links not yest supported" userInfo:nil];
        case '@':
        case 't':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, id val) {
                obj[col] = val;
            });
        default:
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Invalid accessor code"
                                         userInfo:nil];
    }
}


// setter which throws exception
IMP RLMAccessorExceptionSetter(NSUInteger col, char accessorCode, NSString *message) {
    switch (accessorCode) {
        case 'i':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, int val) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        case 'l':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, long val) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        case 'f':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, float val) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        case 'd':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, double val) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        case 'B':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, bool val) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        case 'c':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, BOOL val) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        case 's':
        case 'a':
        case 'k':
        case '@':
        case 't':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj, id val) {
                @throw [NSException exceptionWithName:@"RLMException" reason:message userInfo:nil]; });
        default:
            @throw [NSException exceptionWithName:@"RLMException"
                                           reason:@"Invalid accessor code"
                                         userInfo:nil];
    }
}

// getter for invalid objects
NSString *const c_invalidObjectMessage = @"Object is no longer valid.";
IMP RLMAccessorInvalidGetter(NSUInteger col, char accessorCode) {
    return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
        @throw [NSException exceptionWithName:@"RLMException" reason:c_invalidObjectMessage userInfo:nil];
    });
}

// setter for invalid objects
IMP RLMAccessorInvalidSetter(NSUInteger col, char accessorCode) {
    return RLMAccessorExceptionSetter(col, accessorCode, c_invalidObjectMessage);
}

// setter for readonly objects
IMP RLMAccessorReadOnlySetter(NSUInteger col, char accessorCode) {
    return RLMAccessorExceptionSetter(col, accessorCode, @"Trying to set a property on a read-only object.");
}


// macros/helpers to generate objc type strings for registering methods
#define GETTER_TYPES(C) C ":@"
#define SETTER_TYPES(C) "v:@" C

// getter type strings
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
char accessorCodeForType(char objcTypeCode, RLMType rlmType) {
    switch (objcTypeCode) {
        case 'q':           // long long same as long
            return 'l';
        case '@':           // custom accessors for strings and subtables
            if (rlmType == RLMTypeString) return 's';
            if (rlmType == RLMTypeTable) return 't';
            if (rlmType == RLMTypeDate) return 'a';
            if (rlmType == RLMTypeLink) return 'k';
        default:
            return objcTypeCode;
    }
}

Class RLMCreateAccessor(Class objectClass,
                        NSString *accessorClassPrefix,
                        IMP (*getterGetter)(NSUInteger, char),
                        IMP (*setterGetter)(NSUInteger, char))
{
    // if objectClass is RLMRow use it, otherwise use proxy class
    if (!RLMIsSubclass(objectClass, RLMObject.class)) {
        @throw [NSException exceptionWithName:@"RLMException" reason:@"objectClass must derive from RLMObject" userInfo:nil];
    }
    
    // create and register proxy class which derives from object class
    NSString *accessorClassName = [accessorClassPrefix stringByAppendingString:NSStringFromClass(objectClass)];
    Class proxyClass = objc_allocateClassPair(objectClass, accessorClassName.UTF8String, 0);
    objc_registerClassPair(proxyClass);
    
    // override getters/setters for each propery
    RLMObjectDescriptor *descriptor = [RLMObjectDescriptor descriptorForObjectClass:objectClass];
    for (unsigned int propNum = 0; propNum < descriptor.properties.count; propNum++) {
        RLMProperty *prop = descriptor.properties[propNum];
        SEL getterSel = NSSelectorFromString(prop.getterName);
        SEL setterSel = NSSelectorFromString(prop.setterName);
        IMP getterImp = getterGetter(prop.column, accessorCodeForType(prop.objcType, prop.type));
        IMP setterImp = setterGetter(prop.column, accessorCodeForType(prop.objcType, prop.type));
        class_replaceMethod(proxyClass, getterSel, getterImp, getterTypeStringForObjcCode(prop.objcType));
        class_replaceMethod(proxyClass, setterSel, setterImp, setterTypeStringForObjcCode(prop.objcType));
    }
    return proxyClass;
}

Class RLMAccessorClassForObjectClass(Class objectClass) {
    // see if we have a cached version
    if (Class cls = [s_accessorCache objectForKey:objectClass]) {
        return cls;
    }

    // create accessor and cache
    Class accessorClass = RLMCreateAccessor(objectClass, @"RLMAccessor_", RLMAccessorGetter, RLMAccessorSetter);
    [s_accessorCache setObject:accessorClass forKey:objectClass];
    return accessorClass;
}

Class RLMReadOnlyAccessorClassForObjectClass(Class objectClass) {
    // see if we have a cached version
    if (Class cls = [s_readOnlyAccessorCache objectForKey:objectClass]) {
        return cls;
    }
    
    // create accessor and cache
    Class accessorClass = RLMCreateAccessor(objectClass, @"RLMReadOnly_",
                                            RLMAccessorGetter, RLMAccessorReadOnlySetter);
    [s_readOnlyAccessorCache setObject:accessorClass forKey:objectClass];
    return accessorClass;
}

Class RLMInvalidAccessorClassForObjectClass(Class objectClass) {
    // see if we have a cached version
    if (Class cls = [s_invalidAccessorCache objectForKey:objectClass]) {
        return cls;
    }
    
    // create accessor and cache
    Class accessorClass = RLMCreateAccessor(objectClass, @"RLMInvalid_",
                                            RLMAccessorInvalidGetter, RLMAccessorInvalidSetter);
    [s_invalidAccessorCache setObject:accessorClass forKey:objectClass];
    return accessorClass;
}


