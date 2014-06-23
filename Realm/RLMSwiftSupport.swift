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

@objc class RLMSwiftObjectSchema {
    class func convertSwiftPropertiesToObjC(swiftClass: AnyClass) {
        // get ivars (Swift properties behave like ObjC ivars)
        var ivarCount: CUnsignedInt = 0
        let ivars = class_copyIvarList(swiftClass, &ivarCount)

        let ignoredPropertiesForClass = swiftClass.ignoredProperties() as NSArray?

        for i in 0..ivarCount {
            let ivarName = "\(ivar_getName(ivars[Int(i)]))"

            if ignoredPropertiesForClass != nil &&
                ignoredPropertiesForClass!.containsObject(ivarName) {
                continue
            }

            var typeEncoding: CString = "c"

            let attr = objc_property_attribute_t(name: "T", value: typeEncoding)
            class_addProperty(swiftClass, ivarName.bridgeToObjectiveC().UTF8String, [attr], 1)
        }
    }
}
