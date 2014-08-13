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
#import <Realm/Realm.h>

#if defined(__IPHONE_8_0) || defined(__MAC_10_10)
#define SWIFT
#import <TestFramework/TestFramework.h>
#else
#import "RLMTestObjects.h"
#endif


NSString *RLMTestRealmPath(void);
NSString *RLMDefaultRealmPath(void);
NSString *RLMRealmPathForFile(NSString *);


#if !defined(SWIFT)
@interface XCTestExpectation : NSObject
- (void)fulfill;
@end
#endif

@interface RLMTestCase : XCTestCase

- (RLMRealm *)realmWithTestPath;
- (RLMRealm *)realmWithTestPathAndSchema:(RLMSchema *)schema;
- (RLMRealm *)dynamicRealmWithTestPathAndSchema:(RLMSchema *)schema;

#if !defined(SWIFT)
- (void)waitForExpectationsWithTimeout:(NSTimeInterval)interval handler:(id)noop;
- (XCTestExpectation *)expectationWithDescription:(NSString *)desc;
#endif

@end
