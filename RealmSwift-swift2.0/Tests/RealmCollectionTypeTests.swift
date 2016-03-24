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

class SwiftAggregateObjectList: Object {
    let list = List<SwiftAggregateObject>()
}

class RealmCollectionTypeTests: TestCase {
    var str1: SwiftStringObject!
    var str2: SwiftStringObject!
    var collection: AnyRealmCollection<SwiftStringObject>!

    func getCollection() -> AnyRealmCollection<SwiftStringObject> {
        fatalError("abstract")
    }

    func getAggregateableCollection() -> AnyRealmCollection<SwiftAggregateObject> {
        fatalError("abstract")
    }

    func makeAggregateableObjects() -> [SwiftAggregateObject] {
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
        return [obj1, obj2, obj3]
    }

    override func setUp() {
        super.setUp()

        str1 = SwiftStringObject()
        str1.stringCol = "1"
        str2 = SwiftStringObject()
        str2.stringCol = "2"

        let realm = realmWithTestPath()
        realm.beginWrite()
        realm.add(str1)
        realm.add(str2)

        collection = AnyRealmCollection(getCollection())
    }

    override func tearDown() {
        realmWithTestPath().cancelWrite()

        str1 = nil
        str2 = nil
        collection = nil

        super.tearDown()
    }

    override class func defaultTestSuite() -> XCTestSuite {
        // Don't run tests for the base class
        if isEqual(RealmCollectionTypeTests) {
            return XCTestSuite(name: "empty")
        }
        return super.defaultTestSuite()
    }

    func testRealm() {
        XCTAssertEqual(collection.realm!.path, realmWithTestPath().path)
    }

    func testDescription() {
        // swiftlint:disable:next line_length
        XCTAssertEqual(collection.description, "Results<SwiftStringObject> (\n\t[0] SwiftStringObject {\n\t\tstringCol = 1;\n\t},\n\t[1] SwiftStringObject {\n\t\tstringCol = 2;\n\t}\n)")
    }

    func testCount() {
        XCTAssertEqual(2, collection.count)
        XCTAssertEqual(1, collection.filter("stringCol = '1'").count)
        XCTAssertEqual(1, collection.filter("stringCol = '2'").count)
        XCTAssertEqual(0, collection.filter("stringCol = '0'").count)
    }

    func testIndexOfObject() {
        XCTAssertEqual(0, collection.indexOf(str1)!)
        XCTAssertEqual(1, collection.indexOf(str2)!)

        let str1Only = collection.filter("stringCol = '1'")
        XCTAssertEqual(0, str1Only.indexOf(str1)!)
        XCTAssertNil(str1Only.indexOf(str2))
    }

    func testIndexOfPredicate() {
        let pred1 = NSPredicate(format: "stringCol = '1'")
        let pred2 = NSPredicate(format: "stringCol = '2'")
        let pred3 = NSPredicate(format: "stringCol = '3'")

        XCTAssertEqual(0, collection.indexOf(pred1)!)
        XCTAssertEqual(1, collection.indexOf(pred2)!)
        XCTAssertNil(collection.indexOf(pred3))
    }

    func testIndexOfFormat() {
        XCTAssertEqual(0, collection.indexOf("stringCol = '1'")!)
        XCTAssertEqual(0, collection.indexOf("stringCol = %@", "1")!)
        XCTAssertEqual(1, collection.indexOf("stringCol = %@", "2")!)
        XCTAssertNil(collection.indexOf("stringCol = %@", "3"))
    }

    func testSubscript() {
        XCTAssertEqual(str1, collection[0])
        XCTAssertEqual(str2, collection[1])

        assertThrows(self.collection[200])
        assertThrows(self.collection[-200])
    }

    func testFirst() {
        XCTAssertEqual(str1, collection.first!)
        XCTAssertEqual(str2, collection.filter("stringCol = '2'").first!)
        XCTAssertNil(collection.filter("stringCol = '3'").first)
    }

    func testLast() {
        XCTAssertEqual(str2, collection.last!)
        XCTAssertEqual(str2, collection.filter("stringCol = '2'").last!)
        XCTAssertNil(collection.filter("stringCol = '3'").last)
    }

    func testValueForKey() {
        let expected = collection.map { $0.stringCol }
        let actual = collection.valueForKey("stringCol") as! [String]!
        XCTAssertEqual(expected, actual)

        XCTAssertEqual(collection.map { $0 }, collection.valueForKey("self") as! [SwiftStringObject])
    }

    func testSetValueForKey() {
        collection.setValue("hi there!", forKey: "stringCol")
        let expected = (0..<collection.count).map { _ in "hi there!" }
        let actual = collection.map { $0.stringCol }
        XCTAssertEqual(expected, actual)
    }

    func testFilterFormat() {
        XCTAssertEqual(1, collection.filter("stringCol = '1'").count)
        XCTAssertEqual(1, collection.filter("stringCol = %@", "1").count)
        XCTAssertEqual(1, collection.filter("stringCol = %@", "2").count)
        XCTAssertEqual(0, collection.filter("stringCol = %@", "3").count)
    }

    func testFilterList() {
        let outerArray = SwiftDoubleListOfSwiftObject()
        let realm = realmWithTestPath()
        let innerArray = SwiftListOfSwiftObject()
        innerArray.array.append(SwiftObject())
        outerArray.array.append(innerArray)
        realm.add(outerArray)
        XCTAssertEqual(1, outerArray.array.filter("ANY array IN %@", realm.objects(SwiftObject)).count)
    }

    func testFilterResults() {
        let array = SwiftListOfSwiftObject()
        let realm = realmWithTestPath()
        array.array.append(SwiftObject())
        realm.add(array)
        XCTAssertEqual(1,
            realm.objects(SwiftListOfSwiftObject).filter("ANY array IN %@", realm.objects(SwiftObject)).count)
    }

    func testFilterPredicate() {
        let pred1 = NSPredicate(format: "stringCol = '1'")
        let pred2 = NSPredicate(format: "stringCol = '2'")
        let pred3 = NSPredicate(format: "stringCol = '3'")

        XCTAssertEqual(1, collection.filter(pred1).count)
        XCTAssertEqual(1, collection.filter(pred2).count)
        XCTAssertEqual(0, collection.filter(pred3).count)
    }

    func testSortWithProperty() {
        var sorted = collection.sorted("stringCol", ascending: true)
        XCTAssertEqual("1", sorted[0].stringCol)
        XCTAssertEqual("2", sorted[1].stringCol)

        sorted = collection.sorted("stringCol", ascending: false)
        XCTAssertEqual("2", sorted[0].stringCol)
        XCTAssertEqual("1", sorted[1].stringCol)

        assertThrows(self.collection.sorted("noSuchCol", ascending: true), named: "Invalid sort property")
    }

    func testSortWithDescriptor() {
        let collection = getAggregateableCollection()

        var sorted = collection.sorted([SortDescriptor(property: "intCol", ascending: true)])
        XCTAssertEqual(1, sorted[0].intCol)
        XCTAssertEqual(2, sorted[1].intCol)

        sorted = collection.sorted([SortDescriptor(property: "doubleCol", ascending: false),
            SortDescriptor(property: "intCol", ascending: false)])
        XCTAssertEqual(2.22, sorted[0].doubleCol)
        XCTAssertEqual(3, sorted[0].intCol)
        XCTAssertEqual(2.22, sorted[1].doubleCol)
        XCTAssertEqual(2, sorted[1].intCol)
        XCTAssertEqual(1.11, sorted[2].doubleCol)

        assertThrows(collection.sorted([SortDescriptor(property: "noSuchCol")]), named: "Invalid sort property")
    }

    func testMin() {
        let collection = getAggregateableCollection()
        XCTAssertEqual(1, collection.min("intCol") as Int!)
        XCTAssertEqual(Float(1.1), collection.min("floatCol") as Float!)
        XCTAssertEqual(Double(1.11), collection.min("doubleCol") as Double!)
        XCTAssertEqual(NSDate(timeIntervalSince1970: 1), collection.min("dateCol") as NSDate!)

        assertThrows(collection.min("noSuchCol") as Float!, named: "Invalid property name")
    }

    func testMax() {
        let collection = getAggregateableCollection()
        XCTAssertEqual(3, collection.max("intCol") as Int!)
        XCTAssertEqual(Float(2.2), collection.max("floatCol") as Float!)
        XCTAssertEqual(Double(2.22), collection.max("doubleCol") as Double!)
        XCTAssertEqual(NSDate(timeIntervalSince1970: 2), collection.max("dateCol") as NSDate!)

        assertThrows(collection.max("noSuchCol") as Float!, named: "Invalid property name")
    }

    func testSum() {
        let collection = getAggregateableCollection()
        XCTAssertEqual(6, collection.sum("intCol") as Int)
        XCTAssertEqualWithAccuracy(Float(5.5), collection.sum("floatCol") as Float, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(Double(5.55), collection.sum("doubleCol") as Double, accuracy: 0.001)

        assertThrows(collection.sum("noSuchCol") as Float, named: "Invalid property name")
    }

    func testAverage() {
        let collection = getAggregateableCollection()
        XCTAssertEqual(2, collection.average("intCol") as Int!)
        XCTAssertEqualWithAccuracy(Float(1.8333), collection.average("floatCol") as Float!, accuracy: 0.001)
        XCTAssertEqualWithAccuracy(Double(1.85), collection.average("doubleCol") as Double!, accuracy: 0.001)

        assertThrows(collection.average("noSuchCol")! as Float, named: "Invalid property name")
    }

    func testFastEnumeration() {
        var str = ""
        for obj in collection {
            str += obj.stringCol
        }

        XCTAssertEqual(str, "12")
    }

    func testFastEnumerationWithMutation() {
        let realm = realmWithTestPath()
        for obj in collection {
            realm.delete(obj)
        }
        XCTAssertEqual(0, collection.count)
    }

    func testAssignListProperty() {
        // no way to make RealmCollectionType conform to NSFastEnumeration
        // so test the concrete collections directly.
        fatalError("abstract")
    }

    func testArrayAggregateWithSwiftObjectDoesntThrow() {
        let collection = getAggregateableCollection()

        // Should not throw a type error.
        collection.filter("ANY stringListCol == %@", SwiftStringObject())
    }

    func testAddNotificationBlock() {
        let realm = realmWithTestPath()
        try! realm.commitWrite()

        let expectation = expectationWithDescription("")
        let token = collection.addNotificationBlock { c, error in
            XCTAssertNil(error)
            XCTAssertNotNil(c)
            XCTAssertEqual(c!.count, 2)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        token.stop()
        realm.beginWrite()
    }

    func testValueForKeyPath() {
        XCTAssertEqual(["1", "2"], self.collection.valueForKeyPath("@unionOfObjects.stringCol") as! NSArray?)

        let collection = getAggregateableCollection()
        XCTAssertEqual(3, collection.valueForKeyPath("@count")?.longValue)
        XCTAssertEqual(3, collection.valueForKeyPath("@max.intCol")?.longValue)
        XCTAssertEqual(1, collection.valueForKeyPath("@min.intCol")?.longValue)
        XCTAssertEqual(6, collection.valueForKeyPath("@sum.intCol")?.longValue)
        XCTAssertEqual(2.0, collection.valueForKeyPath("@avg.intCol")?.doubleValue)
    }
}

// MARK: Results

class ResultsTests: RealmCollectionTypeTests {
    override class func defaultTestSuite() -> XCTestSuite {
        // Don't run tests for the base class
        if isEqual(ResultsTests) {
            return XCTestSuite(name: "empty")
        }
        return super.defaultTestSuite()
    }

    func collectionBase() -> Results<SwiftStringObject> {
        fatalError("abstract")
    }

    override func getCollection() -> AnyRealmCollection<SwiftStringObject> {
        return AnyRealmCollection(collectionBase())
    }

    override func testAssignListProperty() {
        let array = SwiftArrayPropertyObject()
        realmWithTestPath().add(array)
        array["array"] = collectionBase()
    }

    func addObjectToResults() {
        let realm = realmWithTestPath()
        try! realm.write {
            realm.create(SwiftStringObject.self, value: ["a"])
        }
    }

    func testNotificationBlockUpdating() {
        let collection = collectionBase()

        let realm = realmWithTestPath()
        try! realm.commitWrite()

        var expectation = expectationWithDescription("")
        var calls = 0
        let token = collection.addNotificationBlock { results, error in
            XCTAssertNil(error)
            XCTAssertNotNil(results)

            XCTAssertEqual(results!.count, calls + 2)
            XCTAssertEqual(results, collection)
            calls += 1

            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        expectation = expectationWithDescription("")
        addObjectToResults()
        waitForExpectationsWithTimeout(1, handler: nil)

        token.stop()
        realm.beginWrite()
    }
}

class ResultsWithCustomInitializerTest: TestCase {
    func testValueForKey() {
        let realm = realmWithTestPath()
        try! realm.write {
            realm.add(SwiftCustomInitializerObject(stringVal: "A"))
        }

        let collection = realm.objects(SwiftCustomInitializerObject)
        let expected = collection.map { $0.stringCol }
        let actual = collection.valueForKey("stringCol") as! [String]!
        XCTAssertEqual(expected, actual)

        XCTAssertEqual(collection.map { $0 }, collection.valueForKey("self") as! [SwiftStringObject])
    }
}

class ResultsFromTableTests: ResultsTests {
    override func collectionBase() -> Results<SwiftStringObject> {
        return realmWithTestPath().objects(SwiftStringObject)
    }

    override func getAggregateableCollection() -> AnyRealmCollection<SwiftAggregateObject> {
        makeAggregateableObjects()
        return AnyRealmCollection(realmWithTestPath().objects(SwiftAggregateObject))
    }
}

class ResultsFromTableViewTests: ResultsTests {
    override func collectionBase() -> Results<SwiftStringObject> {
        return realmWithTestPath().objects(SwiftStringObject).filter("stringCol != ''")
    }

    override func getAggregateableCollection() -> AnyRealmCollection<SwiftAggregateObject> {
        makeAggregateableObjects()
        return AnyRealmCollection(realmWithTestPath().objects(SwiftAggregateObject).filter("trueCol == true"))
    }
}

class ResultsFromLinkViewTests: ResultsTests {
    override func collectionBase() -> Results<SwiftStringObject> {
        let array = realmWithTestPath().create(SwiftArrayPropertyObject.self, value: ["", [str1, str2], []])
        return array.array.filter(NSPredicate(value: true))
    }

    override func getAggregateableCollection() -> AnyRealmCollection<SwiftAggregateObject> {
        let list = SwiftAggregateObjectList()
        realmWithTestPath().add(list)
        list.list.appendContentsOf(makeAggregateableObjects())
        return AnyRealmCollection(list.list.filter(NSPredicate(value: true)))
    }

    override func addObjectToResults() {
        let realm = realmWithTestPath()
        try! realm.write {
            let array = realm.objects(SwiftArrayPropertyObject).last!
            array.array.append(realm.create(SwiftStringObject.self, value: ["a"]))
        }
    }
}

// MARK: List

class ListRealmCollectionTypeTests: RealmCollectionTypeTests {
    override class func defaultTestSuite() -> XCTestSuite {
        // Don't run tests for the base class
        if isEqual(ListRealmCollectionTypeTests) {
            return XCTestSuite(name: "empty")
        }
        return super.defaultTestSuite()
    }

    func collectionBase() -> List<SwiftStringObject> {
        fatalError("abstract")
    }

    override func getCollection() -> AnyRealmCollection<SwiftStringObject> {
        return AnyRealmCollection(collectionBase())
    }

    override func testAssignListProperty() {
        let array = SwiftArrayPropertyObject()
        realmWithTestPath().add(array)
        array["array"] = collectionBase()
    }

    override func testDescription() {
        // swiftlint:disable:next line_length
        XCTAssertEqual(collection.description, "List<SwiftStringObject> (\n\t[0] SwiftStringObject {\n\t\tstringCol = 1;\n\t},\n\t[1] SwiftStringObject {\n\t\tstringCol = 2;\n\t}\n)")
    }

    func testAddNotificationBlockDirect() {
        let collection = collectionBase()

        let realm = realmWithTestPath()
        try! realm.commitWrite()

        let expectation = expectationWithDescription("")
        let token = collection.addNotificationBlock { list in
            XCTAssertEqual(list.count, 2)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1, handler: nil)

        token.stop()
        realm.beginWrite()
    }
}

class ListStandaloneRealmCollectionTypeTests: ListRealmCollectionTypeTests {
    override func collectionBase() -> List<SwiftStringObject> {
        return SwiftArrayPropertyObject(value: ["", [str1, str2], []]).array
    }

    override func getAggregateableCollection() -> AnyRealmCollection<SwiftAggregateObject> {
        return AnyRealmCollection(SwiftAggregateObjectList(value: [makeAggregateableObjects()]).list)
    }

    override func testRealm() {
        XCTAssertNil(collection.realm)
    }

    override func testCount() {
        XCTAssertEqual(2, collection.count)
    }

    override func testIndexOfObject() {
        XCTAssertEqual(0, collection.indexOf(str1)!)
        XCTAssertEqual(1, collection.indexOf(str2)!)
    }

    override func testSortWithDescriptor() {
        let collection = getAggregateableCollection()
        assertThrows(collection.sorted([SortDescriptor(property: "intCol", ascending: true)]))
        assertThrows(collection.sorted([SortDescriptor(property: "doubleCol", ascending: false),
            SortDescriptor(property: "intCol", ascending: false)]))
    }

    override func testFastEnumerationWithMutation() {
        // No standalone removal interface provided on RealmCollectionType
    }

    override func testFirst() {
        XCTAssertEqual(str1, collection.first!)
    }

    override func testLast() {
        XCTAssertEqual(str2, collection.last!)
    }

    // MARK: Things not implemented in standalone

    override func testSortWithProperty() {
        assertThrows(self.collection.sorted("stringCol", ascending: true))
        assertThrows(self.collection.sorted("noSuchCol", ascending: true))
    }

    override func testFilterFormat() {
        assertThrows(self.collection.filter("stringCol = '1'"))
        assertThrows(self.collection.filter("noSuchCol = '1'"))
    }

    override func testFilterPredicate() {
        let pred1 = NSPredicate(format: "stringCol = '1'")
        let pred2 = NSPredicate(format: "noSuchCol = '2'")

        assertThrows(self.collection.filter(pred1))
        assertThrows(self.collection.filter(pred2))
    }

    override func testArrayAggregateWithSwiftObjectDoesntThrow() {
        assertThrows(self.collection.filter("ANY stringListCol == %@", SwiftStringObject()))
    }

    override func testMin() {
        assertThrows(self.collection.min("intCol") as Int!)
        assertThrows(self.collection.min("floatCol") as Float!)
        assertThrows(self.collection.min("doubleCol") as Double!)
        assertThrows(self.collection.min("dateCol") as NSDate!)
    }

    override func testMax() {
        assertThrows(self.collection.max("intCol") as Int!)
        assertThrows(self.collection.max("floatCol") as Float!)
        assertThrows(self.collection.max("doubleCol") as Double!)
        assertThrows(self.collection.max("dateCol") as NSDate!)
    }

    override func testSum() {
        assertThrows(self.collection.sum("intCol") as Int)
        assertThrows(self.collection.sum("floatCol") as Float)
        assertThrows(self.collection.sum("doubleCol") as Double)
    }

    override func testAverage() {
        assertThrows(self.collection.average("intCol") as Int!)
        assertThrows(self.collection.average("floatCol") as Float!)
        assertThrows(self.collection.average("doubleCol") as Double!)
    }

    override func testAddNotificationBlock() {
        let realm = realmWithTestPath()
        try! realm.commitWrite()
        assertThrows(self.collection.addNotificationBlock { _, _ in })
        realm.beginWrite()
    }

    override func testAddNotificationBlockDirect() {
        let collection = collectionBase()
        let realm = realmWithTestPath()
        try! realm.commitWrite()

        assertThrows(collection.addNotificationBlock { _ in })
        realm.beginWrite()
    }
}

class ListNewlyAddedRealmCollectionTypeTests: ListRealmCollectionTypeTests {
    override func collectionBase() -> List<SwiftStringObject> {
        let array = SwiftArrayPropertyObject(value: ["", [str1, str2], []])
        realmWithTestPath().add(array)
        return array.array
    }

    override func getAggregateableCollection() -> AnyRealmCollection<SwiftAggregateObject> {
        let list = SwiftAggregateObjectList(value: [makeAggregateableObjects()])
        realmWithTestPath().add(list)
        return AnyRealmCollection(list.list)
    }
}

class ListNewlyCreatedRealmCollectionTypeTests: ListRealmCollectionTypeTests {
    override func collectionBase() -> List<SwiftStringObject> {
        let array = realmWithTestPath().create(SwiftArrayPropertyObject.self, value: ["", [str1, str2], []])
        return array.array
    }

    override func getAggregateableCollection() -> AnyRealmCollection<SwiftAggregateObject> {
        let list = realmWithTestPath().create(SwiftAggregateObjectList.self, value: [makeAggregateableObjects()])
        return AnyRealmCollection(list.list)
    }
}

class ListRetrievedRealmCollectionTypeTests: ListRealmCollectionTypeTests {
    override func collectionBase() -> List<SwiftStringObject> {
        realmWithTestPath().create(SwiftArrayPropertyObject.self, value: ["", [str1, str2], []])
        let array = realmWithTestPath().objects(SwiftArrayPropertyObject).first!
        return array.array
    }

    override func getAggregateableCollection() -> AnyRealmCollection<SwiftAggregateObject> {
        realmWithTestPath().create(SwiftAggregateObjectList.self, value: [makeAggregateableObjects()])
        let list = realmWithTestPath().objects(SwiftAggregateObjectList.self).first!
        return AnyRealmCollection(list.list)
    }
}
