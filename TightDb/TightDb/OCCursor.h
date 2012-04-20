//
//  OCCursor.h
//  TightDb

#import <Foundation/Foundation.h>

@class OCTable;
@class OCMixed;

#pragma mark - OCCursorBase

@interface OCCursorBase : NSObject
-(id)initWithTable:(OCTable *)table ndx:(size_t)ndx;
@end


#pragma mark - OCAccessor

@interface OCAccessor : NSObject
-(id)initWithCursor:(OCCursorBase *)cursor columnId:(size_t)columnId;
-(int64_t)getInt;
-(void)setInt:(int64_t)value;
-(BOOL)getBool;
-(void)setBool:(BOOL)value;
-(time_t)getDate;
-(void)setDate:(time_t)value;
-(NSString *)getString;
-(void)setString:(NSString *)value;
-(OCMixed *)getMixed;
-(void)setMixed:(OCMixed *)value;
@end