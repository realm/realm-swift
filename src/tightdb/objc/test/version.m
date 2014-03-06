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
  if (Tightdb_Version_Major != [TightdbVersion getMajor])
    STFail(@"Wrong major version");
}
-(void)testMinorVersion
{
  if (Tightdb_Version_Minor != [TightdbVersion getMinor])
    STFail(@"Wrong minor version");
}
-(void)testPatchVersion
{
  if (Tightdb_Version_Patch != [TightdbVersion getPatch])
    STFail(@"Wrong patch version");
}
-(void)testIsAtLeast
{
    if ([TightdbVersion isAtLeast:Tightdb_Version_Major-1 minor:Tightdb_Version_Minor patch:Tightdb_Version_Patch])
        STFail(@"Wrong Major version");
    if ([TightdbVersion isAtLeast:Tightdb_Version_Major minor:Tightdb_Version_Minor-1 patch:Tightdb_Version_Patch])
        STFail(@"Wrong Minor version");
    if ([TightdbVersion isAtLeast:Tightdb_Version_Major minor:Tightdb_Version_Minor patch:Tightdb_Version_Patch-1])
        STFail(@"Wrong Patch version");

    if (![TightdbVersion isAtLeast:Tightdb_Version_Major+1 minor:Tightdb_Version_Minor patch:Tightdb_Version_Patch])
        STFail(@"Wrong Major version");
    if (![TightdbVersion isAtLeast:Tightdb_Version_Major minor:Tightdb_Version_Minor+1 patch:Tightdb_Version_Patch])
        STFail(@"Wrong Minor version");
    if (![TightdbVersion isAtLeast:Tightdb_Version_Major minor:Tightdb_Version_Minor patch:Tightdb_Version_Patch+1])
        STFail(@"Wrong Patch version");
}

-(void)testGetVersion
{
    NSString *s1 = [NSString stringWithFormat:@"%d.%d.%d", 
                             [TightdbVersion getMajor], 
                             [TightdbVersion getMinor],
                             [TightdbVersion getPatch]];
    if (![[TightdbVersion getVersion] isEqualTo:s1])
        STFail(@"Version string incorrect");
}
@end
