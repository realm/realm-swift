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

#import <Foundation/Foundation.h>
#import "RLMUtil.h"
#import "RLMObject.h"
#import "RLMProperty.h"

inline bool nsnumber_is_like_bool(NSObject *obj)
{
    const char* data_type = [(NSNumber *)obj objCType];
    // @encode(BOOL) is 'B' on iOS 64 and 'c'
    // objcType is always 'c'. Therefore compare to "c".
    
    // FIXME: Need to support @(false) which returns a data_type of 'i'
    return data_type[0] == 'c';
}

inline bool nsnumber_is_like_integer(NSObject *obj)
{
    const char* data_type = [(NSNumber *)obj objCType];
    // FIXME: Performance optimization - don't use strcmp, use first char in data_type.
    return (strcmp(data_type, @encode(int)) == 0 ||
            strcmp(data_type, @encode(long)) ==  0 ||
            strcmp(data_type, @encode(long long)) == 0 ||
            strcmp(data_type, @encode(unsigned int)) == 0 ||
            strcmp(data_type, @encode(unsigned long)) == 0 ||
            strcmp(data_type, @encode(unsigned long long)) == 0);
}

inline bool nsnumber_is_like_float(NSObject *obj)
{
    const char* data_type = [(NSNumber *)obj objCType];
    // FIXME: Performance optimization - don't use strcmp, use first char in data_type.
    return (strcmp(data_type, @encode(float)) == 0 ||
            strcmp(data_type, @encode(int)) == 0 ||
            strcmp(data_type, @encode(long)) ==  0 ||
            strcmp(data_type, @encode(long long)) == 0 ||
            strcmp(data_type, @encode(unsigned int)) == 0 ||
            strcmp(data_type, @encode(unsigned long)) == 0 ||
            strcmp(data_type, @encode(unsigned long long)) == 0);
}

inline bool nsnumber_is_like_double(NSObject *obj)
{
    const char* data_type = [(NSNumber *)obj objCType];
    // FIXME: Performance optimization - don't use strcmp, use first char in data_type.
    return (strcmp(data_type, @encode(double)) == 0 ||
            strcmp(data_type, @encode(float)) == 0 ||
            strcmp(data_type, @encode(int)) == 0 ||
            strcmp(data_type, @encode(long)) ==  0 ||
            strcmp(data_type, @encode(long long)) == 0 ||
            strcmp(data_type, @encode(unsigned int)) == 0 ||
            strcmp(data_type, @encode(unsigned long)) == 0 ||
            strcmp(data_type, @encode(unsigned long long)) == 0);
}

inline bool object_has_valid_type(id obj)
{
    return ([obj isKindOfClass:[NSString class]] ||
            [obj isKindOfClass:[NSNumber class]] ||
            [obj isKindOfClass:[NSDate class]] ||
            [obj isKindOfClass:[NSData class]]);
}

BOOL RLMIsObjectValidForProperty(id obj, RLMProperty *property) {
    switch (property.type) {
        case RLMPropertyTypeString:
            return [obj isKindOfClass:[NSString class]];
        case RLMPropertyTypeBool:
            if ([obj isKindOfClass:[NSNumber class]]) {
                return nsnumber_is_like_bool(obj);
            }
            return NO;
        case RLMPropertyTypeDate:
            if ([obj isKindOfClass:[NSNumber class]]) {
                return nsnumber_is_like_integer(obj);
            }
            return [obj isKindOfClass:[NSDate class]];
        case RLMPropertyTypeInt:
            if ([obj isKindOfClass:[NSNumber class]]) {
                return nsnumber_is_like_integer(obj);
            }
            return NO;
        case RLMPropertyTypeFloat:
            if ([obj isKindOfClass:[NSNumber class]]) {
                return nsnumber_is_like_float(obj);
            }
            return NO;
        case RLMPropertyTypeDouble:
            if ([obj isKindOfClass:[NSNumber class]]) {
                return nsnumber_is_like_double(obj);
            }
            return NO;
        case RLMPropertyTypeData:
            return [obj isKindOfClass:[NSData class]];
        case RLMPropertyTypeAny:
            return object_has_valid_type(obj);
        case RLMPropertyTypeObject: {
            // only NSNull, nil, or objects which derive from RLMObject and match the given
            // object class are valid
            BOOL isValidObject = RLMIsSubclass([obj class], [RLMObject class]) &&
                                 [[[obj class] className] isEqualToString:property.objectClassName];
            return isValidObject || obj == nil || obj == NSNull.null;
        }
        // FIXME: missing entries
        case RLMPropertyTypeArray:
            break;
    }
    @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid RLMPropertyType specified" userInfo:nil];
}


void RLMSetAnyProperty(tightdb::Table &table, NSUInteger row_ndx, NSUInteger col_ndx, id obj) {
//    if (obj == nil) {
//        table.nullify_link(col_ndx, row_ndx);
//        return;
//    }
    if ([obj isKindOfClass:[NSString class]]) {
        table.set_mixed(col_ndx, row_ndx, RLMStringDataWithNSString(obj));
        return;
    }
    if ([obj isKindOfClass:[NSDate class]]) {
        table.set_mixed(col_ndx, row_ndx, tightdb::DateTime(time_t([(NSDate *)obj timeIntervalSince1970])));
        return;
    }
    if ([obj isKindOfClass:[NSData class]]) {
        table.set_mixed(col_ndx, row_ndx, RLMBinaryDataForNSData(obj));
        return;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        const char *data_type = [(NSNumber *)obj objCType];
        const char dt = data_type[0];
        switch (dt) {
            case 'i':
            case 's':
            case 'l':
                table.set_mixed(col_ndx, row_ndx, (int64_t)[(NSNumber *)obj longValue]);
                return;
            case 'f':
                table.set_mixed(col_ndx, row_ndx, [(NSNumber *)obj floatValue]);
                return;
            case 'd':
                table.set_mixed(col_ndx, row_ndx, [(NSNumber *)obj doubleValue]);
                return;
            case 'B':
            case 'c':
                table.set_mixed(col_ndx, row_ndx, [(NSNumber *)obj boolValue] == YES);
                return;
        }
    }
    @throw [NSException exceptionWithName:@"RLMException" reason:@"Inserting invalid object for RLMPropertyTypeAny property" userInfo:nil];
}

id RLMGetAnyProperty(tightdb::Table &table, NSUInteger row_ndx, NSUInteger col_ndx) {
    tightdb::Mixed mixed = table.get_mixed(col_ndx, row_ndx);
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
