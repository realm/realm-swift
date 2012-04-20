//
//  OCGroup.h
//  TightDb
//
//  Created by Thomas Andersen on 17/04/12.
//  Copyright (c) 2012 InvulgoSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OCToplevelTable;

@interface OCGroup : NSObject
+(OCGroup *)groupWithFilename:(NSString *)filename;
+(OCGroup *)groupWithBuffer:(const char*)buffer len:(size_t)len;
+(OCGroup *)group;
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

