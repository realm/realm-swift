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
 A unique object identifier.

 This type is similar to a GUID or UUID.
 */
@objc(RealmSwiftObjectId)
public final class ObjectId: RLMObjectId, Decodable {
    // MARK: Initializers
    public override required init() {
        super.init()
    }
    public override required init(string: String) throws {
        try super.init(string: string)
    }
    public required init(_ str: StaticString) {
        try! super.init(string: str.withUTF8Buffer { String(decoding: $0, as: UTF8.self) })
    }
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try super.init(string: container.decode(String.self))
    }
}

extension ObjectId: Encodable {
    public func encode(to encoder: Encoder) throws {
        try self.stringValue.encode(to: encoder)
    }
}
