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

import XCTest
import RealmSwift

class Decimal128Tests: TestCase {

    // MARK: - Initialization
    func testDecimal128Initialization() {
        let d1: Decimal128 = 3.14159
        let d2: Decimal128 = .init(number: 3.14159)
        let d3: Decimal128 = 123
        let d4: Decimal128 = "9.876543"
        let d5 = Decimal128.init(exactly: 0b00000101)

        XCTAssertEqual(d1, 3.14159)
        XCTAssertEqual(d2, 3.14159)
        XCTAssertEqual(d3, 123)
        XCTAssertEqual(d4, "9.876543")
        XCTAssertEqual(d5, 5)
    }

    // MARK: Arithmetic
    func testDecimal128Addition() {
        let d1: Decimal128 = 3.144444
        let d2: Decimal128 = 3.144444
        let d3: Decimal128 = "1.234567"
        let d4: Decimal128 = "9.876543"
        let d5 = Decimal128.init(exactly: 0b00000010)
        let d6 = Decimal128.init(exactly: 0b00000001)

        let addition1 = d1+d2
        let addition2 = d3+d4
        let addition3 = d5!+d6!

        XCTAssertEqual(addition1, 6.28888)
        XCTAssertEqual(addition2.description, "11.111110")
        XCTAssertEqual(d1, 3.144444)
        XCTAssertEqual(d2, 3.144444)
        XCTAssertEqual(d3.description, "1.234567")
        XCTAssertEqual(d4.description, "9.876543")
        XCTAssertEqual(addition3, 3.0)
        XCTAssertEqual(d5, 2.0)
        XCTAssertEqual(d6, 1.0)
    }

    func testDecimal128AdditionAssignment() {
        var d1: Decimal128 = 3.144444
        let d2: Decimal128 = 3.144444
        var d3: Decimal128 = "1.234567"
        var d4: Decimal128 = "9.876543"
        var d5 = Decimal128.init(exactly: 0b00000010)

        d1+=d2
        d3+="1.234567"
        d4+=2.0000000013456546123
        d5!+=0b00000010

        XCTAssertEqual(d1, 6.28888)
        XCTAssertEqual(d3, "2.469134")
        XCTAssertEqual(d4.doubleValue, 11.876543000000002)
        XCTAssertEqual(d5, 4.0)
    }

    func testDecimal128Subtraction() {
        let d1: Decimal128 = 3.144444
        let d2: Decimal128 = 3.144444
        let d3: Decimal128 = "1.234567"
        let d4: Decimal128 = "9.876543"
        let d5 = Decimal128.init(exactly: 0b00000010)
        let d6 = Decimal128.init(exactly: 0b00000001)

        let addition1 = d1-d2
        let addition2 = d3-d4
        let addition3 = d5!-d6!

        XCTAssertEqual(addition1, 6.28888)
        XCTAssertEqual(addition2.description, "11.111110")
        XCTAssertEqual(d1, 3.144444)
        XCTAssertEqual(d2, 3.144444)
        XCTAssertEqual(d3.description, "1.234567")
        XCTAssertEqual(d4.description, "9.876543")
        XCTAssertEqual(addition3, 3.0)
        XCTAssertEqual(d5, 2.0)
        XCTAssertEqual(d6, 1.0)
    }

    func testDecimal128AdditionSubtractionAssignment() {
        var d1: Decimal128 = 3.144444
        let d2: Decimal128 = 3.144444
        var d3: Decimal128 = "1.234567"
        var d4: Decimal128 = "9.876543"
        var d5 = Decimal128.init(exactly: 0b00000010)

        d1-=d2
        d3-="1.234567"
        d4-=2.0000000013456546123
        d5!-=0b00000010

        XCTAssertEqual(d1, 6.28888)
        XCTAssertEqual(d3, "2.469134")
        XCTAssertEqual(d4.doubleValue, 11.876543000000002)
        XCTAssertEqual(d5, 4.0)
    }

    func testDecimal128Division() {
        let d1: Decimal128 = 7
        let d2: Decimal128 = 3.5
        let d3: Decimal128 = "0.21"
        let d4: Decimal128 = "0.7"
        let d5 = Decimal128.init(exactly: 0b00000010)
        let d6 = Decimal128.init(exactly: 0b00000001)

        let division1 = d1/d2
        let division2 = d3/d4
        let division3 = d5!/d6!

        XCTAssertEqual(division1, 2)
        XCTAssertEqual(division2, 0.3)
        XCTAssertEqual(division3, 2)
    }

    func testDecimal128AdditionDivisionAssignment() {
        var d1: Decimal128 = 3.144444
        let d2: Decimal128 = 3.144444
        var d3: Decimal128 = "1.234567"
        var d4: Decimal128 = "9.876543"
        var d5 = Decimal128.init(exactly: 0b00000010)

        d1/=d2
        d3/="1.234567"
        d4/=2.0000000013456546123
        d5!/=0b00000010

        XCTAssertEqual(d1, 6.28888)
        XCTAssertEqual(d3, "2.469134")
        XCTAssertEqual(d4.doubleValue, 11.876543000000002)
        XCTAssertEqual(d5, 4.0)
    }

    func testDecimal128Multiplication() {
        let d1: Decimal128 = 7
        let d2: Decimal128 = 3.5
        let d3: Decimal128 = "0.21"
        let d4: Decimal128 = "0.7"
        let d5 = Decimal128.init(exactly: 0b00000010)
        let d6 = Decimal128.init(exactly: 0b00000001)

        let division1 = d1*d2
        let division2 = d3*d4
        let division3 = d5!*d6!

        XCTAssertEqual(division1, 2)
        XCTAssertEqual(division2, 0.3)
        XCTAssertEqual(division3, 2)
    }

    func testDecimal128AdditionMultiplicationAssignment() {
        var d1: Decimal128 = 3.144444
        let d2: Decimal128 = 3.144444
        var d3: Decimal128 = "1.234567"
        var d4: Decimal128 = "9.876543"
        var d5 = Decimal128.init(exactly: 0b00000010)

        d1*=d2
        d3*="1.234567"
        d4*=2.0000000013456546123
        d5!*=0b00000010

        XCTAssertEqual(d1, 6.28888)
        XCTAssertEqual(d3, "2.469134")
        XCTAssertEqual(d4.doubleValue, 11.876543000000002)
        XCTAssertEqual(d5, 4.0)
    }

    // MARK: Comparison
    func testDecimal128ComparisionEquals() {
        let d1: Decimal128 = 3.14159
        let d2: Decimal128 = .init(number: 3.14159)
        let d3: Decimal128 = 123
        let d4: Decimal128 = "123"
        let d5 = Decimal128.init(exactly: 0b00000101)
        let d6: Decimal128 = 5

        XCTAssertTrue(d1 == d2)
        XCTAssertTrue(d3 == d4)
        XCTAssertTrue(d5 == d6)
    }

    func testDecimal128ComparisionNotEquals() {
        let d1: Decimal128 = 3.14159
        let d2: Decimal128 = .init(number: 3.14159)
        let d3: Decimal128 = 123
        let d4: Decimal128 = "123"
        let d5 = Decimal128.init(exactly: 0b00000101)
        let d6: Decimal128 = 5

        XCTAssertFalse(d1 != d2)
        XCTAssertFalse(d3 != d4)
        XCTAssertFalse(d5 != d6)
    }

    func testDecimal128ComparisionGreaterThan() {
        let d1: Decimal128 = 3.14160
        let d2: Decimal128 = .init(number: 3.14159)
        let d3: Decimal128 = 124
        let d4: Decimal128 = "123"
        let d5 = Decimal128.init(exactly: 0b00000001)
        let d6: Decimal128 = 5

        XCTAssertTrue(d1 > d2)
        XCTAssertTrue(d3 > d4)
        XCTAssertFalse(d5! > d6)
    }

    func testDecimal128ComparisionGreaterThanEquals() {
        let d1: Decimal128 = 3.14159
        let d2: Decimal128 = .init(number: 3.14159)
        let d3: Decimal128 = 124
        let d4: Decimal128 = "123"
        let d5 = Decimal128.init(exactly: 0b00000001)
        let d6: Decimal128 = 5

        XCTAssertTrue(d1 >= d2)
        XCTAssertTrue(d3 >= d4)
        XCTAssertFalse(d5! >= d6)
    }

    func testDecimal128ComparisionLessThan() {
        let d1: Decimal128 = 3.14159
        let d2: Decimal128 = .init(number: 3.14160)
        let d3: Decimal128 = 122
        let d4: Decimal128 = "123"
        let d5 = Decimal128.init(exactly: 0b00000010)
        let d6: Decimal128 = 1

        XCTAssertTrue(d1 < d2)
        XCTAssertTrue(d3 < d4)
        XCTAssertFalse(d5! < d6)
    }

    func testDecimal128ComparisionLessThanEqual() {
        let d1: Decimal128 = 3.14160
        let d2: Decimal128 = .init(number: 3.14160)
        let d3: Decimal128 = 123
        let d4: Decimal128 = "123"
        let d5 = Decimal128.init(exactly: 0b00000010)
        let d6: Decimal128 = 1

        XCTAssertTrue(d1 <= d2)
        XCTAssertTrue(d3 <= d4)
        XCTAssertFalse(d5! <= d6)
    }

    // MARK: Miscellaneous
    func testIsNaN() {
        let d1: Decimal128 = "not a number"
        XCTAssertTrue(d1.isNaN)
        XCTAssertTrue(d1.isSignaling)
        XCTAssertTrue(d1.isSignalingNaN)
    }

    func testMinMax() {
        let min: Decimal128 = .min
        let max: Decimal128 = .max
        XCTAssertGreaterThan(max, min)
        XCTAssertLessThan(min, max)
    }

    func testMagnitude() {
        let d1: Decimal128 = -123.321
        let exp1: Decimal128 = 123.321
        let d2: Decimal128 = 456.321
        let exp2: Decimal128 = 456.321
        XCTAssertEqual(d1.magnitude, exp1)
        XCTAssertEqual(d2.magnitude, exp2)
    }

    func testNegate() {
        let d1: Decimal128 = -123.321
        let d2: Decimal128 = 456.321
        let exp1: Decimal128 = 123.321
        let exp2: Decimal128 = -456.321
        d1.negate()
        d2.negate()
        XCTAssertEqual(d1, exp1)
        XCTAssertEqual(d2, exp2)
    }

    func testAdvance() {
        let d1: Decimal128 = -123.321
        let result1 = d1.advanced(by: -123.321)
        let d2: Decimal128 = -150.0
        let result2 = d2.advanced(by: 300.0)
        XCTAssertEqual(result1, -246.642)
        XCTAssertEqual(result2, 150.0)
    }

    func testDistance() {
        let d: Decimal128 = 10.0
        let result1 = d.distance(to: 5.0)
        let result2 = d.distance(to: 15.0)
        XCTAssertEqual(result1, -5.0)
        XCTAssertEqual(result2, 5.0)
    }
}
