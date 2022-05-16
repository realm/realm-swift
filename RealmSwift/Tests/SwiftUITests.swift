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

#if !(os(iOS) && (arch(i386) || arch(arm)))
import XCTest
import RealmSwift
import SwiftUI
import Combine

class SwiftUIObject: Object, ObjectKeyIdentifiable {
    @Persisted var list: RealmSwift.List<SwiftBoolObject>
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
class SwiftUITests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        if hasSwiftUI() {
            return super.defaultTestSuite
        }
        return XCTestSuite(name: "\(type(of: self))")
    }

    // MARK: - List Operations

    func testManagedUnmanagedListAppendPrimitive() throws {
        let object = SwiftUIObject()
        let state = StateRealmObject(wrappedValue: object.primitiveList)
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.append(1)
        XCTAssertEqual(state.wrappedValue.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.projectedValue.append(2)
        XCTAssertEqual(state.wrappedValue.count, 2)
    }
    func testManagedUnmanagedListAppendUnmanagedObject() throws {
        let object = SwiftUIObject()
        let state = StateRealmObject(wrappedValue: object.list)
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.append(SwiftBoolObject())
        XCTAssertEqual(state.wrappedValue.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.projectedValue.append(SwiftBoolObject())
        XCTAssertEqual(state.wrappedValue.count, 2)
    }
    func testManagedListAppendUnmanagedObservedObject() throws {
        let object = SwiftUIObject()
        var state = StateRealmObject(wrappedValue: object.list)
        XCTAssertEqual(state.wrappedValue.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.update()
        state.projectedValue.append(SwiftBoolObject())
        XCTAssertEqual(state.wrappedValue.count, 1)
    }
    func testManagedListAppendFrozenObject() throws {
        let listObj = SwiftUIObject()
        var state = StateRealmObject(wrappedValue: listObj.list)
        XCTAssertEqual(state.wrappedValue.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        let obj = SwiftBoolObject()
        try realm.write {
            realm.add(listObj)
            realm.add(obj)
        }
        let frozen = obj.freeze()

        state.update()
        state.projectedValue.append(frozen)
        XCTAssertEqual(state.wrappedValue.count, 1)
    }
    func testManagedUnmanagedListRemovePrimitive() throws {
        let object = SwiftUIObject()
        let state = StateRealmObject(wrappedValue: object.primitiveList)
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.append(1)
        XCTAssertEqual(state.wrappedValue.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.projectedValue.append(2)
        XCTAssertEqual(state.wrappedValue.count, 2)

        state.projectedValue.remove(at: 0)
        XCTAssertEqual(state.wrappedValue[0], 2)
        XCTAssertEqual(state.wrappedValue.count, 1)
    }
    func testManagedUnmanagedListRemoveUnmanagedObject() throws {
        let object = SwiftUIObject()
        let state = StateRealmObject(wrappedValue: object.list)
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.append(SwiftBoolObject())
        XCTAssertEqual(state.wrappedValue.count, 1)
        state.projectedValue.remove(at: 0)
        XCTAssertEqual(state.wrappedValue.count, 0)
    }

    func testManagedListAppendRemoveObservedObject() throws {
        let object = SwiftUIObject()
        var state = StateRealmObject(wrappedValue: object.list)
        XCTAssertEqual(state.wrappedValue.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.update()
        state.projectedValue.append(SwiftBoolObject())
        XCTAssertEqual(state.wrappedValue.count, 1)

        state.projectedValue.remove(at: 0)
        XCTAssertEqual(state.wrappedValue.count, 0)
    }

    // MARK: - MutableSet Operations

    func testManagedUnmanagedMutableSetInsertPrimitive() throws {
        let object = SwiftUIObject()
        let state = StateRealmObject(wrappedValue: object.primitiveSet)
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.insert(1)
        XCTAssertEqual(state.wrappedValue.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.projectedValue.insert(2)
        XCTAssertEqual(state.wrappedValue.count, 2)
    }
    func testManagedUnmanagedMutableSetInsertUnmanagedObject() throws {
        let object = SwiftUIObject()
        let state = StateRealmObject(wrappedValue: object.set)
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.insert(SwiftBoolObject())
        XCTAssertEqual(state.wrappedValue.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.projectedValue.insert(SwiftBoolObject())
        XCTAssertEqual(state.wrappedValue.count, 2)
    }
    func testManagedMutableSetInsertUnmanagedObservedObject() throws {
        let object = SwiftUIObject()
        var state = StateRealmObject(wrappedValue: object.set)
        XCTAssertEqual(state.wrappedValue.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.update()
        state.projectedValue.insert(SwiftBoolObject())
        XCTAssertEqual(state.wrappedValue.count, 1)
    }
    func testManagedMutableSetInsertFrozenObject() throws {
        let object = SwiftUIObject()
        var state = StateRealmObject(wrappedValue: object.set)
        XCTAssertEqual(state.wrappedValue.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        let obj = SwiftBoolObject()
        try realm.write {
            realm.add(object)
            realm.add(obj)
        }
        let frozen = obj.freeze()
        state.update()
        state.projectedValue.insert(frozen)
        XCTAssertEqual(state.wrappedValue.count, 1)
    }
    func testMutableSetRemovePrimitive() throws {
        let object = SwiftUIObject()
        let state = StateRealmObject(wrappedValue: object.primitiveSet)
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.insert(1)
        XCTAssertEqual(state.wrappedValue.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.projectedValue.insert(2)
        XCTAssertEqual(state.wrappedValue.count, 2)

        state.projectedValue.remove(1)
        XCTAssertEqual(state.wrappedValue.count, 1)
    }
    func testUnmanagedMutableSetRemoveUnmanagedObject() throws {
        let object = SwiftUIObject()
        let state = StateRealmObject(wrappedValue: object.set)
        XCTAssertEqual(state.wrappedValue.count, 0)
        let obj = SwiftBoolObject()
        state.projectedValue.insert(obj)
        XCTAssertEqual(state.wrappedValue.count, 1)
        state.projectedValue.remove(obj)
        XCTAssertEqual(state.wrappedValue.count, 0)
    }
    func testManagedMutableSetRemoveUnmanagedObject() throws {
        let object = SwiftUIObject()
        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }
        let state = StateRealmObject(wrappedValue: object.set)
        XCTAssertEqual(state.wrappedValue.count, 0)
        let obj = SwiftBoolObject()
        state.projectedValue.insert(obj)
        XCTAssertEqual(state.wrappedValue.count, 1)
        XCTAssertNotNil(obj.realm)
        state.projectedValue.remove(obj)
        XCTAssertEqual(state.wrappedValue.count, 0)
    }

    func testManagedMutableSetRemoveObservedObject() throws {
        let object = SwiftUIObject()
        var state = StateRealmObject(wrappedValue: object.set)
        XCTAssertEqual(state.wrappedValue.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.update()
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
        state.projectedValue.insert(objState.wrappedValue)
        XCTAssertEqual(state.wrappedValue.count, 1)
        state.projectedValue.remove(objState.wrappedValue)
        XCTAssertEqual(state.wrappedValue.count, 0)
        cancellable.cancel()
    }

    // MARK: - Map Operations

    func testManagedUnmanagedMapAppendPrimitive() throws {
        let object = SwiftUIObject()
        let state = StateRealmObject(wrappedValue: object.primitiveMap)
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.set(object: 1, for: "one")
        XCTAssertEqual(state.wrappedValue.count, 1)
        XCTAssertEqual(state.projectedValue["one"], 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.projectedValue.set(object: 2, for: "two")
        state.projectedValue.set(object: 3, for: "two")
        XCTAssertEqual(state.wrappedValue.count, 2)
        XCTAssertEqual(state.projectedValue["two"], 3)
    }

    func testManagedUnmanagedMapAppendUnmanagedObject() throws {
        let object = SwiftUIObject()
        let state = StateRealmObject(wrappedValue: object.map)
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.set(object: SwiftBoolObject(), for: "one")
        XCTAssertEqual(state.wrappedValue.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.projectedValue.set(object: SwiftBoolObject(), for: "two")
        XCTAssertEqual(state.wrappedValue.count, 2)
    }

    func testManagedMapAppendUnmanagedObservedObject() throws {
        let object = SwiftUIObject()
        var state = StateRealmObject(wrappedValue: object.map)
        XCTAssertEqual(state.wrappedValue.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.update()
        state.projectedValue.set(object: SwiftBoolObject(), for: "one")
        XCTAssertEqual(state.wrappedValue.count, 1)
    }

    func testManagedUnmanagedMapRemovePrimitive() throws {
        let object = SwiftUIObject()
        let state = StateRealmObject(wrappedValue: object.primitiveMap)
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.set(object: 1, for: "one")
        XCTAssertEqual(state.wrappedValue.count, 1)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.projectedValue.set(object: 2, for: "two")
        XCTAssertEqual(state.wrappedValue.count, 2)

        state.projectedValue.set(object: nil, for: "one")
        XCTAssertEqual(state.wrappedValue.count, 1)
        XCTAssertEqual(state.wrappedValue.keys, ["two"])
    }

    func testManagedUnmanagedMapRemoveUnmanagedObject() throws {
        let object = SwiftUIObject()
        let state = StateRealmObject(wrappedValue: object.map)
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.set(object: SwiftBoolObject(), for: "one")
        XCTAssertEqual(state.wrappedValue.count, 1)
        state.projectedValue.set(object: nil, for: "one")
        XCTAssertEqual(state.wrappedValue.count, 0)
    }

    func testManagedMapAppendRemoveObservedObject() throws {
        let object = SwiftUIObject()
        var state = StateRealmObject(wrappedValue: object.map)
        XCTAssertEqual(state.wrappedValue.count, 0)

        let realm = inMemoryRealm(inMemoryIdentifier)
        try realm.write { realm.add(object) }

        state.update()
        state.projectedValue.set(object: SwiftBoolObject(), for: "one")
        XCTAssertEqual(state.wrappedValue.count, 1)

        state.projectedValue.set(object: nil, for: "one")
        XCTAssertEqual(state.wrappedValue.count, 0)
    }

    // MARK: - ObservedResults Operations
    func testResultsAppendUnmanagedObject() throws {
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
    func testResultsAppendManagedObject() throws {
        let state = ObservedResults(SwiftUIObject.self, configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        let object = SwiftUIObject()
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.append(object)
        XCTAssertEqual(state.wrappedValue.count, 1)
        state.projectedValue.append(object)
        XCTAssertEqual(state.wrappedValue.count, 1)
    }
    func testResultsRemoveUnmanagedObject() throws {
        let state = ObservedResults(SwiftUIObject.self,
                                    configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        let object = SwiftUIObject()
        XCTAssertEqual(state.wrappedValue.count, 0)
        assertThrows(state.projectedValue.remove(object))
        XCTAssertEqual(state.wrappedValue.count, 0)
    }
    func testResultsRemoveManagedObject() throws {
        let state = ObservedResults(SwiftUIObject.self,
                                    configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        let object = SwiftUIObject()
        XCTAssertEqual(state.wrappedValue.count, 0)
        state.projectedValue.append(object)
        XCTAssertEqual(state.wrappedValue.count, 1)
        state.projectedValue.remove(object)
        XCTAssertEqual(state.wrappedValue.count, 0)
    }
    func testSwiftQuerySyntax() throws {
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
    func testResultsAppendFrozenObject() throws {
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
    func testUnmanagedObjectModification() throws {
        let state = StateRealmObject(wrappedValue: SwiftUIObject())
        state.wrappedValue.str = "bar"
        XCTAssertEqual(state.wrappedValue.str, "bar")
        XCTAssertEqual(state.projectedValue.wrappedValue.str, "bar")
    }
    func testManagedObjectModification() throws {
        let state = StateRealmObject(wrappedValue: SwiftUIObject())
        ObservedResults(SwiftUIObject.self,
                        configuration: inMemoryRealm(inMemoryIdentifier).configuration)
            .projectedValue.append(state.wrappedValue)
        assertThrows(state.wrappedValue.str = "bar")
        state.projectedValue.str.wrappedValue = "bar"
        XCTAssertEqual(state.projectedValue.wrappedValue.str, "bar")
    }
    func testManagedObjectDelete() throws {
        let results = ObservedResults(SwiftUIObject.self,
                                      configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        let state = StateRealmObject(wrappedValue: SwiftUIObject())
        XCTAssertEqual(results.wrappedValue.count, 0)
        state.projectedValue.delete()
        XCTAssertEqual(results.wrappedValue.count, 0)
        results.projectedValue.append(state.wrappedValue)
        XCTAssertEqual(results.wrappedValue.count, 1)
        state.projectedValue.delete()
    }
    // MARK: Bind
    func testUnmanagedManagedObjectBind() {
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

    func testStateRealmObjectKVO() throws {
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
    func testResultsAppendProjection() throws {
        let realm = inMemoryRealm(inMemoryIdentifier)
        let state = ObservedResults(UIElementsProjection.self,
                                    configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        XCTAssertEqual(state.wrappedValue.count, 0)
        try! realm.write {
            realm.create(SwiftUIObject.self)
        }
        XCTAssertEqual(state.wrappedValue.count, 1)
    }

    func testResultsRemoveProjection() throws {
        let realm = inMemoryRealm(inMemoryIdentifier)
        let state = ObservedResults(UIElementsProjection.self,
                                    configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        var object: SwiftUIObject!
        try! realm.write {
            object = realm.create(SwiftUIObject.self)
        }
        XCTAssertEqual(state.wrappedValue.count, 1)
        try! realm.write {
            realm.delete(object)
        }
        XCTAssertEqual(state.wrappedValue.count, 0)
    }

    func testProjectionStateRealmObjectKVO() throws {
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

    func testProjectionDelete() throws {
        let results = ObservedResults(UIElementsProjection.self,
                                      configuration: inMemoryRealm(inMemoryIdentifier).configuration)
        let projection = UIElementsProjection(projecting: SwiftUIObject())
        let state = StateRealmObject(wrappedValue: projection)

        XCTAssertEqual(results.wrappedValue.count, 0)
        state.projectedValue.delete()
        XCTAssertEqual(results.wrappedValue.count, 0)
        results.projectedValue.append(state.wrappedValue)
        XCTAssertEqual(results.wrappedValue.count, 1)
        state.projectedValue.delete()
    }

    // MARK: - Projection Bind
    func testProjectionBind() {
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
}
#endif
