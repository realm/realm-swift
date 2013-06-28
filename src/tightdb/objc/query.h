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
@class TightdbTableView;


@interface TightdbQuery: NSObject
-(id)initWithTable:(TightdbTable *)table;
-(id)initWithTable:(TightdbTable *)table error:(NSError *__autoreleasing *)error;
-(TightdbTable *)getTable;
-(void)group;
-(void)or;
-(void)endgroup;
-(void)subtable:(size_t)column;
-(void)parent;
-(size_t)count;
-(size_t)remove;
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
// Conditions
-(TightdbQuery *)betweenInt:(int64_t)from to:(int64_t)to colNdx:(size_t)colNdx;
-(TightdbQuery *)betweenFloat:(float)from to:(float)to colNdx:(size_t)colNdx;
-(TightdbQuery *)betweenDouble:(double)from to:(double)to colNdx:(size_t)colNdx;
@end


@interface TightdbQueryAccessorBool: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)equal:(BOOL)value;
@end


@interface TightdbQueryAccessorInt: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)equal:(int64_t)value;
-(TightdbQuery *)notEqual:(int64_t)value;
-(TightdbQuery *)greater:(int64_t)value;
-(TightdbQuery *)greaterEqual:(int64_t)value;
-(TightdbQuery *)less:(int64_t)value;
-(TightdbQuery *)lessEqual:(int64_t)value;
-(TightdbQuery *)between:(int64_t)from to:(int64_t)to;
-(int64_t)min;
-(int64_t)max;
-(int64_t)sum;
-(double)avg;
@end


@interface TightdbQueryAccessorFloat: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)equal:(float)value;
-(TightdbQuery *)notEqual:(float)value;
-(TightdbQuery *)greater:(float)value;
-(TightdbQuery *)greaterEqual:(float)value;
-(TightdbQuery *)less:(float)value;
-(TightdbQuery *)lessEqual:(float)value;
-(TightdbQuery *)between:(float)from to:(float)to;
-(float)min;
-(float)max;
-(double)sum;
-(double)avg;
@end


@interface TightdbQueryAccessorDouble: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)equal:(double)value;
-(TightdbQuery *)notEqual:(double)value;
-(TightdbQuery *)greater:(double)value;
-(TightdbQuery *)greaterEqual:(double)value;
-(TightdbQuery *)less:(double)value;
-(TightdbQuery *)lessEqual:(double)value;
-(TightdbQuery *)between:(double)from to:(double)to;
-(double)min;
-(double)max;
-(double)sum;
-(double)avg;
@end


@interface TightdbQueryAccessorString: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)equal:(NSString *)value;
-(TightdbQuery *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(TightdbQuery *)notEqual:(NSString *)value;
-(TightdbQuery *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(TightdbQuery *)beginsWith:(NSString *)value;
-(TightdbQuery *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(TightdbQuery *)endsWith:(NSString *)value;
-(TightdbQuery *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(TightdbQuery *)contains:(NSString *)value;
-(TightdbQuery *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive;
@end


@interface TightdbQueryAccessorBinary: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)equal:(TightdbBinary *)value;
-(TightdbQuery *)notEqual:(TightdbBinary *)value;
-(TightdbQuery *)beginsWith:(TightdbBinary *)value;
-(TightdbQuery *)endsWith:(TightdbBinary *)value;
-(TightdbQuery *)contains:(TightdbBinary *)value;
@end


@interface TightdbQueryAccessorDate: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)equal:(time_t)value;
-(TightdbQuery *)notEqual:(time_t)value;
-(TightdbQuery *)greater:(time_t)value;
-(TightdbQuery *)greaterEqual:(time_t)value;
-(TightdbQuery *)less:(time_t)value;
-(TightdbQuery *)lessEqual:(time_t)value;
-(TightdbQuery *)between:(time_t)from to:(time_t)to;
@end


@interface TightdbQueryAccessorSubtable: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
@end


@interface TightdbQueryAccessorMixed: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
@end
