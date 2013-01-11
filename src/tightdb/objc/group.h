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

@class Table;


@interface Group : NSObject
+(Group *)groupWithFilename:(NSString *)filename;
+(Group *)groupWithBuffer:(char*)buffer len:(size_t)len;
+(Group *)group;

-(size_t)getTableCount;
-(NSString *)getTableName:(size_t)table_ndx;

-(BOOL)hasTable:(NSString *)name;

/// This method returns NO if it encounters a memory allocation error
/// (out of memory).
///
/// The specified table class must be one that is declared by using
/// one of the table macros TIGHTDB_TABLE_*.
-(BOOL)hasTable:(NSString *)name withClass:(Class)obj;

/// This method returns nil if it encounters a memory allocation error
/// (out of memory).
-(Table *)getTable:(NSString *)name;

/// This method returns nil if the group already contains a table with
/// the specified name, but its type is incompatible with the
/// specified table class. This method also returns nil if it
/// encounters a memory allocation error (out of memory).
///
/// The specified table class must be one that is declared by using
/// one of the table macros TIGHTDB_TABLE_*.
-(id)getTable:(NSString *)name withClass:(Class)obj;

// Serialization
-(void)write:(NSString *)filePath;
-(char*)writeToMem:(size_t*)len;

// Conversion
// FIXME: Do we want to conversion methods? Maybe use NSData.

@end

