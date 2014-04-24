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

#include <vector>
#include <map>

// templated getters/setters
// these are used so we can use the same signature for all types
// allowing us to use a single mechanism for generating column specific accessors
template<typename T> inline T column_get(RLMRow *row, NSUInteger col);
template<typename T> inline void column_set(RLMRow *row, NSUInteger col, T val);

// specializations for each type
template<> inline int column_get<int>(RLMRow *row, NSUInteger col) {
    return (int)row.table.getNativeTable.get_int(col, row.ndx); }
template<> inline void column_set<int>(RLMRow *row, NSUInteger col, int val) {
    row.table.getNativeTable.set_int(col, row.ndx, val); }
template<> inline long column_get<long>(RLMRow *row, NSUInteger col) {
    return (long)row.table.getNativeTable.get_int(col, row.ndx); }
template<> inline void column_set<long>(RLMRow *row, NSUInteger col, long val) {
    row.table.getNativeTable.set_int(col, row.ndx, val); }
template<> inline float column_get<float>(RLMRow *row, NSUInteger col) {
    return (float)row.table.getNativeTable.get_float(col, row.ndx); }
template<> inline void column_set<float>(RLMRow *row, NSUInteger col, float val) {
    row.table.getNativeTable.set_float(col, row.ndx, val); }
template<> inline double column_get<double>(RLMRow *row, NSUInteger col) {
    return (double)row.table.getNativeTable.get_double(col, row.ndx); }
template<> inline void column_set<double>(RLMRow *row, NSUInteger col, double val) {
    row.table.getNativeTable.set_double(col, row.ndx, val); }
template<> inline bool column_get<bool>(RLMRow *row, NSUInteger col) {
    return (bool)row.table.getNativeTable.get_bool(col, row.ndx); }
template<> inline void column_set<bool>(RLMRow *row, NSUInteger col, bool val) {
    row.table.getNativeTable.set_bool(col, row.ndx, val); }
template<> inline id column_get<id>(RLMRow *row, NSUInteger col) {
    return row[col]; }
template<> inline void column_set<id>(RLMRow *row, NSUInteger col, id val) {
    row[col] = val; }
template<> inline NSString *column_get<NSString *>(RLMRow *row, NSUInteger col) {
    return to_objc_string(row.table.getNativeTable.get_string(col, row.ndx)); }
template<> inline void column_set<NSString *>(RLMRow *row, NSUInteger col, NSString *val) {
    [row setString:val inColumnWithIndex:col]; }
template<> inline RLMTable * column_get<RLMTable *>(RLMRow *row, NSUInteger col) {
    // TODO - generate getters with subtable object types built in to avoid this lookup
    RLMTable *table = row[col];
    RLMObjectDescriptor *desc = [RLMObjectDescriptor descriptorForObjectClass:row.class];
    RLMProperty *prop = desc.properties[col];
    table.objectClass = prop.subtableObjectClass;
    return table;
}
template<> inline void column_set<RLMTable *>(RLMRow *row, NSUInteger col, RLMTable * val) {
    row[col] = val;
}

// macros to generate objc type strings when registering methods
#define GETTER_TYPES(C) C "@"
#define SETTER_TYPES(C) "v@" C

// in RLMProxy.m
extern BOOL is_class_subclass(Class class1, Class class2);

// determine RLMType from objc code
void type_for_property_string(const char *code,
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

// setup accessor lookup tables (dynamic and generated) and type strings for a given type
#define RLM_REGISTER_ACCESSOR_FOR_TYPE(CHAR, SCHAR)     \
s_getterTypeStrings[CHAR] = GETTER_TYPES(SCHAR);        \
s_setterTypeStrings[CHAR] = SETTER_TYPES(SCHAR);        \

static std::map<char, const char *> s_getterTypeStrings, s_setterTypeStrings;

@implementation RLMProperty

// setup lookup tables for each type
+(void)initialize {
    if (self == RLMProperty.class) {
        RLM_REGISTER_ACCESSOR_FOR_TYPE('i', "i")
        RLM_REGISTER_ACCESSOR_FOR_TYPE('l', "l")
        RLM_REGISTER_ACCESSOR_FOR_TYPE('f', "f")
        RLM_REGISTER_ACCESSOR_FOR_TYPE('d', "d")
        RLM_REGISTER_ACCESSOR_FOR_TYPE('B', "B")
        RLM_REGISTER_ACCESSOR_FOR_TYPE('@', "@")
        RLM_REGISTER_ACCESSOR_FOR_TYPE('s', "@")
        RLM_REGISTER_ACCESSOR_FOR_TYPE('t', "@")
    }
}

// get accessor lookup code based on objc type and rlm type
-(char)accessorCode {
    switch (self.objcType) {
        case 'q':           // long long same as long
            return 'l';
        case 'c':           // BOOL (char) same as bool
            return 'B';
        case '@':
            if (self.type == RLMTypeString) return 's';
            if (self.type == RLMTypeTable) return 't';
        default:
            return self.objcType;
    }
}

-(IMP)getterForColumn:(int)column {
    switch (self.accessorCode) {
        case 'i':   // int
            return imp_implementationWithBlock(^(RLMRow *row){ return column_get<int>(row, column); });
        case 'l':   // long
            return imp_implementationWithBlock(^(RLMRow *row){ return column_get<long>(row, column); });
        case 'f':
            return imp_implementationWithBlock(^(RLMRow *row){ return column_get<float>(row, column); });
        case 'd':
            return imp_implementationWithBlock(^(RLMRow *row){ return column_get<double>(row, column); });
        case 'B':
            return imp_implementationWithBlock(^(RLMRow *row){ return column_get<bool>(row, column); });
        case 's':
            return imp_implementationWithBlock(^(RLMRow *row){ return column_get<NSString *>(row, column); });
        case 't':
        {
            Class subtableObjectClass = self.subtableObjectClass;
            return imp_implementationWithBlock(^(RLMRow *row){
                RLMTable *table = row[column];
                table.objectClass = subtableObjectClass;
                return table;
            });
        }
        case '@':
            return imp_implementationWithBlock(^(RLMRow *row){ return column_get<id>(row, column); });
        default:
            @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid accessor code" userInfo:nil];
    }
}

-(IMP)setterForColumn:(int)column {
    switch (self.accessorCode) {
        case 'i':   // int
            return imp_implementationWithBlock(^(RLMRow *row, int val){ return column_set<int>(row, column, val); });
        case 'l':   // long
            return imp_implementationWithBlock(^(RLMRow *row, long val){ return column_set<long>(row, column, val); });
        case 'f':
            return imp_implementationWithBlock(^(RLMRow *row, float val){ return column_set<float>(row, column, val); });
        case 'd':
            return imp_implementationWithBlock(^(RLMRow *row, double val){ return column_set<double>(row, column, val); });
        case 'B':
            return imp_implementationWithBlock(^(RLMRow *row, bool val){ return column_set<bool>(row, column, val); });
        case 's':
            return imp_implementationWithBlock(^(RLMRow *row, NSString * val){ return column_set<NSString *>(row, column, val); });
        case 't':
            return imp_implementationWithBlock(^(RLMRow *row, RLMTable * val){ return column_set<RLMTable *>(row, column, val); });
        case '@':
            return imp_implementationWithBlock(^(RLMRow *row, id val){ return column_set<id>(row, column, val); });
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
    char t = self.accessorCode;
    class_replaceMethod(cls, get, [self getterForColumn:column], s_getterTypeStrings[t]);
    class_replaceMethod(cls, set, [self setterForColumn:column], s_setterTypeStrings[t]);
}

+(instancetype)propertyForObjectProperty:(objc_property_t)prop {
    // go through all attributes, noting if nonatomic and getting the RLMType
    unsigned int attCount;
    //BOOL nonatomic = NO, dynamic = NO;
    RLMType type = RLMTypeNone;
    char objcType = 0;
    Class subtableObjectType;
    objc_property_attribute_t *atts = property_copyAttributeList(prop, &attCount);
    for (unsigned int a = 0; a < attCount; a++) {
        switch (*(atts[a].name)) {
            case 'T':
                type_for_property_string(atts[a].value, &type, &subtableObjectType);
                objcType = *(atts[a].value);            // first char of type attr
                if (objcType == 'q') objcType = 'l';    // collapse these
                break;
            /*case 'N':
                nonatomic = YES;
                break;
            case 'D':
                dynamic = YES;
                break;*/
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
        return tdbProp;
    }
    return nil;
}


@end



