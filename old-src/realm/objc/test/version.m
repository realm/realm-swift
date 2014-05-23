
#import "RLMTestCase.h"

#import <realm/objc/RLMVersion.h>

@interface RLMTestVersion: RLMTestCase
@end

@implementation RLMTestVersion

-(void)testVersionGetters
{
    XCTAssertEqual((NSInteger)REALM_VERSION_MAJOR, [RLMVersion major] );
    XCTAssertEqual((NSInteger)REALM_VERSION_MINOR, [RLMVersion minor] );
    XCTAssertEqual((NSInteger)REALM_VERSION_PATCH, [RLMVersion major] );

    NSString *ver1 = [RLMVersion version];
    NSString *ver2 = [NSString stringWithFormat:@"%d.%d.%d",
                      REALM_VERSION_MAJOR, REALM_VERSION_MINOR, REALM_VERSION_PATCH];
    XCTAssert( [ver1 isEqualToString:ver2] );
}

-(void)testIsAtLeast
{
    XCTAssertTrue( [RLMVersion isAtLeast:0
                                   minor:0
                                   patch:0] );

    XCTAssertTrue( [RLMVersion isAtLeast:REALM_VERSION_MAJOR
                                   minor:REALM_VERSION_MINOR
                                   patch:REALM_VERSION_PATCH] );

    XCTAssertFalse( [RLMVersion isAtLeast:REALM_VERSION_MAJOR+1
                                    minor:REALM_VERSION_MINOR
                                    patch:REALM_VERSION_PATCH] );

    XCTAssertFalse( [RLMVersion isAtLeast:REALM_VERSION_MAJOR
                                   minor:REALM_VERSION_MINOR+1
                                   patch:REALM_VERSION_PATCH] );

    XCTAssertFalse( [RLMVersion isAtLeast:REALM_VERSION_MAJOR
                                   minor:REALM_VERSION_MINOR
                                   patch:REALM_VERSION_PATCH+1] );
}

@end
