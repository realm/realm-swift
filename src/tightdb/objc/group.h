//
//  group.h
//  TightDb

#import <Foundation/Foundation.h>

@class OCToplevelTable;

@interface Group : NSObject
+(Group *)groupWithFilename:(NSString *)filename;
+(Group *)groupWithBuffer:(const char*)buffer len:(size_t)len;
+(Group *)group;
-(BOOL)isValid;

-(size_t)getTableCount;
-(NSString *)getTableName:(size_t)table_ndx;
-(BOOL)hasTable:(NSString *)name;

// Table stuff
-(id)getTable:(NSString *)name withClass:(Class)obj;

// Serialization
-(void)write:(NSString *)filePath;
-(char*)writeToMem:(size_t*)len;

// Conversion ??? TODO

@end

