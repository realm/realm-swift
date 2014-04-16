/*
 version.m
 TightDB
*/

#import <XCTest/XCTest.h>

#import <tightdb/objc/RLMVersion.h>

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
  if (TDB_VERSION_MAJOR != [RLMVersion getMajor])
    XCTFail(@"Wrong major version");
}
-(void)testMinorVersion
{
  if (TDB_VERSION_MINOR != [RLMVersion getMinor])
    XCTFail(@"Wrong minor version");
}
-(void)testPatchVersion
{
  if (TDB_VERSION_PATCH != [RLMVersion getPatch])
    XCTFail(@"Wrong patch version");
}
-(void)testIsAtLeast
{
    if ([RLMVersion isAtLeast:TDB_VERSION_MAJOR- 1 minor:TDB_VERSION_MINOR patch:TDB_VERSION_PATCH])
        XCTFail(@"Wrong Major version");
    if ([RLMVersion isAtLeast:TDB_VERSION_MAJOR minor:TDB_VERSION_MINOR- 1 patch:TDB_VERSION_PATCH])
        XCTFail(@"Wrong Minor version");
    if ([RLMVersion isAtLeast:TDB_VERSION_MAJOR minor:TDB_VERSION_MINOR patch:TDB_VERSION_PATCH- 1])
        XCTFail(@"Wrong Patch version");

    if (![RLMVersion isAtLeast:TDB_VERSION_MAJOR+ 1 minor:TDB_VERSION_MINOR patch:TDB_VERSION_PATCH])
        XCTFail(@"Wrong Major version");
    if (![RLMVersion isAtLeast:TDB_VERSION_MAJOR minor:TDB_VERSION_MINOR+ 1 patch:TDB_VERSION_PATCH])
        XCTFail(@"Wrong Minor version");
    if (![RLMVersion isAtLeast:TDB_VERSION_MAJOR minor:TDB_VERSION_MINOR patch:TDB_VERSION_PATCH+ 1])
        XCTFail(@"Wrong Patch version");
}

-(void)testGetVersion
{
    NSString *s1 = [NSString stringWithFormat:@"%d.%d.%d", 
                             [RLMVersion getMajor],
                             [RLMVersion getMinor],
                             [RLMVersion getPatch]];
    if (![[RLMVersion getVersion] isEqualToString:s1])
        XCTFail(@"Version string incorrect");
}
@end
