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

#import <Foundation/Foundation.h>
#import <XCTest/XCTestCase.h>

@class RLMUser;

FOUNDATION_EXTERN void RLMAssertThrowsWithReasonMatchingSwift(XCTestCase *self,
                                                              __attribute__((noescape)) dispatch_block_t block,
                                                              NSString *regexString,
                                                              NSString *message,
                                                              NSString *fileName,
                                                              NSUInteger lineNumber);

// Return a fake sync user which can be used to create sync configurations
// for tests which don't actually need to talk to the server
FOUNDATION_EXTERN RLMUser *RLMDummyUser(void);

@interface NSUUID (RLMUUIDCompareTests)
- (NSComparisonResult)compare:(NSUUID *)other;
@end

// It appears to be impossible to check this from Swift so we need a helper function
FOUNDATION_EXTERN bool RLMThreadSanitizerEnabled(void);

