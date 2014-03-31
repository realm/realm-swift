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

#import <Foundation/Foundation.h>
#import "NSObject+TDBTypeConversion.h"
#import "TDBTable.h"
#import "util_noinst.hpp"

@implementation NSObject (TDBTypeConversion)

-(BOOL) TDBBoolValue
{
    if ([self isKindOfClass:[NSNumber class]]) {
        if (nsnumber_is_like_bool(self)) {
            return [(NSNumber *)self boolValue];
        }
    }
    @throw [NSException exceptionWithName:@"tightdb:wrong_column_type"
                        reason:@"NSNumber/BOOL expected"
                        userInfo:nil];
}

-(long long) TDBLongLongValue
{
    if ([self isKindOfClass:[NSNumber class]]) {
        if (nsnumber_is_like_integer(self))
            return [(NSNumber *)self longLongValue];
    }
    @throw [NSException exceptionWithName:@"tightdb:wrong_column_type"
                        reason:@"NSNumber/long long expected"
                        userInfo:nil];
}

-(float) TDBFloatValue
{
    if ([self isKindOfClass:[NSNumber class]]) {
        if (nsnumber_is_like_float(self)) {
            return [(NSNumber *)self floatValue];
        }
    }
    @throw [NSException exceptionWithName:@"tightdb:wrong_column_type"
                        reason:@"NSNumber/float expected"
                        userInfo:nil];
}

-(double) TDBDoubleValue
{
    if ([self isKindOfClass:[NSNumber class]]) {
        if (nsnumber_is_like_double(self)) {
            return [(NSNumber *)self doubleValue];
        }
    }
    @throw [NSException exceptionWithName:@"tightdb:wrong_column_type"
                        reason:@"NSNumber/double expected"
                        userInfo:nil];
}

-(NSData *) TDBasNSData
{
    if ([self isKindOfClass:[NSData class]])
        return (NSData *)self;
    @throw [NSException exceptionWithName:@"tightdb:wrong_column_type"
                        reason:@"NSData expected"
                        userInfo:nil];
}

-(NSString *) TDBasNSString
{
    if ([self isKindOfClass:[NSString class]])
        return (NSString *)self;
    @throw [NSException exceptionWithName:@"tightdb:wrong_column_type"
                        reason:@"NSString expected"
                        userInfo:nil];
}

-(NSDate *) TDBasNSDate
{
    if ([self isKindOfClass:[NSDate class]])
        return (NSDate *)self;
    @throw [NSException exceptionWithName:@"tightdb:wrong_column_type"
                        reason:@"NSDate expected"
                        userInfo:nil];
}

-(TDBTable *) TDBasTDBTable
{
    if ([self isKindOfClass:[TDBTable class]])
        return (TDBTable *)self;
    @throw [NSException exceptionWithName:@"tightdb:wrong_column_type"
                        reason:@"TDBTable expected"
                        userInfo:nil];
}

@end
