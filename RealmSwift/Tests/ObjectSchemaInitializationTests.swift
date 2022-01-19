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
        let schema = SwiftFakeObjectSubclass.sharedSchema()!
        XCTAssertEqual(schema.properties.count, 2)

        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithAnyObject.self),
                     reason: "Property SwiftObjectWithAnyObject.anyObject is declared as NSObject")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithStringArray.self),
                     reason: "Property SwiftObjectWithStringArray.stringArray is declared as Array<String>")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithOptionalStringArray.self),
                     reason: "Property SwiftObjectWithOptionalStringArray.stringArray is declared as Optional<Array<String>>")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithBadPropertyName.self),
                     reason: "Property names beginning with 'new' are not supported.")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithManagedLazyProperty.self),
                     reason: "Lazy managed property 'foobar' is not allowed on a Realm Swift object class.")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithDynamicManagedLazyProperty.self),
                     reason: "Lazy managed property 'foobar' is not allowed on a Realm Swift object class.")

        // Shouldn't throw when not ignoring a property of a type we can't persist if it's not dynamic
        _ = RLMObjectSchema(forObjectClass: SwiftObjectWithEnum.self)
        // Shouldn't throw when not ignoring a property of a type we can't persist if it's not dynamic
        _ = RLMObjectSchema(forObjectClass: SwiftObjectWithStruct.self)

        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithDatePrimaryKey.self),
                     reason: "Property 'date' cannot be made the primary key of 'SwiftObjectWithDatePrimaryKey'")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithNSURL.self),
                     reason: "Property SwiftObjectWithNSURL.url is declared as NSURL")
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithNonOptionalLinkProperty.self),
                     reason: "Object property 'objectCol' must be marked as optional.")
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

    func testMultiplePrimaryKeys() {
        assertThrows(RLMObjectSchema(forObjectClass: SwiftObjectWithMultiplePrimaryKeys.self),
                     reason: "Properties 'pk2' and 'pk1' are both marked as the primary key of 'SwiftObjectWithMultiplePrimaryKeys'")
    }

    func testModernIndexableTypes() {
        let indexed = ModernAllIndexableTypesObject().objectSchema
        for property in indexed.properties {
            XCTAssertTrue(property.isIndexed)
        }
        let notIndexed = ModernAllIndexableButNotIndexedObject().objectSchema
        for property in notIndexed.properties {
            XCTAssertFalse(property.isIndexed)
        }
    }

    func testCustomIndexableTypes() {
        let indexed = CustomAllIndexableTypesObject().objectSchema
        for property in indexed.properties {
            XCTAssertTrue(property.isIndexed)
        }
        let notIndexed = CustomAllIndexableButNotIndexedObject().objectSchema
        for property in notIndexed.properties {
            XCTAssertFalse(property.isIndexed)
        }
    }

    #if DEBUG // this test depends on @testable import
    func assertType<T: SchemaDiscoverable>(_ value: T, _ propertyType: PropertyType,
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

        assertType(MutableSet<Int>(), .int, set: true, hasSelectors: false)
        assertType(MutableSet<Int8>(), .int, set: true, hasSelectors: false)
        assertType(MutableSet<Int16>(), .int, set: true, hasSelectors: false)
        assertType(MutableSet<Int32>(), .int, set: true, hasSelectors: false)
        assertType(MutableSet<Int64>(), .int, set: true, hasSelectors: false)
        assertType(MutableSet<Bool>(), .bool, set: true, hasSelectors: false)
        assertType(MutableSet<Float>(), .float, set: true, hasSelectors: false)
        assertType(MutableSet<Double>(), .double, set: true, hasSelectors: false)
        assertType(MutableSet<String>(), .string, set: true, hasSelectors: false)
        assertType(MutableSet<Data>(), .data, set: true, hasSelectors: false)
        assertType(MutableSet<Date>(), .date, set: true, hasSelectors: false)
        assertType(MutableSet<UUID>(), .UUID, set: true, hasSelectors: false)
        assertType(MutableSet<Decimal128>(), .decimal128, set: true, hasSelectors: false)
        assertType(MutableSet<ObjectId>(), .objectId, set: true, hasSelectors: false)

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

    func assertType<T: _Persistable>(_ type: T.Type, _ propertyType: PropertyType,
                                     optional: Bool = false, list: Bool = false,
                                     set: Bool = false, map: Bool = false,
                                     objectType: String? = nil, line: UInt = #line) {
        let prop = RLMProperty(name: "_property", value: Persisted<T>())
        XCTAssertEqual(prop.name, "property", line: line)
        XCTAssertEqual(prop.type, propertyType, line: line)
        XCTAssertEqual(prop.optional, optional, line: line)
        XCTAssertEqual(prop.array, list, line: line)
        XCTAssertEqual(prop.set, set, line: line)
        XCTAssertEqual(prop.dictionary, map, line: line)
        XCTAssertEqual(prop.objectClassName, objectType, line: line)
        XCTAssertNil(prop.getterSel, line: line)
        XCTAssertNil(prop.setterSel, line: line)
    }

    func testModernPropertyPopulation() {
        assertType(Int.self, .int)
        assertType(Int8.self, .int)
        assertType(Int16.self, .int)
        assertType(Int32.self, .int)
        assertType(Int64.self, .int)
        assertType(Bool.self, .bool)
        assertType(Float.self, .float)
        assertType(Double.self, .double)
        assertType(String.self, .string)
        assertType(Data.self, .data)
        assertType(Date.self, .date)
        assertType(UUID.self, .UUID)
        assertType(Decimal128.self, .decimal128)
        assertType(ObjectId.self, .objectId)
        assertType(AnyRealmValue.self, .any)
        assertType(ModernIntEnum.self, .int)
        assertType(ModernStringEnum.self, .string)

        assertType(Int?.self, .int, optional: true)
        assertType(Int8?.self, .int, optional: true)
        assertType(Int16?.self, .int, optional: true)
        assertType(Int32?.self, .int, optional: true)
        assertType(Int64?.self, .int, optional: true)
        assertType(Bool?.self, .bool, optional: true)
        assertType(Float?.self, .float, optional: true)
        assertType(Double?.self, .double, optional: true)
        assertType(String?.self, .string, optional: true)
        assertType(Data?.self, .data, optional: true)
        assertType(Date?.self, .date, optional: true)
        assertType(UUID?.self, .UUID, optional: true)
        assertType(Decimal128?.self, .decimal128, optional: true)
        assertType(ObjectId?.self, .objectId, optional: true)
        assertType(Object?.self, .object, optional: true, objectType: "RealmSwiftObject")
        assertType(EmbeddedObject?.self, .object, optional: true, objectType: "RealmSwiftEmbeddedObject")
        assertType(ModernIntEnum?.self, .int, optional: true)
        assertType(ModernStringEnum?.self, .string, optional: true)

        assertType(List<Int>.self, .int, list: true)
        assertType(List<Int8>.self, .int, list: true)
        assertType(List<Int16>.self, .int, list: true)
        assertType(List<Int32>.self, .int, list: true)
        assertType(List<Int64>.self, .int, list: true)
        assertType(List<Bool>.self, .bool, list: true)
        assertType(List<Float>.self, .float, list: true)
        assertType(List<Double>.self, .double, list: true)
        assertType(List<String>.self, .string, list: true)
        assertType(List<Data>.self, .data, list: true)
        assertType(List<Date>.self, .date, list: true)
        assertType(List<UUID>.self, .UUID, list: true)
        assertType(List<Decimal128>.self, .decimal128, list: true)
        assertType(List<ObjectId>.self, .objectId, list: true)
        assertType(List<AnyRealmValue>.self, .any, list: true)
        assertType(List<Object>.self, .object, list: true, objectType: "RealmSwiftObject")
        assertType(List<EmbeddedObject>.self, .object, list: true, objectType: "RealmSwiftEmbeddedObject")

        assertType(List<Int?>.self, .int, optional: true, list: true)
        assertType(List<Int8?>.self, .int, optional: true, list: true)
        assertType(List<Int16?>.self, .int, optional: true, list: true)
        assertType(List<Int32?>.self, .int, optional: true, list: true)
        assertType(List<Int64?>.self, .int, optional: true, list: true)
        assertType(List<Bool?>.self, .bool, optional: true, list: true)
        assertType(List<Float?>.self, .float, optional: true, list: true)
        assertType(List<Double?>.self, .double, optional: true, list: true)
        assertType(List<String?>.self, .string, optional: true, list: true)
        assertType(List<Data?>.self, .data, optional: true, list: true)
        assertType(List<Date?>.self, .date, optional: true, list: true)
        assertType(List<UUID?>.self, .UUID, optional: true, list: true)
        assertType(List<Decimal128?>.self, .decimal128, optional: true, list: true)
        assertType(List<ObjectId?>.self, .objectId, optional: true, list: true)

        assertType(MutableSet<Int>.self, .int, set: true)
        assertType(MutableSet<Int8>.self, .int, set: true)
        assertType(MutableSet<Int16>.self, .int, set: true)
        assertType(MutableSet<Int32>.self, .int, set: true)
        assertType(MutableSet<Int64>.self, .int, set: true)
        assertType(MutableSet<Bool>.self, .bool, set: true)
        assertType(MutableSet<Float>.self, .float, set: true)
        assertType(MutableSet<Double>.self, .double, set: true)
        assertType(MutableSet<String>.self, .string, set: true)
        assertType(MutableSet<Data>.self, .data, set: true)
        assertType(MutableSet<Date>.self, .date, set: true)
        assertType(MutableSet<UUID>.self, .UUID, set: true)
        assertType(MutableSet<Decimal128>.self, .decimal128, set: true)
        assertType(MutableSet<ObjectId>.self, .objectId, set: true)
        assertType(MutableSet<AnyRealmValue>.self, .any, set: true)
        assertType(MutableSet<Object>.self, .object, set: true, objectType: "RealmSwiftObject")
        assertType(MutableSet<EmbeddedObject>.self, .object, set: true, objectType: "RealmSwiftEmbeddedObject")

        assertType(MutableSet<Int?>.self, .int, optional: true, set: true)
        assertType(MutableSet<Int8?>.self, .int, optional: true, set: true)
        assertType(MutableSet<Int16?>.self, .int, optional: true, set: true)
        assertType(MutableSet<Int32?>.self, .int, optional: true, set: true)
        assertType(MutableSet<Int64?>.self, .int, optional: true, set: true)
        assertType(MutableSet<Bool?>.self, .bool, optional: true, set: true)
        assertType(MutableSet<Float?>.self, .float, optional: true, set: true)
        assertType(MutableSet<Double?>.self, .double, optional: true, set: true)
        assertType(MutableSet<String?>.self, .string, optional: true, set: true)
        assertType(MutableSet<Data?>.self, .data, optional: true, set: true)
        assertType(MutableSet<Date?>.self, .date, optional: true, set: true)
        assertType(MutableSet<UUID?>.self, .UUID, optional: true, set: true)
        assertType(MutableSet<Decimal128?>.self, .decimal128, optional: true, set: true)
        assertType(MutableSet<ObjectId?>.self, .objectId, optional: true, set: true)

        assertType(Map<String, Int>.self, .int, map: true)
        assertType(Map<String, Int8>.self, .int, map: true)
        assertType(Map<String, Int16>.self, .int, map: true)
        assertType(Map<String, Int32>.self, .int, map: true)
        assertType(Map<String, Int64>.self, .int, map: true)
        assertType(Map<String, Bool>.self, .bool, map: true)
        assertType(Map<String, Float>.self, .float, map: true)
        assertType(Map<String, Double>.self, .double, map: true)
        assertType(Map<String, String>.self, .string, map: true)
        assertType(Map<String, Data>.self, .data, map: true)
        assertType(Map<String, Date>.self, .date, map: true)
        assertType(Map<String, UUID>.self, .UUID, map: true)
        assertType(Map<String, Decimal128>.self, .decimal128, map: true)
        assertType(Map<String, ObjectId>.self, .objectId, map: true)
        assertType(Map<String, AnyRealmValue>.self, .any, map: true)

        assertType(Map<String, Int?>.self, .int, optional: true, map: true)
        assertType(Map<String, Int8?>.self, .int, optional: true, map: true)
        assertType(Map<String, Int16?>.self, .int, optional: true, map: true)
        assertType(Map<String, Int32?>.self, .int, optional: true, map: true)
        assertType(Map<String, Int64?>.self, .int, optional: true, map: true)
        assertType(Map<String, Bool?>.self, .bool, optional: true, map: true)
        assertType(Map<String, Float?>.self, .float, optional: true, map: true)
        assertType(Map<String, Double?>.self, .double, optional: true, map: true)
        assertType(Map<String, String?>.self, .string, optional: true, map: true)
        assertType(Map<String, Data?>.self, .data, optional: true, map: true)
        assertType(Map<String, Date?>.self, .date, optional: true, map: true)
        assertType(Map<String, UUID?>.self, .UUID, optional: true, map: true)
        assertType(Map<String, Decimal128?>.self, .decimal128, optional: true, map: true)
        assertType(Map<String, ObjectId?>.self, .objectId, optional: true, map: true)
        assertType(Map<String, Object?>.self, .object, optional: true, map: true, objectType: "RealmSwiftObject")
        assertType(Map<String, EmbeddedObject?>.self, .object, optional: true, map: true, objectType: "RealmSwiftEmbeddedObject")

        assertThrows(RLMProperty(name: "_name", value: Persisted<Object>()),
                     reason: "Object property 'name' must be marked as optional.")
        assertThrows(RLMProperty(name: "_name", value: Persisted<List<Object?>>()),
                     reason: "List<RealmSwiftObject> property 'name' must not be marked as optional.")
        assertThrows(RLMProperty(name: "_name", value: Persisted<MutableSet<Object?>>()),
                     reason: "MutableSet<RealmSwiftObject> property 'name' must not be marked as optional.")
        assertThrows(RLMProperty(name: "_name", value: Persisted<LinkingObjects<Object>>()),
                     reason: "LinkingObjects<RealmSwiftObject> property 'name' must set the origin property name with @Persisted(originProperty: \"name\").")

        assertThrows(RLMProperty(name: "_name", value: Persisted<EmbeddedObject>()),
                     reason: "Object property 'name' must be marked as optional.")
        assertThrows(RLMProperty(name: "_name", value: Persisted<List<EmbeddedObject?>>()),
                     reason: "List<RealmSwiftObject> property 'name' must not be marked as optional.")
        assertThrows(RLMProperty(name: "_name", value: Persisted<MutableSet<EmbeddedObject?>>()),
                     reason: "MutableSet<RealmSwiftObject> property 'name' must not be marked as optional.")
        assertThrows(RLMProperty(name: "_name", value: Persisted<LinkingObjects<EmbeddedObject>>()),
                     reason: "LinkingObjects<RealmSwiftEmbeddedObject> property 'name' must set the origin property name with @Persisted(originProperty: \"name\").")
        assertThrows(RLMProperty(name: "_name", value: Persisted<Map<String, Object>>()),
                     reason: "Map<String, RealmSwiftObject> property 'name' must be marked as optional.")
        assertThrows(RLMProperty(name: "_name", value: Persisted<Map<String, EmbeddedObject>>()),
                     reason: "Map<String, RealmSwiftObject> property 'name' must be marked as optional.")
    }

    func testModernIndexed() {
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<Int>()).indexed)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<Int>(wrappedValue: 1)).indexed)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<Int>(indexed: false)).indexed)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<Int>(wrappedValue: 1, indexed: false)).indexed)
        XCTAssertTrue(RLMProperty(name: "_property", value: Persisted<Int>(indexed: true)).indexed)
        XCTAssertTrue(RLMProperty(name: "_property", value: Persisted<Int>(wrappedValue: 1, indexed: true)).indexed)
    }

    func testModernPrimary() {
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<Int>()).isPrimary)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<Int>(wrappedValue: 1)).isPrimary)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<Int>(primaryKey: false)).isPrimary)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<Int>(wrappedValue: 1, primaryKey: false)).isPrimary)
        XCTAssertTrue(RLMProperty(name: "_property", value: Persisted<Int>(primaryKey: true)).isPrimary)
        XCTAssertTrue(RLMProperty(name: "_property", value: Persisted<Int>(wrappedValue: 1, primaryKey: true)).isPrimary)
    }

    func testCustomPropertyPopulation() {
        assertType(IntWrapper.self, .int)
        assertType(Int8Wrapper.self, .int)
        assertType(Int16Wrapper.self, .int)
        assertType(Int32Wrapper.self, .int)
        assertType(Int64Wrapper.self, .int)
        assertType(BoolWrapper.self, .bool)
        assertType(FloatWrapper.self, .float)
        assertType(DoubleWrapper.self, .double)
        assertType(StringWrapper.self, .string)
        assertType(DataWrapper.self, .data)
        assertType(DateWrapper.self, .date)
        assertType(UUIDWrapper.self, .UUID)
        assertType(Decimal128Wrapper.self, .decimal128)
        assertType(ObjectIdWrapper.self, .objectId)

        assertType(IntWrapper?.self, .int, optional: true)
        assertType(Int8Wrapper?.self, .int, optional: true)
        assertType(Int16Wrapper?.self, .int, optional: true)
        assertType(Int32Wrapper?.self, .int, optional: true)
        assertType(Int64Wrapper?.self, .int, optional: true)
        assertType(BoolWrapper?.self, .bool, optional: true)
        assertType(FloatWrapper?.self, .float, optional: true)
        assertType(DoubleWrapper?.self, .double, optional: true)
        assertType(StringWrapper?.self, .string, optional: true)
        assertType(DataWrapper?.self, .data, optional: true)
        assertType(DateWrapper?.self, .date, optional: true)
        assertType(UUIDWrapper?.self, .UUID, optional: true)
        assertType(Decimal128Wrapper?.self, .decimal128, optional: true)
        assertType(ObjectIdWrapper?.self, .objectId, optional: true)
        assertType(EmbeddedObjectWrapper?.self, .object, optional: true,
                   objectType: "ModernEmbeddedObject")

        assertType(List<IntWrapper>.self, .int, list: true)
        assertType(List<Int8Wrapper>.self, .int, list: true)
        assertType(List<Int16Wrapper>.self, .int, list: true)
        assertType(List<Int32Wrapper>.self, .int, list: true)
        assertType(List<Int64Wrapper>.self, .int, list: true)
        assertType(List<BoolWrapper>.self, .bool, list: true)
        assertType(List<FloatWrapper>.self, .float, list: true)
        assertType(List<DoubleWrapper>.self, .double, list: true)
        assertType(List<StringWrapper>.self, .string, list: true)
        assertType(List<DataWrapper>.self, .data, list: true)
        assertType(List<DateWrapper>.self, .date, list: true)
        assertType(List<UUIDWrapper>.self, .UUID, list: true)
        assertType(List<Decimal128Wrapper>.self, .decimal128, list: true)
        assertType(List<ObjectIdWrapper>.self, .objectId, list: true)
        assertType(List<EmbeddedObjectWrapper>.self, .object, list: true,
                   objectType: "ModernEmbeddedObject")

        assertType(List<IntWrapper?>.self, .int, optional: true, list: true)
        assertType(List<Int8Wrapper?>.self, .int, optional: true, list: true)
        assertType(List<Int16Wrapper?>.self, .int, optional: true, list: true)
        assertType(List<Int32Wrapper?>.self, .int, optional: true, list: true)
        assertType(List<Int64Wrapper?>.self, .int, optional: true, list: true)
        assertType(List<BoolWrapper?>.self, .bool, optional: true, list: true)
        assertType(List<FloatWrapper?>.self, .float, optional: true, list: true)
        assertType(List<DoubleWrapper?>.self, .double, optional: true, list: true)
        assertType(List<StringWrapper?>.self, .string, optional: true, list: true)
        assertType(List<DataWrapper?>.self, .data, optional: true, list: true)
        assertType(List<DateWrapper?>.self, .date, optional: true, list: true)
        assertType(List<UUIDWrapper?>.self, .UUID, optional: true, list: true)
        assertType(List<Decimal128Wrapper?>.self, .decimal128, optional: true, list: true)
        assertType(List<ObjectIdWrapper?>.self, .objectId, optional: true, list: true)

        assertType(MutableSet<IntWrapper>.self, .int, set: true)
        assertType(MutableSet<Int8Wrapper>.self, .int, set: true)
        assertType(MutableSet<Int16Wrapper>.self, .int, set: true)
        assertType(MutableSet<Int32Wrapper>.self, .int, set: true)
        assertType(MutableSet<Int64Wrapper>.self, .int, set: true)
        assertType(MutableSet<BoolWrapper>.self, .bool, set: true)
        assertType(MutableSet<FloatWrapper>.self, .float, set: true)
        assertType(MutableSet<DoubleWrapper>.self, .double, set: true)
        assertType(MutableSet<StringWrapper>.self, .string, set: true)
        assertType(MutableSet<DataWrapper>.self, .data, set: true)
        assertType(MutableSet<DateWrapper>.self, .date, set: true)
        assertType(MutableSet<UUIDWrapper>.self, .UUID, set: true)
        assertType(MutableSet<Decimal128Wrapper>.self, .decimal128, set: true)
        assertType(MutableSet<ObjectIdWrapper>.self, .objectId, set: true)

        assertType(MutableSet<IntWrapper?>.self, .int, optional: true, set: true)
        assertType(MutableSet<Int8Wrapper?>.self, .int, optional: true, set: true)
        assertType(MutableSet<Int16Wrapper?>.self, .int, optional: true, set: true)
        assertType(MutableSet<Int32Wrapper?>.self, .int, optional: true, set: true)
        assertType(MutableSet<Int64Wrapper?>.self, .int, optional: true, set: true)
        assertType(MutableSet<BoolWrapper?>.self, .bool, optional: true, set: true)
        assertType(MutableSet<FloatWrapper?>.self, .float, optional: true, set: true)
        assertType(MutableSet<DoubleWrapper?>.self, .double, optional: true, set: true)
        assertType(MutableSet<StringWrapper?>.self, .string, optional: true, set: true)
        assertType(MutableSet<DataWrapper?>.self, .data, optional: true, set: true)
        assertType(MutableSet<DateWrapper?>.self, .date, optional: true, set: true)
        assertType(MutableSet<UUIDWrapper?>.self, .UUID, optional: true, set: true)
        assertType(MutableSet<Decimal128Wrapper?>.self, .decimal128, optional: true, set: true)
        assertType(MutableSet<ObjectIdWrapper?>.self, .objectId, optional: true, set: true)

        assertType(Map<String, IntWrapper>.self, .int, map: true)
        assertType(Map<String, Int8Wrapper>.self, .int, map: true)
        assertType(Map<String, Int16Wrapper>.self, .int, map: true)
        assertType(Map<String, Int32Wrapper>.self, .int, map: true)
        assertType(Map<String, Int64Wrapper>.self, .int, map: true)
        assertType(Map<String, BoolWrapper>.self, .bool, map: true)
        assertType(Map<String, FloatWrapper>.self, .float, map: true)
        assertType(Map<String, DoubleWrapper>.self, .double, map: true)
        assertType(Map<String, StringWrapper>.self, .string, map: true)
        assertType(Map<String, DataWrapper>.self, .data, map: true)
        assertType(Map<String, DateWrapper>.self, .date, map: true)
        assertType(Map<String, UUIDWrapper>.self, .UUID, map: true)
        assertType(Map<String, Decimal128Wrapper>.self, .decimal128, map: true)
        assertType(Map<String, ObjectIdWrapper>.self, .objectId, map: true)
        assertType(Map<String, EmbeddedObjectWrapper>.self, .object, optional: true, map: true,
                   objectType: "ModernEmbeddedObject")

        assertType(Map<String, IntWrapper?>.self, .int, optional: true, map: true)
        assertType(Map<String, Int8Wrapper?>.self, .int, optional: true, map: true)
        assertType(Map<String, Int16Wrapper?>.self, .int, optional: true, map: true)
        assertType(Map<String, Int32Wrapper?>.self, .int, optional: true, map: true)
        assertType(Map<String, Int64Wrapper?>.self, .int, optional: true, map: true)
        assertType(Map<String, BoolWrapper?>.self, .bool, optional: true, map: true)
        assertType(Map<String, FloatWrapper?>.self, .float, optional: true, map: true)
        assertType(Map<String, DoubleWrapper?>.self, .double, optional: true, map: true)
        assertType(Map<String, StringWrapper?>.self, .string, optional: true, map: true)
        assertType(Map<String, DataWrapper?>.self, .data, optional: true, map: true)
        assertType(Map<String, DateWrapper?>.self, .date, optional: true, map: true)
        assertType(Map<String, UUIDWrapper?>.self, .UUID, optional: true, map: true)
        assertType(Map<String, Decimal128Wrapper?>.self, .decimal128, optional: true, map: true)
        assertType(Map<String, ObjectIdWrapper?>.self, .objectId, optional: true, map: true)
        assertType(Map<String, EmbeddedObjectWrapper?>.self, .object, optional: true, map: true,
                   objectType: "ModernEmbeddedObject")
    }

    func testCustomIndexed() {
        let v = IntWrapper(persistedValue: 1)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<IntWrapper>()).indexed)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<IntWrapper>(wrappedValue: v)).indexed)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<IntWrapper>(indexed: false)).indexed)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<IntWrapper>(wrappedValue: v, indexed: false)).indexed)
        XCTAssertTrue(RLMProperty(name: "_property", value: Persisted<IntWrapper>(indexed: true)).indexed)
        XCTAssertTrue(RLMProperty(name: "_property", value: Persisted<IntWrapper>(wrappedValue: v, indexed: true)).indexed)
    }

    func testCustomPrimary() {
        let v = IntWrapper(persistedValue: 1)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<IntWrapper>()).isPrimary)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<IntWrapper>(wrappedValue: v)).isPrimary)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<IntWrapper>(primaryKey: false)).isPrimary)
        XCTAssertFalse(RLMProperty(name: "_property", value: Persisted<IntWrapper>(wrappedValue: v, primaryKey: false)).isPrimary)
        XCTAssertTrue(RLMProperty(name: "_property", value: Persisted<IntWrapper>(primaryKey: true)).isPrimary)
        XCTAssertTrue(RLMProperty(name: "_property", value: Persisted<IntWrapper>(wrappedValue: v, primaryKey: true)).isPrimary)
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

extension Set: RealmOptionalType {
    public static func _rlmFromObjc(_ value: Any, insideOptional: Bool) -> Set<Element>? {
        fatalError()
    }

    public var _rlmObjcValue: Any {
        fatalError()
    }
}

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

class SwiftObjectWithMultiplePrimaryKeys: SwiftFakeObject {
    @Persisted(primaryKey: true) var pk1: Int
    @Persisted(primaryKey: true) var pk2: Int
}
