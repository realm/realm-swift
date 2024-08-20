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
import Combine

class SwiftUIObject: Object, ObjectKeyIdentifiable {
    @Persisted var list: RealmSwift.List<SwiftBoolObject>
    @Persisted var stringList: RealmSwift.List<SwiftStringObject>
    @Persisted var set: RealmSwift.MutableSet<SwiftBoolObject>
    @Persisted var map: Map<String, SwiftBoolObject?>
    @Persisted var primitiveList: RealmSwift.List<Int>
    @Persisted var primitiveSet: RealmSwift.MutableSet<Int>
    @Persisted var primitiveMap: Map<String, Int>
    @Persisted var str = "foo"
    @Persisted var int = 0

    convenience init(str: String = "foo") {
        self.init()
        self.str = str
    }
}

class UIElementsProjection: Projection<SwiftUIObject>, ObjectKeyIdentifiable {
    @Projected(\SwiftUIObject.str) var label
    @Projected(\SwiftUIObject.int) var counter
}

class EmbeddedTreeSwiftUIObject1: EmbeddedObject, EmbeddedTreeObject, ObjectKeyIdentifiable {
    @objc dynamic var value = 0
    @objc dynamic var child: EmbeddedTreeObject2?
    let children = RealmSwift.List<EmbeddedTreeObject2>()
}

private let inMemoryIdentifier = "swiftui-tests"

func hasSwiftUI() -> Bool {
    if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
        return true
    }
    return false
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
class SwiftUITests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        if hasSwiftUI() {
            return super.defaultTestSuite
        }
        return XCTestSuite(name: "\(type(of: self))")
    }

    // MARK: - List Operations

    @MainActor func testManagedUnmanagedListAppendPrimitive() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.primitiveList
        XCTAssertEqual(state.count, 0)
        $state.append(1)
        XCTAssertEqual(state.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        $state.append(2)
        XCTAssertEqual(state.count, 2)
    }

    @MainActor func testManagedUnmanagedListAppendUnmanagedObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.list
        XCTAssertEqual(state.count, 0)
        $state.append(SwiftBoolObject())
        XCTAssertEqual(state.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        $state.append(SwiftBoolObject())
        XCTAssertEqual(state.count, 2)
    }

    @MainActor func testManagedListAppendUnmanagedObservedObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.list
        XCTAssertEqual(state.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        _state.update()
        $state.append(SwiftBoolObject())
        XCTAssertEqual(state.count, 1)
    }

    @MainActor func testManagedListAppendFrozenObject() throws {
        let listObj = SwiftUIObject()
        @StateRealmObject var state = listObj.list
        XCTAssertEqual(state.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        let obj = SwiftBoolObject()
        try realm.write {
            realm.add(listObj)
            realm.add(obj)
        }
        let frozen = obj.freeze()

        _state.update()
        $state.append(frozen)
        XCTAssertEqual(state.count, 1)
    }

    @MainActor func testManagedUnmanagedListRemovePrimitive() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.primitiveList
        XCTAssertEqual(state.count, 0)
        $state.append(1)
        XCTAssertEqual(state.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        $state.append(2)
        XCTAssertEqual(state.count, 2)

        $state.remove(at: 0)
        XCTAssertEqual(state[0], 2)
        XCTAssertEqual(state.count, 1)
    }

    @MainActor func testManagedUnmanagedListRemoveUnmanagedObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.list
        XCTAssertEqual(state.count, 0)
        $state.append(SwiftBoolObject())
        XCTAssertEqual(state.count, 1)
        $state.remove(at: 0)
        XCTAssertEqual(state.count, 0)
    }

    @MainActor func testManagedListAppendRemoveObservedObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.list
        XCTAssertEqual(state.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        _state.update()
        $state.append(SwiftBoolObject())
        XCTAssertEqual(state.count, 1)

        $state.remove(at: 0)
        XCTAssertEqual(state.count, 0)
    }

    // MARK: - MutableSet Operations

    @MainActor func testManagedUnmanagedMutableSetInsertPrimitive() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.primitiveSet
        XCTAssertEqual(state.count, 0)
        $state.insert(1)
        XCTAssertEqual(state.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        $state.insert(2)
        XCTAssertEqual(state.count, 2)
    }
    @MainActor func testManagedUnmanagedMutableSetInsertUnmanagedObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.set
        XCTAssertEqual(state.count, 0)
        $state.insert(SwiftBoolObject())
        XCTAssertEqual(state.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        $state.insert(SwiftBoolObject())
        XCTAssertEqual(state.count, 2)
    }
    @MainActor func testManagedMutableSetInsertUnmanagedObservedObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.set
        XCTAssertEqual(state.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        _state.update()
        $state.insert(SwiftBoolObject())
        XCTAssertEqual(state.count, 1)
    }
    @MainActor func testManagedMutableSetInsertFrozenObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.set
        XCTAssertEqual(state.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        let obj = SwiftBoolObject()
        try realm.write {
            realm.add(object)
            realm.add(obj)
        }
        let frozen = obj.freeze()
        _state.update()
        $state.insert(frozen)
        XCTAssertEqual(state.count, 1)
    }
    @MainActor func testMutableSetRemovePrimitive() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.primitiveSet
        XCTAssertEqual(state.count, 0)
        $state.insert(1)
        XCTAssertEqual(state.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        $state.insert(2)
        XCTAssertEqual(state.count, 2)

        $state.remove(1)
        XCTAssertEqual(state.count, 1)
    }
    @MainActor func testUnmanagedMutableSetRemoveUnmanagedObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.set
        XCTAssertEqual(state.count, 0)
        let obj = SwiftBoolObject()
        $state.insert(obj)
        XCTAssertEqual(state.count, 1)
        $state.remove(obj)
        XCTAssertEqual(state.count, 0)
    }
    @MainActor func testManagedMutableSetRemoveUnmanagedObject() throws {
        let object = SwiftUIObject()
        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }
        @StateRealmObject var state = object.set
        XCTAssertEqual(state.count, 0)
        let obj = SwiftBoolObject()
        $state.insert(obj)
        XCTAssertEqual(state.count, 1)
        XCTAssertNotNil(obj.realm)
        $state.remove(obj)
        XCTAssertEqual(state.count, 0)
    }

    @MainActor func testManagedMutableSetRemoveObservedObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.set
        XCTAssertEqual(state.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        _state.update()
        let obj = SwiftBoolObject()
        let objState = StateRealmObject(wrappedValue: obj)

        var hit = 0
        // This will append an observer to SwiftUIKVO
        let cancellable = objState._publisher
            .sink { _ in
            } receiveValue: { _ in
                hit += 1
            }
        objState.wrappedValue.boolCol = true
        XCTAssertEqual(hit, 1)
        $state.insert(objState.wrappedValue)
        XCTAssertEqual(state.count, 1)
        $state.remove(objState.wrappedValue)
        XCTAssertEqual(state.count, 0)
        cancellable.cancel()
    }

    // MARK: - Map Operations

    @MainActor func testManagedUnmanagedMapAppendPrimitive() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.primitiveMap
        XCTAssertEqual(state.count, 0)
        $state.set(object: 1, for: "one")
        XCTAssertEqual(state.count, 1)
        XCTAssertEqual($state["one"], 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        $state.set(object: 2, for: "two")
        $state.set(object: 3, for: "two")
        XCTAssertEqual(state.count, 2)
        XCTAssertEqual($state["two"], 3)
    }

    @MainActor func testManagedUnmanagedMapAppendUnmanagedObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.map
        XCTAssertEqual(state.count, 0)
        $state.set(object: SwiftBoolObject(), for: "one")
        XCTAssertEqual(state.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        $state.set(object: SwiftBoolObject(), for: "two")
        XCTAssertEqual(state.count, 2)
    }

    @MainActor func testManagedMapAppendUnmanagedObservedObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.map
        XCTAssertEqual(state.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        _state.update()
        $state.set(object: SwiftBoolObject(), for: "one")
        XCTAssertEqual(state.count, 1)
    }

    @MainActor func testManagedUnmanagedMapRemovePrimitive() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.primitiveMap
        XCTAssertEqual(state.count, 0)
        $state.set(object: 1, for: "one")
        XCTAssertEqual(state.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        $state.set(object: 2, for: "two")
        XCTAssertEqual(state.count, 2)

        $state.set(object: nil, for: "one")
        XCTAssertEqual(state.count, 1)
        XCTAssertEqual(state.keys, ["two"])
    }

    @MainActor func testManagedUnmanagedMapRemoveUnmanagedObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.map
        XCTAssertEqual(state.count, 0)
        $state.set(object: SwiftBoolObject(), for: "one")
        XCTAssertEqual(state.count, 1)
        $state.set(object: nil, for: "one")
        XCTAssertEqual(state.count, 0)
    }

    @MainActor func testManagedMapAppendRemoveObservedObject() throws {
        let object = SwiftUIObject()
        @StateRealmObject var state = object.map
        XCTAssertEqual(state.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        _state.update()
        $state.set(object: SwiftBoolObject(), for: "one")
        XCTAssertEqual(state.count, 1)

        $state.set(object: nil, for: "one")
        XCTAssertEqual(state.count, 0)
    }

    // MARK: - ObservedResults Operations
    @MainActor func testResultsAppendUnmanagedObject() throws {
        let object = SwiftUIObject()
        let fullResults = ObservedResults(SwiftUIObject.self,
                                          configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(fullResults.wrappedValue.count, 0)
        fullResults.projectedValue.append(object)
        XCTAssertEqual(fullResults.wrappedValue.count, 1)
        let realm = inMemoryRealm(inMemoryIdentifier)
        realm.beginWrite()
        object.str = "abc"
        object.int = 1
        // add another default inited object for filter comparison
        realm.add(SwiftUIObject())
        try realm.commitWrite()
        let filteredResults = ObservedResults(SwiftUIObject.self,
                                              configuration: inMemoryRealm(inMemoryIdentifier).configuration,
                                              filter: NSPredicate(format: "str = %@", "abc"))
        XCTAssertEqual(fullResults.wrappedValue.count, 2)
        XCTAssertEqual(filteredResults.wrappedValue.count, 1)
        var sortedResults = ObservedResults(SwiftUIObject.self,
                                            configuration: inMemoryRealm(inMemoryIdentifier).configuration,
                                            filter: NSPredicate(format: "int >= 0"),
                                            sortDescriptor: SortDescriptor(keyPath: "int", ascending: true))
        XCTAssertEqual(sortedResults.wrappedValue.count, 2)
        XCTAssertEqual(sortedResults.wrappedValue[0].int, 0)
        XCTAssertEqual(sortedResults.wrappedValue[1].int, 1)
        sortedResults = ObservedResults(SwiftUIObject.self,
                                        configuration: inMemoryRealm(inMemoryIdentifier).configuration,
                                        filter: NSPredicate(format: "int >= 0"),
                                        sortDescriptor: SortDescriptor(keyPath: "int", ascending: false))
        XCTAssertEqual(sortedResults.wrappedValue.count, 2)
        XCTAssertEqual(sortedResults.wrappedValue[0].int, 1)
        XCTAssertEqual(sortedResults.wrappedValue[1].int, 0)
    }
    @MainActor func testResultsAppendManagedObject() throws {
        @ObservedResults(SwiftUIObject.self, configuration: inMemoryRealm(inMemoryIdentifier).configuration) var state
        let object = SwiftUIObject()
        XCTAssertEqual(state.count, 0)
        $state.append(object)
        XCTAssertEqual(state.count, 1)
        $state.append(object)
        XCTAssertEqual(state.count, 1)
    }
    @MainActor func testResultsRemoveUnmanagedObject() throws {
        @ObservedResults(SwiftUIObject.self, configuration: inMemoryRealm(inMemoryIdentifier).configuration) var state
        let object = SwiftUIObject()
        XCTAssertEqual(state.count, 0)
        assertThrows($state.remove(object))
        XCTAssertEqual(state.count, 0)
    }
    @MainActor func testResultsRemoveManagedObject() throws {
        @ObservedResults(SwiftUIObject.self, configuration: inMemoryRealm(inMemoryIdentifier).configuration) var state
        let object = SwiftUIObject()
        XCTAssertEqual(state.count, 0)
        $state.append(object)
        XCTAssertEqual(state.count, 1)
        $state.remove(object)
        XCTAssertEqual(state.count, 0)
    }
    @MainActor func testResultsMoveUnmanagedObject() throws {
        @ObservedResults(SwiftUIObject.self, configuration: inMemoryRealm(inMemoryIdentifier).configuration) var state
        let object = SwiftUIObject()
        XCTAssertEqual(state.count, 0)

        object.stringList.append(SwiftStringObject(stringCol: "Tom"))
        object.stringList.append(SwiftStringObject(stringCol: "Sam"))
        object.stringList.append(SwiftStringObject(stringCol: "Dan"))
        object.stringList.append(SwiftStringObject(stringCol: "Paul"))

        let binding = object.bind(\.stringList)
        XCTAssertEqual(object.stringList.first!.stringCol, "Tom")
        XCTAssertEqual(object.stringList[1].stringCol, "Sam")
        XCTAssertEqual(object.stringList[2].stringCol, "Dan")
        XCTAssertEqual(object.stringList.last!.stringCol, "Paul")

        binding.move(fromOffsets: IndexSet([0]), toOffset: 3)
        XCTAssertEqual(object.stringList.first!.stringCol, "Sam")
        XCTAssertEqual(object.stringList[1].stringCol, "Dan")
        XCTAssertEqual(object.stringList[2].stringCol, "Tom")
        XCTAssertEqual(object.stringList.last!.stringCol, "Paul")

        binding.move(fromOffsets: IndexSet([2]), toOffset: 4)
        XCTAssertEqual(object.stringList.first!.stringCol, "Sam")
        XCTAssertEqual(object.stringList[1].stringCol, "Dan")
        XCTAssertEqual(object.stringList[2].stringCol, "Paul")
        XCTAssertEqual(object.stringList.last!.stringCol, "Tom")

        binding.move(fromOffsets: IndexSet([3]), toOffset: 0)
        XCTAssertEqual(object.stringList.first!.stringCol, "Tom")
        XCTAssertEqual(object.stringList[1].stringCol, "Sam")
        XCTAssertEqual(object.stringList[2].stringCol, "Dan")
        XCTAssertEqual(object.stringList.last!.stringCol, "Paul")

        XCTAssertEqual(state.count, 0)
    }
    @MainActor func testResultsMoveManagedObject() throws {
        @ObservedResults(SwiftUIObject.self, configuration: inMemoryRealm(inMemoryIdentifier).configuration) var state
        let object = SwiftUIObject()
        XCTAssertEqual(state.count, 0)

        object.stringList.append(SwiftStringObject(stringCol: "Tom"))
        object.stringList.append(SwiftStringObject(stringCol: "Sam"))
        object.stringList.append(SwiftStringObject(stringCol: "Dan"))
        object.stringList.append(SwiftStringObject(stringCol: "Paul"))

        $state.append(object)

        let binding = object.bind(\.stringList)
        XCTAssertEqual(object.stringList.first!.stringCol, "Tom")
        XCTAssertEqual(object.stringList[1].stringCol, "Sam")
        XCTAssertEqual(object.stringList[2].stringCol, "Dan")
        XCTAssertEqual(object.stringList.last!.stringCol, "Paul")

        binding.move(fromOffsets: IndexSet([0]), toOffset: 3)
        XCTAssertEqual(object.stringList.first!.stringCol, "Sam")
        XCTAssertEqual(object.stringList[1].stringCol, "Dan")
        XCTAssertEqual(object.stringList[2].stringCol, "Tom")
        XCTAssertEqual(object.stringList.last!.stringCol, "Paul")

        binding.move(fromOffsets: IndexSet([2]), toOffset: 4)
        XCTAssertEqual(object.stringList.first!.stringCol, "Sam")
        XCTAssertEqual(object.stringList[1].stringCol, "Dan")
        XCTAssertEqual(object.stringList[2].stringCol, "Paul")
        XCTAssertEqual(object.stringList.last!.stringCol, "Tom")

        binding.move(fromOffsets: IndexSet([3]), toOffset: 0)
        XCTAssertEqual(object.stringList.first!.stringCol, "Tom")
        XCTAssertEqual(object.stringList[1].stringCol, "Sam")
        XCTAssertEqual(object.stringList[2].stringCol, "Dan")
        XCTAssertEqual(object.stringList.last!.stringCol, "Paul")

        XCTAssertEqual(state.count, 1)
    }
    @MainActor func testSwiftQuerySyntax() throws {
        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write {
            realm.add(SwiftUIObject(value: ["str": "apple"]))
            realm.add(SwiftUIObject(value: ["str": "antenna"]))
            realm.add(SwiftUIObject(value: ["str": "baz"]))
        }

        let filteredResults = ObservedResults(SwiftUIObject.self,
                                              configuration: realm.configuration,
                                              where: { $0.str.starts(with: "a") },
                                              sortDescriptor: SortDescriptor.init(keyPath: \SwiftUIObject.str, ascending: true))
        XCTAssertEqual(filteredResults.wrappedValue.count, 2)
        XCTAssertEqual(filteredResults.wrappedValue[0].str, "antenna")
    }
    @MainActor func testResultsAppendFrozenObject() throws {
        let state1 = ObservedResults(SwiftUIObject.self, configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        let object1 = SwiftUIObject()
        XCTAssertEqual(state1.wrappedValue.count, 0)
        state1.projectedValue.append(object1)
        XCTAssertEqual(state1.wrappedValue.count, 1)
        state1.projectedValue.append(object1)
        XCTAssertEqual(state1.wrappedValue.count, 1)
        let state2 = ObservedResults(SwiftUIObject.self, configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        for item in state1.wrappedValue {
            XCTAssert(item.isFrozen)
            state2.append(item)
        }
        XCTAssertEqual(state1.wrappedValue.count, 1)
        let realm = inMemoryRealm(inMemoryIdentifier)
        let object2 = SwiftUIObject()
        try! realm.write {
            realm.add(object2)
        }
        let frozenObj = object2.freeze()
        state2.append(frozenObj)
        XCTAssertEqual(state1.wrappedValue.count, 2)
        XCTAssertEqual(state2.wrappedValue.count, 2)
    }
    // MARK: Object Operations
    @MainActor func testUnmanagedObjectModification() throws {
        @StateRealmObject var state = SwiftUIObject()
        state.str = "bar"
        XCTAssertEqual(state.str, "bar")
        XCTAssertEqual($state.wrappedValue.str, "bar")
    }
    @MainActor func testManagedObjectModification() throws {
        @StateRealmObject var state = SwiftUIObject()
        ObservedResults(SwiftUIObject.self,
                        configuration: inMemoryRealm(inMemoryIdentifier).configuration)
            .projectedValue.append(state)
        assertThrows(state.str = "bar")
        $state.str.wrappedValue = "bar"
        XCTAssertEqual($state.wrappedValue.str, "bar")
    }
    @MainActor func testManagedObjectDelete() throws {
        let results = ObservedResults(SwiftUIObject.self,
                                      configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        @StateRealmObject var state = SwiftUIObject()
        XCTAssertEqual(results.wrappedValue.count, 0)
        $state.delete()
        XCTAssertEqual(results.wrappedValue.count, 0)
        results.projectedValue.append(state)
        XCTAssertEqual(results.wrappedValue.count, 1)
        $state.delete()
    }
    // MARK: Bind
    @MainActor func testUnmanagedManagedObjectBind() {
        let object = SwiftUIObject()
        let binding = object.bind(\.str)
        XCTAssertEqual(object.str, "foo")
        XCTAssertEqual(binding.wrappedValue, "foo")
        binding.wrappedValue = "bar"
        XCTAssertEqual(binding.wrappedValue, "bar")

        let realm = inMemoryRealm(inMemoryIdentifier)
        try? realm.write { realm.add(object) }

        let managedBinding = object.bind(\.str)
        XCTAssertEqual(object.str, "bar")
        XCTAssertEqual(binding.wrappedValue, "bar")
        managedBinding.wrappedValue = "baz"
        XCTAssertEqual(object.str, "baz")
        XCTAssertEqual(binding.wrappedValue, "baz")
    }

    @MainActor func testStateRealmObjectKVO() throws {
        @StateRealmObject var object = SwiftUIObject()
        var hit = 0

        let cancellable = _object._publisher
            .sink { _ in
            } receiveValue: { _ in
                hit += 1
            }
        XCTAssertEqual(hit, 0)
        object.int += 1
        XCTAssertEqual(hit, 1)
        XCTAssertNotNil(object.observationInfo)
        let realm = try Realm()
        try realm.write {
            realm.add(object)
        }
        XCTAssertEqual(hit, 1)
        XCTAssertNil(object.observationInfo)
        try realm.write {
            object.thaw()!.int += 1
        }
        XCTAssertEqual(hit, 2)
        cancellable.cancel()
        XCTAssertEqual(hit, 2)
    }

    // MARK: - Projection ObservedResults Operations
    @MainActor func testResultsAppendProjection() throws {
        let realm = inMemoryRealm(inMemoryIdentifier)
        @ObservedResults(UIElementsProjection.self, configuration: inMemoryRealm(inMemoryIdentifier).configuration) var state
        XCTAssertEqual(state.count, 0)
        try! realm.write {
            realm.create(SwiftUIObject.self)
        }
        XCTAssertEqual(state.count, 1)
    }

    @MainActor func testResultsRemoveProjection() throws {
        let realm = inMemoryRealm(inMemoryIdentifier)
        @ObservedResults(UIElementsProjection.self, configuration: inMemoryRealm(inMemoryIdentifier).configuration) var state
        var object: SwiftUIObject!
        try! realm.write {
            object = realm.create(SwiftUIObject.self)
        }
        XCTAssertEqual(state.count, 1)
        try! realm.write {
            realm.delete(object)
        }
        XCTAssertEqual(state.count, 0)
    }

    @MainActor func testProjectionStateRealmObjectKVO() throws {
        @StateRealmObject var projection = UIElementsProjection(projecting: SwiftUIObject())
        var hit = 0

        let cancellable = _projection._publisher
            .sink { _ in
            } receiveValue: { _ in
                hit += 1
            }
        XCTAssertEqual(hit, 0)
        projection.counter += 1
        XCTAssertEqual(hit, 1)
        XCTAssertNotNil(projection.rootObject.observationInfo)
        let realm = try Realm()
        try realm.write {
            realm.add(projection.rootObject)
        }
        XCTAssertEqual(hit, 1)
        XCTAssertNil(projection.rootObject.observationInfo)
        try realm.write {
            projection.thaw()!.counter += 1
        }
        XCTAssertEqual(hit, 2)
        cancellable.cancel()
        XCTAssertEqual(hit, 2)
    }

    @MainActor func testProjectionDelete() throws {
        let results = ObservedResults(UIElementsProjection.self,
                                      configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        let projection = UIElementsProjection(projecting: SwiftUIObject())
        @StateRealmObject var state = projection

        XCTAssertEqual(results.wrappedValue.count, 0)
        $state.delete()
        XCTAssertEqual(results.wrappedValue.count, 0)
        results.projectedValue.append(state)
        XCTAssertEqual(results.wrappedValue.count, 1)
        $state.delete()
    }

    // MARK: - Projection Bind
    @MainActor func testProjectionBind() {
        let projection = UIElementsProjection(projecting: SwiftUIObject())
        let binding = projection.bind(\.label)
        XCTAssertEqual(projection.label, "foo")
        XCTAssertEqual(binding.wrappedValue, "foo")
        binding.wrappedValue = "bar"
        XCTAssertEqual(binding.wrappedValue, "bar")

        let realm = inMemoryRealm(inMemoryIdentifier)
        try? realm.write { realm.add(projection.rootObject) }

        let managedBinding = projection.bind(\.label)
        XCTAssertEqual(projection.label, "bar")
        XCTAssertEqual(binding.wrappedValue, "bar")
        managedBinding.wrappedValue = "baz"
        XCTAssertEqual(projection.label, "baz")
        XCTAssertEqual(binding.wrappedValue, "baz")
    }

    // MARK: - ObservedSectionedResults

    @MainActor func testObservedSectionedResults() throws {
        let fullResults = ObservedSectionedResults(SwiftUIObject.self,
                                                   sectionKeyPath: \.str,
                                                   configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(fullResults.wrappedValue.count, 0)
        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write {
            let object = SwiftUIObject()
            object.str = "abc"
            object.int = 1
            // add another default inited object for filter comparison
            realm.add(object)
        }
        realm.refresh()
        XCTAssertEqual(fullResults.wrappedValue.count, 1)
        XCTAssertEqual(fullResults.wrappedValue[0].key, "abc")

        try realm.write {
            let object = SwiftUIObject()
            object.str = "def"
            object.int = 1
            // add another default inited object for filter comparison
            realm.add(object)
        }

        var filteredResults = ObservedSectionedResults(SwiftUIObject.self,
                                                       sectionKeyPath: \.str,
                                                       filter: NSPredicate(format: "str = %@", "def"),
                                                       configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(filteredResults.wrappedValue.count, 1)
        XCTAssertEqual(filteredResults.wrappedValue[0].key, "def")

        filteredResults = ObservedSectionedResults(SwiftUIObject.self,
                                                   sectionKeyPath: \.str,
                                                   where: { $0.str == "def" },
                                                   configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(filteredResults.wrappedValue.count, 1)
        XCTAssertEqual(filteredResults.wrappedValue[0].key, "def")
        fullResults.where = { $0.str == "def" }
        XCTAssertEqual(fullResults.wrappedValue.count, 1)
        XCTAssertEqual(fullResults.wrappedValue[0].key, "def")
        fullResults.filter = NSPredicate(format: "str != %@", "def")
        XCTAssertEqual(fullResults.wrappedValue.count, 1)
        XCTAssertEqual(fullResults.wrappedValue[0].key, "abc")
    }

    @MainActor func testObservedSectionedResultsWithProjection() throws {
        let fullResults = ObservedSectionedResults(UIElementsProjection.self,
                                                   sectionKeyPath: \.label,
                                                   configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(fullResults.wrappedValue.count, 0)
        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write {
            let object = SwiftUIObject()
            object.str = "abc"
            object.int = 1
            // add another default inited object for filter comparison
            realm.add(object)
        }
        realm.refresh()
        XCTAssertEqual(fullResults.wrappedValue.count, 1)
        XCTAssertEqual(fullResults.wrappedValue[0].key, "abc")

        try realm.write {
            let object = SwiftUIObject()
            object.str = "def"
            object.int = 1
            // add another default inited object for filter comparison
            realm.add(object)
        }

        let filteredResults = ObservedSectionedResults(UIElementsProjection.self,
                                                       sectionKeyPath: \.label,
                                                       filter: NSPredicate(format: "str = %@", "def"),
                                                       configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(filteredResults.wrappedValue.count, 1)
        XCTAssertEqual(filteredResults.wrappedValue[0].key, "def")
    }

    @MainActor func testAllObservedSectionedResultsConstructors() throws {
        let realm = inMemoryRealm(inMemoryIdentifier)
        let object1 = SwiftUIObject()
        let object2 = SwiftUIObject()
        try realm.write {
            object1.str = "foo"
            realm.add(object1)
            object2.str = "bar"
            realm.add(object2)
        }
        // Projections with `sectionKeyPath`
        var projectionSectionedResults = ObservedSectionedResults(UIElementsProjection.self,
                                                                  sectionKeyPath: \.label,
                                                                  configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(projectionSectionedResults.wrappedValue.count, 2)
        XCTAssertEqual(projectionSectionedResults.wrappedValue.allKeys, ["bar", "foo"])
        XCTAssertEqual(projectionSectionedResults.wrappedValue[0].count, 1)
        XCTAssertEqual(projectionSectionedResults.wrappedValue[0][0].label, "bar")
        XCTAssertEqual(projectionSectionedResults.wrappedValue[1].count, 1)
        XCTAssertEqual(projectionSectionedResults.wrappedValue[1][0].label, "foo")

        projectionSectionedResults = ObservedSectionedResults(UIElementsProjection.self,
                                                              sectionKeyPath: \.label,
                                                              sortDescriptors: [SortDescriptor.init(keyPath: "str", ascending: false)],
                                                              configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(projectionSectionedResults.wrappedValue.count, 2)
        XCTAssertEqual(projectionSectionedResults.wrappedValue.allKeys, ["foo", "bar"])
        XCTAssertEqual(projectionSectionedResults.wrappedValue[0].count, 1)
        XCTAssertEqual(projectionSectionedResults.wrappedValue[0][0].label, "foo")
        XCTAssertEqual(projectionSectionedResults.wrappedValue[1].count, 1)
        XCTAssertEqual(projectionSectionedResults.wrappedValue[1][0].label, "bar")

        projectionSectionedResults = ObservedSectionedResults(UIElementsProjection.self,
                                                              sectionKeyPath: \.label,
                                                              sortDescriptors: [SortDescriptor.init(keyPath: "str")],
                                                              filter: NSPredicate(format: "str == 'foo'"),
                                                              configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(projectionSectionedResults.wrappedValue.count, 1)
        XCTAssertEqual(projectionSectionedResults.wrappedValue.allKeys, ["foo"])
        XCTAssertEqual(projectionSectionedResults.wrappedValue[0].count, 1)
        XCTAssertEqual(projectionSectionedResults.wrappedValue[0][0].label, "foo")

        // Projections with `sectionBlock`
        projectionSectionedResults = ObservedSectionedResults(UIElementsProjection.self,
                                                              sectionBlock: { $0.label.first.map(String.init(_:)) ?? "" },
                                                              sortDescriptors: [SortDescriptor.init(keyPath: "str")],
                                                              configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(projectionSectionedResults.wrappedValue.count, 2)
        XCTAssertEqual(projectionSectionedResults.wrappedValue.allKeys, ["b", "f"])
        XCTAssertEqual(projectionSectionedResults.wrappedValue[0].count, 1)
        XCTAssertEqual(projectionSectionedResults.wrappedValue[0][0].label, "bar")
        XCTAssertEqual(projectionSectionedResults.wrappedValue[1].count, 1)
        XCTAssertEqual(projectionSectionedResults.wrappedValue[1][0].label, "foo")

        projectionSectionedResults = ObservedSectionedResults(UIElementsProjection.self,
                                                              sectionBlock: { $0.label.first.map(String.init(_:)) ?? "" },
                                                              sortDescriptors: [SortDescriptor.init(keyPath: "str")],
                                                              filter: NSPredicate(format: "str == 'foo'"),
                                                              configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(projectionSectionedResults.wrappedValue.count, 1)
        XCTAssertEqual(projectionSectionedResults.wrappedValue.allKeys, ["f"])
        XCTAssertEqual(projectionSectionedResults.wrappedValue[0].count, 1)
        XCTAssertEqual(projectionSectionedResults.wrappedValue[0][0].label, "foo")

        // Objects with `sectionKeyPath`
        var objectSectionedResults = ObservedSectionedResults(SwiftUIObject.self,
                                                              sectionKeyPath: \.str,
                                                              configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(objectSectionedResults.wrappedValue.count, 2)
        XCTAssertEqual(objectSectionedResults.wrappedValue.allKeys, ["bar", "foo"])
        XCTAssertEqual(objectSectionedResults.wrappedValue[0].count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue[0][0].str, "bar")
        XCTAssertEqual(objectSectionedResults.wrappedValue[1].count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue[1][0].str, "foo")

        objectSectionedResults = ObservedSectionedResults(SwiftUIObject.self,
                                                          sectionKeyPath: \.str,
                                                          sortDescriptors: [SortDescriptor.init(keyPath: "str", ascending: false)],
                                                          configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(objectSectionedResults.wrappedValue.count, 2)
        XCTAssertEqual(objectSectionedResults.wrappedValue.allKeys, ["foo", "bar"])
        XCTAssertEqual(objectSectionedResults.wrappedValue[0].count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue[0][0].str, "foo")
        XCTAssertEqual(objectSectionedResults.wrappedValue[1].count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue[1][0].str, "bar")

        objectSectionedResults = ObservedSectionedResults(SwiftUIObject.self,
                                                          sectionKeyPath: \.str,
                                                          sortDescriptors: [SortDescriptor.init(keyPath: "str")],
                                                          where: { $0.str == "foo" },
                                                          configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(objectSectionedResults.wrappedValue.count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue.allKeys, ["foo"])
        XCTAssertEqual(objectSectionedResults.wrappedValue[0].count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue[0][0].str, "foo")

        objectSectionedResults = ObservedSectionedResults(SwiftUIObject.self,
                                                          sectionKeyPath: \.str,
                                                          sortDescriptors: [SortDescriptor.init(keyPath: "str")],
                                                          filter: NSPredicate(format: "str == 'foo'"),
                                                          configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(objectSectionedResults.wrappedValue.count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue.allKeys, ["foo"])
        XCTAssertEqual(objectSectionedResults.wrappedValue[0].count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue[0][0].str, "foo")
        // Objects with `sectionBlock`
        objectSectionedResults = ObservedSectionedResults(SwiftUIObject.self,
                                                          sectionBlock: { $0.str.first.map(String.init(_:)) ?? "" },
                                                          sortDescriptors: [SortDescriptor.init(keyPath: "str")],
                                                          configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(objectSectionedResults.wrappedValue.count, 2)
        XCTAssertEqual(objectSectionedResults.wrappedValue.allKeys, ["b", "f"])
        XCTAssertEqual(objectSectionedResults.wrappedValue[0].count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue[0][0].str, "bar")
        XCTAssertEqual(objectSectionedResults.wrappedValue[1].count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue[1][0].str, "foo")

        objectSectionedResults = ObservedSectionedResults(SwiftUIObject.self,
                                                          sectionBlock: { $0.str.first.map(String.init(_:)) ?? "" },
                                                          sortDescriptors: [SortDescriptor.init(keyPath: "str")],
                                                          filter: NSPredicate(format: "str == 'foo'"),
                                                          configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(objectSectionedResults.wrappedValue.count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue.allKeys, ["f"])
        XCTAssertEqual(objectSectionedResults.wrappedValue[0].count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue[0][0].str, "foo")

        objectSectionedResults = ObservedSectionedResults(SwiftUIObject.self,
                                                          sectionBlock: { $0.str.first.map(String.init(_:)) ?? "" },
                                                          sortDescriptors: [SortDescriptor.init(keyPath: "str")],
                                                          where: { $0.str == "foo" },
                                                          configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(objectSectionedResults.wrappedValue.count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue.allKeys, ["f"])
        XCTAssertEqual(objectSectionedResults.wrappedValue[0].count, 1)
        XCTAssertEqual(objectSectionedResults.wrappedValue[0][0].str, "foo")
    }
}
