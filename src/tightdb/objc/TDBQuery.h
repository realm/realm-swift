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

@class TDBTable;
@class TDBView;


@interface TDBQuery: NSObject <NSFastEnumeration>
-(id)initWithTable:(TDBTable *)table;
-(id)initWithTable:(TDBTable *)table error:(NSError *__autoreleasing *)error;
-(TDBTable *)originTable;

-(TDBQuery *)group;
-(TDBQuery *)Or;
-(TDBQuery *)endGroup;
-(TDBQuery *)subtableInColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)parent;

-(NSUInteger)countRows;
-(NSUInteger)removeRows;

// Aggregates
-(int64_t)minIntInColumnWithIndex:(NSUInteger)colIndex;
-(float)minFloatInColumnWithIndex:(NSUInteger)colIndex;
-(double)minDoubleInColumnWithIndex:(NSUInteger)colIndex;
-(NSDate *)minDateInColumnWithIndex:(NSUInteger)colIndex;

-(int64_t)maxIntInColumnWithIndex:(NSUInteger)colIndex;
-(float)maxFloatInColumnWithIndex:(NSUInteger)colIndex;
-(double)maxDoubleInColumnWithIndex:(NSUInteger)colIndex;
-(NSDate *)maxDateInColumnWithIndex:(NSUInteger)colIndex;

-(NSNumber *)sumColumnWithIndex:(NSUInteger)colIndex;

-(NSNumber *)avgColumnWithIndex:(NSUInteger)colIndex;


/* Search */
-(NSUInteger)findFirstRow;
-(NSUInteger)findFirstRowFromIndex:(NSUInteger)rowIndex;
-(TDBView *)findAllRows;

/* Conditions: */
-(TDBQuery *)boolIsEqualTo:(bool)aBool inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)intIsEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)floatIsEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)doubleIsEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)stringIsEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)stringIsCaseInsensitiveEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)dateIsEqualTo:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)binaryIsEqualTo:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex;


-(TDBQuery *)intIsNotEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)floatIsNotEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)doubleIsNotEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)stringIsNotEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)stringIsNotCaseInsensitiveEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)dateIsNotEqualTo:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)binaryIsNotEqualTo:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex;

-(TDBQuery *)dateIsBetween:(NSDate *)lower :(NSDate *)upper inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)intIsBetween:(int64_t)lower :(int64_t)upper inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)floatIsBetween:(float)lower :(float)upper inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)doubleIsBetween:(double)lower :(double)upper inColumnWithIndex:(NSUInteger)colIndex;

-(TDBQuery *)dateIsGreaterThan:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)intIsGreaterThan:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)floatIsGreaterThan:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)doubleIsGreaterThan:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;

-(TDBQuery *)dateIsGreaterThanOrEqualTo:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)intIsGreaterThanOrEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)floatIsGreaterThanOrEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)doubleIsGreaterThanOrEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;

-(TDBQuery *)dateIsLessThan:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)intIsLessThan:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)floatIsLessThan:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)doubleIsLessThan:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;

-(TDBQuery *)dateIsLessThanOrEqualTo:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)intIsLessThanOrEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)floatIsLessThanOrEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TDBQuery *)doubleIsLessThanOrEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;




@end


@interface TDBQueryAccessorBool: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery *)query;
/* FIXME: Rename columnIsEqualTo to isEqualTo and likewise for all
 * predicates in all the other column proxies
 * below. E.g. columnIsBetween:and_: -> isBetween:and_: */
-(TDBQuery *)columnIsEqualTo:(BOOL)value;
@end


@interface TDBQueryAccessorInt: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery *)query;
-(TDBQuery *)columnIsEqualTo:(int64_t)value;
-(TDBQuery *)columnIsNotEqualTo:(int64_t)value;
-(TDBQuery *)columnIsGreaterThan:(int64_t)value;
-(TDBQuery *)columnIsGreaterThanOrEqualTo:(int64_t)value;
-(TDBQuery *)columnIsLessThan:(int64_t)value;
-(TDBQuery *)columnIsLessThanOrEqualTo:(int64_t)value;
-(TDBQuery *)columnIsBetween:(int64_t)lower :(int64_t)upper;
-(int64_t)min;
-(int64_t)max;
-(int64_t)sum;
-(double)avg;
@end


@interface TDBQueryAccessorFloat: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery *)query;
-(TDBQuery *)columnIsEqualTo:(float)value;
-(TDBQuery *)columnIsNotEqualTo:(float)value;
-(TDBQuery *)columnIsGreaterThan:(float)value;
-(TDBQuery *)columnIsGreaterThanOrEqualTo:(float)value;
-(TDBQuery *)columnIsLessThan:(float)value;
-(TDBQuery *)columnIsLessThanOrEqualTo:(float)value;
-(TDBQuery *)columnIsBetween:(float)lower :(float)upper;
-(float)min;
-(float)max;
-(double)sum;
-(double)avg;
@end


@interface TDBQueryAccessorDouble: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery *)query;
-(TDBQuery *)columnIsEqualTo:(double)value;
-(TDBQuery *)columnIsNotEqualTo:(double)value;
-(TDBQuery *)columnIsGreaterThan:(double)value;
-(TDBQuery *)columnIsGreaterThanOrEqualTo:(double)value;
-(TDBQuery *)columnIsLessThan:(double)value;
-(TDBQuery *)columnIsLessThanOrEqualTo:(double)value;
-(TDBQuery *)columnIsBetween:(double)lower :(double)upper;
-(double)min;
-(double)max;
-(double)sum;
-(double)avg;
@end


@interface TDBQueryAccessorString: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery *)query;
-(TDBQuery *)columnIsEqualTo:(NSString *)value;
-(TDBQuery *)columnIsEqualTo:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(TDBQuery *)columnIsNotEqualTo:(NSString *)value;
-(TDBQuery *)columnIsNotEqualTo:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(TDBQuery *)columnBeginsWith:(NSString *)value;
-(TDBQuery *)columnBeginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(TDBQuery *)columnEndsWith:(NSString *)value;
-(TDBQuery *)columnEndsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(TDBQuery *)columnContains:(NSString *)value;
-(TDBQuery *)columnContains:(NSString *)value caseSensitive:(BOOL)caseSensitive;
@end


@interface TDBQueryAccessorBinary: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery *)query;
-(TDBQuery *)columnIsEqualTo:(NSData *)value;
-(TDBQuery *)columnIsNotEqualTo:(NSData *)value;
-(TDBQuery *)columnBeginsWith:(NSData *)value;
-(TDBQuery *)columnEndsWith:(NSData *)value;
-(TDBQuery *)columnContains:(NSData *)value;
@end


@interface TDBQueryAccessorDate: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery *)query;
-(TDBQuery *)columnIsEqualTo:(NSDate *)value;
-(TDBQuery *)columnIsNotEqualTo:(NSDate *)value;
-(TDBQuery *)columnIsGreaterThan:(NSDate *)value;
-(TDBQuery *)columnIsGreaterThanOrEqualTo:(NSDate *)value;
-(TDBQuery *)columnIsLessThan:(NSDate *)value;
-(TDBQuery *)columnIsLessThanOrEqualTo:(NSDate *)value;
-(TDBQuery *)columnIsBetween:(NSDate *)lower :(NSDate *)upper;
@end


@interface TDBQueryAccessorSubtable: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery *)query;
@end


@interface TDBQueryAccessorMixed: NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(TDBQuery *)query;
@end
