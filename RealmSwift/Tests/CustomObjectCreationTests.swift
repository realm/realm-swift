////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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

private func mapValues<T>(_ values: [T]) -> [String: T] {
    var map = [String: T]()
    for (i, v) in values.enumerated() {
        map["\(i)"] = v
    }
    return map
}

private func objectValues() -> [ModernEmbeddedObject] {
    return [.init(value: [1]), .init(value: [2]), .init(value: [3])]
}

private func objectWrapperValues() -> [EmbeddedObjectWrapper] {
    return objectValues().map(EmbeddedObjectWrapper.init)
}

class CustomObjectCreationTests: TestCase {
    var rawValues: [String: Any]!
    var wrappedValues: [String: Any]!
    var nilOptionalValues: [String: Any]!
    override func setUp() {
        rawValues = [
            "bool": Bool.values().last!,
            "int": Int.values().last!,
            "int8": Int8.values().last!,
            "int16": Int16.values().last!,
            "int32": Int32.values().last!,
            "int64": Int64.values().last!,
            "float": Float.values().last!,
            "double": Double.values().last!,
            "string": String.values().last!,
            "binary": Data.values().last!,
            "date": Date.values().last!,
            "decimal": Decimal128.values().last!,
            "objectId": ObjectId.values().last!,
            "uuid": UUID.values().last!,
            "object": objectValues().last!,

            "optBool": Bool.values().last!,
            "optInt": Int.values().last!,
            "optInt8": Int8.values().last!,
            "optInt16": Int16.values().last!,
            "optInt32": Int32.values().last!,
            "optInt64": Int64.values().last!,
            "optFloat": Float.values().last!,
            "optDouble": Double.values().last!,
            "optString": String.values().last!,
            "optBinary": Data.values().last!,
            "optDate": Date.values().last!,
            "optDecimal": Decimal128.values().last!,
            "optObjectId": ObjectId.values().last!,
            "optUuid": UUID.values().last!,
            "optObject": objectValues().last!,

            "listBool": Bool.values(),
            "listInt": Int.values(),
            "listInt8": Int8.values(),
            "listInt16": Int16.values(),
            "listInt32": Int32.values(),
            "listInt64": Int64.values(),
            "listFloat": Float.values(),
            "listDouble": Double.values(),
            "listString": String.values(),
            "listBinary": Data.values(),
            "listDate": Date.values(),
            "listDecimal": Decimal128.values(),
            "listUuid": UUID.values(),
            "listObjectId": ObjectId.values(),
            "listObject": objectValues(),

            "listOptBool": Bool?.values(),
            "listOptInt": Int?.values(),
            "listOptInt8": Int8?.values(),
            "listOptInt16": Int16?.values(),
            "listOptInt32": Int32?.values(),
            "listOptInt64": Int64?.values(),
            "listOptFloat": Float?.values(),
            "listOptDouble": Double?.values(),
            "listOptString": String?.values(),
            "listOptBinary": Data?.values(),
            "listOptDate": Date?.values(),
            "listOptDecimal": Decimal128?.values(),
            "listOptUuid": UUID?.values(),
            "listOptObjectId": ObjectId?.values(),

            "setBool": Bool.values(),
            "setInt": Int.values(),
            "setInt8": Int8.values(),
            "setInt16": Int16.values(),
            "setInt32": Int32.values(),
            "setInt64": Int64.values(),
            "setFloat": Float.values(),
            "setDouble": Double.values(),
            "setString": String.values(),
            "setBinary": Data.values(),
            "setDate": Date.values(),
            "setDecimal": Decimal128.values(),
            "setUuid": UUID.values(),
            "setObjectId": ObjectId.values(),

            "setOptBool": Bool?.values(),
            "setOptInt": Int?.values(),
            "setOptInt8": Int8?.values(),
            "setOptInt16": Int16?.values(),
            "setOptInt32": Int32?.values(),
            "setOptInt64": Int64?.values(),
            "setOptFloat": Float?.values(),
            "setOptDouble": Double?.values(),
            "setOptString": String?.values(),
            "setOptBinary": Data?.values(),
            "setOptDate": Date?.values(),
            "setOptDecimal": Decimal128?.values(),
            "setOptUuid": UUID?.values(),
            "setOptObjectId": ObjectId?.values(),

            "mapBool": mapValues(Bool.values()),
            "mapInt": mapValues(Int.values()),
            "mapInt8": mapValues(Int8.values()),
            "mapInt16": mapValues(Int16.values()),
            "mapInt32": mapValues(Int32.values()),
            "mapInt64": mapValues(Int64.values()),
            "mapFloat": mapValues(Float.values()),
            "mapDouble": mapValues(Double.values()),
            "mapString": mapValues(String.values()),
            "mapBinary": mapValues(Data.values()),
            "mapDate": mapValues(Date.values()),
            "mapDecimal": mapValues(Decimal128.values()),
            "mapUuid": mapValues(UUID.values()),
            "mapObjectId": mapValues(ObjectId.values()),
            "mapObject": mapValues(objectValues()),

            "mapOptBool": mapValues(Bool?.values()),
            "mapOptInt": mapValues(Int?.values()),
            "mapOptInt8": mapValues(Int8?.values()),
            "mapOptInt16": mapValues(Int16?.values()),
            "mapOptInt32": mapValues(Int32?.values()),
            "mapOptInt64": mapValues(Int64?.values()),
            "mapOptFloat": mapValues(Float?.values()),
            "mapOptDouble": mapValues(Double?.values()),
            "mapOptString": mapValues(String?.values()),
            "mapOptBinary": mapValues(Data?.values()),
            "mapOptDate": mapValues(Date?.values()),
            "mapOptDecimal": mapValues(Decimal128?.values()),
            "mapOptUuid": mapValues(UUID?.values()),
            "mapOptObjectId": mapValues(ObjectId?.values()),
            "mapOptObject": mapValues(objectValues())
        ]
        wrappedValues = [
            "bool": BoolWrapper.values().last!,
            "int": IntWrapper.values().last!,
            "int8": Int8Wrapper.values().last!,
            "int16": Int16Wrapper.values().last!,
            "int32": Int32Wrapper.values().last!,
            "int64": Int64Wrapper.values().last!,
            "float": FloatWrapper.values().last!,
            "double": DoubleWrapper.values().last!,
            "string": StringWrapper.values().last!,
            "binary": DataWrapper.values().last!,
            "date": DateWrapper.values().last!,
            "decimal": Decimal128Wrapper.values().last!,
            "objectId": ObjectIdWrapper.values().last!,
            "uuid": UUIDWrapper.values().last!,
            "object": objectWrapperValues().last!,

            "optBool": BoolWrapper.values().last!,
            "optInt": IntWrapper.values().last!,
            "optInt8": Int8Wrapper.values().last!,
            "optInt16": Int16Wrapper.values().last!,
            "optInt32": Int32Wrapper.values().last!,
            "optInt64": Int64Wrapper.values().last!,
            "optFloat": FloatWrapper.values().last!,
            "optDouble": DoubleWrapper.values().last!,
            "optString": StringWrapper.values().last!,
            "optBinary": DataWrapper.values().last!,
            "optDate": DateWrapper.values().last!,
            "optDecimal": Decimal128Wrapper.values().last!,
            "optObjectId": ObjectIdWrapper.values().last!,
            "optUuid": UUIDWrapper.values().last!,
            "optObject": objectWrapperValues().last!,

            "listBool": BoolWrapper.values(),
            "listInt": IntWrapper.values(),
            "listInt8": Int8Wrapper.values(),
            "listInt16": Int16Wrapper.values(),
            "listInt32": Int32Wrapper.values(),
            "listInt64": Int64Wrapper.values(),
            "listFloat": FloatWrapper.values(),
            "listDouble": DoubleWrapper.values(),
            "listString": StringWrapper.values(),
            "listBinary": DataWrapper.values(),
            "listDate": DateWrapper.values(),
            "listDecimal": Decimal128Wrapper.values(),
            "listUuid": UUIDWrapper.values(),
            "listObjectId": ObjectIdWrapper.values(),
            "listObject": objectWrapperValues(),

            "listOptBool": BoolWrapper?.values(),
            "listOptInt": IntWrapper?.values(),
            "listOptInt8": Int8Wrapper?.values(),
            "listOptInt16": Int16Wrapper?.values(),
            "listOptInt32": Int32Wrapper?.values(),
            "listOptInt64": Int64Wrapper?.values(),
            "listOptFloat": FloatWrapper?.values(),
            "listOptDouble": DoubleWrapper?.values(),
            "listOptString": StringWrapper?.values(),
            "listOptBinary": DataWrapper?.values(),
            "listOptDate": DateWrapper?.values(),
            "listOptDecimal": Decimal128Wrapper?.values(),
            "listOptUuid": UUIDWrapper?.values(),
            "listOptObjectId": ObjectIdWrapper?.values(),

            "setBool": BoolWrapper.values(),
            "setInt": IntWrapper.values(),
            "setInt8": Int8Wrapper.values(),
            "setInt16": Int16Wrapper.values(),
            "setInt32": Int32Wrapper.values(),
            "setInt64": Int64Wrapper.values(),
            "setFloat": FloatWrapper.values(),
            "setDouble": DoubleWrapper.values(),
            "setString": StringWrapper.values(),
            "setBinary": DataWrapper.values(),
            "setDate": DateWrapper.values(),
            "setDecimal": Decimal128Wrapper.values(),
            "setUuid": UUIDWrapper.values(),
            "setObjectId": ObjectIdWrapper.values(),

            "setOptBool": BoolWrapper?.values(),
            "setOptInt": IntWrapper?.values(),
            "setOptInt8": Int8Wrapper?.values(),
            "setOptInt16": Int16Wrapper?.values(),
            "setOptInt32": Int32Wrapper?.values(),
            "setOptInt64": Int64Wrapper?.values(),
            "setOptFloat": FloatWrapper?.values(),
            "setOptDouble": DoubleWrapper?.values(),
            "setOptString": StringWrapper?.values(),
            "setOptBinary": DataWrapper?.values(),
            "setOptDate": DateWrapper?.values(),
            "setOptDecimal": Decimal128Wrapper?.values(),
            "setOptUuid": UUIDWrapper?.values(),
            "setOptObjectId": ObjectIdWrapper?.values(),

            "mapBool": mapValues(BoolWrapper.values()),
            "mapInt": mapValues(IntWrapper.values()),
            "mapInt8": mapValues(Int8Wrapper.values()),
            "mapInt16": mapValues(Int16Wrapper.values()),
            "mapInt32": mapValues(Int32Wrapper.values()),
            "mapInt64": mapValues(Int64Wrapper.values()),
            "mapFloat": mapValues(FloatWrapper.values()),
            "mapDouble": mapValues(DoubleWrapper.values()),
            "mapString": mapValues(StringWrapper.values()),
            "mapBinary": mapValues(DataWrapper.values()),
            "mapDate": mapValues(DateWrapper.values()),
            "mapDecimal": mapValues(Decimal128Wrapper.values()),
            "mapUuid": mapValues(UUIDWrapper.values()),
            "mapObjectId": mapValues(ObjectIdWrapper.values()),
            "mapObject": mapValues(objectWrapperValues()),

            "mapOptBool": mapValues(BoolWrapper?.values()),
            "mapOptInt": mapValues(IntWrapper?.values()),
            "mapOptInt8": mapValues(Int8Wrapper?.values()),
            "mapOptInt16": mapValues(Int16Wrapper?.values()),
            "mapOptInt32": mapValues(Int32Wrapper?.values()),
            "mapOptInt64": mapValues(Int64Wrapper?.values()),
            "mapOptFloat": mapValues(FloatWrapper?.values()),
            "mapOptDouble": mapValues(DoubleWrapper?.values()),
            "mapOptString": mapValues(StringWrapper?.values()),
            "mapOptBinary": mapValues(DataWrapper?.values()),
            "mapOptDate": mapValues(DateWrapper?.values()),
            "mapOptDecimal": mapValues(Decimal128Wrapper?.values()),
            "mapOptUuid": mapValues(UUIDWrapper?.values()),
            "mapOptObjectId": mapValues(ObjectIdWrapper?.values()),
            "mapOptObject": mapValues(objectWrapperValues())
        ]
        nilOptionalValues = [
            "bool": BoolWrapper.values().last!,
            "int": IntWrapper.values().last!,
            "int8": Int8Wrapper.values().last!,
            "int16": Int16Wrapper.values().last!,
            "int32": Int32Wrapper.values().last!,
            "int64": Int64Wrapper.values().last!,
            "float": FloatWrapper.values().last!,
            "double": DoubleWrapper.values().last!,
            "string": StringWrapper.values().last!,
            "binary": DataWrapper.values().last!,
            "date": DateWrapper.values().last!,
            "decimal": Decimal128Wrapper.values().last!,
            "objectId": ObjectIdWrapper.values().last!,
            "uuid": UUIDWrapper.values().last!,
            "object": NSNull(),

            "optBool": NSNull(),
            "optInt": NSNull(),
            "optInt8": NSNull(),
            "optInt16": NSNull(),
            "optInt32": NSNull(),
            "optInt64": NSNull(),
            "optFloat": NSNull(),
            "optDouble": NSNull(),
            "optString": NSNull(),
            "optBinary": NSNull(),
            "optDate": NSNull(),
            "optDecimal": NSNull(),
            "optObjectId": NSNull(),
            "optUuid": NSNull(),
            "optObject": NSNull(),

            "listBool": BoolWrapper.values(),
            "listInt": IntWrapper.values(),
            "listInt8": Int8Wrapper.values(),
            "listInt16": Int16Wrapper.values(),
            "listInt32": Int32Wrapper.values(),
            "listInt64": Int64Wrapper.values(),
            "listFloat": FloatWrapper.values(),
            "listDouble": DoubleWrapper.values(),
            "listString": StringWrapper.values(),
            "listBinary": DataWrapper.values(),
            "listDate": DateWrapper.values(),
            "listDecimal": Decimal128Wrapper.values(),
            "listUuid": UUIDWrapper.values(),
            "listObjectId": ObjectIdWrapper.values(),
            "listObject": objectWrapperValues(),

            "listOptBool": [NSNull()],
            "listOptInt": [NSNull()],
            "listOptInt8": [NSNull()],
            "listOptInt16": [NSNull()],
            "listOptInt32": [NSNull()],
            "listOptInt64": [NSNull()],
            "listOptFloat": [NSNull()],
            "listOptDouble": [NSNull()],
            "listOptString": [NSNull()],
            "listOptBinary": [NSNull()],
            "listOptDate": [NSNull()],
            "listOptDecimal": [NSNull()],
            "listOptUuid": [NSNull()],
            "listOptObjectId": [NSNull()],

            "setBool": BoolWrapper.values(),
            "setInt": IntWrapper.values(),
            "setInt8": Int8Wrapper.values(),
            "setInt16": Int16Wrapper.values(),
            "setInt32": Int32Wrapper.values(),
            "setInt64": Int64Wrapper.values(),
            "setFloat": FloatWrapper.values(),
            "setDouble": DoubleWrapper.values(),
            "setString": StringWrapper.values(),
            "setBinary": DataWrapper.values(),
            "setDate": DateWrapper.values(),
            "setDecimal": Decimal128Wrapper.values(),
            "setUuid": UUIDWrapper.values(),
            "setObjectId": ObjectIdWrapper.values(),

            "setOptBool": [NSNull()],
            "setOptInt": [NSNull()],
            "setOptInt8": [NSNull()],
            "setOptInt16": [NSNull()],
            "setOptInt32": [NSNull()],
            "setOptInt64": [NSNull()],
            "setOptFloat": [NSNull()],
            "setOptDouble": [NSNull()],
            "setOptString": [NSNull()],
            "setOptBinary": [NSNull()],
            "setOptDate": [NSNull()],
            "setOptDecimal": [NSNull()],
            "setOptUuid": [NSNull()],
            "setOptObjectId": [NSNull()],

            "mapBool": mapValues(BoolWrapper.values()),
            "mapInt": mapValues(IntWrapper.values()),
            "mapInt8": mapValues(Int8Wrapper.values()),
            "mapInt16": mapValues(Int16Wrapper.values()),
            "mapInt32": mapValues(Int32Wrapper.values()),
            "mapInt64": mapValues(Int64Wrapper.values()),
            "mapFloat": mapValues(FloatWrapper.values()),
            "mapDouble": mapValues(DoubleWrapper.values()),
            "mapString": mapValues(StringWrapper.values()),
            "mapBinary": mapValues(DataWrapper.values()),
            "mapDate": mapValues(DateWrapper.values()),
            "mapDecimal": mapValues(Decimal128Wrapper.values()),
            "mapUuid": mapValues(UUIDWrapper.values()),
            "mapObjectId": mapValues(ObjectIdWrapper.values()),
            "mapObject": ["0": NSNull()],

            "mapOptBool": ["0": NSNull()],
            "mapOptInt": ["0": NSNull()],
            "mapOptInt8": ["0": NSNull()],
            "mapOptInt16": ["0": NSNull()],
            "mapOptInt32": ["0": NSNull()],
            "mapOptInt64": ["0": NSNull()],
            "mapOptFloat": ["0": NSNull()],
            "mapOptDouble": ["0": NSNull()],
            "mapOptString": ["0": NSNull()],
            "mapOptBinary": ["0": NSNull()],
            "mapOptDate": ["0": NSNull()],
            "mapOptDecimal": ["0": NSNull()],
            "mapOptUuid": ["0": NSNull()],
            "mapOptObjectId": ["0": NSNull()],
            "mapOptObject": ["0": NSNull()],
        ]
        super.setUp()
    }

    override func tearDown() {
        rawValues = nil
        wrappedValues = nil
        super.tearDown()
    }

    @nonobjc func verifyDefault(_ obj: AllCustomPersistableTypes) {
        XCTAssertEqual(obj.bool, BoolWrapper(value: .init()))
        XCTAssertEqual(obj.int, IntWrapper(value: .init()))
        XCTAssertEqual(obj.int8, Int8Wrapper(value: .init()))
        XCTAssertEqual(obj.int16, Int16Wrapper(value: .init()))
        XCTAssertEqual(obj.int32, Int32Wrapper(value: .init()))
        XCTAssertEqual(obj.int64, Int64Wrapper(value: .init()))
        XCTAssertEqual(obj.float, FloatWrapper(value: .init()))
        XCTAssertEqual(obj.double, DoubleWrapper(value: .init()))
        XCTAssertEqual(obj.string, StringWrapper(value: .init()))
        XCTAssertEqual(obj.binary, DataWrapper(value: .init()))
        XCTAssertEqual(obj.decimal, Decimal128Wrapper(value: .init()))
        XCTAssertEqual(obj.object, EmbeddedObjectWrapper(value: .init()))

        // Date and UUID default init generate new values each time
        XCTAssertEqual(obj.date.value.timeIntervalSince1970,
                       DateWrapper(value: .init()).value.timeIntervalSince1970,
                       accuracy: 1.0)
        XCTAssertNotEqual(obj.uuid, UUIDWrapper(value: .init()))
        XCTAssertNotEqual(obj.objectId, ObjectIdWrapper(value: .init()))

        XCTAssertEqual(obj.optBool, nil)
        XCTAssertEqual(obj.optInt, nil)
        XCTAssertEqual(obj.optInt8, nil)
        XCTAssertEqual(obj.optInt16, nil)
        XCTAssertEqual(obj.optInt32, nil)
        XCTAssertEqual(obj.optInt64, nil)
        XCTAssertEqual(obj.optFloat, nil)
        XCTAssertEqual(obj.optDouble, nil)
        XCTAssertEqual(obj.optString, nil)
        XCTAssertEqual(obj.optBinary, nil)
        XCTAssertEqual(obj.optDate, nil)
        XCTAssertEqual(obj.optDecimal, nil)
        XCTAssertEqual(obj.optObjectId, nil)
        XCTAssertEqual(obj.optUuid, nil)
        XCTAssertEqual(obj.optObject, nil)
    }

    @nonobjc func verifyObject(_ obj: AllCustomPersistableTypes) {
        XCTAssertEqual(obj.bool, BoolWrapper.values().last!)
        XCTAssertEqual(obj.int, IntWrapper.values().last!)
        XCTAssertEqual(obj.int8, Int8Wrapper.values().last!)
        XCTAssertEqual(obj.int16, Int16Wrapper.values().last!)
        XCTAssertEqual(obj.int32, Int32Wrapper.values().last!)
        XCTAssertEqual(obj.int64, Int64Wrapper.values().last!)
        XCTAssertEqual(obj.float, FloatWrapper.values().last!)
        XCTAssertEqual(obj.double, DoubleWrapper.values().last!)
        XCTAssertEqual(obj.string, StringWrapper.values().last!)
        XCTAssertEqual(obj.binary, DataWrapper.values().last!)
        XCTAssertEqual(obj.date, DateWrapper.values().last!)
        XCTAssertEqual(obj.decimal, Decimal128Wrapper.values().last!)
        XCTAssertEqual(obj.objectId, ObjectIdWrapper.values().last!)
        XCTAssertEqual(obj.uuid, UUIDWrapper.values().last!)
        XCTAssertEqual(obj.object, objectWrapperValues().last!)

        XCTAssertEqual(obj.optBool, BoolWrapper.values().last!)
        XCTAssertEqual(obj.optInt, IntWrapper.values().last!)
        XCTAssertEqual(obj.optInt8, Int8Wrapper.values().last!)
        XCTAssertEqual(obj.optInt16, Int16Wrapper.values().last!)
        XCTAssertEqual(obj.optInt32, Int32Wrapper.values().last!)
        XCTAssertEqual(obj.optInt64, Int64Wrapper.values().last!)
        XCTAssertEqual(obj.optFloat, FloatWrapper.values().last!)
        XCTAssertEqual(obj.optDouble, DoubleWrapper.values().last!)
        XCTAssertEqual(obj.optString, StringWrapper.values().last!)
        XCTAssertEqual(obj.optBinary, DataWrapper.values().last!)
        XCTAssertEqual(obj.optDate, DateWrapper.values().last!)
        XCTAssertEqual(obj.optDecimal, Decimal128Wrapper.values().last!)
        XCTAssertEqual(obj.optObjectId, ObjectIdWrapper.values().last!)
        XCTAssertEqual(obj.optUuid, UUIDWrapper.values().last!)
        XCTAssertEqual(obj.optObject, objectWrapperValues().last!)
    }

    @nonobjc func verifyDefault(_ obj: CustomPersistableCollections) {
        XCTAssertEqual(obj.listBool.count, 0)
        XCTAssertEqual(obj.listInt.count, 0)
        XCTAssertEqual(obj.listInt8.count, 0)
        XCTAssertEqual(obj.listInt16.count, 0)
        XCTAssertEqual(obj.listInt32.count, 0)
        XCTAssertEqual(obj.listInt64.count, 0)
        XCTAssertEqual(obj.listFloat.count, 0)
        XCTAssertEqual(obj.listDouble.count, 0)
        XCTAssertEqual(obj.listString.count, 0)
        XCTAssertEqual(obj.listBinary.count, 0)
        XCTAssertEqual(obj.listDate.count, 0)
        XCTAssertEqual(obj.listDecimal.count, 0)
        XCTAssertEqual(obj.listUuid.count, 0)
        XCTAssertEqual(obj.listObjectId.count, 0)
        XCTAssertEqual(obj.listObject.count, 0)

        XCTAssertEqual(obj.listOptBool.count, 0)
        XCTAssertEqual(obj.listOptInt.count, 0)
        XCTAssertEqual(obj.listOptInt8.count, 0)
        XCTAssertEqual(obj.listOptInt16.count, 0)
        XCTAssertEqual(obj.listOptInt32.count, 0)
        XCTAssertEqual(obj.listOptInt64.count, 0)
        XCTAssertEqual(obj.listOptFloat.count, 0)
        XCTAssertEqual(obj.listOptDouble.count, 0)
        XCTAssertEqual(obj.listOptString.count, 0)
        XCTAssertEqual(obj.listOptBinary.count, 0)
        XCTAssertEqual(obj.listOptDate.count, 0)
        XCTAssertEqual(obj.listOptDecimal.count, 0)
        XCTAssertEqual(obj.listOptUuid.count, 0)
        XCTAssertEqual(obj.listOptObjectId.count, 0)

        XCTAssertEqual(obj.setBool.count, 0)
        XCTAssertEqual(obj.setInt.count, 0)
        XCTAssertEqual(obj.setInt8.count, 0)
        XCTAssertEqual(obj.setInt16.count, 0)
        XCTAssertEqual(obj.setInt32.count, 0)
        XCTAssertEqual(obj.setInt64.count, 0)
        XCTAssertEqual(obj.setFloat.count, 0)
        XCTAssertEqual(obj.setDouble.count, 0)
        XCTAssertEqual(obj.setString.count, 0)
        XCTAssertEqual(obj.setBinary.count, 0)
        XCTAssertEqual(obj.setDate.count, 0)
        XCTAssertEqual(obj.setDecimal.count, 0)
        XCTAssertEqual(obj.setUuid.count, 0)
        XCTAssertEqual(obj.setObjectId.count, 0)

        XCTAssertEqual(obj.setOptBool.count, 0)
        XCTAssertEqual(obj.setOptInt.count, 0)
        XCTAssertEqual(obj.setOptInt8.count, 0)
        XCTAssertEqual(obj.setOptInt16.count, 0)
        XCTAssertEqual(obj.setOptInt32.count, 0)
        XCTAssertEqual(obj.setOptInt64.count, 0)
        XCTAssertEqual(obj.setOptFloat.count, 0)
        XCTAssertEqual(obj.setOptDouble.count, 0)
        XCTAssertEqual(obj.setOptString.count, 0)
        XCTAssertEqual(obj.setOptBinary.count, 0)
        XCTAssertEqual(obj.setOptDate.count, 0)
        XCTAssertEqual(obj.setOptDecimal.count, 0)
        XCTAssertEqual(obj.setOptUuid.count, 0)
        XCTAssertEqual(obj.setOptObjectId.count, 0)

        XCTAssertEqual(obj.mapBool.count, 0)
        XCTAssertEqual(obj.mapInt.count, 0)
        XCTAssertEqual(obj.mapInt8.count, 0)
        XCTAssertEqual(obj.mapInt16.count, 0)
        XCTAssertEqual(obj.mapInt32.count, 0)
        XCTAssertEqual(obj.mapInt64.count, 0)
        XCTAssertEqual(obj.mapFloat.count, 0)
        XCTAssertEqual(obj.mapDouble.count, 0)
        XCTAssertEqual(obj.mapString.count, 0)
        XCTAssertEqual(obj.mapBinary.count, 0)
        XCTAssertEqual(obj.mapDate.count, 0)
        XCTAssertEqual(obj.mapDecimal.count, 0)
        XCTAssertEqual(obj.mapUuid.count, 0)
        XCTAssertEqual(obj.mapObjectId.count, 0)
        XCTAssertEqual(obj.mapObject.count, 0)

        XCTAssertEqual(obj.mapOptBool.count, 0)
        XCTAssertEqual(obj.mapOptInt.count, 0)
        XCTAssertEqual(obj.mapOptInt8.count, 0)
        XCTAssertEqual(obj.mapOptInt16.count, 0)
        XCTAssertEqual(obj.mapOptInt32.count, 0)
        XCTAssertEqual(obj.mapOptInt64.count, 0)
        XCTAssertEqual(obj.mapOptFloat.count, 0)
        XCTAssertEqual(obj.mapOptDouble.count, 0)
        XCTAssertEqual(obj.mapOptString.count, 0)
        XCTAssertEqual(obj.mapOptBinary.count, 0)
        XCTAssertEqual(obj.mapOptDate.count, 0)
        XCTAssertEqual(obj.mapOptDecimal.count, 0)
        XCTAssertEqual(obj.mapOptUuid.count, 0)
        XCTAssertEqual(obj.mapOptObjectId.count, 0)
    }

    @nonobjc func verifyNil(_ obj: AllCustomPersistableTypes) {
        XCTAssertEqual(obj.object, EmbeddedObjectWrapper(value: 0))
        XCTAssertNil(obj.optBool)
        XCTAssertNil(obj.optInt)
        XCTAssertNil(obj.optInt8)
        XCTAssertNil(obj.optInt16)
        XCTAssertNil(obj.optInt32)
        XCTAssertNil(obj.optInt64)
        XCTAssertNil(obj.optFloat)
        XCTAssertNil(obj.optDouble)
        XCTAssertNil(obj.optString)
        XCTAssertNil(obj.optBinary)
        XCTAssertNil(obj.optDate)
        XCTAssertNil(obj.optDecimal)
        XCTAssertNil(obj.optObjectId)
        XCTAssertNil(obj.optUuid)
        XCTAssertNil(obj.optObject)
    }

    @nonobjc func verifyNil(_ obj: CustomPersistableCollections) {
        assertListEqual(obj.listOptBool, [nil])
        assertListEqual(obj.listOptInt, [nil])
        assertListEqual(obj.listOptInt8, [nil])
        assertListEqual(obj.listOptInt16, [nil])
        assertListEqual(obj.listOptInt32, [nil])
        assertListEqual(obj.listOptInt64, [nil])
        assertListEqual(obj.listOptFloat, [nil])
        assertListEqual(obj.listOptDouble, [nil])
        assertListEqual(obj.listOptString, [nil])
        assertListEqual(obj.listOptBinary, [nil])
        assertListEqual(obj.listOptDate, [nil])
        assertListEqual(obj.listOptDecimal, [nil])
        assertListEqual(obj.listOptUuid, [nil])
        assertListEqual(obj.listOptObjectId, [nil])

        assertSetEqual(obj.setOptBool, [nil])
        assertSetEqual(obj.setOptInt, [nil])
        assertSetEqual(obj.setOptInt8, [nil])
        assertSetEqual(obj.setOptInt16, [nil])
        assertSetEqual(obj.setOptInt32, [nil])
        assertSetEqual(obj.setOptInt64, [nil])
        assertSetEqual(obj.setOptFloat, [nil])
        assertSetEqual(obj.setOptDouble, [nil])
        assertSetEqual(obj.setOptString, [nil])
        assertSetEqual(obj.setOptBinary, [nil])
        assertSetEqual(obj.setOptDate, [nil])
        assertSetEqual(obj.setOptDecimal, [nil])
        assertSetEqual(obj.setOptUuid, [nil])
        assertSetEqual(obj.setOptObjectId, [nil])

        assertMapEqual(obj.mapObject, [EmbeddedObjectWrapper(value: 0)])
        assertMapEqual(obj.mapOptBool, [nil])
        assertMapEqual(obj.mapOptInt, [nil])
        assertMapEqual(obj.mapOptInt8, [nil])
        assertMapEqual(obj.mapOptInt16, [nil])
        assertMapEqual(obj.mapOptInt32, [nil])
        assertMapEqual(obj.mapOptInt64, [nil])
        assertMapEqual(obj.mapOptFloat, [nil])
        assertMapEqual(obj.mapOptDouble, [nil])
        assertMapEqual(obj.mapOptString, [nil])
        assertMapEqual(obj.mapOptBinary, [nil])
        assertMapEqual(obj.mapOptDate, [nil])
        assertMapEqual(obj.mapOptDecimal, [nil])
        assertMapEqual(obj.mapOptUuid, [nil])
        assertMapEqual(obj.mapOptObjectId, [nil])
        assertMapEqual(obj.mapOptObject, [nil])
    }

    @nonobjc func assertListEqual<T: RealmCollectionValue>(_ list: List<T>, _ expected: [T]) {
        XCTAssertEqual(Array(list), Array(expected))
    }

    @nonobjc func assertSetEqual<T: RealmCollectionValue>(_ set: MutableSet<T>, _ expected: [T]) {
        XCTAssertEqual(set.count, Set(expected).count)
        XCTAssertEqual(Set(set), Set(expected))
    }
    @nonobjc func assertMapEqual<T: RealmCollectionValue>(_ map: Map<String, T>, _ expected: [T]) {
        XCTAssertEqual(map.count, expected.count)
        for (i, value) in expected.enumerated() {
            XCTAssertEqual(map["\(i)"], value)
        }
    }

    @nonobjc func verifyObject(_ obj: CustomPersistableCollections) {
        assertListEqual(obj.listBool, BoolWrapper.values())
        assertListEqual(obj.listInt, IntWrapper.values())
        assertListEqual(obj.listInt8, Int8Wrapper.values())
        assertListEqual(obj.listInt16, Int16Wrapper.values())
        assertListEqual(obj.listInt32, Int32Wrapper.values())
        assertListEqual(obj.listInt64, Int64Wrapper.values())
        assertListEqual(obj.listFloat, FloatWrapper.values())
        assertListEqual(obj.listDouble, DoubleWrapper.values())
        assertListEqual(obj.listString, StringWrapper.values())
        assertListEqual(obj.listBinary, DataWrapper.values())
        assertListEqual(obj.listDate, DateWrapper.values())
        assertListEqual(obj.listDecimal, Decimal128Wrapper.values())
        assertListEqual(obj.listUuid, UUIDWrapper.values())
        assertListEqual(obj.listObjectId, ObjectIdWrapper.values())
        assertListEqual(obj.listObject, objectWrapperValues())

        assertListEqual(obj.listOptBool, BoolWrapper?.values())
        assertListEqual(obj.listOptInt, IntWrapper?.values())
        assertListEqual(obj.listOptInt8, Int8Wrapper?.values())
        assertListEqual(obj.listOptInt16, Int16Wrapper?.values())
        assertListEqual(obj.listOptInt32, Int32Wrapper?.values())
        assertListEqual(obj.listOptInt64, Int64Wrapper?.values())
        assertListEqual(obj.listOptFloat, FloatWrapper?.values())
        assertListEqual(obj.listOptDouble, DoubleWrapper?.values())
        assertListEqual(obj.listOptString, StringWrapper?.values())
        assertListEqual(obj.listOptBinary, DataWrapper?.values())
        assertListEqual(obj.listOptDate, DateWrapper?.values())
        assertListEqual(obj.listOptDecimal, Decimal128Wrapper?.values())
        assertListEqual(obj.listOptUuid, UUIDWrapper?.values())
        assertListEqual(obj.listOptObjectId, ObjectIdWrapper?.values())

        assertSetEqual(obj.setBool, BoolWrapper.values())
        assertSetEqual(obj.setInt, IntWrapper.values())
        assertSetEqual(obj.setInt8, Int8Wrapper.values())
        assertSetEqual(obj.setInt16, Int16Wrapper.values())
        assertSetEqual(obj.setInt32, Int32Wrapper.values())
        assertSetEqual(obj.setInt64, Int64Wrapper.values())
        assertSetEqual(obj.setFloat, FloatWrapper.values())
        assertSetEqual(obj.setDouble, DoubleWrapper.values())
        assertSetEqual(obj.setString, StringWrapper.values())
        assertSetEqual(obj.setBinary, DataWrapper.values())
        assertSetEqual(obj.setDate, DateWrapper.values())
        assertSetEqual(obj.setDecimal, Decimal128Wrapper.values())
        assertSetEqual(obj.setUuid, UUIDWrapper.values())
        assertSetEqual(obj.setObjectId, ObjectIdWrapper.values())

        assertSetEqual(obj.setOptBool, BoolWrapper?.values())
        assertSetEqual(obj.setOptInt, IntWrapper?.values())
        assertSetEqual(obj.setOptInt8, Int8Wrapper?.values())
        assertSetEqual(obj.setOptInt16, Int16Wrapper?.values())
        assertSetEqual(obj.setOptInt32, Int32Wrapper?.values())
        assertSetEqual(obj.setOptInt64, Int64Wrapper?.values())
        assertSetEqual(obj.setOptFloat, FloatWrapper?.values())
        assertSetEqual(obj.setOptDouble, DoubleWrapper?.values())
        assertSetEqual(obj.setOptString, StringWrapper?.values())
        assertSetEqual(obj.setOptBinary, DataWrapper?.values())
        assertSetEqual(obj.setOptDate, DateWrapper?.values())
        assertSetEqual(obj.setOptDecimal, Decimal128Wrapper?.values())
        assertSetEqual(obj.setOptUuid, UUIDWrapper?.values())
        assertSetEqual(obj.setOptObjectId, ObjectIdWrapper?.values())

        assertMapEqual(obj.mapBool, BoolWrapper.values())
        assertMapEqual(obj.mapInt, IntWrapper.values())
        assertMapEqual(obj.mapInt8, Int8Wrapper.values())
        assertMapEqual(obj.mapInt16, Int16Wrapper.values())
        assertMapEqual(obj.mapInt32, Int32Wrapper.values())
        assertMapEqual(obj.mapInt64, Int64Wrapper.values())
        assertMapEqual(obj.mapFloat, FloatWrapper.values())
        assertMapEqual(obj.mapDouble, DoubleWrapper.values())
        assertMapEqual(obj.mapString, StringWrapper.values())
        assertMapEqual(obj.mapBinary, DataWrapper.values())
        assertMapEqual(obj.mapDate, DateWrapper.values())
        assertMapEqual(obj.mapDecimal, Decimal128Wrapper.values())
        assertMapEqual(obj.mapUuid, UUIDWrapper.values())
        assertMapEqual(obj.mapObjectId, ObjectIdWrapper.values())
        assertMapEqual(obj.mapObject, objectWrapperValues())

        assertMapEqual(obj.mapOptBool, BoolWrapper?.values())
        assertMapEqual(obj.mapOptInt, IntWrapper?.values())
        assertMapEqual(obj.mapOptInt8, Int8Wrapper?.values())
        assertMapEqual(obj.mapOptInt16, Int16Wrapper?.values())
        assertMapEqual(obj.mapOptInt32, Int32Wrapper?.values())
        assertMapEqual(obj.mapOptInt64, Int64Wrapper?.values())
        assertMapEqual(obj.mapOptFloat, FloatWrapper?.values())
        assertMapEqual(obj.mapOptDouble, DoubleWrapper?.values())
        assertMapEqual(obj.mapOptString, StringWrapper?.values())
        assertMapEqual(obj.mapOptBinary, DataWrapper?.values())
        assertMapEqual(obj.mapOptDate, DateWrapper?.values())
        assertMapEqual(obj.mapOptDecimal, Decimal128Wrapper?.values())
        assertMapEqual(obj.mapOptUuid, UUIDWrapper?.values())
        assertMapEqual(obj.mapOptObjectId, ObjectIdWrapper?.values())
        assertMapEqual(obj.mapOptObject, objectWrapperValues())
    }

    // MARK: - Tests

    func testInitDefault() {
        verifyDefault(AllCustomPersistableTypes())
        verifyDefault(CustomPersistableCollections())
    }

    private func arrayValues<T: Object>(_ type: T.Type, _ values: [String: Any]) -> [Any] {
        T.sharedSchema()!.properties.map { values[$0.name] as Any }
    }

    func testInitWithArray() {
        verifyObject(AllCustomPersistableTypes(value: arrayValues(AllCustomPersistableTypes.self, wrappedValues!)))
        verifyObject(AllCustomPersistableTypes(value: arrayValues(AllCustomPersistableTypes.self, rawValues!)))
        verifyNil(AllCustomPersistableTypes(value: arrayValues(AllCustomPersistableTypes.self, nilOptionalValues!)))
        verifyObject(CustomPersistableCollections(value: arrayValues(CustomPersistableCollections.self, wrappedValues!)))
        verifyObject(CustomPersistableCollections(value: arrayValues(CustomPersistableCollections.self, rawValues!)))
        verifyNil(CustomPersistableCollections(value: arrayValues(CustomPersistableCollections.self, nilOptionalValues!)))
    }

    func testInitWithDictionary() {
        verifyObject(AllCustomPersistableTypes(value: rawValues!))
        verifyObject(AllCustomPersistableTypes(value: wrappedValues!))
        verifyNil(AllCustomPersistableTypes(value: nilOptionalValues!))
        verifyObject(CustomPersistableCollections(value: rawValues!))
        verifyObject(CustomPersistableCollections(value: wrappedValues!))
        verifyNil(CustomPersistableCollections(value: nilOptionalValues!))
    }

    func testInitWithObject() {
        verifyObject(AllCustomPersistableTypes(value: AllCustomPersistableTypes(value: wrappedValues!)))
        verifyNil(AllCustomPersistableTypes(value: AllCustomPersistableTypes(value: nilOptionalValues!)))
        verifyObject(CustomPersistableCollections(value: CustomPersistableCollections(value: wrappedValues!)))
        verifyNil(CustomPersistableCollections(value: CustomPersistableCollections(value: nilOptionalValues!)))
    }

    func testInitFailable() {
        _ = FailableCustomObject(value: [])
        assertThrows(FailableCustomObject(value: ["int": 1]), reason: "Could not convert value '1' to type 'IntFailableWrapper'.")

        let obj = FailableCustomObject(value: ["optInt": 1,
                                               "listInt": [1],
                                               "optListInt": [1],
                                               "setInt": [1],
                                               "optSetInt": [1],
                                               "mapInt": ["1": 1],
                                               "optMapInt": ["1": 1]] as [String: Any])
        XCTAssertNil(obj.optInt)
        assertThrows(obj.listInt[0], reason: "Could not convert value '1' to type 'IntFailableWrapper'.")
        assertListEqual(obj.optListInt, [nil])
        assertThrows(obj.setInt.first, reason: "Could not convert value '1' to type 'IntFailableWrapper'.")
        assertSetEqual(obj.optSetInt, [nil])
        assertThrows(obj.mapInt["1"], reason: "Could not convert value '1' to type 'IntFailableWrapper'.")
        XCTAssertEqual(obj.optMapInt["1"], .some(nil))
    }

    func testCreateDefault() {
        let realm = try! Realm()
        try! realm.write {
            verifyDefault(realm.create(AllCustomPersistableTypes.self))
            verifyDefault(realm.create(CustomPersistableCollections.self))
        }
    }

    func testCreateWithArray() {
        let realm = try! Realm()
        try! realm.write {
            verifyObject(realm.create(AllCustomPersistableTypes.self, value: arrayValues(AllCustomPersistableTypes.self, wrappedValues!)))
            verifyObject(realm.create(AllCustomPersistableTypes.self, value: arrayValues(AllCustomPersistableTypes.self, rawValues!)))
            verifyObject(realm.create(CustomPersistableCollections.self, value: arrayValues(CustomPersistableCollections.self, wrappedValues!)))
            verifyObject(realm.create(CustomPersistableCollections.self, value: arrayValues(CustomPersistableCollections.self, rawValues!)))
        }
    }

    func testCreateWithDictionary() {
        let realm = try! Realm()
        try! realm.write {
            verifyObject(realm.create(AllCustomPersistableTypes.self, value: wrappedValues!))
            verifyObject(realm.create(AllCustomPersistableTypes.self, value: rawValues!))
            verifyObject(realm.create(CustomPersistableCollections.self, value: wrappedValues!))
            verifyObject(realm.create(CustomPersistableCollections.self, value: rawValues!))
        }
    }

    func testCreateWithObject() {
        let realm = try! Realm()
        try! realm.write {
            let obj = AllCustomPersistableTypes(value: wrappedValues!)
            verifyObject(realm.create(AllCustomPersistableTypes.self, value: obj))
        }
    }

    func testCreateFailable() {
        let realm = try! Realm()
        realm.beginWrite()

        let obj = realm.create(FailableCustomObject.self,
                               value: ["int": 1,
                                       "optInt": 1,
                                       "listInt": [1],
                                       "optListInt": [1],
                                       "setInt": [1],
                                       "optSetInt": [1],
                                       "mapInt": ["1": 1],
                                       "optMapInt": ["1": 1]] as [String: Any])

        assertThrows(obj.int, reason: "Failed to convert persisted value '1' to type 'IntFailableWrapper' in a non-optional context.")
        XCTAssertNil(obj.optInt)
        assertThrows(obj.listInt[0], reason: "Could not convert value '1' to type 'IntFailableWrapper'.")
        assertListEqual(obj.optListInt, [nil])
        assertThrows(obj.setInt.first, reason: "Could not convert value '1' to type 'IntFailableWrapper'.")
        assertSetEqual(obj.optSetInt, [nil])
        assertThrows(obj.mapInt["1"], reason: "Could not convert value '1' to type 'IntFailableWrapper'.")
        XCTAssertEqual(obj.optMapInt["1"], .some(nil))

        realm.cancelWrite()
    }

    func testAddDefault() {
        let realm = try! Realm()
        let obj1 = AllCustomPersistableTypes()
        let obj2 = CustomPersistableCollections()
        try! realm.write {
            realm.add(obj1)
            realm.add(obj2)
        }
        verifyDefault(obj1)
        verifyDefault(obj2)
    }

    func testAdd() {
        let realm = try! Realm()
        let obj1 = AllCustomPersistableTypes(value: wrappedValues!)
        let obj2 = CustomPersistableCollections(value: wrappedValues!)
        try! realm.write {
            realm.add(obj1)
            realm.add(obj2)
        }
        verifyObject(obj1)
        verifyObject(obj2)
    }

    func testNullValueForNonOptionalPropertyBackedByOptional() {
        let realm = try! Realm()
        realm.beginWrite()

        // Non-optional object col can be null
        var values = wrappedValues!
        values["object"] = NSNull()
        XCTAssertEqual(AllCustomPersistableTypes(value: values).object.value, 0)
        XCTAssertEqual(realm.create(AllCustomPersistableTypes.self, value: values).object.value, 0)

        // Non-optional map col can contain null
        values = wrappedValues!
        values["mapObject"] = ["1": NSNull()]
        XCTAssertEqual(CustomPersistableCollections(value: values).mapObject["1"]!.value, 0)
        XCTAssertEqual(realm.create(CustomPersistableCollections.self, value: values).mapObject["1"]!.value, 0)

        // List can't, as the backing storage is actually non-optional
        values = wrappedValues!
        values["listObject"] = [NSNull()]
        assertThrows(CustomPersistableCollections(value: values))
        assertThrows(realm.create(CustomPersistableCollections.self, value: values))

        realm.cancelWrite()
    }

    func testInvalidDefaultInit() {
        let expectedError = "Failed to default construct a InvalidDefaultInit using the default value for persisted type Int. This conversion must either succeed, the property must be optional, or you must explicitly specify a default value for the property."
        let obj = InvalidDefaultInitObject()
        assertThrows(obj.value, reason: expectedError)
        let realm = try! Realm()
        realm.beginWrite()
        assertThrows(realm.create(InvalidDefaultInitObject.self), reason: expectedError)
        assertThrows(realm.add(obj), reason: expectedError)

        let obj2 = ValidDefaultInitObject()
        XCTAssertEqual(obj2.value.persistableValue, 0)
        _ = realm.create(ValidDefaultInitObject.self)
        realm.add(obj2)

        realm.cancelWrite()
    }
}

private struct InvalidDefaultInit: FailableCustomPersistable {
    typealias PersistedType = Int
    init?(persistedValue: Int) {
        if persistedValue == 0 {
            return nil
        }
    }
    var persistableValue: Int { 0 }
}

@objc(InvalidDefaultInitObject)
private class InvalidDefaultInitObject: Object {
    @Persisted var value: InvalidDefaultInit
}

@objc(ValidDefaultInitObject)
private class ValidDefaultInitObject: Object {
    @Persisted var value = InvalidDefaultInit(persistedValue: 1)!
}
