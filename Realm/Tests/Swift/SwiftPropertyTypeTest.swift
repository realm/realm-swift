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
import Realm
import TestFramework

class SwiftPropertyTypeTest: SwiftTestCase {

    func testLongType() {
        let longNumber = Int(pow(2.0, 34.0))
        let shortNumber = 1234
        let negativeLongNumber = -Int(pow(2.0, 33.0))
        let updatedLongNumber = Int(pow(2.0, 33.0))

        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        SwiftIntObject.createInRealm(realm, withObject: [longNumber])
        SwiftIntObject.createInRealm(realm, withObject: [shortNumber])
        SwiftIntObject.createInRealm(realm, withObject: [negativeLongNumber])
        realm.commitWriteTransaction()
        
        let objects = SwiftIntObject.allObjectsInRealm(realm)
        XCTAssertEqual(objects.count, 3, "3 rows expected")
        XCTAssertEqual((objects[0] as SwiftIntObject).intCol, longNumber, "2 ^ 34 expected")
        XCTAssertEqual((objects[1] as SwiftIntObject).intCol, shortNumber, "1234 expected")
        XCTAssertEqual((objects[2] as SwiftIntObject).intCol, negativeLongNumber, "-2 ^ 33 expected")

        realm.beginWriteTransaction()
        (objects[0] as SwiftIntObject).intCol = updatedLongNumber
        realm.commitWriteTransaction()

        XCTAssertEqual((objects[0] as SwiftIntObject).intCol, updatedLongNumber, "After update: 2 ^ 33 expected")
    }
}
