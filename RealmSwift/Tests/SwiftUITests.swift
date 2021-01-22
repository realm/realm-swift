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

#if canImport(SwiftUI)
import XCTest
import RealmSwift
import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 13.0, watchOS 6.0, *)
class SwiftUITests: TestCase {
    struct TestListView: View {
        @RealmState var list: RealmSwift.List<SwiftBoolObject>
        @RealmState var optList: RealmSwift.List<SwiftBoolObject>?

        var body: some View {
            VStack {
                ForEach(list, id: \.self) { object in
                    Toggle("toggle", isOn: object.bind(keyPath: \.boolCol))
                }
                ForEach(optList!, id: \.self) { object in
                    Toggle("toggle", isOn: object.bind(keyPath: \.boolCol))
                }
            }
        }
    }
    struct TestObjectView: View {
        @RealmState var object: SwiftObject
        @RealmState var optObject: SwiftObject?

        var body: some View { fatalError() }
    }

    struct TestResultsView: View {
        @RealmState(SwiftObject.self, realm: inMemoryRealm("swiftui-tests")) var results: Results<SwiftObject>
        @RealmState var optResults: Results<SwiftObject>?

        var body: some View {
            VStack {
                ForEach(results, id: \.self) { object in
                    Text(object.stringCol)
                }
                ForEach(optResults!, id: \.self) { object in
                    Text(object.stringCol)
                }
            }
        }
    }

    static let inMemoryIdentifier = "swiftui-tests"
    // We require a struct here to test the property wrapper projections
    struct ListHolder {
        @RealmState var list = RealmSwift.List<SwiftBoolObject>()
        @RealmState var listOpt: RealmSwift.List<SwiftBoolObject>?

        @RealmState var primitieveList = RealmSwift.List<Int>()
        @RealmState var primitiveListOpt: RealmSwift.List<Int>?
    }
    @RealmState var obj = SwiftObject()
    @RealmState var objOpt: SwiftObject?

    @RealmState var embedded = EmbeddedTreeObject1()
    @RealmState var embeddedOpt: EmbeddedTreeObject1?

    @RealmState var results = inMemoryRealm(SwiftUITests.inMemoryIdentifier).objects(SwiftObject.self)
    @RealmState var resultsOpt: Results<SwiftObject>?

    func testListAppend() throws {
        let listHolder = ListHolder(list: obj.arrayCol, listOpt: nil)
        listHolder.list.append(SwiftBoolObject())
        XCTAssertEqual(listHolder.list.count, 1)

        let realm = inMemoryRealm(SwiftUITests.inMemoryIdentifier)
        try realm.write { realm.add(obj) }

        assertThrows(listHolder.list.append(SwiftBoolObject()))
        XCTAssertNoThrow(listHolder.$list.append(SwiftBoolObject()))
        XCTAssertEqual(listHolder.list.count, 2)

        listHolder.listOpt?.append(SwiftBoolObject())
        XCTAssertEqual(listHolder.listOpt?.count, nil)

        listHolder.listOpt = obj.arrayCol
        assertThrows(listHolder.listOpt?.append(SwiftBoolObject()))

        XCTAssertNoThrow(listHolder.$listOpt.append(SwiftBoolObject()))
        XCTAssertEqual(listHolder.listOpt?.count, 3)
    }
//    func testRealmBindingDynamicPrimitiveColumn() {
//        let view = TestResultsView()
//        view.$results.append(SwiftObject())
//        let object = view.$results[0].thaw()!
//        XCTAssertFalse(object.isFrozen)
//        let objectView = TestObjectView(object: object)
//        let oldValue = object.stringCol
//        objectView.$object.stringCol.wrappedValue = oldValue + "foo"
//        XCTAssertEqual(objectView.$object.stringCol.wrappedValue, oldValue + "foo")
//        XCTAssertEqual(object.stringCol, oldValue + "foo")
//    }
//
//    func testRealmBindingDynamicObjectColumn() {
//        let view = TestResultsView()
//        let object = SwiftObject()
//        view.$results.append(object)
//        XCTAssertFalse(object.isFrozen)
//        let objectView = TestObjectView(object: object)
//
//        XCTAssertFalse(objectView.$object.objectCol.boolCol.wrappedValue)
//        XCTAssertFalse(object.objectCol?.boolCol ?? false)
//
//        objectView.$object.objectCol.wrappedValue = SwiftBoolObject()
//        objectView.$object.objectCol.boolCol.wrappedValue = true//.toggle()
//
//        XCTAssertTrue(objectView.$object.objectCol.boolCol.wrappedValue)
//        XCTAssertTrue(object.objectCol?.boolCol ?? false)
//    }
//
//    func testResultsAppendRemove() {
//        let view = TestResultsView()
//        let object = SwiftObject()
//        view.$results.append(object)
//        XCTAssertEqual(view.results.count, 1)
//        view.$results.remove(atOffsets: IndexSet(arrayLiteral: 0))
//        XCTAssertEqual(view.results.count, 0)
//    }
//
//    func testOptResultsAppendRemove() {
//        let object = SwiftObject()
//
//        var optResults = RealmState<Results<SwiftObject>?>()
//        assertThrows(optResults.projectedValue.append(object))
//
//        // we cannot assign to the wrappedValue due to how StateObject functions,
//        // so we'll unit test the individual methods
//        optResults = RealmState(wrappedValue: inMemoryRealm("swiftui-tests").objects(SwiftObject.self))
//
//        optResults.projectedValue.append(object)
//        XCTAssertEqual(optResults.wrappedValue!.count, 1)
//        optResults.projectedValue.remove(atOffsets: IndexSet(arrayLiteral: 0))
//        XCTAssertEqual(optResults.wrappedValue!.count, 0)
//    }
//
//    func testListAppendMoveRemove() {
//        let view = TestResultsView()
//        let object = SwiftObject()
//        view.$results.append(object)
//        let listView = TestListView(list: object.arrayCol)
//        listView.$list.append(SwiftBoolObject())
//        XCTAssertEqual(listView.list.count, 1)
//        listView.$list.append(SwiftBoolObject())
//        XCTAssertEqual(listView.list.count, 2)
//        let realm = inMemoryRealm("swiftui-tests")
//        let obj = listView.$list[0].wrappedValue
//        try! realm.write { obj.thaw()?.boolCol = true }
//        XCTAssertFalse(listView.$list[1].boolCol.wrappedValue)
//        listView.$list.move(fromOffsets: IndexSet([0]), toOffset: 2)
//        XCTAssertTrue(listView.$list[1].boolCol.wrappedValue)
//        listView.$list.remove(atOffsets: IndexSet([0, 1]))
//        XCTAssertEqual(listView.list.count, 0)
//    }
//
//    func testOptListAppendMoveRemove() {
//        let view = TestResultsView()
//        let object = SwiftObject()
//        view.$results.append(object)
//        let list = RealmState<RealmSwift.List<SwiftBoolObject>?>(initialValue: object.arrayCol)
//        list.projectedValue.append(SwiftBoolObject())
//        XCTAssertEqual(list.projectedValue.wrappedValue!.count, 1)
//        list.projectedValue.append(SwiftBoolObject())
//        XCTAssertEqual(list.projectedValue.wrappedValue!.count, 2)
//        let realm = inMemoryRealm("swiftui-tests")
//        let obj = list.projectedValue.wrappedValue![0]
//        try! realm.write { obj.thaw()?.boolCol = true }
//        XCTAssertFalse(list.projectedValue.wrappedValue![1].boolCol)
//        list.projectedValue.move(fromOffsets: IndexSet([0]), toOffset: 2)
//        XCTAssertTrue(list.projectedValue.wrappedValue![1].boolCol)
//        list.projectedValue.remove(atOffsets: IndexSet([0, 1]))
//        XCTAssertEqual(list.projectedValue.wrappedValue!.count, 0)
//    }
//
//    func testObjectBaseBindUnmanaged() {
//        let object = SwiftObject()
//        let boundInt = object.bind(keyPath: \.intCol)
//        boundInt.wrappedValue = 456
//        XCTAssertEqual(boundInt.wrappedValue, 456)
//        XCTAssertEqual(object.intCol, 456)
//    }
//
//    func testObjectBaseBindManaged() {
//        let object = SwiftObject()
//        let realm = inMemoryRealm("swiftui-tests")
//        try! realm.write {
//            realm.add(object)
//        }
//        let boundInt = object.bind(keyPath: \.intCol)
//        boundInt.wrappedValue = 456
//        XCTAssertEqual(boundInt.wrappedValue, 456)
//        XCTAssertEqual(object.intCol, 456)
//    }
}
#endif
