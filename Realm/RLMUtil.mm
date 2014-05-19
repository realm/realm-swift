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

inline bool nsnumber_is_like_bool(NSObject *obj)
{
    const char* data_type = [(NSNumber *)obj objCType];
    // @encode(BOOL) is 'B' on iOS 64 and 'c'
    // objcType is always 'c'. Therefore compare to "c".
    
    return data_type[0] == 'c';
}

inline bool nsnumber_is_like_integer(NSObject *obj)
{
    const char* data_type = [(NSNumber *)obj objCType];
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
    return (strcmp(data_type, @encode(double)) == 0 ||
            strcmp(data_type, @encode(float)) == 0 ||
            strcmp(data_type, @encode(int)) == 0 ||
            strcmp(data_type, @encode(long)) ==  0 ||
            strcmp(data_type, @encode(long long)) == 0 ||
            strcmp(data_type, @encode(unsigned int)) == 0 ||
            strcmp(data_type, @encode(unsigned long)) == 0 ||
            strcmp(data_type, @encode(unsigned long long)) == 0);
}

BOOL RLMIsObjectOfType(id obj, RLMPropertyType type) {
    switch (type) {
        case RLMPropertyTypeString:
            if (![obj isKindOfClass:[NSString class]])
                return NO;
            break;
        case RLMPropertyTypeBool:
            if ([obj isKindOfClass:[NSNumber class]]) {
                if (nsnumber_is_like_bool(obj))
                    break;
                return NO;
            }
            break;
        case RLMPropertyTypeDate:
            if ([obj isKindOfClass:[NSNumber class]]) {
                if (nsnumber_is_like_integer(obj))
                    break;
            }
            if ([obj isKindOfClass:[NSDate class]]) {
                break;
            }
            return NO;
        case RLMPropertyTypeInt:
            if ([obj isKindOfClass:[NSNumber class]]) {
                if (nsnumber_is_like_integer(obj))
                    break;
            }
            return NO;
        case RLMPropertyTypeFloat:
            if ([obj isKindOfClass:[NSNumber class]]) {
                if (nsnumber_is_like_float(obj))
                    break;
            }
            return NO;
        case RLMPropertyTypeDouble:
            if ([obj isKindOfClass:[NSNumber class]]) {
                if (nsnumber_is_like_double(obj))
                    break;
            }
            return NO;
        case RLMPropertyTypeData:
            if ([obj isKindOfClass:[NSData class]])
                break;
            return NO;
        default:
            @throw [NSException exceptionWithName:@"RLMException" reason:@"Invalid RLMPropertyType specified" userInfo:nil];
    }
    return YES;
}

