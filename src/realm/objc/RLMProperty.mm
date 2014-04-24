/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of TightDB Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to TightDB Incorporated
 * and its suppliers and may be covered by U.S. and Foreign Patents,
 * patents in process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from TightDB Incorporated.
 *
 **************************************************************************/
#import "RLMProperty.h"
#import "RLMProxy.h"
#import "RLMObjectDescriptor.h"
#import "RLMTable.h"
#import "RLMFast.h"
#import "RLMRowFast.h"
#import "RLMTable_noinst.h"
#import "util_noinst.hpp"


// in RLMProxy.m
extern BOOL is_class_subclass(Class class1, Class class2);

// determine RLMType from objc code
void typeForPropertyString(const char *code,
                           RLMType *outtype,
                           Class *outSubtableObjectClass) {
    if (!code) {
        *outtype = RLMTypeNone;
        return;
    }
    
    switch (*code) {
        case 'i':   // int
        case 'l':   // long
        case 'q':   // long long
            *outtype = RLMTypeInt;
            break;
        case 'f':
            *outtype = RLMTypeFloat;
            break;
        case 'd':
            *outtype = RLMTypeDouble;
            break;
        case 'c':   // BOOL is stored as char - since rlm has no char type this is ok
        case 'B':
            *outtype = RLMTypeBool;
            break;
        case '@':
        {
            NSString *type = [NSString stringWithUTF8String:code];
            if ([type isEqualToString:@"@\"NSString\""]) *outtype = RLMTypeString;
            else if ([type isEqualToString:@"@\"NSDate\""]) *outtype = RLMTypeDate;
            else if ([type isEqualToString:@"@\"NSData\""]) *outtype = RLMTypeBinary;
            else {
                // check for subtable
                Class cls = NSClassFromString([type substringWithRange:NSMakeRange(2, type.length-3)]);
                if (is_class_subclass(cls, RLMTable.class)) {
                    *outtype = RLMTypeTable;
                    if ([cls respondsToSelector:@selector(objectClass)]) {
                        *outSubtableObjectClass = [cls performSelector:@selector(objectClass)];
                    }
                }
            }
            break;
        }
        default:
            *outtype = RLMTypeNone;
    }
}

// macros to generate objc type strings when registering methods
#define GETTER_TYPES(C) C ":@"
#define SETTER_TYPES(C) "v:@" C

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

@interface RLMProperty ()
@property (nonatomic, assign) BOOL dynamic;
@property (nonatomic, assign) BOOL nonatomic;
@end

@implementation RLMProperty

// get accessor lookup code based on objc type and rlm type
-(char)accessorCode {
    switch (self.objcType) {
        case 'q':           // long long same as long
            return 'l';
        case '@':
            if (self.type == RLMTypeString) return 's';
            if (self.type == RLMTypeTable) return 't';
        default:
            return self.objcType;
    }
}

// dynamic getter with column closure
-(IMP)getterForColumn:(NSUInteger)col {
    switch (self.accessorCode) {
        case 'i':
            return imp_implementationWithBlock(^(RLMRow *row) {
                return (int)row.table.getNativeTable.get_int(col, row.ndx);
            });
        case 'l':
            return imp_implementationWithBlock(^(RLMRow *row) {
                return row.table.getNativeTable.get_int(col, row.ndx);
            });
        case 'f':
            return imp_implementationWithBlock(^(RLMRow *row) {
                return row.table.getNativeTable.get_float(col, row.ndx);
            });
        case 'd':
            return imp_implementationWithBlock(^(RLMRow *row) {
                return row.table.getNativeTable.get_double(col, row.ndx);
            });
        case 'B':
            return imp_implementationWithBlock(^(RLMRow *row) {
                return row.table.getNativeTable.get_bool(col, row.ndx);
            });
        case 'c':
            return imp_implementationWithBlock(^(RLMRow *row) {
                return (BOOL)row.table.getNativeTable.get_bool(col, row.ndx);
            });
        case 's':
            return imp_implementationWithBlock(^(RLMRow *row) {
                return to_objc_string(row.table.getNativeTable.get_string(col, row.ndx));
            });
        case '@':
            return imp_implementationWithBlock(^(RLMRow *row) {
                return row[col];
            });
        case 't':
        {
            Class subtableObjectClass = self.subtableObjectClass;
            return imp_implementationWithBlock(^(RLMRow *row){
                RLMTable *table = row[col];
                table.objectClass = subtableObjectClass;
                return table;
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
            return imp_implementationWithBlock(^(RLMRow *row, int val) {
                row.table.getNativeTable.set_int(col, row.ndx, val);
            });
        case 'l':
            return imp_implementationWithBlock(^(RLMRow *row, long val) {
                row.table.getNativeTable.set_int(col, row.ndx, val);
            });
        case 'f':
            return imp_implementationWithBlock(^(RLMRow *row, float val) {
                row.table.getNativeTable.set_float(col, row.ndx, val);
            });
        case 'd':
            return imp_implementationWithBlock(^(RLMRow *row, double val) {
                row.table.getNativeTable.set_double(col, row.ndx, val);
            });
        case 'B':
            return imp_implementationWithBlock(^(RLMRow *row, bool val) {
                row.table.getNativeTable.set_bool(col, row.ndx, val);
            });
        case 'c':
            return imp_implementationWithBlock(^(RLMRow *row, BOOL val) {
                row.table.getNativeTable.set_bool(col, row.ndx, val);
            });
        case 's':
            return imp_implementationWithBlock(^(RLMRow *row, NSString *val) {
                [row setString:val inColumnWithIndex:col];
            });
        case '@':
        case 't':
            return imp_implementationWithBlock(^(RLMRow *row, id val) {
                row[col] = val;
            });
        default:
            @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid accessor code" userInfo:nil];
    }
}

// add dynamic property getters/setters to the given class
-(void)addToClass:(Class)cls column:(int)column
{
    // generate getter sel
    // TODO - support custom accessor names
    NSString *propName = self.name;
    SEL get = NSSelectorFromString(propName);
    
    // generate setter sel
    NSString *firstChar = [[propName substringToIndex:1] uppercaseString];
    NSString *rest = [propName substringFromIndex:1];
    NSString *setName = [NSString stringWithFormat:@"set%@%@:", firstChar, rest];
    SEL set = NSSelectorFromString(setName);
    
    // set accessors
    class_replaceMethod(cls, get, [self getterForColumn:column], getterTypeStringForCode(self.objcType));
    class_replaceMethod(cls, set, [self setterForColumn:column], setterTypeStringForCode(self.objcType));
}

+(instancetype)propertyForObjectProperty:(objc_property_t)prop {
    // go through all attributes, noting if nonatomic and getting the RLMType
    unsigned int attCount;
    BOOL nonatomic = NO, dynamic = NO;
    RLMType type = RLMTypeNone;
    char objcType = 0;
    Class subtableObjectType;
    objc_property_attribute_t *atts = property_copyAttributeList(prop, &attCount);
    for (unsigned int a = 0; a < attCount; a++) {
        switch (*(atts[a].name)) {
            case 'T':
                typeForPropertyString(atts[a].value, &type, &subtableObjectType);
                objcType = *(atts[a].value);            // first char of type attr
                if (objcType == 'q') objcType = 'l';    // collapse these
                break;
            case 'N':
                nonatomic = YES;
                break;
            case 'D':
                dynamic = YES;
                break;
            default:
                break;
        }
    }
    free(atts);
    
    // if nonatomic and prop has a valid type add to our array
    const char *name = property_getName(prop);
    if (type == RLMTypeNone) {
        NSString * reason = [NSString stringWithFormat:@"Can't persist property '%s' with incompatible type. "
                             "Add to ignoredPropertyNames: method to ignore.", name];
        @throw [NSException exceptionWithName:@"RLMException" reason:reason userInfo:nil];
    }
    else {
        // if nonatomic and valid type, add to array
        RLMProperty *tdbProp = [RLMProperty new];
        tdbProp.type = type;
        tdbProp.objcType = objcType;
        tdbProp.name = [NSString stringWithUTF8String:name];
        tdbProp.subtableObjectClass = subtableObjectType;
        tdbProp.nonatomic = nonatomic;
        tdbProp.dynamic = dynamic;
        return tdbProp;
    }
    return nil;
}


@end



