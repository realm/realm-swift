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

class MapStandaloneTests: MapTests {
    override func createMap() -> SwiftMapPropertyObject {
        let map = SwiftMapPropertyObject()
        XCTAssertNil(map.realm)
        return map
    }

    override func createMapWithLinks() -> SwiftMapOfSwiftObject {
        let map = SwiftMapOfSwiftObject()
        XCTAssertNil(map.realm)
        return map
    }
}

class MapNewlyAddedTests: MapTests {
    override func createMap() -> SwiftMapPropertyObject {
        let map = SwiftMapPropertyObject()
        map.name = "name"
        let realm = realmWithTestPath()
        try! realm.write { realm.add(map) }
        XCTAssertNotNil(map.realm)
        return map
    }

    override func createMapWithLinks() -> SwiftMapOfSwiftObject {
        let map = SwiftMapOfSwiftObject()
        let realm = try! Realm()
        try! realm.write { realm.add(map) }
        XCTAssertNotNil(map.realm)
        return map
    }
}

class MapNewlyCreatedTests: MapTests {
    override func createMap() -> SwiftMapPropertyObject {
        let realm = realmWithTestPath()
        realm.beginWrite()
        let map = realm.create(SwiftMapPropertyObject.self, value: ["name", [], []])
        try! realm.commitWrite()

        XCTAssertNotNil(map.realm)
        return map
    }

    override func createMapWithLinks() -> SwiftMapOfSwiftObject {
        let realm = try! Realm()
        realm.beginWrite()
        let map = realm.create(SwiftMapOfSwiftObject.self)
        try! realm.commitWrite()

        XCTAssertNotNil(map.realm)
        return map
    }
}

class MapRetrievedTests: MapTests {
    override func createMap() -> SwiftMapPropertyObject {
        let realm = realmWithTestPath()
        realm.beginWrite()
        realm.create(SwiftMapPropertyObject.self, value: ["name", [:], [:]])
        try! realm.commitWrite()
        let map = realm.objects(SwiftMapPropertyObject.self).first!

        XCTAssertNotNil(map.realm)
        return map
    }

    override func createMapWithLinks() -> SwiftMapOfSwiftObject {
        let realm = try! Realm()
        realm.beginWrite()
        realm.create(SwiftMapOfSwiftObject.self)
        try! realm.commitWrite()
        let map = realm.objects(SwiftMapOfSwiftObject.self).first!

        XCTAssertNotNil(map.realm)
        return map
    }
}

fileprivate extension Map {
    func addTestObjects(from dictionary: [Key: Value]) where Key: Hashable {
        dictionary.forEach { (k, v) in
            self[k] = v
        }
    }
}

class MapTests: TestCase {
    var str1: SwiftStringObject?
    var str2: SwiftStringObject?
    var mapObject: SwiftMapPropertyObject!
    var map: Map<String, SwiftStringObject>?

    func createMap() -> SwiftMapPropertyObject {
        SwiftMapPropertyObject()//fatalError("abstract")
    }

    func createMapWithLinks() -> SwiftMapOfSwiftObject {
        fatalError("abstract")
    }

    override func setUp() {
        super.setUp()

        let str1 = SwiftStringObject()
        str1.stringCol = "1"
        self.str1 = str1

        let str2 = SwiftStringObject()
        str2.stringCol = "2"
        self.str2 = str2

        mapObject = createMap()
        map = mapObject.map

        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(str1)
            realm.add(str2)
        }
        realm.beginWrite()
    }

    override func tearDown() {
        try! realmWithTestPath().commitWrite()
        str1 = nil
        str2 = nil
        mapObject = nil
        map = nil
        super.tearDown()
    }

    override class var defaultTestSuite: XCTestSuite {
        // Don't run tests for the base class
        if isEqual(MapTests.self) {
            return XCTestSuite(name: "empty")
        }
        return super.defaultTestSuite
    }

    func testPrimitive() {
        let obj = SwiftMapObject()
        let valueInTest = 5
        obj.int[String(valueInTest)] = valueInTest
        //XCTAssertTrue(false)
//        XCTAssertEqual(obj.int.first!.1, 5) // should expect (key, value)
//        XCTAssertEqual(obj.int.last!.1, 5)
//        XCTAssertEqual(obj.int[0].1, 5)
//        XCTAssertEqual(obj.int["5"], 5)
//
//        obj.int.addTestObjects(from: ["6": 6, "7": 7, "8": 8])
//        XCTAssertEqual(obj.int.index(of: 6), 1)
//        XCTAssertEqual(obj.int.max(), 8)
//        XCTAssertEqual(obj.int.sum(), 26)
//
//        obj.string["strKey"] = "strVal"
//        XCTAssertEqual(obj.string.first!.0, "strKey")
//        XCTAssertEqual(obj.string[0].0, "strKey")
//        XCTAssertEqual(obj.string.first!.1, "strVal")
//        XCTAssertEqual(obj.string[0].1, "strVal")


        for entry in obj.int {
            print(entry)
        }

    }

    func testPrimitiveIterationAcrossNil() {
        let obj = SwiftMapObject()
        XCTAssertFalse(obj.int.contains(where: { $0 == "0" || $1 == 5 }))
        XCTAssertFalse(obj.int8.contains(where: { $0 == "0" || $1 == 5 }))
        XCTAssertFalse(obj.int16.contains(where: { $0 == "0" || $1 == 5 }))
        XCTAssertFalse(obj.int32.contains(where: { $0 == "0" || $1 == 5 }))
        XCTAssertFalse(obj.int64.contains(where: { $0 == "0" || $1 == 5 }))
        XCTAssertFalse(obj.float.contains(where: { $0 == "0" || $1 == 3.141592 }))
        XCTAssertFalse(obj.double.contains(where: { $0 == "0" || $1 == 3.141592 }))
//        obj.string["foobar"] = "foobar"
        XCTAssertFalse(obj.string.contains(where: { $0 == "0" || $1 == "foobar" }))
        XCTAssertFalse(obj.data.contains(where: { $0 == "0" || $1 == Data() }))
        XCTAssertFalse(obj.date.contains(where: { $0 == "0" || $1 == Date() }))
        XCTAssertFalse(obj.decimal.contains(where: { $0 == "0" || $1 == Decimal128() }))
        XCTAssertFalse(obj.objectId.contains(where: { $0 == "0" || $1 == ObjectId() }))
        XCTAssertFalse(obj.uuid.contains(where: { $0 == "0" || $1 == UUID() }))

        XCTAssertFalse(obj.intOpt.contains { $1 == nil })
        XCTAssertFalse(obj.int8Opt.contains { $1 == nil })
        XCTAssertFalse(obj.int16Opt.contains { $1 == nil })
        XCTAssertFalse(obj.int32Opt.contains { $1 == nil })
        XCTAssertFalse(obj.int64Opt.contains { $1 == nil })
        XCTAssertFalse(obj.floatOpt.contains { $1 == nil })
        XCTAssertFalse(obj.doubleOpt.contains { $1 == nil })
        XCTAssertFalse(obj.stringOpt.contains { $1 == nil })
        XCTAssertFalse(obj.dataOpt.contains { $1 == nil })
        XCTAssertFalse(obj.dateOpt.contains { $1 == nil })
        XCTAssertFalse(obj.decimalOpt.contains { $1 == nil })
        XCTAssertFalse(obj.objectIdOpt.contains { $1 == nil })
        XCTAssertFalse(obj.uuidOpt.contains { $1 == nil })
    }

    func testInvalidated() {
        guard let map = map else {
            fatalError("Test precondition failure")
        }
        XCTAssertFalse(map.isInvalidated)

        if let realm = mapObject.realm {
            realm.delete(mapObject)
            XCTAssertTrue(map.isInvalidated)
        }
    }

    func testFastEnumerationWithMutation() {
        guard let map = map else {
            fatalError("Test precondition failure")
        }
        for i in 0...5 {
            map[String(i)] = SwiftStringObject(value: [String(i)])
        }
        var sum: Int = 0
        var i: Int = 5
        for obj in map.values {
            sum += Int(obj.stringCol)!
            map[String(i)] = SwiftStringObject(value: [String(i)])
            i+=1
        }
        XCTAssertEqual(sum, 15)
    }

    func testMapDescription() {
        guard let map = map else {
            fatalError("Test precondition failure")
        }
        for i in 0...5 {
            map[String(i)] = SwiftStringObject(value: [String(i)])
        }

        XCTAssertTrue(map.description.hasPrefix("Map<string, SwiftStringObject>"))
        XCTAssertTrue(map.description.contains("[3]: SwiftStringObject {\n\t\tstringCol = 3;\n\t}"))
    }

    func testAppendObject() {
        guard let map = map else {
            fatalError("Test precondition failure")
        }
        for i in 0..<5 {
            map[String(i)] = SwiftStringObject(value: [String(i)])
        }
        XCTAssertEqual(Int(5), map.count)
        XCTAssertEqual("0", map["0"]!.stringCol)
        XCTAssertEqual("1", map["1"]!.stringCol)
        XCTAssertEqual("2", map["2"]!.stringCol)
    }

    func testKeysValuesArraysAccess() {
        let stringMap = Map<String, String>()
        for i in 0...5 {
            stringMap[String(i)] = String(i)
        }
        XCTAssertEqual(stringMap.keys, stringMap.values)
    }

    func testInsert() {
        guard let map = map, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        XCTAssertEqual(Int(0), map.count)

        XCTAssertNil(map[str1.stringCol])
        map[str1.stringCol] = str1
        XCTAssertEqual(Int(1), map.count)

        XCTAssertNil(map[str2.stringCol])
        map[str2.stringCol] = str2
        XCTAssertEqual(Int(2), map.count)
    }

    func testRemove() {
        guard let map = map, let str1 = str1 else {
            fatalError("Test precondition failure")
        }

        map[str1.stringCol] = str1
        XCTAssertEqual(Int(1), map.count)
        XCTAssertNotNil(map[str1.stringCol])

        map.removeValue(for: str1.stringCol)
        XCTAssertEqual(Int(0), map.count)
        XCTAssertNil(map[str1.stringCol])
    }

    func testRemoveAll() {
        guard let map = map else {
            fatalError("Test precondition failure")
        }
        for i in 0..<5 {
            map[String(i)] = SwiftStringObject(value: [String(i)])
        }
        XCTAssertEqual(Int(5), map.count)
        map.removeAll()
        XCTAssertEqual(Int(0), map.count)
        map.removeAll()
        XCTAssertEqual(Int(0), map.count)
    }

    func testReplace() {
        guard let map = map, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        XCTAssertNil(map["testKey"])
        map["testKey"] = str1
        XCTAssertEqual(Int(1), map.count)
        assertEqual(map["testKey"], str1)
        map["testKey"] = str2
        XCTAssertEqual(Int(1), map.count)
        assertEqual(map["testKey"], str2)
    }

    func testChangesArePersisted() {
        guard let map = map else {
            fatalError("Test precondition failure")
        }
        if let realm = map.realm {
            for i in 0..<5 {
                map[String(i)] = SwiftStringObject(value: [String(i)])
            }

            let anotherMap = realm.objects(SwiftMapPropertyObject.self).first!.map
            XCTAssertEqual(map.keys, anotherMap.keys)
        }
    }

    func testPopulateEmptyMap() {
        guard let map = map, let str1 = str1 else {
            fatalError("Test precondition failure")
        }

        XCTAssertEqual(map.count, 0, "Should start with no array elements.")

        map["a"] = SwiftStringObject(value: ["a"])
        map["b"] = realmWithTestPath().create(SwiftStringObject.self, value: ["b"])
        map[str1.stringCol] = str1

        XCTAssertEqual(map.count, 3)
        XCTAssertEqual(map["a"]!.stringCol, "a")
        XCTAssertEqual(map["b"]!.stringCol, "b")
        XCTAssertEqual(map[str1.stringCol]!.stringCol, str1.stringCol)

        // Make sure we can enumerate
        XCTAssertTrue(false)
//        for (key, value) in map {
//            XCTAssertFalse(key.description.isEmpty, "Object should have description")
//            XCTAssertFalse(value.description.isEmpty, "Object should have description")
//        }
    }

    func testEnumeratingMap() {
        let mapObject = createMapWithLinks()

        mapObject.realm?.beginWrite()
        for i in 0..<10 {
            mapObject.map[String(i)] = SwiftObject()
        }
        try! mapObject.realm?.commitWrite()

        XCTAssertEqual(10, mapObject.map.count)

        XCTAssertTrue(false)
//        for (_, value) in mapObject.map {
//            XCTAssertEqual(123, value.intCol)
//            XCTAssertEqual(false, value.objectCol!.boolCol)
//            XCTAssertEqual(0, value.arrayCol.count)
//        }
    }

    func testValueForKey() {
        let realm = try! Realm()
        try! realm.write {
            for value in [1, 2] {
                let mapObject = SwiftMapOfSwiftObject()
                let object = SwiftObject()
                object.intCol = value
                object.doubleCol = Double(value)
                object.stringCol = String(value)
                object.decimalCol = Decimal128(number: value as NSNumber)
                object.objectIdCol = try! ObjectId(string: String(repeating: String(value), count: 24))
                mapObject.map[String(value)] = object
                realm.add(mapObject)
            }
        }

        let mapObjects = realm.objects(SwiftMapOfSwiftObject.self)
        let mapsOfObjects = mapObjects.value(forKeyPath: "map") as! [Map<String, SwiftObject>]
        let objects = realm.objects(SwiftObject.self)

        func testProperty<T: Equatable>(line: UInt = #line, fn: @escaping (SwiftObject) -> T) {
            let tr = mapObjects.flatMap {
                $0.map.values.map(fn)
            }
            let properties: [T] = Array(mapObjects.flatMap {
                $0.map.values.map(fn)
            })
            let kvcProperties: [T] = Array(mapsOfObjects.flatMap { $0.values.map(fn) })
            XCTAssertEqual(properties, kvcProperties, line: line)
        }
        func testProperty<T: Equatable>(_ name: String, line: UInt = #line, fn: @escaping (SwiftObject) -> T) {
            let properties = Array(objects.compactMap(fn))
            let mapsOfObjects = objects.value(forKeyPath: name) as! [T]
            let kvcProperties = Array(mapsOfObjects.compactMap { $0 })
            XCTAssertEqual(properties, kvcProperties, line: line)
        }

        testProperty { $0.intCol }
        testProperty { $0.doubleCol }
        testProperty { $0.stringCol }
        testProperty { $0.decimalCol }
        testProperty { $0.objectIdCol }

        testProperty("intCol") { $0.intCol }
        testProperty("doubleCol") { $0.doubleCol }
        testProperty("stringCol") { $0.stringCol }
        testProperty("decimalCol") { $0.decimalCol }
        testProperty("objectIdCol") { $0.objectIdCol }
    }

    func testUnmanagedListComparison() {
        let obj = SwiftIntObject()
        obj.intCol = 5
        let obj2 = SwiftIntObject()
        obj2.intCol = 6
        let obj3 = SwiftIntObject()
        obj3.intCol = 8

        let objects = ["obj": obj, "obj2": obj2, "obj3": obj3]
        let objects2 = ["obj": obj, "obj2": obj2]

        let mapL = Map<String, SwiftIntObject>()
        let mapR = Map<String, SwiftIntObject>()
        XCTAssertEqual(mapL, mapR, "Empty instances should be equal by `==` operator")

        mapL.addTestObjects(from: objects)
        mapR.addTestObjects(from: objects)

        let mapX = Map<String, SwiftIntObject>()
        mapX.addTestObjects(from: objects2)

        XCTAssertTrue(mapL !== mapR, "instances should not be identical")

        XCTAssertEqual(mapL, mapR, "instances should be equal by `==` operator")
        XCTAssertNotEqual(mapL, mapX, "instances should be equal by `==` operator")

        XCTAssertTrue(mapL.isEqual(mapR), "instances should be equal by `isEqual` method")
        XCTAssertTrue(!mapL.isEqual(mapX), "instances should be equal by `isEqual` method")

        mapX["obj3"] = obj3
        XCTAssertEqual(mapL, mapX, "instances should be equal by `==` operator")
    }
}
