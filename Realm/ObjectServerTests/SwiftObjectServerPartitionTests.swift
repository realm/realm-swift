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

import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
#endif

@available(OSX 10.14, *)
@objc(SwiftObjectServerPartitionTests)
class SwiftObjectServerPartitionTests: SwiftSyncTestCase {
    func writeObjects<T: BSON>(_ user: User, _ partitionValue: T) throws {
        try autoreleasepool {
            var config = user.configuration(partitionValue: partitionValue)
            config.objectTypes = [SwiftPerson.self]
            let realm = try Realm(configuration: config)

            try realm.write {
                realm.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
                realm.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
                realm.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
                realm.add(SwiftPerson(firstName: "George", lastName: "Harrison"))
            }
            waitForUploads(for: realm)
        }
    }

    func roundTripForPartitionValue<T: BSON>(partitionValue: T) throws {
        let partitionType = partitionBsonType(ObjectiveCSupport.convert(object: AnyBSON(partitionValue))!)
        let appId = try RealmServer.shared.createAppForBSONType(partitionType)

        let partitionApp = app(fromAppId: appId)
        let user = try logInUser(for: basicCredentials(app: partitionApp), app: partitionApp)
        let user2 = try logInUser(for: Credentials.anonymous, app: partitionApp)
        let realm = try openRealm(partitionValue: partitionValue, user: user)
        checkCount(expected: 0, realm, SwiftPerson.self)

        try writeObjects(user2, partitionValue)
        waitForDownloads(for: realm)
        checkCount(expected: 4, realm, SwiftPerson.self)
        XCTAssertEqual(realm.objects(SwiftPerson.self).filter { $0.firstName == "Ringo" }.count, 1)

        try writeObjects(user2, partitionValue)
        waitForDownloads(for: realm)
        checkCount(expected: 8, realm, SwiftPerson.self)
        XCTAssertEqual(realm.objects(SwiftPerson.self).filter { $0.firstName == "Ringo" }.count, 2)
    }

    func testSwiftRoundTripForObjectIdPartitionValue() throws {
        try roundTripForPartitionValue(partitionValue: ObjectId("1234567890ab1234567890ab"))
    }

    func testSwiftRoundTripForUUIDPartitionValue() throws {
        try roundTripForPartitionValue(partitionValue: UUID(uuidString: "b1c11e54-e719-4275-b631-69ec3f2d616d")!)
    }

    func testSwiftRoundTripForStringPartitionValue() throws {
        try roundTripForPartitionValue(partitionValue: "1234567890ab1234567890ab")
    }

    func testSwiftRoundTripForIntPartitionValue() throws {
        try roundTripForPartitionValue(partitionValue: 1234567890)
    }
}
