//
//  OCQuery.h
//  TightDB
//

#import <Foundation/Foundation.h>

#pragma mark - OCQuery

@class OCTable;
@class OCTableView;


@interface OCQuery : NSObject

-(void)group;
-(void)or;
-(void)endgroup;
-(void)subtable:(size_t)column;
-(void)parent;
-(size_t)count:(OCTable *)table;
-(double)avg:(OCTable *)table column:(size_t)columndId resultCount:(size_t*)resultCount;
-(OCTableView *)findAll:(OCTable *)table;
@end

#pragma mark - OCXQueryAccessorInt

@interface OCXQueryAccessorInt : NSObject
-(id)initWithColumn:(size_t)columnId query:(OCQuery *)query;
-(OCQuery *)equal:(int64_t)value;
-(OCQuery *)notEqual:(int64_t)value;
-(OCQuery *)greater:(int64_t)value;
-(OCQuery *)less:(int64_t)value;
-(OCQuery *)between:(int64_t)from to:(int64_t)to;
@end

#pragma mark - OCXQueryAccessorBool

@interface OCXQueryAccessorBool : NSObject
-(id)initWithColumn:(size_t)columnId query:(OCQuery *)query;
-(OCQuery *)equal:(BOOL)value;
@end

#pragma mark - OCXQueryAccessorString

@interface OCXQueryAccessorString : NSObject
-(id)initWithColumn:(size_t)columnId query:(OCQuery *)query;
-(OCQuery *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(OCQuery *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(OCQuery *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(OCQuery *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(OCQuery *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive;
@end

