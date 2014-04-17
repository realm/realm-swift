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

@interface RLMQuery (Fast)

-(int64_t)minIntInColumnWithIndex:(NSUInteger)colIndex;
-(float)minFloatInColumnWithIndex:(NSUInteger)colIndex;
-(double)minDoubleInColumnWithIndex:(NSUInteger)colIndex;
-(NSDate *)minDateInColumnWithIndex:(NSUInteger)colIndex;

-(int64_t)maxIntInColumnWithIndex:(NSUInteger)colIndex;
-(float)maxFloatInColumnWithIndex:(NSUInteger)colIndex;
-(double)maxDoubleInColumnWithIndex:(NSUInteger)colIndex;
-(NSDate *)maxDateInColumnWithIndex:(NSUInteger)colIndex;

-(int64_t)sumIntColumnWithIndex:(NSUInteger)colIndex;
-(double)sumFloatColumnWithIndex:(NSUInteger)colIndex;
-(double)sumDoubleColumnWithIndex:(NSUInteger)colIndex;

-(double)avgIntColumnWithIndex:(NSUInteger)colIndex;
-(double)avgFloatColumnWithIndex:(NSUInteger)colIndex;
-(double)avgDoubleColumnWithIndex:(NSUInteger)colIndex;

@end
