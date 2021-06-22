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
import Realm.Private
import Realm.Dynamic
import Foundation

#if DEBUG
    @testable import RealmSwift
#else
    import RealmSwift
#endif

@available(*, deprecated) // Silence deprecation warnings for RealmOptional
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

        let uuidCol = objectSchema["uuidCol"]
        XCTAssertNotNil(uuidCol)
        XCTAssertEqual(uuidCol!.name, "uuidCol")
        XCTAssertEqual(uuidCol!.type, PropertyType.UUID)
        XCTAssertFalse(uuidCol!.isIndexed)
        XCTAssertFalse(uuidCol!.isOptional)
        XCTAssertNil(uuidCol!.objectClassName)

        let anyCol = objectSchema["anyCol"]
        XCTAssertNotNil(anyCol)
        XCTAssertEqual(anyCol!.name, "anyCol")
        XCTAssertEqual(anyCol!.type, PropertyType.any)
        XCTAssertFalse(anyCol!.isIndexed)
        XCTAssertFalse(anyCol!.isOptional)
        XCTAssertNil(anyCol!.objectClassName)

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

        let setCol = objectSchema["setCol"]
        XCTAssertNotNil(setCol)
        XCTAssertEqual(setCol!.name, "setCol")
        XCTAssertEqual(setCol!.type, PropertyType.object)
        XCTAssertTrue(setCol!.isSet)
        XCTAssertFalse(setCol!.isIndexed)
        XCTAssertFalse(setCol!.isOptional)
        XCTAssertEqual(setCol!.objectClassName!, "SwiftBoolObject")

        let dynamicArrayCol = SwiftCompanyObject().objectSchema["employees"]
        XCTAssertNotNil(dynamicArrayCol)
        XCTAssertEqual(dynamicArrayCol!.name, "employees")
        XCTAssertEqual(dynamicArrayCol!.type, PropertyType.object)
        XCTAssertTrue(dynamicArrayCol!.isArray)
        XCTAssertFalse(dynamicArrayCol!.isIndexed)
        XCTAssertFalse(dynamicArrayCol!.isOptional)
        XCTAssertEqual(dynamicArrayCol!.objectClassName!, "SwiftEmployeeObject")

        let dynamicSetCol = SwiftCompanyObject().objectSchema["employeeSet"]
        XCTAssertNotNil(dynamicSetCol)
        XCTAssertEqual(dynamicSetCol!.name, "employeeSet")
        XCTAssertEqual(dynamicSetCol!.type, PropertyType.object)
        XCTAssertTrue(dynamicSetCol!.isSet)
        XCTAssertFalse(dynamicSetCol!.isIndexed)
        XCTAssertFalse(dynamicSetCol!.isOptional)
        XCTAssertEqual(dynamicSetCol!.objectClassName!, "SwiftEmployeeObject")
    }

    func testInvalidObjects() {
        // Should be able to get a schema for a non-RLMObjectBase subclass
        let schema = RLMObjectSchema(forObjectClass: SwiftFakeObjectSubclass.self)
        XCTAssertEqual(schema.properties.count, 2)

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
    }

    func testOptionalProperties() {
        let schema = RLMObjectSchema(forObjectClass: SwiftOptionalObject.self)

        for prop in schema.properties {
            XCTAssertTrue(prop.optional)
        }

        let types = Set(schema.properties.map { $0.type })
        XCTAssertEqual(types, Set([.string, .string, .data, .date, .object, .int,
                                   .float, .double, .bool, .decimal128, .objectId, .UUID]))
    }

    func testImplicitlyUnwrappedOptionalsAreParsedAsOptionals() {
        let schema = SwiftImplicitlyUnwrappedOptionalObject().objectSchema
        XCTAssertTrue(schema["optObjectCol"]!.isOptional)
        XCTAssertTrue(schema["optNSStringCol"]!.isOptional)
        XCTAssertTrue(schema["optStringCol"]!.isOptional)
        XCTAssertTrue(schema["optBinaryCol"]!.isOptional)
        XCTAssertTrue(schema["optDateCol"]!.isOptional)
        XCTAssertTrue(schema["optDecimalCol"]!.isOptional)
        XCTAssertTrue(schema["optObjectIdCol"]!.isOptional)
        XCTAssertTrue(schema["optUuidCol"]!.isOptional)
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

    #if DEBUG // this test depends on @testable import
    func assertType<T: _RealmSchemaDiscoverable>(_ value: T, _ propertyType: PropertyType,
                                                 optional: Bool = false, list: Bool = false,
                                                 set: Bool = false, objectType: String? = nil,
                                                 hasSelectors: Bool = true, line: UInt = #line) {
        let prop = RLMProperty(name: "property", value: value)
        XCTAssertEqual(prop.type, propertyType, line: line)
        XCTAssertEqual(prop.optional, optional, line: line)
        XCTAssertEqual(prop.array, list, line: line)
        XCTAssertEqual(prop.set, set, line: line)
        XCTAssertEqual(prop.objectClassName, objectType, line: line)

        if hasSelectors {
            XCTAssertNotNil(prop.getterSel, line: line)
            XCTAssertNotNil(prop.setterSel, line: line)
        } else {
            XCTAssertNil(prop.getterSel, line: line)
            XCTAssertNil(prop.setterSel, line: line)
        }
    }

    func testPropertyPopulation() {
        assertType(Int(), .int)
        assertType(Int8(), .int)
        assertType(Int16(), .int)
        assertType(Int32(), .int)
        assertType(Int64(), .int)
        assertType(Bool(), .bool)
        assertType(Float(), .float)
        assertType(Double(), .double)
        assertType(String(), .string)
        assertType(Data(), .data)
        assertType(Date(), .date)
        assertType(UUID(), .UUID)
        assertType(Decimal128(), .decimal128)
        assertType(ObjectId(), .objectId)

        assertType(Optional<Int>.none, .int, optional: true)
        assertType(Optional<Int8>.none, .int, optional: true)
        assertType(Optional<Int16>.none, .int, optional: true)
        assertType(Optional<Int32>.none, .int, optional: true)
        assertType(Optional<Int64>.none, .int, optional: true)
        assertType(Optional<Bool>.none, .bool, optional: true)
        assertType(Optional<Float>.none, .float, optional: true)
        assertType(Optional<Double>.none, .double, optional: true)
        assertType(Optional<String>.none, .string, optional: true)
        assertType(Optional<Data>.none, .data, optional: true)
        assertType(Optional<Date>.none, .date, optional: true)
        assertType(Optional<UUID>.none, .UUID, optional: true)
        assertType(Optional<Decimal128>.none, .decimal128, optional: true)
        assertType(Optional<ObjectId>.none, .objectId, optional: true)

        assertType(RealmProperty<Int?>(), .int, optional: true, hasSelectors: false)
        assertType(RealmProperty<Int8?>(), .int, optional: true, hasSelectors: false)
        assertType(RealmProperty<Int16?>(), .int, optional: true, hasSelectors: false)
        assertType(RealmProperty<Int32?>(), .int, optional: true, hasSelectors: false)
        assertType(RealmProperty<Int64?>(), .int, optional: true, hasSelectors: false)
        assertType(RealmProperty<Bool?>(), .bool, optional: true, hasSelectors: false)
        assertType(RealmProperty<Float?>(), .float, optional: true, hasSelectors: false)
        assertType(RealmProperty<Double?>(), .double, optional: true, hasSelectors: false)

        assertType(List<Int>(), .int, list: true, hasSelectors: false)
        assertType(List<Int8>(), .int, list: true, hasSelectors: false)
        assertType(List<Int16>(), .int, list: true, hasSelectors: false)
        assertType(List<Int32>(), .int, list: true, hasSelectors: false)
        assertType(List<Int64>(), .int, list: true, hasSelectors: false)
        assertType(List<Bool>(), .bool, list: true, hasSelectors: false)
        assertType(List<Float>(), .float, list: true, hasSelectors: false)
        assertType(List<Double>(), .double, list: true, hasSelectors: false)
        assertType(List<String>(), .string, list: true, hasSelectors: false)
        assertType(List<Data>(), .data, list: true, hasSelectors: false)
        assertType(List<Date>(), .date, list: true, hasSelectors: false)
        assertType(List<UUID>(), .UUID, list: true, hasSelectors: false)
        assertType(List<Decimal128>(), .decimal128, list: true, hasSelectors: false)
        assertType(List<ObjectId>(), .objectId, list: true, hasSelectors: false)

        assertType(List<Int?>(), .int, optional: true, list: true, hasSelectors: false)
        assertType(List<Int8?>(), .int, optional: true, list: true, hasSelectors: false)
        assertType(List<Int16?>(), .int, optional: true, list: true, hasSelectors: false)
        assertType(List<Int32?>(), .int, optional: true, list: true, hasSelectors: false)
        assertType(List<Int64?>(), .int, optional: true, list: true, hasSelectors: false)
        assertType(List<Bool?>(), .bool, optional: true, list: true, hasSelectors: false)
        assertType(List<Float?>(), .float, optional: true, list: true, hasSelectors: false)
        assertType(List<Double?>(), .double, optional: true, list: true, hasSelectors: false)
        assertType(List<String?>(), .string, optional: true, list: true, hasSelectors: false)
        assertType(List<Data?>(), .data, optional: true, list: true, hasSelectors: false)
        assertType(List<Date?>(), .date, optional: true, list: true, hasSelectors: false)
        assertType(List<UUID?>(), .UUID, optional: true, list: true, hasSelectors: false)
        assertType(List<Decimal128?>(), .decimal128, optional: true, list: true, hasSelectors: false)
        assertType(List<ObjectId?>(), .objectId, optional: true, list: true, hasSelectors: false)

        assertType(MutableSet<Int?>(), .int, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<Int8?>(), .int, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<Int16?>(), .int, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<Int32?>(), .int, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<Int64?>(), .int, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<Bool?>(), .bool, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<Float?>(), .float, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<Double?>(), .double, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<String?>(), .string, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<Data?>(), .data, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<Date?>(), .date, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<UUID?>(), .UUID, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<Decimal128?>(), .decimal128, optional: true, set: true, hasSelectors: false)
        assertType(MutableSet<ObjectId?>(), .objectId, optional: true, set: true, hasSelectors: false)

        assertThrows(RLMProperty(name: "name", value: Object()),
                     reason: "Object property 'name' must be marked as optional.")
        assertThrows(RLMProperty(name: "name", value: List<Object?>()),
                     reason: "List<RealmSwiftObject> property 'name' must not be marked as optional.")
        assertThrows(RLMProperty(name: "name", value: MutableSet<Object?>()),
                     reason: "MutableSet<RealmSwiftObject> property 'name' must not be marked as optional.")
        assertType(Object?.none, .object, optional: true, objectType: "RealmSwiftObject")
        assertType(List<Object>(), .object, list: true, objectType: "RealmSwiftObject", hasSelectors: false)
        assertType(MutableSet<Object>(), .object, set: true, objectType: "RealmSwiftObject", hasSelectors: false)
    }
    #endif // DEBUG
}

class SwiftFakeObject: Object {
    override class func _realmIgnoreClass() -> Bool { return true }
    @objc dynamic var requiredProp: String?
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

class SwiftFakeObjectSubclass: SwiftFakeObject {
    @objc dynamic var dateCol = Date()
}

// swiftlint:disable:next type_name
class SwiftObjectWithNonNullableOptionalProperties: SwiftFakeObject {
    @objc dynamic var optDateCol: Date?
}

class SwiftObjectWithNonOptionalLinkProperty: SwiftFakeObject {
    @objc dynamic var objectCol = SwiftBoolObject()
}

extension Set: RealmOptionalType { }

@available(*, deprecated) // Silence deprecation warnings for RealmOptional
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
