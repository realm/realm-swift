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

extension Decimal128 {

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
