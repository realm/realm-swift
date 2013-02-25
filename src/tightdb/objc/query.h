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

#pragma mark - Query

@class Table;
@class TableView;


@interface Query : NSObject
-(id)initWithTable:(Table *)table;
-(Table *)getTable;
-(void)group;
-(void)or;
-(void)endgroup;
-(void)subtable:(size_t)column;
-(void)parent;
-(size_t)count;
-(int64_t)minInt:(size_t)colNdx;
-(float)minFloat:(size_t)colNdx;
-(double)minDouble:(size_t)colNdx;
-(int64_t)maxInt:(size_t)colNdx;
-(float)maxFloat:(size_t)colNdx;
-(double)maxDouble:(size_t)colNdx;
-(int64_t)sumInt:(size_t)colNdx;
-(double)sumFloat:(size_t)colNdx;
-(double)sumDouble:(size_t)colNdx;
-(double)avgInt:(size_t)colNdx;
-(double)avgFloat:(size_t)colNdx;
-(double)avgDouble:(size_t)colNdx;
-(size_t)findNext:(size_t)last;
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;
//-(void)clear;
@end


#pragma mark - OCXQueryAccessorBool

@interface OCXQueryAccessorBool : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
-(Query *)equal:(BOOL)value;
@end


#pragma mark - OCXQueryAccessorInt

@interface OCXQueryAccessorInt : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
-(Query *)equal:(int64_t)value;
-(Query *)notEqual:(int64_t)value;
-(Query *)greater:(int64_t)value;
-(Query *)greaterEqual:(int64_t)value;
-(Query *)less:(int64_t)value;
-(Query *)lessEqual:(int64_t)value;
-(Query *)between:(int64_t)from to:(int64_t)to;
-(int64_t)min;
-(int64_t)max;
-(int64_t)sum;
-(double)avg;
@end


#pragma mark - OCXQueryAccessorFloat

@interface OCXQueryAccessorFloat : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
-(Query *)equal:(float)value;
-(Query *)notEqual:(float)value;
-(Query *)greater:(float)value;
-(Query *)greaterEqual:(float)value;
-(Query *)less:(float)value;
-(Query *)lessEqual:(float)value;
-(Query *)between:(float)from to:(float)to;
-(float)min;
-(float)max;
-(double)sum;
-(double)avg;
@end


#pragma mark - OCXQueryAccessorDouble

@interface OCXQueryAccessorDouble : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
-(Query *)equal:(double)value;
-(Query *)notEqual:(double)value;
-(Query *)greater:(double)value;
-(Query *)greaterEqual:(double)value;
-(Query *)less:(double)value;
-(Query *)lessEqual:(double)value;
-(Query *)between:(double)from to:(double)to;
-(double)min;
-(double)max;
-(double)sum;
-(double)avg;
@end


#pragma mark - OCXQueryAccessorString

@interface OCXQueryAccessorString : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
-(Query *)equal:(NSString *)value;
-(Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(Query *)notEqual:(NSString *)value;
-(Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(Query *)beginsWith:(NSString *)value;
-(Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(Query *)endsWith:(NSString *)value;
-(Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(Query *)contains:(NSString *)value;
-(Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive;
@end


#pragma mark - OCXQueryAccessorBinary

@interface OCXQueryAccessorBinary : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
@end


#pragma mark - OCXQueryAccessorDate

@interface OCXQueryAccessorDate : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
-(Query *)equal:(time_t)value;
-(Query *)notEqual:(time_t)value;
-(Query *)greater:(time_t)value;
-(Query *)greaterEqual:(time_t)value;
-(Query *)less:(time_t)value;
-(Query *)lessEqual:(time_t)value;
-(Query *)between:(time_t)from to:(time_t)to;
@end


#pragma mark - OCXQueryAccessorSubtable

@interface OCXQueryAccessorSubtable : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
@end


#pragma mark - OCXQueryAccessorMixed

@interface OCXQueryAccessorMixed : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
@end
