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

/**
 
 RLMRealms are the central structure of the Realm library.
 Realms contain tables, which in turn contain your objects.
 
 @warning Realms can only be instantiated directly for reads from the Main (UI) thread of your iOS applications.
 From any other thread or for any writes, you must use an RLMContext to instantiate a Realm.
 
 */

@class RLMTable;

@interface RLMRealm : NSObject

/**---------------------------------------------------------------------------------------
 *  @name Instantiate a Realm
 *  ---------------------------------------------------------------------------------------
 */
/** Obtains an instance of the Realm persisted to disk at the standard location.
 *
 *  The default realm is stored at `Documents/default.realm`.
 *
 *  This method also uses the main run loop, as well as the default notification center.
 *
 *  @warning See RLMContext to instantiate Realms for writes
 *  or to instantiate a realm for reads outside the Main (UI) thread of your app.
 *
 *  @return a Realm instance
 */
+ (instancetype)realmWithDefaultPersistence;

+ (instancetype)realmWithDefaultPersistenceAndInitBlock:(RLMWriteBlock)initBlock;

+ (instancetype)realmWithPersistenceToFile:(NSString *)path;

+ (instancetype)realmWithPersistenceToFile:(NSString *)path
                                 initBlock:(RLMWriteBlock)initBlock;

+ (instancetype)realmWithPersistenceToFile:(NSString *)path
                                   runLoop:(NSRunLoop *)runLoop
                        notificationCenter:(NSNotificationCenter *)notificationCenter
                                     error:(NSError **)error;

+ (instancetype)realmWithPersistenceToFile:(NSString *)path
                                 initBlock:(RLMWriteBlock)initBlock
                                   runLoop:(NSRunLoop *)runLoop
                        notificationCenter:(NSNotificationCenter *)notificationCenter
                                     error:(NSError **)error;

@property (nonatomic, readonly) NSUInteger tableCount;
@property (nonatomic, readonly) BOOL       isEmpty;

/**---------------------------------------------------------------------------------------
 *  @name Create Tables
 *  ---------------------------------------------------------------------------------------
 */

/** Creates a table with the specified name for the specified object class.
 *
 *  @param name     Name of the table to create
 *  @param objClass Class of the objects stored in this Table
 *
 *  @return A Reference to the Table that was created
 */
-(RLMTable *)createTableWithName:(NSString *)name objectClass:(Class)objClass;


-(RLMTable *)createTableWithName:(NSString*)name columns:(NSArray*)columns;
-(id)createTableWithName:(NSString *)name asTableClass:(Class)obj;


/**---------------------------------------------------------------------------------------
 *  @name Access Tables
 *  ---------------------------------------------------------------------------------------
 */

/** Checks for the existence of a Table within the Realm.
 *
 *  @param name The name of the table
 *
 *  @return YES if a table with the specified name already exists. NO if it does not exist.
 */
-(BOOL)hasTableWithName:(NSString *)name;

/** Accesses a table with the specified name from the Realm.
 *
 *  It will use the specified object class when accessing rows.
 *
 *  @param name The name of the table contained in the Realm you want to access
 *  @param objClass The class you want to use when accessing the table
 *
 *  @return A reference to the Table by that name; or nil if no table by that name exists in the Realm
 *
 *  @see tablewithName:
 *  @see tablewithName: asTableClass:
 */
-(RLMTable *)tableWithName:(NSString *)name objectClass:(Class)objClass;

-(RLMTable *)tableWithName:(NSString *)name;
-(id)tableWithName:(NSString *)name asTableClass:(Class)obj;
-(RLMTable *)createTableWithName:(NSString *)name;


-(NSString *)nameOfTableWithIndex:(NSUInteger)tableIndex;
-(BOOL)hasTableWithName:(NSString *)name withTableClass:(Class)obj;

@end
