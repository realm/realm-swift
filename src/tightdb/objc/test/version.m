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
  if (TDB_Version_Major != [TDBVersion getMajor])
    STFail(@"Wrong major version");
}
-(void)testMinorVersion
{
  if (TDB_Version_Minor != [TDBVersion getMinor])
    STFail(@"Wrong minor version");
}
-(void)testPatchVersion
{
  if (TDB_Version_Patch != [TDBVersion getPatch])
    STFail(@"Wrong patch version");
}
-(void)testIsAtLeast
{
    if ([TDBVersion isAtLeast:TDB_Version_Major-1 minor:TDB_Version_Minor patch:TDB_Version_Patch])
        STFail(@"Wrong Major version");
    if ([TDBVersion isAtLeast:TDB_Version_Major minor:TDB_Version_Minor-1 patch:TDB_Version_Patch])
        STFail(@"Wrong Minor version");
    if ([TDBVersion isAtLeast:TDB_Version_Major minor:TDB_Version_Minor patch:TDB_Version_Patch-1])
        STFail(@"Wrong Patch version");

    if (![TDBVersion isAtLeast:TDB_Version_Major+1 minor:TDB_Version_Minor patch:TDB_Version_Patch])
        STFail(@"Wrong Major version");
    if (![TDBVersion isAtLeast:TDB_Version_Major minor:TDB_Version_Minor+1 patch:TDB_Version_Patch])
        STFail(@"Wrong Minor version");
    if (![TDBVersion isAtLeast:TDB_Version_Major minor:TDB_Version_Minor patch:TDB_Version_Patch+1])
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
