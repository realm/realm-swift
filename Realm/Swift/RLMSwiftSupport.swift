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

@objc public class RLMSwiftSupport {

    public class func isSwiftClassName(className: NSString) -> Bool {
        return className.rangeOfString(".").location != NSNotFound
    }

    public class func demangleClassName(className: NSString) -> NSString {
        return className.substringFromIndex(className.rangeOfString(".").location + 1)
    }

    public class func propertiesForClass(aClass: AnyClass) -> [RLMProperty] {
        let className = demangleClassName(NSStringFromClass(aClass))

        let swiftObject = (aClass as RLMObject.Type)()
        let reflection = reflect(swiftObject)
        let ignoredPropertiesForClass = (aClass.ignoredProperties() ?? []) as NSArray

        var properties = [RLMProperty]()

        // Skip the first property (super):
        // super is an implicit property on Swift objects
        for i in 1..<reflection.count {
            let propertyName = reflection[i].0
            if ignoredPropertiesForClass.containsObject(propertyName) {
                continue
            }

            let objcType = objcTypeForSwiftType(propertyName, mirror: reflection[i].1)
            let objcTypeStr = objcType.cStringUsingEncoding(NSUTF8StringEncoding)
            let attrType = "T".cStringUsingEncoding(NSUTF8StringEncoding)
            var attr = objc_property_attribute_t(name: attrType!, value: objcTypeStr!)
            let prop = RLMProperty(name: propertyName,
                attributes: aClass.attributesForProperty(propertyName),
                attributeList: &attr, attributeCount: 1)

            properties.append(prop)
        }

        return properties
    }

    class func objcTypeForSwiftType(name: String, mirror: MirrorType) -> String {
        let valueType = mirror.valueType
        switch valueType {
            // Detect basic types (including optional versions)
            // https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
        case is Bool.Type, is Bool?.Type:
            return "c"
        case is Int.Type, is Int?.Type:
            return "l"
        case is Int16.Type, is Int16?.Type:
            return "s"
        case is Int32.Type, is Int32?.Type:
            return "i"
        case is Int64.Type, is Int64?.Type:
            return "q"
        case is Float.Type, is Float?.Type:
            return "f"
        case is Double.Type, is Double?.Type:
            return "d"
        case is String.Type, is String?.Type:
            return "@\"NSString\""
        case is NSData.Type, is NSData?.Type:
            return "@\"NSData\""
        case is NSDate.Type, is NSDate?.Type:
            return "@\"NSDate\""
        case let objectType as RLMObject.Type:
            return "@\"\(NSStringFromClass(objectType.self))\""
        case is RLMArray.Type:
            return "@\"RLMArray<\((mirror.value as RLMArray).objectClassName)>\""
        default:
            println("Can't persist property '\(name)' with incompatible type.\nAdd to ignoredPropertyNames: method to ignore.")
            abort()
        }
    }
}
