////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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
#import "RLMAssertions.h"
#import "RLMTestObjects.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
NSURL *RLMTestRealmURL(void);
NSURL *RLMDefaultRealmURL(void);
NSString *RLMRealmPathForFile(NSString *);
NSData *RLMGenerateKey(void);
#ifdef __cplusplus
}
#endif

@interface RLMTestCaseBase : XCTestCase
- (void)resetRealmState;
@end

@interface RLMTestCase : RLMTestCaseBase

- (RLMRealm *)realmWithTestPath;
- (RLMRealm *)realmWithTestPathAndSchema:(nullable RLMSchema *)schema;

- (RLMRealm *)inMemoryRealmWithIdentifier:(NSString *)identifier;
- (RLMRealm *)readOnlyRealmWithURL:(NSURL *)fileURL error:(NSError **)error;

- (void)deleteFiles;
- (void)deleteRealmFileAtURL:(NSURL *)fileURL;

- (void)waitForNotification:(RLMNotification)expectedNote realm:(RLMRealm *)realm block:(dispatch_block_t)block;

- (nullable id)nonLiteralNil;
- (BOOL)encryptTests;

- (void)dispatchAsync:(dispatch_block_t)block;
- (void)dispatchAsyncAndWait:(dispatch_block_t)block;

@property (nonatomic, readonly) dispatch_queue_t bgQueue;

@end

NS_ASSUME_NONNULL_END
