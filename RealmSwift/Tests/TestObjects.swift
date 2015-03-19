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

class StringObject: Object {
    dynamic var stringCol = ""
}

class BoolObject: Object {
    dynamic var boolCol = false
}

class IntObject: Object {
    dynamic var intCol = 0
}

class AllTypesObject: Object {
    dynamic var boolCol = false
    dynamic var intCol = 123
    dynamic var floatCol = 1.23 as Float
    dynamic var doubleCol = 12.3
    dynamic var stringCol = "a"
    dynamic var binaryCol = "a".dataUsingEncoding(NSUTF8StringEncoding)!
    dynamic var dateCol = NSDate(timeIntervalSince1970: 1)
    dynamic var objectCol = BoolObject()
    let arrayCol = List<BoolObject>()

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

class OptionalObject: Object {
    // FIXME: Support all optional property types
//    dynamic var optBoolCol: Bool?
//    dynamic var optIntCol: Int?
//    dynamic var optFloatCol: Float?
//    dynamic var optDoubleCol: Double?
//    dynamic var optStringCol: String?
//    dynamic var optBinaryCol: NSData?
//    dynamic var optDateCol: NSDate?
    dynamic var optObjectCol: BoolObject?
//    let arrayCol = List<BoolObject>()
}

class DogObject: Object {
    dynamic var dogName = ""
}

class OwnerObject: Object {
    dynamic var name = ""
    dynamic var dog = DogObject()
}

class AggregateObject: Object {
    dynamic var intCol = 0
    dynamic var floatCol = 0 as Float
    dynamic var doubleCol = 0.0
    dynamic var boolCol = false
    dynamic var dateCol = NSDate()
    dynamic var trueCol = true
}

class AllIntSizesObject: Object {
    dynamic var int16 : Int16 = 0
    dynamic var int32 : Int32 = 0
    dynamic var int64 : Int64 = 0
}

class EmployeeObject: Object {
    dynamic var name = ""
    dynamic var age = 0
    dynamic var hired = false
}

class CompanyObject: Object {
    let employees = List<EmployeeObject>()
}

class ArrayPropertyObject: Object {
    dynamic var name = ""
    let array = List<StringObject>()
    let intArray = List<IntObject>()
}

class ArrayPropertySubclassObject: ArrayPropertyObject {
    let boolArray = List<BoolObject>()
}

class UTF8Object: Object {
    dynamic var 柱колоéнǢкƱаم👍 = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
}

class IgnoredPropertiesObject: Object {
    dynamic var name = ""
    dynamic var age = 0
    dynamic var runtimeProperty: AnyObject?
    dynamic var runtimeDefaultProperty = "property"
    dynamic var readOnlyProperty: Int { return 0 }

    override class func ignoredProperties() -> [String] {
        return ["runtimeProperty", "runtimeDefaultProperty"]
    }
}

class LinkToPrimaryStringObject: Object {
    dynamic var pk = ""
    dynamic var object: PrimaryStringObject?
    let objects = List<PrimaryStringObject>()

    override class func primaryKey() -> String? {
        return "pk"
    }
}

class PrimaryStringObject: Object {
    dynamic var stringCol = ""
    dynamic var intCol = 0

    override class func primaryKey() -> String {
        return "stringCol"
    }
}

class IndexedPropertiesObject: Object {
    dynamic var stringCol = ""
    dynamic var intCol = 0

    override class func indexedProperties() -> [String] {
        return ["stringCol"] // Add "intCol" when integer indexing is supported
    }
}
