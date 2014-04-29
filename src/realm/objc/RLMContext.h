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

@class RLMRealm, RLMTable;

typedef void(^RLMReadBlock)(RLMRealm *realm);
typedef void(^RLMWriteBlock)(RLMRealm *realm);
typedef void(^RLMWriteBlockWithRollback)(RLMRealm *realm, BOOL *rollback);
typedef void(^RLMTableReadBlock)(RLMTable *table);
typedef void(^RLMTableWriteBlock)(RLMTable *table);

/**
 
 RLMContexts are used to perform read and write transactions on an RLMRealm.
 
 **While an RLMRealm can be access directly on the Main UI Thread to read without transaction, an RLMContext
 must be used on any other threads, and to perform any writes (including writes from the Main thread).**
 This is so that the Realm library can perform any necessary locks (in the case of writes), or bring the RLMRealm
 up to date with the event loop for transactionless reads on the Main thread.
 
 We recommend you store a reference to the RLMContext on your ViewController for easy access. For example:
 
    // MyViewController.m
    @property (nonatomic, strong) RLMContext *context;
    
    self.context = [RLMContext contextWithDefaultPersistence];
 
    [context writeTable:@"Dogs" usingBlock:^(RLMTable *table) {
        [table remoteRowAtIndex:indexPath.row];
    }];

 
 */
@interface RLMContext : NSObject

+(NSString *) defaultPath;

/**
 Checks if the underlying RLMRealm has received any writes since the last time you
 used this RLMContext.
 
 @return YES if there have been any changes to the RLMRealm; NO otherwise.
 */
-(BOOL)hasChangedSinceLastTransaction;

/**---------------------------------------------------------------------------------------
 *  @name Creating & Initializing Contexts
 *  ---------------------------------------------------------------------------------------
 */
/**
 Creates an RLMContext for the RLMRealm persisted at the default location
 (`Documents/default.realm`).
 
 @return A reference to the RLMContext.
 */
+(RLMContext *)contextWithDefaultPersistence;
/**
 Creates an RLMContext for the RLMRealm persisted at a specific location.
 
 @param path  Path to the Realm file you want to access.
 @param error Pass-by-reference for errors.
 
 @return A reference to the RLMContext
 */
+(RLMContext *)contextPersistedAtPath:(NSString *)path error:(NSError **)error;


/**---------------------------------------------------------------------------------------
 *  @name Reading a Realm through a Context
 *  ---------------------------------------------------------------------------------------
 */
/**
 Performs a (non-blocking) read transaction on the RLMRealm referenced by this RLMContext.
 
    [[RLMContext contextWithDefaultPersistence] readUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm tableWithName:kTableName objectClass:[RLMDemoObject class]];
        for (RLMDemoObject *object in table) {
            NSLog(@"title: %@\ndate: %@", object.title, object.date);
        }
    }];
 
 @param block A block containing the read code you want to perform.
 */
-(void)readUsingBlock:(RLMReadBlock)block;

/**
 Performs a (non-blocking) read transaction and also pre-opens the specified table as a variable
 
 This is a helpful shortcut removing the need to perform a Table instantiation every time you
 open a transaction. You can still open additional table within the block if you want to.
 
    [context readTable:@"Dogs" usingBlock:^(RLMTable *table) {
        [table rowAtIndex:indexPath.row];
    }];
 
 @param tablename The name of the table you’d like to open.
 @param block     A block containing the read code you want to perform.
 */
-(void)readTable:(NSString*)tablename usingBlock:(RLMTableReadBlock)block;


/**---------------------------------------------------------------------------------------
 *  @name Writing to a Realm through a Context
 *  ---------------------------------------------------------------------------------------
 */
/**
 Performs a (blocking) write transaction on the RLMRealm referenced by this RLMContext
 
     [[RLMContext contextWithDefaultPersistence] writeUsingBlock:^(RLMRealm *realm) {
        RLMTable *table = [realm tableWithName:@"Dogs" objectClass:[RLMDogObject class]];
        // Add row via array. Order matters.
        [table addRow:@[[self randomString], [self randomDate]]];
    }];
 
 @param block A block containing the write code you want to perform.
 */
-(void)writeUsingBlock:(RLMWriteBlock)block;
/**
 Performs a (blocking) write transaction, with automatic rollback in case of errors
 
 @param block A block containing the write code you want to perform.
 */
-(void)writeUsingBlockWithRollback:(RLMWriteBlockWithRollback)block;
/**
 Performs a (blocking) write transaction and also pre-opens the specificied table as a variable
 
 This is a helpful shortcut removing the need to perform a Table instantiation every time you
 open a transaction. You can still open additional table within the block if you want to.
 
    [context writeTable:@"Dogs" usingBlock:^(RLMTable *table) {
        [table remoteRowAtIndex:indexPath.row];
    }];
 
 @param tablename The name of the table you’d like to open.
 @param block     A block containing the write code you want to perform.
 */
-(void)writeTable:(NSString*)tablename usingBlock:(RLMTableWriteBlock)block;


@end
