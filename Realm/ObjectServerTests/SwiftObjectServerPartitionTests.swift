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
    func roundTripForPartitionValue<T: BSON>(partitionValue: T) {
        let partitionType = partitionBsonType(ObjectiveCSupport.convert(object: AnyBSON(partitionValue))!)
        let appId: String
        if isParent {
            appId = try! RealmServer.shared.createAppForBSONType(partitionType)
        } else {
            appId = appIds[0]
        }

        let partitionApp = app(fromAppId: appId)
        do {
            let user = try logInUser(for: basicCredentials(usernameSuffix: "", app: partitionApp), app: partitionApp)
            let realm = try openRealm(partitionValue: partitionValue, user: user)
            if isParent {
                try realm.write {
                    realm.deleteAll()
                }
                checkCount(expected: 0, realm, SwiftPerson.self)
                runChildAndWait(withAppIds: [appId])
                waitForDownloads(for: realm)
                checkCount(expected: 4, realm, SwiftPerson.self)

                XCTAssertEqual(realm.objects(SwiftPerson.self).filter { $0.firstName == "Ringo" }.count, 1)

                runChildAndWait(withAppIds: [appId])
                waitForDownloads(for: realm)
                checkCount(expected: 8, realm, SwiftPerson.self)

                XCTAssertEqual(realm.objects(SwiftPerson.self).filter { $0.firstName == "Ringo" }.count, 2)

                try realm.write {
                    realm.deleteAll()
                }
                waitForUploads(for: realm)
                checkCount(expected: 0, realm, SwiftPerson.self)
            } else {
                try realm.write {
                    realm.add(SwiftPerson(firstName: "Ringo", lastName: "Starr"))
                    realm.add(SwiftPerson(firstName: "John", lastName: "Lennon"))
                    realm.add(SwiftPerson(firstName: "Paul", lastName: "McCartney"))
                    realm.add(SwiftPerson(firstName: "George", lastName: "Harrison"))
                }
                waitForUploads(for: realm)
            }
        } catch {
            XCTFail("Got an error: \(error) (process: \(isParent ? "parent" : "child"))")
        }
    }

    func testSwiftRoundTripForObjectIdPartitionValue() {
        roundTripForPartitionValue(partitionValue: ObjectId("1234567890ab1234567890ab"))
    }

    func testSwiftRoundTripForUUIDPartitionValue() {
        roundTripForPartitionValue(partitionValue: UUID(uuidString: "b1c11e54-e719-4275-b631-69ec3f2d616d")!)
    }

    func testSwiftRoundTripForStringPartitionValue() {
        roundTripForPartitionValue(partitionValue: "1234567890ab1234567890ab")
    }

    func testSwiftRoundTripForIntPartitionValue() {
        roundTripForPartitionValue(partitionValue: 1234567890)
    }
}
