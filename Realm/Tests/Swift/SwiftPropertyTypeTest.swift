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

import XCTest
import Realm
import RealmTestSupport

class SwiftRLMPropertyTypeTest: RLMTestCase {

    func testLongType() {
        let longNumber: Int64 = 17179869184
        let intNumber: Int64 = 2147483647
        let negativeLongNumber: Int64 = -17179869184
        let updatedLongNumber: Int64 = 8589934592

        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        _ = SwiftRLMLongObject.create(in: realm, withValue: [NSNumber(value: longNumber)])
        _ = SwiftRLMLongObject.create(in: realm, withValue: [NSNumber(value: intNumber)])
        _ = SwiftRLMLongObject.create(in: realm, withValue: [NSNumber(value: negativeLongNumber)])
        try! realm.commitWriteTransaction()

        let objects = SwiftRLMLongObject.allObjects(in: realm)
        XCTAssertEqual(objects.count, UInt(3), "3 rows expected")
        XCTAssertEqual((objects[0] as! SwiftRLMLongObject).longCol, longNumber, "2 ^ 34 expected")
        XCTAssertEqual((objects[1] as! SwiftRLMLongObject).longCol, intNumber, "2 ^ 31 - 1 expected")
        XCTAssertEqual((objects[2] as! SwiftRLMLongObject).longCol, negativeLongNumber, "-2 ^ 34 expected")

        realm.beginWriteTransaction()
        (objects[0] as! SwiftRLMLongObject).longCol = updatedLongNumber
        try! realm.commitWriteTransaction()

        XCTAssertEqual((objects[0] as! SwiftRLMLongObject).longCol, updatedLongNumber, "After update: 2 ^ 33 expected")
    }

    func testIntSizes() {
        let realm = realmWithTestPath()

        let v8  = Int8(1)  << 5
        let v16 = Int16(1) << 12
        let v32 = Int32(1) << 30
        // 1 << 40 doesn't auto-promote to Int64 on 32-bit platforms
        let v64 = Int64(1) << 40
        try! realm.transaction {
            let obj = SwiftRLMAllIntSizesObject()

            obj.int8  = v8
            XCTAssertEqual(obj.int8, v8)
            obj.int16 = v16
            XCTAssertEqual(obj.int16, v16)
            obj.int32 = v32
            XCTAssertEqual(obj.int32, v32)
            obj.int64 = v64
            XCTAssertEqual(obj.int64, v64)

            realm.add(obj)
        }

        let obj = SwiftRLMAllIntSizesObject.allObjects(in: realm)[0] as! SwiftRLMAllIntSizesObject
        XCTAssertEqual(obj.int8, v8)
        XCTAssertEqual(obj.int16, v16)
        XCTAssertEqual(obj.int32, v32)
        XCTAssertEqual(obj.int64, v64)
    }

    func testIntSizes_objc() {
        let realm = realmWithTestPath()

        let v16 = Int16(1) << 12
        let v32 = Int32(1) << 30
        // 1 << 40 doesn't auto-promote to Int64 on 32-bit platforms
        let v64 = Int64(1) << 40
        try! realm.transaction {
            let obj = AllIntSizesObject()

            obj.int16 = v16
            XCTAssertEqual(obj.int16, v16)
            obj.int32 = v32
            XCTAssertEqual(obj.int32, v32)
            obj.int64 = v64
            XCTAssertEqual(obj.int64, v64)

            realm.add(obj)
        }

        let obj = AllIntSizesObject.allObjects(in: realm)[0] as! AllIntSizesObject
        XCTAssertEqual(obj.int16, v16)
        XCTAssertEqual(obj.int32, v32)
        XCTAssertEqual(obj.int64, v64)
    }

    func testLazyVarProperties() {
        let realm = realmWithTestPath()
        let succeeded : Void? = try? realm.transaction {
            realm.add(SwiftRLMLazyVarObject())
        }
        XCTAssertNotNil(succeeded, "Writing an NSObject-based object with an lazy property should work.")
    }

    func testIgnoredLazyVarProperties() {
        let realm = realmWithTestPath()
        let succeeded : Void? = try? realm.transaction {
            realm.add(SwiftRLMIgnoredLazyVarObject())
        }
        XCTAssertNotNil(succeeded, "Writing an object with an ignored lazy property should work.")
    }

    func testObjectiveCTypeProperties() {
        let realm = realmWithTestPath()
        var object: SwiftRLMObjectiveCTypesObject!
        let now = NSDate()
        let data = "fizzbuzz".data(using: .utf8)! as Data as NSData
        try! realm.transaction {
            object = SwiftRLMObjectiveCTypesObject()
            realm.add(object)
            object.stringCol = "Hello world!"
            object.dateCol = now
            object.dataCol = data
            object.numCol = 42
        }
        XCTAssertEqual("Hello world!", object.stringCol)
        XCTAssertEqual(now, object.dateCol)
        XCTAssertEqual(data, object.dataCol)
        XCTAssertEqual(42, object.numCol)
    }
}
