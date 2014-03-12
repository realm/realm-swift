/*************************************************************************
 *
 * TIGHTDB CONFIDENTIAL
 * __________________
 *
 *  [2011] - [2012] TightDB Inc
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

@class TightdbBinary;
@class TightdbTable;


@interface TightdbGroup: NSObject

+(TightdbGroup *)groupWithFile:(NSString *)filename withError:(NSError *__autoreleasing *)error;

/**
 * You pass the ownership of the specified buffer to the group. The
 * buffer will eventually be freed using the C function free(), so
 * the buffer you pass, must have been allocated using C function
 * malloc().
 */
+(TightdbGroup *)groupWithBuffer:(TightdbBinary *)buffer withError:(NSError *__autoreleasing *)error;

+(TightdbGroup *)group;

-(NSUInteger)getTableCount;
-(NSString *)getTableName:(NSUInteger)table_ndx;

-(BOOL)hasTable:(NSString *)name;

/**
 * This method returns NO if it encounters a memory allocation error
 * (out of memory).
 *
 * The specified table class must be one that is declared by using
 * one of the table macros TIGHTDB_TABLE_*.
 */
-(BOOL)hasTable:(NSString *)name withClass:(Class)obj;

/**
 * This method returns nil if it encounters a memory allocation error
 * (out of memory).
 */
-(TightdbTable *)getTable:(NSString *)name error:(NSError *__autoreleasing *)error;

/**
 * This method returns nil if the group already contains a table with
 * the specified name, but its type is incompatible with the
 * specified table class. This method also returns nil if it
 * encounters a memory allocation error (out of memory).
 *
 * The specified table class must be one that is declared by using
 * one of the table macros TIGHTDB_TABLE_*.
 */
-(id)getTable:(NSString *)name withClass:(Class)obj error:(NSError *__autoreleasing *)error;

/* Serialization */
-(BOOL)writeToFile:(NSString *)filePath withError:(NSError *__autoreleasing *)error;

/**
 * The ownership of the returned buffer is transferred to the
 * caller. The buffer will have been allocated using C function
 * malloc(), and it is the responsibility of the caller that C
 * function free() is eventually called to free the buffer.
 */
-(TightdbBinary *)writeToBuffer;

@end

