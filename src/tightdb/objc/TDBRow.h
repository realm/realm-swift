/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2014] TightDB Inc
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

@class TDBTable;

@interface TDBRow: NSObject
-(id)initWithTable:(TDBTable *)table ndx:(NSUInteger)ndx;
-(void)TDBSetNdx:(NSUInteger)ndx;
-(NSUInteger)TDBIndex;

-(id)objectAtIndexedSubscript:(NSUInteger)colNdx;
-(id)objectForKeyedSubscript:(id <NSCopying>)key;
-(void)setObject:(id)obj atIndexedSubscript:(NSUInteger)colNdx;
-(void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;

-(void)setInt:(int64_t)anInt inColumnWithIndex:(NSUInteger)colIndex;
-(void)setString:(NSString *)aString inColumnWithIndex:(NSUInteger)colIndex;
-(void)setBool:(BOOL)aBool inColumnWithIndex:(NSUInteger)colIndex;
-(void)setFloat:(float)aFloat inColumnWithIndex:(NSUInteger)colIndex;
-(void)setDouble:(double)aDouble inColumnWithIndex:(NSUInteger)colIndex;
-(void)setDate:(NSDate *)aDate inColumnWithIndex:(NSUInteger)colIndex;
-(void)setBinary:(NSData *)aBinary inColumnWithIndex:(NSUInteger)colIndex;
-(void)setMixed:(id)aMixed inColumnWithIndex:(NSUInteger)colIndex;
-(void)setTable:(TDBTable *)aTable inColumnWithIndex:(NSUInteger)colIndex;

-(int64_t)intInColumnWithIndex:(NSUInteger)colIndex;
-(NSString *)stringInColumnWithIndex:(NSUInteger)colIndex;
-(BOOL)boolInColumnWithIndex:(NSUInteger)colIndex;
-(float)floatInColumnWithIndex:(NSUInteger)colIndex;
-(double)doubleInColumnWithIndex:(NSUInteger)colIndex;
-(NSDate *)dateInColumnWithIndex:(NSUInteger)colIndex;
-(NSData *)binaryInColumnWithIndex:(NSUInteger)colIndex;
-(id)mixedInColumnWithIndex:(NSUInteger)colIndex;
-(TDBTable *)tableInColumnWithIndex:(NSUInteger)colIndex;

@end


/* FIXME: This class can be (and should be) eliminated by using a
   macro switching trick for the individual column types on
   TIGHTDB_CURSOR_PROPERTY macros similar to what is done for query
   accessors. */
@interface TDBAccessor: NSObject
-(id)initWithRow:(TDBRow *)cursor columnId:(NSUInteger)columnId;
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
-(NSData *)getBinary;
-(void)setBinary:(NSData *)value;
-(NSDate *)getDate;
-(void)setDate:(NSDate *)value;
-(void)setSubtable:(TDBTable *)value;
-(id)getSubtable:(Class)obj;
-(id)getMixed;
-(void)setMixed:(id)value;
@end
