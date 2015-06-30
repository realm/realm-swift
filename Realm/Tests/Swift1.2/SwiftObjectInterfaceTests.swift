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
import Foundation

class OuterClass {
    class InnerClass {

    }
}

class SwiftStringObjectSubclass : SwiftStringObject {
    var stringCol2 = ""
}

class SwiftSelfRefrencingSubclass: SwiftStringObject {
    dynamic var objects = RLMArray(objectClassName: SwiftSelfRefrencingSubclass.className())
}


class SwiftDefaultObject: RLMObject {
    dynamic var intCol = 1
    dynamic var boolCol = true

    override class func defaultPropertyValues() -> [NSObject : AnyObject]? {
        return ["intCol": 2]
    }
}

class SwiftObjectInterfaceTests: RLMTestCase {

    // Swift models

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

        let data = NSString(string: "abcd").dataUsingEncoding(NSUTF8StringEncoding)

        let firstObj = SwiftObject.allObjectsInRealm(realm).firstObject() as! SwiftObject
        XCTAssertEqual(firstObj.boolCol, true, "should be true")
        XCTAssertEqual(firstObj.intCol, 1234, "should be 1234")
        XCTAssertEqual(firstObj.floatCol, Float(1.1), "should be 1.1")
        XCTAssertEqual(firstObj.doubleCol, 2.2, "should be 2.2")
        XCTAssertEqual(firstObj.stringCol, "abcd", "should be abcd")
        XCTAssertEqual(firstObj.binaryCol!, data!)
        XCTAssertEqual(firstObj.dateCol, NSDate(timeIntervalSince1970: 123), "should be epoch + 123")
        XCTAssertEqual(firstObj.objectCol.boolCol, true, "should be true")
        XCTAssertEqual(obj.arrayCol.count, UInt(1), "array count should be 1")
        XCTAssertEqual((obj.arrayCol.firstObject() as? SwiftBoolObject)!.boolCol, true, "should be true")
    }

    func testDefaultValueSwiftObject() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        realm.addObject(SwiftObject())
        realm.commitWriteTransaction()

        let data = NSString(string: "a").dataUsingEncoding(NSUTF8StringEncoding)

        let firstObj = SwiftObject.allObjectsInRealm(realm).firstObject() as! SwiftObject
        XCTAssertEqual(firstObj.boolCol, false, "should be false")
        XCTAssertEqual(firstObj.intCol, 123, "should be 123")
        XCTAssertEqual(firstObj.floatCol, Float(1.23), "should be 1.23")
        XCTAssertEqual(firstObj.doubleCol, 12.3, "should be 12.3")
        XCTAssertEqual(firstObj.stringCol, "a", "should be a")
        XCTAssertEqual(firstObj.binaryCol!, data!)
        XCTAssertEqual(firstObj.dateCol, NSDate(timeIntervalSince1970: 1), "should be epoch + 1")
        XCTAssertEqual(firstObj.objectCol.boolCol, false, "should be false")
        XCTAssertEqual(firstObj.arrayCol.count, UInt(0), "array count should be zero")
    }

    func testMergedDefaultValuesSwiftObject() {
        let realm = self.realmWithTestPath()
        realm.beginWriteTransaction()
        SwiftDefaultObject.createInRealm(realm, withValue: NSDictionary())
        realm.commitWriteTransaction()

        let object = SwiftDefaultObject.allObjectsInRealm(realm).firstObject() as! SwiftDefaultObject
        XCTAssertEqual(object.intCol, 2, "defaultPropertyValues should override native property default value")
        XCTAssertEqual(object.boolCol, true, "native property default value should be used if defaultPropertyValues doesn't contain that key")
    }

    func testSubclass() {
        // test className methods
        XCTAssertEqual("SwiftStringObject", SwiftStringObject.className())
        XCTAssertEqual("SwiftStringObjectSubclass", SwiftStringObjectSubclass.className())

        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        SwiftStringObject.createInDefaultRealmWithValue(["string"])

        SwiftStringObjectSubclass.createInDefaultRealmWithValue(["string", "string2"])
        realm.commitWriteTransaction()

        // ensure creation in proper table
        XCTAssertEqual(UInt(1), SwiftStringObjectSubclass.allObjects().count)
        XCTAssertEqual(UInt(1), SwiftStringObject.allObjects().count)

        realm.transactionWithBlock { () -> Void in
            // create self referencing subclass
            let sub = SwiftSelfRefrencingSubclass.createInDefaultRealmWithValue(["string", []])
            let sub2 = SwiftSelfRefrencingSubclass()
            sub.objects.addObject(sub2)
        }
    }

#if REALM_ENABLE_NULL
    func testOptionalSwiftProperties() {
        let realm = realmWithTestPath()
        realm.transactionWithBlock { realm.addObject(SwiftOptionalObject()) }

        let firstObj = SwiftOptionalObject.allObjectsInRealm(realm).firstObject() as! SwiftOptionalObject
        XCTAssertNil(firstObj.optObjectCol)
        XCTAssertNil(firstObj.optStringCol)
        XCTAssertNil(firstObj.optBinaryCol)
        XCTAssertNil(firstObj.optDateCol)

        realm.transactionWithBlock {
            firstObj.optObjectCol = SwiftBoolObject()
            firstObj.optObjectCol!.boolCol = true

            firstObj.optStringCol = "Hi!"
            firstObj.optBinaryCol = NSData(bytes: "hi", length: 2)
            firstObj.optDateCol = NSDate(timeIntervalSinceReferenceDate: 10)
        }
        XCTAssertTrue(firstObj.optObjectCol!.boolCol)
        XCTAssertEqual(firstObj.optStringCol!, "Hi!")
        XCTAssertEqual(firstObj.optBinaryCol!, NSData(bytes: "hi", length: 2))
        XCTAssertEqual(firstObj.optDateCol!,  NSDate(timeIntervalSinceReferenceDate: 10))

        realm.transactionWithBlock {
            firstObj.optObjectCol = nil
            firstObj.optStringCol = nil
            firstObj.optBinaryCol = nil
            firstObj.optDateCol = nil
        }
        XCTAssertNil(firstObj.optObjectCol)
        XCTAssertNil(firstObj.optStringCol)
        XCTAssertNil(firstObj.optBinaryCol)
        XCTAssertNil(firstObj.optDateCol)
    }
#endif

    func testSwiftClassNameIsDemangled() {
        XCTAssertEqual(SwiftObject.className(), "SwiftObject", "Calling className() on Swift class should return demangled name")
    }

    // Objective-C models

    // Note: Swift doesn't support custom accessor names
    // so we test to make sure models with custom accessors can still be accessed
    func testCustomAccessors() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let ca = CustomAccessorsObject.createInRealm(realm, withValue: ["name", 2])
        XCTAssertEqual(ca.name!, "name", "name property should be name.")
        ca.age = 99
        XCTAssertEqual(ca.age, Int32(99), "age property should be 99")
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

        let objectFromRealm = BaseClassStringObject.allObjectsInRealm(realm)[0] as! BaseClassStringObject
        XCTAssertEqual(objectFromRealm.intCol, Int32(1), "Should be 1")
        XCTAssertEqual(objectFromRealm.stringCol!, "stringVal", "Should be stringVal")
    }

    func testCreateOrUpdate() {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        SwiftPrimaryStringObject.createOrUpdateInDefaultRealmWithValue(["string", 1])
        let objects = SwiftPrimaryStringObject.allObjects();
        XCTAssertEqual(objects.count, UInt(1), "Should have 1 object");
        XCTAssertEqual((objects[0] as! SwiftPrimaryStringObject).intCol, 1, "Value should be 1");

        SwiftPrimaryStringObject.createOrUpdateInDefaultRealmWithValue(["stringCol": "string2", "intCol": 2])
        XCTAssertEqual(objects.count, UInt(2), "Should have 2 objects")

        SwiftPrimaryStringObject.createOrUpdateInDefaultRealmWithValue(["string", 3])
        XCTAssertEqual(objects.count, UInt(2), "Should have 2 objects")
        XCTAssertEqual((objects[0] as! SwiftPrimaryStringObject).intCol, 3, "Value should be 3");

        realm.commitWriteTransaction()
    }

    // if this fails (and you haven't changed the test module name), the checks
    // for swift class names and the demangling logic need to be updated
    func testNSStringFromClassDemangledTopLevelClassNames() {
#if os(iOS)
        XCTAssertEqual(NSStringFromClass(OuterClass), "iOS_Tests.OuterClass")
#else
        XCTAssertEqual(NSStringFromClass(OuterClass), "OSX_Tests.OuterClass")
#endif
    }

    // if this fails (and you haven't changed the test module name), the prefix
    // check in RLMSchema initialization needs to be updated
    func testNestedClassNameMangling() {
#if os(iOS)
        XCTAssertEqual(NSStringFromClass(OuterClass.InnerClass.self), "_TtCC9iOS_Tests10OuterClass10InnerClass")
#else
        XCTAssertEqual(NSStringFromClass(OuterClass.InnerClass.self), "_TtCC9OSX_Tests10OuterClass10InnerClass")
#endif
    }

}
