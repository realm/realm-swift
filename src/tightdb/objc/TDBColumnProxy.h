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
#import "TDBTable.h"
#import "TDBMixed.h"

@interface TDBColumnProxy: NSObject
@property(nonatomic, weak) TDBTable *table;
@property(nonatomic) size_t column;
-(id)initWithTable:(TDBTable *)table column:(NSUInteger)column;
-(void)clear;
@end

@interface TDBColumnProxy_Bool: TDBColumnProxy
-(NSUInteger)find:(BOOL)value;
@end

@interface TDBColumnProxy_Int: TDBColumnProxy
-(NSUInteger)find:(int64_t)value;
-(int64_t)minimum;
-(int64_t)maximum;
-(int64_t)sum;
-(double)average;
@end

@interface TDBColumnProxy_Float: TDBColumnProxy
-(NSUInteger)find:(float)value;
-(float)minimum;
-(float)maximum;
-(double)sum;
-(double)average;
@end

@interface TDBColumnProxy_Double: TDBColumnProxy
-(NSUInteger)find:(double)value;
-(double)minimum;
-(double)maximum;
-(double)sum;
-(double)average;
@end

@interface TDBColumnProxy_String: TDBColumnProxy
-(NSUInteger)find:(NSString *)value;
@end

@interface TDBColumnProxy_Binary: TDBColumnProxy
-(NSUInteger)find:(NSData *)value;
@end

@interface TDBColumnProxy_Date: TDBColumnProxy
-(NSUInteger)find:(NSDate *)value;
@end

@interface TDBColumnProxy_Subtable: TDBColumnProxy
@end

@interface TDBColumnProxy_Mixed: TDBColumnProxy
-(NSUInteger)find:(TDBMixed *)value;
@end
