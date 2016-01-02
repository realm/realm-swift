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

import Foundation
import Realm

/**
A `SortDescriptor` stores a property name and a sort order for use with
`sorted(sortDescriptors:)`. It is similar to `NSSortDescriptor`, but supports
only the subset of functionality which can be efficiently run by Realm's query
engine.
*/
public struct SortDescriptor {

    // MARK: Properties

    /// The name of the property which this sort descriptor orders results by.
    public let property: String

    /// Whether this descriptor sorts in ascending or descending order.
    public let ascending: Bool

    /// Converts the receiver to an `RLMSortDescriptor`
    internal var rlmSortDescriptorValue: RLMSortDescriptor {
        return RLMSortDescriptor(property: property, ascending: ascending)
    }

    // MARK: Initializers

    /**
    Creates a `SortDescriptor` with the given property and ascending values.

    - parameter property:  The name of the property which this sort descriptor orders results by.
    - parameter ascending: Whether this descriptor sorts in ascending or descending order.
    */
    public init(property: String, ascending: Bool = true) {
        self.property = property
        self.ascending = ascending
    }

    // MARK: Functions

    /// Returns a copy of the `SortDescriptor` with the sort order reversed.
    public func reversed() -> SortDescriptor {
        return SortDescriptor(property: property, ascending: !ascending)
    }
}

// MARK: CustomStringConvertible

extension SortDescriptor: CustomStringConvertible {
    /// Returns a human-readable description of the sort descriptor.
    public var description: String {
        let direction = ascending ? "ascending" : "descending"
        return "SortDescriptor (property: \(property), direction: \(direction))"
    }
}

// MARK: Equatable

extension SortDescriptor: Equatable {}

// swiftlint:disable valid_docs

/// Returns whether the two sort descriptors are equal.
public func == (lhs: SortDescriptor, rhs: SortDescriptor) -> Bool {
    return lhs.property == rhs.property &&
        lhs.ascending == lhs.ascending
}

// swiftlint:enable valid_docs

// MARK: StringLiteralConvertible

extension SortDescriptor: StringLiteralConvertible {

    /// `StringLiteralType`. Required for `StringLiteralConvertible` conformance.
    public typealias UnicodeScalarLiteralType = StringLiteralType

    /// `StringLiteralType`. Required for `StringLiteralConvertible` conformance.
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType

    /**
    Creates a `SortDescriptor` from a `UnicodeScalarLiteralType`.

    - parameter unicodeScalarLiteral: Property name literal.
    */
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(property: value)
    }

    /**
    Creates a `SortDescriptor` from an `ExtendedGraphemeClusterLiteralType`.

    - parameter extendedGraphemeClusterLiteral: Property name literal.
    */
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(property: value)
    }

    /**
    Creates a `SortDescriptor` from a `StringLiteralType`.

    - parameter stringLiteral: Property name literal.
    */
    public init(stringLiteral value: StringLiteralType) {
        self.init(property: value)
    }
}
