/*
 version.m
 TightDB
*/

#import <XCTest/XCTest.h>

#import <tightdb/objc/TDBVersion.h>

@interface MACTestVersion: XCTestCase
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
    XCTFail(@"Wrong major version");
}
-(void)testMinorVersion
{
  if (TDB_VERSION_MINOR != [TDBVersion getMinor])
    XCTFail(@"Wrong minor version");
}
-(void)testPatchVersion
{
  if (TDB_VERSION_PATCH != [TDBVersion getPatch])
    XCTFail(@"Wrong patch version");
}
-(void)testIsAtLeast
{
    if ([TDBVersion isAtLeast:TDB_VERSION_MAJOR-1 minor:TDB_VERSION_MINOR patch:TDB_VERSION_PATCH])
        XCTFail(@"Wrong Major version");
    if ([TDBVersion isAtLeast:TDB_VERSION_MAJOR minor:TDB_VERSION_MINOR-1 patch:TDB_VERSION_PATCH])
        XCTFail(@"Wrong Minor version");
    if ([TDBVersion isAtLeast:TDB_VERSION_MAJOR minor:TDB_VERSION_MINOR patch:TDB_VERSION_PATCH-1])
        XCTFail(@"Wrong Patch version");

    if (![TDBVersion isAtLeast:TDB_VERSION_MAJOR+1 minor:TDB_VERSION_MINOR patch:TDB_VERSION_PATCH])
        XCTFail(@"Wrong Major version");
    if (![TDBVersion isAtLeast:TDB_VERSION_MAJOR minor:TDB_VERSION_MINOR+1 patch:TDB_VERSION_PATCH])
        XCTFail(@"Wrong Minor version");
    if (![TDBVersion isAtLeast:TDB_VERSION_MAJOR minor:TDB_VERSION_MINOR patch:TDB_VERSION_PATCH+1])
        XCTFail(@"Wrong Patch version");
}

-(void)testGetVersion
{
    NSString *s1 = [NSString stringWithFormat:@"%d.%d.%d", 
                             [TDBVersion getMajor], 
                             [TDBVersion getMinor],
                             [TDBVersion getPatch]];
    if (![[TDBVersion getVersion] isEqualTo:s1])
        XCTFail(@"Version string incorrect");
}
@end
