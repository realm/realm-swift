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
-(double)avgOnColumn:(size_t)columndId;
-(size_t)findNext:(size_t)last;
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;
//-(void)clear;
@end

#pragma mark - OCXQueryAccessorInt

@interface OCXQueryAccessorInt : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
-(Query *)equal:(int64_t)value;
-(Query *)notEqual:(int64_t)value;
-(Query *)greater:(int64_t)value;
-(Query *)less:(int64_t)value;
-(Query *)between:(int64_t)from to:(int64_t)to;
-(double)avg;
@end

#pragma mark - OCXQueryAccessorBool

@interface OCXQueryAccessorBool : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
-(Query *)equal:(BOOL)value;
@end

#pragma mark - OCXQueryAccessorDate

@interface OCXQueryAccessorDate : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
@end

#pragma mark - OCXQueryAccessorString

@interface OCXQueryAccessorString : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
-(Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive;
@end

#pragma mark - OCXQueryAccessorSubtable

@interface OCXQueryAccessorSubtable : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
@end

#pragma mark - OCXQueryAccessorMixed

@interface OCXQueryAccessorMixed : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
@end
