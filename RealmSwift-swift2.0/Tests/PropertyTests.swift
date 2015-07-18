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

class PropertyTests: TestCase {
    var primitiveProperty: Property!
    var linkProperty: Property!
    var primaryProperty: Property!
    var optionalProperty: Property!

    override func setUp() {
        super.setUp()
        autoreleasepool {
            let schema = try! Realm().schema
            self.primitiveProperty = schema["SwiftObject"]!["intCol"]!
            self.linkProperty = schema["SwiftOptionalObject"]!["optObjectCol"]!
            self.primaryProperty = schema["SwiftPrimaryStringObject"]!["stringCol"]!
            self.optionalProperty = schema["SwiftOptionalObject"]!["optObjectCol"]!
        }
    }

    func testName() {
        XCTAssertEqual(primitiveProperty.name, "intCol")
        XCTAssertEqual(linkProperty.name, "optObjectCol")
        XCTAssertEqual(primaryProperty.name, "stringCol")
    }

    func testType() {
        XCTAssertEqual(primitiveProperty.type, PropertyType.Int)
        XCTAssertEqual(linkProperty.type, PropertyType.Object)
        XCTAssertEqual(primaryProperty.type, PropertyType.String)
    }

    func testIndexed() {
        XCTAssertFalse(primitiveProperty.indexed)
        XCTAssertFalse(linkProperty.indexed)
        XCTAssertTrue(primaryProperty.indexed)
    }

    func testOptional() {
        XCTAssertFalse(primitiveProperty.optional)
        XCTAssertTrue(optionalProperty.optional)
    }

    func testObjectClassName() {
        XCTAssertNil(primitiveProperty.objectClassName)
        XCTAssertEqual(linkProperty.objectClassName!, "SwiftBoolObject")
        XCTAssertNil(primaryProperty.objectClassName)
    }

    func testEquals() {
        XCTAssert(try! primitiveProperty == Realm().schema["SwiftObject"]!["intCol"]!)
        XCTAssert(primitiveProperty != linkProperty)
    }
}
