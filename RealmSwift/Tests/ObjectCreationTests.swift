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
import Foundation

class ObjectCreationTests: TestCase {

    // MARK: Init tests
    func testInitWithDefaults() {
        // test all properties are defaults
        let object = AllTypesObject()
        XCTAssertNil(object.realm)

        // test defaults values
        verifyAllTypesObjectWithDictionaryLiteral(object, dictionary: AllTypesObject.defaultValues(), boolObjectValue: false, boolObjectListValues: [])

        // test realm properties are nil for standalone
        XCTAssertNil(object.realm)
        XCTAssertNil(object.objectCol.realm)
        XCTAssertNil(object.arrayCol.realm)
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
            "objectCol": BoolObject(value: [true]) as AnyObject,
            "arrayCol": [BoolObject(value: [true]), BoolObject()]  as AnyObject
           ]

        // test with valid dictionary literals
        let props = Realm().schema["AllTypesObject"]!.properties
        for propNum in 0..<props.count {
            for validValue in validValuesForAllTypesObjectType(props[propNum].type) {
                // update dict with valid value and init
                var values = baselineValues
                values[props[propNum].name] = validValue
                let object = AllTypesObject(value: values)
                verifyAllTypesObjectWithDictionaryLiteral(object, dictionary: values, boolObjectValue: true, boolObjectListValues: [true, false])
            }
        }

        // test with invalid dictionary literals
        for propNum in 0..<props.count {
            for invalidValue in invalidValuesForAllTypesObjectType(props[propNum].type) {
                // update dict with invalid value and init
                var values = baselineValues
                values[props[propNum].name] = invalidValue
                assertThrows(AllTypesObject(value: values), "Invalid property value")
            }
        }
    }

    func testInitWithDefaultsAndDictionary() {
        // test with dictionary with mix of default and one specified value
        let object = AllTypesObject(value: ["intCol": 200])
        let valueDict = defaultAllTypesObjectValuesWithReplacements(["intCol": 200])
        verifyAllTypesObjectWithDictionaryLiteral(object, dictionary: valueDict, boolObjectValue: false, boolObjectListValues: [])
    }

    func testInitWithArray() {
        // array with all values specified
        let baselineValues = [true, 1, 1.1, 11.1, "b", "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData, NSDate(timeIntervalSince1970: 2) as NSDate, ["boolCol": true], [[true], [false]]] as [AnyObject]

        // test with valid dictionary literals
        let props = Realm().schema["AllTypesObject"]!.properties
        for propNum in 0..<props.count {
            for validValue in validValuesForAllTypesObjectType(props[propNum].type) {
                // update dict with valid value and init
                var values = baselineValues
                values[propNum] = validValue
                let object = AllTypesObject(value: values)
                verifyAllTypesObjectWithArrayLiteral(object, array: values, boolObjectValue: true, boolObjectListValues: [true, false])
            }
        }

        // test with invalid dictionary literals
        for propNum in 0..<props.count {
            for invalidValue in invalidValuesForAllTypesObjectType(props[propNum].type) {
                // update dict with invalid value and init
                var values = baselineValues
                values[propNum] = invalidValue
                assertThrows(AllTypesObject(value: values), "Invalid property value")
            }
        }
    }

    func testInitWithKVCObject() {
        // test with kvc object
        let objectWithInt = AllTypesObject(value: ["intCol": 200])
        let objectWithKVCObject = AllTypesObject(value: objectWithInt)
        let valueDict = defaultAllTypesObjectValuesWithReplacements(["intCol": 200])
        verifyAllTypesObjectWithDictionaryLiteral(objectWithKVCObject, dictionary: valueDict, boolObjectValue: false, boolObjectListValues: [])
    }

    // MARK: Creation tests

    func testCreateWithDefaults() {
        let realm = Realm()
        assertThrows(realm.create(AllTypesObject.self), "Must be in write transaction")

        var object: AllTypesObject!
        let objects = realm.objects(AllTypesObject)
        XCTAssertEqual(0, objects.count)
        realm.write {
            // test create with all defaults
            object = realm.create(AllTypesObject.self)
            return
        }
        verifyAllTypesObjectWithDictionaryLiteral(object, dictionary: AllTypesObject.defaultValues(), boolObjectValue: false, boolObjectListValues: [])

        // test realm properties are populated correctly
        XCTAssertEqual(object.realm!, realm)
        XCTAssertEqual(object.objectCol.realm!, realm)
        XCTAssertEqual(object.arrayCol.realm!, realm)
    }

    func testCreateWithDictionary() {
        // dictionary with all values specified
        let baselineValues =
            ["boolCol": true as NSNumber,
                "intCol": 1 as NSNumber,
                "floatCol": 1.1 as NSNumber,
                "doubleCol": 11.1 as NSNumber,
                "stringCol": "b" as NSString,
                "binaryCol": "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData,
                "dateCol": NSDate(timeIntervalSince1970: 2) as NSDate,
                "objectCol": BoolObject(value: [true]) as AnyObject,
                "arrayCol": [BoolObject(value: [true]), BoolObject()]  as AnyObject
            ]

        // test with valid dictionary literals
        let props = Realm().schema["AllTypesObject"]!.properties
        for propNum in 0..<props.count {
            for validValue in validValuesForAllTypesObjectType(props[propNum].type) {
                // update dict with valid value and init
                var values = baselineValues
                values[props[propNum].name] = validValue
                Realm().beginWrite()
                let object = Realm().create(AllTypesObject.self, value: values)
                verifyAllTypesObjectWithDictionaryLiteral(object, dictionary: values, boolObjectValue: true, boolObjectListValues: [true, false])
                Realm().commitWrite()
                verifyAllTypesObjectWithDictionaryLiteral(object, dictionary: values, boolObjectValue: true, boolObjectListValues: [true, false])
            }
        }

        // test with invalid dictionary literals
        for propNum in 0..<props.count {
            for invalidValue in invalidValuesForAllTypesObjectType(props[propNum].type) {
                // update dict with invalid value and init
                var values = baselineValues
                values[props[propNum].name] = invalidValue
                Realm().beginWrite()
                assertThrows(Realm().create(AllTypesObject.self, value: values), "Invalid property value")
                Realm().cancelWrite()
            }
        }
    }

    func testCreateWithDefaultsAndDictionary() {
        // test with dictionary with mix of default and one specified value
        let realm = Realm()
        realm.beginWrite()
        let objectWithInt = realm.create(AllTypesObject.self, value: ["intCol": 200])
        realm.commitWrite()

        let valueDict = defaultAllTypesObjectValuesWithReplacements(["intCol": 200])
        verifyAllTypesObjectWithDictionaryLiteral(objectWithInt, dictionary: valueDict, boolObjectValue: false, boolObjectListValues: [])
    }

    func testCreateWithArray() {
        // array with all values specified
        let baselineValues = [true, 1, 1.1, 11.1, "b", "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData, NSDate(timeIntervalSince1970: 2) as NSDate, ["boolCol": true], [[true], [false]]] as [AnyObject]

        // test with valid dictionary literals
        let props = Realm().schema["AllTypesObject"]!.properties
        for propNum in 0..<props.count {
            for validValue in validValuesForAllTypesObjectType(props[propNum].type) {
                // update dict with valid value and init
                var values = baselineValues
                values[propNum] = validValue
                Realm().beginWrite()
                let object = Realm().create(AllTypesObject.self, value: values)
                verifyAllTypesObjectWithArrayLiteral(object, array: values, boolObjectValue: true, boolObjectListValues: [true, false])
                Realm().commitWrite()
                verifyAllTypesObjectWithArrayLiteral(object, array: values, boolObjectValue: true, boolObjectListValues: [true, false])
            }
        }

        // test with invalid array literals
        for propNum in 0..<props.count {
            for invalidValue in invalidValuesForAllTypesObjectType(props[propNum].type) {
                // update dict with invalid value and init
                var values = baselineValues
                values[propNum] = invalidValue

                Realm().beginWrite()
                assertThrows(Realm().create(AllTypesObject.self, value: values), "Invalid property value '\(invalidValue)' for property number \(propNum)")
                Realm().cancelWrite()
            }
        }
    }

    func testCreateWithKVCObject() {
        // test with kvc object
        Realm().beginWrite()
        let objectWithInt = Realm().create(AllTypesObject.self, value: ["intCol": 200])
        let objectWithKVCObject = Realm().create(AllTypesObject.self, value: objectWithInt)
        let valueDict = defaultAllTypesObjectValuesWithReplacements(["intCol": 200])
        Realm().commitWrite()

        verifyAllTypesObjectWithDictionaryLiteral(objectWithKVCObject, dictionary: valueDict, boolObjectValue: false, boolObjectListValues: [])
        XCTAssertEqual(Realm().objects(AllTypesObject).count, 2, "Object should have been copied")
    }

    func testCreateWithNestedObjects() {
        let standalone = PrimaryStringObject(value: ["primary", 11])
        Realm().beginWrite()
        let objectWithNestedObjects = Realm().create(LinkToPrimaryStringObject.self, value: ["primary", ["primary", 11], [standalone]])
        Realm().commitWrite()

        let stringObjects = Realm().objects(PrimaryStringObject)
        XCTAssertEqual(stringObjects.count, 1)
        let persistedObject = stringObjects.first!

        XCTAssertNotEqual(standalone, persistedObject) // standalone object should be copied into the realm, not added directly
        XCTAssertEqual(objectWithNestedObjects.object!, persistedObject)
        XCTAssertEqual(objectWithNestedObjects.objects.first!, persistedObject)
    }

    func testUpdateWithNestedObjects() {
        let standalone = PrimaryStringObject(value: ["primary", 11])
        Realm().beginWrite()
        let object = Realm().create(LinkToPrimaryStringObject.self, value: ["otherPrimary", standalone, [["primary", 12]]], update: true)
        Realm().commitWrite()

        let stringObjects = Realm().objects(PrimaryStringObject)
        XCTAssertEqual(stringObjects.count, 1)
        let persistedObject = object.object!

        XCTAssertEqual(persistedObject.intCol, 12)
        XCTAssertNil(standalone.realm) // the standalone object should be copied, rather than added, to the realm
        XCTAssertEqual(object.object!, persistedObject)
        XCTAssertEqual(object.objects.first!, persistedObject)
    }

    // This doesn't yet work, as RLMIsObjectValidForProperty doesn't take into account the target Realm,
    // so we end up trying to just add a link to another Realm, which raises an exception.
//    func testCreateWithObjectsFromAnotherRealm() {
//        let values = [
//            "boolCol": true as NSNumber,
//            "intCol": 1 as NSNumber,
//            "floatCol": 1.1 as NSNumber,
//            "doubleCol": 11.1 as NSNumber,
//            "stringCol": "b" as NSString,
//            "binaryCol": "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData,
//            "dateCol": NSDate(timeIntervalSince1970: 2) as NSDate,
//            "objectCol": BoolObject(object: [true]) as AnyObject,
//            "arrayCol": [BoolObject(object: [true]), BoolObject()]  as AnyObject,
//        ]
//
//        realmWithTestPath().beginWrite()
//        let otherRealmObject = realmWithTestPath().create(AllTypesObject.self, value: values)
//        realmWithTestPath().commitWrite()
//
//        Realm().beginWrite()
//        let object = Realm().create(AllTypesObject.self, value: otherRealmObject)
//        Realm().commitWrite()
//
//        XCTAssertNotEqual(otherRealmObject, object)
//        verifyAllTypesObjectWithDictionaryLiteral(object, dictionary: values, boolObjectValue: true, boolObjectListValues: [true, false])
//    }

    func testUpdateWithObjectsFromAnotherRealm() {
        realmWithTestPath().beginWrite()
        let otherRealmObject = realmWithTestPath().create(LinkToPrimaryStringObject.self, value: ["primary", NSNull(), [["2", 2], ["4", 4]]])
        realmWithTestPath().commitWrite()

        Realm().beginWrite()
        Realm().create(LinkToPrimaryStringObject.self, value: ["primary", ["10", 10], [["11", 11]]])
        let object = Realm().create(LinkToPrimaryStringObject.self, value: otherRealmObject, update: true)
        Realm().commitWrite()

        XCTAssertNotEqual(otherRealmObject, object) // the object from the other realm should be copied into this realm
        XCTAssertEqual(Realm().objects(LinkToPrimaryStringObject).count, 1)
        XCTAssertEqual(Realm().objects(PrimaryStringObject).count, 4)
    }

    // test NSNull for object
    // test NSNull for list
    // test null object
    // test null list
    // test literals with standalone objects
    // test literals with existing objects
    // test literals with existing lists

    // MARK: Add tests
    func testAddWithExisingNestedObjects() {
        Realm().beginWrite()
        let existingObject = Realm().create(BoolObject)
        Realm().commitWrite()

        Realm().beginWrite()
        let object = AllTypesObject(value: ["objectCol" : existingObject])
        Realm().add(object)
        Realm().commitWrite()

        XCTAssertNotNil(object.realm)
        XCTAssertEqual(object.objectCol, existingObject)
    }

    func testAddAndUpdateWithExisingNestedObjects() {
        Realm().beginWrite()
        let existingObject = Realm().create(PrimaryStringObject.self, value: ["primary", 1])
        Realm().commitWrite()

        Realm().beginWrite()
        let object = LinkToPrimaryStringObject(value: ["primary", ["primary", 2], []])
        Realm().add(object, update: true)
        Realm().commitWrite()

        XCTAssertNotNil(object.realm)
        XCTAssertEqual(object.object!, existingObject) // the existing object should be updated
        XCTAssertEqual(existingObject.intCol, 2)
    }

    // MARK: Private utilities
    private func verifyAllTypesObjectWithArrayLiteral(object: AllTypesObject, array: [AnyObject], boolObjectValue: Bool, boolObjectListValues: [Bool]) {
        XCTAssertEqual(object.boolCol, array[0] as Bool)
        XCTAssertEqual(object.intCol, array[1] as Int)
        XCTAssertEqual(object.floatCol, array[2] as Float)
        XCTAssertEqual(object.doubleCol, array[3] as Double)
        XCTAssertEqual(object.stringCol, array[4] as String)
        XCTAssertEqual(object.binaryCol, array[5] as NSData)
        XCTAssertEqual(object.dateCol, array[6] as NSDate)
        XCTAssertEqual(object.objectCol.boolCol, boolObjectValue)
        XCTAssertEqual(object.arrayCol.count, boolObjectListValues.count)
        for i in 0..<boolObjectListValues.count {
            XCTAssertEqual(object.arrayCol[i].boolCol, boolObjectListValues[i])
        }
    }

    private func verifyAllTypesObjectWithDictionaryLiteral(object: AllTypesObject, dictionary: [String:AnyObject], boolObjectValue: Bool, boolObjectListValues: [Bool]) {
        XCTAssertEqual(object.boolCol, dictionary["boolCol"] as Bool)
        XCTAssertEqual(object.intCol, dictionary["intCol"] as Int)
        XCTAssertEqual(object.floatCol, dictionary["floatCol"] as Float)
        XCTAssertEqual(object.doubleCol, dictionary["doubleCol"] as Double)
        XCTAssertEqual(object.stringCol, dictionary["stringCol"] as String)
        XCTAssertEqual(object.binaryCol, dictionary["binaryCol"] as NSData)
        XCTAssertEqual(object.dateCol, dictionary["dateCol"] as NSDate)
        XCTAssertEqual(object.objectCol.boolCol, boolObjectValue)
        XCTAssertEqual(object.arrayCol.count, boolObjectListValues.count)
        for i in 0..<boolObjectListValues.count {
            XCTAssertEqual(object.arrayCol[i].boolCol, boolObjectListValues[i])
        }
    }

    private func defaultAllTypesObjectValuesWithReplacements(replace: [String: AnyObject]) -> [String: AnyObject] {
        var valueDict = AllTypesObject.defaultValues()
        for (key, value) in replace {
            valueDict[key] = value
        }
        return valueDict
    }

    // return an array of valid values that can be used to initialize each type
    private func validValuesForAllTypesObjectType(type: PropertyType) -> [AnyObject] {
        Realm().beginWrite()
        let persistedObject = Realm().create(BoolObject.self, value: [true])
        Realm().commitWrite()
        switch type {
            case .Bool:     return [true, 0 as Int, 1 as Int]
            case .Int:      return [1 as Int]
            case .Float:    return [1 as Int, 1.1 as Float, 11.1 as Double]
            case .Double:   return [1 as Int, 1.1 as Float, 11.1 as Double]
            case .String:   return ["b"]
            case .Data:     return ["b".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)! as NSData]
            case .Date:     return [NSDate(timeIntervalSince1970: 2) as AnyObject]
            case .Object:   return [[true], ["boolCol": true], BoolObject(value: [true]), persistedObject]
            case .Array:    return [[[true], [false]], [["boolCol": true], ["boolCol": false]], [BoolObject(value: [true]), BoolObject(value: [false])], [persistedObject, [false]]]
            case .Any:      XCTFail("not supported")
        }
        return []
    }

    private func invalidValuesForAllTypesObjectType(type: PropertyType) -> [AnyObject] {
        Realm().beginWrite()
        let persistedObject = Realm().create(IntObject)
        Realm().commitWrite()
        switch type {
            case .Bool:     return ["invalid", 2 as Int, 1.1 as Float, 11.1 as Double]
            case .Int:      return ["invalid", true, false, 1.1 as Float, 11.1 as Double]
            case .Float:    return ["invalid", true, false]
            case .Double:   return ["invalid", true, false]
            case .String:   return [0x197A71D, true, false]
            case .Data:     return ["invalid"]
            case .Date:     return ["invalid"]
            case .Object:   return ["invalid", ["a"], ["boolCol": "a"], IntObject()]
            case .Array:    return ["invalid", [["a"]], [["boolCol" : "a"]], [[IntObject()]], [[persistedObject]]]
            case .Any:      XCTFail("not supported")
        }
        return []
    }
}

