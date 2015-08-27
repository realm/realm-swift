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
#if REALM_ENABLE_NULL
    dynamic var optNSStringCol: NSString?
    dynamic var optStringCol: String?
    dynamic var optBinaryCol: NSData?
    dynamic var optDateCol: NSDate?
    let optIntCol = RealmOptional<Int>()
    let optFloatCol = RealmOptional<Float>()
    let optDoubleCol = RealmOptional<Double>()
    let optBoolCol = RealmOptional<Bool>()
#endif
    dynamic var optObjectCol: SwiftBoolObject?
    //    let arrayCol = List<SwiftBoolObject?>()
}

class SwiftImplicitlyUnwrappedOptionalObject: Object {
#if REALM_ENABLE_NULL
    dynamic var optNSStringCol: NSString!
    dynamic var optStringCol: String!
    dynamic var optBinaryCol: NSData!
    dynamic var optDateCol: NSDate!
#endif
    dynamic var optObjectCol: SwiftBoolObject!
    //    let arrayCol = List<SwiftBoolObject!>()
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
    dynamic var int8  : Int8  = 0
    dynamic var int16 : Int16 = 0
    dynamic var int32 : Int32 = 0
    dynamic var int64 : Int64 = 0
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

class SwiftUTF8Object: Object {
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

class SwiftLinkToPrimaryStringObject: Object {
    dynamic var pk = ""
    dynamic var object: SwiftPrimaryStringObject?
    let objects = List<SwiftPrimaryStringObject>()

    override class func primaryKey() -> String? {
        return "pk"
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

    override class func indexedProperties() -> [String] {
        return ["stringCol"] // Add "intCol" when integer indexing is supported
    }
}
