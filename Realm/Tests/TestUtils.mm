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

#import "TestUtils.h"

#import <Realm/Realm.h>
#import <Realm/RLMSchema_Private.h>
#import "RLMRealmUtil.hpp"

void RLMAssertThrowsWithReasonMatchingSwift(XCTestCase *self, dispatch_block_t block, NSString *regexString, NSString *message, NSString *fileName, NSUInteger lineNumber) {
    BOOL didThrow = NO;
    @try {
        block();
    }
    @catch (NSException *e) {
        didThrow = YES;
        NSString *reason = e.reason;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:(NSRegularExpressionOptions)0 error:nil];
        if ([regex numberOfMatchesInString:reason options:(NSMatchingOptions)0 range:NSMakeRange(0, reason.length)] == 0) {
            NSString *msg = [NSString stringWithFormat:@"The given expression threw an exception with reason '%@', but expected to match '%@'",
                             reason, regexString];
            [self recordFailureWithDescription:msg inFile:fileName atLine:lineNumber expected:NO];
        }
    }
    if (!didThrow) {
        NSString *prefix = @"The given expression failed to throw an exception";
        message = message ? [NSString stringWithFormat:@"%@ (%@)",  prefix, message] : prefix;
        [self recordFailureWithDescription:message inFile:fileName atLine:lineNumber expected:NO];
    }
}
