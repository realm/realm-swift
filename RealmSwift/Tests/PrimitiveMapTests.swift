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

protocol MapValueFactory {
    associatedtype T: RealmCollectionValue
    associatedtype W: RealmCollectionValue = T
    associatedtype Key: MapKeyType
    associatedtype AverageType: AddableType = Double
    static func map(_ obj: SwiftMapObject) -> Map<Key, T>
    static func values() -> [(key: Key, value: T)]
    static func doubleValue(_ value: AverageType) -> Double
    static func doubleValue(t value: T) -> Double
    static func doubleValue(w value: W) -> Double
}

extension MapValueFactory {
    static func doubleValue(_ value: Double) -> Double {
        return value
    }
    static func doubleValue(t value: T) -> Double {
        return (value as! NSNumber).doubleValue
    }
    static func doubleValue(w value: W) -> Double {
        return (value as! NSNumber).doubleValue
    }
}

class PrimitiveMapTestsBase<O: ObjectFactory, V: MapValueFactory>: TestCase {
    var realm: Realm?
    var obj: SwiftMapObject!
    var obj2: SwiftMapObject!
    var map: Map<V.Key, V.T>!
    var otherMap: Map<V.Key, V.T>!
    var values: [(key: V.Key, value: V.T)]!

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
