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
    return Tightdb_Version_Major;
}

+(const int)getMinor
{
    return Tightdb_Version_Minor;
}

+(const int)getPatch
{
    return Tightdb_Version_Patch;
}

+(BOOL)isAtLeast:(int)major minor:(int)minor patch:(int)patch
{
    if (major < Tightdb_Version_Major)
        return NO;
    if (minor < Tightdb_Version_Minor)
        return NO;
    if (patch < Tightdb_Version_Patch)
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
