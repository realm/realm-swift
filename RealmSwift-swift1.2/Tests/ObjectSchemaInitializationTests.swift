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
import RealmSwift
import Realm.Private
import Realm.Dynamic
import Foundation

class ObjectSchemaInitializationTests: TestCase {
    func testAllValidTypes() {
        let object = SwiftObject()
        let objectSchema = object.objectSchema

        let noSuchCol = objectSchema["noSuchCol"]
        XCTAssertNil(noSuchCol)

        let boolCol = objectSchema["boolCol"]
        XCTAssertNotNil(boolCol)
        XCTAssertEqual(boolCol!.name, "boolCol")
        XCTAssertEqual(boolCol!.type, PropertyType.Bool)
        XCTAssertFalse(boolCol!.indexed)
        XCTAssertFalse(boolCol!.optional)
        XCTAssertNil(boolCol!.objectClassName)

        let intCol = objectSchema["intCol"]
        XCTAssertNotNil(intCol)
        XCTAssertEqual(intCol!.name, "intCol")
        XCTAssertEqual(intCol!.type, PropertyType.Int)
        XCTAssertFalse(intCol!.indexed)
        XCTAssertFalse(intCol!.optional)
        XCTAssertNil(intCol!.objectClassName)

        let floatCol = objectSchema["floatCol"]
        XCTAssertNotNil(floatCol)
        XCTAssertEqual(floatCol!.name, "floatCol")
        XCTAssertEqual(floatCol!.type, PropertyType.Float)
        XCTAssertFalse(floatCol!.indexed)
        XCTAssertFalse(floatCol!.optional)
        XCTAssertNil(floatCol!.objectClassName)

        let doubleCol = objectSchema["doubleCol"]
        XCTAssertNotNil(doubleCol)
        XCTAssertEqual(doubleCol!.name, "doubleCol")
        XCTAssertEqual(doubleCol!.type, PropertyType.Double)
        XCTAssertFalse(doubleCol!.indexed)
        XCTAssertFalse(doubleCol!.optional)
        XCTAssertNil(doubleCol!.objectClassName)

        let stringCol = objectSchema["stringCol"]
        XCTAssertNotNil(stringCol)
        XCTAssertEqual(stringCol!.name, "stringCol")
        XCTAssertEqual(stringCol!.type, PropertyType.String)
        XCTAssertFalse(stringCol!.indexed)
        XCTAssertFalse(stringCol!.optional)
        XCTAssertNil(stringCol!.objectClassName)

        let binaryCol = objectSchema["binaryCol"]
        XCTAssertNotNil(binaryCol)
        XCTAssertEqual(binaryCol!.name, "binaryCol")
        XCTAssertEqual(binaryCol!.type, PropertyType.Data)
        XCTAssertFalse(binaryCol!.indexed)
        XCTAssertFalse(binaryCol!.optional)
        XCTAssertNil(binaryCol!.objectClassName)

        let dateCol = objectSchema["dateCol"]
        XCTAssertNotNil(dateCol)
        XCTAssertEqual(dateCol!.name, "dateCol")
        XCTAssertEqual(dateCol!.type, PropertyType.Date)
        XCTAssertFalse(dateCol!.indexed)
        XCTAssertFalse(dateCol!.optional)
        XCTAssertNil(dateCol!.objectClassName)

        let objectCol = objectSchema["objectCol"]
        XCTAssertNotNil(objectCol)
        XCTAssertEqual(objectCol!.name, "objectCol")
        XCTAssertEqual(objectCol!.type, PropertyType.Object)
        XCTAssertFalse(objectCol!.indexed)
        XCTAssertTrue(objectCol!.optional)
        XCTAssertEqual(objectCol!.objectClassName!, "SwiftBoolObject")

        let arrayCol = objectSchema["arrayCol"]
        XCTAssertNotNil(arrayCol)
        XCTAssertEqual(arrayCol!.name, "arrayCol")
        XCTAssertEqual(arrayCol!.type, PropertyType.Array)
        XCTAssertFalse(arrayCol!.indexed)
        XCTAssertFalse(arrayCol!.optional)
        XCTAssertEqual(objectCol!.objectClassName!, "SwiftBoolObject")

        let dynamicArrayCol = SwiftCompanyObject().objectSchema["employees"]
        XCTAssertNotNil(dynamicArrayCol)
        XCTAssertEqual(dynamicArrayCol!.name, "employees")
        XCTAssertEqual(dynamicArrayCol!.type, PropertyType.Array)
        XCTAssertFalse(dynamicArrayCol!.indexed)
        XCTAssertFalse(arrayCol!.optional)
        XCTAssertEqual(dynamicArrayCol!.objectClassName!, "SwiftEmployeeObject")
    }

    func testInvalidObjects() {
        let schema = RLMObjectSchema(forObjectClass: SwiftFakeObjectSubclass.self) // Should be able to get a schema for a non-RLMObjectBase subclass
        XCTAssertEqual(schema.properties.count, 1)

        // FIXME - disable any and make sure this fails
        RLMObjectSchema(forObjectClass: SwiftObjectWithAnyObject.self)  // Should throw when not ignoring a property of a type we can't persist

        RLMObjectSchema(forObjectClass: SwiftObjectWithEnum.self)       // Shouldn't throw when not ignoring a property of a type we can't persist if it's not dynamic
        RLMObjectSchema(forObjectClass: SwiftObjectWithStruct.self)     // Shouldn't throw when not ignoring a property of a type we can't persist if it's not dynamic

        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithDatePrimaryKey.self), "Should throw when setting a non int/string primary key")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithNSURL.self), "Should throw when not ignoring a property of a type we can't persist")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithNonOptionalLinkProperty.self), "Should throw when not marking a link property as optional")
    }

    func testPrimaryKey() {
        XCTAssertNil(SwiftObject().objectSchema.primaryKeyProperty, "Object should default to having no primary key property")
        XCTAssertEqual(SwiftPrimaryStringObject().objectSchema.primaryKeyProperty!.name, "stringCol")
    }

    func testIgnoredProperties() {
        let schema = SwiftIgnoredPropertiesObject().objectSchema
        XCTAssertNil(schema["runtimeProperty"], "The object schema shouldn't contain ignored properties")
        XCTAssertNil(schema["runtimeDefaultProperty"], "The object schema shouldn't contain ignored properties")
        XCTAssertNil(schema["readOnlyProperty"], "The object schema shouldn't contain read-only properties")
    }

    func testIndexedProperties() {
        XCTAssertTrue(SwiftIndexedPropertiesObject().objectSchema["stringCol"]!.indexed)

        let unindexibleSchema = RLMObjectSchema(forObjectClass: SwiftObjectWithUnindexibleProperties.self)
        for propName in SwiftObjectWithUnindexibleProperties.indexedProperties() {
            XCTAssertFalse(unindexibleSchema[propName]!.indexed, "Shouldn't mark unindexible property '\(propName)' as indexed")
        }
    }

    func testOptionalProperties() {
        let schema = RLMObjectSchema(forObjectClass: SwiftOptionalObject.self)

        for prop in schema.properties {
            XCTAssertTrue((prop as! RLMProperty).optional)
        }

        let types = Set(map(schema.properties) { prop in
            (prop as! RLMProperty).type
        })

#if REALM_ENABLE_NULL
        XCTAssertEqual(types, Set([.String, .String, .Data, .Date, .Object, .Int, .Float, .Double, .Bool]))
#else
        XCTAssertEqual(types, Set([.Object]))
#endif
    }

    func testImplicitlyUnwrappedOptionalsAreParsedAsOptionals() {
        let schema = SwiftImplicitlyUnwrappedOptionalObject().objectSchema
        XCTAssertTrue(schema["optObjectCol"]!.optional)
#if REALM_ENABLE_NULL
        XCTAssertTrue(schema["optNSStringCol"]!.optional)
        XCTAssertTrue(schema["optStringCol"]!.optional)
        XCTAssertTrue(schema["optBinaryCol"]!.optional)
        XCTAssertTrue(schema["optDateCol"]!.optional)
#endif
    }
}

class SwiftFakeObject : NSObject {
    dynamic class func primaryKey() -> String! { return nil }
    dynamic class func ignoredProperties() -> [String] { return [] }
    dynamic class func indexedProperties() -> [String] { return [] }
}

class SwiftObjectWithNSURL : SwiftFakeObject {
    dynamic var URL = NSURL(string: "http://realm.io")!
}

class SwiftObjectWithAnyObject : SwiftFakeObject {
    dynamic var anyObject: AnyObject = NSString(string: "")
}

enum SwiftEnum {
    case Case1
    case Case2
}

class SwiftObjectWithEnum : SwiftFakeObject {
    var swiftEnum = SwiftEnum.Case1
}

class SwiftObjectWithStruct : SwiftFakeObject {
    var swiftStruct = SortDescriptor(property: "prop")
}

class SwiftObjectWithDatePrimaryKey : SwiftFakeObject {
    dynamic var date = NSDate()

    dynamic override class func primaryKey() -> String! {
        return "date"
    }
}

class SwiftFakeObjectSubclass : SwiftFakeObject {
    dynamic var dateCol = NSDate()
}

class SwiftObjectWithUnindexibleProperties : SwiftFakeObject {
    dynamic var boolCol = false
    dynamic var intCol = 123
    dynamic var floatCol = 1.23 as Float
    dynamic var doubleCol = 12.3
    dynamic var binaryCol = "a".dataUsingEncoding(NSUTF8StringEncoding)!
    dynamic var dateCol = NSDate(timeIntervalSince1970: 1)
    dynamic var objectCol: SwiftBoolObject? = SwiftBoolObject()
    let arrayCol = List<SwiftBoolObject>()

    dynamic override class func indexedProperties() -> [String] {
        return ["boolCol", "intCol", "floatCol", "doubleCol", "binaryCol", "dateCol", "objectCol", "arrayCol"]
    }
}

class SwiftObjectWithNonNullableOptionalProperties: SwiftFakeObject {
    dynamic var optDateCol: NSDate?
}

class SwiftObjectWithNonOptionalLinkProperty : SwiftFakeObject {
    dynamic var objectCol = SwiftBoolObject()
}
