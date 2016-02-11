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
import RealmSwift
import Foundation

class ObjectCreationTests: TestCase {

    // MARK: Init tests
    func testInitWithDefaults() {
        // test all properties are defaults
        let object = SwiftObject()
        XCTAssertNil(object.realm)

        // test defaults values
        verifySwiftObjectWithDictionaryLiteral(object, dictionary: SwiftObject.defaultValues(), boolObjectValue: false,
            boolObjectListValues: [])

        // test realm properties are nil for standalone
        XCTAssertNil(object.realm)
        XCTAssertNil(object.objectCol!.realm)
        XCTAssertNil(object.arrayCol.realm)
    }

    func testInitWithOptionalWithoutDefaults() {
        let object = SwiftOptionalObject()
        for prop in object.objectSchema.properties {
            let value = object[prop.name]
            if let value = value as? RLMOptionalBase {
                XCTAssertNil(value.underlyingValue)
            } else {
                XCTAssertNil(value)
            }
        }
    }

    func testInitWithOptionalDefaults() {
        let object = SwiftOptionalDefaultValuesObject()
        verifySwiftOptionalObjectWithDictionaryLiteral(object, dictionary:
            SwiftOptionalDefaultValuesObject.defaultValues(), boolObjectValue: true)
    }

    func testInitWithDictionary() {
        // dictionary with all values specified
        let baselineValues =
           ["boolCol": true as NSNumber,
            "intCol": 1 as NSNumber,
            "floatCol": 1.1 as NSNumber,
            "doubleCol": 11.1 as NSNumber,
            "stringCol": "b" as NSString,
            "binaryCol": "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData,
            "dateCol": NSDate(timeIntervalSince1970: 2) as NSDate,
            "objectCol": SwiftBoolObject(value: [true]) as AnyObject,
            "arrayCol": [SwiftBoolObject(value: [true]), SwiftBoolObject()]  as AnyObject
           ]

        // test with valid dictionary literals
        let props = try! Realm().schema["SwiftObject"]!.properties
        for propNum in 0..<props.count {
            for validValue in validValuesForSwiftObjectType(props[propNum].type) {
                // update dict with valid value and init
                var values = baselineValues
                values[props[propNum].name] = validValue
                let object = SwiftObject(value: values)
                verifySwiftObjectWithDictionaryLiteral(object, dictionary: values, boolObjectValue: true,
                    boolObjectListValues: [true, false])
            }
        }

        // test with invalid dictionary literals
        for propNum in 0..<props.count {
            for invalidValue in invalidValuesForSwiftObjectType(props[propNum].type) {
                // update dict with invalid value and init
                var values = baselineValues
                values[props[propNum].name] = invalidValue
                assertThrows(SwiftObject(value: values), "Invalid property value")
            }
        }
    }

    func testInitWithDefaultsAndDictionary() {
        // test with dictionary with mix of default and one specified value
        let object = SwiftObject(value: ["intCol": 200])
        let valueDict = defaultSwiftObjectValuesWithReplacements(["intCol": 200])
        verifySwiftObjectWithDictionaryLiteral(object, dictionary: valueDict, boolObjectValue: false,
            boolObjectListValues: [])
    }

    func testInitWithArray() {
        // array with all values specified
        let baselineValues = [true, 1, 1.1, 11.1, "b", "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData,
            NSDate(timeIntervalSince1970: 2) as NSDate, ["boolCol": true], [[true], [false]]] as [AnyObject]

        // test with valid dictionary literals
        let props = try! Realm().schema["SwiftObject"]!.properties
        for propNum in 0..<props.count {
            for validValue in validValuesForSwiftObjectType(props[propNum].type) {
                // update dict with valid value and init
                var values = baselineValues
                values[propNum] = validValue
                let object = SwiftObject(value: values)
                verifySwiftObjectWithArrayLiteral(object, array: values, boolObjectValue: true,
                    boolObjectListValues: [true, false])
            }
        }

        // test with invalid dictionary literals
        for propNum in 0..<props.count {
            for invalidValue in invalidValuesForSwiftObjectType(props[propNum].type) {
                // update dict with invalid value and init
                var values = baselineValues
                values[propNum] = invalidValue
                assertThrows(SwiftObject(value: values), "Invalid property value")
            }
        }
    }

    func testInitWithKVCObject() {
        // test with kvc object
        let objectWithInt = SwiftObject(value: ["intCol": 200])
        let objectWithKVCObject = SwiftObject(value: objectWithInt)
        let valueDict = defaultSwiftObjectValuesWithReplacements(["intCol": 200])
        verifySwiftObjectWithDictionaryLiteral(objectWithKVCObject, dictionary: valueDict, boolObjectValue: false,
            boolObjectListValues: [])
    }

    func testGenericInit() {
        func createObject<T: Object>() -> T {
            return T()
        }
        let obj1: SwiftBoolObject = createObject()
        let obj2 = SwiftBoolObject()
        XCTAssertEqual(obj1.boolCol, obj2.boolCol,
            "object created via generic initializer should equal object created by calling initializer directly")
    }

    // MARK: Creation tests

    func testCreateWithDefaults() {
        let realm = try! Realm()
        assertThrows(realm.create(SwiftObject), "Must be in write transaction")

        var object: SwiftObject!
        let objects = realm.objects(SwiftObject)
        XCTAssertEqual(0, objects.count)
        try! realm.write {
            // test create with all defaults
            object = realm.create(SwiftObject)
            return
        }
        verifySwiftObjectWithDictionaryLiteral(object, dictionary: SwiftObject.defaultValues(), boolObjectValue: false,
            boolObjectListValues: [])

        // test realm properties are populated correctly
        XCTAssertEqual(object.realm!, realm)
        XCTAssertEqual(object.objectCol!.realm!, realm)
        XCTAssertEqual(object.arrayCol.realm!, realm)
    }

    func testCreateWithOptionalWithoutDefaults() {
        let realm = try! Realm()
        try! realm.write {
            let object = realm.create(SwiftOptionalObject)
            for prop in object.objectSchema.properties {
                XCTAssertNil(object[prop.name])
            }
        }
    }

    func testCreateWithOptionalDefaults() {
        let realm = try! Realm()
        try! realm.write {
            let object = realm.create(SwiftOptionalDefaultValuesObject)
            self.verifySwiftOptionalObjectWithDictionaryLiteral(object,
                dictionary: SwiftOptionalDefaultValuesObject.defaultValues(), boolObjectValue: true)
        }
    }

    func testCreateWithOptionalIgnoredProperties() {
        let realm = try! Realm()
        try! realm.write {
            let object = realm.create(SwiftOptionalIgnoredPropertiesObject)
            let properties = object.objectSchema.properties
            XCTAssertEqual(properties, [])
        }
    }

    func testCreateWithDictionary() {
        // dictionary with all values specified
        let baselineValues: [String: AnyObject] = [
            "boolCol": true,
            "intCol": 1,
            "floatCol": 1.1,
            "doubleCol": 11.1,
            "stringCol": "b",
            "binaryCol": "b".dataUsingEncoding(NSUTF8StringEncoding)!,
            "dateCol": NSDate(timeIntervalSince1970: 2),
            "objectCol": SwiftBoolObject(value: [true]),
            "arrayCol": [SwiftBoolObject(value: [true]), SwiftBoolObject()]
        ]

        // test with valid dictionary literals
        let props = try! Realm().schema["SwiftObject"]!.properties
        for propNum in 0..<props.count {
            for validValue in validValuesForSwiftObjectType(props[propNum].type) {
                // update dict with valid value and init
                var values = baselineValues
                values[props[propNum].name] = validValue
                try! Realm().beginWrite()
                let object = try! Realm().create(SwiftObject.self, value: values)
                verifySwiftObjectWithDictionaryLiteral(object, dictionary: values, boolObjectValue: true,
                    boolObjectListValues: [true, false])
                try! Realm().commitWrite()
                verifySwiftObjectWithDictionaryLiteral(object, dictionary: values, boolObjectValue: true,
                    boolObjectListValues: [true, false])
            }
        }

        // test with invalid dictionary literals
        for propNum in 0..<props.count {
            for invalidValue in invalidValuesForSwiftObjectType(props[propNum].type) {
                // update dict with invalid value and init
                var values = baselineValues
                values[props[propNum].name] = invalidValue
                try! Realm().beginWrite()
                assertThrows(try! Realm().create(SwiftObject.self, value: values), "Invalid property value")
                try! Realm().cancelWrite()
            }
        }
    }

    func testCreateWithDefaultsAndDictionary() {
        // test with dictionary with mix of default and one specified value
        let realm = try! Realm()
        realm.beginWrite()
        let objectWithInt = realm.create(SwiftObject.self, value: ["intCol": 200])
        try! realm.commitWrite()

        let valueDict = defaultSwiftObjectValuesWithReplacements(["intCol": 200])
        verifySwiftObjectWithDictionaryLiteral(objectWithInt, dictionary: valueDict, boolObjectValue: false,
            boolObjectListValues: [])
    }

    func testCreateWithArray() {
        // array with all values specified
        let baselineValues = [true, 1, 1.1, 11.1, "b", "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData,
            NSDate(timeIntervalSince1970: 2) as NSDate, ["boolCol": true], [[true], [false]]] as [AnyObject]

        // test with valid dictionary literals
        let props = try! Realm().schema["SwiftObject"]!.properties
        for propNum in 0..<props.count {
            for validValue in validValuesForSwiftObjectType(props[propNum].type) {
                // update dict with valid value and init
                var values = baselineValues
                values[propNum] = validValue
                try! Realm().beginWrite()
                let object = try! Realm().create(SwiftObject.self, value: values)
                verifySwiftObjectWithArrayLiteral(object, array: values, boolObjectValue: true,
                    boolObjectListValues: [true, false])
                try! Realm().commitWrite()
                verifySwiftObjectWithArrayLiteral(object, array: values, boolObjectValue: true,
                    boolObjectListValues: [true, false])
            }
        }

        // test with invalid array literals
        for propNum in 0..<props.count {
            for invalidValue in invalidValuesForSwiftObjectType(props[propNum].type) {
                // update dict with invalid value and init
                var values = baselineValues
                values[propNum] = invalidValue

                try! Realm().beginWrite()
                assertThrows(try! Realm().create(SwiftObject.self, value: values),
                    "Invalid property value '\(invalidValue)' for property number \(propNum)")
                try! Realm().cancelWrite()
            }
        }
    }

    func testCreateWithKVCObject() {
        // test with kvc object
        try! Realm().beginWrite()
        let objectWithInt = try! Realm().create(SwiftObject.self, value: ["intCol": 200])
        let objectWithKVCObject = try! Realm().create(SwiftObject.self, value: objectWithInt)
        let valueDict = defaultSwiftObjectValuesWithReplacements(["intCol": 200])
        try! Realm().commitWrite()

        verifySwiftObjectWithDictionaryLiteral(objectWithKVCObject, dictionary: valueDict, boolObjectValue: false,
            boolObjectListValues: [])
        XCTAssertEqual(try! Realm().objects(SwiftObject).count, 2, "Object should have been copied")
    }

    func testCreateWithNestedObjects() {
        let standalone = SwiftPrimaryStringObject(value: ["p0", 11])

        try! Realm().beginWrite()
        let objectWithNestedObjects = try! Realm().create(SwiftLinkToPrimaryStringObject.self, value: ["p1", ["p1", 11],
            [standalone]])
        try! Realm().commitWrite()

        let stringObjects = try! Realm().objects(SwiftPrimaryStringObject)
        XCTAssertEqual(stringObjects.count, 2)
        let persistedObject = stringObjects.first!

        // standalone object should be copied into the realm, not added directly
        XCTAssertNotEqual(standalone, persistedObject)
        XCTAssertEqual(objectWithNestedObjects.object!, persistedObject)
        XCTAssertEqual(objectWithNestedObjects.objects.first!, stringObjects.last!)

        let standalone1 = SwiftPrimaryStringObject(value: ["p3", 11])
        try! Realm().beginWrite()
        assertThrows(try! Realm().create(SwiftLinkToPrimaryStringObject.self, value: ["p3", ["p3", 11], [standalone1]]),
            "Should throw with duplicate primary key")
        try! Realm().commitWrite()
    }

    func testUpdateWithNestedObjects() {
        let standalone = SwiftPrimaryStringObject(value: ["primary", 11])
        try! Realm().beginWrite()
        let object = try! Realm().create(SwiftLinkToPrimaryStringObject.self, value: ["otherPrimary", ["primary", 12],
            [["primary", 12]]], update: true)
        try! Realm().commitWrite()

        let stringObjects = try! Realm().objects(SwiftPrimaryStringObject)
        XCTAssertEqual(stringObjects.count, 1)
        let persistedObject = object.object!

        XCTAssertEqual(persistedObject.intCol, 12)
        XCTAssertNil(standalone.realm) // the standalone object should be copied, rather than added, to the realm
        XCTAssertEqual(object.object!, persistedObject)
        XCTAssertEqual(object.objects.first!, persistedObject)
    }

    func testCreateWithObjectsFromAnotherRealm() {
        let values = [
            "boolCol": true as NSNumber,
            "intCol": 1 as NSNumber,
            "floatCol": 1.1 as NSNumber,
            "doubleCol": 11.1 as NSNumber,
            "stringCol": "b" as NSString,
            "binaryCol": "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData,
            "dateCol": NSDate(timeIntervalSince1970: 2) as NSDate,
            "objectCol": SwiftBoolObject(value: [true]) as AnyObject,
            "arrayCol": [SwiftBoolObject(value: [true]), SwiftBoolObject()] as AnyObject,
        ]

        realmWithTestPath().beginWrite()
        let otherRealmObject = realmWithTestPath().create(SwiftObject.self, value: values)
        try! realmWithTestPath().commitWrite()

        try! Realm().beginWrite()
        let object = try! Realm().create(SwiftObject.self, value: otherRealmObject)
        try! Realm().commitWrite()

        XCTAssertNotEqual(otherRealmObject, object)
        verifySwiftObjectWithDictionaryLiteral(object, dictionary: values, boolObjectValue: true,
            boolObjectListValues: [true, false])
    }

    func testCreateWithDeeplyNestedObjectsFromAnotherRealm() {
        let values = [
            "boolCol": true as NSNumber,
            "intCol": 1 as NSNumber,
            "floatCol": 1.1 as NSNumber,
            "doubleCol": 11.1 as NSNumber,
            "stringCol": "b" as NSString,
            "binaryCol": "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData,
            "dateCol": NSDate(timeIntervalSince1970: 2) as NSDate,
            "objectCol": SwiftBoolObject(value: [true]) as AnyObject,
            "arrayCol": [SwiftBoolObject(value: [true]), SwiftBoolObject()] as AnyObject,
        ]

        let realmA = realmWithTestPath()
        let realmB = try! Realm()

        var realmAObject: SwiftListOfSwiftObject!
        try! realmA.write {
            let array = [SwiftObject(value: values), SwiftObject(value: values)]
            realmAObject = realmA.create(SwiftListOfSwiftObject.self, value: ["array": array])
        }

        var realmBObject: SwiftListOfSwiftObject!
        try! realmB.write {
            realmBObject = realmB.create(SwiftListOfSwiftObject.self, value: realmAObject)
        }

        XCTAssertNotEqual(realmAObject, realmBObject)
        XCTAssertEqual(realmBObject.array.count, 2)
        for swiftObject in realmBObject.array {
            verifySwiftObjectWithDictionaryLiteral(swiftObject, dictionary: values, boolObjectValue: true,
                boolObjectListValues: [true, false])
        }
    }

    func testUpdateWithObjectsFromAnotherRealm() {
        realmWithTestPath().beginWrite()
        let otherRealmObject = realmWithTestPath().create(SwiftLinkToPrimaryStringObject.self,
            value: ["primary", NSNull(), [["2", 2], ["4", 4]]])
        try! realmWithTestPath().commitWrite()

        try! Realm().beginWrite()
        try! Realm().create(SwiftLinkToPrimaryStringObject.self, value: ["primary", ["10", 10], [["11", 11]]])
        let object = try! Realm().create(SwiftLinkToPrimaryStringObject.self, value: otherRealmObject, update: true)
        try! Realm().commitWrite()

        XCTAssertNotEqual(otherRealmObject, object) // the object from the other realm should be copied into this realm
        XCTAssertEqual(try! Realm().objects(SwiftLinkToPrimaryStringObject).count, 1)
        XCTAssertEqual(try! Realm().objects(SwiftPrimaryStringObject).count, 4)
    }

    func testCreateWithNSNullLinks() {
        let values = [
            "boolCol": true as NSNumber,
            "intCol": 1 as NSNumber,
            "floatCol": 1.1 as NSNumber,
            "doubleCol": 11.1 as NSNumber,
            "stringCol": "b" as NSString,
            "binaryCol": "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData,
            "dateCol": NSDate(timeIntervalSince1970: 2) as NSDate,
            "objectCol": NSNull(),
            "arrayCol": NSNull(),
        ]

        realmWithTestPath().beginWrite()
        let object = realmWithTestPath().create(SwiftObject.self, value: values)
        try! realmWithTestPath().commitWrite()

        XCTAssert(object.objectCol == nil) // XCTAssertNil caused a NULL deref inside _swift_getClass
        XCTAssertEqual(object.arrayCol.count, 0)
    }

    // test null object
    // test null list

    // MARK: Add tests
    func testAddWithExisingNestedObjects() {
        try! Realm().beginWrite()
        let existingObject = try! Realm().create(SwiftBoolObject)
        try! Realm().commitWrite()

        try! Realm().beginWrite()
        let object = SwiftObject(value: ["objectCol" : existingObject])
        try! Realm().add(object)
        try! Realm().commitWrite()

        XCTAssertNotNil(object.realm)
        XCTAssertEqual(object.objectCol, existingObject)
    }

    func testAddAndUpdateWithExisingNestedObjects() {
        try! Realm().beginWrite()
        let existingObject = try! Realm().create(SwiftPrimaryStringObject.self, value: ["primary", 1])
        try! Realm().commitWrite()

        try! Realm().beginWrite()
        let object = SwiftLinkToPrimaryStringObject(value: ["primary", ["primary", 2], []])
        try! Realm().add(object, update: true)
        try! Realm().commitWrite()

        XCTAssertNotNil(object.realm)
        XCTAssertEqual(object.object!, existingObject) // the existing object should be updated
        XCTAssertEqual(existingObject.intCol, 2)
    }

    // MARK: Private utilities
    private func verifySwiftObjectWithArrayLiteral(object: SwiftObject, array: [AnyObject], boolObjectValue: Bool,
                                                   boolObjectListValues: [Bool]) {
        XCTAssertEqual(object.boolCol, (array[0] as! Bool))
        XCTAssertEqual(object.intCol, (array[1] as! Int))
        XCTAssertEqual(object.floatCol, (array[2] as! Float))
        XCTAssertEqual(object.doubleCol, (array[3] as! Double))
        XCTAssertEqual(object.stringCol, (array[4] as! String))
        XCTAssertEqual(object.binaryCol, (array[5] as! NSData))
        XCTAssertEqual(object.dateCol, (array[6] as! NSDate))
        XCTAssertEqual(object.objectCol!.boolCol, boolObjectValue)
        XCTAssertEqual(object.arrayCol.count, boolObjectListValues.count)
        for i in 0..<boolObjectListValues.count {
            XCTAssertEqual(object.arrayCol[i].boolCol, boolObjectListValues[i])
        }
    }

    private func verifySwiftObjectWithDictionaryLiteral(object: SwiftObject, dictionary: [String:AnyObject],
                                                        boolObjectValue: Bool, boolObjectListValues: [Bool]) {
        XCTAssertEqual(object.boolCol, (dictionary["boolCol"] as! Bool))
        XCTAssertEqual(object.intCol, (dictionary["intCol"] as! Int))
        XCTAssertEqual(object.floatCol, (dictionary["floatCol"] as! Float))
        XCTAssertEqual(object.doubleCol, (dictionary["doubleCol"] as! Double))
        XCTAssertEqual(object.stringCol, (dictionary["stringCol"] as! String))
        XCTAssertEqual(object.binaryCol, (dictionary["binaryCol"] as! NSData))
        XCTAssertEqual(object.dateCol, (dictionary["dateCol"] as! NSDate))
        XCTAssertEqual(object.objectCol!.boolCol, boolObjectValue)
        XCTAssertEqual(object.arrayCol.count, boolObjectListValues.count)
        for i in 0..<boolObjectListValues.count {
            XCTAssertEqual(object.arrayCol[i].boolCol, boolObjectListValues[i])
        }
    }

    private func verifySwiftOptionalObjectWithDictionaryLiteral(object: SwiftOptionalDefaultValuesObject,
                                                                dictionary: [String:AnyObject],
                                                                boolObjectValue: Bool?) {
        XCTAssertEqual(object.optBoolCol.value, (dictionary["optBoolCol"] as! Bool?))
        XCTAssertEqual(object.optIntCol.value, (dictionary["optIntCol"] as! Int?))
        XCTAssertEqual(object.optInt8Col.value,
                       ((dictionary["optInt8Col"] as! NSNumber?)?.longValue).map({Int8($0)}))
        XCTAssertEqual(object.optInt16Col.value,
                       ((dictionary["optInt16Col"] as! NSNumber?)?.longValue).map({Int16($0)}))
        XCTAssertEqual(object.optInt32Col.value,
            ((dictionary["optInt32Col"] as! NSNumber?)?.longValue).map({Int32($0)}))
        XCTAssertEqual(object.optInt64Col.value, (dictionary["optInt64Col"] as! NSNumber?)?.longLongValue)
        XCTAssertEqual(object.optFloatCol.value, (dictionary["optFloatCol"] as! Float?))
        XCTAssertEqual(object.optDoubleCol.value, (dictionary["optDoubleCol"] as! Double?))
        XCTAssertEqual(object.optStringCol, (dictionary["optStringCol"] as! String?))
        XCTAssertEqual(object.optNSStringCol, (dictionary["optNSStringCol"] as! String?))
        XCTAssertEqual(object.optBinaryCol, (dictionary["optBinaryCol"] as! NSData?))
        XCTAssertEqual(object.optDateCol, (dictionary["optDateCol"] as! NSDate?))
        XCTAssertEqual(object.optObjectCol?.boolCol, boolObjectValue)
    }

    private func defaultSwiftObjectValuesWithReplacements(replace: [String: AnyObject]) -> [String: AnyObject] {
        var valueDict = SwiftObject.defaultValues()
        for (key, value) in replace {
            valueDict[key] = value
        }
        return valueDict
    }

    // return an array of valid values that can be used to initialize each type
    // swiftlint:disable:next cyclomatic_complexity
    private func validValuesForSwiftObjectType(type: PropertyType) -> [AnyObject] {
        try! Realm().beginWrite()
        let persistedObject = try! Realm().create(SwiftBoolObject.self, value: [true])
        try! Realm().commitWrite()
        switch type {
            case .Bool:     return [true, 0 as Int, 1 as Int]
            case .Int:      return [1 as Int]
            case .Float:    return [1 as Int, 1.1 as Float, 11.1 as Double]
            case .Double:   return [1 as Int, 1.1 as Float, 11.1 as Double]
            case .String:   return ["b"]
            case .Data:     return ["b".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)! as NSData]
            case .Date:     return [NSDate(timeIntervalSince1970: 2) as AnyObject]
            case .Object:   return [[true], ["boolCol": true], SwiftBoolObject(value: [true]), persistedObject]
            case .Array:    return [
                [[true], [false]],
                [["boolCol": true], ["boolCol": false]],
                [SwiftBoolObject(value: [true]), SwiftBoolObject(value: [false])],
                [persistedObject, [false]]
            ]
            case .Any:      XCTFail("not supported")
        }
        return []
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func invalidValuesForSwiftObjectType(type: PropertyType) -> [AnyObject] {
        try! Realm().beginWrite()
        let persistedObject = try! Realm().create(SwiftIntObject)
        try! Realm().commitWrite()
        switch type {
            case .Bool:     return ["invalid", 2 as Int, 1.1 as Float, 11.1 as Double]
            case .Int:      return ["invalid", 1.1 as Float, 11.1 as Double]
            case .Float:    return ["invalid", true, false]
            case .Double:   return ["invalid", true, false]
            case .String:   return [0x197A71D, true, false]
            case .Data:     return ["invalid"]
            case .Date:     return ["invalid"]
            case .Object:   return ["invalid", ["a"], ["boolCol": "a"], SwiftIntObject()]
            case .Array:    return ["invalid", [["a"]], [["boolCol" : "a"]], [[SwiftIntObject()]], [[persistedObject]]]
            case .Any:      XCTFail("not supported")
        }
        return []
    }
}
