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


/* NBNB. This class is not included in our public framework!
 * It contains selectors removed from Transaction when the old Group became Transaction.
 * The following selectors are all tested extensively from previuos.
 * They have been put here, as we might wan't to reintroduce Group later on....
 * MEKJAER
 */

#import <Foundation/Foundation.h>
#import "TDBTransaction.h"

@class TDBBinary;
@class TDBTable;


@interface  TDBTransaction() // Selectors are currently implemented in TDBTransaction

/*
 * Init a free-stading in memory group
 */
+(TDBTransaction *)group;

+(TDBTransaction *)groupWithFile:(NSString *)filename withError:(NSError *__autoreleasing *)error;

+(TDBTransaction *)groupWithBuffer:(NSData *)buffer withError:(NSError *__autoreleasing *)error;

-(BOOL)writeContextToFile:(NSString *)path withError:(NSError *__autoreleasing *)error;

-(NSData *)writeContextToBuffer;

@end

