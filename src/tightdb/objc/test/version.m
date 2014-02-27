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
@end
