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
        XCTAssertEqual(boolCol!.type, PropertyType.bool)
        XCTAssertFalse(boolCol!.isIndexed)
        XCTAssertFalse(boolCol!.isOptional)
        XCTAssertNil(boolCol!.objectClassName)

        let intCol = objectSchema["intCol"]
        XCTAssertNotNil(intCol)
        XCTAssertEqual(intCol!.name, "intCol")
        XCTAssertEqual(intCol!.type, PropertyType.int)
        XCTAssertFalse(intCol!.isIndexed)
        XCTAssertFalse(intCol!.isOptional)
        XCTAssertNil(intCol!.objectClassName)

        let floatCol = objectSchema["floatCol"]
        XCTAssertNotNil(floatCol)
        XCTAssertEqual(floatCol!.name, "floatCol")
        XCTAssertEqual(floatCol!.type, PropertyType.float)
        XCTAssertFalse(floatCol!.isIndexed)
        XCTAssertFalse(floatCol!.isOptional)
        XCTAssertNil(floatCol!.objectClassName)

        let doubleCol = objectSchema["doubleCol"]
        XCTAssertNotNil(doubleCol)
        XCTAssertEqual(doubleCol!.name, "doubleCol")
        XCTAssertEqual(doubleCol!.type, PropertyType.double)
        XCTAssertFalse(doubleCol!.isIndexed)
        XCTAssertFalse(doubleCol!.isOptional)
        XCTAssertNil(doubleCol!.objectClassName)

        let stringCol = objectSchema["stringCol"]
        XCTAssertNotNil(stringCol)
        XCTAssertEqual(stringCol!.name, "stringCol")
        XCTAssertEqual(stringCol!.type, PropertyType.string)
        XCTAssertFalse(stringCol!.isIndexed)
        XCTAssertFalse(stringCol!.isOptional)
        XCTAssertNil(stringCol!.objectClassName)

        let binaryCol = objectSchema["binaryCol"]
        XCTAssertNotNil(binaryCol)
        XCTAssertEqual(binaryCol!.name, "binaryCol")
        XCTAssertEqual(binaryCol!.type, PropertyType.data)
        XCTAssertFalse(binaryCol!.isIndexed)
        XCTAssertFalse(binaryCol!.isOptional)
        XCTAssertNil(binaryCol!.objectClassName)

        let dateCol = objectSchema["dateCol"]
        XCTAssertNotNil(dateCol)
        XCTAssertEqual(dateCol!.name, "dateCol")
        XCTAssertEqual(dateCol!.type, PropertyType.date)
        XCTAssertFalse(dateCol!.isIndexed)
        XCTAssertFalse(dateCol!.isOptional)
        XCTAssertNil(dateCol!.objectClassName)

        let objectCol = objectSchema["objectCol"]
        XCTAssertNotNil(objectCol)
        XCTAssertEqual(objectCol!.name, "objectCol")
        XCTAssertEqual(objectCol!.type, PropertyType.object)
        XCTAssertFalse(objectCol!.isIndexed)
        XCTAssertTrue(objectCol!.isOptional)
        XCTAssertEqual(objectCol!.objectClassName!, "SwiftBoolObject")

        let arrayCol = objectSchema["arrayCol"]
        XCTAssertNotNil(arrayCol)
        XCTAssertEqual(arrayCol!.name, "arrayCol")
        XCTAssertEqual(arrayCol!.type, PropertyType.object)
        XCTAssertTrue(arrayCol!.isArray)
        XCTAssertFalse(arrayCol!.isIndexed)
        XCTAssertFalse(arrayCol!.isOptional)
        XCTAssertEqual(objectCol!.objectClassName!, "SwiftBoolObject")

        let dynamicArrayCol = SwiftCompanyObject().objectSchema["employees"]
        XCTAssertNotNil(dynamicArrayCol)
        XCTAssertEqual(dynamicArrayCol!.name, "employees")
        XCTAssertEqual(dynamicArrayCol!.type, PropertyType.object)
        XCTAssertTrue(dynamicArrayCol!.isArray)
        XCTAssertFalse(dynamicArrayCol!.isIndexed)
        XCTAssertFalse(arrayCol!.isOptional)
        XCTAssertEqual(dynamicArrayCol!.objectClassName!, "SwiftEmployeeObject")
    }

    func testInvalidObjects() {
        // Should be able to get a schema for a non-RLMObjectBase subclass
        let schema = RLMObjectSchema(forObjectClass: SwiftFakeObjectSubclass.self)
        XCTAssertEqual(schema.properties.count, 1)

        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithAnyObject.self),
                     "Should throw when not ignoring a property of a type we can't persist")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithStringArray.self),
                     "Should throw when not ignoring a property of a type we can't persist")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithOptionalStringArray.self),
                     "Should throw when not ignoring a property of a type we can't persist")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithBadPropertyName.self),
                     "Should throw when not ignoring a property with a name we don't support")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithManagedLazyProperty.self),
                     "Should throw when not ignoring a lazy property")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithDynamicManagedLazyProperty.self),
                     "Should throw when not ignoring a lazy property")

        // Shouldn't throw when not ignoring a property of a type we can't persist if it's not dynamic
        _ = RLMObjectSchema(forObjectClass: SwiftObjectWithEnum.self)
        // Shouldn't throw when not ignoring a property of a type we can't persist if it's not dynamic
        _ = RLMObjectSchema(forObjectClass: SwiftObjectWithStruct.self)

        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithDatePrimaryKey.self),
            "Should throw when setting a non int/string primary key")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithNSURL.self),
            "Should throw when not ignoring a property of a type we can't persist")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithNonOptionalLinkProperty.self),
            "Should throw when not marking a link property as optional")

        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithNSNumber.self),
                     reason: "Can't persist NSNumber without default value: use a Swift-native number type " +
                             "or provide a default value.",
                     "Should throw when using not providing default value for NSNumber property on Swift model")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithOptionalNSNumber.self),
                     reason: "Can't persist NSNumber without default value: use a Swift-native number type " +
                             "or provide a default value.",
                     "Should throw when using not providing default value for NSNumber property on Swift model")
    }

    func testPrimaryKey() {
        XCTAssertNil(SwiftObject().objectSchema.primaryKeyProperty,
            "Object should default to having no primary key property")
        XCTAssertEqual(SwiftPrimaryStringObject().objectSchema.primaryKeyProperty!.name, "stringCol")
    }

    func testIgnoredProperties() {
        let schema = SwiftIgnoredPropertiesObject().objectSchema
        XCTAssertNil(schema["runtimeProperty"], "The object schema shouldn't contain ignored properties")
        XCTAssertNil(schema["runtimeDefaultProperty"], "The object schema shouldn't contain ignored properties")
        XCTAssertNil(schema["readOnlyProperty"], "The object schema shouldn't contain read-only properties")
    }

    func testIndexedProperties() {
        XCTAssertTrue(SwiftIndexedPropertiesObject().objectSchema["stringCol"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedPropertiesObject().objectSchema["intCol"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedPropertiesObject().objectSchema["int8Col"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedPropertiesObject().objectSchema["int16Col"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedPropertiesObject().objectSchema["int32Col"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedPropertiesObject().objectSchema["int64Col"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedPropertiesObject().objectSchema["boolCol"]!.isIndexed)
        XCTAssertTrue(SwiftIndexedPropertiesObject().objectSchema["dateCol"]!.isIndexed)

        XCTAssertFalse(SwiftIndexedPropertiesObject().objectSchema["floatCol"]!.isIndexed)
        XCTAssertFalse(SwiftIndexedPropertiesObject().objectSchema["doubleCol"]!.isIndexed)
        XCTAssertFalse(SwiftIndexedPropertiesObject().objectSchema["dataCol"]!.isIndexed)

        let unindexibleSchema = RLMObjectSchema(forObjectClass: SwiftObjectWithUnindexibleProperties.self)
        for propName in SwiftObjectWithUnindexibleProperties.indexedProperties() {
            XCTAssertFalse(unindexibleSchema[propName]!.indexed,
                "Shouldn't mark unindexible property '\(propName)' as indexed")
        }
    }

    func testOptionalProperties() {
        let schema = RLMObjectSchema(forObjectClass: SwiftOptionalObject.self)

        for prop in schema.properties {
            XCTAssertTrue(prop.optional)
        }

        let types = Set(schema.properties.map { $0.type })
        XCTAssertEqual(types, Set([.string, .string, .data, .date, .object, .int, .float, .double, .bool]))
    }

    func testImplicitlyUnwrappedOptionalsAreParsedAsOptionals() {
        let schema = SwiftImplicitlyUnwrappedOptionalObject().objectSchema
        XCTAssertTrue(schema["optObjectCol"]!.isOptional)
        XCTAssertTrue(schema["optNSStringCol"]!.isOptional)
        XCTAssertTrue(schema["optStringCol"]!.isOptional)
        XCTAssertTrue(schema["optBinaryCol"]!.isOptional)
        XCTAssertTrue(schema["optDateCol"]!.isOptional)
    }

    func testNonRealmOptionalTypesDeclaredAsRealmOptional() {
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithNonRealmOptionalType.self))
    }

    func testNotExplicitlyIgnoredComputedProperties() {
        let schema = SwiftComputedPropertyNotIgnoredObject().objectSchema
        // The two computed properties should not appear on the schema.
        XCTAssertEqual(schema.properties.count, 1)
        XCTAssertNotNil(schema["_urlBacking"])
    }
}

class SwiftFakeObject: NSObject {
    @objc class func objectUtilClass(_ isSwift: Bool) -> AnyClass { return ObjectUtil.self }
    @objc class func primaryKey() -> String? { return nil }
    @objc class func ignoredProperties() -> [String] { return [] }
    @objc class func indexedProperties() -> [String] { return [] }
    @objc class func _realmObjectName() -> String? { return nil }
}

class SwiftObjectWithNSURL: SwiftFakeObject {
    @objc dynamic var url = NSURL(string: "http://realm.io")!
}

class SwiftObjectWithAnyObject: SwiftFakeObject {
    @objc dynamic var anyObject: AnyObject = NSObject()
}

class SwiftObjectWithStringArray: SwiftFakeObject {
    @objc dynamic var stringArray = [String]()
}

class SwiftObjectWithOptionalStringArray: SwiftFakeObject {
    @objc dynamic var stringArray: [String]?
}

enum SwiftEnum {
    case case1
    case case2
}

class SwiftObjectWithEnum: SwiftFakeObject {
    var swiftEnum = SwiftEnum.case1
}

class SwiftObjectWithStruct: SwiftFakeObject {
    var swiftStruct = SortDescriptor(keyPath: "prop")
}

class SwiftObjectWithDatePrimaryKey: SwiftFakeObject {
    @objc dynamic var date = Date()

    override class func primaryKey() -> String? {
        return "date"
    }
}

class SwiftObjectWithNSNumber: SwiftFakeObject {
    @objc dynamic var number = NSNumber()
}

class SwiftObjectWithOptionalNSNumber: SwiftFakeObject {
    @objc dynamic var number: NSNumber? = NSNumber()
}

class SwiftFakeObjectSubclass: SwiftFakeObject {
    @objc dynamic var dateCol = Date()
}

class SwiftObjectWithUnindexibleProperties: SwiftFakeObject {
    @objc dynamic var boolCol = false
    @objc dynamic var intCol = 123
    @objc dynamic var floatCol = 1.23 as Float
    @objc dynamic var doubleCol = 12.3
    @objc dynamic var binaryCol = "a".data(using: String.Encoding.utf8)!
    @objc dynamic var dateCol = Date(timeIntervalSince1970: 1)
    @objc dynamic var objectCol: SwiftBoolObject? = SwiftBoolObject()
    let arrayCol = List<SwiftBoolObject>()

    dynamic override class func indexedProperties() -> [String] {
        return ["boolCol", "intCol", "floatCol", "doubleCol", "binaryCol", "dateCol", "objectCol", "arrayCol"]
    }
}

// swiftlint:disable:next type_name
class SwiftObjectWithNonNullableOptionalProperties: SwiftFakeObject {
    @objc dynamic var optDateCol: Date?
}

class SwiftObjectWithNonOptionalLinkProperty: SwiftFakeObject {
    @objc dynamic var objectCol = SwiftBoolObject()
}

extension Set: RealmOptionalType { }

class SwiftObjectWithNonRealmOptionalType: SwiftFakeObject {
    let set = RealmOptional<Set<Int>>()
}

class SwiftObjectWithBadPropertyName: SwiftFakeObject {
    @objc dynamic var newValue = false
}

class SwiftObjectWithManagedLazyProperty: SwiftFakeObject {
    lazy var foobar: String = "foo"
}

// swiftlint:disable:next type_name
class SwiftObjectWithDynamicManagedLazyProperty: SwiftFakeObject {
    @objc dynamic lazy var foobar: String = "foo"
}
