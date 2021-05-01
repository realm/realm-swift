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
// swiftlint:disable identifier_name

class PrimitiveMapTestsBase<O: ObjectFactory, V: ValueFactory>: TestCase {
    var realm: Realm?
    var obj: SwiftMapObject!
    var obj2: SwiftMapObject!
    var map: Map<String, V.T>!
    var otherMap: Map<String, V.T>!
    var values: [V.T]!

    class func _defaultTestSuite() -> XCTestSuite {
        return defaultTestSuite
    }

    override func setUp() {
        obj = SwiftMapObject()
        obj2 = SwiftMapObject()
        if O.isManaged() {
            let config = Realm.Configuration(inMemoryIdentifier: "test",
                                             objectTypes: [SwiftMapObject.self, SwiftStringObject.self])
            realm = try! Realm(configuration: config)
            realm!.beginWrite()
            realm!.add(obj)
            realm!.add(obj2)
        }
        map = V.map(obj)
        otherMap = V.map(obj2)
        values = V.values()
    }

    override func tearDown() {
        realm?.cancelWrite()
        realm = nil
        map = nil
        otherMap = nil
        obj = nil
        obj2 = nil
    }
}
