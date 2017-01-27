////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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

#import <XCTest/XCTest.h>

#import "RLMSyncSessionRefreshHandle+ObjectServerTests.h"

@interface RLMAncillaryObjectServerTests : XCTestCase
@end

@interface RLMSyncSessionRefreshHandle ()
+ (NSDate *)fireDateForTokenExpirationDate:(NSDate *)date nowDate:(NSDate *)nowDate;
@end

@implementation RLMAncillaryObjectServerTests

/// Ensure the `fireDateForTokenExpirationDate:nowDate:` method works properly.
/// Rationale: we swizzle this method out for our end-to-end tests, so we need to verify the original works.
- (void)testRefreshHandleDateComparison {
    [RLMSyncSessionRefreshHandle calculateFireDateUsingTestLogic:NO blockOnRefreshCompletion:nil];

    // The method should return nil if the dates are equal in value.
    NSDate *date = [NSDate date];
    NSDate *nowDate = [NSDate dateWithTimeIntervalSince1970:date.timeIntervalSince1970];
    XCTAssertNil([RLMSyncSessionRefreshHandle fireDateForTokenExpirationDate:date nowDate:nowDate]);

    // The method should return nil if the expiration date is in the past.
    date = [NSDate dateWithTimeIntervalSince1970:(date.timeIntervalSince1970 - 1)];
    XCTAssertNil([RLMSyncSessionRefreshHandle fireDateForTokenExpirationDate:date nowDate:nowDate]);

    // The method should return nil if the expiration date is not far enough forward in the future.
    date = [NSDate dateWithTimeIntervalSince1970:(date.timeIntervalSince1970 + 1)];
    XCTAssertNil([RLMSyncSessionRefreshHandle fireDateForTokenExpirationDate:date nowDate:nowDate]);

    // The method should return an actual date if the expiration date is far enough forward in the future.
    date = [NSDate dateWithTimeIntervalSince1970:(date.timeIntervalSince1970 + 100)];
    NSDate *fireDate = [RLMSyncSessionRefreshHandle fireDateForTokenExpirationDate:date nowDate:nowDate];
    XCTAssertNotNil(fireDate);
    XCTAssertGreaterThan(fireDate.timeIntervalSinceReferenceDate, nowDate.timeIntervalSinceReferenceDate);
    XCTAssertLessThan(fireDate.timeIntervalSinceReferenceDate, date.timeIntervalSinceReferenceDate);
}

@end
