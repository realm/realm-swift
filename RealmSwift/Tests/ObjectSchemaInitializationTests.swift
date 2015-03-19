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
import Foundation

class ObjectSchemaInitializationTests: TestCase {
    func testAllValidTypes() {
        let object = AllTypesObject()
        let objectSchema = object.objectSchema

        let noSuchCol = objectSchema["noSuchCol"]
        XCTAssertNil(noSuchCol)

        let boolCol = objectSchema["boolCol"]
        XCTAssertNotNil(boolCol)
        XCTAssertEqual(boolCol!.name, "boolCol")
        XCTAssertEqual(boolCol!.type, PropertyType.Bool)
        XCTAssertFalse(boolCol!.indexed)
        XCTAssertNil(boolCol!.objectClassName)

        let intCol = objectSchema["intCol"]
        XCTAssertNotNil(intCol)
        XCTAssertEqual(intCol!.name, "intCol")
        XCTAssertEqual(intCol!.type, PropertyType.Int)
        XCTAssertFalse(intCol!.indexed)
        XCTAssertNil(intCol!.objectClassName)

        let floatCol = objectSchema["floatCol"]
        XCTAssertNotNil(floatCol)
        XCTAssertEqual(floatCol!.name, "floatCol")
        XCTAssertEqual(floatCol!.type, PropertyType.Float)
        XCTAssertFalse(floatCol!.indexed)
        XCTAssertNil(floatCol!.objectClassName)

        let doubleCol = objectSchema["doubleCol"]
        XCTAssertNotNil(doubleCol)
        XCTAssertEqual(doubleCol!.name, "doubleCol")
        XCTAssertEqual(doubleCol!.type, PropertyType.Double)
        XCTAssertFalse(doubleCol!.indexed)
        XCTAssertNil(doubleCol!.objectClassName)

        let stringCol = objectSchema["stringCol"]
        XCTAssertNotNil(stringCol)
        XCTAssertEqual(stringCol!.name, "stringCol")
        XCTAssertEqual(stringCol!.type, PropertyType.String)
        XCTAssertFalse(stringCol!.indexed)
        XCTAssertNil(stringCol!.objectClassName)

        let binaryCol = objectSchema["binaryCol"]
        XCTAssertNotNil(binaryCol)
        XCTAssertEqual(binaryCol!.name, "binaryCol")
        XCTAssertEqual(binaryCol!.type, PropertyType.Data)
        XCTAssertFalse(binaryCol!.indexed)
        XCTAssertNil(binaryCol!.objectClassName)

        let dateCol = objectSchema["dateCol"]
        XCTAssertNotNil(dateCol)
        XCTAssertEqual(dateCol!.name, "dateCol")
        XCTAssertEqual(dateCol!.type, PropertyType.Date)
        XCTAssertFalse(dateCol!.indexed)
        XCTAssertNil(dateCol!.objectClassName)

        let objectCol = objectSchema["objectCol"]
        XCTAssertNotNil(objectCol)
        XCTAssertEqual(objectCol!.name, "objectCol")
        XCTAssertEqual(objectCol!.type, PropertyType.Object)
        XCTAssertFalse(objectCol!.indexed)
        XCTAssertEqual(objectCol!.objectClassName!, "BoolObject")

        let arrayCol = objectSchema["arrayCol"]
        XCTAssertNotNil(arrayCol)
        XCTAssertEqual(arrayCol!.name, "arrayCol")
        XCTAssertEqual(arrayCol!.type, PropertyType.Array)
        XCTAssertFalse(arrayCol!.indexed)
        XCTAssertEqual(objectCol!.objectClassName!, "BoolObject")
    }

    func testInvalidObjects() {
        let schema = RLMObjectSchema(forObjectClass: FakeObjectSubclass.self) // Should be able to get a schema for a non-RLMObjectBase subclass
        XCTAssertEqual(schema.properties.count, 1)

        // FIXME - disable any and make sure this fails
        RLMObjectSchema(forObjectClass: AllTypesObjectWithAnyObject.self)  // Should throw when not ignoring a property of a type we can't persist

        RLMObjectSchema(forObjectClass: AllTypesObjectWithEnum.self)       // Shouldn't throw when not ignoring a property of a type we can't persist if it's not dynamic
        RLMObjectSchema(forObjectClass: AllTypesObjectWithStruct.self)     // Shouldn't throw when not ignoring a property of a type we can't persist if it's not dynamic

        assertThrows(RLMObjectSchema(forObjectClass: AllTypesObjectWithDatePrimaryKey.self), "Should throw when setting a non int/string primary key")
        assertThrows(RLMObjectSchema(forObjectClass: AllTypesObjectWithNSURL.self), "Should throw when not ignoring a property of a type we can't persist")
    }

    func testPrimaryKey() {
        XCTAssertNil(AllTypesObject().objectSchema.primaryKeyProperty, "Object should default to having no primary key property")
        XCTAssertEqual(PrimaryStringObject().objectSchema.primaryKeyProperty!.name, "stringCol")
    }

    func testIgnoredProperties() {
        let schema = IgnoredPropertiesObject().objectSchema
        XCTAssertNil(schema["runtimeProperty"], "The object schema shouldn't contain ignored properties")
        XCTAssertNil(schema["runtimeDefaultProperty"], "The object schema shouldn't contain ignored properties")
        XCTAssertNil(schema["readOnlyProperty"], "The object schema shouldn't contain read-only properties")
    }

    func testIndexedProperties() {
        XCTAssertTrue(IndexedPropertiesObject().objectSchema["stringCol"]!.indexed)

        let unindexibleSchema = RLMObjectSchema(forObjectClass: AllTypesObjectWithUnindexibleProperties.self)
        for propName in AllTypesObjectWithUnindexibleProperties.indexedProperties() {
            XCTAssertFalse(unindexibleSchema[propName]!.indexed, "Shouldn't mark unindexible property '\(propName)' as indexed")
        }
    }
}

class FakeObject : NSObject {
    dynamic class func primaryKey() -> String! { return nil }
    dynamic class func ignoredProperties() -> [String] { return [] }
    dynamic class func indexedProperties() -> [String] { return [] }
}

class AllTypesObjectWithNSURL : FakeObject {
    dynamic var URL = NSURL(string: "http://realm.io")!
}

class AllTypesObjectWithAnyObject : FakeObject {
    dynamic var anyObject: AnyObject = NSString(string: "")
}

enum Enum {
    case Case1
    case Case2
}

class AllTypesObjectWithEnum : FakeObject {
    var swiftEnum = Enum.Case1
}

class AllTypesObjectWithStruct : FakeObject {
    var swiftStruct = SortDescriptor(property: "prop")
}

class AllTypesObjectWithDatePrimaryKey : FakeObject {
    dynamic var date = NSDate()

    dynamic override class func primaryKey() -> String! {
        return "date"
    }
}

class FakeObjectSubclass : FakeObject {
    dynamic var dateCol = NSDate()
}

class AllTypesObjectWithUnindexibleProperties : FakeObject {
    dynamic var boolCol = false
    dynamic var intCol = 123
    dynamic var floatCol = 1.23 as Float
    dynamic var doubleCol = 12.3
    dynamic var binaryCol = "a".dataUsingEncoding(NSUTF8StringEncoding)!
    dynamic var dateCol = NSDate(timeIntervalSince1970: 1)
    dynamic var objectCol = BoolObject()
    let arrayCol = List<BoolObject>()

    dynamic override class func indexedProperties() -> [String] {
        return ["boolCol", "intCol", "floatCol", "doubleCol", "binaryCol", "dateCol", "objectCol", "arrayCol"]
    }
}

