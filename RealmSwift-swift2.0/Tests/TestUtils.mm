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
#import <Realm/RLMRealmUtil.hpp>
#import <Realm/RLMSchema_Private.h>

// This ensures the shared schema is initialized outside of of a test case,
// so if an exception is thrown, it will kill the test process rather than
// allowing hundreds of test cases to fail in strange ways
__attribute((constructor))
static void initializeSharedSchema() {
    [RLMSchema sharedSchema];
}

void RLMAssertThrows(XCTestCase *self, dispatch_block_t block, NSString *name, NSString *message, NSString *fileName, NSUInteger lineNumber) {
    BOOL didThrow = NO;
    @try {
        block();
    }
    @catch (NSException *e) {
        didThrow = YES;
        if (![name isEqualToString:e.name]) {
            NSString *msg = [NSString stringWithFormat:@"The given expression threw an exception named '%@', but expected '%@'",
                             e.name, name];
            [self recordFailureWithDescription:msg inFile:fileName atLine:lineNumber expected:NO];
        }
    }
    if (!didThrow) {
        NSString *prefix = @"The given expression failed to throw an exception";
        message = message ? [NSString stringWithFormat:@"%@ (%@)",  prefix, message] : prefix;
        [self recordFailureWithDescription:message inFile:fileName atLine:lineNumber expected:NO];
    }
}

bool RLMHasCachedRealmForPath(NSString *path) {
    return RLMGetAnyCachedRealmForPath(path.UTF8String);
}
