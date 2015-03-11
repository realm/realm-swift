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
import Foundation

class ObjectAccessorTests: TestCase {
    func setAndTestAllProperties(object: SwiftObject) {
        object.boolCol = true
        XCTAssertEqual(object.boolCol, true)
        object.boolCol = false
        XCTAssertEqual(object.boolCol, false)

        object.intCol = -1
        XCTAssertEqual(object.intCol, -1)
        object.intCol = 0
        XCTAssertEqual(object.intCol, 0)
        object.intCol = 1
        XCTAssertEqual(object.intCol, 1)

        object.floatCol = 20
        XCTAssertEqual(object.floatCol, 20 as Float)
        object.floatCol = 20.2
        XCTAssertEqual(object.floatCol, 20.2 as Float)

        object.doubleCol = 20
        XCTAssertEqual(object.doubleCol, 20)
        object.doubleCol = 20.2
        XCTAssertEqual(object.doubleCol, 20.2)

        object.stringCol = ""
        XCTAssertEqual(object.stringCol, "")
        let utf8TestString = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
        object.stringCol = utf8TestString
        XCTAssertEqual(object.stringCol, utf8TestString)

        let data = "b".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        object.binaryCol = data
        XCTAssertEqual(object.binaryCol, data)

        let date = NSDate(timeIntervalSinceReferenceDate: 2) as NSDate
        object.dateCol = date
        XCTAssertEqual(object.dateCol, date)

        object.objectCol = SwiftBoolObject(object: [true])
        XCTAssertEqual(object.objectCol.boolCol, true)
    }

    func testStandaloneAccessors() {
        let object = SwiftObject()
        setAndTestAllProperties(object)
    }

    func testPersistedAccessors() {
        let object = SwiftObject()
        Realm().beginWrite()
        Realm().create(SwiftObject.self)
        setAndTestAllProperties(object)
        Realm().commitWrite()
    }
}
