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

#if swift(>=3.0)

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

    override class func defaultPropertyValues() -> [AnyHashable : Any]? {
        return ["intCol": 2]
    }
}

class SwiftOptionalNumberObject: RLMObject {
    dynamic var intCol: NSNumber? = .int(1)
    dynamic var floatCol: NSNumber? = .float(2.2)
    dynamic var doubleCol: NSNumber? = .double(3.3)
    dynamic var boolCol: NSNumber? = true
}

class SwiftNilDefaultOptionalNumberObject: RLMObject {
    dynamic var intCol: NSNumber? = .int(nil)
    dynamic var floatCol: NSNumber? = .float(nil)
    dynamic var doubleCol: NSNumber? = .double(nil)
    dynamic var boolCol: NSNumber? = .bool(nil)
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
        XCTAssertEqual((obj.arrayCol.firstObject() as? SwiftBoolObject)!.boolCol, true, "should be true")
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

    func testNilDefaultOptionalNumberObject() {
        let realm = realmWithTestPath()

        // Ensure that the static methods return NSNumbers when not passed nil
        XCTAssertEqual(1, NSNumber.int(1))
        XCTAssertEqual(2.2 as Float as NSNumber, NSNumber.float(2.2))
        XCTAssertEqual(3.3, NSNumber.double(3.3))
        XCTAssertEqual(true, NSNumber.bool(true))

        // Ensure the object schema was correclty parsed
        let objectSchema = SwiftNilDefaultOptionalNumberObject.sharedSchema()!
        XCTAssertEqual(RLMPropertyType.int,    objectSchema["intCol"]?.type)
        XCTAssertEqual(RLMPropertyType.float,  objectSchema["floatCol"]?.type)
        XCTAssertEqual(RLMPropertyType.double, objectSchema["doubleCol"]?.type)
        XCTAssertEqual(RLMPropertyType.bool,   objectSchema["boolCol"]?.type)

        // Ensure the default initialized object has nil properties
        let empty = SwiftNilDefaultOptionalNumberObject()
        XCTAssertNil(empty.intCol)
        XCTAssertNil(empty.floatCol)
        XCTAssertNil(empty.doubleCol)
        XCTAssertNil(empty.boolCol)

        // Ensure the properties can be initialized to non-nil values
        let initialized = SwiftNilDefaultOptionalNumberObject(value: [1, 2.2 as Float, 3.3, true])
        XCTAssertEqual(.int(1),      initialized.intCol)
        XCTAssertEqual(.float(2.2),  initialized.floatCol)
        XCTAssertEqual(.double(3.3), initialized.doubleCol)
        XCTAssertEqual(.bool(true),  initialized.boolCol)

        // Ensure unmanaged properties can be set back to nil by setting `RLMNumericNull`
        let unmanaged = SwiftNilDefaultOptionalNumberObject(value: [1, 2.2 as Float, 3.3, true])
        unmanaged.intCol    = .int(nil)
        unmanaged.floatCol  = .float(nil)
        unmanaged.doubleCol = .double(nil)
        unmanaged.boolCol   = .bool(nil)
        XCTAssertNil(unmanaged.intCol)
        XCTAssertNil(unmanaged.floatCol)
        XCTAssertNil(unmanaged.doubleCol)
        XCTAssertNil(unmanaged.boolCol)

        // Ensure managed properties can be set back to nil by setting `RLMNumericNull`
        let managed = SwiftNilDefaultOptionalNumberObject(value: [1, 2.2 as Float, 3.3, true])
        try! realm.transaction {
            realm.add(managed)
            managed.intCol    = .int(nil)
            managed.floatCol  = .float(nil)
            managed.doubleCol = .double(nil)
            managed.boolCol   = .bool(nil)
        }
        XCTAssertNil(managed.intCol)
        XCTAssertNil(managed.floatCol)
        XCTAssertNil(managed.doubleCol)
        XCTAssertNil(managed.boolCol)
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
        XCTAssertEqual(SwiftObject.className(), "SwiftObject", "Calling className() on Swift class should return demangled name")
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

#else

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

class SwiftOptionalNumberObject: RLMObject {
    dynamic var intCol: NSNumber? = 1
    dynamic var floatCol: NSNumber? = 2.2 as Float
    dynamic var doubleCol: NSNumber? = 3.3 as Double
    dynamic var boolCol: NSNumber? = true
}

class SwiftNilDefaultOptionalNumberObject: RLMObject {
    dynamic var intCol: NSNumber? = .int(nil)
    dynamic var floatCol: NSNumber? = .float(nil)
    dynamic var doubleCol: NSNumber? = .double(nil)
    dynamic var boolCol: NSNumber? = .bool(nil)
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
        try! realm.commitWriteTransaction()

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
        try! realm.commitWriteTransaction()

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
        try! realm.commitWriteTransaction()

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
        try! realm.commitWriteTransaction()

        // ensure creation in proper table
        XCTAssertEqual(UInt(1), SwiftStringObjectSubclass.allObjects().count)
        XCTAssertEqual(UInt(1), SwiftStringObject.allObjects().count)

        try! realm.transactionWithBlock {
            // create self referencing subclass
            let sub = SwiftSelfRefrencingSubclass.createInDefaultRealmWithValue(["string", []])
            let sub2 = SwiftSelfRefrencingSubclass()
            sub.objects.addObject(sub2)
        }
    }

    func testOptionalNSNumberProperties() {
        let realm = realmWithTestPath()
        let no = SwiftOptionalNumberObject()
        XCTAssertEqual([.Int, .Float, .Double, .Bool], no.objectSchema.properties.map { $0.type })

        XCTAssertEqual(1, no.intCol!)
        XCTAssertEqual(2.2 as Float, no.floatCol!)
        XCTAssertEqual(3.3, no.doubleCol!)
        XCTAssertEqual(true, no.boolCol!)

        try! realm.transactionWithBlock {
            realm.addObject(no)
            no.intCol = nil
            no.floatCol = nil
            no.doubleCol = nil
            no.boolCol = nil
        }

        XCTAssertNil(no.intCol)
        XCTAssertNil(no.floatCol)
        XCTAssertNil(no.doubleCol)
        XCTAssertNil(no.boolCol)

        try! realm.transactionWithBlock {
            no.intCol = 1.1
            no.floatCol = 2.2 as Float
            no.doubleCol = 3.3
            no.boolCol = false
        }

        XCTAssertEqual(1, no.intCol!)
        XCTAssertEqual(2.2 as Float, no.floatCol!)
        XCTAssertEqual(3.3, no.doubleCol!)
        XCTAssertEqual(false, no.boolCol!)
    }

    func testNilDefaultOptionalNumberObject() {
        let realm = realmWithTestPath()

        // Ensure that the static methods return NSNumbers when not passed nil
        XCTAssertEqual(1, NSNumber.int(1))
        XCTAssertEqual(2.2 as Float as NSNumber, NSNumber.float(2.2))
        XCTAssertEqual(3.3, NSNumber.double(3.3))
        XCTAssertEqual(true, NSNumber.bool(true))

        // Ensure the object schema was correclty parsed
        let objectSchema = SwiftNilDefaultOptionalNumberObject.sharedSchema()!
        XCTAssertEqual(RLMPropertyType.Int,    objectSchema["intCol"]?.type)
        XCTAssertEqual(RLMPropertyType.Float,  objectSchema["floatCol"]?.type)
        XCTAssertEqual(RLMPropertyType.Double, objectSchema["doubleCol"]?.type)
        XCTAssertEqual(RLMPropertyType.Bool,   objectSchema["boolCol"]?.type)

        // Ensure the default initialized object has nil properties
        let empty = SwiftNilDefaultOptionalNumberObject()
        XCTAssertNil(empty.intCol)
        XCTAssertNil(empty.floatCol)
        XCTAssertNil(empty.doubleCol)
        XCTAssertNil(empty.boolCol)

        // Ensure the properties can be initialized to non-nil values
        let initialized = SwiftNilDefaultOptionalNumberObject(value: [1, 2.2 as Float, 3.3, true])
        XCTAssertEqual(.int(1),      initialized.intCol)
        XCTAssertEqual(.float(2.2),  initialized.floatCol)
        XCTAssertEqual(.double(3.3), initialized.doubleCol)
        XCTAssertEqual(.bool(true),  initialized.boolCol)

        // Ensure unmanaged properties can be set back to nil by setting `RLMNumericNull`
        let unmanaged = SwiftNilDefaultOptionalNumberObject(value: [1, 2.2 as Float, 3.3, true])
        unmanaged.intCol    = .int(nil)
        unmanaged.floatCol  = .float(nil)
        unmanaged.doubleCol = .double(nil)
        unmanaged.boolCol   = .bool(nil)
        XCTAssertNil(unmanaged.intCol)
        XCTAssertNil(unmanaged.floatCol)
        XCTAssertNil(unmanaged.doubleCol)
        XCTAssertNil(unmanaged.boolCol)

        // Ensure managed properties can be set back to nil by setting `RLMNumericNull`
        let managed = SwiftNilDefaultOptionalNumberObject(value: [1, 2.2 as Float, 3.3, true])
        try! realm.transactionWithBlock {
            realm.addObject(managed)
            managed.intCol    = .int(nil)
            managed.floatCol  = .float(nil)
            managed.doubleCol = .double(nil)
            managed.boolCol   = .bool(nil)
        }
        XCTAssertNil(managed.intCol)
        XCTAssertNil(managed.floatCol)
        XCTAssertNil(managed.doubleCol)
        XCTAssertNil(managed.boolCol)
    }

    func testOptionalSwiftProperties() {
        let realm = realmWithTestPath()
        try! realm.transactionWithBlock { realm.addObject(SwiftOptionalObject()) }

        let firstObj = SwiftOptionalObject.allObjectsInRealm(realm).firstObject() as! SwiftOptionalObject
        XCTAssertNil(firstObj.optObjectCol)
        XCTAssertNil(firstObj.optStringCol)
        XCTAssertNil(firstObj.optNSStringCol)
        XCTAssertNil(firstObj.optBinaryCol)
        XCTAssertNil(firstObj.optDateCol)

        try! realm.transactionWithBlock {
            firstObj.optObjectCol = SwiftBoolObject()
            firstObj.optObjectCol!.boolCol = true

            firstObj.optStringCol = "Hi!"
            firstObj.optNSStringCol = "Hi!"
            firstObj.optBinaryCol = NSData(bytes: "hi", length: 2)
            firstObj.optDateCol = NSDate(timeIntervalSinceReferenceDate: 10)
        }
        XCTAssertTrue(firstObj.optObjectCol!.boolCol)
        XCTAssertEqual(firstObj.optStringCol!, "Hi!")
        XCTAssertEqual(firstObj.optNSStringCol!, "Hi!")
        XCTAssertEqual(firstObj.optBinaryCol!, NSData(bytes: "hi", length: 2))
        XCTAssertEqual(firstObj.optDateCol!,  NSDate(timeIntervalSinceReferenceDate: 10))

        try! realm.transactionWithBlock {
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
        try! realm.commitWriteTransaction()
    }

    func testClassExtension() {
        let realm = realmWithTestPath()

        realm.beginWriteTransaction()
        let bObject = BaseClassStringObject()
        bObject.intCol = 1
        bObject.stringCol = "stringVal"
        realm.addObject(bObject)
        try! realm.commitWriteTransaction()

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

        try! realm.commitWriteTransaction()
    }

    // if this fails (and you haven't changed the test module name), the checks
    // for swift class names and the demangling logic need to be updated
    func testNSStringFromClassDemangledTopLevelClassNames() {
        XCTAssertEqual(NSStringFromClass(OuterClass), "Tests.OuterClass")
    }

    // if this fails (and you haven't changed the test module name), the prefix
    // check in RLMSchema initialization needs to be updated
    func testNestedClassNameMangling() {
        XCTAssertEqual(NSStringFromClass(OuterClass.InnerClass.self), "_TtCC5Tests10OuterClass10InnerClass")
    }

}

#endif
