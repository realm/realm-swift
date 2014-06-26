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

extension RLMArray: Sequence {

    func generate() -> GeneratorOf<RLMObject> {
        var i  = 0
        return GeneratorOf<RLMObject>({
            if (i >= self.count) {
                return .None
            } else {
                return self[i++] as? RLMObject
            }
        })
    }
}

@objc class ParsedClass {
    var swift = false
    var name: String

    var moduleName: String?
    var mangledName: String?

    init(swift: Bool, name: String, moduleName: String?, mangledName: String?) {
        self.swift = swift
        self.name = name
        self.moduleName = moduleName
        self.mangledName = mangledName
    }
}

extension String {
    subscript (r: Range<Int>) -> String {
        get {
            let startIndex = advance(self.startIndex, r.startIndex)
            let endIndex = advance(startIndex, r.endIndex)

            return self[Range(start: startIndex, end: endIndex)]
        }
    }
}

@objc class RLMSwiftSupport {

    class func isSwiftClassName(className: NSString) -> Bool {
        return className.rangeOfString("^_T\\w{2}\\d+\\w+$", options: .RegularExpressionSearch).location != NSNotFound
    }

    class func parseClass(aClass: AnyClass) -> ParsedClass {
        // Swift mangling details found here: http://www.eswick.com/2014/06/inside-swift
        // Swift class names look like _TFC9swifttest5Shape
        // Format: _T{2 characters}{module length}{module}{class length}{class}

        let originalName = NSStringFromClass(aClass)

        if !isSwiftClassName(originalName) {
            return ParsedClass(swift: false,
                name: originalName,
                moduleName: nil,
                mangledName: nil)
        }

        let originalNameLength = originalName.utf16count
        var cursor = 4
        var substring = originalName[cursor..originalNameLength-cursor]

        // Module
        let moduleLength = substring.bridgeToObjectiveC().integerValue
        let moduleLengthLength = "\(moduleLength)".utf16count
        let moduleName = substring[moduleLengthLength..moduleLength]

        // Update cursor and substring
        cursor += moduleLengthLength + moduleName.utf16count
        substring = originalName[cursor..originalNameLength-cursor]

        // Class name
        let classLength = substring.bridgeToObjectiveC().integerValue
        let classLengthLength = "\(classLength)".utf16count
        let className = substring[classLengthLength..classLength]

        return ParsedClass(swift: true,
            name: className,
            moduleName: moduleName,
            mangledName: originalName)
    }

    class func schemaForObjectClass(aClass: AnyClass) -> RLMObjectSchema {
        let parsedClass = parseClass(aClass)

        if !parsedClass.swift {
            return RLMObjectSchema(forObjectClass: aClass)
        }

        RLMSchema.mangledClassMap()[parsedClass.name] = parsedClass.mangledName

        let swiftObject = (aClass as RLMObject.Type)()

        let reflection = reflect(swiftObject)

        let ignoredPropertiesForClass = aClass.ignoredProperties() as NSArray?

        var propArray = RLMProperty[]()

        for i in 1..reflection.count {
            // Skip the first property (super):
            // super is an implicit property on Swift objects
            let propertyName = reflection[i].0

            if ignoredPropertiesForClass != nil &&
                ignoredPropertiesForClass!.containsObject(propertyName) {
                    continue
            }

            let realmAttributes = aClass.attributesForProperty(propertyName)

            let (property, typeEncoding) = propertyForValueType(reflection[i].1.valueType,
                name: propertyName,
                attributes: realmAttributes, column: propArray.count)

            propArray += property

            let attr = objc_property_attribute_t(name: "T", value: typeEncoding)
            class_addProperty(aClass, propertyName.bridgeToObjectiveC().UTF8String, [attr], 1)
        }

        let schema = RLMObjectSchema()
        schema.properties = propArray
        schema.className = parsedClass.name
        return schema
    }

    class func propertyForValueType(valueType: Any.Type, name: String, attributes: RLMPropertyAttributes, column: Int) -> (RLMProperty, CString) {
        var propertyType: RLMPropertyType?
        var encoding: CString?
        var objectClassName: String?

        switch valueType {
            // Detect basic types (including optional versions)
        case is Bool.Type, is Bool?.Type:
            (propertyType, encoding) = (RLMPropertyType.Bool, "c")
        case is Int.Type, is Int?.Type:
            (propertyType, encoding) = (RLMPropertyType.Int, "i")
        case is Float.Type, is Float?.Type:
            (propertyType, encoding) = (RLMPropertyType.Float, "f")
        case is Double.Type, is Double?.Type:
            (propertyType, encoding) = (RLMPropertyType.Double, "d")
        case is String.Type, is String?.Type:
            (propertyType, encoding) = (RLMPropertyType.String, "S")
        case is NSData.Type, is NSData?.Type:
            (propertyType, encoding) = (RLMPropertyType.Data, "@\"NSData\"")
        case is NSDate.Type, is NSDate?.Type:
            (propertyType, encoding) = (RLMPropertyType.Date, "@\"NSDate\"")

            // Detect Objective-C object types
        case let c as RLMObject.Type:
            let parsedClass = RLMSwiftSupport.parseClass(c.self)
            if parsedClass.swift {
                // Mangled class map must contain this property's class
                // for Realm to create the proper table
                let mapMissingName = !RLMSchema.mangledClassMap().allKeys.bridgeToObjectiveC().containsObject(parsedClass.name)
                if mapMissingName {
                    RLMSchema.mangledClassMap()[parsedClass.name] = parsedClass.mangledName
                }
            }
            objectClassName = parsedClass.name
            let typeEncoding = "@\"\(NSStringFromClass(c.self))\"".bridgeToObjectiveC().UTF8String
            (propertyType, encoding) = (RLMPropertyType.Object, typeEncoding)
            
        default:
            println("Can't persist property '\(name)' with incompatible type.\nAdd to ignoredPropertyNames: method to ignore.")
            assert(false)
        }

        let prop = RLMProperty(name: name, type: propertyType!, column: column)
        prop.attributes = attributes
        prop.objectClassName = objectClassName
        return (prop, encoding!)
    }

//            else if ([type hasPrefix:arrayPrefix]) {
//                // get object class from type string - @"RLMArray<objectClassName>"
//                _objectClassName = [type substringWithRange:NSMakeRange(arrayPrefix.length, type.length-arrayPrefix.length-2)];
//                _type = RLMPropertyTypeArray;
//                
//                // verify type
//                Class cls = RLMClassFromString(self.objectClassName);
//                if (class_getSuperclass(cls) != RLMObject.class) {
//                    @throw [NSException exceptionWithName:@"RLMException"
//                                                   reason:[NSString stringWithFormat:@"Property of type '%@' must descend from RLMObject", self.objectClassName]
//                                                 userInfo:nil];
//                }
//            }

}
