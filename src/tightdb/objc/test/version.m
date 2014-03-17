/*
 version.m
 TightDB
*/

#import <SenTestingKit/SenTestingKit.h>

#import <tightdb/objc/version.h>

@interface MACTestVersion: SenTestCase
@end

@implementation MACTestVersion
{
}

-(void)setUp
{
  [super setUp];
}

-(void)tearDown
{
}

-(void)testMajorVersion
{
  if (TDB_VERSION_MAJOR != [TDBVersion getMajor])
    STFail(@"Wrong major version");
}
-(void)testMinorVersion
{
  if (TDB_VERSION_MINOR != [TDBVersion getMinor])
    STFail(@"Wrong minor version");
}
-(void)testPatchVersion
{
  if (TDB_VERSION_PATCH != [TDBVersion getPatch])
    STFail(@"Wrong patch version");
}
-(void)testIsAtLeast
{
    if ([TDBVersion isAtLeast:TDB_VERSION_MAJOR-1 minor:TDB_VERSION_MINOR patch:TDB_VERSION_PATCH])
        STFail(@"Wrong Major version");
    if ([TDBVersion isAtLeast:TDB_VERSION_MAJOR minor:TDB_VERSION_MINOR-1 patch:TDB_VERSION_PATCH])
        STFail(@"Wrong Minor version");
    if ([TDBVersion isAtLeast:TDB_VERSION_MAJOR minor:TDB_VERSION_MINOR patch:TDB_VERSION_PATCH-1])
        STFail(@"Wrong Patch version");

    if (![TDBVersion isAtLeast:TDB_VERSION_MAJOR+1 minor:TDB_VERSION_MINOR patch:TDB_VERSION_PATCH])
        STFail(@"Wrong Major version");
    if (![TDBVersion isAtLeast:TDB_VERSION_MAJOR minor:TDB_VERSION_MINOR+1 patch:TDB_VERSION_PATCH])
        STFail(@"Wrong Minor version");
    if (![TDBVersion isAtLeast:TDB_VERSION_MAJOR minor:TDB_VERSION_MINOR patch:TDB_VERSION_PATCH+1])
        STFail(@"Wrong Patch version");
}

-(void)testGetVersion
{
    NSString *s1 = [NSString stringWithFormat:@"%d.%d.%d", 
                             [TDBVersion getMajor], 
                             [TDBVersion getMinor],
                             [TDBVersion getPatch]];
    if (![[TDBVersion getVersion] isEqualTo:s1])
        STFail(@"Version string incorrect");
}
@end
