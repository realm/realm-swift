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
        let results1 = objects.filter {
            $0.stringCol == "Foo"
        }
        XCTAssertEqual(results1.count, 1)
        XCTAssertEqual(results1.first!.stringCol, "Foo")

        let results2 = objects.filter {
            $0.stringCol != "Foo"
        }
        XCTAssertEqual(results2.count, 0)

        let results3 = objects.filter {
            $0.intCol == 5
        }

        XCTAssertEqual(results3.count, 1)
        XCTAssertEqual(results3.first!.intCol, 5)
    }
}
