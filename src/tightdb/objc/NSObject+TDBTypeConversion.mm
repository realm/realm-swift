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


@implementation NSObject (TDBTypeConversion)

-(BOOL) TDBBoolValue
{
    if ([self isKindOfClass:[NSNumber class]]) {
        if (strcmp([(NSNumber *)self objCType], @encode(BOOL)) == 0) {
            return [(NSNumber *)self boolValue];
        }
    }
    NSException* exception = [NSException exceptionWithName:@"tightdb:wrong_column_type"
                                                     reason:@"NSNumber/BOOL expected"
                                                   userInfo:nil];
    [exception raise];
    __builtin_unreachable();
}

-(long long) TDBLongLongValue
{
    if ([self isKindOfClass:[NSNumber class]]) {
        if (strcmp([(NSNumber *)self objCType], @encode(long long)) == 0)
            return [(NSNumber *)self longLongValue];
    }
    NSException* exception = [NSException exceptionWithName:@"tightdb:wrong_column_type"
                                                     reason:@"NSNumber/long long expected"
                                                     userInfo:nil];
    [exception raise];
    __builtin_unreachable();

}

-(float) TDBFloatValue
{
    if ([self isKindOfClass:[NSNumber class]]) {
        if (strcmp([(NSNumber *)self objCType], @encode(float)) == 0) {
            return [(NSNumber *)self floatValue];
        }
    }
    NSException* exception = [NSException exceptionWithName:@"tightdb:wrong_column_type"
                                                     reason:@"NSNumber/float expected"
                                                     userInfo:nil];
    [exception raise];
    __builtin_unreachable();
}

-(double) TDBDoubleValue
{
    if ([self isKindOfClass:[NSNumber class]]) {
        if (strcmp([(NSNumber *)self objCType], @encode(double)) == 0) {
            return [(NSNumber *)self doubleValue];
        }
    }
    NSException* exception = [NSException exceptionWithName:@"tightdb:wrong_column_type"
                                                     reason:@"NSNumber/double expected"
                                                     userInfo:nil];
    [exception raise];
    __builtin_unreachable();
}

-(NSData *) TDBasNSData
{
    if ([self isKindOfClass:[NSData class]])
        return (NSData *)self;
    NSException* exception = [NSException exceptionWithName:@"tightdb:wrong_column_type"
                                                     reason:@"NSData expected"
                                                     userInfo:nil];
    [exception raise];
    __builtin_unreachable();
}

-(NSString *) TDBasNSString
{
    if ([self isKindOfClass:[NSString class]])
        return (NSString *)self;
    NSException* exception = [NSException exceptionWithName:@"tightdb:wrong_column_type"
                                                     reason:@"NSString expected"
                                                     userInfo:nil];
    [exception raise];
    __builtin_unreachable();
}

-(NSDate *) TDBasNSDate
{
    if ([self isKindOfClass:[NSDate class]])
        return (NSDate *)self;
    NSException* exception = [NSException exceptionWithName:@"tightdb:wrong_column_type"
                                                     reason:@"NSDate expected"
                                                   userInfo:nil];
    [exception raise];
    __builtin_unreachable();
}

-(TDBTable *) TDBasTDBTable
{
    if ([self isKindOfClass:[TDBTable class]])
        return (TDBTable *)self;
    NSException* exception = [NSException exceptionWithName:@"tightdb:wrong_column_type"
                                                     reason:@"TDBTable expected"
                                                   userInfo:nil];
    [exception raise];
    __builtin_unreachable();
}

@end
