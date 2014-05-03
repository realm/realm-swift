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

/**
 
 RLMRealms are the central structure of the Realm library.
 An RLMRealm contains RLMTable(s), which in turn contain your objects (RLMRow subclasses).
    
    RLMRealm *realm = [RLMRealm realmWithDefaultPersistenceAndInitBlock:^(RLMRealm *realm) {
        // Create table if it doesn't exist
        if (realm.isEmpty) {
            [realm createTableWithName:@"Dogs" objectClass:[RLMDogObject class]];
        }
    }];

 
 */

@class RLMTable;

@interface RLMRealm : NSObject


/**---------------------------------------------------------------------------------------
 *  @name Creating & Initializing a Realm
 *  ---------------------------------------------------------------------------------------
 */
/** Obtains an instance of the RLMRealm persisted to disk at the standard location.
 
 The default RLMRealm is persisted at `<Application_Home>/Documents/default.realm`.
 
 This method also uses the main run loop, as well as the default notification center.
 
 @return An RLMRealm instance.
 */
+ (instancetype)defaultRealm;

/**
 Instantiates an RLMRealm with persistence to a specific File.
  
 @param path Path to the file you want the data saved in.
 
 @return An RLMRealm instance.
 */
+ (instancetype)realmWithPath:(NSString *)path;

/**
 Instantiates an RLMRealm with a manual init block, with persistence to a specific file, and an error

 @param path        Path to the file you want the data saved in.
 @param error       Pass-by-reference for errors.

 @return An RLMRealm instance.
 */
+ (instancetype)realmWithPath:(NSString *)path error:(NSError **)error;

- (void)addNotification:(void(^)(RLMRealm *realm))block;
- (void)removeNotification:(void(^)(RLMRealm *realm))block;
- (void)removeAllNotifications;

- (void)beginWriteTransaction;
- (void)commitWriteTransaction;
- (void)abandonWriteTransaction;

- (void)writeUsingBlock:(void(^)(RLMRealm *realm))block;

/**---------------------------------------------------------------------------------------
 *  @name Adding Tables to a Realm
 *  ---------------------------------------------------------------------------------------
 */
/** Creates an RLMTable with the specified name for the specified object class.

 @param name     Name of the RLMTable to create.
 @param objClass Class of the objects stored in this RLMTable.
 
 @return A Reference to the RLMTable that was created.
 */
-(RLMTable *)createTableWithName:(NSString *)name objectClass:(Class)objClass;


-(RLMTable *)createTableWithName:(NSString*)name columns:(NSArray*)columns;
-(id)createTableWithName:(NSString *)name asTableClass:(Class)obj;


/**---------------------------------------------------------------------------------------
 *  @name Accessing Tables in a Realm
 *  ---------------------------------------------------------------------------------------
 */
/**
 *  The number of tables in this RLMRealm.
 */
@property (nonatomic, readonly) NSUInteger tableCount;

/**
 *  YES if the RLMRealm contains no RLMTable; NO if it has at least one.
 */
@property (nonatomic, readonly) BOOL isEmpty;

/** Checks for the existence of an RLMTable within the RLMRealm.
 
 @param name The name of the RLMTable.
 
 @return YES if an RLMTable with the specified name already exists. NO if it does not exist.
 */
-(BOOL)hasTableWithName:(NSString *)name;

/** Accesses an RLMTable with the specified name from the Realm.
 
 It will use the specified object class when accessing rows.
 
 @param name The name of the RLMTable you want to access in this RLMRealm.
 @param objClass The class you want to use when accessing the RLMTable.
 
 @return A reference to the RLMTable by that name; or nil if no RLMTable by that name exists in the RLMRealm.
 
 */
-(RLMTable *)tableWithName:(NSString *)name objectClass:(Class)objClass;

-(RLMTable *)tableWithName:(NSString *)name;
-(id)tableWithName:(NSString *)name asTableClass:(Class)obj;
-(RLMTable *)createTableWithName:(NSString *)name;


-(NSString *)nameOfTableWithIndex:(NSUInteger)tableIndex;
-(BOOL)hasTableWithName:(NSString *)name withTableClass:(Class)obj;

@end
