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

#include <string>
#include <tightdb.hpp>
#include <tightdb/version.hpp>

#import  "TDBVersion.h"


@implementation TDBVersion
{
}

-(id)init
{
    self = [super init];
    return self;
}

+(const int)getMajor
{
    return TDB_VERSION_MAJOR;
}

+(const int)getMinor
{
    return TDB_VERSION_MINOR;
}

+(const int)getPatch
{
    return TDB_VERSION_PATCH;
}

+(BOOL)isAtLeast:(int)major minor:(int)minor patch:(int)patch
{
    if (major < TDB_VERSION_MAJOR)
        return NO;
    if (minor < TDB_VERSION_MINOR)
        return NO;
    if (patch < TDB_VERSION_PATCH)
        return NO;
    return YES;
}

+(NSString*)getVersion
{
    NSString *s = [NSString stringWithFormat:@"%d.%d.%d", 
                            [TDBVersion getMajor],
                            [TDBVersion getMinor],
                            [TDBVersion getPatch]];
    return s;
}

+(NSString*)getCoreVersion
{
    NSString *s = [NSString stringWithFormat:@"%d.%d.%d",
                            tightdb::Version::get_major(),
                            tightdb::Version::get_minor(),
                            tightdb::Version::get_patch()];
    return s;
}
@end
