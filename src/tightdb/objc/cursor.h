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

@class Table;
@class BinaryData;
@class OCMixed;

#pragma mark - CursorBase

@interface CursorBase : NSObject
-(id)initWithTable:(Table *)table ndx:(size_t)ndx;
-(void)setNdx:(size_t)ndx;
@end


#pragma mark - OCAccessor

/* FIXME: This class can be (and should be) eliminated by using a
   macro switching trick for the individual column types on
   TIGHTDB_CURSOR_PROPERTY macros similar to what is done for query
   accessors. */
@interface OCAccessor : NSObject
-(id)initWithCursor:(CursorBase *)cursor columnId:(size_t)columnId;
-(BOOL)getBool;
-(void)setBool:(BOOL)value;
-(int64_t)getInt;
-(void)setInt:(int64_t)value;
-(float)getFloat;
-(void)setFloat:(float)value;
-(double)getDouble;
-(void)setDouble:(double)value;
-(NSString *)getString;
-(void)setString:(NSString *)value;
-(BinaryData *)getBinary;
-(void)setBinary:(BinaryData *)value;
-(void)setBinary:(const char *)data size:(size_t)size;
-(time_t)getDate;
-(void)setDate:(time_t)value;
-(id)getSubtable:(Class)obj;
-(OCMixed *)getMixed;
-(void)setMixed:(OCMixed *)value;
@end
