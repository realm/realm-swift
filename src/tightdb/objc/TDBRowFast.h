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

@interface TDBRow (Fast)

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
