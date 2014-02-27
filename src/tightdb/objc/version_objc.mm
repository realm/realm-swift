/*
 * version.mm
 * TightDB
 */

#include <string>
#include <tightdb.hpp>
#import  <tightdb/objc/version.h>

@implementation TightdbVersion
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

@end
