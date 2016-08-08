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

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "RLMHandover_Private.hpp"

@interface ConformanceTests : XCTestCase

@property (nonatomic, readonly) unsigned int count;
@property (nonatomic, readonly) Class *classList;

@end

static BOOL classOrSuperclass_conformsToProtocol(Class cls, Protocol *protocol) {
    if (cls == nil) return NO;
    else if (class_conformsToProtocol(cls, protocol)) return YES;
    else return classOrSuperclass_conformsToProtocol(class_getSuperclass(cls), protocol);
}

@implementation ConformanceTests

- (void)setUp {
    [super setUp];

    _classList = objc_copyClassList(&_count);
}

- (void)tearDown {
    free(_classList);
}

- (void)testThreadConfinedPrivateConformance {
    // Ensure that conformance to `RLMThreadConfined` implies conformance to `RLMThreadConfined_Private`
    Protocol *publicProtocol = @protocol(RLMThreadConfined);
    Protocol *privateProtocol = @protocol(RLMThreadConfined_Private);
    for (Class *c = self.classList; c < self.classList + self.count; c++) {
        if (classOrSuperclass_conformsToProtocol(*c, publicProtocol)) {
            XCTAssertTrue(classOrSuperclass_conformsToProtocol(*c, privateProtocol),
                          "%@ conforms to `RLMThreadConfined` but not `RLMThreadConfined_Private`", *c);
        }
    }
}

@end
