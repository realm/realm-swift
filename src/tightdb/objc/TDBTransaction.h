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

@class TDBTable;


@interface TDBTransaction: NSObject

@property (nonatomic, readonly) NSUInteger tableCount;




-(NSString *)getTableName:(NSUInteger)table_ndx;

-(BOOL)hasTableWithName:(NSString *)name;

/**
 * This method returns NO if it encounters a memory allocation error
 * (out of memory).
 *
 * The specified table class must be one that is declared by using
 * one of the table macros TIGHTDB_TABLE_*.
 */
-(BOOL)hasTableWithName:(NSString *)name withTableClass:(Class)obj;


/**
 * This method returns a table with the specified name from the group.
 * Returns nil if no table with the specified name exists.
 */
-(TDBTable *)getTableWithName:(NSString *)name;

/**
 * This method returns nil if it encounters a memory allocation error
 * (out of memory).
 */
-(TDBTable *)getOrCreateTableWithName:(NSString *)name;

/**
 * This method returns nil if the group already contains a table with
 * the specified name, but its type is incompatible with the
 * specified table class. This method also returns nil if it
 * encounters a memory allocation error (out of memory).
 *
 * The specified table class must be one that is declared by using
 * one of the table macros TIGHTDB_TABLE_*.
 */
-(id)getOrCreateTableWithName:(NSString *)name asTableClass:(Class)obj;






@end

