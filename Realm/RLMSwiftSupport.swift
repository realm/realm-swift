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

@objc class RLMSwiftSupport {
    class func convertSwiftPropertiesToObjC(swiftClass: AnyClass) {
        let swiftObject = (swiftClass as RLMObject.Type)()

        let reflection = reflect(swiftObject)

        let propertyCount = reflection.count

        let ignoredPropertiesForClass = swiftClass.ignoredProperties() as NSArray?

        for i in 1..propertyCount {
            // Skip the first property (super):
            // super is an implicit property on Swift objects
            let propertyName = reflection[i].0

            if ignoredPropertiesForClass != nil &&
                ignoredPropertiesForClass!.containsObject(propertyName) {
                continue
            }

            var typeEncoding = encodingForValueType(reflection[i].1.valueType)

            let attr = objc_property_attribute_t(name: "T", value: typeEncoding)
            class_addProperty(swiftClass, propertyName.bridgeToObjectiveC().UTF8String, [attr], 1)
        }
    }

    class func encodingForValueType(type: Any.Type) -> CString {
        switch type {
        // Detect basic types (including optional versions)
        case is Bool.Type, is Bool?.Type:
            return "c"
        case is Int.Type, is Int?.Type:
            return "i"
        case is Float.Type, is Float?.Type:
            return "f"
        case is Double.Type, is Double?.Type:
            return "d"
        case is String.Type, is String?.Type:
            return "S"

        // Detect Objective-C object types
        case let c as NSObject.Type:
            return "@\"\(NSStringFromClass(c.self))\"".bridgeToObjectiveC().UTF8String

        default:
            println("Other type")
            return ""
        }
    }
}
