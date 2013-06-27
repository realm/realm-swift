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
@end


/* FIXME: This class can be (and should be) eliminated by using a
   macro switching trick for the individual column types on
   TIGHTDB_CURSOR_PROPERTY macros similar to what is done for query
   accessors. */
@interface TightdbAccessor: NSObject
-(id)initWithCursor:(TightdbCursor *)cursor columnId:(size_t)columnId;
-(BOOL)getBool;
-(BOOL)setBool:(BOOL)value;
-(BOOL)setBool:(BOOL)value error:(NSError *__autoreleasing *)error;
-(int64_t)getInt;
-(BOOL)setInt:(int64_t)value;
-(BOOL)setInt:(int64_t)value error:(NSError *__autoreleasing *)error;
-(float)getFloat;
-(BOOL)setFloat:(float)value;
-(BOOL)setFloat:(float)value error:(NSError *__autoreleasing *)error;
-(double)getDouble;
-(BOOL)setDouble:(double)value;
-(BOOL)setDouble:(double)value error:(NSError *__autoreleasing *)error;
-(NSString *)getString;
-(BOOL)setString:(NSString *)value;
-(BOOL)setString:(NSString *)value error:(NSError *__autoreleasing *)error;
-(TightdbBinary *)getBinary;
-(BOOL)setBinary:(TightdbBinary *)value;
-(BOOL)setBinary:(TightdbBinary *)value error:(NSError *__autoreleasing *)error;
-(BOOL)setBinary:(const char *)data size:(size_t)size;
-(BOOL)setBinary:(const char *)data size:(size_t)size error:(NSError *__autoreleasing *)error;
-(time_t)getDate;
-(BOOL)setDate:(time_t)value;
-(BOOL)setDate:(time_t)value error:(NSError *__autoreleasing *)error;
-(id)getSubtable:(Class)obj;
-(TightdbMixed *)getMixed;
-(BOOL)setMixed:(TightdbMixed *)value;
-(BOOL)setMixed:(TightdbMixed *)value error:(NSError *__autoreleasing *)error;
@end
