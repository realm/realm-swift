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
#import "TDBTable_priv.h"
#import "TDBColumnProxy.h"

@implementation TDBColumnProxy
@synthesize table = _table, column = _column;
-(id)initWithTable:(TDBTable*)table column:(NSUInteger)column
{
    self = [super init];
    if (self) {
        _table = table;
        _column = column;
    }
    return self;
}
-(void)clear
{
    _table = nil;
}
@end

@implementation TDBColumnProxyBool
-(NSUInteger)find:(BOOL)value
{
    return [self.table findRowIndexWithBool:value inColumnWithIndex:self.column ];
}
@end

@implementation TDBColumnProxyInt
-(NSUInteger)find:(int64_t)value
{
    return [self.table findRowIndexWithInt:value inColumnWithIndex:self.column ];
}
-(int64_t)minimum
{
    return [self.table minIntInColumnWithIndex:self.column ];
}
-(int64_t)maximum
{
    return [self.table maxIntInColumnWithIndex:self.column ];
}
-(int64_t)sum
{
    return [self.table sumIntColumnWithIndex:self.column ];
}
-(double)average
{
    return [self.table avgIntColumnWithIndex:self.column ];
}
@end

@implementation TDBColumnProxyFloat
-(NSUInteger)find:(float)value
{
    return [self.table findRowIndexWithFloat:value inColumnWithIndex:self.column];
}
-(float)minimum
{
    return [self.table minFloatInColumnWithIndex:self.column];
}
-(float)maximum
{
    return [self.table maxFloatInColumnWithIndex:self.column];
}
-(double)sum
{
    return [self.table sumFloatColumnWithIndex:self.column];
}
-(double)average
{
    return [self.table avgFloatColumnWithIndex:self.column];
}
@end

@implementation TDBColumnProxyDouble
-(NSUInteger)find:(double)value
{
    return [self.table findRowIndexWithDouble:value inColumnWithIndex:self.column];
}
-(double)minimum
{
    return [self.table minDoubleInColumnWithIndex:self.column];
}
-(double)maximum
{
    return [self.table maxDoubleInColumnWithIndex:self.column];
}
-(double)sum
{
    return [self.table sumDoubleColumnWithIndex:self.column];
}
-(double)average
{
    return [self.table avgDoubleColumnWithIndex:self.column];
}
@end

@implementation TDBColumnProxyString
-(NSUInteger)find:(NSString*)value
{
    return [self.table findRowIndexWithString:value inColumnWithIndex:self.column];
}
@end

@implementation TDBColumnProxyBinary
-(NSUInteger)find:(TDBBinary*)value
{
    return [self.table findRowIndexWithBinary:value inColumnWithIndex:self.column];
}
@end

@implementation TDBColumnProxyDate
-(NSUInteger)find:(NSDate *)value
{
    return [self.table findRowIndexWithDate:value inColumnWithIndex:self.column];
}
@end

@implementation TDBColumnProxySubtable
@end

@implementation TDBColumnProxyMixed
-(NSUInteger)find:(TDBMixed*)value
{
    return [self.table findRowIndexWithMixed:value inColumnWithIndex:self.column];
}
@end

