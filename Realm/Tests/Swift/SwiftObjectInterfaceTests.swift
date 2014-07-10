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
import TestFramework

class SwiftObjectInterfaceTests: RLMTestCase {
    
    // Note: Swift doesn't support custom accessor names
    // so we test to make sure models with custom accessors can still be accessed
    func testCustomAccessors() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let ca = CustomAccessorsObject.createInRealm(realm, withObject: ["name", 2])
        XCTAssertEqualObjects(ca.name, "name", "name property should be name.")
        ca.age = 99
        XCTAssertEqual(ca.age, 99, "age property should be 99")
        realm.commitWriteTransaction()
    }
    
    func testClassExtension() {
        let realm = realmWithTestPath()
        
        realm.beginWriteTransaction()
        let bObject = BaseClassStringObject()
        bObject.intCol = 1
        bObject.stringCol = "stringVal"
        realm.addObject(bObject)
        realm.commitWriteTransaction()
        
        let objectFromRealm = BaseClassStringObject.allObjectsInRealm(realm)[0] as BaseClassStringObject
        XCTAssertEqual(objectFromRealm.intCol, 1, "Should be 1")
        XCTAssertEqualObjects(objectFromRealm.stringCol, "stringVal", "Should be stringVal")
    }
}
