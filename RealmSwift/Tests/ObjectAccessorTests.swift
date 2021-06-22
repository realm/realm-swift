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

@available(*, deprecated) // Silence deprecation warnings for RealmOptional
class ObjectAccessorTests: TestCase {
    func setAndTestAllPropertiesViaNormalAccess(_ object: SwiftObject, _ optObject: SwiftOptionalObject) {
        object.boolCol = true
        XCTAssertEqual(object.boolCol, true)
        object.boolCol = false
        XCTAssertEqual(object.boolCol, false)

        object.intCol = -1
        XCTAssertEqual(object.intCol, -1)
        object.intCol = 0
        XCTAssertEqual(object.intCol, 0)
        object.intCol = 1
        XCTAssertEqual(object.intCol, 1)

        object.int8Col = -1
        XCTAssertEqual(object.int8Col, -1)
        object.int8Col = 0
        XCTAssertEqual(object.int8Col, 0)
        object.int8Col = 1
        XCTAssertEqual(object.int8Col, 1)

        object.int16Col = -1
        XCTAssertEqual(object.int16Col, -1)
        object.int16Col = 0
        XCTAssertEqual(object.int16Col, 0)
        object.int16Col = 1
        XCTAssertEqual(object.int16Col, 1)

        object.int32Col = -1
        XCTAssertEqual(object.int32Col, -1)
        object.int32Col = 0
        XCTAssertEqual(object.int32Col, 0)
        object.int32Col = 1
        XCTAssertEqual(object.int32Col, 1)

        object.int64Col = -1
        XCTAssertEqual(object.int64Col, -1)
        object.int64Col = 0
        XCTAssertEqual(object.int64Col, 0)
        object.int64Col = 1
        XCTAssertEqual(object.int64Col, 1)

        object.floatCol = 20
        XCTAssertEqual(object.floatCol, 20 as Float)
        object.floatCol = 20.2
        XCTAssertEqual(object.floatCol, 20.2 as Float)
        object.floatCol = 16777217
        XCTAssertEqual(Double(object.floatCol), 16777216.0 as Double)

        object.doubleCol = 20
        XCTAssertEqual(object.doubleCol, 20)
        object.doubleCol = 20.2
        XCTAssertEqual(object.doubleCol, 20.2)
        object.doubleCol = 16777217
        XCTAssertEqual(object.doubleCol, 16777217)

        object.stringCol = ""
        XCTAssertEqual(object.stringCol, "")
        let utf8TestString = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
        object.stringCol = utf8TestString
        XCTAssertEqual(object.stringCol, utf8TestString)

        let data = "b".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        object.binaryCol = data
        XCTAssertEqual(object.binaryCol, data)

        let date = Date(timeIntervalSinceReferenceDate: 2)
        object.dateCol = date
        XCTAssertEqual(object.dateCol, date)

        object.objectCol = SwiftBoolObject(value: [true])
        XCTAssertEqual(object.objectCol!.boolCol, true)

        object.intEnumCol = .value1
        XCTAssertEqual(object.intEnumCol, .value1)
        object.intEnumCol = .value2
        XCTAssertEqual(object.intEnumCol, .value2)

        object.decimalCol = "inf"
        XCTAssertEqual(object.decimalCol, "inf")
        object.decimalCol = "-inf"
        XCTAssertEqual(object.decimalCol, "-inf")
        object.decimalCol = "0"
        XCTAssertEqual(object.decimalCol, "0")
        object.decimalCol = "nan"
        XCTAssertTrue(object.decimalCol.isNaN)

        let oid1 = ObjectId("1234567890ab1234567890ab")
        let oid2 = ObjectId("abcdef123456abcdef123456")
        object.objectIdCol = oid1
        XCTAssertEqual(object.objectIdCol, oid1)
        object.objectIdCol = oid2
        XCTAssertEqual(object.objectIdCol, oid2)

        object.anyCol.value = .string("hello")
        XCTAssertEqual(object.anyCol.value.stringValue, "hello")

        // Optional properties

        optObject.optNSStringCol = ""
        XCTAssertEqual(optObject.optNSStringCol!, "")
        optObject.optNSStringCol = utf8TestString as NSString?
        XCTAssertEqual(optObject.optNSStringCol! as String, utf8TestString)
        optObject.optNSStringCol = nil
        XCTAssertNil(optObject.optNSStringCol)

        optObject.optStringCol = ""
        XCTAssertEqual(optObject.optStringCol!, "")
        optObject.optStringCol = utf8TestString
        XCTAssertEqual(optObject.optStringCol!, utf8TestString)
        optObject.optStringCol = nil
        XCTAssertNil(optObject.optStringCol)

        optObject.optBinaryCol = data
        XCTAssertEqual(optObject.optBinaryCol!, data)
        optObject.optBinaryCol = nil
        XCTAssertNil(optObject.optBinaryCol)

        optObject.optDateCol = date
        XCTAssertEqual(optObject.optDateCol!, date)
        optObject.optDateCol = nil
        XCTAssertNil(optObject.optDateCol)

        optObject.optIntCol.value = Int.min
        XCTAssertEqual(optObject.optIntCol.value!, Int.min)
        optObject.optIntCol.value = 0
        XCTAssertEqual(optObject.optIntCol.value!, 0)
        optObject.optIntCol.value = Int.max
        XCTAssertEqual(optObject.optIntCol.value!, Int.max)
        optObject.optIntCol.value = nil
        XCTAssertNil(optObject.optIntCol.value)

        optObject.optInt8Col.value = Int8.min
        XCTAssertEqual(optObject.optInt8Col.value!, Int8.min)
        optObject.optInt8Col.value = 0
        XCTAssertEqual(optObject.optInt8Col.value!, 0)
        optObject.optInt8Col.value = Int8.max
        XCTAssertEqual(optObject.optInt8Col.value!, Int8.max)
        optObject.optInt8Col.value = nil
        XCTAssertNil(optObject.optInt8Col.value)

        optObject.optInt16Col.value = Int16.min
        XCTAssertEqual(optObject.optInt16Col.value!, Int16.min)
        optObject.optInt16Col.value = 0
        XCTAssertEqual(optObject.optInt16Col.value!, 0)
        optObject.optInt16Col.value = Int16.max
        XCTAssertEqual(optObject.optInt16Col.value!, Int16.max)
        optObject.optInt16Col.value = nil
        XCTAssertNil(optObject.optInt16Col.value)

        optObject.optInt32Col.value = Int32.min
        XCTAssertEqual(optObject.optInt32Col.value!, Int32.min)
        optObject.optInt32Col.value = 0
        XCTAssertEqual(optObject.optInt32Col.value!, 0)
        optObject.optInt32Col.value = Int32.max
        XCTAssertEqual(optObject.optInt32Col.value!, Int32.max)
        optObject.optInt32Col.value = nil
        XCTAssertNil(optObject.optInt32Col.value)

        optObject.optInt64Col.value = Int64.min
        XCTAssertEqual(optObject.optInt64Col.value!, Int64.min)
        optObject.optInt64Col.value = 0
        XCTAssertEqual(optObject.optInt64Col.value!, 0)
        optObject.optInt64Col.value = Int64.max
        XCTAssertEqual(optObject.optInt64Col.value!, Int64.max)
        optObject.optInt64Col.value = nil
        XCTAssertNil(optObject.optInt64Col.value)

        optObject.optFloatCol.value = -Float.greatestFiniteMagnitude
        XCTAssertEqual(optObject.optFloatCol.value!, -Float.greatestFiniteMagnitude)
        optObject.optFloatCol.value = 0
        XCTAssertEqual(optObject.optFloatCol.value!, 0)
        optObject.optFloatCol.value = Float.greatestFiniteMagnitude
        XCTAssertEqual(optObject.optFloatCol.value!, Float.greatestFiniteMagnitude)
        optObject.optFloatCol.value = nil
        XCTAssertNil(optObject.optFloatCol.value)

        optObject.optDoubleCol.value = -Double.greatestFiniteMagnitude
        XCTAssertEqual(optObject.optDoubleCol.value!, -Double.greatestFiniteMagnitude)
        optObject.optDoubleCol.value = 0
        XCTAssertEqual(optObject.optDoubleCol.value!, 0)
        optObject.optDoubleCol.value = Double.greatestFiniteMagnitude
        XCTAssertEqual(optObject.optDoubleCol.value!, Double.greatestFiniteMagnitude)
        optObject.optDoubleCol.value = nil
        XCTAssertNil(optObject.optDoubleCol.value)

        optObject.optBoolCol.value = true
        XCTAssertEqual(optObject.optBoolCol.value!, true)
        optObject.optBoolCol.value = false
        XCTAssertEqual(optObject.optBoolCol.value!, false)
        optObject.optBoolCol.value = nil
        XCTAssertNil(optObject.optBoolCol.value)

        optObject.optObjectCol = SwiftBoolObject(value: [true])
        XCTAssertEqual(optObject.optObjectCol!.boolCol, true)
        optObject.optObjectCol = nil
        XCTAssertNil(optObject.optObjectCol)

        optObject.optEnumCol.value = .value1
        XCTAssertEqual(optObject.optEnumCol.value, .value1)
        optObject.optEnumCol.value = .value2
        XCTAssertEqual(optObject.optEnumCol.value, .value2)
        optObject.optEnumCol.value = nil
        XCTAssertNil(optObject.optEnumCol.value)
    }

    func setAndTestAllPropertiesViaSubscript(_ object: SwiftObject, _ optObject: SwiftOptionalObject) {
        object["boolCol"] = true
        XCTAssertEqual(object["boolCol"] as! Bool, true)
        object["boolCol"] = false
        XCTAssertEqual(object["boolCol"] as! Bool, false)

        object["intCol"] = -1
        XCTAssertEqual(object["intCol"] as! Int, -1)
        object["intCol"] = 0
        XCTAssertEqual(object["intCol"] as! Int, 0)
        object["intCol"] = 1
        XCTAssertEqual(object["intCol"] as! Int, 1)

        object["int8Col"] = -1
        XCTAssertEqual(object["int8Col"] as! Int, -1)
        object["int8Col"] = 0
        XCTAssertEqual(object["int8Col"] as! Int, 0)
        object["int8Col"] = 1
        XCTAssertEqual(object["int8Col"] as! Int, 1)

        object["int16Col"] = -1
        XCTAssertEqual(object["int16Col"] as! Int, -1)
        object["int16Col"] = 0
        XCTAssertEqual(object["int16Col"] as! Int, 0)
        object["int16Col"] = 1
        XCTAssertEqual(object["int16Col"] as! Int, 1)

        object["int32Col"] = -1
        XCTAssertEqual(object["int32Col"] as! Int, -1)
        object["int32Col"] = 0
        XCTAssertEqual(object["int32Col"] as! Int, 0)
        object["int32Col"] = 1
        XCTAssertEqual(object["int32Col"] as! Int, 1)

        object["int64Col"] = -1
        XCTAssertEqual(object["int64Col"] as! Int, -1)
        object["int64Col"] = 0
        XCTAssertEqual(object["int64Col"] as! Int, 0)
        object["int64Col"] = 1
        XCTAssertEqual(object["int64Col"] as! Int, 1)

        object["floatCol"] = 20
        XCTAssertEqual(object["floatCol"] as! Float, 20 as Float)
        object["floatCol"] = 20.2
        XCTAssertEqual(object["floatCol"] as! Float, 20.2 as Float)
        object["floatCol"] = 16777217
        XCTAssertEqual(object["floatCol"] as! Float, 16777216 as Float)

        object["doubleCol"] = 20
        XCTAssertEqual(object["doubleCol"] as! Double, 20)
        object["doubleCol"] = 20.2
        XCTAssertEqual(object["doubleCol"] as! Double, 20.2)
        object["doubleCol"] = 16777217
        XCTAssertEqual(object["doubleCol"] as! Double, 16777217)

        object["stringCol"] = ""
        XCTAssertEqual(object["stringCol"] as! String, "")
        let utf8TestString = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
        object["stringCol"] = utf8TestString
        XCTAssertEqual(object["stringCol"] as! String, utf8TestString)

        let data = "b".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        object["binaryCol"] = data
        XCTAssertEqual(object["binaryCol"] as! Data, data)

        let date = Date(timeIntervalSinceReferenceDate: 2)
        object["dateCol"] = date
        XCTAssertEqual(object["dateCol"] as! Date, date)

        object["objectCol"] = SwiftBoolObject(value: [true])
        XCTAssertEqual((object["objectCol"]! as! SwiftBoolObject).boolCol, true)

        object["intEnumCol"] = IntEnum.value1
        XCTAssertEqual(object["intEnumCol"] as! Int, IntEnum.value1.rawValue)
        object["intEnumCol"] = IntEnum.value2
        XCTAssertEqual(object["intEnumCol"] as! Int, IntEnum.value2.rawValue)

        object["decimalCol"] = Decimal128("inf")
        XCTAssertEqual(object["decimalCol"] as! Decimal128, "inf")
        object["decimalCol"] = Decimal128("-inf")
        XCTAssertEqual(object["decimalCol"] as! Decimal128, "-inf")
        object["decimalCol"] = Decimal128("0")
        XCTAssertEqual(object["decimalCol"] as! Decimal128, "0")
        object["decimalCol"] = Decimal128("nan")
        XCTAssertTrue((object["decimalCol"] as! Decimal128).isNaN)

        let oid1 = ObjectId("1234567890ab1234567890ab")
        let oid2 = ObjectId("abcdef123456abcdef123456")
        object["objectIdCol"] = oid1
        XCTAssertEqual(object["objectIdCol"] as! ObjectId, oid1)
        object["objectIdCol"] = oid2
        XCTAssertEqual(object["objectIdCol"] as! ObjectId, oid2)

        object["anyCol"] = AnyRealmValue.string("hello")
        XCTAssertEqual(object["anyCol"] as! String, "hello")
        object["anyCol"] = "goodbye"
        XCTAssertEqual(object["anyCol"] as! String, "goodbye")

        // Optional properties

        optObject["optNSStringCol"] = ""
        XCTAssertEqual(optObject["optNSStringCol"] as! String, "")
        optObject["optNSStringCol"] = utf8TestString as NSString?
        XCTAssertEqual(optObject["optNSStringCol"] as! String, utf8TestString)
        optObject["optNSStringCol"] = nil
        XCTAssertNil(optObject["optNSStringCol"])

        optObject["optStringCol"] = ""
        XCTAssertEqual(optObject["optStringCol"] as! String, "")
        optObject["optStringCol"] = utf8TestString
        XCTAssertEqual(optObject["optStringCol"] as! String, utf8TestString)
        optObject["optStringCol"] = nil
        XCTAssertNil(optObject["optStringCol"])

        optObject["optBinaryCol"] = data
        XCTAssertEqual(optObject["optBinaryCol"] as! Data, data)
        optObject["optBinaryCol"] = nil
        XCTAssertNil(optObject["optBinaryCol"])

        optObject["optDateCol"] = date
        XCTAssertEqual(optObject["optDateCol"] as! Date, date)
        optObject["optDateCol"] = nil
        XCTAssertNil(optObject["optDateCol"])

        optObject["optIntCol"] = Int.min
        XCTAssertEqual(optObject["optIntCol"] as! Int, Int.min)
        optObject["optIntCol"] = 0
        XCTAssertEqual(optObject["optIntCol"] as! Int, 0)
        optObject["optIntCol"] = Int.max
        XCTAssertEqual(optObject["optIntCol"] as! Int, Int.max)
        optObject["optIntCol"] = nil
        XCTAssertNil(optObject["optIntCol"])

        optObject["optInt8Col"] = Int8.min
        XCTAssertEqual(optObject["optInt8Col"] as! Int8, Int8.min)
        optObject["optInt8Col"] = 0
        XCTAssertEqual(optObject["optInt8Col"] as! Int8, 0)
        optObject["optInt8Col"] = Int8.max
        XCTAssertEqual(optObject["optInt8Col"] as! Int8, Int8.max)
        optObject["optInt8Col"] = nil
        XCTAssertNil(optObject["optInt8Col"])

        optObject["optInt16Col"] = Int16.min
        XCTAssertEqual(optObject["optInt16Col"] as! Int16, Int16.min)
        optObject["optInt16Col"] = 0
        XCTAssertEqual(optObject["optInt16Col"] as! Int16, 0)
        optObject["optInt16Col"] = Int16.max
        XCTAssertEqual(optObject["optInt16Col"] as! Int16, Int16.max)
        optObject["optInt16Col"] = nil
        XCTAssertNil(optObject["optInt16Col"])

        optObject["optInt32Col"] = Int32.min
        XCTAssertEqual(optObject["optInt32Col"] as! Int32, Int32.min)
        optObject["optInt32Col"] = 0
        XCTAssertEqual(optObject["optInt32Col"] as! Int32, 0)
        optObject["optInt32Col"] = Int32.max
        XCTAssertEqual(optObject["optInt32Col"] as! Int32, Int32.max)
        optObject["optInt32Col"] = nil
        XCTAssertNil(optObject["optInt32Col"])

        optObject["optInt64Col"] = Int64.min
        XCTAssertEqual(optObject["optInt64Col"] as! Int64, Int64.min)
        optObject["optInt64Col"] = 0
        XCTAssertEqual(optObject["optInt64Col"] as! Int64, 0)
        optObject["optInt64Col"] = Int64.max
        XCTAssertEqual(optObject["optInt64Col"] as! Int64, Int64.max)
        optObject["optInt64Col"] = nil
        XCTAssertNil(optObject["optInt64Col"])

        optObject["optFloatCol"] = -Float.greatestFiniteMagnitude
        XCTAssertEqual(optObject["optFloatCol"] as! Float, -Float.greatestFiniteMagnitude)
        optObject["optFloatCol"] = 0
        XCTAssertEqual(optObject["optFloatCol"] as! Float, 0)
        optObject["optFloatCol"] = Float.greatestFiniteMagnitude
        XCTAssertEqual(optObject["optFloatCol"] as! Float, Float.greatestFiniteMagnitude)
        optObject["optFloatCol"] = nil
        XCTAssertNil(optObject["optFloatCol"])

        optObject["optDoubleCol"] = -Double.greatestFiniteMagnitude
        XCTAssertEqual(optObject["optDoubleCol"] as! Double, -Double.greatestFiniteMagnitude)
        optObject["optDoubleCol"] = 0
        XCTAssertEqual(optObject["optDoubleCol"] as! Double, 0)
        optObject["optDoubleCol"] = Double.greatestFiniteMagnitude
        XCTAssertEqual(optObject["optDoubleCol"] as! Double, Double.greatestFiniteMagnitude)
        optObject["optDoubleCol"] = nil
        XCTAssertNil(optObject["optDoubleCol"])

        optObject["optBoolCol"] = true
        XCTAssertEqual(optObject["optBoolCol"] as! Bool, true)
        optObject["optBoolCol"] = false
        XCTAssertEqual(optObject["optBoolCol"] as! Bool, false)
        optObject["optBoolCol"] = nil
        XCTAssertNil(optObject["optBoolCol"])

        optObject["optObjectCol"] = SwiftBoolObject(value: [true])
        XCTAssertEqual((optObject["optObjectCol"] as! SwiftBoolObject).boolCol, true)
        optObject["optObjectCol"] = nil
        XCTAssertNil(optObject["optObjectCol"])

        optObject["optEnumCol"] = IntEnum.value1
        XCTAssertEqual(optObject["optEnumCol"] as! Int, IntEnum.value1.rawValue)
        optObject["optEnumCol"] = IntEnum.value2
        XCTAssertEqual(optObject["optEnumCol"] as! Int, IntEnum.value2.rawValue)
        optObject["optEnumCol"] = nil
        XCTAssertNil(optObject["optEnumCol"])
    }

    func setAndTestAnyViaAccessorObjectWithCoercion(_ object: ObjectBase) {
        let anyProp = RLMObjectBaseObjectSchema(object)!.properties.first { $0.name == "anyCol" }!
        func get() -> Any {
            return anyProp.swiftAccessor!.get(anyProp, on: object)
        }
        func set(_ value: Any) {
            anyProp.swiftAccessor!.set(anyProp, on: object, to: value)
        }
        set(true)
        XCTAssertEqual(get() as! Bool, true)
        set(false)
        XCTAssertEqual(get() as! Bool, false)

        set(-1)
        XCTAssertEqual(get() as! Int, -1)
        set(0)
        XCTAssertEqual(get() as! Int, 0)
        set(1)
        XCTAssertEqual(get() as! Int, 1)

        set(-1 as Int8)
        XCTAssertEqual(get() as! Int, -1)
        set(0 as Int8)
        XCTAssertEqual(get() as! Int, 0)
        set(1 as Int8)
        XCTAssertEqual(get() as! Int, 1)

        set(-1 as Int16)
        XCTAssertEqual(get() as! Int, -1)
        set(0 as Int16)
        XCTAssertEqual(get() as! Int, 0)
        set(1 as Int16)
        XCTAssertEqual(get() as! Int, 1)

        set(-1 as Int32)
        XCTAssertEqual(get() as! Int, -1)
        set(0 as Int32)
        XCTAssertEqual(get() as! Int, 0)
        set(1 as Int32)
        XCTAssertEqual(get() as! Int, 1)

        set(-1 as Int64)
        XCTAssertEqual(get() as! Int, -1)
        set(0 as Int64)
        XCTAssertEqual(get() as! Int, 0)
        set(1 as Int64)
        XCTAssertEqual(get() as! Int, 1)

        set(20 as Float)
        XCTAssertEqual(get() as! Float, 20 as Float)
        set(20.2 as Float)
        XCTAssertEqual(get() as! Float, 20.2 as Float)

        set(20 as Double)
        XCTAssertEqual(get() as! Double, 20)
        set(20.2 as Double)
        XCTAssertEqual(get() as! Double, 20.2)
        set(16777217 as Double)
        XCTAssertEqual(get() as! Double, 16777217)

        set("")
        XCTAssertEqual(get() as! String, "")
        let utf8TestString = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
        set(utf8TestString)
        XCTAssertEqual(get() as! String, utf8TestString)

        let data = "b".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        set(data)
        XCTAssertEqual(get() as! Data, data)

        let date = Date(timeIntervalSinceReferenceDate: 2)
        set(date)
        XCTAssertEqual(get() as! Date, date)

        set(SwiftBoolObject(value: [true]))
        XCTAssertEqual((get() as! SwiftBoolObject).boolCol, true)

        set(Decimal128("inf"))
        XCTAssertEqual(get() as! Decimal128, "inf")
        set(Decimal128("-inf"))
        XCTAssertEqual(get() as! Decimal128, "-inf")
        set(Decimal128("0"))
        XCTAssertEqual(get() as! Decimal128, "0")
        set(Decimal128("nan"))
        XCTAssertTrue((get() as! Decimal128).isNaN)

        let oid1 = ObjectId("1234567890ab1234567890ab")
        let oid2 = ObjectId("abcdef123456abcdef123456")
        set(oid1)
        XCTAssertEqual(get() as! ObjectId, oid1)
        set(oid2)
        XCTAssertEqual(get() as! ObjectId, oid2)

        set(NSNull())
        XCTAssertTrue(get() is NSNull)
    }

    func setAndTestAnyViaAccessorObjectWithExplicitAnyRealmValue(_ object: ObjectBase) {
        let anyProp = RLMObjectBaseObjectSchema(object)!.properties.first { $0.name == "anyCol" }!
        func get() -> Any {
            return anyProp.swiftAccessor!.get(anyProp, on: object)
        }
        func set(_ value: AnyRealmValue) {
            anyProp.swiftAccessor!.set(anyProp, on: object, to: value)
        }
        set(.bool(true))
        XCTAssertEqual(get() as! Bool, true)
        set(.bool(false))
        XCTAssertEqual(get() as! Bool, false)

        set(.int(-1))
        XCTAssertEqual(get() as! Int, -1)
        set(.int(0))
        XCTAssertEqual(get() as! Int, 0)
        set(.int(1))
        XCTAssertEqual(get() as! Int, 1)

        set(.float(20))
        XCTAssertEqual(get() as! Float, 20 as Float)
        set(.float(20.2))
        XCTAssertEqual(get() as! Float, 20.2 as Float)

        set(.double(20))
        XCTAssertEqual(get() as! Double, 20)
        set(.double(20.2))
        XCTAssertEqual(get() as! Double, 20.2)
        set(.double(16777217))
        XCTAssertEqual(get() as! Double, 16777217)

        set(.string(""))
        XCTAssertEqual(get() as! String, "")
        let utf8TestString = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
        set(.string(utf8TestString))
        XCTAssertEqual(get() as! String, utf8TestString)

        let data = "b".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        set(.data(data))
        XCTAssertEqual(get() as! Data, data)

        let date = Date(timeIntervalSinceReferenceDate: 2)
        set(.date(date))
        XCTAssertEqual(get() as! Date, date)

        set(.object(SwiftBoolObject(value: [true])))
        XCTAssertEqual((get() as! SwiftBoolObject).boolCol, true)

        set(.decimal128(Decimal128("inf")))
        XCTAssertEqual(get() as! Decimal128, "inf")
        set(.decimal128(Decimal128("-inf")))
        XCTAssertEqual(get() as! Decimal128, "-inf")
        set(.decimal128(Decimal128("0")))
        XCTAssertEqual(get() as! Decimal128, "0")
        set(.decimal128(Decimal128("nan")))
        XCTAssertTrue((get() as! Decimal128).isNaN)

        let oid1 = ObjectId("1234567890ab1234567890ab")
        let oid2 = ObjectId("abcdef123456abcdef123456")
        set(.objectId(oid1))
        XCTAssertEqual(get() as! ObjectId, oid1)
        set(.objectId(oid2))
        XCTAssertEqual(get() as! ObjectId, oid2)

        set(.none)
        XCTAssertTrue(get() is NSNull)
    }

    func get(_ object: ObjectBase, _ propertyName: String) -> Any {
        let prop = RLMObjectBaseObjectSchema(object)!.properties.first { $0.name == propertyName }!
        return prop.swiftAccessor!.get(prop, on: object)
    }
    func set(_ object: ObjectBase, _ propertyName: String, _ value: Any) {
        let prop = RLMObjectBaseObjectSchema(object)!.properties.first { $0.name == propertyName }!
        prop.swiftAccessor!.set(prop, on: object, to: value)
    }

    func setAndTestRealmPropertyViaAccessor(_ object: ObjectBase) {
        set(object, "otherInt", -1)
        XCTAssertEqual(get(object, "otherInt") as! Int, -1)
        set(object, "otherInt", 0)
        XCTAssertEqual(get(object, "otherInt") as! Int, 0)
        set(object, "otherInt", 1)
        XCTAssertEqual(get(object, "otherInt") as! Int, 1)
        set(object, "otherInt", NSNull())
        XCTAssertTrue(get(object, "otherInt") is NSNull)

        set(object, "otherInt8", -1)
        XCTAssertEqual(get(object, "otherInt8") as! Int, -1)
        set(object, "otherInt8", 0)
        XCTAssertEqual(get(object, "otherInt8") as! Int, 0)
        set(object, "otherInt8", 1)
        XCTAssertEqual(get(object, "otherInt8") as! Int, 1)

        set(object, "otherInt16", -1)
        XCTAssertEqual(get(object, "otherInt16") as! Int, -1)
        set(object, "otherInt16", 0)
        XCTAssertEqual(get(object, "otherInt16") as! Int, 0)
        set(object, "otherInt16", 1)
        XCTAssertEqual(get(object, "otherInt16") as! Int, 1)

        set(object, "otherInt32", -1)
        XCTAssertEqual(get(object, "otherInt32") as! Int, -1)
        set(object, "otherInt32", 0)
        XCTAssertEqual(get(object, "otherInt32") as! Int, 0)
        set(object, "otherInt32", 1)
        XCTAssertEqual(get(object, "otherInt32") as! Int, 1)

        set(object, "otherInt64", -1)
        XCTAssertEqual(get(object, "otherInt64") as! Int, -1)
        set(object, "otherInt64", 0)
        XCTAssertEqual(get(object, "otherInt64") as! Int, 0)
        set(object, "otherInt64", 1)
        XCTAssertEqual(get(object, "otherInt64") as! Int, 1)

        set(object, "otherFloat", -20 as Float)
        XCTAssertEqual(get(object, "otherFloat") as! Float, -20)
        set(object, "otherFloat", 20.2 as Float)
        XCTAssertEqual(get(object, "otherFloat") as! Float, 20.2)
        // 16777217 is not exactly representable as a float
        set(object, "otherFloat", 16777217 as Double)
        XCTAssertEqual(get(object, "otherFloat") as! Float, 16777216)

        set(object, "otherDouble", -20 as Double)
        XCTAssertEqual(get(object, "otherDouble") as! Double, -20)
        set(object, "otherDouble", 20.2 as Double)
        XCTAssertEqual(get(object, "otherDouble") as! Double, 20.2)
        set(object, "otherDouble", 16777217 as Double)
        XCTAssertEqual(get(object, "otherDouble") as! Double, 16777217)

        set(object, "otherBool", true)
        XCTAssertEqual(get(object, "otherBool") as! Bool, true)
        set(object, "otherBool", false)
        XCTAssertEqual(get(object, "otherBool") as! Bool, false)
        set(object, "otherBool", 1)
        XCTAssertEqual(get(object, "otherBool") as! Bool, true)
        set(object, "otherBool", 0)
        XCTAssertEqual(get(object, "otherBool") as! Bool, false)

        set(object, "otherEnum", IntEnum.value1)
        XCTAssertEqual(get(object, "otherEnum") as! Int, IntEnum.value1.rawValue)
        set(object, "otherEnum", IntEnum.value2)
        XCTAssertEqual(get(object, "otherEnum") as! Int, IntEnum.value2.rawValue)
        set(object, "otherEnum", IntEnum.value1.rawValue)
        XCTAssertEqual(get(object, "otherEnum") as! Int, IntEnum.value1.rawValue)
    }

    func setAndTestRealmOptionalViaAccessor(_ object: ObjectBase) {
        set(object, "optIntCol", -1)
        XCTAssertEqual(get(object, "optIntCol") as! Int, -1)
        set(object, "optIntCol", 0)
        XCTAssertEqual(get(object, "optIntCol") as! Int, 0)
        set(object, "optIntCol", 1)
        XCTAssertEqual(get(object, "optIntCol") as! Int, 1)
        set(object, "optIntCol", NSNull())
        XCTAssertTrue(get(object, "optIntCol") is NSNull)

        set(object, "optInt8Col", -1)
        XCTAssertEqual(get(object, "optInt8Col") as! Int, -1)
        set(object, "optInt8Col", 0)
        XCTAssertEqual(get(object, "optInt8Col") as! Int, 0)
        set(object, "optInt8Col", 1)
        XCTAssertEqual(get(object, "optInt8Col") as! Int, 1)

        set(object, "optInt16Col", -1)
        XCTAssertEqual(get(object, "optInt16Col") as! Int, -1)
        set(object, "optInt16Col", 0)
        XCTAssertEqual(get(object, "optInt16Col") as! Int, 0)
        set(object, "optInt16Col", 1)
        XCTAssertEqual(get(object, "optInt16Col") as! Int, 1)

        set(object, "optInt32Col", -1)
        XCTAssertEqual(get(object, "optInt32Col") as! Int, -1)
        set(object, "optInt32Col", 0)
        XCTAssertEqual(get(object, "optInt32Col") as! Int, 0)
        set(object, "optInt32Col", 1)
        XCTAssertEqual(get(object, "optInt32Col") as! Int, 1)

        set(object, "optInt64Col", -1)
        XCTAssertEqual(get(object, "optInt64Col") as! Int, -1)
        set(object, "optInt64Col", 0)
        XCTAssertEqual(get(object, "optInt64Col") as! Int, 0)
        set(object, "optInt64Col", 1)
        XCTAssertEqual(get(object, "optInt64Col") as! Int, 1)

        set(object, "optFloatCol", -20 as Float)
        XCTAssertEqual(get(object, "optFloatCol") as! Float, -20)
        set(object, "optFloatCol", 20.2 as Float)
        XCTAssertEqual(get(object, "optFloatCol") as! Float, 20.2)
        // 16777217 is not exactly representable as a float
        set(object, "optFloatCol", 16777217 as Double)
        XCTAssertEqual(get(object, "optFloatCol") as! Float, 16777216)

        set(object, "optDoubleCol", -20 as Double)
        XCTAssertEqual(get(object, "optDoubleCol") as! Double, -20)
        set(object, "optDoubleCol", 20.2 as Double)
        XCTAssertEqual(get(object, "optDoubleCol") as! Double, 20.2)
        set(object, "optDoubleCol", 16777217 as Double)
        XCTAssertEqual(get(object, "optDoubleCol") as! Double, 16777217)

        set(object, "optBoolCol", true)
        XCTAssertEqual(get(object, "optBoolCol") as! Bool, true)
        set(object, "optBoolCol", false)
        XCTAssertEqual(get(object, "optBoolCol") as! Bool, false)
        set(object, "optBoolCol", 1)
        XCTAssertEqual(get(object, "optBoolCol") as! Bool, true)
        set(object, "optBoolCol", 0)
        XCTAssertEqual(get(object, "optBoolCol") as! Bool, false)

        set(object, "optEnumCol", IntEnum.value1)
        XCTAssertEqual(get(object, "optEnumCol") as! Int, IntEnum.value1.rawValue)
        set(object, "optEnumCol", IntEnum.value2)
        XCTAssertEqual(get(object, "optEnumCol") as! Int, IntEnum.value2.rawValue)
        set(object, "optEnumCol", IntEnum.value1.rawValue)
        XCTAssertEqual(get(object, "optEnumCol") as! Int, IntEnum.value1.rawValue)
        set(object, "optEnumCol", NSNull())
        XCTAssertTrue(get(object, "optEnumCol") is NSNull)
    }

    func setAndTestListViaAccessor(_ object: ObjectBase) {
        XCTAssertTrue(get(object, "int") is List<Int>)
        XCTAssertTrue(get(object, "int8") is List<Int8>)
        XCTAssertTrue(get(object, "int16") is List<Int16>)
        XCTAssertTrue(get(object, "int32") is List<Int32>)
        XCTAssertTrue(get(object, "int64") is List<Int64>)
        XCTAssertTrue(get(object, "float") is List<Float>)
        XCTAssertTrue(get(object, "double") is List<Double>)
        XCTAssertTrue(get(object, "string") is List<String>)
        XCTAssertTrue(get(object, "data") is List<Data>)
        XCTAssertTrue(get(object, "date") is List<Date>)
        XCTAssertTrue(get(object, "decimal") is List<Decimal128>)
        XCTAssertTrue(get(object, "objectId") is List<ObjectId>)
        XCTAssertTrue(get(object, "uuid") is List<UUID>)
        XCTAssertTrue(get(object, "any") is List<AnyRealmValue>)

        XCTAssertTrue(get(object, "intOpt") is List<Int?>)
        XCTAssertTrue(get(object, "int8Opt") is List<Int8?>)
        XCTAssertTrue(get(object, "int16Opt") is List<Int16?>)
        XCTAssertTrue(get(object, "int32Opt") is List<Int32?>)
        XCTAssertTrue(get(object, "int64Opt") is List<Int64?>)
        XCTAssertTrue(get(object, "floatOpt") is List<Float?>)
        XCTAssertTrue(get(object, "doubleOpt") is List<Double?>)
        XCTAssertTrue(get(object, "stringOpt") is List<String?>)
        XCTAssertTrue(get(object, "dataOpt") is List<Data?>)
        XCTAssertTrue(get(object, "dateOpt") is List<Date?>)
        XCTAssertTrue(get(object, "decimalOpt") is List<Decimal128?>)
        XCTAssertTrue(get(object, "objectIdOpt") is List<ObjectId?>)
        XCTAssertTrue(get(object, "uuidOpt") is List<UUID?>)

        set(object, "int", [1, 2, 3])
        XCTAssertEqual(Array(get(object, "int") as! List<Int>), [1, 2, 3])
        set(object, "int", [4, 5, 6])
        XCTAssertEqual(Array(get(object, "int") as! List<Int>), [4, 5, 6])
        set(object, "int8", get(object, "int"))
        XCTAssertEqual(Array(get(object, "int8") as! List<Int8>), [4, 5, 6])
        set(object, "int", NSNull())
        XCTAssertEqual((get(object, "int") as! List<Int>).count, 0)
    }

    func setAndTestSetViaAccessor(_ object: ObjectBase) {
        XCTAssertTrue(get(object, "int") is MutableSet<Int>)
        XCTAssertTrue(get(object, "int8") is MutableSet<Int8>)
        XCTAssertTrue(get(object, "int16") is MutableSet<Int16>)
        XCTAssertTrue(get(object, "int32") is MutableSet<Int32>)
        XCTAssertTrue(get(object, "int64") is MutableSet<Int64>)
        XCTAssertTrue(get(object, "float") is MutableSet<Float>)
        XCTAssertTrue(get(object, "double") is MutableSet<Double>)
        XCTAssertTrue(get(object, "string") is MutableSet<String>)
        XCTAssertTrue(get(object, "data") is MutableSet<Data>)
        XCTAssertTrue(get(object, "date") is MutableSet<Date>)
        XCTAssertTrue(get(object, "decimal") is MutableSet<Decimal128>)
        XCTAssertTrue(get(object, "objectId") is MutableSet<ObjectId>)
        XCTAssertTrue(get(object, "uuid") is MutableSet<UUID>)
        XCTAssertTrue(get(object, "any") is MutableSet<AnyRealmValue>)

        XCTAssertTrue(get(object, "intOpt") is MutableSet<Int?>)
        XCTAssertTrue(get(object, "int8Opt") is MutableSet<Int8?>)
        XCTAssertTrue(get(object, "int16Opt") is MutableSet<Int16?>)
        XCTAssertTrue(get(object, "int32Opt") is MutableSet<Int32?>)
        XCTAssertTrue(get(object, "int64Opt") is MutableSet<Int64?>)
        XCTAssertTrue(get(object, "floatOpt") is MutableSet<Float?>)
        XCTAssertTrue(get(object, "doubleOpt") is MutableSet<Double?>)
        XCTAssertTrue(get(object, "stringOpt") is MutableSet<String?>)
        XCTAssertTrue(get(object, "dataOpt") is MutableSet<Data?>)
        XCTAssertTrue(get(object, "dateOpt") is MutableSet<Date?>)
        XCTAssertTrue(get(object, "decimalOpt") is MutableSet<Decimal128?>)
        XCTAssertTrue(get(object, "objectIdOpt") is MutableSet<ObjectId?>)
        XCTAssertTrue(get(object, "uuidOpt") is MutableSet<UUID?>)

        set(object, "int", [1, 2, 3])
        XCTAssertEqual(Array(get(object, "int") as! MutableSet<Int>).sorted(), [1, 2, 3])
        set(object, "int", [4, 5, 6])
        XCTAssertEqual(Array(get(object, "int") as! MutableSet<Int>).sorted(), [4, 5, 6])
        set(object, "int8", get(object, "int"))
        XCTAssertEqual(Array(get(object, "int8") as! MutableSet<Int8>).sorted(), [4, 5, 6])
        set(object, "int", NSNull())
        XCTAssertEqual((get(object, "int") as! MutableSet<Int>).count, 0)
    }

    func setAndTestMapViaAccessor(_ object: ObjectBase) {
        XCTAssertTrue(get(object, "int") is Map<String, Int>)
        XCTAssertTrue(get(object, "int8") is Map<String, Int8>)
        XCTAssertTrue(get(object, "int16") is Map<String, Int16>)
        XCTAssertTrue(get(object, "int32") is Map<String, Int32>)
        XCTAssertTrue(get(object, "int64") is Map<String, Int64>)
        XCTAssertTrue(get(object, "float") is Map<String, Float>)
        XCTAssertTrue(get(object, "double") is Map<String, Double>)
        XCTAssertTrue(get(object, "string") is Map<String, String>)
        XCTAssertTrue(get(object, "data") is Map<String, Data>)
        XCTAssertTrue(get(object, "date") is Map<String, Date>)
        XCTAssertTrue(get(object, "decimal") is Map<String, Decimal128>)
        XCTAssertTrue(get(object, "objectId") is Map<String, ObjectId>)
        XCTAssertTrue(get(object, "uuid") is Map<String, UUID>)
        XCTAssertTrue(get(object, "any") is Map<String, AnyRealmValue>)

        XCTAssertTrue(get(object, "intOpt") is Map<String, Int?>)
        XCTAssertTrue(get(object, "int8Opt") is Map<String, Int8?>)
        XCTAssertTrue(get(object, "int16Opt") is Map<String, Int16?>)
        XCTAssertTrue(get(object, "int32Opt") is Map<String, Int32?>)
        XCTAssertTrue(get(object, "int64Opt") is Map<String, Int64?>)
        XCTAssertTrue(get(object, "floatOpt") is Map<String, Float?>)
        XCTAssertTrue(get(object, "doubleOpt") is Map<String, Double?>)
        XCTAssertTrue(get(object, "stringOpt") is Map<String, String?>)
        XCTAssertTrue(get(object, "dataOpt") is Map<String, Data?>)
        XCTAssertTrue(get(object, "dateOpt") is Map<String, Date?>)
        XCTAssertTrue(get(object, "decimalOpt") is Map<String, Decimal128?>)
        XCTAssertTrue(get(object, "objectIdOpt") is Map<String, ObjectId?>)
        XCTAssertTrue(get(object, "uuidOpt") is Map<String, UUID?>)

        set(object, "int", ["one": 1, "two": 2, "three": 3])
        XCTAssertEqual((get(object, "int") as! Map<String, Int>)["one"], 1)
        XCTAssertEqual((get(object, "int") as! Map<String, Int>)["two"], 2)
        XCTAssertEqual((get(object, "int") as! Map<String, Int>)["three"], 3)
        set(object, "int", NSNull())
        XCTAssertEqual((get(object, "int") as! Map<String, Int>).count, 0)
    }

    func testUnmanagedAccessors() {
        setAndTestAllPropertiesViaNormalAccess(SwiftObject(), SwiftOptionalObject())
        setAndTestAllPropertiesViaSubscript(SwiftObject(), SwiftOptionalObject())
        setAndTestAnyViaAccessorObjectWithCoercion(SwiftObject())
        setAndTestAnyViaAccessorObjectWithExplicitAnyRealmValue(SwiftObject())
        setAndTestRealmPropertyViaAccessor(CodableObject())
        setAndTestRealmOptionalViaAccessor(SwiftOptionalObject())
        setAndTestListViaAccessor(SwiftListObject())
        setAndTestSetViaAccessor(SwiftMutableSetObject())
        setAndTestMapViaAccessor(SwiftMapObject())
    }

    func testManagedAccessors() {
        let realm = try! Realm()
        realm.beginWrite()
        let object = realm.create(SwiftObject.self)
        let optionalObject = realm.create(SwiftOptionalObject.self)
        setAndTestAllPropertiesViaNormalAccess(object, optionalObject)
        setAndTestAllPropertiesViaSubscript(object, optionalObject)
        setAndTestAnyViaAccessorObjectWithCoercion(object)
        setAndTestAnyViaAccessorObjectWithExplicitAnyRealmValue(object)
        setAndTestRealmPropertyViaAccessor(realm.create(CodableObject.self))
        setAndTestRealmOptionalViaAccessor(optionalObject)
        setAndTestListViaAccessor(realm.create(SwiftListObject.self))
        setAndTestSetViaAccessor(realm.create(SwiftMutableSetObject.self))
        setAndTestMapViaAccessor(realm.create(SwiftMapObject.self))
        realm.cancelWrite()
    }

    func testIntSizes() {
        let realm = realmWithTestPath()

        let v8  = Int8(1)  << 6
        let v16 = Int16(1) << 12
        let v32 = Int32(1) << 30
        // 1 << 40 doesn't auto-promote to Int64 on 32-bit platforms
        let v64 = Int64(1) << 40
        try! realm.write {
            let obj = SwiftAllIntSizesObject()

            let testObject: () -> Void = {
                obj.objectSchema.properties.map { $0.name }.forEach { obj[$0] = 0 }

                obj["int8"] = NSNumber(value: v8)
                XCTAssertEqual((obj["int8"]! as! Int), Int(v8))
                obj["int16"] = NSNumber(value: v16)
                XCTAssertEqual((obj["int16"]! as! Int), Int(v16))
                obj["int32"] = NSNumber(value: v32)
                XCTAssertEqual((obj["int32"]! as! Int), Int(v32))
                obj["int64"] = NSNumber(value: v64)
                XCTAssertEqual((obj["int64"]! as! NSNumber), NSNumber(value: v64))

                obj.objectSchema.properties.map { $0.name }.forEach { obj[$0] = 0 }

                obj.setValue(NSNumber(value: v8), forKey: "int8")
                XCTAssertEqual((obj.value(forKey: "int8")! as! Int), Int(v8))
                obj.setValue(NSNumber(value: v16), forKey: "int16")
                XCTAssertEqual((obj.value(forKey: "int16")! as! Int), Int(v16))
                obj.setValue(NSNumber(value: v32), forKey: "int32")
                XCTAssertEqual((obj.value(forKey: "int32")! as! Int), Int(v32))
                obj.setValue(NSNumber(value: v64), forKey: "int64")
                XCTAssertEqual((obj.value(forKey: "int64")! as! NSNumber), NSNumber(value: v64))

                obj.objectSchema.properties.map { $0.name }.forEach { obj[$0] = 0 }

                obj.int8 = v8
                XCTAssertEqual(obj.int8, v8)
                obj.int16 = v16
                XCTAssertEqual(obj.int16, v16)
                obj.int32 = v32
                XCTAssertEqual(obj.int32, v32)
                obj.int64 = v64
                XCTAssertEqual(obj.int64, v64)
            }

            testObject()

            realm.add(obj)

            testObject()
        }

        let obj = realm.objects(SwiftAllIntSizesObject.self).first!
        XCTAssertEqual(obj.int8, v8)
        XCTAssertEqual(obj.int16, v16)
        XCTAssertEqual(obj.int32, v32)
        XCTAssertEqual(obj.int64, v64)
    }

    func testLongType() {
        let longNumber: Int64 = 17179869184
        let intNumber: Int64 = 2147483647
        let negativeLongNumber: Int64 = -17179869184
        let updatedLongNumber: Int64 = 8589934592

        let realm = realmWithTestPath()

        realm.beginWrite()
        realm.create(SwiftLongObject.self, value: [NSNumber(value: longNumber)])
        realm.create(SwiftLongObject.self, value: [NSNumber(value: intNumber)])
        realm.create(SwiftLongObject.self, value: [NSNumber(value: negativeLongNumber)])
        try! realm.commitWrite()

        let objects = realm.objects(SwiftLongObject.self)
        XCTAssertEqual(objects.count, Int(3), "3 rows expected")
        XCTAssertEqual(objects[0].longCol, longNumber, "2 ^ 34 expected")
        XCTAssertEqual(objects[1].longCol, intNumber, "2 ^ 31 - 1 expected")
        XCTAssertEqual(objects[2].longCol, negativeLongNumber, "-2 ^ 34 expected")

        realm.beginWrite()
        objects[0].longCol = updatedLongNumber
        try! realm.commitWrite()

        XCTAssertEqual(objects[0].longCol, updatedLongNumber, "After update: 2 ^ 33 expected")
    }

    func testCollectionsDuringResultsFastEnumeration() {
        let realm = realmWithTestPath()

        let object1 = SwiftObject()
        let object2 = SwiftObject()

        let trueObject = SwiftBoolObject()
        trueObject.boolCol = true

        let falseObject = SwiftBoolObject()
        falseObject.boolCol = false

        object1.arrayCol.append(trueObject)
        object1.arrayCol.append(falseObject)

        object2.arrayCol.append(trueObject)
        object2.arrayCol.append(falseObject)

        object1.setCol.insert(trueObject)
        object1.setCol.insert(falseObject)

        object2.setCol.insert(trueObject)
        object2.setCol.insert(falseObject)

        try! realm.write {
            realm.add(object1)
            realm.add(object2)
        }

        let objects = realm.objects(SwiftObject.self)

        let firstObject = objects.first
        XCTAssertEqual(2, firstObject!.arrayCol.count)
        XCTAssertEqual(2, firstObject!.setCol.count)

        let lastObject = objects.last
        XCTAssertEqual(2, lastObject!.arrayCol.count)
        XCTAssertEqual(2, lastObject!.setCol.count)

        var iterator = objects.makeIterator()
        let next = iterator.next()!
        XCTAssertEqual(next.arrayCol.count, 2)
        XCTAssertEqual(next.setCol.count, 2)

        for obj in objects {
            XCTAssertEqual(2, obj.arrayCol.count)
            XCTAssertEqual(2, obj.setCol.count)
        }
    }

    func testSettingOptionalPropertyOnDeletedObjectsThrows() {
        let realm = try! Realm()
        try! realm.write {
            let obj = realm.create(SwiftOptionalObject.self)
            let copy = realm.objects(SwiftOptionalObject.self).first!
            realm.delete(obj)

            self.assertThrows(copy.optIntCol.value = 1)
            self.assertThrows(copy.optIntCol.value = nil)

            self.assertThrows(obj.optIntCol.value = 1)
            self.assertThrows(obj.optIntCol.value = nil)
        }
    }

    func testLinkingObjectsDynamicGet() {
        let fido = SwiftDogObject()
        let owner = SwiftOwnerObject()
        owner.dog = fido
        owner.name = "JP"
        let realm = try! Realm()
        try! realm.write {
            realm.add([fido, owner])
        }

        // Get the linking objects property via subscript.
        let dynamicOwners = fido["owners"]
        guard let owners = dynamicOwners else {
            XCTFail("Got an unexpected nil for fido[\"owners\"]")
            return
        }
        XCTAssertTrue(owners is LinkingObjects<SwiftOwnerObject>)
        // Make sure the results actually functions.
        guard let firstOwner = (owners as? LinkingObjects<SwiftOwnerObject>)?.first else {
            XCTFail("Was not able to get first owner")
            return
        }
        XCTAssertEqual(firstOwner.name, "JP")
    }

    func testRenamedProperties() {
        let obj = SwiftRenamedProperties1()
        obj.propA = 5
        obj.propB = "a"

        let link = LinkToSwiftRenamedProperties1()
        link.linkA = obj
        link.array1.append(obj)
        link.set1.insert(obj)

        let realm = try! Realm()
        try! realm.write {
            realm.add(link)
        }

        XCTAssertEqual(obj.propA, 5)
        XCTAssertEqual(obj.propB, "a")
        XCTAssertTrue(link.linkA!.isSameObject(as: obj))
        XCTAssertTrue(link.array1[0].isSameObject(as: obj))
        XCTAssertTrue(link.set1.contains(obj))
        XCTAssertTrue(obj.linking1[0].isSameObject(as: link))

        XCTAssertEqual(obj["propA"]! as! Int, 5)
        XCTAssertEqual(obj["propB"]! as! String, "a")
        XCTAssertTrue((link["linkA"]! as! SwiftRenamedProperties1).isSameObject(as: obj))
        XCTAssertTrue((link["array1"]! as! List<SwiftRenamedProperties1>)[0].isSameObject(as: obj))
        XCTAssertTrue((link["set1"]! as! MutableSet<SwiftRenamedProperties1>).contains(obj))
        XCTAssertTrue((obj["linking1"]! as! LinkingObjects<LinkToSwiftRenamedProperties1>)[0].isSameObject(as: link))

        XCTAssertTrue(link.dynamicList("array1")[0].isSameObject(as: obj))
        XCTAssertTrue(link.dynamicMutableSet("set1")[0].isSameObject(as: obj))

        let obj2 = realm.objects(SwiftRenamedProperties2.self).first!
        let link2 = realm.objects(LinkToSwiftRenamedProperties2.self).first!

        XCTAssertEqual(obj2.propC, 5)
        XCTAssertEqual(obj2.propD, "a")
        XCTAssertTrue(link2.linkC!.isSameObject(as: obj))
        XCTAssertTrue(link2.array2[0].isSameObject(as: obj))
        XCTAssertTrue(link2.set2[0].isSameObject(as: obj))

        XCTAssertTrue(obj2.linking1[0].isSameObject(as: link))

        XCTAssertEqual(obj2["propC"]! as! Int, 5)
        XCTAssertEqual(obj2["propD"]! as! String, "a")
        XCTAssertTrue((link2["linkC"]! as! SwiftRenamedProperties1).isSameObject(as: obj))
        XCTAssertTrue((link2["array2"]! as! List<SwiftRenamedProperties2>)[0].isSameObject(as: obj))
        XCTAssertTrue((link2["set2"]! as! MutableSet<SwiftRenamedProperties2>)[0].isSameObject(as: obj))

        XCTAssertTrue((obj2["linking1"]! as! LinkingObjects<LinkToSwiftRenamedProperties1>)[0].isSameObject(as: link))

        XCTAssertTrue(link2.dynamicList("array2")[0].isSameObject(as: obj))
        XCTAssertTrue(link2.dynamicMutableSet("set2")[0].isSameObject(as: obj))
    }

    func testPropertiesOutlivingParentObject() {
        var optional: RealmOptional<Int>!
        var realmProperty: RealmProperty<Int?>!
        var list: List<Int>!
        var set: MutableSet<Int>!
        let realm = try! Realm()
        try! realm.write {
            autoreleasepool {
                let optObject = realm.create(SwiftOptionalObject.self, value: ["optIntCol": 1, "otherIntCol": 1])
                optional = optObject.optIntCol
                realmProperty = optObject.otherIntCol
                list = realm.create(SwiftListObject.self, value: ["int": [1]]).int
                set = realm.create(SwiftMutableSetObject.self, value: ["int": [1]]).int
            }
        }

        // Verify that we can still read the correct value
        XCTAssertEqual(optional.value, 1)
        XCTAssertEqual(realmProperty.value, 1)
        XCTAssertEqual(list.count, 1)
        XCTAssertEqual(list[0], 1)
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set[0], 1)

        // Verify that we can modify the values via the standalone property objects and
        // have it properly update the parent
        try! realm.write {
            optional.value = 2
            realmProperty.value = 2
            list.append(2)
            set.insert(2)
        }

        XCTAssertEqual(optional.value, 2)
        XCTAssertEqual(realmProperty.value, 2)
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list[0], 1)
        XCTAssertEqual(list[1], 2)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set[0], 1)
        XCTAssertEqual(set[1], 2)

        autoreleasepool {
            XCTAssertEqual(realm.objects(SwiftOptionalObject.self).first!.optIntCol.value, 2)
            XCTAssertEqual(realm.objects(SwiftOptionalObject.self).first!.otherIntCol.value, 2)
            XCTAssertEqual(Array(realm.objects(SwiftListObject.self).first!.int), [1, 2])
            XCTAssertEqual(Array(realm.objects(SwiftMutableSetObject.self).first!.int), [1, 2])
        }

        try! realm.write {
            optional.value = nil
            realmProperty.value = nil
            list.removeAll()
            set.removeAll()
        }

        XCTAssertEqual(optional.value, nil)
        XCTAssertEqual(realmProperty.value, nil)
        XCTAssertEqual(list.count, 0)
        XCTAssertEqual(set.count, 0)

        autoreleasepool {
            XCTAssertEqual(realm.objects(SwiftOptionalObject.self).first!.optIntCol.value, nil)
            XCTAssertEqual(realm.objects(SwiftOptionalObject.self).first!.otherIntCol.value, nil)
            XCTAssertEqual(Array(realm.objects(SwiftListObject.self).first!.int), [])
            XCTAssertEqual(Array(realm.objects(SwiftMutableSetObject.self).first!.int), [])
        }
    }

    func testSetEmbeddedLink() {
        let realm = try! Realm()
        realm.beginWrite()

        let parent = EmbeddedParentObject()
        realm.add(parent)

        let child1 = EmbeddedTreeObject1()
        parent.object = child1
        XCTAssertEqual(child1.realm, realm)
        XCTAssertNoThrow(parent.object = child1)

        let child2 = EmbeddedTreeObject1()
        parent.object = child2
        XCTAssertEqual(child1.realm, realm)
        XCTAssertTrue(child1.isInvalidated)

        let child3 = EmbeddedTreeObject1()
        parent.array.append(child3)
        assertThrows(parent.object = child3,
                     reason: "Can't set link to existing managed embedded object")
    }
}
