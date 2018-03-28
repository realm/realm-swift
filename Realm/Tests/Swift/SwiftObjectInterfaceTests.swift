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
    @objc dynamic var stringCol2 = ""
}

class SwiftSelfRefrencingSubclass: SwiftStringObject {
    @objc dynamic var objects = RLMArray<SwiftSelfRefrencingSubclass>(objectClassName: SwiftSelfRefrencingSubclass.className())
}


class SwiftDefaultObject: RLMObject {
    @objc dynamic var intCol = 1
    @objc dynamic var boolCol = true

    override class func defaultPropertyValues() -> [AnyHashable : Any]? {
        return ["intCol": 2]
    }
}

class SwiftOptionalNumberObject: RLMObject {
    @objc dynamic var intCol: NSNumber? = 1
    @objc dynamic var floatCol: NSNumber? = 2.2 as Float as NSNumber
    @objc dynamic var doubleCol: NSNumber? = 3.3
    @objc dynamic var boolCol: NSNumber? = true
}

class SwiftObjectInterfaceTests: RLMTestCase {

    // Swift models

    func testSwiftObject() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()

        let obj = SwiftObject()
        realm.add(obj)

        obj.boolCol = true
        obj.intCol = 1234
        obj.floatCol = 1.1
        obj.doubleCol = 2.2
        obj.stringCol = "abcd"
        obj.binaryCol = "abcd".data(using: String.Encoding.utf8)
        obj.dateCol = Date(timeIntervalSince1970: 123)
        obj.objectCol = SwiftBoolObject()
        obj.objectCol.boolCol = true
        obj.arrayCol.add(obj.objectCol)
        try! realm.commitWriteTransaction()

        let data = "abcd".data(using: String.Encoding.utf8)

        let firstObj = SwiftObject.allObjects(in: realm).firstObject() as! SwiftObject
        XCTAssertEqual(firstObj.boolCol, true, "should be true")
        XCTAssertEqual(firstObj.intCol, 1234, "should be 1234")
        XCTAssertEqual(firstObj.floatCol, Float(1.1), "should be 1.1")
        XCTAssertEqual(firstObj.doubleCol, 2.2, "should be 2.2")
        XCTAssertEqual(firstObj.stringCol, "abcd", "should be abcd")
        XCTAssertEqual(firstObj.binaryCol!, data!)
        XCTAssertEqual(firstObj.dateCol, Date(timeIntervalSince1970: 123), "should be epoch + 123")
        XCTAssertEqual(firstObj.objectCol.boolCol, true, "should be true")
        XCTAssertEqual(obj.arrayCol.count, UInt(1), "array count should be 1")
        XCTAssertEqual(obj.arrayCol.firstObject()!.boolCol, true, "should be true")
    }

    func testDefaultValueSwiftObject() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        realm.add(SwiftObject())
        try! realm.commitWriteTransaction()

        let data = "a".data(using: String.Encoding.utf8)

        let firstObj = SwiftObject.allObjects(in: realm).firstObject() as! SwiftObject
        XCTAssertEqual(firstObj.boolCol, false, "should be false")
        XCTAssertEqual(firstObj.intCol, 123, "should be 123")
        XCTAssertEqual(firstObj.floatCol, Float(1.23), "should be 1.23")
        XCTAssertEqual(firstObj.doubleCol, 12.3, "should be 12.3")
        XCTAssertEqual(firstObj.stringCol, "a", "should be a")
        XCTAssertEqual(firstObj.binaryCol!, data!)
        XCTAssertEqual(firstObj.dateCol, Date(timeIntervalSince1970: 1), "should be epoch + 1")
        XCTAssertEqual(firstObj.objectCol.boolCol, false, "should be false")
        XCTAssertEqual(firstObj.arrayCol.count, UInt(0), "array count should be zero")
    }

    func testMergedDefaultValuesSwiftObject() {
        let realm = self.realmWithTestPath()
        realm.beginWriteTransaction()
        _ = SwiftDefaultObject.create(in: realm, withValue: NSDictionary())
        try! realm.commitWriteTransaction()

        let object = SwiftDefaultObject.allObjects(in: realm).firstObject() as! SwiftDefaultObject
        XCTAssertEqual(object.intCol, 2, "defaultPropertyValues should override native property default value")
        XCTAssertEqual(object.boolCol, true, "native property default value should be used if defaultPropertyValues doesn't contain that key")
    }

    func testSubclass() {
        // test className methods
        XCTAssertEqual("SwiftStringObject", SwiftStringObject.className())
        XCTAssertEqual("SwiftStringObjectSubclass", SwiftStringObjectSubclass.className())

        let realm = RLMRealm.default()
        realm.beginWriteTransaction()
        _ = SwiftStringObject.createInDefaultRealm(withValue: ["string"])

        _ = SwiftStringObjectSubclass.createInDefaultRealm(withValue: ["string", "string2"])
        try! realm.commitWriteTransaction()

        // ensure creation in proper table
        XCTAssertEqual(UInt(1), SwiftStringObjectSubclass.allObjects().count)
        XCTAssertEqual(UInt(1), SwiftStringObject.allObjects().count)

        try! realm.transaction {
            // create self referencing subclass
            let sub = SwiftSelfRefrencingSubclass.createInDefaultRealm(withValue: ["string", []])
            let sub2 = SwiftSelfRefrencingSubclass()
            sub.objects.add(sub2)
        }
    }

    func testOptionalNSNumberProperties() {
        let realm = realmWithTestPath()
        let no = SwiftOptionalNumberObject()
        XCTAssertEqual([.int, .float, .double, .bool], no.objectSchema.properties.map { $0.type })

        XCTAssertEqual(1, no.intCol!)
        XCTAssertEqual(2.2 as Float as NSNumber, no.floatCol!)
        XCTAssertEqual(3.3, no.doubleCol!)
        XCTAssertEqual(true, no.boolCol!)

        try! realm.transaction {
            realm.add(no)
            no.intCol = nil
            no.floatCol = nil
            no.doubleCol = nil
            no.boolCol = nil
        }

        XCTAssertNil(no.intCol)
        XCTAssertNil(no.floatCol)
        XCTAssertNil(no.doubleCol)
        XCTAssertNil(no.boolCol)

        try! realm.transaction {
            no.intCol = 1.1
            no.floatCol = 2.2 as Float as NSNumber
            no.doubleCol = 3.3
            no.boolCol = false
        }

        XCTAssertEqual(1, no.intCol!)
        XCTAssertEqual(2.2 as Float as NSNumber, no.floatCol!)
        XCTAssertEqual(3.3, no.doubleCol!)
        XCTAssertEqual(false, no.boolCol!)
    }

    func testOptionalSwiftProperties() {
        let realm = realmWithTestPath()
        try! realm.transaction { realm.add(SwiftOptionalObject()) }

        let firstObj = SwiftOptionalObject.allObjects(in: realm).firstObject() as! SwiftOptionalObject
        XCTAssertNil(firstObj.optObjectCol)
        XCTAssertNil(firstObj.optStringCol)
        XCTAssertNil(firstObj.optNSStringCol)
        XCTAssertNil(firstObj.optBinaryCol)
        XCTAssertNil(firstObj.optDateCol)

        try! realm.transaction {
            firstObj.optObjectCol = SwiftBoolObject()
            firstObj.optObjectCol!.boolCol = true

            firstObj.optStringCol = "Hi!"
            firstObj.optNSStringCol = "Hi!"
            firstObj.optBinaryCol = Data(bytes: "hi", count: 2)
            firstObj.optDateCol = Date(timeIntervalSinceReferenceDate: 10)
        }
        XCTAssertTrue(firstObj.optObjectCol!.boolCol)
        XCTAssertEqual(firstObj.optStringCol!, "Hi!")
        XCTAssertEqual(firstObj.optNSStringCol!, "Hi!")
        XCTAssertEqual(firstObj.optBinaryCol!, Data(bytes: "hi", count: 2))
        XCTAssertEqual(firstObj.optDateCol!,  Date(timeIntervalSinceReferenceDate: 10))

        try! realm.transaction {
            firstObj.optObjectCol = nil
            firstObj.optStringCol = nil
            firstObj.optNSStringCol = nil
            firstObj.optBinaryCol = nil
            firstObj.optDateCol = nil
        }
        XCTAssertNil(firstObj.optObjectCol)
        XCTAssertNil(firstObj.optStringCol)
        XCTAssertNil(firstObj.optNSStringCol)
        XCTAssertNil(firstObj.optBinaryCol)
        XCTAssertNil(firstObj.optDateCol)
    }

    func testSwiftClassNameIsDemangled() {
        XCTAssertEqual(SwiftObject.className(), "SwiftObject",
                       "Calling className() on Swift class should return demangled name")
    }

    func testPrimitiveArray() {
        let obj = SwiftPrimitiveArrayObject()
        let str = "str" as NSString
        let data = "str".data(using: .utf8)! as Data as NSData
        let date = NSDate()
        let str2 = "str2" as NSString
        let data2 = "str2".data(using: .utf8)! as Data as NSData
        let date2 = NSDate(timeIntervalSince1970: 0)

        obj.stringCol.add(str)
        XCTAssertEqual(obj.stringCol[0], str)
        XCTAssertEqual(obj.stringCol.index(of: str), 0)
        XCTAssertEqual(obj.stringCol.index(of: str2), UInt(NSNotFound))

        obj.dataCol.add(data)
        XCTAssertEqual(obj.dataCol[0], data)
        XCTAssertEqual(obj.dataCol.index(of: data), 0)
        XCTAssertEqual(obj.dataCol.index(of: data2), UInt(NSNotFound))

        obj.dateCol.add(date)
        XCTAssertEqual(obj.dateCol[0], date)
        XCTAssertEqual(obj.dateCol.index(of: date), 0)
        XCTAssertEqual(obj.dateCol.index(of: date2), UInt(NSNotFound))

        obj.optStringCol.add(str)
        XCTAssertEqual(obj.optStringCol[0], str)
        obj.optDataCol.add(data)
        XCTAssertEqual(obj.optDataCol[0], data)
        obj.optDateCol.add(date)
        XCTAssertEqual(obj.optDateCol[0], date)

        obj.optStringCol.add(NSNull())
        XCTAssertEqual(obj.optStringCol[1], NSNull())
        obj.optDataCol.add(NSNull())
        XCTAssertEqual(obj.optDataCol[1], NSNull())
        obj.optDateCol.add(NSNull())
        XCTAssertEqual(obj.optDateCol[1], NSNull())

        assertThrowsWithReasonMatching(obj.optDataCol.add(str), ".*")
    }

    // Objective-C models

    // Note: Swift doesn't support custom accessor names
    // so we test to make sure models with custom accessors can still be accessed
    func testCustomAccessors() {
        let realm = realmWithTestPath()
        realm.beginWriteTransaction()
        let ca = CustomAccessorsObject.create(in: realm, withValue: ["name", 2])
        XCTAssertEqual(ca.name!, "name", "name property should be name.")
        ca.age = 99
        XCTAssertEqual(ca.age, Int32(99), "age property should be 99")
        try! realm.commitWriteTransaction()
    }

    func testClassExtension() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let bObject = BaseClassStringObject()
        bObject.intCol = 1
        bObject.stringCol = "stringVal"
        realm.add(bObject)
        try! realm.commitWriteTransaction()

        let objectFromRealm = BaseClassStringObject.allObjects(in: realm)[0] as! BaseClassStringObject
        XCTAssertEqual(objectFromRealm.intCol, Int32(1), "Should be 1")
        XCTAssertEqual(objectFromRealm.stringCol!, "stringVal", "Should be stringVal")
    }

    func testCreateOrUpdate() {
        let realm = RLMRealm.default()
        realm.beginWriteTransaction()
        _ = SwiftPrimaryStringObject.createOrUpdateInDefaultRealm(withValue: ["string", 1])
        let objects = SwiftPrimaryStringObject.allObjects();
        XCTAssertEqual(objects.count, UInt(1), "Should have 1 object");
        XCTAssertEqual((objects[0] as! SwiftPrimaryStringObject).intCol, 1, "Value should be 1");

        _ = SwiftPrimaryStringObject.createOrUpdateInDefaultRealm(withValue: ["stringCol": "string2", "intCol": 2])
        XCTAssertEqual(objects.count, UInt(2), "Should have 2 objects")

        _ = SwiftPrimaryStringObject.createOrUpdateInDefaultRealm(withValue: ["string", 3])
        XCTAssertEqual(objects.count, UInt(2), "Should have 2 objects")
        XCTAssertEqual((objects[0] as! SwiftPrimaryStringObject).intCol, 3, "Value should be 3");

        try! realm.commitWriteTransaction()
    }

    func testObjectForPrimaryKey() {
        let realm = RLMRealm.default()
        realm.beginWriteTransaction()
        _ = SwiftPrimaryStringObject.createOrUpdateInDefaultRealm(withValue: ["string", 1])

        let obj = SwiftPrimaryStringObject.object(forPrimaryKey: "string")
        XCTAssertNotNil(obj!)
        XCTAssertEqual(obj!.intCol, 1)

        realm.cancelWriteTransaction()
    }

    // if this fails (and you haven't changed the test module name), the checks
    // for swift class names and the demangling logic need to be updated
    func testNSStringFromClassDemangledTopLevelClassNames() {
        XCTAssertEqual(NSStringFromClass(OuterClass.self), "Tests.OuterClass")
    }

    // if this fails (and you haven't changed the test module name), the prefix
    // check in RLMSchema initialization needs to be updated
    func testNestedClassNameMangling() {
        XCTAssertEqual(NSStringFromClass(OuterClass.InnerClass.self), "_TtCC5Tests10OuterClass10InnerClass")
    }

}
