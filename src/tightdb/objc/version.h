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

#define Tightdb_Version_Major 0
#define Tightdb_Version_Minor 1
#define Tightdb_Version_Patch 6

@interface TightdbVersion: NSObject
-(id)init;
+(const int)getMajor;
+(const int)getMinor;
+(const int)getPatch;
+(BOOL)isAtLeast:(int)major minor:(int)minor patch:(int)patch;
+(NSString*)getVersion;
+(NSString*)getCoreVersion;
@end
