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

#import "RLMVersion.h"


@implementation RLMVersion
{
}

+(NSInteger)major
{
    return REALM_VERSION_MAJOR;
}

+(NSInteger)minor
{
    return REALM_VERSION_MINOR;
}

+(NSInteger)patch
{
    return REALM_VERSION_PATCH;
}

+(BOOL)isAtLeast:(NSInteger)major minor:(NSInteger)minor patch:(NSInteger)patch
{
    if ([RLMVersion major] < major)
        return false;
    if ([RLMVersion major] > major)
        return true;

    if ([RLMVersion minor] < minor)
        return false;
    if ([RLMVersion minor] > minor)
        return true;

    return (self.patch >= patch);
}

+(NSString*)version
{
    return [NSString stringWithFormat:@"%ld.%ld.%ld",
            [RLMVersion major],
            [RLMVersion minor],
            [RLMVersion patch]];
}

// Not shared in the interface p.t.
+(NSString*)coreVersion
{
    return [NSString stringWithFormat:@"%d.%d.%d",
            tightdb::Version::get_major(),
            tightdb::Version::get_minor(),
            tightdb::Version::get_patch()];
}
@end
