////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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

@class RLMRealm, RLMSchema;

/**
 A helper class intended for use when writing unit tests involving Realms, especially those involving the use of GCD.

 To use this class, create a property on your `XCTestCase` class of type `RLMUnitTestHelper`, and either instantiate the
 test helper upon initialization or lazily when requested.

 Your `XCTestCase` test case subclass must override the `-invokeTest` method. In that method, call the helper's
 `invokeTestWithBlock:` method. Inside the block passed to `-invokeTestWithBlock:`, call `[super invokeTest]`. You can
 also do additional work within the block if necessary.

 The test helper overrides the default Realm configuration to use either a special file or special in-memory identifier.
 Each test's Realms are completely isolated from the Realms of other tests. All internal state will automatically be
 reset after each test.

 Obtain this special Realm for test use simply by calling `[RLMRealm defaultRealm]`. You may also obtain Realms with
 other configurations explicitly, as usual.

 Instead of using GDC functions directly, use the `-dispatch:` and `dispatchAndWait:` methods instead.
 */
@interface RLMUnitTestHelper : NSObject

/**
 An on-disk test Realm for your unit test to use. The Realm is cleaned up and properly destroyed after each test suite.
 */
@property (nonatomic, readonly) RLMRealm *onDiskTestRealm;

/**
 An in-memory test Realm for your unit test to use. The Realm is properly destroyed after each test suite.
 */
@property (nonatomic, readonly) RLMRealm *inMemoryTestRealm;

/**
 Invokes the unit test.
 
 This method should always be called within the `XCUnitTest`'s `-invokeTest` method. The block must contain a call to
 `[super invokeTest]`.
 */
- (void)invokeTestWithBlock:(void (^)(void))invokeBlock;

/**
 Dispatches an asynchronous block on the test-specific dispatch queue. Prefer this method to using GCD directly.
 */
- (void)dispatch:(dispatch_block_t)block;

/**
 Dispatches a block on the test-specific dispatch queue, and wait for the block to complete executing before returning.
 Prefer this method to using GCD directly.
 */
- (void)dispatchAndWait:(dispatch_block_t)block;

@end
