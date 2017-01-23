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

import Realm

class SwiftStringObject: RLMObject {
    dynamic var stringCol = ""
}

class SwiftBoolObject: RLMObject {
    dynamic var boolCol = false
}

class SwiftIntObject: RLMObject {
    dynamic var intCol = 0
}

class SwiftLongObject: RLMObject {
    dynamic var longCol: Int64 = 0
}

class SwiftObject: RLMObject {
    dynamic var boolCol = false
    dynamic var intCol = 123
    dynamic var floatCol = 1.23 as Float
    dynamic var doubleCol = 12.3
    dynamic var stringCol = "a"
    dynamic var binaryCol = "a".data(using: String.Encoding.utf8)
    dynamic var dateCol = Date(timeIntervalSince1970: 1)
    dynamic var objectCol = SwiftBoolObject()
    dynamic var arrayCol = RLMArray(objectClassName: SwiftBoolObject.className())
}

class SwiftOptionalObject: RLMObject {
    // FIXME: Support all optional property types
//    dynamic var optBoolCol: Bool?
//    dynamic var optIntCol: Int?
//    dynamic var optFloatCol: Float?
//    dynamic var optDoubleCol: Double?
    dynamic var optStringCol: String?
    dynamic var optNSStringCol: NSString?
    dynamic var optBinaryCol: Data?
    dynamic var optDateCol: Date?
    dynamic var optObjectCol: SwiftBoolObject?
}

class SwiftDogObject: RLMObject {
    dynamic var dogName = ""
}

class SwiftOwnerObject: RLMObject {
    dynamic var name = ""
    dynamic var dog: SwiftDogObject? = SwiftDogObject()
}

class SwiftAggregateObject: RLMObject {
    dynamic var intCol = 0
    dynamic var floatCol = 0 as Float
    dynamic var doubleCol = 0.0
    dynamic var boolCol = false
    dynamic var dateCol = Date()
}

class SwiftAllIntSizesObject: RLMObject {
    dynamic var int8  : Int8  = 0
    dynamic var int16 : Int16 = 0
    dynamic var int32 : Int32 = 0
    dynamic var int64 : Int64 = 0
}

class SwiftEmployeeObject: RLMObject {
    dynamic var name = ""
    dynamic var age = 0
    dynamic var hired = false
}

class SwiftCompanyObject: RLMObject {
    dynamic var employees = RLMArray(objectClassName: SwiftEmployeeObject.className())
}

class SwiftArrayPropertyObject: RLMObject {
    dynamic var name = ""
    dynamic var array = RLMArray(objectClassName: SwiftStringObject.className())
    dynamic var intArray = RLMArray(objectClassName: SwiftIntObject.className())
}

class SwiftDynamicObject: RLMObject {
    dynamic var stringCol = "a"
    dynamic var intCol = 0
}

class SwiftUTF8Object: RLMObject {
    dynamic var 柱колоéнǢкƱаم👍 = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
}

class SwiftIgnoredPropertiesObject: RLMObject {
    dynamic var name = ""
    dynamic var age = 0
    dynamic var runtimeProperty: AnyObject?
    dynamic var readOnlyProperty: Int { return 0 }

    override class func ignoredProperties() -> [String]? {
        return ["runtimeProperty"]
    }
}

class SwiftPrimaryStringObject: RLMObject {
    dynamic var stringCol = ""
    dynamic var intCol = 0

    override class func primaryKey() -> String {
        return "stringCol"
    }
}

class SwiftLinkSourceObject: RLMObject {
    dynamic var id = 0
    dynamic var link: SwiftLinkTargetObject?
}

class SwiftLinkTargetObject: RLMObject {
    dynamic var id = 0
    dynamic var backlinks: RLMLinkingObjects<SwiftLinkSourceObject>?

    override class func linkingObjectsProperties() -> [String : RLMPropertyDescriptor] {
        return ["backlinks": RLMPropertyDescriptor(with: SwiftLinkSourceObject.self, propertyName: "link")]
    }
}

class SwiftLazyVarObject : RLMObject {
    dynamic lazy var lazyProperty : String = "hello world"
}

class SwiftIgnoredLazyVarObject : RLMObject {
    dynamic var id = 0
    dynamic lazy var ignoredVar : String = "hello world"
    override class func ignoredProperties() -> [String] { return ["ignoredVar"] }
}

class SwiftObjectiveCTypesObject: RLMObject {
    dynamic var stringCol: NSString?
    dynamic var dateCol: NSDate?
    dynamic var dataCol: NSData?
    dynamic var numCol: NSNumber? = 0
}
