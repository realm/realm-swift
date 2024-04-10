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

#if os(macOS)
import RealmSwift
import XCTest
import Combine

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
import SwiftUI
import RealmSwiftTestSupport
#endif

@available(macOS 13.0, *)
class SyncMigrationTests: SwiftSyncTestCase {
    override func configuration(user: User) -> Realm.Configuration {
        user.flexibleSyncConfiguration()
    }

    override func createApp() throws -> String {
        try RealmServer.shared.createApp(fields: [], types: [ObjectWithNullablePropsV0.self], typeUpdates: [[ObjectWithNullablePropsV1.self], [ObjectWithNullablePropsV0.self]])
    }

    override var objectTypes: [ObjectBase.Type] {
        [ObjectWithNullablePropsV0.self]
    }

    func openMigrationRealm(schemaVersion: UInt64, type: ObjectBase.Type) throws -> Realm {
        var config = try configuration()
        config.schemaVersion = schemaVersion
        config.objectTypes = [type]

        let realm = Realm.asyncOpen(configuration: config).await(self)
        RLMRealmSubscribeToAll(ObjectiveCSupport.convert(object: realm))
        waitForDownloads(for: realm)

        return realm
    }

    func testCanMigratePropertyOptionality() throws {
        let realmv0 = try openMigrationRealm(schemaVersion: 0, type: ObjectWithNullablePropsV0.self)

        let oid = ObjectId()
        let uuid = UUID()
        let date = Date(timeIntervalSince1970: -987)

        try realmv0.write {
            realmv0.add(ObjectWithNullablePropsV0(boolCol: true, intCol: 42, doubleCol: 123.456, stringCol: "abc", binaryCol: "foo".data(using: String.Encoding.utf8)!, dateCol: date, longCol: 998877665544332211, decimalCol: Decimal128(1), uuidCol: uuid, objectIdCol: oid))
        }

        waitForUploads(for: realmv0)

        let realmv1 =  try openMigrationRealm(schemaVersion: 1, type: ObjectWithNullablePropsV1.self)
        let objv1 = realmv1.objects(ObjectWithNullablePropsV1.self).first!

        XCTAssertEqual(objv1.boolCol, true)
        XCTAssertEqual(objv1.intCol, 42)
        XCTAssertEqual(objv1.doubleCol, 123.456)
        XCTAssertEqual(objv1.stringCol, "abc")
        XCTAssertEqual(objv1.binaryCol, "foo".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(objv1.dateCol, date)
        XCTAssertEqual(objv1.longCol, 998877665544332211)
        XCTAssertEqual(objv1.decimalCol, Decimal128(1))
        XCTAssertEqual(objv1.uuidCol, uuid)
        XCTAssertEqual(objv1.objectIdCol, oid)

        let realmv2 =  try openMigrationRealm(schemaVersion: 2, type: ObjectWithNullablePropsV0.self)
        let objv2 = realmv2.objects(ObjectWithNullablePropsV0.self).first!

        XCTAssertEqual(objv2.boolCol, true)
        XCTAssertEqual(objv2.intCol, 42)
        XCTAssertEqual(objv2.doubleCol, 123.456)
        XCTAssertEqual(objv2.stringCol, "abc")
        XCTAssertEqual(objv2.binaryCol, "foo".data(using: String.Encoding.utf8)!)
        XCTAssertEqual(objv2.dateCol, date)
        XCTAssertEqual(objv2.longCol, 998877665544332211)
        XCTAssertEqual(objv2.decimalCol, Decimal128(1))
        XCTAssertEqual(objv2.uuidCol, uuid)
        XCTAssertEqual(objv2.objectIdCol, oid)
    }
}

#endif // os(macOS)
