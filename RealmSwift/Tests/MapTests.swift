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

class MapTests: TestCase {
    
    override func setUp() {
        super.setUp()
        let realm = realmWithTestPath()
        realm.beginWrite()
    }

    override func tearDown() {
        try! realmWithTestPath().commitWrite()
        super.tearDown()
    }

    func testPrimitive() {
        let obj = SwiftMapObject()
        let valueInTest = 5
        obj.int[String(valueInTest)] = valueInTest
        XCTAssertEqual(obj.int.first!, 5)
        XCTAssertEqual(obj.int.last!, 5)
        XCTAssertEqual(obj.int[0], 5)
        XCTAssertEqual(obj.int["5"], 5)
        
//        obj.int.app
//        obj.int.append(objectsIn: [6, 7, 8] as [Int])
//        XCTAssertEqual(obj.int.index(of: 6), 1)
//        XCTAssertEqual(2, obj.int.index(matching: NSPredicate(format: "self == 7")))
//        XCTAssertNil(obj.int.index(matching: NSPredicate(format: "self == 9")))
//        XCTAssertEqual(obj.int.max(), 8)
//        XCTAssertEqual(obj.int.sum(), 26)
//
//        obj.string.append("str")
//        XCTAssertEqual(obj.string.first!, "str")
//        XCTAssertEqual(obj.string[0], "str")
    }
}
