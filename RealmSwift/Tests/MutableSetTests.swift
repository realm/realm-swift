////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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

class MutableSetTests: TestCase {
    var str1: SwiftStringObject?
    var str2: SwiftStringObject?
    var str3: SwiftStringObject?
    var setObject: SwiftMutableSetPropertyObject!
    var setObject2: SwiftMutableSetPropertyObject!
    var set: MutableSet<SwiftStringObject>?
    var set2: MutableSet<SwiftStringObject>?

    func createSet() -> SwiftMutableSetPropertyObject {
        fatalError("abstract")
    }

    func createSetWithLinks() -> SwiftMutableSetOfSwiftObject {
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

        let str3 = SwiftStringObject()
        str3.stringCol = "3"
        self.str3 = str3

        setObject = createSet()
        setObject2 = createSet()
        set = setObject.set
        set2 = setObject2.set

        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(str1)
            realm.add(str2)
            realm.add(str3)
        }

        realm.beginWrite()
    }

    override func tearDown() {
        try! realmWithTestPath().commitWrite()

        str1 = nil
        str2 = nil
        str3 = nil
        setObject = nil
        setObject2 = nil
        set = nil
        set2 = nil

        super.tearDown()
    }

    override class var defaultTestSuite: XCTestSuite {
        // Don't run tests for the base class
        if isEqual(MutableSetTests.self) {
            return XCTestSuite(name: "empty")
        }
        return super.defaultTestSuite
    }

    func testPrimitive() {
        let obj = SwiftMutableSetObject()
        obj.int.insert(5)
        XCTAssertEqual(obj.int.first!, 5)
        XCTAssertEqual(obj.int.last!, 5)
        XCTAssertEqual(obj.int[0], 5)
        obj.int.insert(objectsIn: [6, 7, 8] as [Int])
        XCTAssertEqual(obj.int.max(), 8)
        XCTAssertEqual(obj.int.sum(), 26)

        obj.string.insert("str")
        XCTAssertEqual(obj.string.first!, "str")
        XCTAssertEqual(obj.string[0], "str")
    }

    func testPrimitiveIterationAcrossNil() {
        let obj = SwiftMutableSetObject()
        XCTAssertFalse(obj.int.contains(5))
        XCTAssertFalse(obj.int8.contains(5))
        XCTAssertFalse(obj.int16.contains(5))
        XCTAssertFalse(obj.int32.contains(5))
        XCTAssertFalse(obj.int64.contains(5))
        XCTAssertFalse(obj.float.contains(3.141592))
        XCTAssertFalse(obj.double.contains(3.141592))
        XCTAssertFalse(obj.string.contains("foobar"))
        XCTAssertFalse(obj.data.contains(Data()))
        XCTAssertFalse(obj.date.contains(Date()))
        XCTAssertFalse(obj.decimal.contains(Decimal128()))
        XCTAssertFalse(obj.objectId.contains(ObjectId()))
        XCTAssertFalse(obj.uuidOpt.contains(UUID()))

        XCTAssertFalse(obj.intOpt.contains { $0 == nil })
        XCTAssertFalse(obj.int8Opt.contains { $0 == nil })
        XCTAssertFalse(obj.int16Opt.contains { $0 == nil })
        XCTAssertFalse(obj.int32Opt.contains { $0 == nil })
        XCTAssertFalse(obj.int64Opt.contains { $0 == nil })
        XCTAssertFalse(obj.floatOpt.contains { $0 == nil })
        XCTAssertFalse(obj.doubleOpt.contains { $0 == nil })
        XCTAssertFalse(obj.stringOpt.contains { $0 == nil })
        XCTAssertFalse(obj.dataOpt.contains { $0 == nil })
        XCTAssertFalse(obj.dateOpt.contains { $0 == nil })
        XCTAssertFalse(obj.decimalOpt.contains { $0 == nil })
        XCTAssertFalse(obj.objectIdOpt.contains { $0 == nil })
        XCTAssertFalse(obj.uuidOpt.contains { $0 == nil })
    }

    func testInvalidated() {
        guard let set = set else {
            fatalError("Test precondition failure")
        }
        XCTAssertFalse(set.isInvalidated)

        if let realm = setObject.realm {
            realm.delete(setObject)
            XCTAssertTrue(set.isInvalidated)
        }
    }

    func testFastEnumerationWithMutation() {
        guard let set = set, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        set.insert(objectsIn: [str1, str2, str1, str2, str1, str2, str1, str2, str1,
            str2, str1, str2, str1, str2, str1, str2, str1, str2, str1, str2])
        var str = ""
        for obj in set {
            str += obj.stringCol
            set.insert(objectsIn: [str1])
        }

        XCTAssertTrue(set.contains(str1))
        XCTAssertTrue(set.contains(str2))
    }

    func testAppendObject() {
        guard let set = set, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }
        for str in [str1, str2, str1] {
            set.insert(str)
        }
        XCTAssertEqual(Int(2), set.count)
        XCTAssertTrue(set.contains(str1))
        XCTAssertTrue(set.contains(str2))
    }

    func testInsert() {
        guard let set = set, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }
        set.insert(objectsIn: [str1, str2, str1])
        XCTAssertEqual(Int(2), set.count)
        XCTAssertTrue(set.contains(str1))
        XCTAssertTrue(set.contains(str2))
    }

    func testAppendResults() {
        guard let set = set, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }
        set.insert(objectsIn: realmWithTestPath().objects(SwiftStringObject.self))
        XCTAssertEqual(Int(3), set.count)
        // The unmanaged NSSet backing object won't work with MutableSet.contains(:)
        set.forEach {
            // Ordering is not guaranteed so we can't subscript
            XCTAssertTrue($0.isSameObject(as: str1) || $0.isSameObject(as: str2) || $0.isSameObject(as: str3))
        }
    }

    func testRemoveAll() {
        guard let set = set, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        set.insert(objectsIn: [str1, str2])

        set.removeAll()
        XCTAssertEqual(Int(0), set.count)

        set.removeAll() // should be a no-op
        XCTAssertEqual(Int(0), set.count)
    }

    func testRemoveObject() {
        guard let set = set, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }

        set.insert(objectsIn: [str1, str2])
        XCTAssertTrue(set.contains(str1))
        XCTAssertEqual(Int(2), set.count)
        set.remove(str1)
        XCTAssertFalse(set.contains(str1))
        XCTAssertEqual(Int(1), set.count)
        set.removeAll()
        XCTAssertEqual(Int(0), set.count)
        XCTAssertFalse(set.contains(str1))
        XCTAssertFalse(set.contains(str2))
    }

    func testChangesArePersisted() {
        guard let set = set, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }
        if let realm = set.realm {
            set.insert(objectsIn: [str1, str2])

            let otherSet = realm.objects(SwiftMutableSetPropertyObject.self).first!.set
            XCTAssertEqual(Int(2), otherSet.count)
        }
    }

    func testPopulateEmptySet() {
        guard let set = set else {
            fatalError("Test precondition failure")
        }

        XCTAssertEqual(set.count, 0, "Should start with no set elements.")

        let obj = SwiftStringObject()
        obj.stringCol = "a"
        set.insert(obj)
        set.insert(realmWithTestPath().create(SwiftStringObject.self, value: ["b"]))
        set.insert(obj)

        XCTAssertEqual(set.count, 2)
        set.forEach {
            XCTAssertTrue($0.stringCol == "a" || $0.stringCol == "b")
        }

        // Make sure we can enumerate
        for obj in set {
            XCTAssertTrue(obj.description.utf16.count > 0, "Object should have description")
        }
    }

    func testEnumeratingSetWithSetProperties() {
        let setObject = createSetWithLinks()

        setObject.realm?.beginWrite()
        for _ in 0..<10 {
            setObject.set.insert(SwiftObject())
        }
        try! setObject.realm?.commitWrite()

        XCTAssertEqual(10, setObject.set.count)

        for object in setObject.set {
            XCTAssertEqual(123, object.intCol)
            XCTAssertEqual(false, object.objectCol!.boolCol)
            XCTAssertEqual(0, object.setCol.count)
        }
    }

    func testValueForKey() {
        let realm = try! Realm()
        try! realm.write {
            for value in [1, 2] {
                let setObject = SwiftMutableSetOfSwiftObject()
                let object = SwiftObject()
                object.intCol = value
                object.doubleCol = Double(value)
                object.stringCol = String(value)
                object.decimalCol = Decimal128(number: value as NSNumber)
                object.objectIdCol = try! ObjectId(string: String(repeating: String(value), count: 24))
                setObject.set.insert(object)
                realm.add(setObject)
            }
        }

        let setObjects = realm.objects(SwiftMutableSetOfSwiftObject.self)
        let setsOfObjects = setObjects.value(forKeyPath: "set") as! [MutableSet<SwiftObject>]
        let objects = realm.objects(SwiftObject.self)

        func testProperty<T: Equatable>(line: UInt = #line, fn: @escaping (SwiftObject) -> T) {
            let properties: [T] = Array(setObjects.flatMap { $0.set.map(fn) })
            let kvcProperties: [T] = Array(setsOfObjects.flatMap { $0.map(fn) })
            XCTAssertEqual(properties, kvcProperties, line: line)
        }
        func testProperty<T: Equatable>(_ name: String, line: UInt = #line, fn: @escaping (SwiftObject) -> T) {
            let properties = Array(objects.compactMap(fn))
            let setsOfObjects = objects.value(forKeyPath: name) as! [T]
            let kvcProperties = Array(setsOfObjects.compactMap { $0 })

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

    @available(*, deprecated) // Silence deprecation warnings for RealmOptional
    func testValueForKeyOptional() {
        let realm = try! Realm()
        try! realm.write {
            for value in [1, 2] {
                let setObject = SwiftMutableSetOfSwiftOptionalObject()
                let object = SwiftOptionalObject()
                object.optIntCol.value = value
                object.optInt8Col.value = Int8(value)
                object.optDoubleCol.value = Double(value)
                object.optStringCol = String(value)
                object.optNSStringCol = NSString(format: "%d", value)
                object.optDecimalCol = Decimal128(number: value as NSNumber)
                object.optObjectIdCol = try! ObjectId(string: String(repeating: String(value), count: 24))
                setObject.set.insert(object)
                realm.add(setObject)
            }
        }

        let setObjects = realm.objects(SwiftMutableSetOfSwiftOptionalObject.self)
        let setOfObjects = setObjects.value(forKeyPath: "set") as! [MutableSet<SwiftOptionalObject>]
        let objects = realm.objects(SwiftOptionalObject.self)

        func testProperty<T: Equatable>(line: UInt = #line, fn: @escaping (SwiftOptionalObject) -> T) {
            let properties: [T] = Array(setObjects.flatMap { $0.set.map(fn) })
            let kvcProperties: [T] = Array(setOfObjects.flatMap { $0.map(fn) })
            XCTAssertEqual(properties, kvcProperties, line: line)
        }
        func testProperty<T: Equatable>(_ name: String, line: UInt = #line, fn: @escaping (SwiftOptionalObject) -> T) {
            let properties = Array(objects.compactMap(fn))
            let setsOfObjects = objects.value(forKeyPath: name) as! [T]
            let kvcProperties = Array(setsOfObjects.compactMap { $0 })

            XCTAssertEqual(properties, kvcProperties, line: line)
        }

        testProperty { $0.optIntCol.value }
        testProperty { $0.optInt8Col.value }
        testProperty { $0.optDoubleCol.value }
        testProperty { $0.optStringCol }
        testProperty { $0.optNSStringCol }
        testProperty { $0.optDecimalCol }
        testProperty { $0.optObjectCol }

        testProperty("optIntCol") { $0.optIntCol.value }
        testProperty("optInt8Col") { $0.optInt8Col.value }
        testProperty("optDoubleCol") { $0.optDoubleCol.value }
        testProperty("optStringCol") { $0.optStringCol }
        testProperty("optNSStringCol") { $0.optNSStringCol }
        testProperty("optDecimalCol") { $0.optDecimalCol }
        testProperty("optObjectCol") { $0.optObjectCol }
    }

    func testUnmanagedSetComparison() {
        let obj = SwiftIntObject()
        obj.intCol = 5
        let obj2 = SwiftIntObject()
        obj2.intCol = 6
        let obj3 = SwiftIntObject()
        obj3.intCol = 8

        let objects = [obj, obj2, obj3]
        let objects2 = [obj, obj2]

        let set1 = MutableSet<SwiftIntObject>()
        let set2 = MutableSet<SwiftIntObject>()
        XCTAssertEqual(set1, set2, "Empty instances should be equal by `==` operator")

        set1.insert(objectsIn: objects)
        set2.insert(objectsIn: objects)

        let set3 = MutableSet<SwiftIntObject>()
        set3.insert(objectsIn: objects2)

        XCTAssertTrue(set1 !== set2, "instances should not be identical")

        XCTAssertEqual(set1, set2, "instances should be equal by `==` operator")
        XCTAssertNotEqual(set1, set3, "instances should be equal by `==` operator")

        XCTAssertTrue(set1.isEqual(set2), "instances should be equal by `isEqual` method")
        XCTAssertTrue(!set1.isEqual(set3), "instances should be equal by `isEqual` method")

        XCTAssertEqual(Array(set1), Array(set2), "instances converted to Swift.Array should be equal")
        XCTAssertNotEqual(Array(set1), Array(set3), "instances converted to Swift.Array should be equal")
        XCTAssertEqual(Set(set1), Set(set2), "instances converted to Swift.Array should be equal")
        XCTAssertNotEqual(Set(set1), Set(set3), "instances converted to Swift.Array should be equal")
        set3.insert(obj3)
        XCTAssertEqual(set1, set3, "instances should be equal by `==` operator")
    }

    func testSubset() {
        guard let set = set, let set2 = set2, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }
        set.removeAll()
        set2.removeAll()
        XCTAssertEqual(Int(0), set.count)
        XCTAssertEqual(Int(0), set2.count)
        set.insert(objectsIn: [str1, str2, str1])
        set2.insert(objectsIn: [str1])
        XCTAssertEqual(Int(2), set.count)
        XCTAssertEqual(Int(1), set2.count)
        XCTAssertTrue(set2.isSubset(of: set))
        XCTAssertFalse(set.isSubset(of: set2))
    }

    func testUnion() {
        guard let set = set, let set2 = set2, let str1 = str1, let str2 = str2 else {
            fatalError("Test precondition failure")
        }
        set.removeAll()
        set2.removeAll()
        set.insert(objectsIn: [str1, str2, str1])
        set2.insert(objectsIn: [str1])
        XCTAssertEqual(Int(2), set.count)
        XCTAssertEqual(Int(1), set2.count)
        XCTAssertTrue(set2.isSubset(of: set))
        XCTAssertFalse(set.isSubset(of: set2))
    }

    func testIntersection() {
        guard let set = set, let set2 = set2, let str1 = str1, let str2 = str2, let str3 = str3 else {
            fatalError("Test precondition failure")
        }
        set.removeAll()
        set2.removeAll()
        set.insert(objectsIn: [str1, str2])
        set2.insert(objectsIn: [str2, str3])
        XCTAssertEqual(Int(2), set.count)
        XCTAssertEqual(Int(2), set2.count)
        XCTAssertTrue(set.intersects(set2))
        XCTAssertTrue(set2.intersects(set))

        set.formIntersection(set2)
        XCTAssertTrue(set.intersects(set2))
        XCTAssertTrue(set2.intersects(set))
        XCTAssertEqual(Int(1), set.count)
    }

    func testSubtract() {
        guard let set = set, let set2 = set2, let str1 = str1, let str2 = str2, let str3 = str3 else {
            fatalError("Test precondition failure")
        }
        set.removeAll()
        set2.removeAll()
        set.insert(objectsIn: [str1, str2])
        set2.insert(objectsIn: [str2, str3])
        XCTAssertEqual(Int(2), set.count)
        XCTAssertEqual(Int(2), set2.count)

        set.subtract(set2)
        XCTAssertEqual(Int(1), set.count)
        XCTAssertTrue(set.contains(str1))
    }
}

class MutableSetStandaloneTests: MutableSetTests {
    override func createSet() -> SwiftMutableSetPropertyObject {
        let set = SwiftMutableSetPropertyObject()
        XCTAssertNil(set.realm)
        return set
    }

    override func createSetWithLinks() -> SwiftMutableSetOfSwiftObject {
        let set = SwiftMutableSetOfSwiftObject()
        XCTAssertNil(set.realm)
        return set
    }
}

class MutableSetNewlyAddedTests: MutableSetTests {
    override func createSet() -> SwiftMutableSetPropertyObject {
        let set = SwiftMutableSetPropertyObject()
        set.name = "name"
        let realm = realmWithTestPath()
        try! realm.write { realm.add(set) }

        XCTAssertNotNil(set.realm)
        return set
    }

    override func createSetWithLinks() -> SwiftMutableSetOfSwiftObject {
        let set = SwiftMutableSetOfSwiftObject()
        let realm = try! Realm()
        try! realm.write { realm.add(set) }

        XCTAssertNotNil(set.realm)
        return set
    }
}

class MutableSetNewlyCreatedTests: MutableSetTests {
    override func createSet() -> SwiftMutableSetPropertyObject {
        let realm = realmWithTestPath()
        realm.beginWrite()
        let set = realm.create(SwiftMutableSetPropertyObject.self, value: ["name", [], []])
        try! realm.commitWrite()

        XCTAssertNotNil(set.realm)
        return set
    }

    override func createSetWithLinks() -> SwiftMutableSetOfSwiftObject {
        let realm = try! Realm()
        realm.beginWrite()
        let set = realm.create(SwiftMutableSetOfSwiftObject.self)
        try! realm.commitWrite()

        XCTAssertNotNil(set.realm)
        return set
    }
}

class MutableSetRetrievedTests: MutableSetTests {
    override func createSet() -> SwiftMutableSetPropertyObject {
        let realm = realmWithTestPath()
        realm.beginWrite()
        realm.create(SwiftMutableSetPropertyObject.self, value: ["name", [], []])
        try! realm.commitWrite()
        let set = realm.objects(SwiftMutableSetPropertyObject.self).last!

        XCTAssertNotNil(set.realm)
        return set
    }

    override func createSetWithLinks() -> SwiftMutableSetOfSwiftObject {
        let realm = try! Realm()
        realm.beginWrite()
        realm.create(SwiftMutableSetOfSwiftObject.self)
        try! realm.commitWrite()
        let set = realm.objects(SwiftMutableSetOfSwiftObject.self).first!

        XCTAssertNotNil(set.realm)
        return set
    }
}
