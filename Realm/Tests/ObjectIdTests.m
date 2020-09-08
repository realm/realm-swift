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

#import "RLMTestCase.h"
#import <Realm/RLMObjectId.h>

@interface ObjectIdTests : RLMTestCase
@end

@implementation ObjectIdTests

#pragma mark - Initialization

- (void)testObjectIdInitialization {
    NSString *strValue = @"000123450000ffbeef91906c";
    RLMObjectId *objectId = [[RLMObjectId alloc] initWithString:strValue error:nil];
    XCTAssertTrue([objectId.stringValue isEqualToString:strValue]);
    XCTAssertTrue([strValue isEqualToString:objectId.stringValue]);

    NSDate *now = [NSDate date];
    RLMObjectId *objectId2 = [[RLMObjectId alloc] initWithTimestamp:now
                                                  machineIdentifier:10
                                                  processIdentifier:20];
    XCTAssertEqual((int)now.timeIntervalSince1970, objectId2.timestamp.timeIntervalSince1970);
}

- (void)testObjectIdComparision {
    NSString *strValue = @"000123450000ffbeef91906c";
    RLMObjectId *objectId = [[RLMObjectId alloc] initWithString:strValue error:nil];

    NSString *strValue2 = @"000123450000ffbeef91906d";
    RLMObjectId *objectId2 = [[RLMObjectId alloc] initWithString:strValue2 error:nil];

    NSString *strValue3 = @"000123450000ffbeef91906c";
    RLMObjectId *objectId3 = [[RLMObjectId alloc] initWithString:strValue3 error:nil];

    XCTAssertFalse([objectId isEqual:objectId2]);
    XCTAssertTrue([objectId isEqual:objectId3]);
}

- (void)testObjectIdGreaterThan {
    NSString *strValue = @"000123450000ffbeef91906c";
    RLMObjectId *objectId = [[RLMObjectId alloc] initWithString:strValue error:nil];

    NSString *strValue2 = @"000154850000ffbaaf20906d";
    RLMObjectId *objectId2 = [[RLMObjectId alloc] initWithString:strValue2 error:nil];

    NSString *strValue3 = @"000123450000ffbeef91906c";
    RLMObjectId *objectId3 = [[RLMObjectId alloc] initWithString:strValue3 error:nil];

    XCTAssertTrue([objectId2 isGreaterThan:objectId]);
    XCTAssertFalse([objectId isGreaterThan:objectId3]);
}

- (void)testObjectIdGreaterThanOrEqualTo {
    NSString *strValue = @"000123450000ffbeef91906c";
    RLMObjectId *objectId = [[RLMObjectId alloc] initWithString:strValue error:nil];

    NSString *strValue2 = @"000154850000ffbaaf20906d";
    RLMObjectId *objectId2 = [[RLMObjectId alloc] initWithString:strValue2 error:nil];

    NSString *strValue3 = @"000123450000ffbeef91906c";
    RLMObjectId *objectId3 = [[RLMObjectId alloc] initWithString:strValue3 error:nil];

    XCTAssertTrue([objectId2 isGreaterThanOrEqualTo:objectId]);
    XCTAssertTrue([objectId isGreaterThanOrEqualTo:objectId3]);
}

- (void)testObjectIdLessThan {
    NSString *strValue = @"000123450000ffbeef91906c";
    RLMObjectId *objectId = [[RLMObjectId alloc] initWithString:strValue error:nil];

    NSString *strValue2 = @"000154850000ffbaaf20906d";
    RLMObjectId *objectId2 = [[RLMObjectId alloc] initWithString:strValue2 error:nil];

    NSString *strValue3 = @"000123450000ffbeef91906c";
    RLMObjectId *objectId3 = [[RLMObjectId alloc] initWithString:strValue3 error:nil];

    XCTAssertTrue([objectId isLessThan:objectId2]);
    XCTAssertFalse([objectId isLessThan:objectId3]);
}

- (void)testObjectIdLessThanOrEqualTo {
    NSString *strValue = @"000123450000ffbeef91906c";
    RLMObjectId *objectId = [[RLMObjectId alloc] initWithString:strValue error:nil];

    NSString *strValue2 = @"000154850000ffbaaf20906d";
    RLMObjectId *objectId2 = [[RLMObjectId alloc] initWithString:strValue2 error:nil];

    NSString *strValue3 = @"000123450000ffbeef91906c";
    RLMObjectId *objectId3 = [[RLMObjectId alloc] initWithString:strValue3 error:nil];

    XCTAssertTrue([objectId isLessThanOrEqualTo:objectId2]);
    XCTAssertTrue([objectId isLessThanOrEqualTo:objectId3]);
}

@end
