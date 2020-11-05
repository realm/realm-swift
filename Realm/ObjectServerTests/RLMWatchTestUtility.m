////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

#import "RLMWatchTestUtility.h"

#import <Realm/RLMBSON.h>

@implementation RLMWatchTestUtility {
    NSUInteger _targetChangeEventCount;
    NSUInteger _currentChangeEventCount;
    RLMObjectId *_matchingObjectId;
    BOOL _didOpenWasCalled;
    __weak XCTestExpectation *_expectation;
}

- (instancetype)initWithChangeEventCount:(NSUInteger)changeEventCount
                             expectation:(XCTestExpectation *)expectation {
    if (self = [super init]) {
        _targetChangeEventCount = changeEventCount;
        _semaphore = dispatch_semaphore_create(0);
        _isOpenSemaphore = dispatch_semaphore_create(0);
        _expectation = expectation;
        return self;
    }
    return nil;
}

- (instancetype)initWithChangeEventCount:(NSUInteger)changeEventCount
                        matchingObjectId:(RLMObjectId *)matchingObjectId
                             expectation:(XCTestExpectation *)expectation {
    if (self = [super init]) {
        _targetChangeEventCount = changeEventCount;
        _semaphore = dispatch_semaphore_create(0);
        _isOpenSemaphore = dispatch_semaphore_create(0);
        _matchingObjectId = matchingObjectId;
        _expectation = expectation;
        return self;
    }
    return nil;
}

- (void)changeStreamDidCloseWithError:(nullable NSError *)error {
    XCTAssertNil(error);
    XCTAssertTrue(_didOpenWasCalled);
    XCTAssertEqual(_currentChangeEventCount, _targetChangeEventCount);
    [_expectation fulfill];
}

- (void)changeStreamDidOpen:(nonnull __unused RLMChangeStream *)changeStream {
    _didOpenWasCalled = YES;
    dispatch_semaphore_signal(self.isOpenSemaphore);
}

- (void)changeStreamDidReceiveChangeEvent:(nonnull id<RLMBSON>)changeEvent {
    _currentChangeEventCount++;
    if (_matchingObjectId) {
        RLMObjectId *objectId = ((NSDictionary *)changeEvent)[@"fullDocument"][@"_id"];
        XCTAssertTrue([objectId.stringValue isEqualToString:_matchingObjectId.stringValue]);
        dispatch_semaphore_signal(self.semaphore);
    } else {
        dispatch_semaphore_signal(self.semaphore);
    }
}

- (void)changeStreamDidReceiveError:(nonnull NSError *)error {
    XCTAssertNil(error);
}

@end
