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

#if FALSE

// swiftlint:disable all
class QueryTests_Prototype: TestCase {

    func objects() -> Results<ModernAllTypesObject> {
        realmWithTestPath().objects(ModernAllTypesObject.self)
    }

    override func setUp() {
        let realm = realmWithTestPath()
        try! realm.write {
            let object = ModernAllTypesObject()
            object.stringCol = "Foo"
            object.intCol = 5
            object.arrayInt.append(objectsIn: [1, 2, 3, 4, 5])
            object.mapString["Foo"] = "Bar"

            let object2 = ModernAllTypesObject()
            object2.stringCol = "Bar"
            object2.intCol = 6
            object2.arrayInt.append(objectsIn: [1, 2, 3, 4, 5])

            let object3 = ModernAllTypesObject()
            object3.intCol = 5
            object3.stringCol = "insideArrayCol"

            object.arrayCol.append(object3)

            object.objectCol = object2
            realm.add(object)
        }
    }

    func testBasicComparision() {
        // Equals
        let equalsQuery1 = objects().query { obj in
            obj.stringCol == "Foo"
        }
        XCTAssertEqual(equalsQuery1.count, 1)

        let equalsQuery2 = objects().query { obj in
            obj.objectCol.stringCol == "Bar"
        }
        XCTAssertEqual(equalsQuery2.count, 1)

        // Not Equals
        let equalsQuery3 = objects().query { obj in
            obj.objectCol.stringCol != "Bar"
        }
        XCTAssertEqual(equalsQuery3.count, 2)

        // Greater than
        let equalsQuery4 = objects().query { obj in
            obj.intCol > 4
        }
        XCTAssertEqual(equalsQuery4.count, 3)

        // Less than
        let equalsQuery5 = objects().query { obj in
            obj.intCol < 6
        }
        XCTAssertEqual(equalsQuery5.count, 2)

        // Greater than or equal
        let equalsQuery6 = objects().query { obj in
            obj.intCol >= 5
        }
        XCTAssertEqual(equalsQuery6.count, 3)

        // Less than or equal
        let equalsQuery7 = objects().query { obj in
            obj.intCol <= 6
        }
        XCTAssertEqual(equalsQuery7.count, 3)

        // Between
//        let equalsQuery8 = objects().query { obj in
//            obj.intCol.between(5, 6)
//        }
//        XCTAssertEqual(equalsQuery8.count, 3)
    }

    func testRange() {
        // >..
        let rangeQuery1 = objects().query { obj in
            obj.intCol.contains(4..<5)
        }
        XCTAssertEqual(rangeQuery1.count, 3)

        // ...
        let rangeQuery2 = objects().query { obj in
            obj.intCol.contains(4...5)
        }
        XCTAssertEqual(rangeQuery2.count, 3)
    }

    func testStringQuery() {
        // Contains
        let containsQuery1 = objects().query { obj in
            obj.stringCol.contains("f")
        }
        XCTAssertEqual(containsQuery1.count, 0)

        let containsQuery2 = objects().query { obj in
            obj.stringCol.contains("f", options: [.caseInsensitive])
        }
        XCTAssertEqual(containsQuery2.count, 1)

        let containsQuery3 = objects().query { obj in
            obj.stringCol.contains("á", options: [.caseInsensitive, .diacriticInsensitive])
        }
        XCTAssertEqual(containsQuery3.count, 1)

        // Begins with
        let beginsWithQuery = objects().query { obj in
            obj.stringCol.starts(with:"Fo")
        }
        XCTAssertEqual(beginsWithQuery.count, 1)

        // Ends with
        let endsWithQuery = objects().query { obj in
            obj.stringCol.ends(with:"ó", options: [.diacriticInsensitive, .caseInsensitive])
        }
        XCTAssertEqual(endsWithQuery.count, 1)

        // Like
        let likeQuery = objects().query { obj in
            obj.stringCol.like("F*", caseInsensitive: true)
        }
        XCTAssertEqual(likeQuery.count, 1)
    }

    func testArrayQueries() {
        let o = objects().query { $0.stringCol == "insideArrayCol"}.first!
        // In
        let containsQuery1 = objects().query { obj in
            obj.arrayCol.contains(o)
        }
        XCTAssertEqual(containsQuery1.count, 1)
    }

    func testSubquery() {
//        let subquery = objects().query { obj in
//            obj.subquery(\.arrayCol) { arrayCol in
//                arrayCol.intCol == 5 && arrayCol.stringCol == "Foo"
//            } == 1
//        }
//        XCTAssertEqual(subquery.count, 1)

        let subquery2 = objects().query { obj in
            obj.intCol == 5 &&
            obj.arrayInt.contains(1) &&
            (obj.arrayCol.intCol == 5 && obj.arrayCol.stringCol == "insideArrayCol").count() == 5 &&
            (obj.arrayCol.stringCol == "Bar").count() == 5
        }
        XCTAssertEqual(subquery2.count, 1)
    }

    func testSubqueryMap() {

        let subquery2 = objects().query { obj in
            obj.mapString.contains("Bar")
        }
        XCTAssertEqual(subquery2.count, 1)

        let subquery3 = objects().query { obj in
            obj.mapString["Bar"] == "Foo"
        }
        XCTAssertEqual(subquery3.count, 1)
    }

    func testOptional() {
        let query = objects().query { obj in
            obj.optStringCol == .none
        }
        XCTAssertEqual(query.count, 3)

        let query2 = objects().query { obj in
            obj.optStringCol == nil
        }
        XCTAssertEqual(query2.count, 3)
    }

    func testMap() {
        try! realmWithTestPath().write {
            let obj = ModernAllTypesObject(value: ["intCol": 123, "mapInt": ["foo": 123]])
            let colObj = ModernCollectionObject(value: ["map": ["foo": obj]])
            realmWithTestPath().add(colObj)
        }
        print(realmWithTestPath().objects(ModernCollectionObject.self))
        let result = realmWithTestPath().objects(ModernCollectionObject.self).filter("map.intCol == 456")
        print(result)
        let result2 = realmWithTestPath().objects(ModernAllTypesObject.self).filter("mapInt == 456")
        print(result2)
    }

    func testCompoundNot() {
        let compoundQuery1 = objects().query {
            $0.stringCol.ends(with: "oo", options: [.caseInsensitive, .diacriticInsensitive]) && !$0.stringCol.contains("hy", options: [.caseInsensitive, .diacriticInsensitive])
        }
        XCTAssertEqual(compoundQuery1.count, 1)
        
        let compoundQuery2 = objects().query {
            !$0.stringCol.contains("hy", options: [.caseInsensitive, .diacriticInsensitive]) && $0.stringCol.ends(with: "oo", options: [.caseInsensitive, .diacriticInsensitive])
        }
        XCTAssertEqual(compoundQuery2.count, 1)
    }
}

#endif
