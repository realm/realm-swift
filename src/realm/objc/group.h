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


/* NBNB. This class is not included in our public framework!
 * It contains selectors removed from Realm when the old Group became 
 * Transaction which then became Realm.
 * The following selectors are all tested extensively from previous.
 * They have been put here, as we might wan't to reintroduce Group later on....
 * MEKJAER
 */

#import <Foundation/Foundation.h>
#import "RLMRealm.h"

@interface RLMRealm () // Selectors are currently implemented in RLMRealm

/*
 * Init a free-standing realm in memory
 */
+ (RLMRealm *)realm;

+ (RLMRealm *)realmWithFile:(NSString *)filename error:(NSError *__autoreleasing *)error;

+ (RLMRealm *)realmWithBuffer:(NSData *)buffer error:(NSError *__autoreleasing *)error;

- (NSData *)writeRealmToBuffer;

@end
