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
import RealmSwift

class SwiftPropertyTypeTest: TestCase {
    
    func testLongType() {
        let longNumber = 17179869184
        let intNumber = 2147483647
        let negativeLongNumber = -17179869184
        let updatedLongNumber = 8589934592
        
        let realm = realmWithTestPath()
        
        realm.beginWrite()
        SwiftIntObject.createInRealm(realm, withObject: [longNumber])
        SwiftIntObject.createInRealm(realm, withObject: [intNumber])
        SwiftIntObject.createInRealm(realm, withObject: [negativeLongNumber])
        realm.commitWrite()
        
        let objects = realm.objects(SwiftIntObject)
        XCTAssertEqual(objects.count, Int(3), "3 rows expected")
        XCTAssertEqual(objects[0].intCol, longNumber, "2 ^ 34 expected")
        XCTAssertEqual(objects[1].intCol, intNumber, "2 ^ 31 - 1 expected")
        XCTAssertEqual(objects[2].intCol, negativeLongNumber, "-2 ^ 34 expected")
        
        realm.beginWrite()
        objects[0].intCol = updatedLongNumber
        realm.commitWrite()
        
        XCTAssertEqual(objects[0].intCol, updatedLongNumber, "After update: 2 ^ 33 expected")
    }

    func testIntSizes() {
        let realm = realmWithTestPath()

        let v16 = Int16(1) << 12
        let v32 = Int32(1) << 30
        // 1 << 40 doesn't auto-promote to Int64 on 32-bit platforms
        let v64 = Int64(1) << 40
        realm.write {
            let obj = SwiftAllIntSizesObject()

            obj.int16 = v16
            XCTAssertEqual(obj.int16, v16)
            obj.int32 = v32
            XCTAssertEqual(obj.int32, v32)
            obj.int64 = v64
            XCTAssertEqual(obj.int64, v64)

            realm.add(obj)
        }

        let obj = realm.objects(SwiftAllIntSizesObject).first!
        XCTAssertEqual(obj.int16, v16)
        XCTAssertEqual(obj.int32, v32)
        XCTAssertEqual(obj.int64, v64)
    }
}
