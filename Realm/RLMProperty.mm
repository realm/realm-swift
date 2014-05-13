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
#import "RLMProperty.h"
#import "RLMObjectDescriptor.h"
#import "RLMPrivate.hpp"
#import "RLMUtil.h"

// macros/helpers to generate objc type strings for registering methods
#define GETTER_TYPES(C) C ":@"
#define SETTER_TYPES(C) "v:@" C

// getter type strings
const char * getterTypeStringForCode(char code) {
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
const char * setterTypeStringForCode(char code) {
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

// private properties
@interface RLMProperty ()
@property (nonatomic, assign) BOOL dynamic;
@property (nonatomic, assign) BOOL nonatomic;
@property (nonatomic, copy) NSString * getterName;
@property (nonatomic, copy) NSString * setterName;
@end

@implementation RLMProperty

@synthesize getterName = _getterName;
@synthesize setterName = _setterName;

// get accessor lookup code based on objc type and rlm type
-(char)accessorCode {
    switch (self.objcType) {
        case 'q':           // long long same as long
            return 'l';
        case '@':           // custom accessors for strings and subtables
            if (self.type == RLMTypeString) return 's';
            if (self.type == RLMTypeTable) return 't';
            if (self.type == RLMTypeDate) return 'a';
        default:
            return self.objcType;
    }
}

// dynamic getter with column closure
-(IMP)getterForColumn:(NSUInteger)col {
    switch (self.accessorCode) {
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
        case '@':
            return imp_implementationWithBlock(^(id<RLMAccessor> obj) {
                return obj[col];
            });
        case 't':
        {
            return imp_implementationWithBlock(^(id<RLMAccessor> obj){
                RLMArray *array = obj[col];
                return array;
            });
        }
        default:
            @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid accessor code" userInfo:nil];
    }
}


// dynamic setter with column closure
-(IMP)setterForColumn:(int)col {
    switch (self.accessorCode) {
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

// add dynamic property getters/setters to the given class
-(void)addToClass:(Class)cls
{
    // set accessors
    self.column = _column;
    SEL getter = NSSelectorFromString(self.getterName), setter = NSSelectorFromString(self.setterName);
    class_replaceMethod(cls, getter, [self getterForColumn:_column], getterTypeStringForCode(self.objcType));
    class_replaceMethod(cls, setter, [self setterForColumn:_column], setterTypeStringForCode(self.objcType));
}


// determine RLMType from objc code
-(void)parsePropertyTypeString:(const char *)code {
    self.objcType = *(code);    // first char of type attr
    if (self.objcType == 'q') {
        self.objcType = 'l';    // collapse these as they are the same
    }
    
    // map to RLMType
    switch (self.objcType) {
        case 'i':   // int
        case 'l':   // long
            self.type = RLMTypeInt;
            break;
        case 'f':
            self.type = RLMTypeFloat;
            break;
        case 'd':
            self.type = RLMTypeDouble;
            break;
        case 'c':   // BOOL is stored as char - since rlm has no char type this is ok
        case 'B':
            self.type = RLMTypeBool;
            break;
        case '@':
        {
            NSString *type = [NSString stringWithUTF8String:code];
            // if one charachter, this is an untyped id, ie [type isEqualToString:@"@"]
            if (type.length == 1) {
                self.type = RLMTypeMixed;
            }
            else if ([type isEqualToString:@"@\"NSString\""]) {
                self.type = RLMTypeString;
            }
            else if ([type isEqualToString:@"@\"NSDate\""]) {
                self.type = RLMTypeDate;
            }
            else if ([type isEqualToString:@"@\"NSData\""]) {
                self.type = RLMTypeBinary;
            }
            else if ([type hasPrefix:@"@\"RLMArray<"]) {
                // check for array class
                Class cls = NSClassFromString([type substringWithRange:NSMakeRange(11, type.length-5)]);
                if (RLMIsKindOfclass(cls, RLMObject.class)) {
                    self.subtableObjectClass = cls;
                }
                else {
                    @throw [NSException exceptionWithName:@"RLMException" reason:@"No type specified for RLMArray" userInfo:nil];
                }
                self.type = RLMTypeTable;
            }
            break;
        }
        default:
            self.type = RLMTypeNone;
            break;
    }
}

+(instancetype)propertyForObjectProperty:(objc_property_t)runtimeProp column:(NSUInteger)column
{
    // create new property
    RLMProperty *prop = [RLMProperty new];
    prop.name = [NSString stringWithUTF8String:property_getName(runtimeProp)];
    prop.column = column;
    
    // parse attributes
    unsigned int attCount;
    objc_property_attribute_t *atts = property_copyAttributeList(runtimeProp, &attCount);
    for (unsigned int a = 0; a < attCount; a++) {
        switch (*(atts[a].name)) {
            case 'T':
                [prop parsePropertyTypeString:atts[a].value];
                break;
            case 'N':
                prop.nonatomic = YES;
                break;
            case 'D':
                prop.dynamic = YES;
                break;
            case 'G':
                prop.getterName = [NSString stringWithUTF8String:atts[a].value];
                break;
            case 'S':
                prop.setterName = [NSString stringWithUTF8String:atts[a].value];
                break;
            default:
                break;
        }
    }
    free(atts);
    
    // make sure we have a valid type
    if (prop.type == RLMTypeNone) {
        NSString * reason = [NSString stringWithFormat:@"Can't persist property '%@' with incompatible type. "
                             "Add to ignoredPropertyNames: method to ignore.", prop.name];
        @throw [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];
    }
    
    // populate getter/setter names if generic
    if (!prop.getterName) {
        prop.getterName = prop.name;
    }
    if (!prop.setterName) {
        prop.setterName = [NSString stringWithFormat:@"set%c%@:", toupper(prop.name.UTF8String[0]), [prop.name substringFromIndex:1]];
    }
    
    return prop;
}


@end



