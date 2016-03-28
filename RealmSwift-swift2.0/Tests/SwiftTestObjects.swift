////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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

import Foundation
import RealmSwift
import Realm

class SwiftStringObject: Object {
    dynamic var stringCol = ""
}

class SwiftBoolObject: Object {
    dynamic var boolCol = false
}

class SwiftIntObject: Object {
    dynamic var intCol = 0
}

class SwiftLongObject: Object {
    dynamic var longCol: Int64 = 0
}

class SwiftObject: Object {
    dynamic var boolCol = false
    dynamic var intCol = 123
    dynamic var floatCol = 1.23 as Float
    dynamic var doubleCol = 12.3
    dynamic var stringCol = "a"
    dynamic var binaryCol = "a".dataUsingEncoding(NSUTF8StringEncoding)!
    dynamic var dateCol = NSDate(timeIntervalSince1970: 1)
    dynamic var objectCol: SwiftBoolObject? = SwiftBoolObject()
    let arrayCol = List<SwiftBoolObject>()

    class func defaultValues() -> [String: AnyObject] {
        return  ["boolCol": false as AnyObject,
            "intCol": 123 as AnyObject,
            "floatCol": 1.23 as AnyObject,
            "doubleCol": 12.3 as AnyObject,
            "stringCol": "a" as AnyObject,
            "binaryCol":  "a".dataUsingEncoding(NSUTF8StringEncoding)! as NSData,
            "dateCol": NSDate(timeIntervalSince1970: 1) as NSDate,
            "objectCol": [false],
            "arrayCol": [] as NSArray]
    }
}

class SwiftOptionalObject: Object {
    dynamic var optNSStringCol: NSString?
    dynamic var optStringCol: String?
    dynamic var optBinaryCol: NSData?
    dynamic var optDateCol: NSDate?
    let optIntCol = RealmOptional<Int>()
    let optInt8Col = RealmOptional<Int8>()
    let optInt16Col = RealmOptional<Int16>()
    let optInt32Col = RealmOptional<Int32>()
    let optInt64Col = RealmOptional<Int64>()
    let optFloatCol = RealmOptional<Float>()
    let optDoubleCol = RealmOptional<Double>()
    let optBoolCol = RealmOptional<Bool>()
    dynamic var optObjectCol: SwiftBoolObject?
    //    let arrayCol = List<SwiftBoolObject?>()
}

class SwiftImplicitlyUnwrappedOptionalObject: Object {
    dynamic var optNSStringCol: NSString!
    dynamic var optStringCol: String!
    dynamic var optBinaryCol: NSData!
    dynamic var optDateCol: NSDate!
    dynamic var optObjectCol: SwiftBoolObject!
    //    let arrayCol = List<SwiftBoolObject!>()
}

class SwiftOptionalDefaultValuesObject: Object {
    dynamic var optNSStringCol: NSString? = "A"
    dynamic var optStringCol: String? = "B"
    dynamic var optBinaryCol: NSData? = "C".dataUsingEncoding(NSUTF8StringEncoding)
    dynamic var optDateCol: NSDate? = NSDate(timeIntervalSince1970: 10)
    let optIntCol = RealmOptional<Int>(1)
    let optInt8Col = RealmOptional<Int8>(1)
    let optInt16Col = RealmOptional<Int16>(1)
    let optInt32Col = RealmOptional<Int32>(1)
    let optInt64Col = RealmOptional<Int64>(1)
    let optFloatCol = RealmOptional<Float>(2.2)
    let optDoubleCol = RealmOptional<Double>(3.3)
    let optBoolCol = RealmOptional<Bool>(true)
    dynamic var optObjectCol: SwiftBoolObject? = SwiftBoolObject(value: [true])
    //    let arrayCol = List<SwiftBoolObject?>()

    class func defaultValues() -> [String: AnyObject] {
        return [
            "optNSStringCol" : "A",
            "optStringCol" : "B",
            "optBinaryCol" : "C".dataUsingEncoding(NSUTF8StringEncoding)! as NSData,
            "optDateCol" : NSDate(timeIntervalSince1970: 10),
            "optIntCol" : 1,
            "optInt8Col" : 1,
            "optInt16Col" : 1,
            "optInt32Col" : 1,
            "optInt64Col" : 1,
            "optFloatCol" : 2.2 as Float,
            "optDoubleCol" : 3.3,
            "optBoolCol" : true,
        ]
    }
}

class SwiftOptionalIgnoredPropertiesObject: Object {
    dynamic var optNSStringCol: NSString? = "A"
    dynamic var optStringCol: String? = "B"
    dynamic var optBinaryCol: NSData? = "C".dataUsingEncoding(NSUTF8StringEncoding)
    dynamic var optDateCol: NSDate? = NSDate(timeIntervalSince1970: 10)
    dynamic var optObjectCol: SwiftBoolObject? = SwiftBoolObject(value: [true])

    override class func ignoredProperties() -> [String] {
        return [
            "optNSStringCol",
            "optStringCol",
            "optBinaryCol",
            "optDateCol",
            "optObjectCol"
        ]
    }
}



class SwiftDogObject: Object {
    dynamic var dogName = ""
}

class SwiftOwnerObject: Object {
    dynamic var name = ""
    dynamic var dog: SwiftDogObject? = SwiftDogObject()
}

class SwiftAggregateObject: Object {
    dynamic var intCol = 0
    dynamic var floatCol = 0 as Float
    dynamic var doubleCol = 0.0
    dynamic var boolCol = false
    dynamic var dateCol = NSDate()
    dynamic var trueCol = true
    let stringListCol = List<SwiftStringObject>()
}

class SwiftAllIntSizesObject: Object {
    dynamic var int8: Int8  = 0
    dynamic var int16: Int16 = 0
    dynamic var int32: Int32 = 0
    dynamic var int64: Int64 = 0
}

class SwiftEmployeeObject: Object {
    dynamic var name = ""
    dynamic var age = 0
    dynamic var hired = false
}

class SwiftCompanyObject: Object {
    let employees = List<SwiftEmployeeObject>()
}

class SwiftArrayPropertyObject: Object {
    dynamic var name = ""
    let array = List<SwiftStringObject>()
    let intArray = List<SwiftIntObject>()
}

class SwiftDoubleListOfSwiftObject: Object {
    let array = List<SwiftListOfSwiftObject>()
}

class SwiftListOfSwiftObject: Object {
    let array = List<SwiftObject>()
}

class SwiftArrayPropertySubclassObject: SwiftArrayPropertyObject {
    let boolArray = List<SwiftBoolObject>()
}

class SwiftLinkToPrimaryStringObject: Object {
    // swiftlint:disable:next variable_name
    dynamic var pk = ""
    dynamic var object: SwiftPrimaryStringObject?
    let objects = List<SwiftPrimaryStringObject>()

    override class func primaryKey() -> String? {
        return "pk"
    }
}

class SwiftUTF8Object: Object {
    // swiftlint:disable:next variable_name
    dynamic var 柱колоéнǢкƱаم👍 = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
}

class SwiftIgnoredPropertiesObject: Object {
    dynamic var name = ""
    dynamic var age = 0
    dynamic var runtimeProperty: AnyObject?
    dynamic var runtimeDefaultProperty = "property"
    dynamic var readOnlyProperty: Int { return 0 }

    override class func ignoredProperties() -> [String] {
        return ["runtimeProperty", "runtimeDefaultProperty"]
    }
}

class SwiftRecursiveObject: Object {
    let objects = List<SwiftRecursiveObject>()
}

class SwiftPrimaryStringObject: Object {
    dynamic var stringCol = ""
    dynamic var intCol = 0

    override class func primaryKey() -> String? {
        return "stringCol"
    }
}

class SwiftIndexedPropertiesObject: Object {
    dynamic var stringCol = ""
    dynamic var intCol = 0
    dynamic var int8Col: Int8 = 0
    dynamic var int16Col: Int16 = 0
    dynamic var int32Col: Int32 = 0
    dynamic var int64Col: Int64 = 0
    dynamic var boolCol = false
    dynamic var dateCol = NSDate()

    dynamic var floatCol: Float = 0.0
    dynamic var doubleCol: Double = 0.0
    dynamic var dataCol = NSData()

    override class func indexedProperties() -> [String] {
        return ["stringCol", "intCol", "int8Col", "int16Col", "int32Col", "int64Col", "boolCol", "dateCol"]
    }
}

class SwiftIndexedOptinalPropertiesObject: Object {
    dynamic var optionalStringCol: String? = ""
    let optionalIntCol = RealmOptional<Int>()
    let optionalInt8Col = RealmOptional<Int8>()
    let optionalInt16Col = RealmOptional<Int16>()
    let optionalInt32Col = RealmOptional<Int32>()
    let optionalInt64Col = RealmOptional<Int64>()
    let optionalBoolCol = RealmOptional<Bool>()
    dynamic var optionalDateCol: NSDate? = NSDate()

    let optionalFloatCol = RealmOptional<Float>()
    let optionalDoubleCol = RealmOptional<Double>()
    dynamic var optionalDataCol: NSData? = NSData()

    override class func indexedProperties() -> [String] {
        return ["optionalStringCol", "optionalIntCol", "optionalInt8Col", "optionalInt16Col",
            "optionalInt32Col", "optionalInt64Col", "optionalBoolCol", "optionalDateCol"]
    }
}

class SwiftCustomInitializerObject: Object {
    dynamic var stringCol: String

    init(stringVal: String) {
        stringCol = stringVal
        super.init()
    }

    required init() {
        stringCol = ""
        super.init()
    }

    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        stringCol = ""
        super.init(realm: realm, schema: schema)
    }

    required init(value: AnyObject, schema: RLMSchema) {
        stringCol = ""
        super.init(value: value, schema: schema)
    }
}

class SwiftConvenienceInitializerObject: Object {
    dynamic var stringCol = ""

    convenience init(stringCol: String) {
        self.init()
        self.stringCol = stringCol
    }
}
