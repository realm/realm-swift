/*
 * version.mm
 * TightDB
 */

#include <string>
#include <tightdb.hpp>
#include <tightdb/version.hpp>
#import  <tightdb/objc/version.h>

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
