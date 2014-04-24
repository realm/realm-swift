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

#define REALM_VERSION_MAJOR 0
#define REALM_VERSION_MINOR 10
#define REALM_VERSION_PATCH 0

@interface RLMVersion : NSObject

+(NSString*)version;

+(NSInteger)major;
+(NSInteger)minor;
+(NSInteger)patch;

+(BOOL)isAtLeast:(NSInteger)major minor:(NSInteger)minor patch:(NSInteger)patch;

@end
