////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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
#if DEBUG
    @testable import RealmSwift
#else
    import RealmSwift
#endif
import Foundation

class TestClass: Object {
    dynamic var id: Int = 0
    
    let intArray = List<RealmInt>()
    let doubleArray = List<RealmDouble>()
    let stringArray = List<RealmString>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class SwiftObjectAddingTests: TestCase {
    
    func testShouldAddObjectWithExpressibleInts() {
        let realm = try! Realm(fileURL: testRealmURL())
        try! realm.write {
            let object = TestClass()
            
            object.intArray.append(0)
            object.intArray.append(1)
            
            realm.add(object)
        }
        
        if let object = realm.object(ofType: TestClass.self, forPrimaryKey: 0) {
            XCTAssertEqual(object.intArray.count, 2)
            XCTAssertEqual(object.stringArray.count, 0)
            XCTAssertEqual(object.doubleArray.count, 0)
            
            XCTAssertEqual(object.intArray[0].value, 0)
            XCTAssertEqual(object.intArray[1].value, 1)
        } else {
            XCTFail()
        }
    }
    
    func testShouldAddObjectWithExpressibleDoubles() {
        let realm = try! Realm(fileURL: testRealmURL())
        try! realm.write {
            let object = TestClass()
            
            object.doubleArray.append(0.0)
            object.doubleArray.append(1.5)
            
            realm.add(object)
        }
        
        if let object = realm.object(ofType: TestClass.self, forPrimaryKey: 0) {
            XCTAssertEqual(object.intArray.count, 0)
            XCTAssertEqual(object.doubleArray.count, 2)
            XCTAssertEqual(object.stringArray.count, 0)
            
            XCTAssertEqual(object.doubleArray[0].value, 0.0)
            XCTAssertEqual(object.doubleArray[1].value, 1.5)
        } else {
            XCTFail()
        }
    }
    
    func testShouldAddObjectWithExpressibleStrings() {
        let realm = try! Realm(fileURL: testRealmURL())
        try! realm.write {
            let object = TestClass()
            
            object.stringArray.append("abba")
            object.stringArray.append("kappacino")
            
            realm.add(object)
        }
        
        if let object = realm.object(ofType: TestClass.self, forPrimaryKey: 0) {
            XCTAssertEqual(object.intArray.count, 0)
            XCTAssertEqual(object.doubleArray.count, 0)
            XCTAssertEqual(object.stringArray.count, 2)
            
            XCTAssertEqual(object.stringArray[0].value, "abba")
            XCTAssertEqual(object.stringArray[1].value, "kappacino")
        } else {
            XCTFail()
        }
    }
    
    func testShouldThrowOnAddingObjectWithExistingId() {
        let realm = try! Realm(fileURL: testRealmURL())
        
        try! realm.write {
            let object = TestClass()
            realm.add(object)
        }
        
        try! realm.write {
            let object = TestClass()
            assertThrows(realm.add(object))
        }
    }
    
    func testShouldUpdateObjectWithExisitingId() {
        let realm = try! Realm(fileURL: testRealmURL())

        try! realm.write {
            let object = TestClass()
            realm.add(object)
        }
        
        assertTestObjectEmpty(realm: realm)
        
        try! realm.write {
            let object = TestClass()
            
            object.intArray.append(0)
            object.intArray.append(1)
            
            realm.add(object, update: true)
        }
        
        if let object = realm.object(ofType: TestClass.self, forPrimaryKey: 0) {
            XCTAssertEqual(object.intArray.count, 2)
            XCTAssertEqual(object.stringArray.count, 0)
            XCTAssertEqual(object.doubleArray.count, 0)
            
            XCTAssertEqual(object.intArray[0].value, 0)
            XCTAssertEqual(object.intArray[1].value, 1)
        } else {
            XCTFail()
        }
    }

    func testShouldNotUpdateObjectWithExisitingId() {
        let realm = try! Realm(fileURL: testRealmURL())
        
        try! realm.write {
            realm.deleteAll()
        }
        
        try! realm.write {
            let object = TestClass()
            realm.add(object)
        }
        
        assertTestObjectEmpty(realm: realm)
        
        try! realm.write {
            let object = TestClass()
            
            object.intArray.append(0)
            object.intArray.append(1)
            
            realm.add(object, update: false)
        }
        
        assertTestObjectEmpty(realm: realm)
    }
    
    private func assertTestObjectEmpty(realm: Realm) {
        if let object = realm.object(ofType: TestClass.self, forPrimaryKey: 0) {
            XCTAssertEqual(object.intArray.count, 0)
            XCTAssertEqual(object.stringArray.count, 0)
            XCTAssertEqual(object.doubleArray.count, 0)
        } else {
            XCTFail()
        }
    }
}
