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
    var stringCol = ""
}

class SwiftBoolObject: RLMObject {
    var boolCol = false
}

class SwiftIntObject: RLMObject {
    var intCol = 0
}

class SwiftObject: RLMObject {
    var boolCol = false
    var intCol = 123
    var floatCol = 1.23 as Float
    var doubleCol = 12.3
    var stringCol = "a"
    var binaryCol = "a".dataUsingEncoding(NSUTF8StringEncoding)
    var dateCol = NSDate(timeIntervalSince1970: 1)
    var objectCol = SwiftBoolObject()
    var arrayCol = RLMArray(objectClassName: SwiftBoolObject.className())
}

class SwiftDogObject: RLMObject {
    var dogName = ""
}

class SwiftOwnerObject: RLMObject {
    var name = ""
    var dog = SwiftDogObject()
}

class SwiftAggregateObject: RLMObject {
    var intCol = 0
    var floatCol = 0 as Float
    var doubleCol = 0.0
    var boolCol = false
    var dateCol = NSDate()
}

class SwiftEmployeeObject: RLMObject {
    var name = ""
    var age = 0
    var hired = false
}

class SwiftCompanyObject: RLMObject {
    var employees = RLMArray(objectClassName: SwiftEmployeeObject.className())
}

class SwiftArrayPropertyObject: RLMObject {
    var name = ""
    var array = RLMArray(objectClassName: SwiftStringObject.className())
    var intArray = RLMArray(objectClassName: SwiftIntObject.className())
}
