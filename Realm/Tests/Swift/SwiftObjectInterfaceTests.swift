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

class SwiftBoolObject: RLMObject {
    var boolCol = false
}

class SwiftObject: RLMObject {
    var boolCol = false
    var intCol = 123
    var floatCol = 1.23 as Float
    var doubleCol = 12.3
    var stringCol = "a"
    var binaryCol = "a".dataUsingEncoding(NSUTF8StringEncoding)
    var dateCol = NSDate(timeIntervalSince1970: 1)
    var swiftDateCol = NSDate(timeIntervalSince1970: 1)
    var objectCol = SwiftBoolObject()
    var arrayCol = RLMArray(objectClassName: SwiftBoolObject.className())
}

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
        
        let objectFromRealm = realm.allObjects(BaseClassStringObject.className())[0] as BaseClassStringObject
        XCTAssertEqual(objectFromRealm.intCol, 1, "Should be 1")
        XCTAssertEqualObjects(objectFromRealm.stringCol, "stringVal", "Should be stringVal")
    }

    func testSwiftObject() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        
        let obj = SwiftObject()
        realm.addObject(obj)

        obj.boolCol = true
        obj.intCol = 1234
        obj.floatCol = 1.1
        obj.doubleCol = 2.2
        obj.stringCol = "abcd"
        obj.binaryCol = "abcd".dataUsingEncoding(NSUTF8StringEncoding)
        obj.dateCol = NSDate(timeIntervalSince1970: 123)
        obj.objectCol = SwiftBoolObject()
        obj.objectCol.boolCol = true
        obj.arrayCol.addObject(obj.objectCol)

        realm.commitWriteTransaction()
        
        let firstObj = realm.allObjects(SwiftObject.className()).firstObject() as SwiftObject
        XCTAssertEqual(firstObj.boolCol, true, "should be true")
        XCTAssertEqual(firstObj.intCol, 1234, "should be 1234")
        XCTAssertEqual(firstObj.floatCol, 1.1, "should be 1.1")
        XCTAssertEqual(firstObj.doubleCol, 2.2, "should be 2.2")
        XCTAssertEqual(firstObj.stringCol, "abcd", "should be abcd")
        XCTAssertEqual(firstObj.binaryCol, "abcd".dataUsingEncoding(NSUTF8StringEncoding), "should be abcd data")
        XCTAssertEqual(firstObj.dateCol, NSDate(timeIntervalSince1970: 123), "should be epoch + 123")
        XCTAssertEqual(firstObj.objectCol.boolCol, true, "should be true")
        XCTAssertEqual(obj.arrayCol.count, 1, "array count should be 1")
        XCTAssertEqual((obj.arrayCol.firstObject() as? SwiftBoolObject)!.boolCol, true, "should be true")
    }

    func testDefaultValueSwiftObject() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        realm.addObject(SwiftObject())
        realm.commitWriteTransaction()
        
        let firstObj = realm.allObjects(SwiftObject.className()).firstObject() as SwiftObject
        XCTAssertEqual(firstObj.boolCol, false, "should be false")
        XCTAssertEqual(firstObj.intCol, 123, "should be 123")
        XCTAssertEqual(firstObj.floatCol, 1.23, "should be 1.1")
        XCTAssertEqual(firstObj.doubleCol, 12.3, "should be 2.2")
        XCTAssertEqual(firstObj.stringCol, "a", "should be a")
        XCTAssertEqual(firstObj.binaryCol, "a".dataUsingEncoding(NSUTF8StringEncoding), "should be a data")
        XCTAssertEqual(firstObj.dateCol, NSDate(timeIntervalSince1970: 1), "should be epoch + 1")
        XCTAssertEqual(firstObj.objectCol.boolCol, false, "should be false")
        XCTAssertEqual(firstObj.arrayCol.count, 0, "array count should be zero")
    }

    func testSwiftClassNameIsDemangled() {
        XCTAssertEqualObjects(SwiftObject.className(), "SwiftObject", "Calling className() on Swift class should return demangled name")
    }
}
