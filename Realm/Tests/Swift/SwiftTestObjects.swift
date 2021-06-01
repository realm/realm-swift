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

#if canImport(RealmTestSupport)
import RealmTestSupport
#endif

class SwiftRLMStringObject: RLMObject {
    @objc dynamic var stringCol = ""
}

class SwiftRLMBoolObject: RLMObject {
    @objc dynamic var boolCol = false
}

class SwiftRLMIntObject: RLMObject {
    @objc dynamic var intCol = 0
}

class SwiftRLMLongObject: RLMObject {
    @objc dynamic var longCol: Int64 = 0
}

class SwiftRLMObject: RLMObject {
    @objc dynamic var boolCol = false
    @objc dynamic var intCol = 123
    @objc dynamic var floatCol = 1.23 as Float
    @objc dynamic var doubleCol = 12.3
    @objc dynamic var stringCol = "a"
    @objc dynamic var binaryCol = "a".data(using: String.Encoding.utf8)
    @objc dynamic var dateCol = Date(timeIntervalSince1970: 1)
    @objc dynamic var objectCol = SwiftRLMBoolObject()
    @objc dynamic var arrayCol = RLMArray<SwiftRLMBoolObject>(objectClassName: SwiftRLMBoolObject.className())
    @objc dynamic var setCol = RLMSet<SwiftRLMBoolObject>(objectClassName: SwiftRLMBoolObject.className())
    @objc dynamic var uuidCol = UUID(uuidString: "00000000-0000-0000-0000-000000000000")
    @objc dynamic var rlmValue: RLMValue = "A Mixed Object" as NSString
}

class SwiftRLMOptionalObject: RLMObject {
    @objc dynamic var optStringCol: String?
    @objc dynamic var optNSStringCol: NSString?
    @objc dynamic var optBinaryCol: Data?
    @objc dynamic var optDateCol: Date?
    @objc dynamic var optObjectCol: SwiftRLMBoolObject?
    @objc dynamic var uuidCol: UUID?
}

class SwiftRLMPrimitiveArrayObject: RLMObject {
    @objc dynamic var stringCol = RLMArray<NSString>(objectType: .string, optional: false)
    @objc dynamic var optStringCol = RLMArray<NSObject>(objectType: .string, optional: true)
    @objc dynamic var dataCol = RLMArray<NSData>(objectType: .data, optional: false)
    @objc dynamic var optDataCol = RLMArray<NSObject>(objectType: .data, optional: true)
    @objc dynamic var dateCol = RLMArray<NSDate>(objectType: .date, optional: false)
    @objc dynamic var optDateCol = RLMArray<NSObject>(objectType: .date, optional: true)
    @objc dynamic var uuidCol = RLMArray<NSUUID>(objectType: .UUID, optional: false)
    @objc dynamic var optUuidCol = RLMArray<NSObject>(objectType: .UUID, optional: true)
}

class SwiftRLMPrimitiveSetObject: RLMObject {
    @objc dynamic var stringCol = RLMSet<NSString>(objectType: .string, optional: false)
    @objc dynamic var optStringCol = RLMSet<NSObject>(objectType: .string, optional: true)
    @objc dynamic var dataCol = RLMSet<NSData>(objectType: .data, optional: false)
    @objc dynamic var optDataCol = RLMSet<NSObject>(objectType: .data, optional: true)
    @objc dynamic var dateCol = RLMSet<NSDate>(objectType: .date, optional: false)
    @objc dynamic var optDateCol = RLMSet<NSObject>(objectType: .date, optional: true)
    @objc dynamic var uuidCol = RLMSet<NSUUID>(objectType: .UUID, optional: false)
    @objc dynamic var optUuidCol = RLMSet<NSObject>(objectType: .UUID, optional: true)
}

class SwiftRLMDogObject: RLMObject {
    @objc dynamic var dogName = ""
}

class SwiftRLMOwnerObject: RLMObject {
    @objc dynamic var name = ""
    @objc dynamic var dog: SwiftRLMDogObject? = SwiftRLMDogObject()
}

class SwiftRLMAggregateObject: RLMObject {
    @objc dynamic var intCol = 0
    @objc dynamic var floatCol = 0 as Float
    @objc dynamic var doubleCol = 0.0
    @objc dynamic var boolCol = false
    @objc dynamic var dateCol = Date()
}

class SwiftRLMAllIntSizesObject: RLMObject {
    @objc dynamic var int8: Int8  = 0
    @objc dynamic var int16: Int16 = 0
    @objc dynamic var int32: Int32 = 0
    @objc dynamic var int64: Int64 = 0
}

class SwiftRLMEmployeeObject: RLMObject {
    @objc dynamic var name = ""
    @objc dynamic var age = 0
    @objc dynamic var hired = false
}

class SwiftRLMCompanyObject: RLMObject {
    @objc dynamic var employees = RLMArray<SwiftRLMEmployeeObject>(objectClassName: SwiftRLMEmployeeObject.className())
    @objc dynamic var employeeSet = RLMSet<SwiftRLMEmployeeObject>(objectClassName: SwiftRLMEmployeeObject.className())
    @objc dynamic var employeeMap = RLMDictionary<NSString, SwiftRLMEmployeeObject>(objectClassName: SwiftRLMEmployeeObject.className(), keyType: .string)
}

class SwiftRLMAggregateSet: RLMObject {
    @objc dynamic var set = RLMSet<SwiftRLMAggregateObject>(objectClassName: SwiftRLMAggregateObject.className())
}

class SwiftRLMArrayPropertyObject: RLMObject {
    @objc dynamic var name = ""
    @objc dynamic var array = RLMArray<SwiftRLMStringObject>(objectClassName: SwiftRLMStringObject.className())
    @objc dynamic var intArray = RLMArray<SwiftRLMIntObject>(objectClassName: SwiftRLMIntObject.className())
}

class SwiftRLMSetPropertyObject: RLMObject {
    @objc dynamic var name = ""
    @objc dynamic var set = RLMSet<SwiftRLMStringObject>(objectClassName: SwiftRLMStringObject.className())
    @objc dynamic var intSet = RLMSet<SwiftRLMIntObject>(objectClassName: SwiftRLMIntObject.className())
}

class SwiftRLMDictionaryPropertyObject: RLMObject {
    @objc dynamic var dict = RLMDictionary<NSString, SwiftRLMAggregateObject>(objectClassName: SwiftRLMAggregateObject.className(), keyType: .string)
}

class SwiftRLMDictionaryEmployeeObject: RLMObject {
    @objc dynamic var dict = RLMDictionary<NSString, SwiftRLMEmployeeObject>(objectClassName: SwiftRLMEmployeeObject.className(), keyType: .string)
}

class SwiftRLMDynamicObject: RLMObject {
    @objc dynamic var stringCol = "a"
    @objc dynamic var intCol = 0
}

class SwiftRLMUTF8Object: RLMObject {
    @objc dynamic var 柱колоéнǢкƱаم👍 = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
}

class SwiftRLMIgnoredPropertiesObject: RLMObject {
    @objc dynamic var name = ""
    @objc dynamic var age = 0
    @objc dynamic var runtimeProperty: AnyObject?
    @objc dynamic var readOnlyProperty: Int { return 0 }

    override class func ignoredProperties() -> [String]? {
        return ["runtimeProperty"]
    }
}

class SwiftRLMPrimaryStringObject: RLMObject {
    @objc dynamic var stringCol = ""
    @objc dynamic var intCol = 0

    override class func primaryKey() -> String {
        return "stringCol"
    }
}

class SwiftRLMLinkSourceObject: RLMObject {
    @objc dynamic var id = 0
    @objc dynamic var link: SwiftRLMLinkTargetObject?
}

class SwiftRLMLinkTargetObject: RLMObject {
    @objc dynamic var id = 0
    @objc dynamic var backlinks: RLMLinkingObjects<SwiftRLMLinkSourceObject>?

    override class func linkingObjectsProperties() -> [String : RLMPropertyDescriptor] {
        return ["backlinks": RLMPropertyDescriptor(with: SwiftRLMLinkSourceObject.self, propertyName: "link")]
    }
}

class SwiftRLMLazyVarObject: RLMObject {
    @objc dynamic lazy var lazyProperty: String = "hello world"
}

class SwiftRLMIgnoredLazyVarObject: RLMObject {
    @objc dynamic var id = 0
    @objc dynamic lazy var ignoredVar: String = "hello world"
    override class func ignoredProperties() -> [String] { return ["ignoredVar"] }
}

class SwiftRLMObjectiveCTypesObject: RLMObject {
    @objc dynamic var stringCol: NSString?
    @objc dynamic var dateCol: NSDate?
    @objc dynamic var dataCol: NSData?
    @objc dynamic var numCol: NSNumber? = 0
}
