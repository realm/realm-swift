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
 A 128-bit IEEE-754  decimal floating point number.

 This type is similar to Swift's built-in Decimal type, but allocates bits differently, resulting in a different representable range.
 */
@objc(RealmSwiftDecimal128)
public final class Decimal128: RLMDecimal128, Decodable {
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

    public override required init() {
        super.init()
    }
    public override required init(value: Any) {
        super.init(value: value)
    }
    public override required init(number: NSNumber) {
        super.init(number: number)
    }
    public override required init(string: String) throws {
        try super.init(string: string)
    }
}

extension Decimal128: Encodable {
    public func encode(to encoder: Encoder) throws {
        try self.stringValue.encode(to: encoder)
    }
}

extension Decimal128: ExpressibleByIntegerLiteral {
    public convenience init(integerLiteral value: Int64) {
        self.init(number: value as NSNumber)
    }
}

extension Decimal128: ExpressibleByFloatLiteral {
    public convenience init(floatLiteral value: Double) {
        self.init(number: value as NSNumber)
    }
}

extension Decimal128: ExpressibleByStringLiteral {
    public convenience init(stringLiteral value: String) {
        try! self.init(string: value)
    }
}
