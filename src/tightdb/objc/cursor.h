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

@class TightdbTable;
@class TightdbBinary;
@class TightdbMixed;

@interface TightdbCursor: NSObject
-(id)initWithTable:(TightdbTable *)table ndx:(size_t)ndx;
-(void)setNdx:(size_t)ndx;
-(size_t)index;

-(void)setInt:(int64_t)value inColumn:(size_t)colNdx;
-(void)setString:(NSString *)value inColumn:(size_t)colNdx;
-(void)setBool:(BOOL)value inColumn:(size_t)colNdx;
-(void)setFloat:(float)value inColumn:(size_t)colNdx;
-(void)setDouble:(double)value inColumn:(size_t)colNdx;
-(void)setDate:(time_t)value inColumn:(size_t)colNdx;
-(void)setBinary:(TightdbBinary *)value inColumn:(size_t)colNdx;
-(void)setMixed:(TightdbMixed *)value inColumn:(size_t)colNdx;
-(void)setTable:(TightdbTable *)value inColumn:(size_t)colNdx;

-(int64_t)getIntInColumn:(size_t)colNdx;
-(NSString *)getStringInColumn:(size_t)colNdx;
-(BOOL)getBoolInColumn:(size_t)colNdx;
-(float)getFloatInColumn:(size_t)colNdx;
-(double)getDoubleInColumn:(size_t)colNdx;
-(time_t)getDateInColumn:(size_t)colNdx;
-(TightdbBinary *)getBinaryInColumn:(size_t)colNdx;
-(TightdbMixed *)getMixedInColumn:(size_t)colNdx;
-(TightdbTable *)getTableInColumn:(size_t)colNdx;

@end


/* FIXME: This class can be (and should be) eliminated by using a
   macro switching trick for the individual column types on
   TIGHTDB_CURSOR_PROPERTY macros similar to what is done for query
   accessors. */
@interface TightdbAccessor: NSObject
-(id)initWithCursor:(TightdbCursor *)cursor columnId:(size_t)columnId;
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
-(TightdbBinary *)getBinary;
-(void)setBinary:(TightdbBinary *)value;
-(time_t)getDate;
-(void)setDate:(time_t)value;
-(void)setSubtable:(TightdbTable *)value;
-(id)getSubtable:(Class)obj;
-(TightdbMixed *)getMixed;
-(void)setMixed:(TightdbMixed *)value;
@end
