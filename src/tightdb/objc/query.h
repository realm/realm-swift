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
-(TightdbQuery *)group;
-(TightdbQuery *)or;
-(TightdbQuery *)endgroup;
-(void)subtable:(size_t)column;
-(void)parent;
-(NSNumber *)count;
-(NSNumber *)countWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)remove;
-(NSNumber *)removeWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)minInt:(size_t)colNdx;
-(NSNumber *)minInt:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)minFloat:(size_t)colNdx;
-(NSNumber *)minFloat:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)minDouble:(size_t)colNdx;
-(NSNumber *)minDouble:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)maxInt:(size_t)colNdx;
-(NSNumber *)maxInt:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)maxFloat:(size_t)colNdx;
-(NSNumber *)maxFloat:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)maxDouble:(size_t)colNdx;
-(NSNumber *)maxDouble:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)sumInt:(size_t)colNdx;
-(NSNumber *)sumInt:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)sumFloat:(size_t)colNdx;
-(NSNumber *)sumFloat:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)sumDouble:(size_t)colNdx;
-(NSNumber *)sumDouble:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)avgInt:(size_t)colNdx;
-(NSNumber *)avgInt:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)avgFloat:(size_t)colNdx;
-(NSNumber *)avgFloat:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(NSNumber *)avgDouble:(size_t)colNdx;
-(NSNumber *)avgDouble:(size_t)colNdx error:(NSError *__autoreleasing *)error;
-(size_t)findNext:(size_t)last;
-(size_t)findNext:(size_t)last error:(NSError *__autoreleasing *)error;
-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;

// Conditions:

-(TightdbQuery *)column:(size_t)colNdx isBetweenInt:(int64_t)from and:(int64_t)to;	
-(TightdbQuery *)column:(size_t)colNdx isBetweenFloat:(float)from and:(float)to;	
-(TightdbQuery *)column:(size_t)colNdx isBetweenDouble:(double)from and:(double)to;	

-(TightdbQuery *)column:(size_t)colNdx isEqualToBool:(bool)value;
-(TightdbQuery *)column:(size_t)colNdx isEqualToInt:(int64_t)value;
-(TightdbQuery *)column:(size_t)colNdx isEqualToFloat:(float)value;
-(TightdbQuery *)column:(size_t)colNdx isEqualToDouble:(double)value;
-(TightdbQuery *)column:(size_t)colNdx isEqualToString:(NSString *)value;
-(TightdbQuery *)column:(size_t)colNdx isEqualToString:(NSString *)value caseSensitive:(bool)caseSensitive;
-(TightdbQuery *)column:(size_t)colNdx isEqualToDate:(time_t)value;
-(TightdbQuery *)column:(size_t)colNdx isEqualToBinary:(TightdbBinary *)value;

-(TightdbQuery *)column:(size_t)colNdx isNotEqualToInt:(int64_t)value;
-(TightdbQuery *)column:(size_t)colNdx isNotEqualToFloat:(float)value;
-(TightdbQuery *)column:(size_t)colNdx isNotEqualToDouble:(double)value;
-(TightdbQuery *)column:(size_t)colNdx isNotEqualToString:(NSString *)value;
-(TightdbQuery *)column:(size_t)colNdx isNotEqualToString:(NSString *)value caseSensitive:(bool)caseSensitive;
-(TightdbQuery *)column:(size_t)colNdx isNotEqualToDate:(time_t)value;
-(TightdbQuery *)column:(size_t)colNdx isNotEqualToBinary:(TightdbBinary *)value;

-(TightdbQuery *)column:(size_t)colNdx isGreaterThanInt:(int64_t)value;
-(TightdbQuery *)column:(size_t)colNdx isGreaterThanFloat:(float)value;
-(TightdbQuery *)column:(size_t)colNdx isGreaterThanDouble:(double)value;
-(TightdbQuery *)column:(size_t)colNdx isGreaterThanDate:(time_t)value;

-(TightdbQuery *)column:(size_t)colNdx isGreaterThanOrEqualToInt:(int64_t)value;
-(TightdbQuery *)column:(size_t)colNdx isGreaterThanOrEqualToFloat:(float)value;
-(TightdbQuery *)column:(size_t)colNdx isGreaterThanOrEqualToDouble:(double)value;
-(TightdbQuery *)column:(size_t)colNdx isGreaterThanOrEqualToDate:(time_t)value;

-(TightdbQuery *)column:(size_t)colNdx isLessThanInt:(int64_t)value;
-(TightdbQuery *)column:(size_t)colNdx isLessThanFloat:(float)value;
-(TightdbQuery *)column:(size_t)colNdx isLessThanDouble:(double)value;
-(TightdbQuery *)column:(size_t)colNdx isLessThanDate:(time_t)value;

-(TightdbQuery *)column:(size_t)colNdx isLessThanOrEqualToInt:(int64_t)value;
-(TightdbQuery *)column:(size_t)colNdx isLessThanOrEqualToFloat:(float)value;
-(TightdbQuery *)column:(size_t)colNdx isLessThanOrEqualToDouble:(double)value;
-(TightdbQuery *)column:(size_t)colNdx isLessThanOrEqualToDate:(time_t)value;


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
-(NSNumber *)min;
-(NSNumber *)minWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)max;
-(NSNumber *)maxWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)sum;
-(NSNumber *)sumWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)avg;
-(NSNumber *)avgWithError:(NSError *__autoreleasing *)error;
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
-(NSNumber *)min;
-(NSNumber *)minWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)max;
-(NSNumber *)maxWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)sum;
-(NSNumber *)sumWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)avg;
-(NSNumber *)avgWithError:(NSError *__autoreleasing *)error;
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
-(NSNumber *)min;
-(NSNumber *)minWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)max;
-(NSNumber *)maxWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)sum;
-(NSNumber *)sumWithError:(NSError *__autoreleasing *)error;
-(NSNumber *)avg;
-(NSNumber *)avgWithError:(NSError *__autoreleasing *)error;
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
