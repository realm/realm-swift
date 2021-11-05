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

var pkCounter = 0
func nextPrimaryKey() -> Int {
    pkCounter += 1
    return pkCounter
}

@available(*, deprecated) // Silence deprecation warnings for RealmOptional
class SwiftKVOObject: Object {
    @objc dynamic var pk = nextPrimaryKey() // primary key for equality
    @objc dynamic var ignored: Int = 0

    @objc dynamic var boolCol: Bool = false
    @objc dynamic var int8Col: Int8 = 1
    @objc dynamic var int16Col: Int16 = 2
    @objc dynamic var int32Col: Int32 = 3
    @objc dynamic var int64Col: Int64 = 4
    @objc dynamic var floatCol: Float = 5
    @objc dynamic var doubleCol: Double = 6
    @objc dynamic var stringCol: String = ""
    @objc dynamic var binaryCol: Data = Data()
    @objc dynamic var dateCol: Date = Date(timeIntervalSince1970: 0)
    @objc dynamic var decimalCol: Decimal128 = Decimal128(number: 1)
    @objc dynamic var objectIdCol = ObjectId()
    @objc dynamic var objectCol: SwiftKVOObject?
    let arrayCol = List<SwiftKVOObject>()
    let setCol = MutableSet<SwiftKVOObject>()
    let optIntCol = RealmOptional<Int>()
    let optFloatCol = RealmOptional<Float>()
    let optDoubleCol = RealmOptional<Double>()
    let optBoolCol = RealmOptional<Bool>()
    let otherIntCol = RealmProperty<Int?>()
    let otherFloatCol = RealmProperty<Float?>()
    let otherDoubleCol = RealmProperty<Double?>()
    let otherBoolCol = RealmProperty<Bool?>()
    @objc dynamic var optStringCol: String?
    @objc dynamic var optBinaryCol: Data?
    @objc dynamic var optDateCol: Date?
    @objc dynamic var optDecimalCol: Decimal128?
    @objc dynamic var optObjectIdCol: ObjectId?

    let arrayBool = List<Bool>()
    let arrayInt8 = List<Int8>()
    let arrayInt16 = List<Int16>()
    let arrayInt32 = List<Int32>()
    let arrayInt64 = List<Int64>()
    let arrayFloat = List<Float>()
    let arrayDouble = List<Double>()
    let arrayString = List<String>()
    let arrayBinary = List<Data>()
    let arrayDate = List<Date>()
    let arrayDecimal = List<Decimal128>()
    let arrayObjectId = List<ObjectId>()

    let arrayOptBool = List<Bool?>()
    let arrayOptInt8 = List<Int8?>()
    let arrayOptInt16 = List<Int16?>()
    let arrayOptInt32 = List<Int32?>()
    let arrayOptInt64 = List<Int64?>()
    let arrayOptFloat = List<Float?>()
    let arrayOptDouble = List<Double?>()
    let arrayOptString = List<String?>()
    let arrayOptBinary = List<Data?>()
    let arrayOptDate = List<Date?>()
    let arrayOptDecimal = List<Decimal128?>()
    let arrayOptObjectId = List<ObjectId?>()

    let setBool = MutableSet<Bool>()
    let setInt8 = MutableSet<Int8>()
    let setInt16 = MutableSet<Int16>()
    let setInt32 = MutableSet<Int32>()
    let setInt64 = MutableSet<Int64>()
    let setFloat = MutableSet<Float>()
    let setDouble = MutableSet<Double>()
    let setString = MutableSet<String>()
    let setBinary = MutableSet<Data>()
    let setDate = MutableSet<Date>()
    let setDecimal = MutableSet<Decimal128>()
    let setObjectId = MutableSet<ObjectId>()

    let setOptBool = MutableSet<Bool?>()
    let setOptInt8 = MutableSet<Int8?>()
    let setOptInt16 = MutableSet<Int16?>()
    let setOptInt32 = MutableSet<Int32?>()
    let setOptInt64 = MutableSet<Int64?>()
    let setOptFloat = MutableSet<Float?>()
    let setOptDouble = MutableSet<Double?>()
    let setOptString = MutableSet<String?>()
    let setOptBinary = MutableSet<Data?>()
    let setOptDate = MutableSet<Date?>()
    let setOptDecimal = MutableSet<Decimal128?>()
    let setOptObjectId = MutableSet<ObjectId?>()

    let mapBool = Map<String, Bool>()
    let mapInt8 = Map<String, Int8>()
    let mapInt16 = Map<String, Int16>()
    let mapInt32 = Map<String, Int32>()
    let mapInt64 = Map<String, Int64>()
    let mapFloat = Map<String, Float>()
    let mapDouble = Map<String, Double>()
    let mapString = Map<String, String>()
    let mapBinary = Map<String, Data>()
    let mapDate = Map<String, Date>()
    let mapDecimal = Map<String, Decimal128>()
    let mapObjectId = Map<String, ObjectId>()

    let mapOptBool = Map<String, Bool?>()
    let mapOptInt8 = Map<String, Int8?>()
    let mapOptInt16 = Map<String, Int16?>()
    let mapOptInt32 = Map<String, Int32?>()
    let mapOptInt64 = Map<String, Int64?>()
    let mapOptFloat = Map<String, Float?>()
    let mapOptDouble = Map<String, Double?>()
    let mapOptString = Map<String, String?>()
    let mapOptBinary = Map<String, Data?>()
    let mapOptDate = Map<String, Date?>()
    let mapOptDecimal = Map<String, Decimal128?>()
    let mapOptObjectId = Map<String, ObjectId?>()

    override class func primaryKey() -> String { return "pk" }
    override class func ignoredProperties() -> [String] { return ["ignored"] }
}

// Most of the testing of KVO functionality is done in the obj-c tests
// These tests just verify that it also works on Swift types
@available(*, deprecated) // Silence deprecation warnings for RealmOptional
class KVOTests: TestCase {
    var realm: Realm! = nil

    override func setUp() {
        super.setUp()
        realm = try! Realm()
        realm.beginWrite()
    }

    override func tearDown() {
        realm.cancelWrite()
        realm = nil
        super.tearDown()
    }

    var changeDictionary: [NSKeyValueChangeKey: Any]?

    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        changeDictionary = change
    }

    // swiftlint:disable:next cyclomatic_complexity
    func observeChange<T: Equatable>(_ obj: SwiftKVOObject, _ key: String, _ old: T?, _ new: T?,
                                     fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        let kvoOptions: NSKeyValueObservingOptions = [.old, .new]
        obj.addObserver(self, forKeyPath: key, options: kvoOptions, context: nil)
        block()
        obj.removeObserver(self, forKeyPath: key)

        XCTAssert(changeDictionary != nil, "Did not get a notification", file: (fileName), line: lineNumber)
        guard changeDictionary != nil else { return }

        let actualOld = changeDictionary![.oldKey] as? T
        let actualNew = changeDictionary![.newKey] as? T

        XCTAssert(old == actualOld,
                  "Old value: expected \(String(describing: old)), got \(String(describing: actualOld))",
                  file: (fileName), line: lineNumber)
        XCTAssert(new == actualNew,
                  "New value: expected \(String(describing: new)), got \(String(describing: actualNew))",
                  file: (fileName), line: lineNumber)

        changeDictionary = nil
    }

    func observeChange<T: Equatable>(_ obj: SwiftKVOObject, _ keyPath: KeyPath<SwiftKVOObject, T>, _ old: T, _ new: T,
                                     fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        let kvoOptions: NSKeyValueObservingOptions = [.old, .new]
        var gotNotification = false
        let observation = obj.observe(keyPath, options: kvoOptions) { _, change in
            XCTAssertEqual(change.oldValue, old, file: (fileName), line: lineNumber)
            XCTAssertEqual(change.newValue, new, file: (fileName), line: lineNumber)
            gotNotification = true
        }

        block()
        observation.invalidate()

        XCTAssertTrue(gotNotification, file: (fileName), line: lineNumber)
    }

    func observeChange<T: Equatable>(_ obj: SwiftKVOObject, _ keyPath: KeyPath<SwiftKVOObject, T?>, _ old: T?, _ new: T?,
                                     fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        let kvoOptions: NSKeyValueObservingOptions = [.old, .new]
        var gotNotification = false
        let observation = obj.observe(keyPath, options: kvoOptions) { _, change in
            if let oldValue = change.oldValue {
                XCTAssertEqual(oldValue, old, file: (fileName), line: lineNumber)
            } else {
                XCTAssertNil(old, file: (fileName), line: lineNumber)
            }
            if let newValue = change.newValue {
                XCTAssertEqual(newValue, new, file: (fileName), line: lineNumber)
            } else {
                XCTAssertNil(new, file: (fileName), line: lineNumber)
            }
            gotNotification = true
        }

        block()
        observation.invalidate()

        XCTAssertTrue(gotNotification, file: (fileName), line: lineNumber)
    }

    func observeListChange(_ obj: NSObject, _ key: String, _ kind: NSKeyValueChange, _ indexes: NSIndexSet = NSIndexSet(index: 0),
                           fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        obj.addObserver(self, forKeyPath: key, options: [.old, .new], context: nil)
        block()
        obj.removeObserver(self, forKeyPath: key)
        XCTAssert(changeDictionary != nil, "Did not get a notification", file: (fileName), line: lineNumber)
        guard changeDictionary != nil else { return }

        let actualKind = NSKeyValueChange(rawValue: (changeDictionary![NSKeyValueChangeKey.kindKey] as! NSNumber).uintValue)!
        let actualIndexes = changeDictionary![NSKeyValueChangeKey.indexesKey]! as! NSIndexSet
        XCTAssert(actualKind == kind, "Change kind: expected \(kind), got \(actualKind)", file: (fileName),
            line: lineNumber)
        XCTAssert(actualIndexes.isEqual(indexes), "Changed indexes: expected \(indexes), got \(actualIndexes)",
                  file: (fileName), line: lineNumber)

        changeDictionary = nil
    }

    func observeSetChange(_ obj: SwiftKVOObject, _ key: String,
                          fileName: StaticString = #file, lineNumber: UInt = #line, _ block: () -> Void) {
        obj.addObserver(self, forKeyPath: key, options: [], context: nil)
        block()
        obj.removeObserver(self, forKeyPath: key)

        XCTAssert(changeDictionary != nil, "Did not get a notification", file: (fileName), line: lineNumber)
        guard changeDictionary != nil else { return }
    }

    func getObject(_ obj: SwiftKVOObject) -> (SwiftKVOObject, SwiftKVOObject) {
        return (obj, obj)
    }

    // Actual tests follow

    func testAllPropertyTypes() {
        let (obj, obs) = getObject(SwiftKVOObject())

        observeChange(obs, "boolCol", false, true) { obj.boolCol = true }
        observeChange(obs, "int8Col", 1 as Int8, 10) { obj.int8Col = 10 }
        observeChange(obs, "int16Col", 2 as Int16, 10) { obj.int16Col = 10 }
        observeChange(obs, "int32Col", 3 as Int32, 10) { obj.int32Col = 10 }
        observeChange(obs, "int64Col", 4 as Int64, 10) { obj.int64Col = 10 }
        observeChange(obs, "floatCol", 5 as Float, 10) { obj.floatCol = 10 }
        observeChange(obs, "doubleCol", 6 as Double, 10) { obj.doubleCol = 10 }
        observeChange(obs, "stringCol", "", "abc") { obj.stringCol = "abc" }
        observeChange(obs, "objectCol", nil, obj) { obj.objectCol = obj }

        let data = "abc".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        observeChange(obs, "binaryCol", Data(), data) { obj.binaryCol = data }

        let date = Date(timeIntervalSince1970: 1)
        observeChange(obs, "dateCol", Date(timeIntervalSince1970: 0), date) { obj.dateCol = date }

        let decimal = Decimal128(number: 2)
        observeChange(obs, "decimalCol", Decimal128(number: 1), decimal) { obj.decimalCol = decimal }

        let oldObjectId = obj.objectIdCol
        let objectId = ObjectId()
        observeChange(obs, "objectIdCol", oldObjectId, objectId) { obj.objectIdCol = objectId }

        observeListChange(obs, "arrayCol", .insertion) { obj.arrayCol.append(obj) }
        observeListChange(obs, "arrayCol", .removal) { obj.arrayCol.removeAll() }
        observeSetChange(obs, "setCol") { obj.setCol.insert(obj) }
        observeSetChange(obs, "setCol") { obj.setCol.remove(obj) }

        observeChange(obs, "optIntCol", nil, 10) { obj.optIntCol.value = 10 }
        observeChange(obs, "optFloatCol", nil, 10.0) { obj.optFloatCol.value = 10 }
        observeChange(obs, "optDoubleCol", nil, 10.0) { obj.optDoubleCol.value = 10 }
        observeChange(obs, "optBoolCol", nil, true) { obj.optBoolCol.value = true }
        observeChange(obs, "optStringCol", nil, "abc") { obj.optStringCol = "abc" }
        observeChange(obs, "optBinaryCol", nil, data) { obj.optBinaryCol = data }
        observeChange(obs, "optDateCol", nil, date) { obj.optDateCol = date }
        observeChange(obs, "optDecimalCol", nil, decimal) { obj.optDecimalCol = decimal }
        observeChange(obs, "optObjectIdCol", nil, objectId) { obj.optObjectIdCol = objectId }

        observeChange(obs, "otherIntCol", nil, 10) { obj.otherIntCol.value = 10 }
        observeChange(obs, "otherFloatCol", nil, 10.0) { obj.otherFloatCol.value = 10 }
        observeChange(obs, "otherDoubleCol", nil, 10.0) { obj.otherDoubleCol.value = 10 }
        observeChange(obs, "otherBoolCol", nil, true) { obj.otherBoolCol.value = true }

        observeChange(obs, "optIntCol", 10, nil) { obj.optIntCol.value = nil }
        observeChange(obs, "optFloatCol", 10.0, nil) { obj.optFloatCol.value = nil }
        observeChange(obs, "optDoubleCol", 10.0, nil) { obj.optDoubleCol.value = nil }
        observeChange(obs, "optBoolCol", true, nil) { obj.optBoolCol.value = nil }
        observeChange(obs, "optStringCol", "abc", nil) { obj.optStringCol = nil }
        observeChange(obs, "optBinaryCol", data, nil) { obj.optBinaryCol = nil }
        observeChange(obs, "optDateCol", date, nil) { obj.optDateCol = nil }
        observeChange(obs, "optDecimalCol", decimal, nil) { obj.optDecimalCol = nil }
        observeChange(obs, "optObjectIdCol", objectId, nil) { obj.optObjectIdCol = nil }

        observeChange(obs, "otherIntCol", 10, nil) { obj.otherIntCol.value = nil }
        observeChange(obs, "otherFloatCol", 10.0, nil) { obj.otherFloatCol.value = nil }
        observeChange(obs, "otherDoubleCol", 10.0, nil) { obj.otherDoubleCol.value = nil }
        observeChange(obs, "otherBoolCol", true, nil) { obj.otherBoolCol.value = nil }

        observeListChange(obs, "arrayBool", .insertion) { obj.arrayBool.append(true) }
        observeListChange(obs, "arrayInt8", .insertion) { obj.arrayInt8.append(10) }
        observeListChange(obs, "arrayInt16", .insertion) { obj.arrayInt16.append(10) }
        observeListChange(obs, "arrayInt32", .insertion) { obj.arrayInt32.append(10) }
        observeListChange(obs, "arrayInt64", .insertion) { obj.arrayInt64.append(10) }
        observeListChange(obs, "arrayFloat", .insertion) { obj.arrayFloat.append(10) }
        observeListChange(obs, "arrayDouble", .insertion) { obj.arrayDouble.append(10) }
        observeListChange(obs, "arrayString", .insertion) { obj.arrayString.append("abc") }
        observeListChange(obs, "arrayDecimal", .insertion) { obj.arrayDecimal.append(decimal) }
        observeListChange(obs, "arrayObjectId", .insertion) { obj.arrayObjectId.append(objectId) }

        observeListChange(obs, "arrayOptBool", .insertion) { obj.arrayOptBool.append(true) }
        observeListChange(obs, "arrayOptInt8", .insertion) { obj.arrayOptInt8.append(10) }
        observeListChange(obs, "arrayOptInt16", .insertion) { obj.arrayOptInt16.append(10) }
        observeListChange(obs, "arrayOptInt32", .insertion) { obj.arrayOptInt32.append(10) }
        observeListChange(obs, "arrayOptInt64", .insertion) { obj.arrayOptInt64.append(10) }
        observeListChange(obs, "arrayOptFloat", .insertion) { obj.arrayOptFloat.append(10) }
        observeListChange(obs, "arrayOptDouble", .insertion) { obj.arrayOptDouble.append(10) }
        observeListChange(obs, "arrayOptString", .insertion) { obj.arrayOptString.append("abc") }
        observeListChange(obs, "arrayOptBinary", .insertion) { obj.arrayOptBinary.append(data) }
        observeListChange(obs, "arrayOptDate", .insertion) { obj.arrayOptDate.append(date) }
        observeListChange(obs, "arrayOptDecimal", .insertion) { obj.arrayOptDecimal.append(decimal) }
        observeListChange(obs, "arrayOptObjectId", .insertion) { obj.arrayOptObjectId.append(objectId) }

        observeListChange(obs, "arrayOptBool", .insertion) { obj.arrayOptBool.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt8", .insertion) { obj.arrayOptInt8.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt16", .insertion) { obj.arrayOptInt16.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt32", .insertion) { obj.arrayOptInt32.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptInt64", .insertion) { obj.arrayOptInt64.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptFloat", .insertion) { obj.arrayOptFloat.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptDouble", .insertion) { obj.arrayOptDouble.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptString", .insertion) { obj.arrayOptString.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptDate", .insertion) { obj.arrayOptDate.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptBinary", .insertion) { obj.arrayOptBinary.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptDecimal", .insertion) { obj.arrayOptDecimal.insert(nil, at: 0) }
        observeListChange(obs, "arrayOptObjectId", .insertion) { obj.arrayOptObjectId.insert(nil, at: 0) }

        observeSetChange(obs, "setBool") { obj.setBool.insert(true) }
        observeSetChange(obs, "setInt8") { obj.setInt8.insert(10) }
        observeSetChange(obs, "setInt16") { obj.setInt16.insert(10) }
        observeSetChange(obs, "setInt32") { obj.setInt32.insert(10) }
        observeSetChange(obs, "setInt64") { obj.setInt64.insert(10) }
        observeSetChange(obs, "setFloat") { obj.setFloat.insert(10) }
        observeSetChange(obs, "setDouble") { obj.setDouble.insert(10) }
        observeSetChange(obs, "setString") { obj.setString.insert("abc") }
        observeSetChange(obs, "setDecimal") { obj.setDecimal.insert(decimal) }
        observeSetChange(obs, "setObjectId") { obj.setObjectId.insert(objectId) }

        observeSetChange(obs, "setOptBool") { obj.setOptBool.insert(true) }
        observeSetChange(obs, "setOptInt8") { obj.setOptInt8.insert(10) }
        observeSetChange(obs, "setOptInt16") { obj.setOptInt16.insert(10) }
        observeSetChange(obs, "setOptInt32") { obj.setOptInt32.insert(10) }
        observeSetChange(obs, "setOptInt64") { obj.setOptInt64.insert(10) }
        observeSetChange(obs, "setOptFloat") { obj.setOptFloat.insert(10) }
        observeSetChange(obs, "setOptDouble") { obj.setOptDouble.insert(10) }
        observeSetChange(obs, "setOptString") { obj.setOptString.insert("abc") }
        observeSetChange(obs, "setOptBinary") { obj.setOptBinary.insert(data) }
        observeSetChange(obs, "setOptDate") { obj.setOptDate.insert(date) }
        observeSetChange(obs, "setOptDecimal") { obj.setOptDecimal.insert(decimal) }
        observeSetChange(obs, "setOptObjectId") { obj.setOptObjectId.insert(objectId) }

        observeSetChange(obs, "setOptBool") { obj.setOptBool.insert(nil) }
        observeSetChange(obs, "setOptInt8") { obj.setOptInt8.insert(nil) }
        observeSetChange(obs, "setOptInt16") { obj.setOptInt16.insert(nil) }
        observeSetChange(obs, "setOptInt32") { obj.setOptInt32.insert(nil) }
        observeSetChange(obs, "setOptInt64") { obj.setOptInt64.insert(nil) }
        observeSetChange(obs, "setOptFloat") { obj.setOptFloat.insert(nil) }
        observeSetChange(obs, "setOptDouble") { obj.setOptDouble.insert(nil) }
        observeSetChange(obs, "setOptString") { obj.setOptString.insert(nil) }
        observeSetChange(obs, "setOptDate") { obj.setOptDate.insert(nil) }
        observeSetChange(obs, "setOptBinary") { obj.setOptBinary.insert(nil) }
        observeSetChange(obs, "setOptDecimal") { obj.setOptDecimal.insert(nil) }
        observeSetChange(obs, "setOptObjectId") { obj.setOptObjectId.insert(nil) }

        observeSetChange(obs, "mapBool") { obj.mapBool["key"] = true }
        observeSetChange(obs, "mapInt8") { obj.mapInt8["key"] = 10 }
        observeSetChange(obs, "mapInt16") { obj.mapInt16["key"] = 10 }
        observeSetChange(obs, "mapInt32") { obj.mapInt32["key"] = 10 }
        observeSetChange(obs, "mapInt64") { obj.mapInt64["key"] = 10 }
        observeSetChange(obs, "mapFloat") { obj.mapFloat["key"] = 10 }
        observeSetChange(obs, "mapDouble") { obj.mapDouble["key"] = 10 }
        observeSetChange(obs, "mapString") { obj.mapString["key"] = "abc" }
        observeSetChange(obs, "mapDecimal") { obj.mapDecimal["key"] = decimal }
        observeSetChange(obs, "mapObjectId") { obj.mapObjectId["key"] = objectId }

        observeSetChange(obs, "mapOptBool") { obj.mapOptBool["key"] = true }
        observeSetChange(obs, "mapOptInt8") { obj.mapOptInt8["key"] = 10 }
        observeSetChange(obs, "mapOptInt16") { obj.mapOptInt16["key"] = 10 }
        observeSetChange(obs, "mapOptInt32") { obj.mapOptInt32["key"] = 10 }
        observeSetChange(obs, "mapOptInt64") { obj.mapOptInt64["key"] = 10 }
        observeSetChange(obs, "mapOptFloat") { obj.mapOptFloat["key"] = 10 }
        observeSetChange(obs, "mapOptDouble") { obj.mapOptDouble["key"] = 10 }
        observeSetChange(obs, "mapOptString") { obj.mapOptString["key"] = "abc" }
        observeSetChange(obs, "mapOptDecimal") { obj.mapOptDecimal["key"] = decimal }
        observeSetChange(obs, "mapOptObjectId") { obj.mapOptObjectId["key"] = objectId }

        observeSetChange(obs, "mapOptBool") { obj.mapOptBool["key"] = nil }
        observeSetChange(obs, "mapOptInt8") { obj.mapOptInt8["key"] = nil }
        observeSetChange(obs, "mapOptInt16") { obj.mapOptInt16["key"] = nil }
        observeSetChange(obs, "mapOptInt32") { obj.mapOptInt32["key"] = nil }
        observeSetChange(obs, "mapOptInt64") { obj.mapOptInt64["key"] = nil }
        observeSetChange(obs, "mapOptFloat") { obj.mapOptFloat["key"] = nil }
        observeSetChange(obs, "mapOptDouble") { obj.mapOptDouble["key"] = nil }
        observeSetChange(obs, "mapOptString") { obj.mapOptString["key"] = nil }
        observeSetChange(obs, "mapOptDecimal") { obj.mapOptDecimal["key"] = nil }
        observeSetChange(obs, "mapOptObjectId") { obj.mapOptObjectId["key"] = nil }

        if obs.realm == nil {
            return
        }

        observeChange(obs, "invalidated", false, true) {
            self.realm.delete(obj)
        }

        let (obj2, obs2) = getObject(SwiftKVOObject())
        observeChange(obs2, "arrayCol.invalidated", false, true) {
            self.realm.delete(obj2)
        }

        let (obj3, obs3) = getObject(SwiftKVOObject())
        observeChange(obs3, "setCol.invalidated", false, true) {
            self.realm.delete(obj3)
        }

        let (obj4, obs4) = getObject(SwiftKVOObject())
        observeChange(obs4, "mapBool.invalidated", false, true) {
            self.realm.delete(obj4)
        }
    }

    func testTypedObservation() {
        let (obj, obs) = getObject(SwiftKVOObject())

        // Swift 5.2+ warns when a literal keypath to a non-@objc property is
        // passed to observe(). This only works when it's passed directly and
        // not via a helper, so make sure we aren't triggering this warning on
        // any property types.
        _ = obs.observe(\.boolCol) { _, _ in }
        _ = obs.observe(\.int8Col) { _, _ in }
        _ = obs.observe(\.int16Col) { _, _ in }
        _ = obs.observe(\.int32Col) { _, _ in }
        _ = obs.observe(\.int64Col) { _, _ in }
        _ = obs.observe(\.floatCol) { _, _ in }
        _ = obs.observe(\.doubleCol) { _, _ in }
        _ = obs.observe(\.stringCol) { _, _ in }
        _ = obs.observe(\.binaryCol) { _, _ in }
        _ = obs.observe(\.dateCol) { _, _ in }
        _ = obs.observe(\.objectCol) { _, _ in }
        _ = obs.observe(\.optStringCol) { _, _ in }
        _ = obs.observe(\.optBinaryCol) { _, _ in }
        _ = obs.observe(\.optDateCol) { _, _ in }
        _ = obs.observe(\.optStringCol) { _, _ in }
        _ = obs.observe(\.optBinaryCol) { _, _ in }
        _ = obs.observe(\.optDateCol) { _, _ in }
        _ = obs.observe(\.isInvalidated) { _, _ in }

        observeChange(obs, \.boolCol, false, true) { obj.boolCol = true }

        observeChange(obs, \.int8Col, 1 as Int8, 10 as Int8) { obj.int8Col = 10 }
        observeChange(obs, \.int16Col, 2 as Int16, 10 as Int16) { obj.int16Col = 10 }
        observeChange(obs, \.int32Col, 3 as Int32, 10 as Int32) { obj.int32Col = 10 }
        observeChange(obs, \.int64Col, 4 as Int64, 10 as Int64) { obj.int64Col = 10 }
        observeChange(obs, \.floatCol, 5 as Float, 10 as Float) { obj.floatCol = 10 }
        observeChange(obs, \.doubleCol, 6 as Double, 10 as Double) { obj.doubleCol = 10 }
        observeChange(obs, \.stringCol, "", "abc") { obj.stringCol = "abc" }

        let data = "abc".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        observeChange(obs, \.binaryCol, Data(), data) { obj.binaryCol = data }

        let date = Date(timeIntervalSince1970: 1)
        observeChange(obs, \.dateCol, Date(timeIntervalSince1970: 0), date) { obj.dateCol = date }

        let decimal = Decimal128(number: 2)
        observeChange(obs, \.decimalCol, Decimal128(number: 1), decimal) { obj.decimalCol = decimal }

        let oldObjectId = obj.objectIdCol
        let objectId = ObjectId()
        observeChange(obs, \.objectIdCol, oldObjectId, objectId) { obj.objectIdCol = objectId }

        observeChange(obs, \.objectCol, nil, obj) { obj.objectCol = obj }

        observeChange(obs, \.optStringCol, nil, "abc") { obj.optStringCol = "abc" }
        observeChange(obs, \.optBinaryCol, nil, data) { obj.optBinaryCol = data }
        observeChange(obs, \.optDateCol, nil, date) { obj.optDateCol = date }
        observeChange(obs, \.optDecimalCol, nil, decimal) { obj.optDecimalCol = decimal }
        observeChange(obs, \.optObjectIdCol, nil, objectId) { obj.optObjectIdCol = objectId }

        observeChange(obs, \.optStringCol, "abc", nil) { obj.optStringCol = nil }
        observeChange(obs, \.optBinaryCol, data, nil) { obj.optBinaryCol = nil }
        observeChange(obs, \.optDateCol, date, nil) { obj.optDateCol = nil }
        observeChange(obs, \.optDecimalCol, decimal, nil) { obj.optDecimalCol = nil }
        observeChange(obs, \.optObjectIdCol, objectId, nil) { obj.optObjectIdCol = nil }

        if obs.realm == nil {
            return
        }

        observeChange(obs, \.isInvalidated, false, true) {
            self.realm.delete(obj)
        }
    }

    func testReadSharedSchemaFromObservedObject() {
        let obj = SwiftKVOObject()
        obj.addObserver(self, forKeyPath: "boolCol", options: [.old, .new], context: nil)
        XCTAssertEqual(type(of: obj).sharedSchema(), SwiftKVOObject.sharedSchema())
        obj.removeObserver(self, forKeyPath: "boolCol")
    }
}

@available(*, deprecated) // Silence deprecation warnings for RealmOptional
class KVOPersistedTests: KVOTests {
    override func getObject(_ obj: SwiftKVOObject) -> (SwiftKVOObject, SwiftKVOObject) {
        realm.add(obj)
        return (obj, obj)
    }
}

@available(*, deprecated) // Silence deprecation warnings for RealmOptional
class KVOMultipleAccessorsTests: KVOTests {
    override func getObject(_ obj: SwiftKVOObject) -> (SwiftKVOObject, SwiftKVOObject) {
        realm.add(obj)
        return (obj, realm.object(ofType: SwiftKVOObject.self, forPrimaryKey: obj.pk)!)
    }
}
