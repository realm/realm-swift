////////////////////////////////////////////////////////////////////////////
//
// TIGHTDB CONFIDENTIAL
// __________________
//
//  [2011] - [2014] TightDB Inc
//  All Rights Reserved.
//
// NOTICE:  All information contained herein is, and remains
// the property of TightDB Incorporated and its suppliers,
// if any.  The intellectual and technical concepts contained
// herein are proprietary to TightDB Incorporated
// and its suppliers and may be covered by U.S. and Foreign Patents,
// patents in process, and are protected by trade secret or copyright law.
// Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained
// from TightDB Incorporated.
//
////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "RLMContext.h"

@class RLMTable;

/**
 `RLMRealm` is a class that provides fully ACID compliant access to `RLMTable`'s.
 
 `RLMRealm` objects are used for writing or reading tables. These tables are 
 persisted to disk, and changes to the tables are done through explicit transactions 
 within write blocks on a context.
 
 Implicit transactions are updated at intervals of the runloop cycle only when 
 there are new changes available. This implies that an update to a table is either 
 stored or will fail, and the context is thereby always consistent.
 
 Realm objects can either be created independently, or by an `RLMContext`'s 
 write/read block.
 
 Using a realm, you can access your data within the main thread of your 
 application, without the need for an explicit context or transactions. The file 
 format used by Realm can be used on any platform, and data can be accessed by 
 any language Realm supports.
 */
@interface RLMRealm : NSObject

#pragma mark - Constructors

///------------------------------------------------
/// @name Constructors
///------------------------------------------------

/**
 Creates a stand-alone `RLMRealm` at the default file path that lives outside any
 explicit `RLMContext`. Can only be called on the main thread.
 
 @return The newly initialized realm.
 */
+ (instancetype)realmWithDefaultPersistence;

/**
 Creates a stand-alone `RLMRealm` at the default file path that lives outside any 
 explicit `RLMContext`.
 
 Can only be called on the main thread. Runs an optional initialization block on
 a writable context before returning.
 
 @param initBlock The optional initialization block on a writable context before returning.
 
 @return The newly initialized realm.
 */
+ (instancetype)realmWithDefaultPersistenceAndInitBlock:(RLMWriteBlock)initBlock;

/**
 Creates a stand-alone `RLMRealm` at the specified file path that lives outside any
 explicit `RLMContext`. Can only be called on the main thread.
 
 @param path The file path where the realm is represented on disk.
 
 @return The newly initialized realm.
 */
+ (instancetype)realmWithPersistenceToFile:(NSString *)path;

/**
 Creates a stand-alone `RLMRealm` at the specified file path that lives outside any
 explicit `RLMContext`.
 
 Can only be called on the main thread. Runs an optional initialization block on
 a writable context before returning.
 
 @param path The file path where the realm is represented on disk.
 @param initBlock The optional initialization block on a writable context before returning.
 
 @return The newly initialized realm.
 */
+ (instancetype)realmWithPersistenceToFile:(NSString *)path
                                 initBlock:(RLMWriteBlock)initBlock;

/**
 Creates a stand-alone `RLMRealm` at the specified file path that lives outside any
 explicit `RLMContext`.
 
 Read and write transactions are synchronized to cycles of the specified run loop.
 
 @param path The file path where the realm is represented on disk.
 @param runLoop The run loop on which read transactions will be synchronized. 
        E.g. `[NSRunLoop mainRunLoop]`
 @param notificationCenter The notification center realm notifications will be sent to. 
        E.g. `[NSNotificationCenter defaultCenter]`
 @param error A pointer to an `NSError`.
 
 @return The newly initialized realm.
 */
+ (instancetype)realmWithPersistenceToFile:(NSString *)path
                                   runLoop:(NSRunLoop *)runLoop
                        notificationCenter:(NSNotificationCenter *)notificationCenter
                                     error:(NSError **)error;

/**
 Creates a stand-alone `RLMRealm` at the specified file path that lives outside any
 explicit `RLMContext`.
 
 Read and write transactions are synchronized to cycles of the specified run loop.
 Runs an optional initialization block on a writable context before returning.
 
 @param path The file path where the realm is represented on disk.
 @param initBlock The optional initialization block on a writable context before returning.
 @param runLoop The run loop on which read transactions will be synchronized.
 E.g. `[NSRunLoop mainRunLoop]`
 @param notificationCenter The notification center realm notifications will be sent to.
 E.g. `[NSNotificationCenter defaultCenter]`
 @param error A pointer to an `NSError`.
 
 @return The newly initialized realm.
 */
+ (instancetype)realmWithPersistenceToFile:(NSString *)path
                                 initBlock:(RLMWriteBlock)initBlock
                                   runLoop:(NSRunLoop *)runLoop
                        notificationCenter:(NSNotificationCenter *)notificationCenter
                                     error:(NSError **)error;

#pragma mark - Properties

///------------------------------------------------
/// @name Properties
///------------------------------------------------

/**
 The number of tables in the realm
 */
@property (nonatomic, readonly) NSUInteger tableCount;

/**
 Returns `YES` if there are no tables in the realm. `NO` otherwise.
 */
@property (nonatomic, readonly) BOOL isEmpty;

#pragma mark - Get Tables

/**
 Whether or not a table with the specified name already exists in the realm.
 
 @param name The name string of the table to check for existence in the realm.
 
 @return `YES` if the realm has a table with that name. `NO` otherwise.
 */
- (BOOL)hasTableWithName:(NSString *)name;

/**
 Returns a table with the specified name from the realm.
 
 @param name The name string of the table to get from the realm.
 
 @return The table with the specified name in the realm if it exists.
 `nil` otherwise.
 */
- (RLMTable *)tableWithName:(NSString *)name;

/**
 Returns a table with the specified name and object class from the realm.
 
 @param name The name string of the table to get from the realm.
 @param objClass The class of `RLMRow`-derived objects stored in the table.
 
 @return The table with the specified name and object class in the realm if it exists.
 `nil` otherwise.
 */
- (RLMTable *)tableWithName:(NSString *)name objectClass:(Class)objClass;

/**
 Returns a table with the specified name and table class from the realm.
 
 @param name The name string of the table to get from the realm.
 @param obj The class of the typed table.
 
 @return The table with the specified name and table class in the realm if it exists.
 `nil` otherwise.
 */
-(id)tableWithName:(NSString *)name asTableClass:(Class)obj;

/**
 * This method creates a table with the specific name.
 * If a table with that name already exists, an exception is thrown.
 * Optionally specify object class to be used when accessing table rows
 */
-(RLMTable *)createTableWithName:(NSString *)name;
-(RLMTable *)createTableWithName:(NSString *)name objectClass:(Class)objClass;

/**
 * This method creates a table with the specific name.
 * If a table with that name already exists, an exception is thrown.
 *
 * The columns parameter adds columns to the table the same way as
 * RLMTable's initWithColumns:.
 */
-(RLMTable *)createTableWithName:(NSString*)name columns:(NSArray*)columns;

/**
 * This method creates a table with the specified name as a specific table.
 * If a table with that name already exists, an exception is thrown.
 *
 * The specified table class must be one that is declared by using
 * one of the table macros REALM_TABLE_*.
 */
-(id)createTableWithName:(NSString *)name asTableClass:(Class)obj;



-(NSString *)nameOfTableWithIndex:(NSUInteger)tableIndex;


/**
 * This method returns YES if a table with the specified name already exists. NO if it does not exists.
 *
 * The specified table class must be one that is declared by using
 * one of the table macros REALM_TABLE_*.
 */
-(BOOL)hasTableWithName:(NSString *)name withTableClass:(Class)obj;

@end
