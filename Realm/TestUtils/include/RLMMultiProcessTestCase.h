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

@class NSTask, RLMChildProcessEnvironment;

@interface RLMMultiProcessTestCase : RLMTestCase
// if true, this is running the main test process
@property (nonatomic, readonly) bool isParent;

// spawn a child process running the current test and wait for it complete
// returns the return code of the process
- (int)runChildAndWait;
- (int)runChildAndWaitWithAppIds:(NSArray *)appIds;
- (int)runChildAndWaitWithEnvironment:(RLMChildProcessEnvironment *)environment;

- (NSTask *)childTask;
- (NSTask *)childTaskWithAppIds:(NSArray *)appIds;

@end

#define RLMRunChildAndWait() \
    XCTAssertEqual(0, [self runChildAndWait], @"Tests in child process failed")

#define RLMRunChildAndWaitWithAppIds(...) \
    XCTAssertEqual(0, [self runChildAndWaitWithAppIds:@[__VA_ARGS__]], @"Tests in child process failed")
