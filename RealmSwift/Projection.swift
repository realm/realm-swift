////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
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
import Realm
import Realm.Private

public enum ProjectionError: Error {
    case propertyNotFound(propertyName: String)
}

public enum ProjectedProperty {
    case asis(projectedName: String)
    case rename(projectedName: String, fromName: String)
    case keyPath(projectedName: String, keyPath: String)
}

@dynamicMemberLookup
open class RealmProjection<T: Object> {

    private let type: T.Type = T.self
    private let object: T
    private let associations: [ProjectedProperty]

    private var props: [String: Property] = [:]

    public convenience init(object: T) {
        self.init(object: object, associations: [])
        try! validate()
    }

    public init(object: T, associations: [ProjectedProperty]) {
        self.object = object
        self.associations = associations
        try! validate()
    }

    private func validate() throws {
//         no duplicates
        for association in associations {
            switch association {
            case .asis(let projectedName):
                guard let prop = property(projectedName) else {
                    throw ProjectionError.propertyNotFound(propertyName: projectedName)
                }
                props[projectedName] = prop
            case .rename(let projectedName, let fromName):
                guard let prop = property(fromName) else {
                    throw ProjectionError.propertyNotFound(propertyName: fromName)
                }
                props[projectedName] = prop
            case .keyPath(let projectedName, let keyPath):
                throw ProjectionError.propertyNotFound(propertyName: keyPath)
            }
        }
    }

    private func property(_ name: String) -> Property? {
        for prop in object.objectSchema.properties {
            if prop.name == name {
                return prop
            }
        }
        return nil
    }

    public subscript(dynamicMember member: String) -> Any? {
        guard let prop = props[member] else {
            return nil
        }
        return object[prop.name]
    }
}
