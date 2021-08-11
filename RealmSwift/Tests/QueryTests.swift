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

class QueryTests: TestCase {

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
        let equalsQuery8 = objects().query { obj in
            obj.intCol.between(5, 6)
        }
        XCTAssertEqual(equalsQuery8.count, 3)

//        let q = objects().filter("obj.arrayCol[FIRST].intCol == 1")
//        XCTAssertEqual(q.count, 1)
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
}
