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

import XCTest
import RealmSwift

class SortDescriptorTests: TestCase {

    let sortDescriptor = SortDescriptor(keyPath: "property")

    func testAscendingDefaultsToTrue() {
        XCTAssertTrue(sortDescriptor.ascending)
    }

    func testReversedReturnsReversedDescriptor() {
        let reversed = sortDescriptor.reversed()
        XCTAssertEqual(reversed.keyPath, sortDescriptor.keyPath, "Key path should stay the same when reversed.")
        XCTAssertFalse(reversed.ascending)
        XCTAssertTrue(reversed.reversed().ascending)
    }

    func testDescription() {
        XCTAssertEqual(sortDescriptor.description, "SortDescriptor(keyPath: property, direction: ascending)")
    }

    func testStringLiteralConvertible() {
        let literalSortDescriptor: RealmSwift.SortDescriptor = "property"
        XCTAssertEqual(sortDescriptor, literalSortDescriptor,
            "SortDescriptor should conform to StringLiteralConvertible")
    }

    func testComparison() {
        let sortDescriptor1 = SortDescriptor(keyPath: "property1", ascending: true)
        let sortDescriptor2 = SortDescriptor(keyPath: "property1", ascending: false)
        let sortDescriptor3 = SortDescriptor(keyPath: "property2", ascending: true)
        let sortDescriptor4 = SortDescriptor(keyPath: "property2", ascending: false)

        // validate different
        XCTAssertNotEqual(sortDescriptor1, sortDescriptor2, "Should not match")
        XCTAssertNotEqual(sortDescriptor1, sortDescriptor3, "Should not match")
        XCTAssertNotEqual(sortDescriptor1, sortDescriptor4, "Should not match")

        XCTAssertNotEqual(sortDescriptor2, sortDescriptor3, "Should not match")
        XCTAssertNotEqual(sortDescriptor2, sortDescriptor4, "Should not match")

        XCTAssertNotEqual(sortDescriptor3, sortDescriptor4, "Should not match")

        let sortDescriptor5 = SortDescriptor(keyPath: "property1", ascending: true)
        let sortDescriptor6 = SortDescriptor(keyPath: "property2", ascending: true)

        // validate same
        XCTAssertEqual(sortDescriptor1, sortDescriptor5, "Should match")
        XCTAssertEqual(sortDescriptor3, sortDescriptor6, "Should match")
    }
}
