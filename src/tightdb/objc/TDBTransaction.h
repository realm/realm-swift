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

@class TDBTable;


@interface TDBTransaction: NSObject

@property (nonatomic, readonly) NSUInteger tableCount;


/**
 * This method returns YES if a table with the specified name already exists. NO if it does not exist.
 */
-(BOOL)hasTableWithName:(NSString *)name;


/**
 * This method returns a table with the specified name from the group.
 * Returns nil if no table with the specified name exists.
 */
-(TDBTable *)getTableWithName:(NSString *)name;

/**
 * This method returns a table with the specified name from the group.
 * Returns nil if no table with the specified name exists.
 */
-(id)getTableWithName:(NSString *)name asTableClass:(Class)obj;

/**
 * This method creates a table with the specific name.
 * If a table with that name already exists, an exception is thrown.
 */
-(TDBTable *)createTableWithName:(NSString *)name;

/**
 * This method creates a table with the specified name as a specific table.
 * If a table with that name already exists, an exception is thrown.
 *
 * The specified table class must be one that is declared by using
 * one of the table macros TIGHTDB_TABLE_*.
 */
-(id)createTableWithName:(NSString *)name asTableClass:(Class)obj;



-(NSString *)nameOfTableWithIndex:(NSUInteger)tableIndex;


/**
 * This method will write the context to disk at the specified path.
 * Metadata and tables will be stored, and can be retrieved at later times.
 */
-(BOOL)writeContextToFile:(NSString *)path error:(NSError *__autoreleasing *)error;


#ifdef HAS_TABLE_WITH_NAME_AND_CLASS
/**
 * This method returns YES if a table with the specified name already exists. NO if it does not exists.
 *
 * The specified table class must be one that is declared by using
 * one of the table macros TIGHTDB_TABLE_*.
 */
-(BOOL)hasTableWithName:(NSString *)name withTableClass:(Class)obj;

#endif


@end

