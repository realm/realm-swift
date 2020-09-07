////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
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
 A 128-bit IEEE 754-2008 decimal floating point number.

 This type is similar to Swift's built-in Decimal type, but allocates bits differently, resulting in a different representable range. (NS)Decimal stores a significand of up to 38 digits long and an exponent from -128 to 127, while this type stores up to 34 digits of significand and an exponent from -6143 to 6144.
 */
@objc(RealmSwiftDecimal128)
public final class Decimal128: RLMDecimal128, Decodable {
    /// Creates a new zero-initialized Decimal128.
    public override required init() {
        super.init()
    }

    /// Converts the given value to a Decimal128.
    ///
    /// The following types can be converted to Decimal128:
    /// - Int (of any size)
    /// - Float
    /// - Double
    /// - String
    /// - NSNumber
    /// - Decimal
    ///
    /// Passing a value with a type not in this list is a fatal error. Passing a string which cannot be parsed as a valid Decimal128 is a fatal error.
    ///
    /// - parameter value: The value to convert to a Decimal128.
    public override required init(value: Any) {
        super.init(value: value)
    }

    /// Converts the given number to a Decimal128.
    ///
    /// This initializer cannot fail and is never lossy.
    ///
    /// - parameter number: The number to convert to a Decimal128.
    public override required init(number: NSNumber) {
        super.init(number: number)
    }

    /// Parse the given string as a Decimal128.
    ///
    /// This initializer throws if the string is not a valid Decimal128 or is not a value which can be exactly represented by Decimal128.
    ///
    /// - parameter string: The string to parse.
    public override required init(string: String) throws {
        try super.init(string: string)
    }

    /// Creates a new Decimal128 by decoding from the given decoder.
    ///
    /// This initializer throws an error if the decoder is invalid or does not decode to a value which can be converted to Decimal128.
    ///
    /// - Parameter decoder: The decoder to read data from.
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let strValue = try? container.decode(String.self) {
            try super.init(string: strValue)
        } else if let intValue = try? container.decode(Int64.self) {
            super.init(number: intValue as NSNumber)
        } else if let doubleValue = try? container.decode(Double.self) {
            super.init(number: doubleValue as NSNumber)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot convert value to Decimal128")
        }
    }

}

extension Decimal128: Encodable {
    /// Encodes this Decimal128 to the given encoder.
    ///
    /// This function throws an error if the given encoder is unable to encode a string.
    ///
    /// - Parameter encoder: The encoder to write data to.
    public func encode(to encoder: Encoder) throws {
        try self.stringValue.encode(to: encoder)
    }
}

extension Decimal128: ExpressibleByIntegerLiteral {
    /// Creates a new Decimal128 from the given integer literal.
    public convenience init(integerLiteral value: Int64) {
        self.init(number: value as NSNumber)
    }
}

extension Decimal128: ExpressibleByFloatLiteral {
    /// Creates a new Decimal128 from the given float literal.
    public convenience init(floatLiteral value: Double) {
        self.init(number: value as NSNumber)
    }
}

extension Decimal128: ExpressibleByStringLiteral {
    /// Creates a new Decimal128 from the given string literal.
    ///
    /// Aborts if the string cannot be parsed as a Decimal128.
    public convenience init(stringLiteral value: String) {
        try! self.init(string: value)
    }
}

extension Decimal128: Comparable {
    /// Returns a Boolean value indicating whether two decimal128 values are equal.
    ///
    /// - Parameters:
    ///   - lhs: A Decimal128 value to compare.
    ///   - rhs: Another Decimal128 value to compare.
    public static func == (lhs: Decimal128, rhs: Decimal128) -> Bool {
        lhs.isEqual(to: rhs)
    }

    /// Returns a Boolean value indicating whether the decimal128 value of the first
    /// argument is less than that of the second argument.
    ///
    /// - Parameters:
    ///   - lhs: A Decimal128 value to compare.
    ///   - rhs: Another Decimal128 value to compare.
    public static func < (lhs: Decimal128, rhs: Decimal128) -> Bool {
        lhs.isLessThan(rhs)
    }

    /// Returns a Boolean value indicating whether the decimal128 value of the first
    /// argument is less than or equal to that of the second argument.
    ///
    /// - Parameters:
    ///   - lhs: A Decimal128 value to compare.
    ///   - rhs: Another Decimal128 value to compare.
    public static func <= (lhs: Decimal128, rhs: Decimal128) -> Bool {
        lhs.isLessThanOrEqual(to: rhs)
    }

    /// Returns a Boolean value indicating whether the decimal128 value of the first
    /// argument is greater than or equal to that of the second argument.
    ///
    /// - Parameters:
    ///   - lhs: A Decimal128 value to compare.
    ///   - rhs: Another Decimal128 value to compare.
    public static func >= (lhs: Decimal128, rhs: Decimal128) -> Bool {
        lhs.isGreaterThanOrEqual(to: rhs)
    }

    /// Returns a Boolean value indicating whether the decimal128 value of the first
    /// argument is greater than that of the second argument.
    ///
    /// - Parameters:
    ///   - lhs: A Decimal128 value to compare.
    ///   - rhs: Another Decimal128 value to compare.
    public static func > (lhs: Decimal128, rhs: Decimal128) -> Bool {
        lhs.isGreaterThan(rhs)
    }

}

extension Decimal128 : SignedNumeric {
    /// Creates a new instance from the given integer, if it can be represented
    /// exactly.
    ///
    /// If the value passed as `source` is not representable exactly, the result
    /// is `nil`. In the following example, the constant `x` is successfully
    /// created from a value of `100`, while the attempt to initialize the
    /// constant `y` from `1_000` fails because the `Int8` type can represent
    /// `127` at maximum:
    ///
    /// - Parameter source: A value to convert to this type of integer.
    public convenience init?<T>(exactly source: T) where T : BinaryInteger {
        self.init(value: source)
    }

    /// A type that can represent the absolute value of Decimal128
    public typealias Magnitude = Decimal128

    /// The magnitude of this Decimal128.
    public var magnitude: Magnitude {
        fatalError("Magnitude not available")
    }

    /// Replaces this Decimal128 value with its additive inverse.
    public func negate() {
        fatalError("Negate not available")
    }

    /// Adds two decimal128 values and produces their sum.
    ///
    /// - Parameters:
    ///   - lhs: The first Decimal128 value to add.
    ///   - rhs: The second Decimal128 value to add.
    public static func + (lhs: Decimal128, rhs: Decimal128) -> Decimal128 {
        lhs.decimalNumber(byAdding: rhs) as! Decimal128
    }

    /// Adds two decimal128 values and stores the result in the left-hand-side variable.
    ///
    /// - Parameters:
    ///   - lhs: The first Decimal128 value to add.
    ///   - rhs: The second Decimal128 value to add.
    public static func += (lhs: inout Decimal128, rhs: Decimal128) {
        lhs.additionAssignment(with: rhs)
    }

    /// Subtracts one Decimal128 value from another and produces their difference.
    ///
    /// - Parameters:
    ///   - lhs: A Decimal128 value.
    ///   - rhs: The Decimal128 value to subtract from `lhs`.
    public static func - (lhs: Decimal128, rhs: Decimal128) -> Decimal128 {
        fatalError("Operator not available")
    }

    /// Subtracts the second Decimal128 value from the first and stores the difference in the
    /// left-hand-side variable.
    ///
    /// - Parameters:
    ///   - lhs: A Decimal128 value.
    ///   - rhs: The Decimal128 value to subtract from `lhs`.
    public static func -= (lhs: inout Decimal128, rhs: Decimal128) {
        fatalError("Operator not available")
    }

    /// Multiplies two Decimal128 values and stores the result in the left-hand-side
    /// variable.
    ///
    /// - Parameters:
    ///   - lhs: The first Decimal128 value to multiply.
    ///   - rhs: The second Decimal128 value to multiply.
    public static func *= (lhs: inout Decimal128, rhs: Decimal128) {
        fatalError("Operator not available")
    }

    /// Returns the quotient of dividing the first Decimal128 value by the second.
    ///
    /// - Parameters:
    ///   - lhs: The Decimal128 value to divide.
    ///   - rhs: The Decimal128 value to divide `lhs` by. `rhs` must not be zero.
    public static func / (lhs: Decimal128, rhs: Decimal128) -> Decimal128 {
        lhs.decimalNumberFromDividing(by: rhs) as! Decimal128
    }
    
    /// Divides the first Decimal128 value by the second and stores the quotient in the
    /// left-hand-side variable.
    ///
    /// - Parameters:
    ///   - lhs: The Decimal128 value to divide.
    ///   - rhs: The Decimal128 value to divide `lhs` by. `rhs` must not be zero.
    public static func /= (lhs: inout Decimal128, rhs: Decimal128) {
        fatalError("Operator not available")
    }

    /// Multiplies two Decimal128 values and produces their product.
    ///
    /// - Parameters:
    ///   - lhs: The first Decimal128 value to multiply.
    ///   - rhs: The second Decimal128 value to multiply.
    public static func * (lhs: Decimal128, rhs: Decimal128) -> Decimal128 {
        fatalError("Operator not available")
    }
}

/*
 TODO: Decide wheter to impl from core level or cocoa level
extension Decimal128 : Strideable {

    /// Returns the distance from this value to the given value, expressed as a
    /// stride.
    ///
    /// If this type's `Stride` type conforms to `BinaryInteger`, then for two
    /// values `x` and `y`, and a distance `n = x.distance(to: y)`,
    /// `x.advanced(by: n) == y`. Using this method with types that have a
    /// noninteger `Stride` may result in an approximation.
    ///
    /// - Parameter other: The value to calculate the distance to.
    /// - Returns: The distance from this value to `other`.
    ///
    /// - Complexity: O(1)
    public func distance(to other: Decimal128) -> Decimal128 {
        0.0
    }

    /// Returns a value that is offset the specified distance from this value.
    ///
    /// Use the `advanced(by:)` method in generic code to offset a value by a
    /// specified distance. If you're working directly with numeric values, use
    /// the addition operator (`+`) instead of this method.
    ///
    ///     func addOne<T: Strideable>(to x: T) -> T
    ///         where T.Stride: ExpressibleByIntegerLiteral
    ///     {
    ///         return x.advanced(by: 1)
    ///     }
    ///
    ///     let x = addOne(to: 5)
    ///     // x == 6
    ///     let y = addOne(to: 3.5)
    ///     // y = 4.5
    ///
    /// If this type's `Stride` type conforms to `BinaryInteger`, then for a
    /// value `x`, a distance `n`, and a value `y = x.advanced(by: n)`,
    /// `x.distance(to: y) == n`. Using this method with types that have a
    /// noninteger `Stride` may result in an approximation.
    ///
    /// - Parameter n: The distance to advance this value.
    /// - Returns: A value that is offset from this value by `n`.
    ///
    /// - Complexity: O(1)
    public func advanced(by n: Decimal128) -> Decimal128 {
        0.0
    }

    /// A type that represents the distance between two values.
    public typealias Stride = Decimal128
}*/

extension Decimal128 {
    /// `true` if `self` is a signaling NaN, `false` otherwise.
    public var isSignaling: Bool {
        self.isNaN
    }

    /// `true` if `self` is a signaling NaN, `false` otherwise.
    public var isSignalingNaN: Bool {
        self.isSignaling
    }
}
