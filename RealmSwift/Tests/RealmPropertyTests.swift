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
import Realm
import RealmSwift

class RealmPropertyObject: Object {
    var optionalIntValue = RealmProperty<Int?>()
    var optionalInt8Value = RealmProperty<Int8?>()
    var optionalInt16Value = RealmProperty<Int16?>()
    var optionalInt32Value = RealmProperty<Int32?>()
    var optionalInt64Value = RealmProperty<Int64?>()
    var optionalFloatValue = RealmProperty<Float?>()
    var optionalDoubleValue = RealmProperty<Double?>()
    var optionalBoolValue = RealmProperty<Bool?>()
    // required for schema validation, but not used in tests.
    @objc dynamic var int = 0
}

class RealmPropertyTests: TestCase {
    private func test<T: Equatable>(keyPath: KeyPath<RealmPropertyObject, RealmProperty<T?>>,
                                    value: T?) {
        let o = RealmPropertyObject()
        o[keyPath: keyPath].value = value
        XCTAssertEqual(o[keyPath: keyPath].value, value)
        o[keyPath: keyPath].value = nil
        XCTAssertNil(o[keyPath: keyPath].value)
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(o)
        }
        XCTAssertNil(o[keyPath: keyPath].value)
        try! realm.write {
            o[keyPath: keyPath].value = value
        }
        XCTAssertEqual(o[keyPath: keyPath].value, value)
    }

    func testObject() {
        test(keyPath: \.optionalIntValue, value: 123456)
        test(keyPath: \.optionalInt8Value, value: 127 as Int8)
        test(keyPath: \.optionalInt16Value, value: 32766 as Int16)
        test(keyPath: \.optionalInt32Value, value: 2147483647 as Int32)
        test(keyPath: \.optionalInt64Value, value: 0x7FFFFFFFFFFFFFFF as Int64)
        test(keyPath: \.optionalFloatValue, value: 12345.6789 as Float)
        test(keyPath: \.optionalDoubleValue, value: 12345.6789 as Double)
        test(keyPath: \.optionalBoolValue, value: true)
    }
}
