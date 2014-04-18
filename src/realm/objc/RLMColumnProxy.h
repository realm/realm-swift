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

#import "RLMTable.h"


@interface RLMColumnProxy : NSObject
@property(nonatomic, weak) RLMTable *table;
@property(nonatomic) size_t column;
-(id)initWithTable:(RLMTable *)table column:(NSUInteger)column;
-(void)clear;
@end

@interface RLMColumnProxyBool : RLMColumnProxy
-(NSUInteger)find:(BOOL)value;
@end

@interface RLMColumnProxyInt : RLMColumnProxy
-(NSUInteger)find:(int64_t)value;
-(int64_t)minimum;
-(int64_t)maximum;
-(int64_t)sum;
-(double)average;
@end

@interface RLMColumnProxyFloat : RLMColumnProxy
-(NSUInteger)find:(float)value;
-(float)minimum;
-(float)maximum;
-(double)sum;
-(double)average;
@end

@interface RLMColumnProxyDouble : RLMColumnProxy
-(NSUInteger)find:(double)value;
-(double)minimum;
-(double)maximum;
-(double)sum;
-(double)average;
@end

@interface RLMColumnProxyString : RLMColumnProxy
-(NSUInteger)find:(NSString *)value;
@end

@interface RLMColumnProxyBinary : RLMColumnProxy
-(NSUInteger)find:(NSData *)value;
@end

@interface RLMColumnProxyDate : RLMColumnProxy
-(NSUInteger)find:(NSDate *)value;
@end

@interface RLMColumnProxySubtable : RLMColumnProxy
@end

@interface RLMColumnProxyMixed : RLMColumnProxy
-(NSUInteger)find:(id)value;
@end
