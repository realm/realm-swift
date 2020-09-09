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

import XCTest
import RealmSwift

class ObjectIdTests: TestCase {

    func testObjectIdInitialization() {
        let strValue = "000123450000ffbeef91906c"
        let objectId = try! ObjectId(string: strValue)
        XCTAssertEqual(objectId.stringValue, strValue)
        XCTAssertEqual(strValue, objectId.stringValue)

        let now = Date()
        let objectId2 = ObjectId(timestamp: now, machineId: 10, processId: 20)
        XCTAssertEqual(Int(now.timeIntervalSince1970), Int(objectId2.timestamp.timeIntervalSince1970))
    }

    func testObjectIdComparision() {
        let strValue = "000123450000ffbeef91906c"
        let objectId = try! ObjectId(string: strValue)

        let strValue2 = "000123450000ffbeef91906d"
        let objectId2 = try! ObjectId(string: strValue2)

        let strValue3 = "000123450000ffbeef91906c"
        let objectId3 = try! ObjectId(string: strValue3)

        XCTAssertTrue(objectId != objectId2)
        XCTAssertTrue(objectId == objectId3)
    }

    func testObjectIdGreaterThan() {
        let strValue = "000123450000ffbeef91906c"
        let objectId = try! ObjectId(string: strValue)

        let strValue2 = "000123450000ffbeef91906d"
        let objectId2 = try! ObjectId(string: strValue2)

        let strValue3 = "000123450000ffbeef91906c"
        let objectId3 = try! ObjectId(string: strValue3)

        XCTAssertTrue(objectId2 > objectId)
        XCTAssertFalse(objectId > objectId3)
    }

    func testObjectIdGreaterThanOrEqualTo() {
        let strValue = "000123450000ffbeef91906c"
        let objectId = try! ObjectId(string: strValue)

        let strValue2 = "000123450000ffbeef91906d"
        let objectId2 = try! ObjectId(string: strValue2)

        let strValue3 = "000123450000ffbeef91906c"
        let objectId3 = try! ObjectId(string: strValue3)

        XCTAssertTrue(objectId2 >= objectId)
        XCTAssertTrue(objectId >= objectId3)
    }

    func testObjectIdLessThan() {
        let strValue = "000123450000ffbeef91906c"
        let objectId = try! ObjectId(string: strValue)

        let strValue2 = "000123450000ffbeef91906d"
        let objectId2 = try! ObjectId(string: strValue2)

        let strValue3 = "000123450000ffbeef91906c"
        let objectId3 = try! ObjectId(string: strValue3)

        XCTAssertTrue(objectId < objectId2)
        XCTAssertFalse(objectId < objectId3)
    }

    func testObjectIdLessThanOrEqualTo() {
        let strValue = "000123450000ffbeef91906c"
        let objectId = try! ObjectId(string: strValue)

        let strValue2 = "000123450000ffbeef91906d"
        let objectId2 = try! ObjectId(string: strValue2)

        let strValue3 = "000123450000ffbeef91906c"
        let objectId3 = try! ObjectId(string: strValue3)

        XCTAssertTrue(objectId <= objectId2)
        XCTAssertTrue(objectId <= objectId3)
    }
}
