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

@interface RLMSmartContext : NSObject

/**
 * Use the main run loop and the default notification center.
 */
+(RLMSmartContext *)contextWithDefaultPersistence;

+(RLMSmartContext *)contextWithPersistenceToFile:(NSString *)path;

+(RLMSmartContext *)contextWithPersistenceToFile:(NSString *)path
                                         runLoop:(NSRunLoop *)runLoop
                              notificationCenter:(NSNotificationCenter *)notificationCenter
                                           error:(NSError **)error;

// Get table with specified name and optional table class
-(RLMTable *)tableWithName:(NSString *)name;
-(id)tableWithName:(NSString *)name asTableClass:(Class)obj;

@end
