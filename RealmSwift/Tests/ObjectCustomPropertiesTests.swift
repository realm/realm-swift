////////////////////////////////////////////////////////////////////////////
//
// Copyright 2024 Realm Inc.
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

import XCTest
import Realm
@_spi(RealmSwiftPrivate) import RealmSwift

final class ObjectCustomPropertiesTests: TestCase, @unchecked Sendable {
    override func tearDown() {
        super.tearDown()
        CustomPropertiesObject.injected_customRealmProperties = nil
    }

    func testCustomProperties() throws {
        CustomPropertiesObject.injected_customRealmProperties = [CustomPropertiesObject.preMadeRLMProperty]

        let customProperties = try XCTUnwrap(CustomPropertiesObject._customRealmProperties())
        XCTAssertEqual(customProperties.count, 1)
        XCTAssert(customProperties.first === CustomPropertiesObject.preMadeRLMProperty)

        // Assert properties are custom properties
        let properties = CustomPropertiesObject._getProperties()
        XCTAssertEqual(properties.count, 1)
        XCTAssert(properties.first === CustomPropertiesObject.preMadeRLMProperty)
    }

    func testNoCustomProperties() {
        CustomPropertiesObject.injected_customRealmProperties = nil

        let customProperties = CustomPropertiesObject._customRealmProperties()
        XCTAssertNil(customProperties)

        // Assert properties are generated despite `nil` custom properties
        let properties = CustomPropertiesObject._getProperties()
        XCTAssertEqual(properties.count, 1)
        XCTAssert(properties.first !== CustomPropertiesObject.preMadeRLMProperty)
    }

    func testEmptyCustomProperties() throws {
        CustomPropertiesObject.injected_customRealmProperties = []

        let customProperties = try XCTUnwrap(CustomPropertiesObject._customRealmProperties())
        XCTAssertEqual(customProperties.count, 0)

        // Assert properties are custom properties (rather incorrectly)
        let properties = CustomPropertiesObject._getProperties()
        XCTAssertEqual(properties.count, 0)
    }
}

@objc(CustomPropertiesObject)
private final class CustomPropertiesObject: Object {
    @Persisted var value: String

    static override func _customRealmProperties() -> [RLMProperty]? {
        return injected_customRealmProperties
    }

    static nonisolated(unsafe) var injected_customRealmProperties: [RLMProperty]?
    static let preMadeRLMProperty = RLMProperty(name: "value", objectType: CustomPropertiesObject.self, valueType: String.self)
}
