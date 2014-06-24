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

// Swift enumeration

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

// Swift & Objective-C class parsing

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

    // Swift property utilities
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

    // Swift class parsing
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
}
