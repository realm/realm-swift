////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
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
import RealmSwift

private func fileSize(path: String) -> Int {
    let attributes = try! FileManager.default.attributesOfItem(atPath: path)
    return attributes[.size] as! Int
}

class CompactionTests: TestCase {
    func testSuccessfulCompactOnLaunch() {
        let expectedUsedBytesBeforeMin = 50000
        let count = 1000

        autoreleasepool {
            // Make compactable Realm
            let realm = realmWithTestPath()
            let uuid = UUID().uuidString
            try! realm.write {
                realm.create(SwiftStringObject.self, value: ["A"])
                for _ in 0..<count {
                    realm.create(SwiftStringObject.self, value: [uuid])
                }
                realm.create(SwiftStringObject.self, value: ["B"])
            }
        }
        let expectedTotalBytesBefore = fileSize(path: testRealmURL().path)

        // Configure the Realm to compact on launch
        let config = Realm.Configuration(fileURL: testRealmURL(),
                                         shouldCompactOnLaunch: { totalBytes, usedBytes in
            // Confirm expected sizes
            XCTAssertEqual(totalBytes, expectedTotalBytesBefore)
            XCTAssert((usedBytes < totalBytes) && (usedBytes > expectedUsedBytesBeforeMin))
            return true
        })

        // Confirm expected sizes before and after opening the Realm
        XCTAssertEqual(fileSize(path: config.fileURL!.path), expectedTotalBytesBefore)
        let realm = try! Realm(configuration: config)
        XCTAssertLessThan(fileSize(path: config.fileURL!.path), expectedTotalBytesBefore)

        // Validate that the file still contains what it should
        XCTAssertEqual(realm.objects(SwiftStringObject.self).count, count + 2)
        XCTAssertEqual("A", realm.objects(SwiftStringObject.self).first?.stringCol)
        XCTAssertEqual("B", realm.objects(SwiftStringObject.self).last?.stringCol)
    }
}
