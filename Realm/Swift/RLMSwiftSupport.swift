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

    public class func schemaForObjectClass(aClass: AnyClass) -> RLMObjectSchema {
        let className = demangleClassName(NSStringFromClass(aClass))

        let swiftObject = (aClass as RLMObject.Type)()
        let reflection = reflect(swiftObject)
        let ignoredPropertiesForClass = aClass.ignoredProperties() as NSArray?

        var properties = [RLMProperty]()

        // Skip the first property (super):
        // super is an implicit property on Swift objects
        for i in 1..<reflection.count {
            let propertyName = reflection[i].0
            if ignoredPropertiesForClass?.containsObject(propertyName) ?? false {
                continue
            }

            properties.append(createPropertyForClass(aClass,
                mirror: reflection[i].1,
                name: propertyName,
                attr: aClass.attributesForProperty(propertyName)))
        }

        return RLMObjectSchema(className: className as NSString?, objectClass: aClass, properties: properties)
    }

    class func createPropertyForClass(aClass: AnyClass,
        mirror: MirrorType,
        name: String,
        attr: RLMPropertyAttributes) -> RLMProperty {
            let valueType = mirror.valueType
            let (p, t) = { () -> (RLMProperty, String) in
                switch valueType {
                    // Detect basic types (including optional versions)
                case is Bool.Type, is Bool?.Type:
                    return (RLMProperty(name: name, type: .Bool, objectClassName: nil, attributes: attr), "c")
                case is Int.Type, is Int?.Type:
#if arch(x86_64) || arch(arm64)
                    let t = "l"
#else
                    let t = "i"
#endif
                    return (RLMProperty(name: name, type: .Int, objectClassName: nil, attributes: attr), t)
                case is Float.Type, is Float?.Type:
                    return (RLMProperty(name: name, type: .Float, objectClassName: nil, attributes: attr), "f")
                case is Double.Type, is Double?.Type:
                    return (RLMProperty(name: name, type: .Double, objectClassName: nil, attributes: attr), "d")
                case is String.Type, is String?.Type:
                    return (RLMProperty(name: name, type: .String, objectClassName: nil, attributes: attr), "S")
                case is NSData.Type, is NSData?.Type:
                    return (RLMProperty(name: name, type: .Data, objectClassName: nil, attributes: attr), "@\"NSData\"")
                case is NSDate.Type, is NSDate?.Type:
                    return (RLMProperty(name: name, type: .Date, objectClassName: nil, attributes: attr), "@\"NSDate\"")
                case let objectType as RLMObject.Type:
                    let mangledClassName = NSStringFromClass(objectType.self)
                    let objectClassName = self.demangleClassName(mangledClassName)
                    let typeEncoding = "@\"\(mangledClassName))\""
                    return (RLMProperty(name: name, type: .Object, objectClassName: objectClassName, attributes: attr), typeEncoding)
                case let c as RLMArray.Type:
                    let objectClassName = (mirror.value as RLMArray).objectClassName
                    return (RLMProperty(name: name, type: .Array, objectClassName: objectClassName, attributes: attr), "@\"RLMArray\"")
                default:
                    println("Can't persist property '\(name)' with incompatible type.\nAdd to ignoredPropertyNames: method to ignore.")
                    abort()
                }
            }()

            // create objc property
            let attr = objc_property_attribute_t(name: "T", value: t)
            class_addProperty(aClass, p.name, [attr], 1)
            return p
    }
}
