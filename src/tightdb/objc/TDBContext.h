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

#import "RLMTransaction.h"


typedef void(^TDBReadBlock)(RLMTransaction *transaction);
typedef BOOL(^TDBWriteBlock)(RLMTransaction *transaction);
typedef void(^RLMTableReadBlock)(RLMTable *table);
typedef BOOL(^RLMTableWriteBlock)(RLMTable *table);

/****************	  TDBContext	****************/

@interface TDBContext: NSObject

+(NSString *) defaultPath;

// Initializers
+(TDBContext *)contextWithDefaultPersistence;
+(TDBContext *)contextPersistedAtPath:(NSString *)path error:(NSError **)error;

// Transactions
-(void)readUsingBlock:(TDBReadBlock)block;
-(BOOL)writeUsingBlock:(TDBWriteBlock)block error:(NSError **)error;

// Shortcuts for transactions on a single table
-(void)readTable:(NSString*)tablename usingBlock:(RLMTableReadBlock)block;
-(BOOL)writeTable:(NSString*)tablename usingBlock:(RLMTableWriteBlock)block error:(NSError **)error;

// Context state info
-(BOOL)hasChangedSinceLastTransaction;


@end
