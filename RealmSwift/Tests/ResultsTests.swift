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

class ResultsTests: TestCase {
    var str1: SwiftStringObject!
    var str2: SwiftStringObject!
    var results: Results<SwiftStringObject>!

    func getResults() -> Results<SwiftStringObject> {
        fatalError("abstract")
    }

    func getAggregateableResults() -> Results<SwiftAggregateObject> {
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

        realmWithTestPath().add([obj1, obj2])
        return [obj1, obj2]
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

        results = getResults()
    }

    override func tearDown() {
        realmWithTestPath().commitWrite()

        str1 = nil
        str2 = nil
        results = nil

        super.tearDown()
    }

    override class func defaultTestSuite() -> XCTestSuite! {
        // Don't run tests for the base class
        if self.isEqual(ResultsTests) {
            return nil
        }
        return super.defaultTestSuite()
    }

    func testRealm() {
        XCTAssertEqual(results.realm.path, realmWithTestPath().path)
    }

    func testDescription() {
        XCTAssertFalse(results.description.isEmpty)
    }

    func testCount() {
        XCTAssertEqual(Int(2), results.count)
        XCTAssertEqual(Int(1), results.filter("stringCol = '1'").count)
        XCTAssertEqual(Int(1), results.filter("stringCol = '2'").count)
        XCTAssertEqual(Int(0), results.filter("stringCol = '0'").count)
    }

    func testIndexOfObject() {
        XCTAssertEqual(Int(0), results.indexOf(str1)!)
        XCTAssertEqual(Int(1), results.indexOf(str2)!)

        let str1Only = results.filter("stringCol = '1'")
        XCTAssertEqual(Int(0), str1Only.indexOf(str1)!)
        XCTAssertNil(str1Only.indexOf(str2))
    }

    func testIndexOfPredicate() {
        let pred1 = NSPredicate(format: "stringCol = '1'")!
        let pred2 = NSPredicate(format: "stringCol = '2'")!
        let pred3 = NSPredicate(format: "stringCol = '3'")!

        XCTAssertEqual(Int(0), results.indexOf(pred1)!)
        XCTAssertEqual(Int(1), results.indexOf(pred2)!)
        XCTAssertNil(results.indexOf(pred3))
    }

    func testIndexOfFormat() {
        XCTAssertEqual(Int(0), results.indexOf("stringCol = %@", "1")!)
        XCTAssertEqual(Int(1), results.indexOf("stringCol = %@", "2")!)
        XCTAssertNil(results.indexOf("stringCol = %@", "3"))
    }

    func testSubscript() {
        XCTAssertEqual(str1, results[0])
        XCTAssertEqual(str2, results[1])
    }

    func testFirst() {
        XCTAssertEqual(str1, results.first!)
        XCTAssertEqual(str2, results.filter("stringCol = '2'").first!)
        XCTAssertNil(results.filter("stringCol = '3'").first)
    }

    func testLast() {
        XCTAssertEqual(str2, results.last!)
        XCTAssertEqual(str2, results.filter("stringCol = '2'").last!)
        XCTAssertNil(results.filter("stringCol = '3'").last)
    }

    func testFilterFormat() {
        XCTAssertEqual(Int(1), results.filter("stringCol = %@", "1").count)
        XCTAssertEqual(Int(1), results.filter("stringCol = %@", "2").count)
        XCTAssertEqual(Int(0), results.filter("stringCol = %@", "3").count)
    }

    func testFilterPredicate() {
        let pred1 = NSPredicate(format: "stringCol = '1'")!
        let pred2 = NSPredicate(format: "stringCol = '2'")!
        let pred3 = NSPredicate(format: "stringCol = '3'")!

        XCTAssertEqual(Int(1), results.filter(pred1).count)
        XCTAssertEqual(Int(1), results.filter(pred2).count)
        XCTAssertEqual(Int(0), results.filter(pred3).count)
    }

    func testSortWithProperty() {
        var sorted = results.sorted("stringCol", ascending: true)
        XCTAssertEqual("1", sorted[0].stringCol)
        XCTAssertEqual("2", sorted[1].stringCol)

        sorted = results.sorted("stringCol", ascending: false)
        XCTAssertEqual("2", sorted[0].stringCol)
        XCTAssertEqual("1", sorted[1].stringCol)
    }

    func testSortWithDescriptor() {
        var sorted = results.sorted([SortDescriptor(property: "stringCol", ascending: true)])
        XCTAssertEqual("1", sorted[0].stringCol)
        XCTAssertEqual("2", sorted[1].stringCol)

        sorted = results.sorted([SortDescriptor(property: "stringCol", ascending: false)])
        XCTAssertEqual("2", sorted[0].stringCol)
        XCTAssertEqual("1", sorted[1].stringCol)
    }

    func testMin() {
        let results = getAggregateableResults()
        XCTAssertEqual(1, results.min("intCol") as Int!)
        XCTAssertEqual(Float(1.1), results.min("floatCol") as Float!)
        XCTAssertEqual(Double(1.11), results.min("doubleCol") as Double!)
        XCTAssertEqual(NSDate(timeIntervalSince1970: 1), results.min("dateCol") as NSDate!)
    }

    func testMax() {
        let results = getAggregateableResults()
        XCTAssertEqual(2, results.max("intCol") as Int!)
        XCTAssertEqual(Float(2.2), results.max("floatCol") as Float!)
        XCTAssertEqual(Double(2.22), results.max("doubleCol") as Double!)
        XCTAssertEqual(NSDate(timeIntervalSince1970: 2), results.max("dateCol") as NSDate!)
    }

    func testSum() {
        let results = getAggregateableResults()
        XCTAssertEqual(Int(3), results.sum("intCol") as Int)
        XCTAssertEqualWithAccuracy(Float(3.3), results.sum("floatCol") as Float, 0.001)
        XCTAssertEqual(Double(3.33), results.sum("doubleCol") as Double)
    }

    func testAverage() {
        let results = getAggregateableResults()
        XCTAssertEqual(Int(1), results.average("intCol") as Int)
        XCTAssertEqualWithAccuracy(Float(1.65), results.average("floatCol") as Float, 0.001)
        XCTAssertEqual(Double(1.665), results.average("doubleCol") as Double)
    }

    func testFastEnumeration() {
        var str = ""
        for obj in results {
            str += obj.stringCol
        }

        XCTAssertEqual(str, "12")
    }
}

class ResultsFromTableTests: ResultsTests {
    override func getResults() -> Results<SwiftStringObject> {
        return realmWithTestPath().objects(SwiftStringObject)
    }

    override func getAggregateableResults() -> Results<SwiftAggregateObject> {
        makeAggregateableObjects()
        return realmWithTestPath().objects(SwiftAggregateObject)
    }
}

class ResultsFromTableViewTests: ResultsTests {
    override func getResults() -> Results<SwiftStringObject> {
        return realmWithTestPath().objects(SwiftStringObject)
    }

    override func getAggregateableResults() -> Results<SwiftAggregateObject> {
        makeAggregateableObjects()
        return realmWithTestPath().objects(SwiftAggregateObject).filter("trueCol == true")
    }
}

class ResultsFromLinkViewTests: ResultsTests {
    override func getResults() -> Results<SwiftStringObject> {
        let array = SwiftArrayPropertyObject.createInRealm(realmWithTestPath(),
        withObject: ["", [str1, str2], []])
        return array.array.filter("stringCol != ''") // i.e. all of them
    }

    override func getAggregateableResults() -> Results<SwiftAggregateObject> {
        let list = SwiftAggregateObjectList()
        realmWithTestPath().add(list)
        list.list.append(makeAggregateableObjects())
        return list.list.filter("intCol != 0") // i.e. all of them
    }
}
