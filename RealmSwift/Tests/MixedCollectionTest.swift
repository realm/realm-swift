////////////////////////////////////////////////////////////////////////////
//
// Copyright 2024 Realm Inc.
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

class MixedCollectionTest: TestCase, @unchecked Sendable {
    func testAnyMixedDictionary() throws {
        let so = SwiftStringObject()
        so.stringCol = "hello"
        let d = Date()
        let oid = ObjectId.generate()
        let uuid = UUID()

        func assertObject(_ o: AnyRealmTypeObject) {
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key1"], .string("hello"))
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key2"], .bool(false))
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key3"], .int(234))
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key4"], .float(789.123))
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key5"], .double(12345.678901))
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key6"], .data(Data("a".utf8)))
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key7"], .date(d))
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key9"], .objectId(oid))
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key10"], .uuid(uuid))
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key11"], .decimal128(Decimal128(number: 567)))

            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key1"]?.stringValue, "hello")
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key2"]?.boolValue, false)
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key3"]?.intValue, 234)
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key4"]?.floatValue, 789.123)
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key5"]?.doubleValue, 12345.678901)
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key6"]?.dataValue, Data("a".utf8))
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key7"]?.dateValue, d)
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key8"]?.object(SwiftStringObject.self)?.stringCol, so.stringCol)
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key9"]?.objectIdValue, oid)
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key10"]?.uuidValue, uuid)
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key11"]?.decimal128Value, Decimal128(number: 567))
        }

        let dictionary: Dictionary<String, AnyRealmValue> = [
            "key1": .string("hello"),
            "key2": .bool(false),
            "key3": .int(234),
            "key4": .float(789.123),
            "key5": .double(12345.678901),
            "key6": .data(Data("a".utf8)),
            "key7": .date(d),
            "key8": .object(so),
            "key9": .objectId(oid),
            "key10": .uuid(uuid),
            "key11": .decimal128(Decimal128(number: 567))
        ]

        let dictionary1: Dictionary<String, AnyRealmValue> = [
            "key": .none
        ]

        let o = AnyRealmTypeObject()
        // Unmanaged Set
        o.anyValue.value = AnyRealmValue.fromDictionary(dictionary)
        assertObject(o)
        // Unmanaged update
        o.anyValue.value = AnyRealmValue.fromDictionary(dictionary1)
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key"], AnyRealmValue.none)

        // Add mixed collection to object
        let realm = realmWithTestPath()
        try realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key"], AnyRealmValue.none)

        // Update managed object
        try realm.write {
            o.anyValue.value = AnyRealmValue.fromDictionary(dictionary1)
        }
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key"], AnyRealmValue.none)

        // Create managed object
        try realm.write {
            let object = realm.create(AnyRealmTypeObject.self, value: [ "anyValue": dictionary ])
            assertObject(object)
        }

        // Results
        let result = realm.objects(AnyRealmTypeObject.self).last
        XCTAssertNotNil(result)
        assertObject(result!)
    }

    func testAnyMixedDictionaryUpdateAndDelete() throws {
        let so = SwiftStringObject()
        so.stringCol = "hello"

        let dictionary: Dictionary<String, AnyRealmValue> = [
            "key1": .string("hello"),
            "key2": .bool(false),
            "key3": .int(234),
        ]

        let o = AnyRealmTypeObject()
        // Unmanaged Set
        o.anyValue.value = AnyRealmValue.fromDictionary(dictionary)
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key1"], .string("hello"))

        // Unmanaged Update
        o.anyValue.value.dictionaryValue?["key1"] = .object(so)
        o.anyValue.value.dictionaryValue?["key2"] = .data(Data("a".utf8))
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key1"]?.object(SwiftStringObject.self)?.stringCol, so.stringCol)
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key2"], .data(Data("a".utf8)))

        // Add mixed collection to object
        let realm = realmWithTestPath()
        try realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key1"]?.object(SwiftStringObject.self)?.stringCol, so.stringCol)
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key2"], .data(Data("a".utf8)))

        // Update managed object
        try realm.write {
            o.anyValue.value.dictionaryValue?["key1"] = .double(12345.678901)
            o.anyValue.value.dictionaryValue?["key2"] = .float(789.123)
        }
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key1"], .double(12345.678901))
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key2"], .float(789.123))

        let result = realm.objects(AnyRealmTypeObject.self).last
        XCTAssertNotNil(result)
        // Delete
        try realm.write {
            result?.anyValue.value.dictionaryValue?["key1"] = nil
            result?.anyValue.value.dictionaryValue?["key2"] = nil
        }
        XCTAssertNil(result?.anyValue.value.dictionaryValue?["key1"])
        XCTAssertNil(result?.anyValue.value.dictionaryValue?["key2"])
    }

    func testAnyMixedNestedDictionary() throws {
        let so = SwiftStringObject()
        so.stringCol = "hello"

        func assertDictionary1(_ o: AnyRealmTypeObject) {
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key1"]?.dictionaryValue?["key2"]?.dictionaryValue?["key3"]?.object(SwiftStringObject.self)?.stringCol, "hello")
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key4"]?.boolValue, false)
        }

        func assertDictionary2(_ o: AnyRealmTypeObject) {
            XCTAssertEqual(o.anyValue.value.dictionaryValue?["key10"]?.dictionaryValue?["key11"]?.dictionaryValue?["key12"]?.dictionaryValue?["key1"]?.dictionaryValue?["key2"]?.dictionaryValue?["key3"]?.object(SwiftStringObject.self)?.stringCol, "hello")
        }

        let subDict2: AnyRealmValue = AnyRealmValue.fromDictionary([ "key3": .object(so) ])
        let subDict3: AnyRealmValue = AnyRealmValue.fromDictionary([ "key2": subDict2 ])
        let subDict4: AnyRealmValue = AnyRealmValue.fromDictionary([ "key1": subDict3 ])
        let dictionary1: Dictionary<String, AnyRealmValue> = [
            "key0": subDict4,
            "key4": .bool(false)
        ]

        let subDict5: AnyRealmValue = AnyRealmValue.fromDictionary([ "key12": subDict4 ])
        let subDict6: AnyRealmValue = AnyRealmValue.fromDictionary([ "key11": subDict5 ])
        let dictionary2: Dictionary<String, AnyRealmValue> = [
            "key10": subDict6,
        ]

        let o = AnyRealmTypeObject()
        // Unmanaged Set
        o.anyValue.value = AnyRealmValue.fromDictionary(dictionary2)
        // Unamanged Read
        assertDictionary2(o)

        // Unmanaged update
        o.anyValue.value = AnyRealmValue.fromDictionary(dictionary1)
        // Update assert
        assertDictionary1(o)

        // Add mixed collection to object
        let realm = realmWithTestPath()
        try realm.write {
            realm.add(o)
        }
        // Add assert
        assertDictionary1(o)

        // Update managed object
        try realm.write {
            o.anyValue.value = AnyRealmValue.fromDictionary(dictionary2)
        }
        // Update assert
        assertDictionary2(o)

        try realm.write {
            let d = [ "key0": [ "key1": [ "key2": [ "key3": AnyRealmValue.object(so)]]],
                      "key4": AnyRealmValue.bool(false)]
            let object = realm.create(AnyRealmTypeObject.self, value: [ "anyValue": d])
            assertDictionary1(object)
        }

        // Results
        let result = realm.objects(AnyRealmTypeObject.self).last

        // Results assert
        XCTAssertNotNil(result)
        assertDictionary1(result!)
    }

    func testAnyMixedList() throws {
        let so = SwiftStringObject()
        so.stringCol = "hello"
        let d = Date()
        let oid = ObjectId.generate()
        let uuid = UUID()

        func assertObject(_ o: AnyRealmTypeObject) {
            XCTAssertEqual(o.anyValue.value.listValue?[0], .string("hello"))
            XCTAssertEqual(o.anyValue.value.listValue?[1], .bool(false))
            XCTAssertEqual(o.anyValue.value.listValue?[2], .int(234))
            XCTAssertEqual(o.anyValue.value.listValue?[3], .float(789.123))
            XCTAssertEqual(o.anyValue.value.listValue?[4], .double(12345.678901))
            XCTAssertEqual(o.anyValue.value.listValue?[5], .data(Data("a".utf8)))
            XCTAssertEqual(o.anyValue.value.listValue?[6], .date(d))
            XCTAssertEqual(o.anyValue.value.listValue?[8], .objectId(oid))
            XCTAssertEqual(o.anyValue.value.listValue?[9], .uuid(uuid))
            XCTAssertEqual(o.anyValue.value.listValue?[10], .decimal128(Decimal128(number: 567)))

            XCTAssertEqual(o.anyValue.value.listValue?[0].stringValue, "hello")
            XCTAssertEqual(o.anyValue.value.listValue?[1].boolValue, false)
            XCTAssertEqual(o.anyValue.value.listValue?[2].intValue, 234)
            XCTAssertEqual(o.anyValue.value.listValue?[3].floatValue, 789.123)
            XCTAssertEqual(o.anyValue.value.listValue?[4].doubleValue, 12345.678901)
            XCTAssertEqual(o.anyValue.value.listValue?[5].dataValue, Data("a".utf8))
            XCTAssertEqual(o.anyValue.value.listValue?[6].dateValue, d)
            XCTAssertEqual(o.anyValue.value.listValue?[7].object(SwiftStringObject.self)?.stringCol, so.stringCol)
            XCTAssertEqual(o.anyValue.value.listValue?[8].objectIdValue, oid)
            XCTAssertEqual(o.anyValue.value.listValue?[9].uuidValue, uuid)
            XCTAssertEqual(o.anyValue.value.listValue?[10].decimal128Value, Decimal128(number: 567))
        }

        let list: Array<AnyRealmValue> = [
            .string("hello"),
            .bool(false),
            .int(234),
            .float(789.123),
            .double(12345.678901),
            .data(Data("a".utf8)),
            .date(d),
            .object(so),
            .objectId(oid),
            .uuid(uuid),
            .decimal128(Decimal128(number: 567))
        ]

        let list1: Array<AnyRealmValue> = [
            .none
        ]

        let o = AnyRealmTypeObject()
        // Unmanaged Set
        let l = AnyRealmValue.fromArray(list)
        o.anyValue.value = l
        assertObject(o)
        // Unmanaged update
        o.anyValue.value = AnyRealmValue.fromArray(list1)
        XCTAssertEqual(o.anyValue.value.listValue?[0], AnyRealmValue.none)

        // Add mixed collection to object
        let realm = realmWithTestPath()
        try realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.listValue?[0], AnyRealmValue.none)

        // Update managed object
        try realm.write {
            o.anyValue.value = AnyRealmValue.fromArray(list1)
        }
        XCTAssertEqual(o.anyValue.value.listValue?[0], AnyRealmValue.none)

        try realm.write {
            let object = realm.create(AnyRealmTypeObject.self, value: [ "anyValue": list ])
            assertObject(object)
        }

        // Results
        let result = realm.objects(AnyRealmTypeObject.self).last
        XCTAssertNotNil(result)
        assertObject(result!)
    }

    func testAnyMixedListUpdateAndDelete() throws {
        let so = SwiftStringObject()
        so.stringCol = "hello"

        let list: Array<AnyRealmValue> = [
            .string("hello"),
            .bool(false),
            .int(234),
        ]

        let o = AnyRealmTypeObject()
        // Unmanaged Set
        o.anyValue.value = AnyRealmValue.fromArray(list)
        XCTAssertEqual(o.anyValue.value.listValue?[0], .string("hello"))

        // Unmanaged Update
        o.anyValue.value.listValue?[0] = .object(so)
        o.anyValue.value.listValue?[1] = .data(Data("a".utf8))
        XCTAssertEqual(o.anyValue.value.listValue?[0].object(SwiftStringObject.self)?.stringCol, so.stringCol)
        XCTAssertEqual(o.anyValue.value.listValue?[1], .data(Data("a".utf8)))

        // Add mixed collection to object
        let realm = realmWithTestPath()
        try realm.write {
            realm.add(o)
        }
        XCTAssertEqual(o.anyValue.value.listValue?[0].object(SwiftStringObject.self)?.stringCol, so.stringCol)
        XCTAssertEqual(o.anyValue.value.listValue?[1], .data(Data("a".utf8)))

        // Update managed object
        try realm.write {
            o.anyValue.value.listValue?[0] = .double(12345.678901)
            o.anyValue.value.listValue?[1] = .float(789.123)
        }
        XCTAssertEqual(o.anyValue.value.listValue?[0], .double(12345.678901))
        XCTAssertEqual(o.anyValue.value.listValue?[1], .float(789.123))

        let result = realm.objects(AnyRealmTypeObject.self).last
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.anyValue.value.listValue?.count, 3)

        // Delete
        try realm.write {
            result?.anyValue.value.listValue?.remove(at: 0)
            result?.anyValue.value.listValue?.remove(at: 0)
        }
        XCTAssertNotEqual(result?.anyValue.value.listValue?[0], .double(12345.678901))
        XCTAssertEqual(result?.anyValue.value.listValue?[0], .int(234))
        XCTAssertEqual(result?.anyValue.value.listValue?.count, 1)
    }

    func testAnyMixedNestedArray() throws {
        let so = SwiftStringObject()
        so.stringCol = "hello"

        func assertArray1(_ o: AnyRealmTypeObject) {
            XCTAssertEqual(o.anyValue.value.listValue?[0].listValue?[0].listValue?[0].listValue?[0].object(SwiftStringObject.self)?.stringCol, "hello")
            XCTAssertEqual(o.anyValue.value.listValue?[1].boolValue, false)
        }

        func assertArray2(_ o: AnyRealmTypeObject) {
            XCTAssertEqual(o.anyValue.value.listValue?[0].listValue?[0].listValue?[0].listValue?[0].listValue?[0].listValue?[0].object(SwiftStringObject.self)?.stringCol, "hello")
        }

        let subArray2: AnyRealmValue = AnyRealmValue.fromArray([ .object(so) ])
        let subArray3: AnyRealmValue = AnyRealmValue.fromArray([ subArray2 ])
        let subArray4: AnyRealmValue = AnyRealmValue.fromArray([ subArray3 ])
        let array1: Array<AnyRealmValue> = [
            subArray4, .bool(false)
        ]

        let subArray5: AnyRealmValue = AnyRealmValue.fromArray([ subArray4 ])
        let subArray6: AnyRealmValue = AnyRealmValue.fromArray([ subArray5 ])
        let array2: Array<AnyRealmValue> = [
            subArray6
        ]

        let o = AnyRealmTypeObject()
        // Unmanaged Set
        o.anyValue.value = AnyRealmValue.fromArray(array2)
        // Unamanged Read
        assertArray2(o)

        // Unmanaged update
        o.anyValue.value = AnyRealmValue.fromArray(array1)
        // Update assert
        assertArray1(o)

        // Add mixed collection to object
        let realm = realmWithTestPath()
        try realm.write {
            realm.add(o)
        }
        // Add assert
        assertArray1(o)

        // Update managed object
        try realm.write {
            o.anyValue.value = AnyRealmValue.fromArray(array2)
        }
        // Update assert
        assertArray2(o)

        try realm.write {
            let d = [[[[ AnyRealmValue.object(so)]]], AnyRealmValue.bool(false)]
            let object = realm.create(AnyRealmTypeObject.self, value: [ "anyValue": d])
            assertArray1(object)
        }

        // Results
        let result = realm.objects(AnyRealmTypeObject.self).last
        XCTAssertNotNil(result)
        assertArray1(result!)
    }

    func testMixedNestedCollection() throws {
        let so = SwiftStringObject()
        so.stringCol = "hello"

        let subArray2: AnyRealmValue = AnyRealmValue.fromArray([ .object(so) ])
        let subDict2: AnyRealmValue = AnyRealmValue.fromDictionary([ "key1": subArray2 ])
        let subArray3: AnyRealmValue = AnyRealmValue.fromArray([ subArray2, subDict2])
        let subDict3: AnyRealmValue = AnyRealmValue.fromDictionary([ "key2": subArray3 ])
        let subArray4: AnyRealmValue = AnyRealmValue.fromArray([ subDict3 ])
        let subDict4: AnyRealmValue = AnyRealmValue.fromDictionary([ "key3": subArray4 ])
        let subArray5: AnyRealmValue = AnyRealmValue.fromArray([ subDict4 ])
        let subDict5: AnyRealmValue = AnyRealmValue.fromDictionary([ "key4": subArray5 ])
        let subArray6: AnyRealmValue = AnyRealmValue.fromArray([ subDict5 ])
        let subDict6: AnyRealmValue = AnyRealmValue.fromDictionary([ "key5": subArray6 ])
        let dictionary: Dictionary<String, AnyRealmValue> = [
            "key0": subDict6,
        ]

        func assertMixed(_ o: AnyRealmTypeObject) {
            let baseNested: List<AnyRealmValue>? = o.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key5"]?.listValue?[0].dictionaryValue?["key4"]?.listValue?[0].dictionaryValue?["key3"]?.listValue
            let nested1: String? = baseNested?[0].dictionaryValue?["key2"]?.listValue?[0].listValue?[0].object(SwiftStringObject.self)?.stringCol
            XCTAssertEqual(nested1, "hello")
            let nested2: String? = baseNested?[0].dictionaryValue?["key2"]?.listValue?[1].dictionaryValue?["key1"]?.listValue?[0].object(SwiftStringObject.self)?.stringCol
            XCTAssertEqual(nested2, "hello")
        }

        let o = AnyRealmTypeObject()
        // Unmanaged Set
        o.anyValue.value = AnyRealmValue.fromDictionary(dictionary)
        // Unamanged Read
        assertMixed(o)

        // Unmanaged update
        o.anyValue.value = AnyRealmValue.fromDictionary(dictionary)
        // Update assert
        assertMixed(o)

        // Add mixed collection to object
        let realm = realmWithTestPath()
        try realm.write {
            realm.add(o)
        }
        // Add assert
        assertMixed(o)

        // Update managed object
        try realm.write {
            o.anyValue.value = AnyRealmValue.fromDictionary(dictionary)
        }
        // Update assert
        assertMixed(o)

        try realm.write {
            let d = ["key0": ["key5": [["key4": [["key3": [["key2": [[AnyRealmValue.object(so)], ["key1": [AnyRealmValue.object(so)]]]]]]]]]]]
            let object = realm.create(AnyRealmTypeObject.self, value: [ "anyValue": d])
            assertMixed(object)
        }

        // Results
        let result = realm.objects(AnyRealmTypeObject.self).last

        // Results assert
        XCTAssertNotNil(result)
        assertMixed(result!)
    }

    func testMixedCollectionEquality() throws {
        let so = SwiftStringObject()
        so.stringCol = "hello"
        let subArray2: AnyRealmValue = AnyRealmValue.fromArray([ .object(so) ])
        let subDict2: AnyRealmValue = AnyRealmValue.fromDictionary([ "key1": subArray2 ])
        let subArray3: AnyRealmValue = AnyRealmValue.fromArray([ subArray2, subDict2])
        let subDict3: AnyRealmValue = AnyRealmValue.fromDictionary([ "key2": subArray3 ])
        let subArray4: AnyRealmValue = AnyRealmValue.fromArray([ subDict3 ])
        let subDict4: AnyRealmValue = AnyRealmValue.fromDictionary([ "key3": subArray4 ])
        let subArray5: AnyRealmValue = AnyRealmValue.fromArray([ subDict4 ])
        let subDict5: AnyRealmValue = AnyRealmValue.fromDictionary([ "key4": subArray5 ])
        let subArray6: AnyRealmValue = AnyRealmValue.fromArray([ subDict5 ])
        let subDict6: AnyRealmValue = AnyRealmValue.fromDictionary([ "key5": subArray6 ])
        let dictionary: Dictionary<String, AnyRealmValue> = [
            "key0": subDict6,
        ]

        XCTAssertEqual(AnyRealmValue.fromDictionary([:]), AnyRealmValue.fromDictionary([:])) // Empty mixed lists should be equal
        XCTAssertEqual(AnyRealmValue.fromDictionary(dictionary), AnyRealmValue.fromDictionary(dictionary)) // Unamanged mixed list should be equal

        var dictionary2 = dictionary
        dictionary2["newKey"] = .bool(false)
        XCTAssertNotEqual(AnyRealmValue.fromDictionary(dictionary), AnyRealmValue.fromDictionary(dictionary2))

        let anyValue = AnyRealmValue.fromDictionary(dictionary)
        let anyValue2 = AnyRealmValue.fromDictionary(dictionary)
        anyValue2.dictionaryValue?["newKey"] = .bool(false)
        XCTAssertNotEqual(anyValue, anyValue2)

        let mixedObject = AnyRealmTypeObject()
        mixedObject.anyValue.value = anyValue
        let mixedObject2 = mixedObject

        XCTAssertEqual(mixedObject.anyValue, mixedObject2.anyValue)
        XCTAssertEqual(mixedObject.anyValue.value, mixedObject2.anyValue.value)
        XCTAssertEqual(mixedObject.anyValue, mixedObject2.anyValue, "instances should be equal by `==` operator")
        XCTAssertTrue(mixedObject.isEqual(mixedObject2), "instances should be equal by `isEqual` method")

        XCTAssertEqual(mixedObject.anyValue.value.dictionaryValue, mixedObject.anyValue.value.dictionaryValue)

        let realm = realmWithTestPath()
        try realm.write {
            realm.add(mixedObject)
            realm.add(mixedObject2)
        }

        XCTAssertEqual(mixedObject.anyValue.value, mixedObject2.anyValue.value)
        XCTAssertEqual(mixedObject.anyValue.value.dictionaryValue?["key0"], mixedObject2.anyValue.value.dictionaryValue?["key0"])
        XCTAssertEqual(mixedObject.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key5"]?.listValue?[0], mixedObject2.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key5"]?.listValue?[0])

        let mixedObject3 = AnyRealmTypeObject()
        mixedObject3.anyValue.value = AnyRealmValue.fromDictionary(dictionary)

        try realm.write {
            realm.add(mixedObject3)
        }

        XCTAssertNotEqual(mixedObject.anyValue.value, mixedObject3.anyValue.value)
        XCTAssertNotEqual(mixedObject.anyValue.value.dictionaryValue?["key0"], mixedObject3.anyValue.value.dictionaryValue?["key0"])
        XCTAssertNotEqual(mixedObject.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key5"]?.listValue?[0], mixedObject3.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key5"]?.listValue?[0])
    }

    func testMixedCollectionModernObjectEquality() throws {
        let so = SwiftStringObject()
        so.stringCol = "hello"
        let subArray2: AnyRealmValue = AnyRealmValue.fromArray([ .object(so) ])
        let subDict2: AnyRealmValue = AnyRealmValue.fromDictionary([ "key1": subArray2 ])
        let subArray3: AnyRealmValue = AnyRealmValue.fromArray([ subArray2, subDict2])
        let subDict3: AnyRealmValue = AnyRealmValue.fromDictionary([ "key2": subArray3 ])
        let subArray4: AnyRealmValue = AnyRealmValue.fromArray([ subDict3 ])
        let subDict4: AnyRealmValue = AnyRealmValue.fromDictionary([ "key3": subArray4 ])
        let subArray5: AnyRealmValue = AnyRealmValue.fromArray([ subDict4 ])
        let subDict5: AnyRealmValue = AnyRealmValue.fromDictionary([ "key4": subArray5 ])
        let subArray6: AnyRealmValue = AnyRealmValue.fromArray([ subDict5 ])
        let subDict6: AnyRealmValue = AnyRealmValue.fromDictionary([ "key5": subArray6 ])
        let dictionary: Dictionary<String, AnyRealmValue> = [
            "key0": subDict6,
        ]

        XCTAssertEqual(AnyRealmValue.fromDictionary([:]), AnyRealmValue.fromDictionary([:])) // Empty mixed lists should be equal
        XCTAssertEqual(AnyRealmValue.fromDictionary(dictionary), AnyRealmValue.fromDictionary(dictionary)) // Unamanged mixed list should be equal

        var dictionary2 = dictionary
        dictionary2["newKey"] = .bool(false)
        XCTAssertNotEqual(AnyRealmValue.fromDictionary(dictionary), AnyRealmValue.fromDictionary(dictionary2))

        let anyValue = AnyRealmValue.fromDictionary(dictionary)
        let anyValue2 = AnyRealmValue.fromDictionary(dictionary)
        anyValue2.dictionaryValue?["newKey"] = .bool(false)
        XCTAssertNotEqual(anyValue, anyValue2)

        // Unmanaged equality
        let mixedObject = ModernAllTypesObject()
        mixedObject.anyCol = anyValue
        XCTAssertEqual(mixedObject.anyCol, anyValue)
        XCTAssertEqual(mixedObject.anyCol, AnyRealmValue.fromDictionary(dictionary))
        let mixedObject2 = mixedObject
        XCTAssertEqual(mixedObject2.anyCol, anyValue)
        XCTAssertEqual(mixedObject2.anyCol, AnyRealmValue.fromDictionary(dictionary))

        XCTAssertEqual(mixedObject.anyCol, mixedObject2.anyCol)
        XCTAssertTrue(mixedObject.anyCol == mixedObject2.anyCol, "instances should be equal by `==` operator")
        XCTAssertTrue(mixedObject.isEqual(mixedObject2), "instances should be equal by `isEqual` method")
        XCTAssertEqual(mixedObject.anyCol.dictionaryValue, mixedObject.anyCol.dictionaryValue)

        let realm = realmWithTestPath()
        try realm.write {
            realm.add(mixedObject)
            realm.add(mixedObject2)
        }

        XCTAssertEqual(mixedObject.anyCol, mixedObject2.anyCol)
        XCTAssertTrue(mixedObject.anyCol == mixedObject2.anyCol, "instances should be equal by `==` operator")
        XCTAssertTrue(mixedObject.isEqual(mixedObject2), "instances should be equal by `isEqual` method")

        let mixedObject3 = ModernAllTypesObject()
        mixedObject3.anyCol = AnyRealmValue.fromDictionary(dictionary)

        try realm.write {
            realm.add(mixedObject3)
        }

        XCTAssertNotEqual(mixedObject.anyCol, mixedObject3.anyCol)
        XCTAssertNotEqual(mixedObject.anyCol.dictionaryValue?["key0"], mixedObject3.anyCol.dictionaryValue?["key0"])
        XCTAssertNotEqual(mixedObject.anyCol.dictionaryValue?["key0"]?.dictionaryValue?["key5"]?.listValue?[0], mixedObject3.anyCol.dictionaryValue?["key0"]?.dictionaryValue?["key5"]?.listValue?[0])
    }

    @MainActor
    func testMixedCollectionObjectNotifications() throws {
        let subArray3: AnyRealmValue = AnyRealmValue.fromArray([ .int(3) ])
        let subArray2: AnyRealmValue = AnyRealmValue.fromArray([ subArray3 ])
        let subDict1: AnyRealmValue = AnyRealmValue.fromDictionary([ "key1": subArray2 ])
        let dictionary: Dictionary<String, AnyRealmValue> = [
            "key0": subDict1,
        ]

        func expectChange(_ name: String) -> ((ObjectChange<ObjectBase>) -> Void) {
            let exp = expectation(description: "Object changes for mixed collections")
            return { change in
                if case .change(_, let properties) = change {
                    XCTAssertEqual(properties.count, 1)
                    if let prop = properties.first {
                        XCTAssertEqual(prop.name, name)
                    }
                } else {
                    XCTFail("expected .change, got \(change)")
                }
                exp.fulfill()
            }
        }

        func assertObjectNotification(_ object: Object, block: @escaping () -> Void) {
            let token = object.observe(expectChange("anyValue"))
            let realm = realmWithTestPath()
            try! realm.write {
                block()
            }

            waitForExpectations(timeout: 2)
            token.invalidate()
        }

        let o = AnyRealmTypeObject()
        let realm = realmWithTestPath()
        try realm.write {
            realm.add(o)
        }

        assertObjectNotification(o) {
            o.anyValue.value = AnyRealmValue.fromDictionary(dictionary)
        }

        assertObjectNotification(o) {
            o.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key1"]?.listValue?[0].listValue?[0] = .bool(true)
        }

        assertObjectNotification(o) {
            o.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key1"]?.listValue?.append(.float(33.33))
        }

        assertObjectNotification(o) {
            o.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key1"]?.listValue?.removeLast()
        }

        assertObjectNotification(o) {
            o.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key1"]?.listValue?.removeAll()
        }

        assertObjectNotification(o) {
            o.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key2"] = .string("nowhere")
        }

        assertObjectNotification(o) {
            o.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key2"] = nil
        }

        assertObjectNotification(o) {
            o.anyValue.value.dictionaryValue?.removeAll()
        }
    }

    @MainActor
    func testMixedCollectionDictionaryNotifications() throws {
        let subDict2: AnyRealmValue = AnyRealmValue.fromDictionary([ "key5": .float(43) ])
        let subDict1: AnyRealmValue = AnyRealmValue.fromDictionary([ "key1": subDict2 ])
        let dictionary: Dictionary<String, AnyRealmValue> = [
            "key0": subDict1,
            "key3": .decimal128(Decimal128(1)),
        ]

        func expectChanges(_ deletions: [String], _ insertions: [String], _ modifications: [String]) -> ((RealmMapChange<Map<String, AnyRealmValue>>) -> Void) {
            let exp = expectation(description: "Dictionary changes for mixed collections")
            return { change in
                switch change {
                case .initial:
                    break
                case .update(_, deletions: let d, insertions: let i, modifications: let m):
                    XCTAssertEqual(d.count, deletions.count)
                    XCTAssertEqual(d, deletions)
                    XCTAssertEqual(i.count, insertions.count)
                    XCTAssertEqual(i, insertions)
                    XCTAssertEqual(m.count, modifications.count)
                    XCTAssertEqual(m, modifications)
                    exp.fulfill()
                case .error(let error):
                    XCTFail("Unexpected error \(error)")
                }
            }
        }

        func assertDictionaryNotification(_ dictionary: Map<String, AnyRealmValue>?, deletions: [String], insertions: [String], modifications: [String], block: @escaping () -> Void) {
            let token = dictionary?.observe(expectChanges(deletions, insertions, modifications))
            let realm = realmWithTestPath()
            try! realm.write {
                block()
            }

            waitForExpectations(timeout: 2)
            token?.invalidate()
        }

        let o = AnyRealmTypeObject()
        o.anyValue.value = AnyRealmValue.fromDictionary(dictionary)
        let realm = realmWithTestPath()
        try realm.write {
            realm.add(o)
        }

        assertDictionaryNotification(o.anyValue.value.dictionaryValue, deletions: [], insertions: ["key2"], modifications: []) {
            o.anyValue.value.dictionaryValue?["key2"] = AnyRealmValue.fromDictionary(dictionary)
        }

        assertDictionaryNotification(o.anyValue.value.dictionaryValue, deletions: [], insertions: ["key10"], modifications: []) {
            o.anyValue.value.dictionaryValue?["key10"] = AnyRealmValue.fromDictionary(dictionary)
        }

        assertDictionaryNotification(o.anyValue.value.dictionaryValue?["key10"]?.dictionaryValue, deletions: [], insertions: [], modifications: ["key0"]) {
            o.anyValue.value.dictionaryValue?["key10"]?.dictionaryValue?["key0"] = .string("new")
        }

        assertDictionaryNotification(o.anyValue.value.dictionaryValue, deletions: ["key3"], insertions: [], modifications: []) {
            o.anyValue.value.dictionaryValue?["key3"] = nil
        }

        assertDictionaryNotification(o.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key1"]?.dictionaryValue, deletions: [], insertions: ["key6"], modifications: []) {
            o.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key1"]?.dictionaryValue?["key6"] = .date(Date())
        }

        assertDictionaryNotification(o.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key1"]?.dictionaryValue, deletions: ["key5", "key6"], insertions: [], modifications: []) {
            o.anyValue.value.dictionaryValue?["key0"]?.dictionaryValue?["key1"]?.dictionaryValue?.removeAll()
        }
    }

    @MainActor
    func testMixedCollectionArrayNotifications() throws {
        let subArray2: AnyRealmValue = AnyRealmValue.fromArray([ .float(43), .string("lunch"), .double(12.34) ])
        let subArray1: AnyRealmValue = AnyRealmValue.fromArray([ subArray2, .bool(false) ])
        let array: Array<AnyRealmValue> = [
            subArray1, .decimal128(Decimal128(1)),
        ]

        func expectChanges(_ deletions: [Int], _ insertions: [Int], _ modifications: [Int]) -> ((RealmCollectionChange<List<AnyRealmValue>>) -> Void) {
            let exp = expectation(description: "Dictionary changes for mixed collections")
            return { change in
                switch change {
                case .initial:
                    break
                case .update(_, deletions: let d, insertions: let i, modifications: let m):
                    XCTAssertEqual(d.count, deletions.count)
                    XCTAssertEqual(d, deletions)
                    XCTAssertEqual(i.count, insertions.count)
                    XCTAssertEqual(i, insertions)
                    XCTAssertEqual(m.count, modifications.count)
                    XCTAssertEqual(m, modifications)
                    exp.fulfill()
                case .error(let error):
                    XCTFail("Unexpected error \(error)")
                }
            }
        }

        func assertDictionaryNotification(_ list: List<AnyRealmValue>?, deletions: [Int], insertions: [Int], modifications: [Int], block: @escaping () -> Void) {
            let token = list?.observe(expectChanges(deletions, insertions, modifications))
            let realm = realmWithTestPath()
            try! realm.write {
                block()
            }

            waitForExpectations(timeout: 2)
            token?.invalidate()
        }

        let o = AnyRealmTypeObject()
        o.anyValue.value = AnyRealmValue.fromArray(array)
        let realm = realmWithTestPath()
        try realm.write {
            realm.add(o)
        }

        assertDictionaryNotification(o.anyValue.value.listValue, deletions: [], insertions: [2], modifications: []) {
            o.anyValue.value.listValue?.append(AnyRealmValue.fromArray(array))
        }

        assertDictionaryNotification(o.anyValue.value.listValue?[0].listValue, deletions: [], insertions: [], modifications: [1]) {
            o.anyValue.value.listValue?[0].listValue?[1] = .objectId(ObjectId.generate())
        }

        assertDictionaryNotification(o.anyValue.value.listValue?[0].listValue?[0].listValue, deletions: [2], insertions: [], modifications: []) {
            o.anyValue.value.listValue?[0].listValue?[0].listValue?.removeLast()
        }

        assertDictionaryNotification(o.anyValue.value.listValue?[0].listValue?[0].listValue, deletions: [0, 1], insertions: [], modifications: []) {
            o.anyValue.value.listValue?[0].listValue?[0].listValue?.removeAll()
        }
    }

    func testReassignToMixedList() throws {
        let list = AnyRealmValue.fromArray([.bool(true), AnyRealmValue.fromDictionary(["key": .int(12)]), .float(13.12)])

        let mixedObject = AnyRealmTypeObject()
        mixedObject.anyValue.value = list

        let realm = realmWithTestPath()
        try realm.write {
            realm.add(mixedObject)
        }
        XCTAssertEqual(mixedObject.anyValue.value.listValue?[1].dictionaryValue?["key"], .int(12))

        try realm.write {
            mixedObject.anyValue.value.listValue?.append(AnyRealmValue.fromArray([.double(20.20), .string("hello")]))
        }
        XCTAssertEqual(mixedObject.anyValue.value.listValue?[3].listValue?[0], .double(20.20))

        try realm.write {
            let listItem = mixedObject.anyValue.value.listValue?[0]
            mixedObject.anyValue.value.listValue?.append(listItem!)
        }
        XCTAssertEqual(mixedObject.anyValue.value.listValue?[4], .bool(true))

        try realm.write {
            let listItem = mixedObject.anyValue.value.listValue?[3]
            mixedObject.anyValue.value.listValue?.append(listItem!)
        }
        // TODO: Self-assignment - this doesn't work due to https://github.com/realm/realm-core/issues/7422
//        XCTAssertEqual(mixedObject.anyValue.value.listValue?[4].listValue?[0], .double(20.20))

        try realm.write {
            let listItem = mixedObject.anyValue.value.listValue?[3]
            mixedObject.anyValue.value.listValue?[3] = listItem!
        }
        // TODO: Self-assignment - this doesn't work due to https://github.com/realm/realm-core/issues/7422
//        XCTAssertEqual(mixedObject.anyValue.value.listValue?[3].listValue?[0],  .double(20.20))

        try realm.write {
            mixedObject.anyValue.value.listValue?[1] = AnyRealmValue.fromDictionary(["new-key": .int(3)])
        }
        XCTAssertEqual(mixedObject.anyValue.value.listValue?[1].dictionaryValue?["new-key"], .int(3))

        try realm.write {
            let listItem = mixedObject.anyValue.value.listValue?[1]
            mixedObject.anyValue.value.listValue?.append(listItem!)
        }
        // TODO: Self-assignment - this doesn't work due to https://github.com/realm/realm-core/issues/7422
//        XCTAssertEqual(mixedObject.anyValue.value.listValue?[3].dictionaryValue?["new-key"], .int(3))

        try realm.write {
            let listItem = mixedObject.anyValue.value.listValue?[1]
            mixedObject.anyValue.value.listValue?[3] = listItem!
        }
        // TODO: Self-assignment - this doesn't work due to https://github.com/realm/realm-core/issues/7422
//        XCTAssertEqual(mixedObject.anyValue.value.listValue?[3].dictionaryValue?["new-key"], .int(3))
    }

    func testReassignToMixedDictionary() throws {
        let dictionary = AnyRealmValue.fromDictionary(["key1": .bool(true), "key2": AnyRealmValue.fromDictionary(["key4": .int(12)]), "key3": .float(13.12)])

        let mixedObject = AnyRealmTypeObject()
        mixedObject.anyValue.value = dictionary

        let realm = realmWithTestPath()
        try realm.write {
            realm.add(mixedObject)
        }
        XCTAssertEqual(mixedObject.anyValue.value.dictionaryValue?["key2"]?.dictionaryValue?["key4"], .int(12))

        try realm.write {
            mixedObject.anyValue.value.dictionaryValue?["key4"] = AnyRealmValue.fromDictionary(["new-key": .int(3)])
        }
        XCTAssertEqual(mixedObject.anyValue.value.dictionaryValue?["key4"]?.dictionaryValue?["new-key"], .int(3))

        try realm.write {
            let dictItem = mixedObject.anyValue.value.dictionaryValue?["key1"]
            mixedObject.anyValue.value.dictionaryValue?["key5"] = dictItem
        }
        XCTAssertEqual(mixedObject.anyValue.value.dictionaryValue?["key5"], .bool(true))

        try realm.write {
            let dictItem = mixedObject.anyValue.value.dictionaryValue?["key2"]
            mixedObject.anyValue.value.dictionaryValue?["key6"] = dictItem
        }
        // TODO: Self-assignment - this doesn't work due to https://github.com/realm/realm-core/issues/7422
//        XCTAssertEqual(mixedObject.anyValue.value.dictionaryValue?["key6"]?.dictionaryValue?["key4"], .int(12))

        try realm.write {
            mixedObject.anyValue.value.dictionaryValue?["key7"] = AnyRealmValue.fromArray([.string("hello"), .double(20.20)])
        }
        XCTAssertEqual(mixedObject.anyValue.value.dictionaryValue?["key7"]?.listValue?[0], .string("hello"))

        try realm.write {
            let dictItem = mixedObject.anyValue.value.dictionaryValue?["key7"]
            mixedObject.anyValue.value.dictionaryValue?["key2"] = dictItem
        }
        // TODO: Self-assignment - this doesn't work due to https://github.com/realm/realm-core/issues/7422
//        XCTAssertEqual(mixedObject.anyValue.value.dictionaryValue?["key2"]?.listValue?[0], .string("hello"))
    }

    func testEnumerationNestedCollection() throws {
        var count = 0
        var accessNestedValue = false
        func iterateNestedCollectionKeyValue(_ value: AnyRealmValue) {
            count+=1
            switch value {
            case .list(let l):
                for item in l {
                    iterateNestedCollectionKeyValue(item)
                }
            case .dictionary(let d):
                for (_, val) in d.asKeyValueSequence() {
                    iterateNestedCollectionKeyValue(val)
                }
            default:
                accessNestedValue = true
            }
        }

        let so = SwiftStringObject()
        so.stringCol = "hello"

        let subArray2: AnyRealmValue = AnyRealmValue.fromArray([ .object(so) ])
        let subDict2: AnyRealmValue = AnyRealmValue.fromDictionary([ "key1": subArray2 ])
        let subArray3: AnyRealmValue = AnyRealmValue.fromArray([ subDict2 ])
        let subDict3: AnyRealmValue = AnyRealmValue.fromDictionary([ "key2": subArray3 ])
        let subArray4: AnyRealmValue = AnyRealmValue.fromArray([ subDict3 ])
        let subDict4: AnyRealmValue = AnyRealmValue.fromDictionary([ "key3": subArray4 ])
        let subArray5: AnyRealmValue = AnyRealmValue.fromArray([ subDict4 ])
        let subDict5: AnyRealmValue = AnyRealmValue.fromDictionary([ "key4": subArray5 ])
        let subArray6: AnyRealmValue = AnyRealmValue.fromArray([ subDict5 ])
        let subDict6: AnyRealmValue = AnyRealmValue.fromDictionary([ "key5": subArray6 ])
        let dictionary: Dictionary<String, AnyRealmValue> = [
            "key0": subDict6,
        ]

        let o = AnyRealmTypeObject()
        o.anyValue.value = AnyRealmValue.fromDictionary(dictionary)

        let realm = realmWithTestPath()
        try realm.write {
            realm.add(o)
        }

        iterateNestedCollectionKeyValue(o.anyValue.value)
        XCTAssertEqual(count, 12)
        XCTAssertTrue(accessNestedValue)

        var countValue = 0
        var accessNestedValueValue = false
        func iterateNestedCollectionValue(_ value: AnyRealmValue) {
            countValue+=1
            switch value {
            case .list(let l):
                for item in l {
                    iterateNestedCollectionValue(item)
                }
            case .dictionary(let d):
                for (val) in d {
                    iterateNestedCollectionValue(val.value)
                }
            default:
                accessNestedValueValue = true
            }
        }

        iterateNestedCollectionValue(o.anyValue.value)
        XCTAssertEqual(countValue, 12)
        XCTAssertTrue(accessNestedValueValue)
    }

    func testCollectionReassign() throws {
        let dictionary: Dictionary<String, AnyRealmValue> = [
            "key1": .string("hello"),
            "key2": .bool(false),
        ]

        let dictionary1: Dictionary<String, AnyRealmValue> = [
            "key1": .string("adios"),
        ]

        let o = AnyRealmTypeObject()
        o.anyValue.value = AnyRealmValue.fromDictionary(dictionary)

        let realm = realmWithTestPath()
        try realm.write {
            realm.add(o)

        }
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key1"], .string("hello"))
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key2"], .bool(false))

        try realm.write {
            o.anyValue.value = AnyRealmValue.fromDictionary(dictionary1)
        }
        XCTAssertEqual(o.anyValue.value.dictionaryValue?["key1"], .string("adios"))
        XCTAssertNil(o.anyValue.value.dictionaryValue?["key2"])
    }
}
