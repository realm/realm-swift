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
#import "RLMTable_noinst.h"

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
template<> inline RLMTable * column_get<RLMTable *>(RLMRow *row, NSUInteger col) {
    RLMTable *table = row[col];
    
    // set custom object class
    RLMObjectDescriptor * desc = [RLMObjectDescriptor descriptorForObjectClass:row.class];
    RLMProperty * prop = desc.properties[col];
    table.objectClass = prop.subtableObjectClass;
    return table;
}
template<> inline void column_set<RLMTable *>(RLMRow *row, NSUInteger col, RLMTable * val) {
    row[col] = val;
}
template<> inline id column_get<id>(RLMRow *row, NSUInteger col) {
    return row[col]; }
template<> inline void column_set<id>(RLMRow *row, NSUInteger col, id val) {
    row[col] = val; }

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
                if ([type compare:@"RLMTable" options:0 range:NSMakeRange(2, 8)] == NSOrderedSame) {
                    *outtype = RLMTypeTable;
                    
                    // for macro table classes we can extract subtable type now
                    // if typename is of form "@\"RLMTable<SubObjectClas>\""
                    const unsigned int subOffset = 11;
                    if (type.length > subOffset) {
                        NSRange range = NSMakeRange(subOffset, type.length - subOffset - 2);
                        NSString *subclassName = [type substringWithRange:range];
                        *outSubtableObjectClass = NSClassFromString(subclassName);
                    }
                }
            }
            break;
        }
        default:
            *outtype = RLMTypeNone;
    }
}

@implementation RLMProperty

+(void)initialize {
    s_columnAccessors['i'] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, int>::enumerate();
    s_columnAccessors['l'] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, long>::enumerate();
    s_columnAccessors['f'] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, float>::enumerate();
    s_columnAccessors['d'] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, double>::enumerate();
    s_columnAccessors['B'] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, bool>::enumerate();
    s_columnAccessors['@'] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, id>::enumerate();
    s_columnAccessors['q'] = s_columnAccessors['l'];
    s_columnAccessors['c'] = s_columnAccessors['B'];
    
    s_dynamicGetters['i'] = (IMP)dynamic_get<int>; s_dynamicSetters['i'] = (IMP)dynamic_set<int>;
    s_dynamicGetters['l'] = (IMP)dynamic_get<long>; s_dynamicSetters['l'] = (IMP)dynamic_set<long>;
    s_dynamicGetters['f'] = (IMP)dynamic_get<float>; s_dynamicSetters['f'] = (IMP)dynamic_set<float>;
    s_dynamicGetters['d'] = (IMP)dynamic_get<double>; s_dynamicSetters['d'] = (IMP)dynamic_set<double>;
    s_dynamicGetters['B'] = (IMP)dynamic_get<bool>; s_dynamicSetters['B'] = (IMP)dynamic_set<bool>;
    s_dynamicGetters['@'] = (IMP)dynamic_get<id>; s_dynamicSetters['@'] = (IMP)dynamic_set<id>;
    s_dynamicGetters['q'] = s_dynamicGetters['l']; s_dynamicSetters['q'] = s_dynamicSetters['l'];
    s_dynamicGetters['c'] = s_dynamicGetters['B']; s_dynamicSetters['c'] = s_dynamicSetters['B'];


    s_getterTypeStrings['i'] = GETTER_TYPES("i"); s_setterTypeStrings['i'] = SETTER_TYPES("i");
    s_getterTypeStrings['l'] = GETTER_TYPES("l"); s_setterTypeStrings['l'] = SETTER_TYPES("l");
    s_getterTypeStrings['f'] = GETTER_TYPES("f"); s_setterTypeStrings['f'] = SETTER_TYPES("f");
    s_getterTypeStrings['d'] = GETTER_TYPES("d"); s_setterTypeStrings['d'] = SETTER_TYPES("d");
    s_getterTypeStrings['B'] = GETTER_TYPES("B"); s_setterTypeStrings['B'] = SETTER_TYPES("B");
    s_getterTypeStrings['@'] = GETTER_TYPES("@"); s_setterTypeStrings['@'] = SETTER_TYPES("@");
    s_getterTypeStrings['q'] = s_getterTypeStrings['l']; s_setterTypeStrings['q'] = s_setterTypeStrings['l'];
    s_getterTypeStrings['c'] = s_getterTypeStrings['B']; s_setterTypeStrings['c'] = s_setterTypeStrings['B'];
}


// add dynamic property getters/setters to the given class
-(void)addToClass:(Class)cls existing:(NSSet *)existing column:(int)column
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
    char t = self.objcType;
    if (self.type == RLMTypeTable) {
        getter = (IMP)dynamic_get<RLMTable *>;
        setter = (IMP)dynamic_set<RLMTable *>;
    }
    else {
        GettersSetters & accessors = s_columnAccessors[t];
        getter = column < NUM_COLUMN_ACCESSORS ? (IMP)accessors.first[column] : (IMP)s_dynamicGetters[t];
        setter = column < NUM_COLUMN_ACCESSORS ? (IMP)accessors.second[column] : (IMP)s_dynamicSetters[t];
    }
    
    // set accessors
    if ([existing containsObject:propName]) {
        class_replaceMethod(cls, get, getter, s_getterTypeStrings[t]);
        class_replaceMethod(cls, set, setter, s_setterTypeStrings[t]);
    }
    else {
        class_addMethod(cls, get, getter, s_getterTypeStrings[t]);
        class_addMethod(cls, set, setter, s_setterTypeStrings[t]);
    }
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
        NSLog(@"Skipping property '%s' with incompatible type", name);
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



