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
import Foundation
import Realm.Private
import Realm.Dynamic

#if swift(>=3.0)

class SwiftDynamicTests: RLMTestCase {

    // Swift models

    func testDynamicRealmExists() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm(url

                : RLMTestRealmURL())
            realm.beginWriteTransaction()
            _ = SwiftDynamicObject.create(in: realm, withValue: ["column1", 1])
            _ = SwiftDynamicObject.create(in: realm, withValue: ["column2", 2])
            try! realm.commitWriteTransaction()
        }
        let dyrealm = realm(withTestPathAndSchema: nil)
        XCTAssertNotNil(dyrealm, "realm should not be nil")

        // verify schema
        let dynSchema = dyrealm.schema[SwiftDynamicObject.className()]
        XCTAssertNotNil(dynSchema, "Should be able to get object schema dynamically")
        XCTAssertEqual(dynSchema.properties.count, Int(2))
        XCTAssertEqual(dynSchema.properties[0].name, "stringCol")
        XCTAssertEqual(dynSchema.properties[1].type, RLMPropertyType.int)

        // verify object type
        let array = SwiftDynamicObject.allObjects(in: dyrealm)
        XCTAssertEqual(array.count, UInt(2))
        XCTAssertEqual(array.objectClassName, SwiftDynamicObject.className())
    }

    func testDynamicProperties() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm(url: RLMTestRealmURL())
            realm.beginWriteTransaction()
            _ = SwiftDynamicObject.create(in: realm, withValue: ["column1", 1])
            _ = SwiftDynamicObject.create(in: realm, withValue: ["column2", 2])
            try! realm.commitWriteTransaction()
        }

        // verify properties
        let dyrealm = realm(withTestPathAndSchema: nil)
        let array = dyrealm.allObjects("SwiftDynamicObject")!

        XCTAssertTrue(array[0]["intCol"] as! NSNumber == 1)
        XCTAssertTrue(array[1]["stringCol"] as! String == "column2")
    }

    // Objective-C models

    func testDynamicRealmExists_objc() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm(url: RLMTestRealmURL())
            realm.beginWriteTransaction()
            _ = DynamicObject.create(in: realm, withValue: ["column1", 1])
            _ = DynamicObject.create(in: realm, withValue: ["column2", 2])
            try! realm.commitWriteTransaction()
        }
        let dyrealm = realm(withTestPathAndSchema: nil)
        XCTAssertNotNil(dyrealm, "realm should not be nil")

        // verify schema
        let dynSchema = dyrealm.schema[DynamicObject.className()]
        XCTAssertNotNil(dynSchema, "Should be able to get object schema dynamically")
        XCTAssertTrue(dynSchema.properties.count == 2)
        XCTAssertTrue(dynSchema.properties[0].name == "stringCol")
        XCTAssertTrue(dynSchema.properties[1].type == RLMPropertyType.int)

        // verify object type
        let array = DynamicObject.allObjects(in: dyrealm)
        XCTAssertEqual(array.count, UInt(2))
        XCTAssertEqual(array.objectClassName, DynamicObject.className())
    }

    func testDynamicProperties_objc() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm(url: RLMTestRealmURL())
            realm.beginWriteTransaction()
            _ = DynamicObject.create(in: realm, withValue: ["column1", 1])
            _ = DynamicObject.create(in: realm, withValue: ["column2", 2])
            try! realm.commitWriteTransaction()
        }

        // verify properties
        let dyrealm = realm(withTestPathAndSchema: nil)
        let array = dyrealm.allObjects("DynamicObject")!

        XCTAssertTrue(array[0]["intCol"] as! NSNumber == 1)
        XCTAssertTrue(array[1]["stringCol"] as! String == "column2")
    }

    // these helper functions make the below test not take five minutes to compile
    // I suspect a type inference bug
    func Ni(_ x: Int) -> AnyObject {
        return NSNumber(value: x)
    }

    func Nb(_ x: Bool) -> AnyObject {
        return NSNumber(value: x)
    }

    func Nd(_ x: Double) -> AnyObject {
        return NSNumber(value: x)
    }

    func Nf(_ x: Float) -> AnyObject {
        return NSNumber(value: x)
    }

    func testDynamicTypes_objc() {
        let date = NSDate(timeIntervalSince1970: 100000)
        let data = "a".data(using: String.Encoding.utf8)!
        let obj1 = [Nb(true), Ni(1), Nf(1.1), Nd(1.11), "string" as NSString,
            data as AnyObject, date, Nb(true), Ni(11), NSNull()] as NSArray

        let obj = StringObject()
        obj.stringCol = "string"

        let data2 = "b".data(using: String.Encoding.utf8)!
        let obj2 = [Nb(false), Ni(2), Nf(2.2), Nd(2.22), "string2" as NSString,
            data2 as AnyObject, date, Nb(false), Ni(22), obj] as NSArray

        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = self.realmWithTestPath()
            realm.beginWriteTransaction()
            _ = AllTypesObject.create(in: realm, withValue: obj1)
            _ = AllTypesObject.create(in: realm, withValue: obj2)
            try! realm.commitWriteTransaction()
        }

        // verify properties
        let dyrealm = realm(withTestPathAndSchema: nil)
        let results = dyrealm.allObjects(AllTypesObject.className())!
        XCTAssertEqual(results.count, UInt(2))
        let robj1 = results[0]
        let robj2 = results[1]

        let schema = dyrealm.schema[AllTypesObject.className()]
        for idx in 0..<obj1.count - 1 {
            let prop = schema.properties[idx]
            XCTAssertTrue((obj1[idx] as AnyObject).isEqual(robj1[prop.name]))
            XCTAssertTrue((obj2[idx] as AnyObject).isEqual(robj2[prop.name]))
        }

        // check sub object type
        XCTAssertTrue(schema.properties[9].objectClassName! == "StringObject")

        // check object equality
        XCTAssertNil(robj1["objectCol"], "object should be nil")
        XCTAssertTrue((robj2["objectCol"] as! RLMObject)["stringCol"] as! String == "string")
    }
}

#else

class SwiftDynamicTests: RLMTestCase {

    // Swift models

    func testDynamicRealmExists() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm(URL: RLMTestRealmURL())
            realm.beginWriteTransaction()
            SwiftDynamicObject.createInRealm(realm, withValue: ["column1", 1])
            SwiftDynamicObject.createInRealm(realm, withValue: ["column2", 2])
            try! realm.commitWriteTransaction()
        }
        let dyrealm = realmWithTestPathAndSchema(nil)
        XCTAssertNotNil(dyrealm, "realm should not be nil")
        XCTAssertTrue(dyrealm.isKindOfClass(RLMRealm))

        // verify schema
        let dynSchema = dyrealm.schema[SwiftDynamicObject.className()]
        XCTAssertNotNil(dynSchema, "Should be able to get object schema dynamically")
        XCTAssertEqual(dynSchema.properties.count, Int(2))
        XCTAssertEqual(dynSchema.properties[0].name, "stringCol")
        XCTAssertEqual(dynSchema.properties[1].type, RLMPropertyType.Int)

        // verify object type
        let array = SwiftDynamicObject.allObjectsInRealm(dyrealm)
        XCTAssertEqual(array.count, UInt(2))
        XCTAssertEqual(array.objectClassName, SwiftDynamicObject.className())
    }

    func testDynamicProperties() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm(URL: RLMTestRealmURL())
            realm.beginWriteTransaction()
            SwiftDynamicObject.createInRealm(realm, withValue: ["column1", 1])
            SwiftDynamicObject.createInRealm(realm, withValue: ["column2", 2])
            try! realm.commitWriteTransaction()
        }

        // verify properties
        let dyrealm = realmWithTestPathAndSchema(nil)
        let array = dyrealm.allObjects("SwiftDynamicObject")

        XCTAssertTrue(array[0]["intCol"] as! NSNumber == 1)
        XCTAssertTrue(array[1]["stringCol"] as! String == "column2")
    }

    // Objective-C models

    func testDynamicRealmExists_objc() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm(URL: RLMTestRealmURL())
            realm.beginWriteTransaction()
            DynamicObject.createInRealm(realm, withValue: ["column1", 1])
            DynamicObject.createInRealm(realm, withValue: ["column2", 2])
            try! realm.commitWriteTransaction()
        }
        let dyrealm = realmWithTestPathAndSchema(nil)
        XCTAssertNotNil(dyrealm, "realm should not be nil")

        // verify schema
        let dynSchema = dyrealm.schema[DynamicObject.className()]
        XCTAssertNotNil(dynSchema, "Should be able to get object schema dynamically")
        XCTAssertTrue(dynSchema.properties.count == 2)
        XCTAssertTrue(dynSchema.properties[0].name == "stringCol")
        XCTAssertTrue(dynSchema.properties[1].type == RLMPropertyType.Int)

        // verify object type
        let array = DynamicObject.allObjectsInRealm(dyrealm)
        XCTAssertEqual(array.count, UInt(2))
        XCTAssertEqual(array.objectClassName, DynamicObject.className())
    }

    func testDynamicProperties_objc() {
        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = RLMRealm(URL: RLMTestRealmURL())
            realm.beginWriteTransaction()
            DynamicObject.createInRealm(realm, withValue: ["column1", 1])
            DynamicObject.createInRealm(realm, withValue: ["column2", 2])
            try! realm.commitWriteTransaction()
        }

        // verify properties
        let dyrealm = realmWithTestPathAndSchema(nil)
        let array = dyrealm.allObjects("DynamicObject")

        XCTAssertTrue(array[0]["intCol"] as! NSNumber == 1)
        XCTAssertTrue(array[1]["stringCol"] as! String == "column2")
    }

    // these helper functions make the below test not take five minutes to compile
    // I suspect a type inference bug
    func Ni(x: Int) -> AnyObject {
        return NSNumber(integer: x)
    }

    func Nb(x: Bool) -> AnyObject {
        return NSNumber(bool: x)
    }

    func Nd(x: Double) -> AnyObject {
        return NSNumber(double: x)
    }

    func Nf(x: Float) -> AnyObject {
        return NSNumber(float: x)
    }

    func testDynamicTypes_objc() {
        let date = NSDate(timeIntervalSince1970: 100000)
        let data = "a".dataUsingEncoding(NSUTF8StringEncoding)!
        let obj1 = [Nb(true), Ni(1), Nf(1.1), Nd(1.11), "string" as NSString,
            data as AnyObject, date, Nb(true), Ni(11), NSNull()] as NSArray

        let obj = StringObject()
        obj.stringCol = "string"

        let data2 = "b".dataUsingEncoding(NSUTF8StringEncoding)!
        let obj2 = [Nb(false), Ni(2), Nf(2.2), Nd(2.22), "string2" as NSString,
            data2 as AnyObject, date, Nb(false), Ni(22), obj] as NSArray

        autoreleasepool {
            // open realm in autoreleasepool to create tables and then dispose
            let realm = self.realmWithTestPath()
            realm.beginWriteTransaction()
            AllTypesObject.createInRealm(realm, withValue: obj1)
            AllTypesObject.createInRealm(realm, withValue: obj2)
            try! realm.commitWriteTransaction()
        }

        // verify properties
        let dyrealm = realmWithTestPathAndSchema(nil)
        let results = dyrealm.allObjects(AllTypesObject.className())
        XCTAssertEqual(results.count, UInt(2))
        let robj1 = results[0]
        let robj2 = results[1]

        let schema = dyrealm.schema[AllTypesObject.className()]
        for idx in 0..<obj1.count - 1 {
            let prop = schema.properties[idx]
            XCTAssertTrue(obj1[idx].isEqual(robj1[prop.name]))
            XCTAssertTrue(obj2[idx].isEqual(robj2[prop.name]))
        }

        // check sub object type
        XCTAssertTrue(schema.properties[9].objectClassName! == "StringObject")

        // check object equality
        XCTAssertNil(robj1["objectCol"], "object should be nil")
        XCTAssertTrue((robj2["objectCol"] as! RLMObject)["stringCol"] as! String == "string")
    }
}

#endif
