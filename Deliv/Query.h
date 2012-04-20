//
//  Query.h
//  TightDB
//

#import <Foundation/Foundation.h>

#pragma mark - Query

@class Table;
@class TableView;


@interface Query : NSObject

-(void)group;
-(void)or;
-(void)endgroup;
-(void)subtable:(size_t)column;
-(void)parent;
-(size_t)count:(Table *)table;
-(double)avg:(Table *)table column:(size_t)columndId resultCount:(size_t*)resultCount;
-(TableView *)findAll:(Table *)table;
@end

#pragma mark - OCXQueryAccessorInt

@interface OCXQueryAccessorInt : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
-(Query *)equal:(int64_t)value;
-(Query *)notEqual:(int64_t)value;
-(Query *)greater:(int64_t)value;
-(Query *)less:(int64_t)value;
-(Query *)between:(int64_t)from to:(int64_t)to;
@end

#pragma mark - OCXQueryAccessorBool

@interface OCXQueryAccessorBool : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
-(Query *)equal:(BOOL)value;
@end

#pragma mark - OCXQueryAccessorString

@interface OCXQueryAccessorString : NSObject
-(id)initWithColumn:(size_t)columnId query:(Query *)query;
-(Query *)equal:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(Query *)notEqual:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(Query *)beginsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(Query *)endsWith:(NSString *)value caseSensitive:(BOOL)caseSensitive;
-(Query *)contains:(NSString *)value caseSensitive:(BOOL)caseSensitive;
@end

