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
@class TightdbTableView; // jjepsen: this must be an error?

// jjepsen: please review this
@class TightdbView;


@interface TightdbQuery: NSObject <NSFastEnumeration>
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

// jjepsen: started naming convention updateting here, more will follow. Kept old methods for now.
-(NSNumber *)minimumIntOfColumn:(size_t)colNdx;
-(NSNumber *)minimumIntOfColumn:(size_t)colNdx withError:(NSError *__autoreleasing *)error;

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

// jjepsen: please review this.
-(TightdbView *)findAll;

-(NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained *)stackbuf count:(NSUInteger)len;

// Conditions:

-(TightdbQuery *)column:(size_t)colNdx isBetweenInt:(int64_t)from and_:(int64_t)to;	
-(TightdbQuery *)column:(size_t)colNdx isBetweenFloat:(float)from and_:(float)to;	
-(TightdbQuery *)column:(size_t)colNdx isBetweenDouble:(double)from and_:(double)to;	
-(TightdbQuery *)column:(size_t)colNdx isBetweenDate:(time_t)from and_:(time_t)to;	

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
-(TightdbQuery *)columnIsEqualTo:(BOOL)value;
@end


@interface TightdbQueryAccessorInt: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)columnIsEqualTo:(int64_t)value;
-(TightdbQuery *)columnIsNotEqualTo:(int64_t)value;
-(TightdbQuery *)columnIsGreaterThan:(int64_t)value;
-(TightdbQuery *)columnIsGreaterThanOrEqualTo:(int64_t)value;
-(TightdbQuery *)columnIsLessThan:(int64_t)value;
-(TightdbQuery *)columnIsLessThanOrEqualTo:(int64_t)value;
-(TightdbQuery *)columnIsBetween:(int64_t)from and_:(int64_t)to;
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
-(TightdbQuery *)columnIsEqualTo:(float)value;
-(TightdbQuery *)columnIsNotEqualTo:(float)value;
-(TightdbQuery *)columnIsGreaterThan:(float)value;
-(TightdbQuery *)columnIsGreaterThanOrEqualTo:(float)value;
-(TightdbQuery *)columnIsLessThan:(float)value;
-(TightdbQuery *)columnIsLessThanOrEqualTo:(float)value;
-(TightdbQuery *)columnIsBetween:(float)from and_:(float)to;
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
-(TightdbQuery *)columnIsEqualTo:(double)value;
-(TightdbQuery *)columnIsNotEqualTo:(double)value;
-(TightdbQuery *)columnIsGreaterThan:(double)value;
-(TightdbQuery *)columnIsGreaterThanOrEqualTo:(double)value;
-(TightdbQuery *)columnIsLessThan:(double)value;
-(TightdbQuery *)columnIsLessThanOrEqualTo:(double)value;
-(TightdbQuery *)columnIsBetween:(double)from and_:(double)to;
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
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)columnIsEqualTo:(TightdbBinary *)value;
-(TightdbQuery *)columnIsNotEqualTo:(TightdbBinary *)value;
-(TightdbQuery *)columnBeginsWith:(TightdbBinary *)value;
-(TightdbQuery *)columnEndsWith:(TightdbBinary *)value;
-(TightdbQuery *)columnContains:(TightdbBinary *)value;
@end


@interface TightdbQueryAccessorDate: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
-(TightdbQuery *)columnIsEqualTo:(time_t)value;
-(TightdbQuery *)columnIsNotEqualTo:(time_t)value;
-(TightdbQuery *)columnIsGreaterThan:(time_t)value;
-(TightdbQuery *)columnIsGreaterThanOrEqualTo:(time_t)value;
-(TightdbQuery *)columnIsLessThan:(time_t)value;
-(TightdbQuery *)columnIsLessThanOrEqualTo:(time_t)value;
-(TightdbQuery *)columnIsBetween:(time_t)from and_:(time_t)to;
@end


@interface TightdbQueryAccessorSubtable: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
@end


@interface TightdbQueryAccessorMixed: NSObject
-(id)initWithColumn:(size_t)columnId query:(TightdbQuery *)query;
@end
