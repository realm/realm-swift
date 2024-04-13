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

        let objv0 = try realmv0.write {
            let value = ObjectWithNullablePropsV0(boolCol: true, intCol: 42, doubleCol: 123.456, stringCol: "abc", binaryCol: "foo".data(using: String.Encoding.utf8)!, dateCol: date, longCol: 998877665544332211, decimalCol: Decimal128(1), uuidCol: uuid, objectIdCol: oid)
            realmv0.add(value)
            return value
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
        XCTAssertEqual(objv1.willBeRemovedCol, "")

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

        try realmv0.write {
            objv0.boolCol = nil
            objv0.intCol = nil
            objv0.doubleCol = nil
            objv0.stringCol = nil
            objv0.binaryCol = nil
            objv0.dateCol = nil
            objv0.longCol = nil
            objv0.decimalCol = nil
            objv0.uuidCol = nil
            objv0.objectIdCol = nil
        }

        waitForUploads(for: realmv0)
        waitForDownloads(for: realmv1)
        waitForDownloads(for: realmv2)

        XCTAssertEqual(objv1.boolCol, false)
        XCTAssertEqual(objv1.intCol, 0)
        XCTAssertEqual(objv1.doubleCol, 0)
        XCTAssertEqual(objv1.stringCol, "")
        XCTAssertEqual(objv1.binaryCol, Data())
        XCTAssertEqual(objv1.dateCol, Date(timeIntervalSince1970: -62135596800)) // This is 0001-01-01 00:00:00 UTC
        XCTAssertEqual(objv1.longCol, 0)
        XCTAssertEqual(objv1.decimalCol, Decimal128(0))
        XCTAssertEqual(objv1.uuidCol, UUID.init(uuidString: "00000000-0000-0000-0000-000000000000"))
        XCTAssertEqual(objv1.objectIdCol, try ObjectId(string: "000000000000000000000000"))
        XCTAssertEqual(objv1.willBeRemovedCol, "")

        XCTAssertNil(objv2.boolCol)
        XCTAssertNil(objv2.intCol)
        XCTAssertNil(objv2.doubleCol)
        XCTAssertNil(objv2.stringCol)
        XCTAssertNil(objv2.binaryCol)
        XCTAssertNil(objv2.dateCol)
        XCTAssertNil(objv2.longCol)
        XCTAssertNil(objv2.decimalCol)
        XCTAssertNil(objv2.uuidCol)
        XCTAssertNil(objv2.objectIdCol)
    }

    func testCanRemoveField() throws {
        let realmv1 = try openMigrationRealm(schemaVersion: 1, type: ObjectWithNullablePropsV1.self)

        let date = Date()
        let uuid = UUID()
        let oid = ObjectId()

        let objv1 = try realmv1.write {
            let value = ObjectWithNullablePropsV1(boolCol: true, intCol: 987, doubleCol: 123.456, stringCol: "hello there", binaryCol: "general kenobi".data(using: String.Encoding.utf8)!, dateCol: date, longCol: -98765432123456789, decimalCol: Decimal128(value: 1.23456), uuidCol: uuid, objectIdCol: oid, willBeRemovedCol: "this should go away!")

            realmv1.add(value)

            return value
        }

        XCTAssertEqual(objv1.willBeRemovedCol, "this should go away!")

        waitForUploads(for: realmv1)

        let realmv1_differentUser = try openMigrationRealm(schemaVersion: 1, type: ObjectWithNullablePropsV1.self)
        let objv1_differentUser = realmv1_differentUser.objects(ObjectWithNullablePropsV1.self).first!

        // Removed fields are not synced, so new clients will not see them
        XCTAssertEqual(objv1_differentUser.willBeRemovedCol, "")

        try realmv1_differentUser.write {
            objv1_differentUser.willBeRemovedCol = "update from different user"
            objv1_differentUser.stringCol = "string from different user"
        }

        waitForUploads(for: realmv1_differentUser)
        waitForDownloads(for: realmv1)

        // String update should have been synced, but not the removed field one
        XCTAssertEqual(objv1.stringCol, "string from different user")
        XCTAssertEqual(objv1.willBeRemovedCol, "this should go away!")

        let realmv2 = try openMigrationRealm(schemaVersion: 2, type: ObjectWithNullablePropsV0.self)
        let id2 = try realmv2.write {
            let value = ObjectWithNullablePropsV0()
            realmv2.add(value)
            return value._id
        }

        waitForUploads(for: realmv2)
        waitForDownloads(for: realmv1)

        let objv2 = realmv1.object(ofType: ObjectWithNullablePropsV1.self, forPrimaryKey: id2)!
        let objv2_differentUser = realmv1_differentUser.object(ofType: ObjectWithNullablePropsV1.self, forPrimaryKey: id2)!
        XCTAssertEqual(objv2.willBeRemovedCol, "")
        XCTAssertEqual(objv2_differentUser.willBeRemovedCol, "")

        // Values for willBeRemovedCol should not have changed, even if they are different across the two realms
        XCTAssertEqual(objv1.willBeRemovedCol, "this should go away!")
        XCTAssertEqual(objv1_differentUser.willBeRemovedCol, "update from different user")
    }

    func testOpenRealmFailsWithNonExistingSchemaVersion() throws {
        var config = try configuration()
        config.schemaVersion = 3
        config.objectTypes = [ObjectWithNullablePropsV1.self]

        Realm.asyncOpen(configuration: config).awaitFailure(self) { error in

            let expected = "Client provided invalid schema version: schema version in BIND 3 is greater than latest schema version 2"
            XCTAssertTrue(error.localizedDescription.localizedStandardContains(expected), "Expected \(error.localizedDescription) to contain \(expected)")
        }
    }

    func testSameRealmCanBeMigratedThroughConsequtiveVersions() throws {
        var user: User?
        var realmPath: URL?
        try autoreleasepool {
            let realm = try openMigrationRealm(schemaVersion: 0, type: ObjectWithNullablePropsV0.self)
            realmPath = realm.configuration.fileURL
            user = realm.configuration.syncConfiguration!.user
            try realm.write {
                let value = ObjectWithNullablePropsV0()
                value.stringCol = "some value"
                realm.add(value)
            }
        }

        var configv1 = user!.flexibleSyncConfiguration()
        configv1.schemaVersion = 1
        configv1.objectTypes = [ObjectWithNullablePropsV1.self]

        try autoreleasepool {
            let realm = Realm.asyncOpen(configuration: configv1).await(self)
            XCTAssertEqual(realm.configuration.fileURL, realmPath)

            let objv1 = realm.objects(ObjectWithNullablePropsV1.self).first!
            XCTAssertEqual(objv1.boolCol, false)
            XCTAssertEqual(objv1.intCol, 0)
            XCTAssertEqual(objv1.doubleCol, 0)
            XCTAssertEqual(objv1.stringCol, "some value")
            XCTAssertEqual(objv1.binaryCol, Data())
            XCTAssertEqual(objv1.dateCol, Date(timeIntervalSince1970: -62135596800)) // This is 0001-01-01 00:00:00 UTC
            XCTAssertEqual(objv1.longCol, 0)
            XCTAssertEqual(objv1.decimalCol, Decimal128(0))
            XCTAssertEqual(objv1.uuidCol, UUID.init(uuidString: "00000000-0000-0000-0000-000000000000"))
            XCTAssertEqual(objv1.objectIdCol, try ObjectId(string: "000000000000000000000000"))
            XCTAssertEqual(objv1.willBeRemovedCol, "")
        }

        var configv2 = user!.flexibleSyncConfiguration()
        configv2.schemaVersion = 2
        configv2.objectTypes = [ObjectWithNullablePropsV0.self]

        autoreleasepool {
            let realm = Realm.asyncOpen(configuration: configv2).await(self)
            XCTAssertEqual(realm.configuration.fileURL, realmPath)

            let objv2 = realm.objects(ObjectWithNullablePropsV0.self).first!
            XCTAssertNil(objv2.boolCol)
            XCTAssertNil(objv2.intCol)
            XCTAssertNil(objv2.doubleCol)
            XCTAssertEqual(objv2.stringCol, "some value")
            XCTAssertNil(objv2.binaryCol)
            XCTAssertNil(objv2.dateCol)
            XCTAssertNil(objv2.longCol)
            XCTAssertNil(objv2.decimalCol)
            XCTAssertNil(objv2.uuidCol)
            XCTAssertNil(objv2.objectIdCol)
        }
    }
}

#endif // os(macOS)
