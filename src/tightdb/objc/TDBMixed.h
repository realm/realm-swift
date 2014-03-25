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

#import "TDBTable.h"

@interface TDBMixed: NSObject
+(TDBMixed *)mixedWithBool:(BOOL)value;
+(TDBMixed *)mixedWithInt64:(int64_t)value;
+(TDBMixed *)mixedWithFloat:(float)value;
+(TDBMixed *)mixedWithDouble:(double)value;
+(TDBMixed *)mixedWithString:(NSString *)value;
+(TDBMixed *)mixedWithBinary:(NSData *)value;
+(TDBMixed *)mixedWithBinary:(const char *)data size:(size_t)size;
+(TDBMixed *)mixedWithDate:(NSDate *)value;
+(TDBMixed *)mixedWithTable:(TDBTable *)value;
-(BOOL)isEqual:(TDBMixed *)other;
-(TDBType)getType;
-(BOOL)getBool;
-(int64_t)getInt;
-(float)getFloat;
-(double)getDouble;
-(NSString *)getString;
-(NSData *)getBinary;
-(NSDate *)getDate;
-(TDBTable *)getTable;
@end

