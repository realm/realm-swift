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

@class RLMTable;
@class RLMView;


@interface RLMQuery : NSObject <NSFastEnumeration>
-(id)initWithTable:(RLMTable *)table;
-(id)initWithTable:(RLMTable *)table error:(NSError *__autoreleasing *)error;
-(RLMTable *)originTable;

// Combiners
-(RLMQuery *)group;
-(RLMQuery *)Or;
-(RLMQuery *)endGroup;
-(RLMQuery *)subtableInColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)parent;

// Actions
-(NSUInteger)countRows;
-(NSUInteger)removeRows;

// Aggregates
-(id)minInColumnWithIndex:(NSUInteger)colIndex;
-(id)maxInColumnWithIndex:(NSUInteger)colIndex;
-(NSNumber *)sumColumnWithIndex:(NSUInteger)colIndex;
-(NSNumber *)avgColumnWithIndex:(NSUInteger)colIndex;

// Search
-(NSUInteger)indexOfFirstMatchingRow;
-(NSUInteger)indexOfFirstMatchingRowFromIndex:(NSUInteger)rowIndex;
-(RLMView *)findAllRows;

// Conditions
-(RLMQuery *)boolIsEqualTo:(bool)aBool inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)intIsEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)floatIsEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)doubleIsEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)stringIsEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)stringIsCaseInsensitiveEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)dateIsEqualTo:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)binaryIsEqualTo:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex;

-(RLMQuery *)intIsNotEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)floatIsNotEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)doubleIsNotEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)stringIsNotEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)stringIsNotCaseInsensitiveEqualTo:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)dateIsNotEqualTo:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)binaryIsNotEqualTo:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex;

-(RLMQuery *)dateIsBetween:(NSDate *)lower :(NSDate *)upper inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)intIsBetween:(int64_t)lower :(int64_t)upper inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)floatIsBetween:(float)lower :(float)upper inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)doubleIsBetween:(double)lower :(double)upper inColumnWithIndex:(NSUInteger)colIndex;

-(RLMQuery *)dateIsGreaterThan:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)intIsGreaterThan:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)floatIsGreaterThan:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)doubleIsGreaterThan:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;

-(RLMQuery *)dateIsGreaterThanOrEqualTo:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)intIsGreaterThanOrEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)floatIsGreaterThanOrEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)doubleIsGreaterThanOrEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;

-(RLMQuery *)dateIsLessThan:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)intIsLessThan:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)floatIsLessThan:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)doubleIsLessThan:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;

-(RLMQuery *)dateIsLessThanOrEqualTo:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)intIsLessThanOrEqualTo:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)floatIsLessThanOrEqualTo:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(RLMQuery *)doubleIsLessThanOrEqualTo:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;

// FIXME:
// -(RLMQuery *)beginsWith:(NSString *)value
// -(RLMQuery *)endsWith:(NSString *)value
// -(RLMQuery *)contains:(NSString *)value

@end


@interface RLMQueryAccessorBool : NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query;
// FIXME: Rename columnIsEqualTo to isEqualTo and likewise for all
// predicates in all the other column proxies
// below. E.g. columnIsBetween:and_: -> isBetween:and_:
-(RLMQuery *)columnIsEqualTo:(BOOL)value;
@end


@interface RLMQueryAccessorInt : NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query;
-(RLMQuery *)columnIsEqualTo:(int64_t)value;
-(RLMQuery *)columnIsNotEqualTo:(int64_t)value;
-(RLMQuery *)columnIsGreaterThan:(int64_t)value;
-(RLMQuery *)columnIsGreaterThanOrEqualTo:(int64_t)value;
-(RLMQuery *)columnIsLessThan:(int64_t)value;
-(RLMQuery *)columnIsLessThanOrEqualTo:(int64_t)value;
-(RLMQuery *)columnIsBetween:(int64_t)lower :(int64_t)upper;
-(int64_t)min;
-(int64_t)max;
-(int64_t)sum;
-(double)avg;
@end


@interface RLMQueryAccessorFloat : NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query;
-(RLMQuery *)columnIsEqualTo:(float)value;
-(RLMQuery *)columnIsNotEqualTo:(float)value;
-(RLMQuery *)columnIsGreaterThan:(float)value;
-(RLMQuery *)columnIsGreaterThanOrEqualTo:(float)value;
-(RLMQuery *)columnIsLessThan:(float)value;
-(RLMQuery *)columnIsLessThanOrEqualTo:(float)value;
-(RLMQuery *)columnIsBetween:(float)lower :(float)upper;
-(float)min;
-(float)max;
-(double)sum;
-(double)avg;
@end


@interface RLMQueryAccessorDouble : NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query;
-(RLMQuery *)columnIsEqualTo:(double)value;
-(RLMQuery *)columnIsNotEqualTo:(double)value;
-(RLMQuery *)columnIsGreaterThan:(double)value;
-(RLMQuery *)columnIsGreaterThanOrEqualTo:(double)value;
-(RLMQuery *)columnIsLessThan:(double)value;
-(RLMQuery *)columnIsLessThanOrEqualTo:(double)value;
-(RLMQuery *)columnIsBetween:(double)lower :(double)upper;
-(double)min;
-(double)max;
-(double)sum;
-(double)avg;
@end


@interface RLMQueryAccessorString : NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query;
-(RLMQuery *)columnIsEqualTo:(NSString *)value;
-(RLMQuery *)columnIsEqualTo:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(RLMQuery *)columnIsNotEqualTo:(NSString *)value;
-(RLMQuery *)columnIsNotEqualTo:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(RLMQuery *)columnBeginsWith:(NSString *)value;
-(RLMQuery *)columnBeginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(RLMQuery *)columnEndsWith:(NSString *)value;
-(RLMQuery *)columnEndsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(RLMQuery *)columnContains:(NSString *)value;
-(RLMQuery *)columnContains:(NSString *)value caseSensitive:(BOOL)caseSensitive;
@end


@interface RLMQueryAccessorBinary : NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query;
-(RLMQuery *)columnIsEqualTo:(NSData *)value;
-(RLMQuery *)columnIsNotEqualTo:(NSData *)value;
-(RLMQuery *)columnBeginsWith:(NSData *)value;
-(RLMQuery *)columnEndsWith:(NSData *)value;
-(RLMQuery *)columnContains:(NSData *)value;
@end


@interface RLMQueryAccessorDate : NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query;
-(RLMQuery *)columnIsEqualTo:(NSDate *)value;
-(RLMQuery *)columnIsNotEqualTo:(NSDate *)value;
-(RLMQuery *)columnIsGreaterThan:(NSDate *)value;
-(RLMQuery *)columnIsGreaterThanOrEqualTo:(NSDate *)value;
-(RLMQuery *)columnIsLessThan:(NSDate *)value;
-(RLMQuery *)columnIsLessThanOrEqualTo:(NSDate *)value;
-(RLMQuery *)columnIsBetween:(NSDate *)lower :(NSDate *)upper;
@end


@interface RLMQueryAccessorSubtable : NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query;
@end


@interface RLMQueryAccessorMixed : NSObject
-(id)initWithColumn:(NSUInteger)columnId query:(RLMQuery *)query;
@end
