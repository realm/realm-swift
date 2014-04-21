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
#import "RLMTable.h"
#import "RLMFast.h"
#import "RLMTable_noinst.h"

#include <vector>
#include <map>

// templated getters/setters
template<typename T> inline T column_get(RLMRow * row, int col);
template<typename T> inline void column_set(RLMRow * row, int col, T val);

// specializations for each type
template<> inline int column_get<int>(RLMRow * row, int col) {
    return (int)row.table.getNativeTable.get_int(col, row.ndx); }
template<> inline void column_set<int>(RLMRow * row, int col, int val) {
    row.table.getNativeTable.set_int(col, row.ndx, val); }
template<> inline long column_get<long>(RLMRow * row, int col) {
    return (long)row.table.getNativeTable.get_int(col, row.ndx); }
template<> inline void column_set<long>(RLMRow * row, int col, long val) {
    row.table.getNativeTable.set_int(col, row.ndx, val); }
template<> inline float column_get<float>(RLMRow * row, int col) {
    return (float)row.table.getNativeTable.get_float(col, row.ndx); }
template<> inline void column_set<float>(RLMRow * row, int col, float val) {
    row.table.getNativeTable.set_float(col, row.ndx, val); }
template<> inline double column_get<double>(RLMRow * row, int col) {
    return (double)row.table.getNativeTable.get_double(col, row.ndx); }
template<> inline void column_set<double>(RLMRow * row, int col, double val) {
    row.table.getNativeTable.set_double(col, row.ndx, val); }
template<> inline bool column_get<bool>(RLMRow * row, int col) {
    return (bool)row.table.getNativeTable.get_bool(col, row.ndx); }
template<> inline void column_set<bool>(RLMRow * row, int col, bool val) {
    row.table.getNativeTable.set_bool(col, row.ndx, val); }
template<> inline id column_get<id>(RLMRow * row, int col) { return row[col]; }
template<> inline void column_set<id>(RLMRow * row, int col, id val) { row[col] = val; }

// fixed column accessors
template<typename T, int C>
T column_get(RLMRow * row, SEL) {
    return column_get<T>(row, C);
}
template<typename T, int C>
void column_set(RLMRow * row, SEL, T val) {
    column_set<T>(row, C, val);
}

// column lookup accessors
template<typename T, int C>
T column_lookup_get(RLMRow * row, SEL sel) {
    NSUInteger col = [row.table indexOfColumnWithName:NSStringFromSelector(sel)];
    return column_get<T>(row, col);
}
template<typename T, int C>
void column_lookup_set(RLMRow * row, SEL sel, T val) {
    NSString * name = NSStringFromSelector(sel);
    name = [name substringWithRange:NSMakeRange(3, name.length-4)];
    NSUInteger col = [row.table indexOfColumnWithName:name];
    column_set<T>(row, col, val);
}


// column accessor enumerator
typedef std::vector<IMP> ColumnFuncs;
typedef std::pair<ColumnFuncs, ColumnFuncs> GettersSetters;

template <int NUM, typename TYPE>
class ColumnFuncsEnumerator {
public:
    // column index
    enum { column = NUM - 1 };
    
    // static method for function generation
    static GettersSetters enumerate(void) {
        ColumnFuncsEnumerator<NUM, TYPE> enumerator;
        GettersSetters funcs;
        funcs.first.resize(NUM);
        funcs.second.resize(NUM);
        enumerator.registerFuncs(funcs);
        return funcs;
    }
    
	ColumnFuncsEnumerator<column, TYPE> prev;
	void registerFuncs(GettersSetters & funcs) {
        funcs.first[column] = (IMP)column_get<TYPE, column>;
        funcs.second[column] = (IMP)column_set<TYPE, column>;
        prev.registerFuncs(funcs);
	}
};

// partial specialization to end the loop
template <typename T>
class ColumnFuncsEnumerator<0, T> {
public:
	enum { column = 0 };
    void registerFuncs(GettersSetters &) {}
};

static std::map<char, GettersSetters> s_columnAccessors;
static std::map<char, const char *> s_getterTypeStrings, s_setterTypeStrings;

#define GETTER_TYPES(C) C "@:"
#define SETTER_TYPES(C) "v@:" C

#define NUM_COLUMN_ACCESSORS 50

// determine RLMType from objc code
void type_for_property_string(const char * code,
                              RLMType * outtype,
                              Class * outSubtableObjectClass) {
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
        case 'c':   // BOOL is stored as char - since tdb has no char this is ok
        case 'B':
            *outtype = RLMTypeBool;
            break;
        case '@':
        {
            NSString * type = [NSString stringWithUTF8String:code];
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
                        NSString * subclassName = [type substringWithRange:NSMakeRange(subOffset, type.length - subOffset - 2)];
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

// dynamic getter for subtable
// TODO - generate column getters
id dynamic_get_subtable(RLMRow * row, SEL sel) {
    NSString * propName = NSStringFromSelector(sel);
    NSUInteger col = [row.table indexOfColumnWithName:propName];
    RLMTable * table = row[col];
    
    // set custom object class
    Class subtableObjectClass = [row.class subtableObjectClassForProperty:propName];
    table.objectClass = subtableObjectClass;
    return table;
}

@implementation RLMProperty

+(void)initialize {
    s_columnAccessors['i'] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, int>::enumerate();
    s_columnAccessors['l'] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, long>::enumerate();
    s_columnAccessors['f'] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, float>::enumerate();
    s_columnAccessors['d'] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, double>::enumerate();
    s_columnAccessors['B'] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, bool>::enumerate();
    s_columnAccessors['@'] = ColumnFuncsEnumerator<NUM_COLUMN_ACCESSORS, id>::enumerate();
    
    s_getterTypeStrings['i'] = GETTER_TYPES("i"); s_setterTypeStrings['i'] = SETTER_TYPES("i");
    s_getterTypeStrings['l'] = GETTER_TYPES("l"); s_setterTypeStrings['l'] = SETTER_TYPES("l");
    s_getterTypeStrings['f'] = GETTER_TYPES("f"); s_setterTypeStrings['f'] = SETTER_TYPES("f");
    s_getterTypeStrings['d'] = GETTER_TYPES("d"); s_setterTypeStrings['d'] = SETTER_TYPES("d");
    s_getterTypeStrings['B'] = GETTER_TYPES("B"); s_setterTypeStrings['B'] = SETTER_TYPES("B");
    s_getterTypeStrings['@'] = GETTER_TYPES("@"); s_setterTypeStrings['@'] = SETTER_TYPES("@");
}


// add dynamic property getters/setters to the given class
-(void)addToClass:(Class)cls existing:(NSSet *)existing column:(int)column
{
    // generate getter sel
    // TODO - support custom accessor names
    NSString * propName = self.name;
    SEL get = NSSelectorFromString(propName);
    
    // generate setter sel
    NSString * firstChar = [[propName substringToIndex:1] uppercaseString];
    NSString * rest = [propName substringFromIndex:1];
    NSString * setName = [NSString stringWithFormat:@"set%@%@:", firstChar, rest];
    SEL set = NSSelectorFromString(setName);
    
    // create getter/setter based on type
    BOOL exists = [existing containsObject:propName];
    if (self.type == RLMTypeTable) {
        if (exists) class_replaceMethod(cls, get, (IMP)dynamic_get_subtable, "@@:");
        else class_addMethod(cls, get, (IMP)dynamic_get_subtable, "@@:");
    }
    else {
        // TODO - make sure we don't go over column limit
        char t = self.objcType;
        GettersSetters & accessors = s_columnAccessors[t];
        IMP getter = (IMP)accessors.first[column];
        IMP setter = (IMP)accessors.second[column];
        if (exists) {
            class_replaceMethod(cls, get, getter, s_getterTypeStrings[t]);
            class_replaceMethod(cls, set, setter, s_setterTypeStrings[t]);
        }
        else {
            class_addMethod(cls, get, getter, s_getterTypeStrings[t]);
            class_addMethod(cls, set, setter, s_setterTypeStrings[t]);
        }
    }
}

+(RLMProperty *)propertyForObjectProperty:(objc_property_t)prop {
    // go through all attributes, noting if nonatomic and getting the RLMType
    unsigned int attCount;
    BOOL nonatomic = NO, dynamic = NO;
    RLMType type = RLMTypeNone;
    char objcType = 0;
    Class subtableObjectType;
    objc_property_attribute_t * atts = property_copyAttributeList(prop, &attCount);
    for (unsigned int a = 0; a < attCount; a++) {
        switch (*(atts[a].name)) {
            case 'T':
                type_for_property_string(atts[a].value, &type, &subtableObjectType);
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
    const char * name = property_getName(prop);
    if (type == RLMTypeNone) {
        NSLog(@"Skipping property '%s' with incompatible type", name);
    }
    else {
        // if nonatomic and valid type, add to array
        RLMProperty * tdbProp = [RLMProperty new];
        tdbProp.type = type;
        tdbProp.objcType = objcType;
        tdbProp.name = [NSString stringWithUTF8String:name];
        tdbProp.subtableObjectClass = subtableObjectType;
        return tdbProp;
    }
    return nil;
}


@end



