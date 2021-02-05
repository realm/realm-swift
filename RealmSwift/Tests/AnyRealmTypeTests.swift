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

class AnyRealmTypeTests: TestCase {

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
}
