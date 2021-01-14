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

import XCTest
import RealmSwift
import SwiftUI

@available(iOS 14.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
class SwiftUITests: TestCase {
    struct TestListView {
        @RealmState var list: RealmSwift.List<SwiftBoolObject>
    }
    struct TestObjectView {
        @RealmState var object: SwiftObject
    }
    struct TestResultsView {
        @RealmState(SwiftObject.self, realm: inMemoryRealm("swiftui-tests")) var results: Results<SwiftObject>
    }

    func testRealmBindingDynamicPrimitiveColumn() {
        let view = TestResultsView()
        view.$results.append(SwiftObject())
        let object = view.$results[0].thaw()!
        XCTAssertFalse(object.isFrozen)
        let objectView = TestObjectView(object: object)
        let oldValue = object.stringCol
        objectView.$object.stringCol.wrappedValue = oldValue + "foo"
        XCTAssertEqual(objectView.$object.stringCol.wrappedValue, oldValue + "foo")
        XCTAssertEqual(object.stringCol, oldValue + "foo")
    }

    func testRealmBindingDynamicObjectColumn() {
        let view = TestResultsView()
        let object = SwiftObject()
        view.$results.append(object)
        XCTAssertFalse(object.isFrozen)
        let objectView = TestObjectView(object: object)

        XCTAssertFalse(objectView.$object.objectCol.boolCol.wrappedValue)
        XCTAssertFalse(object.objectCol?.boolCol ?? false)

        objectView.$object.objectCol.wrappedValue = SwiftBoolObject()
        objectView.$object.objectCol.boolCol.wrappedValue = true//.toggle()

        XCTAssertTrue(objectView.$object.objectCol.boolCol.wrappedValue)
        XCTAssertTrue(object.objectCol?.boolCol ?? false)
    }

    func testResultsAppendRemove() {
        let view = TestResultsView()
        let object = SwiftObject()
        view.$results.append(object)
        XCTAssertEqual(view.results.count, 1)
        view.$results.remove(atOffsets: IndexSet(arrayLiteral: 0))
        XCTAssertEqual(view.results.count, 0)
    }

    func testListAppendMoveRemove() {
        let view = TestResultsView()
        let object = SwiftObject()
        view.$results.append(object)
        let listView = TestListView(list: object.arrayCol)
        listView.$list.append(SwiftBoolObject())
        XCTAssertEqual(listView.list.count, 1)
        listView.$list.append(SwiftBoolObject())
        XCTAssertEqual(listView.list.count, 2)
        let realm = inMemoryRealm("swiftui-tests")
        let obj = listView.$list[0].wrappedValue
        try! realm.write { obj.thaw()?.boolCol = true }
        XCTAssertFalse(listView.$list[1].boolCol.wrappedValue)
        listView.$list.move(fromOffsets: IndexSet([0]), toOffset: 2)
        XCTAssertTrue(listView.$list[1].boolCol.wrappedValue)
        listView.$list.remove(atOffsets: IndexSet([0, 1]))
        XCTAssertEqual(listView.list.count, 0)
    }
}
