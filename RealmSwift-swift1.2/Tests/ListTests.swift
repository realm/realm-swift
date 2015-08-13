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

class ListTests: TestCase {
    var str1: SwiftStringObject!
    var str2: SwiftStringObject!
    var arrayObject: SwiftArrayPropertyObject!
    var array: List<SwiftStringObject>!

    func createArray() -> SwiftArrayPropertyObject {
        fatalError("abstract")
    }

    func createArrayWithLinks() -> SwiftListOfSwiftObject {
        fatalError("abstract")
    }

    override func setUp() {
        super.setUp()

        str1 = SwiftStringObject()
        str1.stringCol = "1"
        str2 = SwiftStringObject()
        str2.stringCol = "2"
        arrayObject = createArray()
        array = arrayObject.array

        let realm = realmWithTestPath()
        realm.write {
            realm.add(self.str1)
            realm.add(self.str2)
        }

        realm.beginWrite()
    }

    override func tearDown() {
        realmWithTestPath().commitWrite()

        str1 = nil
        str2 = nil
        arrayObject = nil
        array = nil

        super.tearDown()
    }

    override class func defaultTestSuite() -> XCTestSuite! {
        // Don't run tests for the base class
        if isEqual(ListTests) {
            return nil
        }
        return super.defaultTestSuite()
    }

    func testDescription() {
        XCTAssertFalse(array.description.isEmpty)
    }

    func testInvalidated() {
        XCTAssertFalse(array.invalidated)

        if let realm = arrayObject.realm {
            realm.delete(arrayObject)
            XCTAssertTrue(array.invalidated)
        }
    }

    func testCount() {
        XCTAssertEqual(Int(0), array.count)

        array.append(str1)
        XCTAssertEqual(Int(1), array.count)

        array.append(str2)
        XCTAssertEqual(Int(2), array.count)
    }

    func testIndexOfObject() {
        XCTAssertNil(array.indexOf(str1))
        XCTAssertNil(array.indexOf(str2))

        array.append(str1)
        XCTAssertEqual(Int(0), array.indexOf(str1)!)
        XCTAssertNil(array.indexOf(str2))

        array.append(str2)
        XCTAssertEqual(Int(0), array.indexOf(str1)!)
        XCTAssertEqual(Int(1), array.indexOf(str2)!)
    }

    func testIndexOfPredicate() {
        let pred1 = NSPredicate(format: "stringCol = '1'")
        let pred2 = NSPredicate(format: "stringCol = '2'")

        XCTAssertNil(array.indexOf(pred1))
        XCTAssertNil(array.indexOf(pred2))

        array.append(str1)
        XCTAssertEqual(Int(0), array.indexOf(pred1)!)
        XCTAssertNil(array.indexOf(pred2))

        array.append(str2)
        XCTAssertEqual(Int(0), array.indexOf(pred1)!)
        XCTAssertEqual(Int(1), array.indexOf(pred2)!)
    }

    func testIndexOfFormat() {
        XCTAssertNil(array.indexOf("stringCol = %@", "1"))
        XCTAssertNil(array.indexOf("stringCol = %@", "2"))

        array.append(str1)
        XCTAssertEqual(Int(0), array.indexOf("stringCol = %@", "1")!)
        XCTAssertNil(array.indexOf("stringCol = %@", "2"))

        array.append(str2)
        XCTAssertEqual(Int(0), array.indexOf("stringCol = %@", "1")!)
        XCTAssertEqual(Int(1), array.indexOf("stringCol = %@", "2")!)
    }

    func testSubscript() {
        array.append(str1)
        XCTAssertEqual(str1, array[0])

        array[0] = str2
        XCTAssertEqual(str2, array[0])
        assertThrows(self.array[-1] = self.str2)

        array.append(str1)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str1, array[1])

        assertThrows(self.array[200])
        assertThrows(self.array[-200])
    }

    func testFirst() {
        XCTAssertNil(array.first)

        array.append(str1)
        XCTAssertNotNil(array.first)
        XCTAssertEqual(str1, array.first!)

        array.append(str2)
        XCTAssertEqual(str1, array.first!)
    }

    func testLast() {
        XCTAssertNil(array.last)

        array.append(str1)
        XCTAssertNotNil(array.last)
        XCTAssertEqual(str1, array.last!)

        array.append(str2)
        XCTAssertEqual(str2, array.last!)
    }

    func testValueForKey() {
        let expected = map(array) { $0.stringCol }
        let actual = array.valueForKey("stringCol") as! [String]!
        XCTAssertEqual(expected, actual)

        XCTAssertEqual(map(array) { $0 }, array.valueForKey("self") as! [SwiftStringObject])
    }

    func testSetValueForKey() {
        array.setValue("hi there!", forKey: "stringCol")
        let expected = map(array!) { _ in "hi there!" }
        let actual = map(array) { $0.stringCol }
        XCTAssertEqual(expected, actual)
    }

    func testFilterFormat() {
        XCTAssertEqual(Int(0), array.filter("stringCol = '1'").count)
        XCTAssertEqual(Int(0), array.filter("stringCol = '2'").count)

        array.append(str1)
        XCTAssertEqual(Int(1), array.filter("stringCol = '1'").count)
        XCTAssertEqual(Int(0), array.filter("stringCol = '2'").count)

        array.append(str2)
        XCTAssertEqual(Int(1), array.filter("stringCol = '1'").count)
        XCTAssertEqual(Int(1), array.filter("stringCol = '2'").count)
    }

    func testFilterList() {
        let innerArray = createArrayWithLinks()

        if let realm = innerArray.realm {
            realm.beginWrite()
            innerArray.array.append(SwiftObject())
            let outerArray = SwiftDoubleListOfSwiftObject()
            realm.add(outerArray)
            outerArray.array.append(innerArray)
            realm.commitWrite()
            XCTAssertEqual(Int(1), outerArray.array.filter("ANY array IN %@", innerArray.array).count)
        }
    }

    func testFilterResults() {
        let arrayObject = createArrayWithLinks()

        if let realm = arrayObject.realm {
            realm.beginWrite()
            arrayObject.array.append(SwiftObject())
            let subArray = arrayObject.array
            realm.commitWrite()
            XCTAssertEqual(Int(1), realm.objects(SwiftListOfSwiftObject).filter("ANY array IN %@", subArray).count)
        }
    }

    func testFilterPredicate() {
        let pred1 = NSPredicate(format: "stringCol = '1'")
        let pred2 = NSPredicate(format: "stringCol = '2'")

        XCTAssertEqual(Int(0), array.filter(pred1).count)
        XCTAssertEqual(Int(0), array.filter(pred2).count)

        array.append(str1)
        XCTAssertEqual(Int(1), array.filter(pred1).count)
        XCTAssertEqual(Int(0), array.filter(pred2).count)

        array.append(str2)
        XCTAssertEqual(Int(1), array.filter(pred1).count)
        XCTAssertEqual(Int(1), array.filter(pred2).count)
    }

    func testSortWithProperty() {
        array.extend([str1, str2])

        var sorted = array.sorted("stringCol", ascending: true)
        XCTAssertEqual("1", sorted[0].stringCol)
        XCTAssertEqual("2", sorted[1].stringCol)

        sorted = array.sorted("stringCol", ascending: false)
        XCTAssertEqual("2", sorted[0].stringCol)
        XCTAssertEqual("1", sorted[1].stringCol)

        assertThrows(self.array.sorted("noSuchCol"), named: "Invalid sort property")
    }

    func testSortWithDescriptors() {
        let object = realmWithTestPath().create(SwiftAggregateObjectList.self, value: [[]])
        let array = object.list

        let obj1 = SwiftAggregateObject()
        obj1.intCol = 1
        obj1.floatCol = 1.1
        obj1.doubleCol = 1.11
        obj1.dateCol = NSDate(timeIntervalSince1970: 1)
        obj1.boolCol = false

        let obj2 = SwiftAggregateObject()
        obj2.intCol = 2
        obj2.floatCol = 2.2
        obj2.doubleCol = 2.22
        obj2.dateCol = NSDate(timeIntervalSince1970: 2)
        obj2.boolCol = false

        let obj3 = SwiftAggregateObject()
        obj3.intCol = 3
        obj3.floatCol = 2.2
        obj3.doubleCol = 2.22
        obj3.dateCol = NSDate(timeIntervalSince1970: 2)
        obj3.boolCol = false

        realmWithTestPath().add([obj1, obj2, obj3])
        array.extend([obj1, obj2, obj3])

        var sorted = array.sorted([SortDescriptor(property: "intCol", ascending: true)])
        XCTAssertEqual(1, sorted[0].intCol)
        XCTAssertEqual(2, sorted[1].intCol)

        sorted = array.sorted([SortDescriptor(property: "doubleCol", ascending: false), SortDescriptor(property: "intCol", ascending: false)])
        XCTAssertEqual(2.22, sorted[0].doubleCol)
        XCTAssertEqual(3, sorted[0].intCol)
        XCTAssertEqual(2.22, sorted[1].doubleCol)
        XCTAssertEqual(2, sorted[1].intCol)
        XCTAssertEqual(1.11, sorted[2].doubleCol)

        assertThrows(array.sorted([SortDescriptor(property: "noSuchCol", ascending: true)]),
            named: "Invalid sort property")
    }

    func testFastEnumeration() {
        array.extend([str1, str2, str1])
        var str = ""
        for obj in array {
            str += obj.stringCol
        }

        XCTAssertEqual(str, "121")
    }

    func testFastEnumerationWithMutation() {
        array.extend([str1, str2, str1, str2, str1, str2, str1, str2, str1,
            str2, str1, str2, str1, str2, str1, str2, str1, str2, str1, str2])
        var str = ""
        for obj in array {
            str += obj.stringCol
            array.extend([str1])
        }

        XCTAssertEqual(str, "12121212121212121212")
    }

    func testAppendObject() {
        for str in [str1, str2, str1] {
            array.append(str)
        }
        XCTAssertEqual(Int(3), array.count)
        XCTAssertEqual(str1, array[0])
        XCTAssertEqual(str2, array[1])
        XCTAssertEqual(str1, array[2])
    }

    func testAppendArray() {
        array.extend([str1, str2, str1])
        XCTAssertEqual(Int(3), array.count)
        XCTAssertEqual(str1, array[0])
        XCTAssertEqual(str2, array[1])
        XCTAssertEqual(str1, array[2])
    }

    func testAppendResults() {
        array.extend(realmWithTestPath().objects(SwiftStringObject))
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str1, array[0])
        XCTAssertEqual(str2, array[1])
    }

    func testInsert() {
        XCTAssertEqual(Int(0), array.count)

        array.insert(str1, atIndex: 0)
        XCTAssertEqual(Int(1), array.count)
        XCTAssertEqual(str1, array[0])

        array.insert(str2, atIndex: 0)
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str1, array[1])

        assertThrows(self.array.insert(self.str2, atIndex: 200))
        assertThrows(self.array.insert(self.str2, atIndex: -200))
    }

    func testRemoveAtIndex() {
        array.extend([str1, str2, str1])

        array.removeAtIndex(1)
        XCTAssertEqual(str1, array[0])
        XCTAssertEqual(str1, array[1])

        assertThrows(self.array.removeAtIndex(200))
        assertThrows(self.array.removeAtIndex(-200))
    }

    func testRemoveLast() {
        array.extend([str1, str2])

        array.removeLast()
        XCTAssertEqual(Int(1), array.count)
        XCTAssertEqual(str1, array[0])

        array.removeLast()
        XCTAssertEqual(Int(0), array.count)

        array.removeLast() // should be a no-op
        XCTAssertEqual(Int(0), array.count)
    }

    func testRemoveAll() {
        array.extend([str1, str2])

        array.removeAll()
        XCTAssertEqual(Int(0), array.count)

        array.removeAll() // should be a no-op
        XCTAssertEqual(Int(0), array.count)
    }

    func testReplace() {
        array.extend([str1, str1])

        array.replace(0, object: str2)
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str1, array[1])

        array.replace(1, object: str2)
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str2, array[1])

        assertThrows(self.array.replace(200, object: self.str2))
        assertThrows(self.array.replace(-200, object: self.str2))
    }

    func testMove()  {
        array.extend([str1, str2])

        array.move(from: 1, to: 0)

        XCTAssertEqual(array[0].stringCol, "2")
        XCTAssertEqual(array[1].stringCol, "1")

        array.move(from: 0, to: 1)

        XCTAssertEqual(array[0].stringCol, "1")
        XCTAssertEqual(array[1].stringCol, "2")

        array.move(from: 0, to: 0)

        XCTAssertEqual(array[0].stringCol, "1")
        XCTAssertEqual(array[1].stringCol, "2")

        assertThrows(self.array.move(from: 0, to: 2))
        assertThrows(self.array.move(from: 2, to: 0))
    }

    func testSwap() {
        array.extend([str1, str2])

        array.swap(0, 1)
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str1, array[1])

        array.swap(1, 1)
        XCTAssertEqual(Int(2), array.count)
        XCTAssertEqual(str2, array[0])
        XCTAssertEqual(str1, array[1])

        assertThrows(self.array.swap(-1, 0))
        assertThrows(self.array.swap(0, -1))
        assertThrows(self.array.swap(1000, 0))
        assertThrows(self.array.swap(0, 1000))
    }

    func testChangesArePersisted() {
        if let realm = array.realm {
            array.extend([str1, str2])

            let otherArray = realm.objects(SwiftArrayPropertyObject).first!.array
            XCTAssertEqual(Int(2), otherArray.count)
        }
    }

    func testPopulateEmptyArray() {
        XCTAssertEqual(array.count, 0, "Should start with no array elements.")

        let obj = SwiftStringObject()
        obj.stringCol = "a"
        array.append(obj)
        array.append(realmWithTestPath().create(SwiftStringObject.self, value: ["b"]))
        array.append(obj)

        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array[0].stringCol, "a")
        XCTAssertEqual(array[1].stringCol, "b")
        XCTAssertEqual(array[2].stringCol, "a")

        // Make sure we can enumerate
        for obj in array {
            XCTAssertTrue(count(obj.description) > 0, "Object should have description")
        }
    }

    func testEnumeratingListWithListProperties() {
        let arrayObject = createArrayWithLinks()

        arrayObject.realm?.beginWrite()
        for _ in 0..<10 {
            arrayObject.array.append(SwiftObject())
        }
        arrayObject.realm?.commitWrite()

        XCTAssertEqual(10, arrayObject.array.count)

        for object in arrayObject.array {
            XCTAssertEqual(123, object.intCol)
            XCTAssertEqual(false, object.objectCol.boolCol)
            XCTAssertEqual(0, object.arrayCol.count)
        }
    }
}

class ListStandaloneTests: ListTests {
    override func createArray() -> SwiftArrayPropertyObject {
        let array = SwiftArrayPropertyObject()
        XCTAssertNil(array.realm)
        return array
    }

    override func createArrayWithLinks() -> SwiftListOfSwiftObject {
        let array = SwiftListOfSwiftObject()
        XCTAssertNil(array.realm)
        return array
    }

    // MARK: Things not implemented in standalone

    override func testSortWithProperty() {
        assertThrows(self.array.sorted("stringCol", ascending: true))
        assertThrows(self.array.sorted("noSuchCol"))
    }

    override func testSortWithDescriptors() {
        assertThrows(self.array.sorted([SortDescriptor(property: "intCol", ascending: true)]))
        assertThrows(self.array.sorted([SortDescriptor(property: "noSuchCol", ascending: true)]))
    }

    override func testFilterFormat() {
        assertThrows(self.array.filter("stringCol = '1'"))
        assertThrows(self.array.filter("noSuchCol = '1'"))
    }

    override func testFilterPredicate() {
        let pred1 = NSPredicate(format: "stringCol = '1'")
        let pred2 = NSPredicate(format: "noSuchCol = '2'")

        assertThrows(self.array.filter(pred1))
        assertThrows(self.array.filter(pred2))
    }
}

class ListNewlyAddedTests: ListTests {
    override func createArray() -> SwiftArrayPropertyObject {
        let array = SwiftArrayPropertyObject()
        array.name = "name"
        let realm = realmWithTestPath()
        realm.write { realm.add(array) }

        XCTAssertNotNil(array.realm)
        return array
    }

    override func createArrayWithLinks() -> SwiftListOfSwiftObject {
        let array = SwiftListOfSwiftObject()
        let realm = Realm()
        realm.write { realm.add(array) }

        XCTAssertNotNil(array.realm)
        return array
    }
}

class ListNewlyCreatedTests: ListTests {
    override func createArray() -> SwiftArrayPropertyObject {
        let realm = realmWithTestPath()
        realm.beginWrite()
        let array = realm.create(SwiftArrayPropertyObject.self, value: ["name", [], []])
        realm.commitWrite()

        XCTAssertNotNil(array.realm)
        return array
    }

    override func createArrayWithLinks() -> SwiftListOfSwiftObject {
        let realm = Realm()
        realm.beginWrite()
        let array = realm.create(SwiftListOfSwiftObject)
        realm.commitWrite()

        XCTAssertNotNil(array.realm)
        return array
    }
}

class ListRetrievedTests: ListTests {
    override func createArray() -> SwiftArrayPropertyObject {
        let realm = realmWithTestPath()
        realm.beginWrite()
        realm.create(SwiftArrayPropertyObject.self, value: ["name", [], []])
        realm.commitWrite()
        let array = realm.objects(SwiftArrayPropertyObject).first!

        XCTAssertNotNil(array.realm)
        return array
    }

    override func createArrayWithLinks() -> SwiftListOfSwiftObject {
        let realm = Realm()
        realm.beginWrite()
        realm.create(SwiftListOfSwiftObject)
        realm.commitWrite()
        let array = realm.objects(SwiftListOfSwiftObject).first!

        XCTAssertNotNil(array.realm)
        return array
    }
}
