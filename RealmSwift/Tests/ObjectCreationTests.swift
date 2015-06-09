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
        let object = SwiftObject()
        XCTAssertNil(object.realm)

        // test defaults values
        verifySwiftObjectWithDictionaryLiteral(object, dictionary: SwiftObject.defaultValues(), boolObjectValue: false, boolObjectListValues: [])

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
            "objectCol": SwiftBoolObject(value: [true]) as AnyObject,
            "arrayCol": [SwiftBoolObject(value: [true]), SwiftBoolObject()]  as AnyObject
           ]

        // test with valid dictionary literals
        let props = Realm().schema["SwiftObject"]!.properties
        for propNum in 0..<props.count {
            for validValue in validValuesForSwiftObjectType(props[propNum].type) {
                // update dict with valid value and init
                var values = baselineValues
                values[props[propNum].name] = validValue
                let object = SwiftObject(value: values)
                verifySwiftObjectWithDictionaryLiteral(object, dictionary: values, boolObjectValue: true, boolObjectListValues: [true, false])
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
        verifySwiftObjectWithDictionaryLiteral(object, dictionary: valueDict, boolObjectValue: false, boolObjectListValues: [])
    }

    func testInitWithArray() {
        // array with all values specified
        let baselineValues = [true, 1, 1.1, 11.1, "b", "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData, NSDate(timeIntervalSince1970: 2) as NSDate, ["boolCol": true], [[true], [false]]] as [AnyObject]

        // test with valid dictionary literals
        let props = Realm().schema["SwiftObject"]!.properties
        for propNum in 0..<props.count {
            for validValue in validValuesForSwiftObjectType(props[propNum].type) {
                // update dict with valid value and init
                var values = baselineValues
                values[propNum] = validValue
                let object = SwiftObject(value: values)
                verifySwiftObjectWithArrayLiteral(object, array: values, boolObjectValue: true, boolObjectListValues: [true, false])
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
        verifySwiftObjectWithDictionaryLiteral(objectWithKVCObject, dictionary: valueDict, boolObjectValue: false, boolObjectListValues: [])
    }

    func testGenericInit() {
        func createObject<T: Object>() -> T {
            return T()
        }
        let obj1: SwiftBoolObject = createObject()
        let obj2 = SwiftBoolObject()
        XCTAssertEqual(obj1.boolCol, obj2.boolCol, "object created via generic initializer should equal object created by calling initializer directly")
    }

    // MARK: Creation tests

    func testCreateWithDefaults() {
        let realm = Realm()
        assertThrows(realm.create(SwiftObject), "Must be in write transaction")

        var object: SwiftObject!
        let objects = realm.objects(SwiftObject)
        XCTAssertEqual(0, objects.count)
        realm.write {
            // test create with all defaults
            object = realm.create(SwiftObject)
            return
        }
        verifySwiftObjectWithDictionaryLiteral(object, dictionary: SwiftObject.defaultValues(), boolObjectValue: false, boolObjectListValues: [])

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
                "objectCol": SwiftBoolObject(value: [true]) as AnyObject,
                "arrayCol": [SwiftBoolObject(value: [true]), SwiftBoolObject()]  as AnyObject
            ]

        // test with valid dictionary literals
        let props = Realm().schema["SwiftObject"]!.properties
        for propNum in 0..<props.count {
            for validValue in validValuesForSwiftObjectType(props[propNum].type) {
                // update dict with valid value and init
                var values = baselineValues
                values[props[propNum].name] = validValue
                Realm().beginWrite()
                let object = Realm().create(SwiftObject.self, value: values)
                verifySwiftObjectWithDictionaryLiteral(object, dictionary: values, boolObjectValue: true, boolObjectListValues: [true, false])
                Realm().commitWrite()
                verifySwiftObjectWithDictionaryLiteral(object, dictionary: values, boolObjectValue: true, boolObjectListValues: [true, false])
            }
        }

        // test with invalid dictionary literals
        for propNum in 0..<props.count {
            for invalidValue in invalidValuesForSwiftObjectType(props[propNum].type) {
                // update dict with invalid value and init
                var values = baselineValues
                values[props[propNum].name] = invalidValue
                Realm().beginWrite()
                assertThrows(Realm().create(SwiftObject.self, value: values), "Invalid property value")
                Realm().cancelWrite()
            }
        }
    }

    func testCreateWithDefaultsAndDictionary() {
        // test with dictionary with mix of default and one specified value
        let realm = Realm()
        realm.beginWrite()
        let objectWithInt = realm.create(SwiftObject.self, value: ["intCol": 200])
        realm.commitWrite()

        let valueDict = defaultSwiftObjectValuesWithReplacements(["intCol": 200])
        verifySwiftObjectWithDictionaryLiteral(objectWithInt, dictionary: valueDict, boolObjectValue: false, boolObjectListValues: [])
    }

    func testCreateWithArray() {
        // array with all values specified
        let baselineValues = [true, 1, 1.1, 11.1, "b", "b".dataUsingEncoding(NSUTF8StringEncoding)! as NSData, NSDate(timeIntervalSince1970: 2) as NSDate, ["boolCol": true], [[true], [false]]] as [AnyObject]

        // test with valid dictionary literals
        let props = Realm().schema["SwiftObject"]!.properties
        for propNum in 0..<props.count {
            for validValue in validValuesForSwiftObjectType(props[propNum].type) {
                // update dict with valid value and init
                var values = baselineValues
                values[propNum] = validValue
                Realm().beginWrite()
                let object = Realm().create(SwiftObject.self, value: values)
                verifySwiftObjectWithArrayLiteral(object, array: values, boolObjectValue: true, boolObjectListValues: [true, false])
                Realm().commitWrite()
                verifySwiftObjectWithArrayLiteral(object, array: values, boolObjectValue: true, boolObjectListValues: [true, false])
            }
        }

        // test with invalid array literals
        for propNum in 0..<props.count {
            for invalidValue in invalidValuesForSwiftObjectType(props[propNum].type) {
                // update dict with invalid value and init
                var values = baselineValues
                values[propNum] = invalidValue

                Realm().beginWrite()
                assertThrows(Realm().create(SwiftObject.self, value: values), "Invalid property value '\(invalidValue)' for property number \(propNum)")
                Realm().cancelWrite()
            }
        }
    }

    func testCreateWithKVCObject() {
        // test with kvc object
        Realm().beginWrite()
        let objectWithInt = Realm().create(SwiftObject.self, value: ["intCol": 200])
        let objectWithKVCObject = Realm().create(SwiftObject.self, value: objectWithInt)
        let valueDict = defaultSwiftObjectValuesWithReplacements(["intCol": 200])
        Realm().commitWrite()

        verifySwiftObjectWithDictionaryLiteral(objectWithKVCObject, dictionary: valueDict, boolObjectValue: false, boolObjectListValues: [])
        XCTAssertEqual(Realm().objects(SwiftObject).count, 2, "Object should have been copied")
    }

    func testCreateWithNestedObjects() {
        let standalone = SwiftPrimaryStringObject(value: ["p0", 11])

        Realm().beginWrite()
        let objectWithNestedObjects = Realm().create(SwiftLinkToPrimaryStringObject.self, value: ["p1", ["p1", 11], [standalone]])
        Realm().commitWrite()

        let stringObjects = Realm().objects(SwiftPrimaryStringObject)
        XCTAssertEqual(stringObjects.count, 2)
        let persistedObject = stringObjects.first!

        XCTAssertNotEqual(standalone, persistedObject) // standalone object should be copied into the realm, not added directly
        XCTAssertEqual(objectWithNestedObjects.object!, persistedObject)
        XCTAssertEqual(objectWithNestedObjects.objects.first!, stringObjects.last!)

        let standalone1 = SwiftPrimaryStringObject(value: ["p3", 11])
        Realm().beginWrite()
        assertThrows(Realm().create(SwiftLinkToPrimaryStringObject.self, value: ["p3", ["p3", 11], [standalone1]]), "Should throw with duplicate primary key")
        Realm().commitWrite()
    }

    func testUpdateWithNestedObjects() {
        let standalone = SwiftPrimaryStringObject(value: ["primary", 11])
        Realm().beginWrite()
        let object = Realm().create(SwiftLinkToPrimaryStringObject.self, value: ["otherPrimary", ["primary", 12], [["primary", 12]]], update: true)
        Realm().commitWrite()

        let stringObjects = Realm().objects(SwiftPrimaryStringObject)
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
        realmWithTestPath().commitWrite()

        Realm().beginWrite()
        let object = Realm().create(SwiftObject.self, value: otherRealmObject)
        Realm().commitWrite()

        XCTAssertNotEqual(otherRealmObject, object)
        verifySwiftObjectWithDictionaryLiteral(object, dictionary: values, boolObjectValue: true, boolObjectListValues: [true, false])
    }

    func testUpdateWithObjectsFromAnotherRealm() {
        realmWithTestPath().beginWrite()
        let otherRealmObject = realmWithTestPath().create(SwiftLinkToPrimaryStringObject.self, value: ["primary", NSNull(), [["2", 2], ["4", 4]]])
        realmWithTestPath().commitWrite()

        Realm().beginWrite()
        Realm().create(SwiftLinkToPrimaryStringObject.self, value: ["primary", ["10", 10], [["11", 11]]])
        let object = Realm().create(SwiftLinkToPrimaryStringObject.self, value: otherRealmObject, update: true)
        Realm().commitWrite()

        XCTAssertNotEqual(otherRealmObject, object) // the object from the other realm should be copied into this realm
        XCTAssertEqual(Realm().objects(SwiftLinkToPrimaryStringObject).count, 1)
        XCTAssertEqual(Realm().objects(SwiftPrimaryStringObject).count, 4)
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
        realmWithTestPath().commitWrite()

        XCTAssertNil(object.objectCol)
        XCTAssertEqual(object.arrayCol.count, 0)
    }

    // test null object
    // test null list

    // MARK: Add tests
    func testAddWithExisingNestedObjects() {
        Realm().beginWrite()
        let existingObject = Realm().create(SwiftBoolObject)
        Realm().commitWrite()

        Realm().beginWrite()
        let object = SwiftObject(value: ["objectCol" : existingObject])
        Realm().add(object)
        Realm().commitWrite()

        XCTAssertNotNil(object.realm)
        XCTAssertEqual(object.objectCol, existingObject)
    }

    func testAddAndUpdateWithExisingNestedObjects() {
        Realm().beginWrite()
        let existingObject = Realm().create(SwiftPrimaryStringObject.self, value: ["primary", 1])
        Realm().commitWrite()

        Realm().beginWrite()
        let object = SwiftLinkToPrimaryStringObject(value: ["primary", ["primary", 2], []])
        Realm().add(object, update: true)
        Realm().commitWrite()

        XCTAssertNotNil(object.realm)
        XCTAssertEqual(object.object!, existingObject) // the existing object should be updated
        XCTAssertEqual(existingObject.intCol, 2)
    }

    // MARK: Private utilities
    private func verifySwiftObjectWithArrayLiteral(object: SwiftObject, array: [AnyObject], boolObjectValue: Bool, boolObjectListValues: [Bool]) {
        XCTAssertEqual(object.boolCol, array[0] as! Bool)
        XCTAssertEqual(object.intCol, array[1] as! Int)
        XCTAssertEqual(object.floatCol, array[2] as! Float)
        XCTAssertEqual(object.doubleCol, array[3] as! Double)
        XCTAssertEqual(object.stringCol, array[4] as! String)
        XCTAssertEqual(object.binaryCol, array[5] as! NSData)
        XCTAssertEqual(object.dateCol, array[6] as! NSDate)
        XCTAssertEqual(object.objectCol.boolCol, boolObjectValue)
        XCTAssertEqual(object.arrayCol.count, boolObjectListValues.count)
        for i in 0..<boolObjectListValues.count {
            XCTAssertEqual(object.arrayCol[i].boolCol, boolObjectListValues[i])
        }
    }

    private func verifySwiftObjectWithDictionaryLiteral(object: SwiftObject, dictionary: [String:AnyObject], boolObjectValue: Bool, boolObjectListValues: [Bool]) {
        XCTAssertEqual(object.boolCol, dictionary["boolCol"] as! Bool)
        XCTAssertEqual(object.intCol, dictionary["intCol"] as! Int)
        XCTAssertEqual(object.floatCol, dictionary["floatCol"] as! Float)
        XCTAssertEqual(object.doubleCol, dictionary["doubleCol"] as! Double)
        XCTAssertEqual(object.stringCol, dictionary["stringCol"] as! String)
        XCTAssertEqual(object.binaryCol, dictionary["binaryCol"] as! NSData)
        XCTAssertEqual(object.dateCol, dictionary["dateCol"] as! NSDate)
        XCTAssertEqual(object.objectCol.boolCol, boolObjectValue)
        XCTAssertEqual(object.arrayCol.count, boolObjectListValues.count)
        for i in 0..<boolObjectListValues.count {
            XCTAssertEqual(object.arrayCol[i].boolCol, boolObjectListValues[i])
        }
    }

    private func defaultSwiftObjectValuesWithReplacements(replace: [String: AnyObject]) -> [String: AnyObject] {
        var valueDict = SwiftObject.defaultValues()
        for (key, value) in replace {
            valueDict[key] = value
        }
        return valueDict
    }

    // return an array of valid values that can be used to initialize each type
    private func validValuesForSwiftObjectType(type: PropertyType) -> [AnyObject] {
        Realm().beginWrite()
        let persistedObject = Realm().create(SwiftBoolObject.self, value: [true])
        Realm().commitWrite()
        switch type {
            case .Bool:     return [true, 0 as Int, 1 as Int]
            case .Int:      return [1 as Int]
            case .Float:    return [1 as Int, 1.1 as Float, 11.1 as Double]
            case .Double:   return [1 as Int, 1.1 as Float, 11.1 as Double]
            case .String:   return ["b"]
            case .Data:     return ["b".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)! as NSData]
            case .Date:     return [NSDate(timeIntervalSince1970: 2) as AnyObject]
            case .Object:   return [[true], ["boolCol": true], SwiftBoolObject(value: [true]), persistedObject]
            case .Array:    return [[[true], [false]], [["boolCol": true], ["boolCol": false]], [SwiftBoolObject(value: [true]), SwiftBoolObject(value: [false])], [persistedObject, [false]]]
            case .Any:      XCTFail("not supported")
        }
        return []
    }

    private func invalidValuesForSwiftObjectType(type: PropertyType) -> [AnyObject] {
        Realm().beginWrite()
        let persistedObject = Realm().create(SwiftIntObject)
        Realm().commitWrite()
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

