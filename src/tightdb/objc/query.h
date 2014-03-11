/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2012] TightDB Inc
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

@class TightdbBinary;
@class TightdbTable;

/* jjepsen: please review this */
@class TightdbView;


@interface TightdbQuery: NSObject <NSFastEnumeration>
-(id)initWithTable:(TightdbTable *)table;
-(id)initWithTable:(TightdbTable *)table error:(NSError *__autoreleasing *)error;
-(TightdbTable *)getTable;
-(TightdbQuery *)group;
-(TightdbQuery *)or;
-(TightdbQuery *)endgroup;
-(void)subtable:(NSUInteger)column;
-(void)parent;
-(NSUInteger)count;
-(NSUInteger)countWithError:(NSError *__autoreleasing *)error;
-(NSUInteger)remove;
-(NSUInteger)removeWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)minimumWithIntColumn:(NSUInteger)colNdx;
-(NSNumber *)minimumWithIntColumn:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)minimumWithFloatColumn:(NSUInteger)colNdx;
-(NSNumber *)minimumWithFloatColumn:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)minimumWithDoubleColumn:(NSUInteger)colNdx;
-(NSNumber *)minimumWithDoubleColumn:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)maximumWithIntColumn:(NSUInteger)colNdx;
-(NSNumber *)maximumWithIntColumn:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)maximumWithFloatColumn:(NSUInteger)colNdx;
-(NSNumber *)maximumWithFloatColumn:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)maximumWithDoubleColumn:(NSUInteger)colNdx;
-(NSNumber *)maximumWithDoubleColumn:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)sumWithIntColumn:(NSUInteger)colNdx;
-(NSNumber *)sumWithIntColumn:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)sumWithFloatColumn:(NSUInteger)colNdx;
-(NSNumber *)sumWithFloatColumn:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)sumWithDoubleColumn:(NSUInteger)colNdx;
-(NSNumber *)sumWithDoubleColumn:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)averageWithIntColumn:(NSUInteger)colNdx;
-(NSNumber *)averageWithIntColumn:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)averageWithFloatColumn:(NSUInteger)colNdx;
-(NSNumber *)averageWithFloatColumn:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)averageWithDoubleColumn:(NSUInteger)colNdx;
-(NSNumber *)averageWithDoubleColumn:(NSUInteger)colNdx error:(NSError *__autoreleasing *)error;
-(NSUInteger)find:(NSUInteger)last;
-(NSUInteger)find:(NSUInteger)last error:(NSError *__autoreleasing *)error;

/* jjepsen: please review this. */
-(TightdbView *)findAll;

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;

/* Conditions: */

-(TightdbQuery *)column:(NSUInteger)colNdx isBetweenInt:(int64_t)from and_:(int64_t)to;
-(TightdbQuery *)column:(NSUInteger)colNdx isBetweenFloat:(float)from and_:(float)to;
-(TightdbQuery *)column:(NSUInteger)colNdx isBetweenDouble:(double)from and_:(double)to;
-(TightdbQuery *)column:(NSUInteger)colNdx isBetweenDate:(time_t)from and_:(time_t)to;

-(TightdbQuery *)column:(NSUInteger)colNdx isEqualToBool:(bool)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isEqualToInt:(int64_t)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isEqualToFloat:(float)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isEqualToDouble:(double)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isEqualToString:(NSString *)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isEqualToString:(NSString *)value caseSensitive:(bool)caseSensitive;
-(TightdbQuery *)column:(NSUInteger)colNdx isEqualToDate:(time_t)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isEqualToBinary:(TightdbBinary *)value;

-(TightdbQuery *)column:(NSUInteger)colNdx isNotEqualToInt:(int64_t)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isNotEqualToFloat:(float)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isNotEqualToDouble:(double)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isNotEqualToString:(NSString *)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isNotEqualToString:(NSString *)value caseSensitive:(bool)caseSensitive;
-(TightdbQuery *)column:(NSUInteger)colNdx isNotEqualToDate:(time_t)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isNotEqualToBinary:(TightdbBinary *)value;

-(TightdbQuery *)column:(NSUInteger)colNdx isGreaterThanInt:(int64_t)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isGreaterThanFloat:(float)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isGreaterThanDouble:(double)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isGreaterThanDate:(time_t)value;

-(TightdbQuery *)column:(NSUInteger)colNdx isGreaterThanOrEqualToInt:(int64_t)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isGreaterThanOrEqualToFloat:(float)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isGreaterThanOrEqualToDouble:(double)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isGreaterThanOrEqualToDate:(time_t)value;

-(TightdbQuery *)column:(NSUInteger)colNdx isLessThanInt:(int64_t)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isLessThanFloat:(float)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isLessThanDouble:(double)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isLessThanDate:(time_t)value;

-(TightdbQuery *)column:(NSUInteger)colNdx isLessThanOrEqualToInt:(int64_t)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isLessThanOrEqualToFloat:(float)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isLessThanOrEqualToDouble:(double)value;
-(TightdbQuery *)column:(NSUInteger)colNdx isLessThanOrEqualToDate:(time_t)value;


@end


@interface TightdbQueryAccessorBool: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery *)query;
/* FIXME: Rename columnIsEqualTo to isEqualTo and likewise for all
 * predicates in all the other column proxies
 * below. E.g. columnIsBetween:and_: -> isBetween:and_: */
-(TightdbQuery *)columnIsEqualTo:(BOOL)value;
@end


@interface TightdbQueryAccessorInt: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)columnIsEqualTo:(int64_t)value;
-(TightdbQuery *)columnIsNotEqualTo:(int64_t)value;
-(TightdbQuery *)columnIsGreaterThan:(int64_t)value;
-(TightdbQuery *)columnIsGreaterThanOrEqualTo:(int64_t)value;
-(TightdbQuery *)columnIsLessThan:(int64_t)value;
-(TightdbQuery *)columnIsLessThanOrEqualTo:(int64_t)value;
-(TightdbQuery *)columnIsBetween:(int64_t)from and_:(int64_t)to;
-(NSNumber *)minimum;
-(NSNumber *)minimumWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)maximum;
-(NSNumber *)maximumWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)sum;
-(NSNumber *)sumWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)average;
-(NSNumber *)averageWithError:(NSError *__autoreleasing *)error;
@end


@interface TightdbQueryAccessorFloat: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)columnIsEqualTo:(float)value;
-(TightdbQuery *)columnIsNotEqualTo:(float)value;
-(TightdbQuery *)columnIsGreaterThan:(float)value;
-(TightdbQuery *)columnIsGreaterThanOrEqualTo:(float)value;
-(TightdbQuery *)columnIsLessThan:(float)value;
-(TightdbQuery *)columnIsLessThanOrEqualTo:(float)value;
-(TightdbQuery *)columnIsBetween:(float)from and_:(float)to;
-(NSNumber *)minimum;
-(NSNumber *)minimumWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)maximum;
-(NSNumber *)maximumWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)sum;
-(NSNumber *)sumWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)average;
-(NSNumber *)averageWithError:(NSError *__autoreleasing *)error;
@end


@interface TightdbQueryAccessorDouble: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)columnIsEqualTo:(double)value;
-(TightdbQuery *)columnIsNotEqualTo:(double)value;
-(TightdbQuery *)columnIsGreaterThan:(double)value;
-(TightdbQuery *)columnIsGreaterThanOrEqualTo:(double)value;
-(TightdbQuery *)columnIsLessThan:(double)value;
-(TightdbQuery *)columnIsLessThanOrEqualTo:(double)value;
-(TightdbQuery *)columnIsBetween:(double)from and_:(double)to;
-(NSNumber *)minimum;
-(NSNumber *)minimumWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)maximum;
-(NSNumber *)maximumWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)sum;
-(NSNumber *)sumWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)average;
-(NSNumber *)averageWithError:(NSError *__autoreleasing *)error;
@end


@interface TightdbQueryAccessorString: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)columnIsEqualTo:(NSString *)value;
-(TightdbQuery *)columnIsEqualTo:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(TightdbQuery *)columnIsNotEqualTo:(NSString *)value;
-(TightdbQuery *)columnIsNotEqualTo:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(TightdbQuery *)columnBeginsWith:(NSString *)value;
-(TightdbQuery *)columnBeginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(TightdbQuery *)columnEndsWith:(NSString *)value;
-(TightdbQuery *)columnEndsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(TightdbQuery *)columnContains:(NSString *)value;
-(TightdbQuery *)columnContains:(NSString *)value caseSensitive:(BOOL)caseSensitive;
@end


@interface TightdbQueryAccessorBinary: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)columnIsEqualTo:(TightdbBinary *)value;
-(TightdbQuery *)columnIsNotEqualTo:(TightdbBinary *)value;
-(TightdbQuery *)columnBeginsWith:(TightdbBinary *)value;
-(TightdbQuery *)columnEndsWith:(TightdbBinary *)value;
-(TightdbQuery *)columnContains:(TightdbBinary *)value;
@end


@interface TightdbQueryAccessorDate: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)columnIsEqualTo:(time_t)value;
-(TightdbQuery *)columnIsNotEqualTo:(time_t)value;
-(TightdbQuery *)columnIsGreaterThan:(time_t)value;
-(TightdbQuery *)columnIsGreaterThanOrEqualTo:(time_t)value;
-(TightdbQuery *)columnIsLessThan:(time_t)value;
-(TightdbQuery *)columnIsLessThanOrEqualTo:(time_t)value;
-(TightdbQuery *)columnIsBetween:(time_t)from and_:(time_t)to;
@end


@interface TightdbQueryAccessorSubtable: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery *)query;
@end


@interface TightdbQueryAccessorMixed: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TightdbQuery *)query;
@end
