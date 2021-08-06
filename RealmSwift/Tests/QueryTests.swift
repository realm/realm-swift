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

    func testPrototype() {
        let realm = realmWithTestPath()
        let objects = realm.objects(ModernAllTypesObject.self)
        try! realm.write {
            let object = ModernAllTypesObject()
            object.stringCol = "Foo"
            object.intCol = 5
            object.arrayInt.append(objectsIn: [1, 2, 3, 4, 5])

            realm.add(object)
        }

        // Simple example of string comparision
        let results1 = objects.query {
            $0.stringCol == "Foo"
        }
        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results1.first!.stringCol, "Foo")

        let results2 = objects.query {
            $0.stringCol != "Foo"
        }
        XCTAssertEqual(results2.count, 0)

        let results3 = objects.query {
            $0.intCol == 5
        }

        XCTAssertEqual(results3.count, 1)
        XCTAssertEqual(results3.first!.intCol, 5)

        let results4 = objects.query {
            $0.intCol > 5
        }

        XCTAssertEqual(results4.count, 0)

        let results5 = objects.query {
            $0.intCol < 5
        }

        XCTAssertEqual(results5.count, 0)

        let results6 = objects.query {
            $0.intCol <= 5
        }

        XCTAssertEqual(results6.count, 1)

        let results7 = objects.query {
            $0.intCol >= 5
        }

        XCTAssertEqual(results7.count, 1)

        let results8 = objects.query {
            $0.intCol == 5 && $0.stringCol == "Foo"
        }

        XCTAssertEqual(results8.count, 1)

        let results9 = objects.query {
            $0.intCol == 0 && $0.stringCol == "Foo"
        }

        XCTAssertEqual(results9.count, 0)

        let results10 = objects.query {
            $0.intCol == 0 || $0.stringCol == "Foo"
        }

        XCTAssertEqual(results10.count, 1)

        let results11 = objects.query {
            $0.intCol.between(0, 5)
        }

        XCTAssertEqual(results11.count, 1)

        let results12 = objects.query {
            !$0.intCol.between(0, 5)
        }

        XCTAssertEqual(results12.count, 0)

//        let results13 = objects.query {
//            ($0.arrayCol.intCol == 5).count == 50
//        }
//
//        XCTAssertEqual(results13.count, 0)

    }
}
