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
@class TDBTable;

/* jjepsen: please review this */
@class TightdbView;


@interface TightdbQuery: NSObject <NSFastEnumeration>
-(id)initWithTable:(TDBTable *)table;
-(id)initWithTable:(TDBTable *)table error:(NSError *__autoreleasing *)error;
-(TDBTable *)originTable;

-(TightdbQuery *)group;
-(TightdbQuery *)Or;
-(TightdbQuery *)endGroup;
-(void)subtableInColumnWithIndex:(NSUInteger)colIndex;
-(void)parent;

-(NSUInteger)countRows;
-(NSUInteger)removeRows;

-(int64_t)sumIntColumnWithIndex:(NSUInteger)colIndex;
-(double)sumFloatColumnWithIndex:(NSUInteger)colIndex;
-(double)sumDoubleColumnWithIndex:(NSUInteger)colIndex;
-(int64_t)maxIntInColumnWithIndex:(NSUInteger)colIndex;
-(float)maxFloatInColumnWithIndex:(NSUInteger)colIndex;
-(double)maxDoubleInColumnWithIndex:(NSUInteger)colIndex;
-(int64_t)minIntInColumnWithIndex:(NSUInteger)colIndex;
-(float)minFloatInColumnWithIndex:(NSUInteger)colIndex;
-(double)minDoubleInColumnWithIndex:(NSUInteger)colIndex;
-(double)avgIntColumnWithIndex:(NSUInteger)colIndex;
-(double)avgFloatColumnWithIndex:(NSUInteger)colIndex;
-(double)avgDoubleColumnWithIndex:(NSUInteger)colIndex;

-(NSUInteger)findFromRowIndex:(NSUInteger)rowIndex;

-(TightdbView *)findAllRows;

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;

/* Conditions: */



-(TightdbQuery *)boolIsEqualTo:(bool)aBool inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)intIsEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)floatIsEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)doubleIsEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)stringIsEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)stringIsCaseInsensitiveEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)dateIsEqualTo:(time_t)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)binaryIsEqualTo:(TightdbBinary *)aBinary inColumnWithIndex:(NSUInteger)colIndex;


-(TightdbQuery *)intIsNotEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)floatIsNotEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)doubleIsNotEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)stringIsNotEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)stringIsNotCaseInsensitiveEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)dateIsNotEqualTo:(time_t)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)binaryIsNotEqualTo:(TightdbBinary *)aBinary inColumnWithIndex:(NSUInteger)colIndex;

-(TightdbQuery *)dateIsGreaterThan:(time_t)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)intIsGreaterThan:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)floatIsGreaterThan:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)doubleIsGreaterThan:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;

-(TightdbQuery *)dateIsGreaterThanOrEqualTo:(time_t)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)intIsGreaterThanOrEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)floatIsGreaterThanOrEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)doubleIsGreaterThanOrEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;

-(TightdbQuery *)dateIsLessThan:(time_t)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)intIsLessThan:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)floatIsLessThan:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)doubleIsLessThan:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;

-(TightdbQuery *)dateIsLessThanOrEqualTo:(time_t)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)intIsLessThanOrEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)floatIsLessThanOrEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(TightdbQuery *)doubleIsLessThanOrEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;




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
-(int64_t)min;
-(int64_t)max;
-(int64_t)sum;
-(double)avg;
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
-(float)min;
-(float)max;
-(double)sum;
-(double)avg;
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
-(double)min;
-(double)max;
-(double)sum;
-(double)avg;
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
