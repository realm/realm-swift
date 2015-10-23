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

#ifdef __cplusplus
extern "C" {
#endif
NSString *RLMTestRealmPath(void);
NSString *RLMDefaultRealmPath(void);
NSString *RLMRealmPathForFile(NSString *);
NSData *RLMGenerateKey(void);
#ifdef __cplusplus
}
#endif

@interface RLMTestCase : XCTestCase

- (RLMRealm *)realmWithTestPath;
- (RLMRealm *)realmWithTestPathAndSchema:(RLMSchema *)schema;

- (RLMRealm *)inMemoryRealmWithIdentifier:(NSString *)identifier;
- (RLMRealm *)readOnlyRealmWithPath:(NSString *)path error:(NSError **)error;

- (void)deleteFiles;
- (void)deleteRealmFileAtPath:(NSString *)realmPath;

- (void)waitForNotification:(NSString *)expectedNote realm:(RLMRealm *)realm block:(dispatch_block_t)block;

- (id)nonLiteralNil;

- (void)dispatchAsync:(dispatch_block_t)block;
- (void)dispatchAsyncAndWait:(dispatch_block_t)block;

@end
