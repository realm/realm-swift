////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

#import "RLMTestCase.h"

#import "RLMConstants.h"
#import "RLMUtil.hpp"
#import "RLMVersion.h"

@interface UtilTests : RLMTestCase

@end

static BOOL RLMEqualExceptions(NSException *actual, NSException *expected) {
    return [actual.name isEqualToString:expected.name]
        && [actual.reason isEqualToString:expected.reason]
        && [actual.userInfo isEqual:expected.userInfo];
}

@implementation UtilTests

- (void)testRLMExceptionWithReasonAndUserInfo {
    NSString *const reason = @"Reason";
    NSDictionary *expectedUserInfo = @{
                                       RLMRealmVersionKey : REALM_COCOA_VERSION,
                                       RLMRealmCoreVersionKey : @REALM_VERSION,
                                       };

    XCTAssertTrue(RLMEqualExceptions(RLMException(reason),
                                     [NSException exceptionWithName:RLMExceptionName reason:reason userInfo:expectedUserInfo]));
}

- (void)testRLMExceptionWithCPlusPlusException {
    std::runtime_error exception("Reason");
    NSDictionary *expectedUserInfo = @{
                                       RLMRealmVersionKey : REALM_COCOA_VERSION,
                                       RLMRealmCoreVersionKey : @REALM_VERSION,
                                       };

    XCTAssertTrue(RLMEqualExceptions(RLMException(exception),
                                     [NSException exceptionWithName:RLMExceptionName reason:@"Reason" userInfo:expectedUserInfo]));
}

- (void)testRLMMakeError {
    std::runtime_error exception("Reason");
    RLMError code = RLMErrorFail;
    NSDictionary *expectedUserInfo = @{
                                       NSLocalizedDescriptionKey : @"Reason",
                                       @"Error Code" : @(code),
                                       };

    XCTAssertEqualObjects(RLMMakeError(code, exception),
                          [NSError errorWithDomain:RLMErrorDomain code:code userInfo:expectedUserInfo]);
}

- (void)testRLMSetErrorOrThrowWithNilErrorPointer {
    NSError *error = [NSError errorWithDomain:RLMErrorDomain code:RLMErrorFail userInfo:nil];

    XCTAssertThrows(RLMSetErrorOrThrow(error, nil));
}

- (void)testRLMSetErrorOrThrowWithErrorPointer {
    NSError *error = [NSError errorWithDomain:RLMErrorDomain code:RLMErrorFail userInfo:nil];
    NSError *outError = nil;

    XCTAssertNoThrow(RLMSetErrorOrThrow(error, &outError));
    XCTAssertEqualObjects(error, outError);
}

@end
