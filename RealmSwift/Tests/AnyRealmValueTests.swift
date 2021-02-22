////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

class AnyRealmTypeObject: Object {
    var anyValue = AnyRealmValue()
    @objc dynamic var stringObj: SwiftStringObject?
}

class AnyRealmValueTests: TestCase {

    func testInt() {
        let o = AnyRealmTypeObject()
        o.anyValue.value = .int(123)
        XCTAssertEqual(o.anyValue.value.intValue, 123)
        o.anyValue.value = .int(456)
        XCTAssertEqual(o.anyValue.value.intValue, 456)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.intValue, 456)
        try! realm.write {
            o.anyValue.value = .int(987)
        }
        XCTAssertEqual(o.anyValue.value.intValue, 987)
    }

    func testFloat() {
        let o = AnyRealmTypeObject()
        o.anyValue.value = .float(123.456)
        XCTAssertEqual(o.anyValue.value.floatValue, 123.456)
        o.anyValue.value = .float(456.678)
        XCTAssertEqual(o.anyValue.value.floatValue, 456.678)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.floatValue, 456.678)
        try! realm.write {
            o.anyValue.value = .float(987.123)
        }
        XCTAssertEqual(o.anyValue.value.floatValue, 987.123)
    }

    func testString() {
        let o = AnyRealmTypeObject()
        o.anyValue.value = .string("good news everyone")
        XCTAssertEqual(o.anyValue.value.stringValue, "good news everyone")
        o.anyValue.value = .string("professor farnsworth")
        XCTAssertEqual(o.anyValue.value.stringValue, "professor farnsworth")
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.stringValue, "professor farnsworth")
        try! realm.write {
            o.anyValue.value = .string("Dr. zoidberg")
        }
        XCTAssertEqual(o.anyValue.value.stringValue, "Dr. zoidberg")
    }

    func testData() {
        let d1 = Data(repeating: 1, count: 64)
        let d2 = Data(repeating: 2, count: 64)
        let d3 = Data(repeating: 3, count: 64)
        let o = AnyRealmTypeObject()
        o.anyValue.value = .data(d1)
        XCTAssertEqual(o.anyValue.value.dataValue, d1)
        o.anyValue.value = .data(d2)
        XCTAssertEqual(o.anyValue.value.dataValue, d2)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.dataValue, d2)
        try! realm.write {
            o.anyValue.value = .data(d3)
        }
        XCTAssertEqual(o.anyValue.value.dataValue, d3)
    }

    func testDate() {
        let d1 = Date(timeIntervalSinceNow: 10000)
        let d2 = Date(timeIntervalSinceNow: 20000)
        let d3 = Date(timeIntervalSinceNow: 30000)
        let o = AnyRealmTypeObject()
        o.anyValue.value = .date(d1)
        XCTAssertEqual(o.anyValue.value.dateValue, d1)
        o.anyValue.value = .date(d2)
        XCTAssertEqual(o.anyValue.value.dateValue, d2)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.dateValue!.timeIntervalSince1970,
                       d2.timeIntervalSince1970, accuracy:1)
        try! realm.write {
            o.anyValue.value = .date(d3)
        }
        XCTAssertEqual(o.anyValue.value.dateValue!.timeIntervalSince1970,
                       d3.timeIntervalSince1970, accuracy:1)
    }

    func testObjectId() {
        let o1 = ObjectId.generate()
        let o2 = ObjectId.generate()
        let o3 = ObjectId.generate()
        let o = AnyRealmTypeObject()
        o.anyValue.value = .objectId(o1)
        XCTAssertEqual(o.anyValue.value.objectIdValue, o1)
        o.anyValue.value = .objectId(o2)
        XCTAssertEqual(o.anyValue.value.objectIdValue, o2)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.objectIdValue, o2)
        try! realm.write {
            o.anyValue.value = .objectId(o3)
        }
        XCTAssertEqual(o.anyValue.value.objectIdValue, o3)
    }

    func testDecimal128() {
        let d1 = Decimal128(floatLiteral: 1234.5678)
        let d2 = Decimal128(floatLiteral: 6789.1234)
        let d3 = Decimal128(floatLiteral: 1.0)
        let o = AnyRealmTypeObject()
        o.anyValue.value = .decimal128(d1)
        XCTAssertEqual(o.anyValue.value.decimal128Value, d1)
        o.anyValue.value = .decimal128(d2)
        XCTAssertEqual(o.anyValue.value.decimal128Value, d2)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.decimal128Value, d2)
        try! realm.write {
            o.anyValue.value = .decimal128(d3)
        }
        XCTAssertEqual(o.anyValue.value.decimal128Value, d3)
    }

    func testObject() {
        let o = AnyRealmTypeObject()
        let so = SwiftStringObject()
        so.stringCol = "hello"
        o.anyValue.value = .object(so)
        XCTAssertEqual(o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol, "hello")
        o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol = "there"
        XCTAssertEqual(o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol, "there")
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol, "there")
        try! realm.write {
            o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol = "bye!"
        }
        XCTAssertEqual(o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol, "bye!")
    }

    func testAssortment() {
        // The purpose of this test is to reuse a mixed container
        // and ensure no issues exist in doing that.
        let o = AnyRealmTypeObject()
        let so = SwiftStringObject()
        so.stringCol = "hello"
        let data = Data(repeating: 1, count: 64)
        let date = Date()
        let objectId = ObjectId.generate()
        let decimal = Decimal128(floatLiteral: 12345.6789)

        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }

        testVariation(object: o, value: .int(123), keyPath: \.intValue, expected: 123, realm: realm)
        testVariation(object: o, value: .float(123.456), keyPath: \.floatValue, expected: 123.456, realm: realm)
        testVariation(object: o, value: .string("hello there"), keyPath: \.stringValue, expected: "hello there", realm: realm)
        testVariation(object: o, value: .data(data), keyPath: \.dataValue, expected: data, realm: realm)
        //testVariation(object: o, value: .date(date), keyPath: \.dateValue, expected: date, realm: realm)
        testVariation(object: o, value: .objectId(objectId), keyPath: \.objectIdValue, expected: objectId, realm: realm)
        testVariation(object: o, value: .decimal128(decimal), keyPath: \.decimal128Value, expected: decimal, realm: realm)

        try! realm.write {
            o.anyValue.value = .object(so)
        }
        XCTAssertEqual(o.anyValue.value.objectValue(SwiftStringObject.self)!.stringCol, "hello")
    }

    private func testVariation<T: Equatable>(object: AnyRealmTypeObject,
                                             value: AnyRealmValue.Value,
                                             keyPath: KeyPath<AnyRealmValue.Value, T?>,
                                             expected: T,
                                             realm: Realm) {
        try! realm.write {
            object.anyValue.value = value
        }
        XCTAssertEqual(object.anyValue.value[keyPath: keyPath], expected)
    }
}
