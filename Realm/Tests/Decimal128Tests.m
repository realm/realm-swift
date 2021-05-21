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
#import <Realm/RLMDecimal128.h>

@interface Decimal128Tests : RLMTestCase
@end

@implementation Decimal128Tests

#pragma mark - Initialization

- (void)testDecimal128Initialization {
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithNumber:@3.14159];
    RLMDecimal128 *d2 = [[RLMDecimal128 alloc] initWithString:@"3.14159" error:nil];
    NSError *error;
    RLMDecimal128 *d3 = [[RLMDecimal128 alloc] initWithString:@"1.2.3" error:&error];
    XCTAssertNil(error);
    RLMDecimal128 *d4 = [[RLMDecimal128 alloc] initWithValue:@3.14159];
    RLMDecimal128 *d5 = [[RLMDecimal128 alloc] initWithValue:@"123.456"];
    RLMDecimal128 *d6 = [[RLMDecimal128 alloc] initWithNumber:@123456789];
    RLMDecimal128 *d7 = [[RLMDecimal128 alloc] init];
    XCTAssertEqual(d1.doubleValue, 3.14159);
    XCTAssertTrue([d1.stringValue isEqualToString:@"3.14159"]);
    XCTAssertEqual(d2.doubleValue, 3.14159);
    XCTAssertTrue([d2.stringValue isEqualToString:@"3.14159"]);
    XCTAssertTrue(d3.isNaN);
    XCTAssertEqual(d4.doubleValue, 3.14159);
    XCTAssertTrue([d5.stringValue isEqualToString:@"123.456"]);
    XCTAssertTrue([d6.stringValue isEqualToString:@"123456789"]);
    XCTAssertEqual(d7.doubleValue, 0);
}

- (void)testDecimal128Decimal {
    NSNumber *n1 = @3.14159;
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithString:@"3.14159" error:nil];
    XCTAssertEqual(n1.decimalValue._exponent, d1.decimalValue._exponent);
    XCTAssertEqual(n1.decimalValue._isCompact, d1.decimalValue._isCompact);
    XCTAssertEqual(n1.decimalValue._isNegative, d1.decimalValue._isNegative);
    XCTAssertEqual(n1.decimalValue._length, d1.decimalValue._length);
    XCTAssertEqual(n1.decimalValue._mantissa[0], d1.decimalValue._mantissa[0]);
    XCTAssertEqual(n1.decimalValue._reserved, d1.decimalValue._reserved);
}

#pragma mark - Arithmetic

- (void)testDecimal128Addition {
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithNumber:@3.14159];
    RLMDecimal128 *d2 = [d1 decimalNumberByAdding:[[RLMDecimal128 alloc] initWithString:@"3.14159" error:nil]];
    XCTAssertEqual(d2.doubleValue, 6.28318);
    XCTAssertTrue([d2.stringValue isEqualToString:@"6.28318"]);
    XCTAssertEqual(d2.doubleValue, 6.28318);
}

- (void)testDecimal128Subtraction {
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithNumber:@2.5];
    RLMDecimal128 *d2 = [d1 decimalNumberBySubtracting:[[RLMDecimal128 alloc] initWithString:@"5.5" error:nil]];
    XCTAssertEqual(d2.doubleValue, -3.0);
    XCTAssertTrue([d2.stringValue isEqualToString:@"-3.0"]);
}

- (void)testDecimal128Division {
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithNumber:@0.21];
    RLMDecimal128 *d2 = [[RLMDecimal128 alloc] initWithString:@"0.7" error:nil];
    RLMDecimal128 *result = [d1 decimalNumberByDividingBy:d2];
    XCTAssertEqual(result.doubleValue, 0.3);
    XCTAssertTrue([result.stringValue isEqualToString:@"3E-1"]);
}

- (void)testDecimal128Multiplication {
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithNumber:@1.5];
    RLMDecimal128 *d2 = [[RLMDecimal128 alloc] initWithString:@"2.5" error:nil];
    RLMDecimal128 *result = [d1 decimalNumberByMultiplyingBy:d2];
    XCTAssertEqual(result.doubleValue, 3.75);
    XCTAssertTrue([result.stringValue isEqualToString:@"3.75"]);
}

#pragma mark - Comparison

- (void)testDecimal128InitializationEquals {
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithNumber:@3.14159];
    RLMDecimal128 *d2 = [[RLMDecimal128 alloc] initWithString:@"3.14159" error:nil];
    XCTAssertTrue([d1 isEqual:d2]);
}

- (void)testDecimal128InitializationGreaterThan {
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithNumber:@3.14160];
    RLMDecimal128 *d2 = [[RLMDecimal128 alloc] initWithString:@"3.14159" error:nil];
    XCTAssertTrue([d1 isGreaterThan:d2]);
}

- (void)testDecimal128InitializationGreaterThanEquals {
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithNumber:@3.14158];
    RLMDecimal128 *d2 = [[RLMDecimal128 alloc] initWithString:@"3.14159" error:nil];
    RLMDecimal128 *d3 = [[RLMDecimal128 alloc] initWithString:@"3.14159" error:nil];
    XCTAssertFalse([d1 isGreaterThanOrEqualTo:d2]);
    XCTAssertTrue([d2 isLessThanOrEqualTo:d3]);
}

- (void)testDecimal128InitializationLessThan {
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithNumber:@3.14159];
    RLMDecimal128 *d2 = [[RLMDecimal128 alloc] initWithString:@"3.14160" error:nil];
    XCTAssertTrue([d1 isLessThan:d2]);
}

- (void)testDecimal128InitializationLessThanEquals {
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithNumber:@3.14159];
    RLMDecimal128 *d2 = [[RLMDecimal128 alloc] initWithString:@"3.14160" error:nil];
    RLMDecimal128 *d3 = [[RLMDecimal128 alloc] initWithString:@"3.14160" error:nil];
    XCTAssertTrue([d1 isLessThanOrEqualTo:d2]);
    XCTAssertTrue([d2 isLessThanOrEqualTo:d3]);
}

#pragma mark - Miscellaneous

- (void)testNaN {
    RLMDecimal128 *nan = [[RLMDecimal128 alloc] initWithValue:[NSNull null]];
    XCTAssertTrue(nan.isNaN);
}

- (void)testMininumMaximumValue {
    RLMDecimal128 *min = RLMDecimal128.minimumDecimalNumber;
    RLMDecimal128 *max = RLMDecimal128.maximumDecimalNumber;
    XCTAssertTrue([min isLessThan:max]);
    XCTAssertTrue([max isGreaterThan:min]);
}

- (void)testMagnitude {
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithNumber:@-123.321];
    RLMDecimal128 *exp1 = [RLMDecimal128 decimalWithNumber:@123.321];
    RLMDecimal128 *d2 = [[RLMDecimal128 alloc] initWithNumber:@456.321];
    RLMDecimal128 *exp2 = [RLMDecimal128 decimalWithNumber:@456.321];
    XCTAssertTrue([d1.magnitude isEqual:exp1]);
    XCTAssertTrue([d2.magnitude isEqual:exp2]);
}

- (void)testNegate {
    RLMDecimal128 *d1 = [[RLMDecimal128 alloc] initWithNumber:@-123.321];
    RLMDecimal128 *exp1 = [RLMDecimal128 decimalWithNumber:@123.321];
    RLMDecimal128 *d2 = [[RLMDecimal128 alloc] initWithNumber:@456.321];
    RLMDecimal128 *exp2 = [RLMDecimal128 decimalWithNumber:@-456.321];
    [d1 negate];
    [d2 negate];
    XCTAssertTrue([d1 isEqual:exp1]);
    XCTAssertTrue([d2 isEqual:exp2]);
}

@end
