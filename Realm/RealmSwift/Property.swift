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

// MARK: Equatable

//public func ==(lhs: Property, rhs: Property) -> Bool {
//    return lhs.rlmProperty.isEqualToProperty(rhs.rlmProperty)
//}

//public class Property: Equatable {
public class Property {
    // MARK: Properties

    var rlmProperty: RLMProperty
    public var name: String { return rlmProperty.name }
    public var type: PropertyType { return rlmProperty.type }
    public var indexed: Bool { return rlmProperty.indexed }
    public var objectClassName: String { return rlmProperty.objectClassName }

    // MARK: Initializers

    init(rlmProperty: RLMProperty) {
        self.rlmProperty = rlmProperty
    }
}
