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

#include <tightdb/table.hpp>

#import "RLMTable.h"


@interface RLMTable (noinst)

-(tightdb::Table&)getNativeTable;
-(void)setNativeTable:(tightdb::Table*)table;

-(void)setParent:(id)parent; // Workaround for ARC release problem.

-(void)setReadOnly:(BOOL)read_only;
-(BOOL)isReadOnly;

// Also returns NO if memory allocation fails.
-(BOOL)_checkType;

// Returns NO if memory allocation fails.
-(BOOL)_addColumns;


-(RLMRow *)addEmptyRow;
-(RLMRow *)insertEmptyRowAtIndex:(NSUInteger)rowIndex;

/* Aggregate functions */
/* FIXME: Consider adding:
 countRowsWithValue: @"foo"
 countRowsWithValue: @300 */
-(NSUInteger)countRowsWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)countRowsWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)countRowsWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)countRowsWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
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



-(NSUInteger)findRowIndexWithBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithBinary:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(NSUInteger)findRowIndexWithMixed:(id)aMixed inColumnWithIndex:(NSUInteger)colIndex;


-(RLMView *)findAllRowsWithBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex;
-(RLMView *)findAllRowsWithInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(RLMView *)findAllRowsWithFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(RLMView *)findAllRowsWithDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(RLMView *)findAllRowsWithString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(RLMView *)findAllRowsWithBinary:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex;
-(RLMView *)findAllRowsWithDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(RLMView *)findAllRowsWithMixed:(id)aMixed inColumnWithIndex:(NSUInteger)colIndex;

@end
