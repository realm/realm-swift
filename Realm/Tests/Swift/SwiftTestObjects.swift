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

class SwiftStringObject: RealmObject {
    var stringCol = ""
}

class SwiftBoolObject: RealmObject {
    var boolCol = false
}

class SwiftIntObject: RealmObject {
    var intCol = 0
}

class SwiftObject: RealmObject {
    var boolCol = false
    var intCol = 123
    var floatCol = 1.23 as Float
    var doubleCol = 12.3
    var stringCol = "a"
    var binaryCol = "a".dataUsingEncoding(NSUTF8StringEncoding)
    var dateCol = NSDate(timeIntervalSince1970: 1)
    var objectCol = SwiftBoolObject()
    var arrayCol = RealmArray<SwiftBoolObject>().property
}

class SwiftOptionalObject: RealmObject {
    // FIXME: Support all optional property types
//    var optBoolCol: Bool?
//    var optIntCol: Int?
//    var optFloatCol: Float?
//    var optDoubleCol: Double?
    var optStringCol: String?
    var optBinaryCol: NSData?
    var optDateCol: NSDate?
//    var optObjectCol: SwiftBoolObject?
//    var arrayCol = RLMArray(objectClassName: SwiftBoolObject.className())
}

class SwiftDogObject: RealmObject {
    var dogName = ""
}

class SwiftOwnerObject: RealmObject {
    var name = ""
    var dog = SwiftDogObject()
}

class SwiftAggregateObject: RealmObject {
    var intCol = 0
    var floatCol = 0 as Float
    var doubleCol = 0.0
    var boolCol = false
    var dateCol = NSDate()
}

class SwiftEmployeeObject: RealmObject {
    var name = ""
    var age = 0
    var hired = false
}

class SwiftCompanyObject: RealmObject {
    var employees = RealmArray<SwiftEmployeeObject>().property
}

class SwiftArrayPropertyObject: RealmObject {
    var name = ""
    var array = RealmArray<SwiftStringObject>().property
    var intArray = RealmArray<SwiftIntObject>().property
}

class SwiftDynamicObject: RealmObject {
    var stringCol = "a"
    var intCol = 0
}

class SwiftUTF8Object: RLMObject {
    var 柱колоéнǢкƱаم👍 = "值значен™👍☞⎠‱௹♣︎☐▼❒∑⨌⧭иеمرحبا"
}
