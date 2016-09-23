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

#import "shared_realm.hpp"

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

- (void)testSystemExceptionWithPOSIXSystemException {
    int code = ENOENT;
    NSString *description = @"No such file or directory";

    std::system_error exception(code, std::generic_category());
    NSDictionary *expectedUserInfo = @{
                                       NSLocalizedDescriptionKey : description,
                                       @"Error Code" : @(code),
                                       @"Category": [NSString stringWithUTF8String:std::generic_category().name()]
                                       };
    XCTAssertEqualObjects(RLMMakeError(exception),
                          [NSError errorWithDomain:NSPOSIXErrorDomain code:code userInfo:expectedUserInfo]);
}

- (void)testSystemExceptionWithNonPOSIXSystemException {
    int code = 999;
    NSString *description = @"unspecified system_category error";

    std::system_error exception(code, std::system_category());
    NSDictionary *expectedUserInfo = @{
                                       NSLocalizedDescriptionKey : description,
                                       @"Error Code" : @(code),
                                       @"Category": [NSString stringWithUTF8String:std::system_category().name()]
                                       };
    XCTAssertEqualObjects(RLMMakeError(exception),
                          [NSError errorWithDomain:RLMUnknownSystemErrorDomain code:code userInfo:expectedUserInfo]);
}

- (void)testRealmFileException {
    realm::RealmFileException exception(realm::RealmFileException::Kind::NotFound,
                                        "/some/path",
                                        "don't do that to your files",
                                        "lp0 on fire");
    RLMError dummyCode = RLMErrorFail;
    NSDictionary *expectedUserInfo = @{NSLocalizedDescriptionKey: @"don't do that to your files",
                                       NSFilePathErrorKey: @"/some/path",
                                       @"Error Code": @(dummyCode),
                                       @"Underlying": @"lp0 on fire"};

    XCTAssertEqualObjects(RLMMakeError(dummyCode, exception),
                          [NSError errorWithDomain:RLMErrorDomain code:dummyCode userInfo:expectedUserInfo]);
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
