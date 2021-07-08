////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

/// A protocol describing types that can parameterize a `RealmOptional`.
public protocol RealmOptionalType {
}

public extension RealmOptionalType {
    /// :nodoc:
    static func className() -> String {
        return ""
    }
}
extension Int: RealmOptionalType {}
extension Int8: RealmOptionalType {}
extension Int16: RealmOptionalType {}
extension Int32: RealmOptionalType {}
extension Int64: RealmOptionalType {}
extension Float: RealmOptionalType {}
extension Double: RealmOptionalType {}
extension Bool: RealmOptionalType {}

/**
 A `RealmOptional` instance represents an optional value for types that can't be
 directly declared as `@objc` in Swift, such as `Int`, `Float`, `Double`, and `Bool`.

 To change the underlying value stored by a `RealmOptional` instance, mutate the instance's `value` property.
 */
@available(*, deprecated, renamed: "RealmProperty", message: "RealmOptional<T> has been deprecated, use RealmProperty<T?> instead.")
public final class RealmOptional<Value: RealmOptionalType>: RLMSwiftValueStorage {
    /// The value the optional represents.
    public var value: Value? {
        get {
            return RLMGetSwiftValueStorage(self).map(dynamicBridgeCast)
        }
        set {
            RLMSetSwiftValueStorage(self, newValue.map(dynamicBridgeCast))
        }
    }

    /**
     Creates a `RealmOptional` instance encapsulating the given default value.

     - parameter value: The value to store in the optional, or `nil` if not specified.
     */
    public init(_ value: Value? = nil) {
        super.init()
        self.value = value
    }
}

@available(*, deprecated, message: "RealmOptional has been deprecated, use RealmProperty<T?> instead.")
extension RealmOptional: Equatable where Value: Equatable {
    public static func == (lhs: RealmOptional<Value>, rhs: RealmOptional<Value>) -> Bool {
        return lhs.value == rhs.value
    }
}

@available(*, deprecated, message: "RealmOptional has been deprecated, use RealmProperty<T?> instead.")
extension RealmOptional: Codable where Value: Codable, Value: _RealmSchemaDiscoverable {
    public convenience init(from decoder: Decoder) throws {
        self.init()
        // `try decoder.singleValueContainer().decode(Value?.self)` incorrectly
        // rejects null values: https://bugs.swift.org/browse/SR-7404
        self.value = try decoder.decodeOptional(Value?.self)
    }

    public func encode(to encoder: Encoder) throws {
        try self.value.encode(to: encoder)
    }
}

internal protocol RealmOptionalProtocol { }
@available(*, deprecated, message: "RealmOptional has been deprecated, use RealmProperty<T?> instead.")
extension RealmOptional: RealmOptionalProtocol { }

internal extension Decoder {
    func decodeOptional<T: _RealmSchemaDiscoverable>(_ type: T.Type) throws -> T where T: Decodable {
        let container = try singleValueContainer()
        return container.decodeNil() ? T._nilValue() : try container.decode(T.self)
    }
}
