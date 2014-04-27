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

/****************	  RLMContext	****************/

@interface RLMContext : NSObject

+(NSString *) defaultPath;

// Initializers
+(RLMContext *)contextWithDefaultPersistence;
+(RLMContext *)contextPersistedAtPath:(NSString *)path error:(NSError **)error;

// Transactions
-(void)readUsingBlock:(RLMReadBlock)block;
-(void)writeUsingBlock:(RLMWriteBlock)block;
-(void)writeUsingBlockWithRollback:(RLMWriteBlockWithRollback)block;

// Shortcuts for transactions on a single table
-(void)readTable:(NSString*)tablename usingBlock:(RLMTableReadBlock)block;
-(void)writeTable:(NSString*)tablename usingBlock:(RLMTableWriteBlock)block;

// Context state info
-(BOOL)hasChangedSinceLastTransaction;

@end
