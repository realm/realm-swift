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

// fixed column accessors
// bakes the column number into the method signature to avoid looking up by name
template<typename T, int C>
T column_get(RLMRow *row, SEL) {
    return column_get<T>(row, C);
}
template<typename T, int C>
void column_set(RLMRow *row, SEL, T val) {
    column_set<T>(row, C, val);
}

// column lookup accessors
// these are the slow versions of the above and are used in objects where you have more
// than NUM_COLUMN_ACCESSORS columns
template<typename T>
T dynamic_get(RLMRow *row, SEL sel) {
    NSUInteger col = [row.table indexOfColumnWithName:NSStringFromSelector(sel)];
    return column_get<T>(row, col);
}
template<typename T>
void dynamic_set(RLMRow *row, SEL sel, T val) {
    NSString *name = NSStringFromSelector(sel);
    // TODO - this currently assumes setters are named set<propertyname>
    // we need to validate this and have a table of actual accessor names rather
    // than making this asumption (in asana)
    NSRange end = NSMakeRange(4, name.length-5);
    name = [NSString stringWithFormat:@"%c%@", tolower([name characterAtIndex:3]), [name substringWithRange:end]];
    NSUInteger col = [row.table indexOfColumnWithName:name];
    column_set<T>(row, col, val);
}


// column accessor enumerator objects for storing generated functions
typedef std::vector<IMP> ColumnFuncs;
typedef std::pair<ColumnFuncs, ColumnFuncs> GettersSetters;

// column generator for generating fast accessors with baked in column indexes
// works with template recursion - we instantiate a version of this class for the
// NUM column, which references a version of this class for each previous column
// until we get to the 0th column
template <int NUM, typename TYPE>
class ColumnFuncsEnumerator {
public:
    // column index
    enum { column = NUM - 1 };
    
    // entry point for function generation
    // creates the lookup table, and starts populating with the last column
    static GettersSetters enumerate(void) {
        ColumnFuncsEnumerator<NUM, TYPE> enumerator;
        GettersSetters funcs;
        funcs.first.resize(NUM);
        funcs.second.resize(NUM);
        enumerator.registerFuncs(funcs);
        return funcs;
    }
    
    // this is called recursively for each column starting with column NUM
    // once we get to the 0th column, the specialized version
    // of this function is called which ends the recursion
	ColumnFuncsEnumerator<column, TYPE> prev;
	void registerFuncs(GettersSetters & funcs) {
        funcs.first[column] = (IMP)column_get<TYPE, column>;
        funcs.second[column] = (IMP)column_set<TYPE, column>;
        prev.registerFuncs(funcs);
	}
};

// partial specialization to end the recursion
template <typename T>
class ColumnFuncsEnumerator<0, T> {
public:
	enum { column = 0 };
    void registerFuncs(GettersSetters &) {}
};

// static accessor lookup table and method type strings
static std::map<char, GettersSetters> s_columnAccessors;
static std::map<char, IMP> s_dynamicGetters, s_dynamicSetters;
static std::map<char, const char *> s_getterTypeStrings, s_setterTypeStrings;

// macros to generate objc type strings when registering methods
#define GETTER_TYPES(C) C "@:"
#define SETTER_TYPES(C) "v@:" C

#define NUM_COLUMN_ACCESSORS 25

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
#define RLM_REGISTER_ACCESSOR_FOR_TYPE(CHAR, SCHAR, TYPE)   \
s_dynamicGetters[CHAR] = (IMP)dynamic_get<TYPE>;        \
s_dynamicSetters[CHAR] = (IMP)dynamic_set<TYPE>;        \
s_getterTypeStrings[CHAR] = GETTER_TYPES(SCHAR);        \
s_setterTypeStrings[CHAR] = SETTER_TYPES(SCHAR);        \
s_columnAccessors[CHAR] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, TYPE>::enumerate();


@implementation RLMProperty

// setup lookup tables for each type
+(void)initialize {
    if (self == RLMProperty.class) {
        RLM_REGISTER_ACCESSOR_FOR_TYPE('i', "i", int)
        RLM_REGISTER_ACCESSOR_FOR_TYPE('l', "l", long)
        RLM_REGISTER_ACCESSOR_FOR_TYPE('f', "f", float)
        RLM_REGISTER_ACCESSOR_FOR_TYPE('d', "d", double)
        RLM_REGISTER_ACCESSOR_FOR_TYPE('B', "B", bool)
        RLM_REGISTER_ACCESSOR_FOR_TYPE('@', "@", id)
        RLM_REGISTER_ACCESSOR_FOR_TYPE('s', "s", NSString *)
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
        default:
            return self.objcType;
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
        
    // determine accessor implementations
    IMP getter, setter;
    char t = self.accessorCode;
    if (self.type == RLMTypeTable) {
        getter = (IMP)dynamic_get<RLMTable *>;
        setter = (IMP)dynamic_set<RLMTable *>;
    }
    else {
        GettersSetters & accessors = s_columnAccessors[t];
        if (column < NUM_COLUMN_ACCESSORS) {
            // static column accessors
            getter = (IMP)accessors.first[column];
            setter = (IMP)accessors.second[column];
        }
        else {
            // dynamic accessors with column lookup
            getter = (IMP)s_dynamicGetters[t];
            setter = (IMP)s_dynamicSetters[t];
        }
    }
    
    // set accessors
    class_replaceMethod(cls, get, getter, s_getterTypeStrings[t]);
    class_replaceMethod(cls, set, setter, s_setterTypeStrings[t]);
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



