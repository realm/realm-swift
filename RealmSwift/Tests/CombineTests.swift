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

#if !(os(iOS) && (arch(i386) || arch(arm)))
import XCTest
import Combine
import RealmSwift

class CombineIdentifiableObject: Object, ObjectKeyIdentifiable {
    @objc dynamic var value = 0
    @objc dynamic var child: CombineIdentifiableEmbeddedObject?
}
class CombineIdentifiableEmbeddedObject: EmbeddedObject, ObjectKeyIdentifiable {
    @objc dynamic var value = 0
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension Publisher {
    public func signal(_ semaphore: DispatchSemaphore) -> Publishers.HandleEvents<Self> {
        self.handleEvents(receiveOutput: { _ in semaphore.signal() })
    }
}

// XCTest doesn't care about the @available on the class and will try to run
// the tests even on older versions. Putting this check inside `defaultTestSuite`
// results in a warning about it being redundant due to the enclosing check, so
// it needs to be out of line.
func hasCombine() -> Bool {
    if #available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *) {
        return true
    }
    return false
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
class ObjectIdentifiableTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        if hasCombine() {
            return super.defaultTestSuite
        }
        return XCTestSuite(name: "\(type(of: self))")
    }

    func testUnmanaged() {
        let obj1 = CombineIdentifiableObject(value: [1])
        let obj2 = CombineIdentifiableObject(value: [1])
        let obj3 = CombineIdentifiableObject(value: [2])
        XCTAssertEqual(obj1.id, obj1.id)
        XCTAssertNotEqual(obj1.id, obj2.id)
        XCTAssertNotEqual(obj2.id, obj3.id)
        XCTAssertNotEqual(obj1.id, obj3.id)
    }

    func testManagedTopLevel() {
        let realm = try! Realm()
        let (obj1, obj2) = try! realm.write {
            return (
                realm.create(CombineIdentifiableObject.self, value: [1]),
                realm.create(CombineIdentifiableObject.self, value: [2])
            )
        }
        XCTAssertEqual(obj1.id, obj1.id)
        XCTAssertNotEqual(obj1.id, obj2.id)
        XCTAssertEqual(obj1.id, realm.objects(CombineIdentifiableObject.self).first!.id)
        XCTAssertEqual(obj2.id, realm.objects(CombineIdentifiableObject.self).last!.id)
    }

    func testManagedEmbedded() {
        let realm = try! Realm()
        let (obj1, obj2) = try! realm.write {
            return (
                realm.create(CombineIdentifiableObject.self, value: [1, [1]]),
                realm.create(CombineIdentifiableObject.self, value: [2, [2]])
            )
        }
        XCTAssertEqual(obj1.child!.id, obj1.child!.id)
        XCTAssertNotEqual(obj1.child!.id, obj2.child!.id)
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
class CombinePublisherTestCase: TestCase {
    var realm: Realm!
    var cancellable: AnyCancellable?
    var notificationToken: NotificationToken?
    let subscribeOnQueue = DispatchQueue(label: "subscribe on")
    let receiveOnQueue = DispatchQueue(label: "receive on")

    override class var defaultTestSuite: XCTestSuite {
        if hasCombine() {
            return super.defaultTestSuite
        }
        return XCTestSuite(name: "\(type(of: self))")
    }

    override func setUp() {
        super.setUp()
        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "test"))
    }

    override func tearDown() {
        if let cancellable = cancellable {
            cancellable.cancel()
        }
        if let notificationToken = notificationToken {
            notificationToken.invalidate()
        }
        realm.invalidate()
        realm = nil
        subscribeOnQueue.sync { }
        receiveOnQueue.sync { }
        super.tearDown()
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
class CombineRealmTests: CombinePublisherTestCase {
    func testWillChangeLocalWrite() {
        var called = false
        cancellable = realm
            .objectWillChange
            .sink {
            called = true
        }

        try! realm.write {
            realm.create(SwiftIntObject.self, value: [])
        }
        XCTAssertTrue(called)
    }

    func testWillChangeLocalWriteWithToken() {
        var called = false

        cancellable = realm
            .objectWillChange
            .saveToken(on: self, for: \.notificationToken)
            .sink {
            called = true
        }

        try! realm.write {
            realm.create(SwiftIntObject.self, value: [])
        }
        XCTAssertNotNil(notificationToken)
        XCTAssertTrue(called)
    }

    func testWillChangeLocalWriteWithoutNotifying() {
        var called = false
        cancellable = realm
            .objectWillChange
            .saveToken(on: self, for: \.notificationToken)
            .sink {
            called = true
        }

        XCTAssertNotNil(notificationToken)
        for _ in 0..<10 {
            try! realm.write(withoutNotifying: [notificationToken!]) {
                realm.create(SwiftIntObject.self, value: [])
            }
            XCTAssertFalse(called)
        }
    }

    func testWillChangeRemoteWrite() {
        let exp = XCTestExpectation()
        cancellable = realm.objectWillChange.sink {
            exp.fulfill()
        }
        subscribeOnQueue.async {
            let backgroundRealm = try! Realm(configuration: self.realm.configuration)
            try! backgroundRealm.write {
                backgroundRealm.create(SwiftIntObject.self, value: [])
            }
        }
        wait(for: [exp], timeout: 1)
    }
}

// MARK: - Object

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
class CombineObjectPublisherTests: CombinePublisherTestCase {
    var obj: SwiftIntObject!

    override func setUp() {
        super.setUp()
        obj = try! realm.write { realm.create(SwiftIntObject.self, value: []) }
    }

    func testWillChange() {
        let exp = XCTestExpectation()
        cancellable = obj.objectWillChange.sink {
            exp.fulfill()
        }
        try! realm.write { obj.intCol = 1 }
        wait(for: [exp], timeout: 1)
    }

    func testWillChangeWithToken() {
        let exp = XCTestExpectation()
        cancellable = obj
            .objectWillChange
            .saveToken(on: self, at: \.notificationToken)
            .sink {
            exp.fulfill()
        }
        XCTAssertNotNil(notificationToken)
        try! realm.write { obj.intCol = 1 }
    }

    func testChange() {
        let exp = XCTestExpectation()
        cancellable = valuePublisher(obj).assertNoFailure().sink { o in
            XCTAssertEqual(self.obj, o)
            exp.fulfill()
        }

        try! realm.write { obj.intCol = 1 }
        wait(for: [exp], timeout: 1)
    }

    func testChangeSet() {
        let exp = XCTestExpectation()
        cancellable = changesetPublisher(obj).assertNoFailure().sink { change in
            if case .change(let o, let properties) = change {
                XCTAssertEqual(self.obj, o)
                XCTAssertEqual(properties.count, 1)
                XCTAssertEqual(properties[0].name, "intCol")
                XCTAssertNil(properties[0].oldValue)
                XCTAssertEqual(properties[0].newValue as? Int, 1)
            } else {
                XCTFail("Expected .change but got \(change)")
            }
            exp.fulfill()
        }

        try! realm.write { obj.intCol = 1 }
        wait(for: [exp], timeout: 1)
    }

    func testDelete() {
        let exp = XCTestExpectation()
        cancellable = valuePublisher(obj).sink(receiveCompletion: { _ in exp.fulfill() },
                                         receiveValue: { _ in })
        try! realm.write { realm.delete(obj) }
        wait(for: [exp], timeout: 1)
    }

    func testSubscribeOn() {
        let sema = DispatchSemaphore(value: 0)
        var i = 1
        cancellable = valuePublisher(obj)
            .subscribe(on: subscribeOnQueue)
            .map { obj -> SwiftIntObject in
                sema.signal()
                XCTAssertEqual(obj.intCol, i)
                i += 1
                return obj
            }
            .collect()
            .assertNoFailure()
            .sink { arr in
                XCTAssertEqual(arr.count, 10)
                sema.signal()
            }

        for _ in 0..<10 {
            try! realm.write { obj.intCol += 1 }
            // wait between each write so that the notifications can't get coalesced
            // also would deadlock if the subscription was on the main thread
            sema.wait()
        }
        try! realm.write { realm.delete(obj) }
        sema.wait()
    }

    func testReceiveOn() {
        var exp = XCTestExpectation()
        cancellable = valuePublisher(obj)
            .receive(on: receiveOnQueue)
            .map { obj -> Int in
                exp.fulfill()
                return obj.intCol
            }
            .collect()
            .assertNoFailure()
            .sink { arr in
                XCTAssertEqual(arr.count, 10)
                for i in 1..<10 {
                    XCTAssertTrue(arr.contains(i))
                }
                exp.fulfill()
            }

        for _ in 0..<10 {
            try! realm.write { obj.intCol += 1 }
            wait(for: [exp], timeout: 10)
            exp = XCTestExpectation()
        }
        try! realm.write { realm.delete(obj) }
        wait(for: [exp], timeout: 10)
    }

    func testChangeSetSubscribeOn() {
        let sema = DispatchSemaphore(value: 0)

        var prev: SwiftIntObject?
        cancellable = changesetPublisher(obj)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink(receiveCompletion: { _ in sema.signal() }, receiveValue: { change in
                if case .change(let o, let properties) = change {
                    XCTAssertNotEqual(self.obj, o)
                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "intCol")
                    if let prev = prev {
                        XCTAssertEqual(properties[0].oldValue as? Int, prev.intCol)
                    }
                    XCTAssertEqual(properties[0].newValue as? Int, o.intCol)
                    prev = o.freeze()
                    XCTAssertEqual(prev!.intCol, o.intCol)

                    if o.intCol == 100 {
                        sema.signal()
                    }
                } else {
                    XCTFail("Expected .change but got \(change)")
                }
            })

        for _ in 0..<100 {
            try! realm.write { obj.intCol += 1 }
        }
        sema.wait()
        try! realm.write { realm.delete(obj) }

        sema.wait()
        XCTAssertNotNil(prev)
        XCTAssertEqual(prev!.intCol, 100)
    }

    func testChangeSetSubscribeOnKeyPath() {
        let obj = try! realm.write { realm.create(SwiftObject.self, value: ["intCol": 0, "boolCol": false]) }
        let sema = DispatchSemaphore(value: 0)

        var prev: SwiftObject?
        cancellable = changesetPublisher(obj, keyPaths: ["intCol"])
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink(receiveCompletion: { _ in sema.signal() }, receiveValue: { change in
                if case .change(let o, let properties) = change {
                    XCTAssertNotEqual(self.obj, o)
                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "intCol")
                    if let prev = prev {
                        XCTAssertEqual(properties[0].oldValue as? Int, prev.intCol)
                    }
                    XCTAssertEqual(properties[0].newValue as? Int, o.intCol)
                    prev = o.freeze()
                    XCTAssertEqual(prev!.intCol, o.intCol)

                    if o.intCol >= 100 {
                        sema.signal()
                    }
                } else {
                    XCTFail("Expected .change but got \(change)")
                }
            })

        for _ in 0..<100 {
            try! realm.write { obj.intCol += 1 }
        }
        sema.wait()

        // The following two lines check if a write outside of
        // the intended keyPath does *not* publish a
        // change.
        // If a changeset is published for boolCol, the test would fail
        // above when checking for property name "intCol".
        try! realm.write { obj.boolCol = true }
        try! realm.write { obj.intCol += 1 }
        sema.wait()

        try! realm.write { realm.delete(obj) }
        sema.wait()

        XCTAssertNotNil(prev)
        XCTAssertEqual(prev!.intCol, 101)
    }

    func testChangeSetReceiveOn() {
        var exp = XCTestExpectation(description: "change")

        cancellable = changesetPublisher(obj)
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { change in
                if case .change(let o, let properties) = change {
                    XCTAssertNotEqual(self.obj, o)
                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "intCol")
                    // oldValue is always nil because we subscribed on the thread doing the writing
                    XCTAssertNil(properties[0].oldValue)
                    XCTAssertEqual(properties[0].newValue as? Int, o.intCol)
                } else {
                    XCTFail("Expected .change but got \(change)")
                }
                exp.fulfill()
            })

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { obj.intCol += 1 }
            wait(for: [exp], timeout: 1)
        }
        exp = XCTestExpectation(description: "completion")
        try! realm.write { realm.delete(obj) }
        wait(for: [exp], timeout: 1)
    }

    func testChangeSetSubscribeOnAndReceiveOn() {
        let sema = DispatchSemaphore(value: 0)

        var prev: SwiftIntObject?
        cancellable = changesetPublisher(obj)
            .subscribe(on: subscribeOnQueue)
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink(receiveCompletion: { _ in sema.signal() }, receiveValue: { change in
                if case .change(let o, let properties) = change {
                    XCTAssertNotEqual(self.obj, o)
                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "intCol")
                    if let prev = prev {
                        XCTAssertEqual(properties[0].oldValue as? Int, prev.intCol)
                    }
                    XCTAssertEqual(properties[0].newValue as? Int, o.intCol)
                    prev = o.freeze()
                    XCTAssertEqual(prev!.intCol, o.intCol)

                    if o.intCol == 100 {
                        sema.signal()
                    }
                    o.realm?.invalidate()
                } else {
                    XCTFail("Expected .change but got \(change)")
                }
            })

        for _ in 0..<100 {
            try! realm.write { obj.intCol += 1 }
        }
        sema.wait()
        try! realm.write { realm.delete(obj) }

        sema.wait()
        XCTAssertNotNil(prev)
        XCTAssertEqual(prev!.intCol, 100)
    }

    func testChangeSetMakeThreadSafe() {
        var exp = XCTestExpectation(description: "change")

        cancellable = changesetPublisher(obj)
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { change in
                if case .change(let o, let properties) = change {
                    XCTAssertNotEqual(self.obj, o)
                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "intCol")
                    XCTAssertNil(properties[0].oldValue)
                    XCTAssertEqual(properties[0].newValue as? Int, o.intCol)
                } else {
                    XCTFail("Expected .change but got \(change)")
                }
                exp.fulfill()
            })

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { obj.intCol += 1 }
            wait(for: [exp], timeout: 1)
        }
        exp = XCTestExpectation(description: "completion")
        try! realm.write { realm.delete(obj) }
        wait(for: [exp], timeout: 1)
    }

    func testFrozen() {
        let exp = XCTestExpectation()

        cancellable = valuePublisher(obj)
            .freeze()
            .collect()
            .assertNoFailure()
            .sink { arr in
                XCTAssertEqual(arr.count, 10)
                for i in 0..<10 {
                    XCTAssertEqual(arr[i].intCol, i + 1)
                }
                exp.fulfill()
        }

        for _ in 0..<10 {
            try! realm.write { obj.intCol += 1 }
        }
        try! realm.write { realm.delete(obj) }
        wait(for: [exp], timeout: 1)
    }

    func testFrozenChangeSetSubscribeOn() {
        let sema = DispatchSemaphore(value: 0)
        cancellable = changesetPublisher(obj)
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .collect()
            .assertNoFailure()
            .sink { arr in
                var prev: SwiftIntObject?
                for change in arr {
                    guard case .change(let obj, let properties) = change else {
                        XCTFail("Expected .change, got(\(change)")
                        sema.signal()
                        return
                    }

                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "intCol")
                    XCTAssertEqual(properties[0].newValue as? Int, obj.intCol)
                    if let prev = prev {
                        XCTAssertEqual(properties[0].oldValue as? Int, prev.intCol)
                    }
                    prev = obj
                }
                sema.signal()
            }

        for _ in 0..<100 {
            try! realm.write { obj.intCol += 1 }
        }
        try! realm.write { realm.delete(obj) }
        sema.wait()
    }

    func testFrozenChangeSetReceiveOn() {
        let exp = XCTestExpectation(description: "sink complete")
        cancellable = changesetPublisher(obj)
            .freeze()
            .receive(on: receiveOnQueue)
            .collect()
            .assertNoFailure()
            .sink { arr in
                for change in arr {
                    guard case .change(let obj, let properties) = change else {
                        XCTFail("Expected .change, got(\(change)")
                        exp.fulfill()
                        return
                    }

                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "intCol")
                    XCTAssertEqual(properties[0].newValue as? Int, obj.intCol)
                    // subscribing on the thread making writes means that oldValue
                    // is always nil
                    XCTAssertNil(properties[0].oldValue)
                }
                exp.fulfill()
        }

        for _ in 0..<100 {
            try! realm.write { obj.intCol += 1 }
        }
        try! realm.write { realm.delete(obj) }
        wait(for: [exp], timeout: 1)
    }

    func testFrozenChangeSetSubscribeOnAndReceiveOn() {
        let sema = DispatchSemaphore(value: 0)
        cancellable = changesetPublisher(obj)
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .receive(on: receiveOnQueue)
            .collect()
            .assertNoFailure()
            .sink { arr in
                var prev: SwiftIntObject?
                for change in arr {
                    guard case .change(let obj, let properties) = change else {
                        XCTFail("Expected .change, got(\(change)")
                        sema.signal()
                        return
                    }

                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "intCol")
                    XCTAssertEqual(properties[0].newValue as? Int, obj.intCol)
                    if let prev = prev {
                        XCTAssertEqual(properties[0].oldValue as? Int, prev.intCol)
                    }
                    prev = obj
                }
                sema.signal()
        }

        for _ in 0..<100 {
            try! realm.write { obj.intCol += 1 }
        }
        try! realm.write { realm.delete(obj) }
        sema.wait()
    }

    func testReceiveOnAfterMap() {
        var exp = XCTestExpectation()
        cancellable = valuePublisher(obj)
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .map { obj -> Int in
                exp.fulfill()
                return obj.intCol
            }
            .collect()
            .assertNoFailure()
            .sink { arr in
                XCTAssertEqual(arr.count, 10)
                for i in 1..<10 {
                    XCTAssertTrue(arr.contains(i))
                }
                exp.fulfill()
            }

        for _ in 0..<10 {
            try! realm.write { obj.intCol += 1 }
            wait(for: [exp], timeout: 1)
            exp = XCTestExpectation()
        }
        try! realm.write { realm.delete(obj) }
        wait(for: [exp], timeout: 1)
    }

    func testUnmanagedMakeThreadSafe() {
        let objects = [SwiftIntObject(value: [1]), SwiftIntObject(value: [2]), SwiftIntObject(value: [3])]

        let exp = XCTestExpectation()
        cancellable = objects.publisher
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .map { $0.intCol }
            .collect()
            .sink { (arr: [Int]) in
                XCTAssertEqual(arr, [1, 2, 3])
                exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func testManagedMakeThreadSafe() {
        let objects = try! realm.write {
            return [
                realm.create(SwiftIntObject.self, value: [1]),
                realm.create(SwiftIntObject.self, value: [2]),
                realm.create(SwiftIntObject.self, value: [3])
            ]
        }

        let exp = XCTestExpectation()
        cancellable = objects.publisher
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .map { $0.intCol }
            .collect()
            .sink { (arr: [Int]) in
                XCTAssertEqual(arr, [1, 2, 3])
                exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func testFrozenMakeThreadSafe() {
        var exp = XCTestExpectation()
        cancellable = valuePublisher(obj)
            .freeze()
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { obj in
                XCTAssertTrue(obj.isFrozen)
                exp.fulfill()
            }

        for _ in 0..<10 {
            try! realm.write { obj.intCol += 1 }
            wait(for: [exp], timeout: 1)
            exp = XCTestExpectation()
        }
    }

    func testMixedMakeThreadSafe() {
        let realm2 = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "test2"))
        var objects = try! realm.write {
            try! realm2.write {
                return [
                    realm.create(SwiftIntObject.self, value: [1]),
                    realm2.create(SwiftIntObject.self, value: [2]),
                    SwiftIntObject(value: [3]),
                    realm.create(SwiftIntObject.self, value: [4]),
                    realm2.create(SwiftIntObject.self, value: [5])
                ]
            }
        }
        objects[3] = objects[3].freeze()
        objects[4] = objects[4].freeze()
        let exp = XCTestExpectation()
        cancellable = objects.publisher
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .map { $0.intCol }
            .collect()
            .sink { (arr: [Int]) in
                XCTAssertEqual(arr, [1, 2, 3, 4, 5])
                exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
}

private protocol CombineTestCollection {
    static func getCollection(_ realm: Realm) -> Self
    func appendObject()
    func modifyObject()
    // Keypath which is modified by `modifyObject`
    var includedKeyPath: [String] { get }
    // Keypath which is not modified by `modifyObject`
    var excludedKeyPath: [String] { get }
}

// MARK: - List, MutableSet

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
private class CombineCollectionPublisherTests<Collection: RealmCollection>: CombinePublisherTestCase
        where Collection: CombineTestCollection, Collection: RealmSubscribable {
    var collection: Collection!

    class func testSuite(_ name: String) -> XCTestSuite {
        if hasCombine() {
            // By default this test suite's name will be the generic type's
            // mangled name, which is an unreadable mess. It appears that the
            // way to override it is with a subclass with an explicit name, which
            // can't be done in pure Swift.
            let cls: AnyClass = objc_allocateClassPair(CombineCollectionPublisherTests<Collection>.self, "CombinePublisherTests<\(name)>", 0)!
            objc_registerClassPair(cls)
            return cls.defaultTestSuite
        }
        return XCTestSuite(name: "CombinePublisherTests<\(name)>")
    }

    override func setUp() {
        super.setUp()
        collection = Collection.getCollection(realm)
    }

    func testWillChange() {
        let exp = XCTestExpectation()
        cancellable = collection.objectWillChange.sink {
            exp.fulfill()
        }
        try! realm.write { collection.appendObject() }
        wait(for: [exp], timeout: 1)
    }

    func testBasic() {
        var exp = XCTestExpectation()
        var calls = 0
        cancellable = collection.collectionPublisher
            .assertNoFailure()
            .sink { c in
                XCTAssertEqual(c.count, calls)
                calls += 1
                exp.fulfill()
            }

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
            exp = XCTestExpectation()
        }
    }

    func testBasicWithNotificationToken() {
        var exp = XCTestExpectation()
        var calls = 0
        cancellable = collection.collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .assertNoFailure()
            .sink { c in
                XCTAssertEqual(c.count, calls)
                calls += 1
                exp.fulfill()
            }
        XCTAssertNotNil(notificationToken)
        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
            exp = XCTestExpectation()
        }
    }

    func testBasicWithoutNotifying() {
        var calls = 0
        cancellable = collection
            .collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .assertNoFailure()
            .sink { _ in
                calls += 1
            }
        XCTAssertNotNil(notificationToken)
        for _ in 0..<10 {
            try! realm.write(withoutNotifying: [notificationToken!]) { collection.appendObject() }
            XCTAssertEqual(calls, 1) // 1 for the initial notification
        }
    }

    func checkChangeset(_ change: RealmCollectionChange<Collection>, calls: Int, frozen: Bool = false) {
        switch change {
        case .initial(let collection):
            XCTAssertEqual(collection.isFrozen, frozen)
            XCTAssertEqual(calls, 0)
            XCTAssertEqual(collection.count, 0)
        case .update(let collection, deletions: let deletions, insertions: let insertions,
                     modifications: let modifications):
            XCTAssertEqual(collection.isFrozen, frozen)
            XCTAssertEqual(collection.count, calls)
            XCTAssertEqual(insertions, [calls - 1])
            XCTAssertEqual(deletions, [])
            XCTAssertEqual(modifications, [])
        case .error(let error):
            XCTFail("Unexpected error \(error)")
        }
    }

    func testChangeSet() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        cancellable = collection.changesetPublisher
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testChangeSetWithToken() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        cancellable = collection
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testChangeSetWithoutNotifying() {
        var calls = 0
        cancellable = collection
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .sink { _ in
                calls += 1
            }
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            try! realm.write(withoutNotifying: [notificationToken!]) { collection.appendObject() }
            XCTAssertEqual(calls, 1) // 1 for the initial observation
        }
    }

    func testSubscribeOn() {
        let sema = DispatchSemaphore(value: 0)
        var calls = 0
        cancellable = collection
            .collectionPublisher
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, calls)
                calls += 1
                sema.signal()
        }
        sema.wait()

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            sema.wait()
        }
    }
    func testSubscribeOnKeyPath() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.collectionPublisher(keyPaths: collection.includedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { _ in
                ex.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "change notification")
        try! realm.write { collection.modifyObject() }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    func testSubscribeOnKeyPathNoChange() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.collectionPublisher(keyPaths: collection.excludedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { _ in
                ex.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "no change notification")
        ex.isInverted = true
        try! realm.write { collection.modifyObject() }
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testSubscribeOnWithToken() {
        let sema = DispatchSemaphore(value: 0)
        var calls = 0
        cancellable = collection
            .collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, calls)
                calls += 1
                sema.signal()
        }
        sema.wait()
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            sema.wait()
        }
    }

    func testReceiveOn() {
        var calls = 0
        var exp = XCTestExpectation(description: "initial")
        cancellable = collection.collectionPublisher
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, calls)
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testReceiveOnWithToken() {
        var calls = 0
        var exp = XCTestExpectation(description: "initial")
        cancellable = collection
            .collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, calls)
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testChangeSetSubscribeOn() {
        var calls = 0
        let sema = DispatchSemaphore(value: 0)
        cancellable = collection.changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                sema.signal()
        }
        sema.wait()

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            sema.wait()
        }
    }

    func testChangeSetSubscribeOnKeyPath() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.changesetPublisher(keyPaths: collection.includedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .sink { _ in
                ex.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "change notification")
        try! realm.write { collection.modifyObject() }
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testChangeSetSubscribeOnKeyPathNoChange() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.changesetPublisher(keyPaths: collection.excludedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .sink { _ in
                ex.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "no change notification")
        ex.isInverted = true
        try! realm.write { collection.modifyObject() }
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testChangeSetSubscribeOnWithToken() {
        var calls = 0
        let sema = DispatchSemaphore(value: 0)
        cancellable = collection
            .changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .saveToken(on: self, at: \.notificationToken)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                sema.signal()
        }
        sema.wait()
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            sema.wait()
        }
    }

    func testChangeSetReceiveOn() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        cancellable = collection.changesetPublisher
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testChangeSetReceiveOnWithToken() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        cancellable = collection
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testMakeThreadSafe() {
        var calls = 0
        var exp = XCTestExpectation(description: "initial")
        cancellable = collection.collectionPublisher
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, calls)
                calls += 1
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testMakeThreadSafeChangeset() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        cancellable = collection.changesetPublisher
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testMakeThreadSafeWithChangesetToken() {
        var calls = 0
        var exp = XCTestExpectation(description: "initial")
        cancellable = collection
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testFrozen() {
        let exp = XCTestExpectation()
        cancellable = collection.collectionPublisher
            .freeze()
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { arr in
                XCTAssertEqual(arr.count, 10)
                for (i, collection) in arr.enumerated() {
                    XCTAssertTrue(collection.isFrozen)
                    XCTAssertEqual(collection.count, i)
                }
                exp.fulfill()
        }

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
        }
        wait(for: [exp], timeout: 10)
    }

    func testFrozenChangeSetSubscribeOn() {
        let sema = DispatchSemaphore(value: 0)
        cancellable = collection.changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .assertNoFailure()
            .signal(sema)
            .prefix(10)
            .collect()
            .sink { arr in
                XCTAssertEqual(arr.count, 10)
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, calls: i, frozen: true)
                }
                sema.signal()
            }

        for _ in 0..<10 {
            sema.wait()
            try! realm.write { collection.appendObject() }
        }
        sema.wait()
    }

    func testFrozenChangeSetReceiveOn() {
        let exp = XCTestExpectation()
        cancellable = collection.changesetPublisher
            .freeze()
            .receive(on: receiveOnQueue)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { arr in
                XCTAssertEqual(arr.count, 10)
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, calls: i, frozen: true)
                }
                exp.fulfill()
        }

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
        }
        wait(for: [exp], timeout: 10)
    }

    func testFrozenChangeSetSubscribeOnAndReceiveOn() {
        let sema = DispatchSemaphore(value: 0)
        cancellable = collection.changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .receive(on: receiveOnQueue)
            .signal(sema)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { arr in
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, calls: i, frozen: true)
                }
                sema.signal()
        }

        for _ in 0..<10 {
            sema.wait()
            try! realm.write { collection.appendObject() }
        }
        sema.wait()
    }

    func testFrozenMakeThreadSafe() {
        let sema = DispatchSemaphore(value: 0)
        cancellable = collection.collectionPublisher
            .freeze()
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { arr in
                for (i, collection) in arr.enumerated() {
                    XCTAssertTrue(collection.isFrozen)
                    XCTAssertEqual(collection.count, i)
                }
                sema.signal()
            }

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
        }
        sema.wait()
    }

    func testFrozenMakeThreadSafeChangeset() {
        let exp = XCTestExpectation()
        cancellable = collection.changesetPublisher
            .freeze()
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { arr in
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, calls: i, frozen: true)
                }
                exp.fulfill()
        }

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
        }
        wait(for: [exp], timeout: 10)
    }
}

extension Results: CombineTestCollection where Element == SwiftObject {
    static func getCollection(_ realm: Realm) -> Results<Element> {
        return realm.objects(Element.self)
    }

    func appendObject() {
        realm?.create(Element.self, value: [])
    }

    func modifyObject() {
        self.first!.intCol += 1
    }

    var includedKeyPath: [String] {
        return ["intCol"]
    }

    var excludedKeyPath: [String] {
        return ["stringCol"]
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
class ResultsPublisherTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        return CombineCollectionPublisherTests<Results<SwiftObject>>.testSuite("Results")
    }
}

extension List: CombineTestCollection where Element == SwiftObject {
    static func getCollection(_ realm: Realm) -> List<Element> {
        return try! realm.write { realm.create(SwiftArrayPropertyObject.self, value: []).swiftObjArray }
    }

    func appendObject() {
        append(realm!.create(Element.self, value: []))
    }

    func modifyObject() {
        self.first!.intCol += 1
    }

    var includedKeyPath: [String] {
        return ["intCol"]
    }

    var excludedKeyPath: [String] {
        return ["stringCol"]
    }
}


@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
class ManagedListPublisherTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        return CombineCollectionPublisherTests<List<SwiftObject>>.testSuite("List")
    }
}

extension MutableSet: CombineTestCollection where Element == SwiftObject {
    static func getCollection(_ realm: Realm) -> MutableSet<Element> {
        return try! realm.write { realm.create(SwiftMutableSetPropertyObject.self, value: []).swiftObjSet }
    }

    func appendObject() {
        insert(realm!.create(Element.self, value: []))
    }

    func modifyObject() {
        self.first!.intCol += 1
    }

    var includedKeyPath: [String] {
        return ["intCol"]
    }

    var excludedKeyPath: [String] {
        return ["stringCol"]
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
class ManagedMutableSetPublisherTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        return CombineCollectionPublisherTests<MutableSet<SwiftObject>>.testSuite("MutableSet")
    }
}

extension LinkingObjects: CombineTestCollection where Element == SwiftOwnerObject {
    static func getCollection(_ realm: Realm) -> LinkingObjects<Element> {
        return try! realm.write { realm.create(SwiftDogObject.self, value: []).owners }
    }

    func appendObject() {
        realm!.create(SwiftOwnerObject.self, value: ["", realm!.objects(SwiftDogObject.self).first!])
    }

    func modifyObject() {
        self.first!.name += "concat"
    }

    var includedKeyPath: [String] {
        return ["name"]
    }

    var excludedKeyPath: [String] {
        return ["dog"]
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
class LinkingObjectsPublisherTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        return CombineCollectionPublisherTests<LinkingObjects<SwiftOwnerObject>>.testSuite("LinkingObjects")
    }
}

extension AnyRealmCollection: CombineTestCollection where Element == SwiftObject {
    static func getCollection(_ realm: Realm) -> AnyRealmCollection<Element> {
        return AnyRealmCollection(realm.objects(Element.self))
    }

    func appendObject() {
        realm?.create(Element.self, value: [])
    }

    func modifyObject() {
        self.first!.intCol += 1
    }

    var includedKeyPath: [String] {
        return ["intCol"]
    }

    var excludedKeyPath: [String] {
        return ["stringCol"]
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
class AnyRealmCollectionPublisherTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        return CombineCollectionPublisherTests<AnyRealmCollection<SwiftObject>>.testSuite("AnyRealmCollection")
    }
}

// MARK: - Map

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
private class CombineMapPublisherTests<Collection: RealmKeyedCollection>: CombinePublisherTestCase
        where Collection: CombineTestCollection, Collection: RealmSubscribable {
    var collection: Collection!

    class func testSuite(_ name: String) -> XCTestSuite {
        if hasCombine() {
            // By default this test suite's name will be the generic type's
            // mangled name, which is an unreadable mess. It appears that the
            // way to override it is with a subclass with an explicit name, which
            // can't be done in pure Swift.
            let cls: AnyClass = objc_allocateClassPair(CombineMapPublisherTests<Collection>.self, "CombinePublisherTests<\(name)>", 0)!
            objc_registerClassPair(cls)
            return cls.defaultTestSuite
        }
        return XCTestSuite(name: "CombinePublisherTests<\(name)>")
    }

    override func setUp() {
        super.setUp()
        collection = Collection.getCollection(realm)
    }

    func testWillChange() {
        let exp = XCTestExpectation()
        cancellable = collection.objectWillChange.sink {
            exp.fulfill()
        }
        try! realm.write { collection.appendObject() }
        wait(for: [exp], timeout: 1)
    }

    func testBasic() {
        var exp = XCTestExpectation()
        var calls = 0
        cancellable = collection.collectionPublisher
            .assertNoFailure()
            .sink { c in
                XCTAssertEqual(c.count, calls)
                calls += 1
                exp.fulfill()
            }

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
            exp = XCTestExpectation()
        }
    }

    func testBasicWithNotificationToken() {
        var exp = XCTestExpectation()
        var calls = 0
        cancellable = collection.collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .assertNoFailure()
            .sink { c in
                XCTAssertEqual(c.count, calls)
                calls += 1
                exp.fulfill()
            }
        XCTAssertNotNil(notificationToken)
        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
            exp = XCTestExpectation()
        }
    }

    func testBasicWithoutNotifying() {
        var calls = 0
        cancellable = collection
            .collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .assertNoFailure()
            .sink { _ in
                calls += 1
            }
        XCTAssertNotNil(notificationToken)
        for _ in 0..<10 {
            try! realm.write(withoutNotifying: [notificationToken!]) { collection.appendObject() }
            XCTAssertEqual(calls, 1) // 1 for the initial notification
        }
    }

    func checkChangeset(_ change: RealmMapChange<Collection>, calls: Int, frozen: Bool = false) {
        switch change {
        case .initial(let collection):
            XCTAssertEqual(collection.isFrozen, frozen)
            XCTAssertEqual(calls, 0)
            XCTAssertEqual(collection.count, 0)
        case .update(let collection, deletions: let deletions, insertions: let insertions, modifications: let modifications):
            XCTAssertEqual(collection.isFrozen, frozen)
            XCTAssertEqual(collection.count, calls)
            // one insertion at a time
            XCTAssertEqual(insertions.count, 1)
            XCTAssertEqual(modifications, [])
            XCTAssertEqual(deletions, [])
        case .error(let error):
            XCTFail("Unexpected error \(error)")
        }
    }

    func testChangeSet() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        cancellable = collection.changesetPublisher
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testChangeSetWithToken() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        cancellable = collection
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testChangeSetWithoutNotifying() {
        var calls = 0
        cancellable = collection
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .sink { _ in
                calls += 1
            }
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            try! realm.write(withoutNotifying: [notificationToken!]) { collection.appendObject() }
            XCTAssertEqual(calls, 1) // 1 for the initial observation
        }
    }

    func testSubscribeOn() {
        let sema = DispatchSemaphore(value: 0)
        var calls = 0
        cancellable = collection
            .collectionPublisher
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, calls)
                calls += 1
                sema.signal()
        }
        sema.wait()

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            sema.wait()
        }
    }

    func testSubscribeOnKeyPath() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.collectionPublisher(keyPaths: collection.includedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { _ in
                ex.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "change notification")
        try! realm.write { collection.modifyObject() }
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testSubscribeOnKeyPathNoChange() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.collectionPublisher(keyPaths: collection.excludedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { _ in
                ex.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "no change notification")
        ex.isInverted = true
        try! realm.write { collection.modifyObject() }
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testSubscribeOnWithToken() {
        let sema = DispatchSemaphore(value: 0)
        var calls = 0
        cancellable = collection
            .collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, calls)
                calls += 1
                sema.signal()
        }
        sema.wait()
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            sema.wait()
        }
    }

    func testReceiveOn() {
        var calls = 0
        var exp = XCTestExpectation(description: "initial")
        cancellable = collection.collectionPublisher
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, calls)
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testReceiveOnWithToken() {
        var calls = 0
        var exp = XCTestExpectation(description: "initial")
        cancellable = collection
            .collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, calls)
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testChangeSetSubscribeOn() {
        var calls = 0
        let sema = DispatchSemaphore(value: 0)
        cancellable = collection.changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                sema.signal()
        }
        sema.wait()

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            sema.wait()
        }
    }

    func testChangeSetSubscribeOnKeyPath() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.changesetPublisher(keyPaths: collection.includedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .sink { _ in
                ex.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "change notification")
        try! realm.write { collection.modifyObject() }
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testChangeSetSubscribeOnKeyPathNoChange() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.changesetPublisher(keyPaths: collection.excludedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .sink { _ in
                ex.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        waitForExpectations(timeout: 1.0, handler: nil)

        ex = expectation(description: "no change notification")
        ex.isInverted = true
        try! realm.write { collection.modifyObject() }
        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testChangeSetSubscribeOnWithToken() {
        var calls = 0
        let sema = DispatchSemaphore(value: 0)
        cancellable = collection
            .changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .saveToken(on: self, at: \.notificationToken)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                sema.signal()
        }
        sema.wait()
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            sema.wait()
        }
    }

    func testChangeSetReceiveOn() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        cancellable = collection.changesetPublisher
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testChangeSetReceiveOnWithToken() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        cancellable = collection
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testMakeThreadSafe() {
        var calls = 0
        var exp = XCTestExpectation(description: "initial")
        cancellable = collection.collectionPublisher
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, calls)
                calls += 1
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testMakeThreadSafeChangeset() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        cancellable = collection.changesetPublisher
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testMakeThreadSafeWithChangesetToken() {
        var calls = 0
        var exp = XCTestExpectation(description: "initial")
        cancellable = collection
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, calls: calls)
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }
    }

    func testFrozen() {
        let exp = XCTestExpectation()
        cancellable = collection.collectionPublisher
            .freeze()
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { arr in
                for (i, collection) in arr.enumerated() {
                    XCTAssertTrue(collection.isFrozen)
                    XCTAssertEqual(collection.count, i)
                }
                exp.fulfill()
        }

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
        }
        wait(for: [exp], timeout: 10)
    }

    func testFrozenChangeSetSubscribeOn() {
        let sema = DispatchSemaphore(value: 0)
        cancellable = collection.changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .assertNoFailure()
            .signal(sema)
            .prefix(10)
            .collect()
            .sink { arr in
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, calls: i, frozen: true)
                }
                sema.signal()
            }

        for _ in 0..<10 {
            sema.wait()
            try! realm.write { collection.appendObject() }
        }
        sema.wait()
    }

    func testFrozenChangeSetReceiveOn() {
        let exp = XCTestExpectation()
        cancellable = collection.changesetPublisher
            .freeze()
            .receive(on: receiveOnQueue)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { arr in
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, calls: i, frozen: true)
                }
                exp.fulfill()
        }

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
        }
        wait(for: [exp], timeout: 10)
    }

    func testFrozenChangeSetSubscribeOnAndReceiveOn() {
        let sema = DispatchSemaphore(value: 0)
        cancellable = collection.changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .receive(on: receiveOnQueue)
            .signal(sema)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { arr in
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, calls: i, frozen: true)
                }
                sema.signal()
        }

        for _ in 0..<10 {
            sema.wait()
            try! realm.write { collection.appendObject() }
        }
        sema.wait()
    }

    func testFrozenMakeThreadSafe() {
        let sema = DispatchSemaphore(value: 0)
        cancellable = collection.collectionPublisher
            .freeze()
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { arr in
                for (i, collection) in arr.enumerated() {
                    XCTAssertTrue(collection.isFrozen)
                    XCTAssertEqual(collection.count, i)
                }
                sema.signal()
            }

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
        }
        sema.wait()
    }

    func testFrozenMakeThreadSafeChangeset() {
        let exp = XCTestExpectation()
        cancellable = collection.changesetPublisher
            .freeze()
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { arr in
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, calls: i, frozen: true)
                }
                exp.fulfill()
        }

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
        }
        wait(for: [exp], timeout: 10)
    }
}

extension Map: CombineTestCollection where Key == String, Value == SwiftObject? {
    static func getCollection(_ realm: Realm) -> Map<Key, Value> {
        return try! realm.write { realm.create(SwiftMapPropertyObject.self, value: []).swiftObjectMap }
    }

    func appendObject() {
        let key = UUID().uuidString
        self[key] = realm!.create(SwiftObject.self, value: [])
    }

    func modifyObject() {
        self.values.first!!.intCol += 1
    }

    var includedKeyPath: [String] {
        return ["intCol"]
    }

    var excludedKeyPath: [String] {
        return ["stringCol"]
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
class ManagedMapPublisherTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        return CombineMapPublisherTests<Map<String, SwiftObject?>>.testSuite("Map")
    }
}

// MARK: - Projection

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension SimpleObject: ObjectKeyIdentifiable {
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
extension SimpleProjection: ObjectKeyIdentifiable {
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
public final class AltSimpleProjection: Projection<SimpleObject>, ObjectKeyIdentifiable {
    @Projected(\SimpleObject.int) var int
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
class CombineProjectionPublisherTests: CombinePublisherTestCase {

    var object: SimpleObject!
    var projection: SimpleProjection!

    override func setUp() {
        super.setUp()
        try! realm.write {
            object = realm.create(SimpleObject.self)
        }
        projection = realm.objects(SimpleProjection.self).first!
    }

    func testWillChange() {
        let exp = XCTestExpectation()
        cancellable = projection.objectWillChange.sink {
            exp.fulfill()
        }
        try! realm.write { object.int = 1 }
        wait(for: [exp], timeout: 1)
    }

    func testWillChangeWithToken() {
        let exp = XCTestExpectation()
        cancellable = projection
            .objectWillChange
            .saveToken(on: self, at: \.notificationToken)
            .sink {
            exp.fulfill()
        }
        XCTAssertNotNil(notificationToken)
        try! realm.write { object.int = 1 }
    }

    func testChange() {
        let exp = XCTestExpectation()
        cancellable = valuePublisher(projection)
            .assertNoFailure()
            .sink { o in
            XCTAssertEqual(self.projection, o)
            exp.fulfill()
        }

        try! realm.write { object.int = 1 }
        wait(for: [exp], timeout: 1)
    }

    func testChangeSet() {
        let exp = XCTestExpectation()
        cancellable = changesetPublisher(projection)
            .assertNoFailure()
            .sink { change in
                if case .change(let p, let properties) = change {
                    XCTAssertEqual(self.projection, p)
                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "int")
                    XCTAssertNil(properties[0].oldValue)
                    XCTAssertEqual(properties[0].newValue as? Int, 1)
                } else {
                    XCTFail("Expected .change but got \(change)")
                }
                exp.fulfill()
            }
        try! realm.write { object.int = 1 }
        wait(for: [exp], timeout: 1)
    }

    func testDelete() {
        let exp = XCTestExpectation()
        cancellable = valuePublisher(projection)
            .sink(receiveCompletion: { _ in exp.fulfill() },
                  receiveValue: { _ in })
        try! realm.write { realm.delete(object) }
        wait(for: [exp], timeout: 1)
    }

    func testSubscribeOn() {
        let sema = DispatchSemaphore(value: 0)
        var i = 1
        cancellable = valuePublisher(projection)
            .subscribe(on: subscribeOnQueue)
            .map { projection -> SimpleProjection in
                sema.signal()
                XCTAssertEqual(projection.int, i)
                i += 1
                return projection
            }
            .collect()
            .assertNoFailure()
            .sink { arr in
                XCTAssertEqual(arr.count, 10)
                sema.signal()
            }

        for _ in 0..<10 {
            try! realm.write { object.int += 1 }
            // wait between each write so that the notifications can't get coalesced
            // also would deadlock if the subscription was on the main thread
            sema.wait()
        }
        try! realm.write { realm.delete(object) }
        sema.wait()
    }

    func testReceiveOn() {
        var exp = XCTestExpectation()
        cancellable = valuePublisher(projection)
            .receive(on: receiveOnQueue)
            .map { projection -> Int in
                exp.fulfill()
                return projection.int
            }
            .collect()
            .assertNoFailure()
            .sink { arr in
                XCTAssertEqual(arr.count, 10)
                for i in 1..<10 {
                    XCTAssertTrue(arr.contains(i))
                }
                exp.fulfill()
            }

        for _ in 0..<10 {
            try! realm.write { object.int += 1 }
            wait(for: [exp], timeout: 10)
            exp = XCTestExpectation()
        }
        try! realm.write { realm.delete(object) }
        wait(for: [exp], timeout: 10)
    }

    func testChangeSetSubscribeOn() {
        let sema = DispatchSemaphore(value: 0)

        var prevProj: SimpleProjection?
        cancellable = changesetPublisher(projection)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink(receiveCompletion: { _ in sema.signal() }, receiveValue: { change in
                if case .change(let p, let properties) = change {
                    XCTAssertNotEqual(self.projection, p)
                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "int")
                    if let prevProj = prevProj {
                        XCTAssertEqual(properties[0].oldValue as? Int, prevProj.int)
                    }
                    XCTAssertEqual(properties[0].newValue as? Int, p.int)
                    prevProj = p.freeze()
                    XCTAssertEqual(prevProj!.int, p.int)

                    if p.int == 100 {
                        sema.signal()
                    }
                } else {
                    XCTFail("Expected .change but got \(change)")
                }
            })

        for _ in 0..<100 {
            try! realm.write { object.int += 1 }
        }
        sema.wait()
        try! realm.write { realm.delete(object) }

        sema.wait()
        XCTAssertNotNil(prevProj)
        XCTAssertEqual(prevProj!.int, 100)
    }

    func testChangeSetSubscribeOnKeyPath() {
        let sema = DispatchSemaphore(value: 0)

        var prevProj: SimpleProjection?
        cancellable = changesetPublisher(projection, keyPaths: ["int"])
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink(receiveCompletion: { _ in sema.signal() }, receiveValue: { change in
                if case .change(let p, let properties) = change {
                    XCTAssertNotEqual(self.projection, p)
                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "int")
                    if let prevProj = prevProj {
                        XCTAssertEqual(properties[0].oldValue as? Int, prevProj.int)
                    }
                    XCTAssertEqual(properties[0].newValue as? Int, p.int)
                    prevProj = p.freeze()
                    XCTAssertEqual(prevProj!.int, p.int)

                    if p.int >= 100 {
                        sema.signal()
                    }
                } else {
                    XCTFail("Expected .change but got \(change)")
                }
            })

        for _ in 0..<100 {
            try! realm.write { object.int += 1 }
        }
        sema.wait()

        // The following two lines check if a write outside of
        // the intended keyPath does *not* publish a
        // change.
        // If a changeset is published for boolCol, the test would fail
        // above when checking for property name "intCol".
        try! realm.write { object.bool = true }
        try! realm.write { object.int += 1 }
        sema.wait()

        try! realm.write { realm.delete(object) }
        sema.wait()

        XCTAssertNotNil(prevProj)
        XCTAssertEqual(prevProj!.int, 101)
    }

    func testChangeSetReceiveOn() {
        var exp = XCTestExpectation(description: "change")

        cancellable = changesetPublisher(projection)
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { change in
                if case .change(let p, let properties) = change {
                    XCTAssertNotEqual(self.projection, p)
                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "int")
                    // oldValue is always nil because we subscribed on the thread doing the writing
                    XCTAssertNil(properties[0].oldValue)
                    XCTAssertEqual(properties[0].newValue as? Int, p.int)
                } else {
                    XCTFail("Expected .change but got \(change)")
                }
                exp.fulfill()
            })

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { object.int += 1 }
            wait(for: [exp], timeout: 1)
        }
        exp = XCTestExpectation(description: "completion")
        try! realm.write { realm.delete(object) }
        wait(for: [exp], timeout: 1)
    }

    func testChangeSetSubscribeOnAndReceiveOn() {
        let sema = DispatchSemaphore(value: 0)

        var prev: SimpleProjection?
        cancellable = changesetPublisher(projection)
            .subscribe(on: subscribeOnQueue)
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink(receiveCompletion: { _ in sema.signal() }, receiveValue: { change in
                if case .change(let p, let properties) = change {
                    XCTAssertNotEqual(self.projection, p)
                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "int")
                    if let prev = prev {
                        XCTAssertEqual(properties[0].oldValue as? Int, prev.int)
                    }
                    XCTAssertEqual(properties[0].newValue as? Int, p.int)
                    prev = p.freeze()
                    XCTAssertEqual(prev!.int, p.int)

                    if p.int == 100 {
                        sema.signal()
                    }
                    p.realm?.invalidate()
                } else {
                    XCTFail("Expected .change but got \(change)")
                }
            })

        for _ in 0..<100 {
            try! realm.write { object.int += 1 }
        }
        sema.wait()
        try! realm.write { realm.delete(object) }

        sema.wait()
        XCTAssertNotNil(prev)
        XCTAssertEqual(prev!.int, 100)
    }

    func testChangeSetMakeThreadSafe() {
        var exp = XCTestExpectation(description: "change")

        cancellable = changesetPublisher(projection)
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { change in
                if case .change(let p, let properties) = change {
                    XCTAssertNotEqual(self.projection, p)
                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "int")
                    XCTAssertNil(properties[0].oldValue)
                    XCTAssertEqual(properties[0].newValue as? Int, p.int)
                } else {
                    XCTFail("Expected .change but got \(change)")
                }
                exp.fulfill()
            })

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { object.int += 1 }
            wait(for: [exp], timeout: 1)
        }
        exp = XCTestExpectation(description: "completion")
        try! realm.write { realm.delete(object) }
        wait(for: [exp], timeout: 1)
    }

    func testFrozen() {
        let exp = XCTestExpectation()

        cancellable = valuePublisher(projection)
            .freeze()
            .collect()
            .assertNoFailure()
            .sink { arr in
                XCTAssertEqual(arr.count, 10)
                for i in 0..<10 {
                    XCTAssertEqual(arr[i].int, i + 1)
                }
                exp.fulfill()
        }

        for _ in 0..<10 {
            try! realm.write { object.int += 1 }
        }
        try! realm.write { realm.delete(object) }
        wait(for: [exp], timeout: 1)
    }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func testFrozenPublisherSubscribeOn() {
        let exp = XCTestExpectation()
        cancellable = projection.publisher
            .threadSafeReference()
            .receive(on: subscribeOnQueue)
            .freeze()
            .assertNoFailure()
            .sink { change in
                print(change)
                exp.fulfill()
            }
        try! realm.write { object.int += 1 }
        wait(for: [exp], timeout: 1)
    }

    func testFrozenChangeSetSubscribeOn() {
        let sema = DispatchSemaphore(value: 0)
        cancellable = changesetPublisher(projection)
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .collect()
            .assertNoFailure()
            .sink { arr in
                var prev: SimpleProjection?
                for change in arr {
                    print(change)
                    guard case .change(let p, let properties) = change else {
                        XCTFail("Expected .change, got(\(change)")
                        sema.signal()
                        return
                    }

                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "int")
                    XCTAssertEqual(properties[0].newValue as? Int, p.int)
                    if let prev = prev {
                        XCTAssertEqual(properties[0].oldValue as? Int, prev.int)
                    }
                    prev = p
                }
                sema.signal()
            }

        for _ in 0..<100 {
            try! realm.write { object.int += 1 }
        }
        try! realm.write { realm.delete(object) }
        sema.wait()
    }

    func testFrozenChangeSetReceiveOn() {
        let exp = XCTestExpectation(description: "sink complete")
        cancellable = changesetPublisher(projection)
            .freeze()
            .receive(on: receiveOnQueue)
            .collect()
            .assertNoFailure()
            .sink { arr in
                for change in arr {
                    guard case .change(let p, let properties) = change else {
                        XCTFail("Expected .change, got(\(change)")
                        exp.fulfill()
                        return
                    }

                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "int")
                    XCTAssertEqual(properties[0].newValue as? Int, p.int)
                    // subscribing on the thread making writes means that oldValue
                    // is always nil
                    XCTAssertNil(properties[0].oldValue)
                }
                exp.fulfill()
        }

        for _ in 0..<100 {
            try! realm.write { object.int += 1 }
        }
        try! realm.write { realm.delete(object) }
        wait(for: [exp], timeout: 1)
    }

    func testFrozenChangeSetSubscribeOnAndReceiveOn() {
        let sema = DispatchSemaphore(value: 0)
        cancellable = changesetPublisher(projection)
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .receive(on: receiveOnQueue)
            .collect()
            .assertNoFailure()
            .sink { arr in
                var prev: SimpleProjection?
                for change in arr {
                    guard case .change(let p, let properties) = change else {
                        XCTFail("Expected .change, got(\(change)")
                        sema.signal()
                        return
                    }

                    XCTAssertEqual(properties.count, 1)
                    XCTAssertEqual(properties[0].name, "int")
                    XCTAssertEqual(properties[0].newValue as? Int, p.int)
                    if let prev = prev {
                        XCTAssertEqual(properties[0].oldValue as? Int, prev.int)
                    }
                    prev = p
                }
                sema.signal()
        }

        for _ in 0..<100 {
            try! realm.write { object.int += 1 }
        }
        try! realm.write { realm.delete(object) }
        sema.wait()
    }

    func testReceiveOnAfterMap() {
        var exp = XCTestExpectation()
        cancellable = valuePublisher(projection)
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .map { projection -> Int in
                exp.fulfill()
                return projection.int
            }
            .collect()
            .assertNoFailure()
            .sink { arr in
                XCTAssertEqual(arr.count, 10)
                for i in 1..<10 {
                    XCTAssertTrue(arr.contains(i))
                }
                exp.fulfill()
            }

        for _ in 0..<10 {
            try! realm.write { object.int += 1 }
            wait(for: [exp], timeout: 1)
            exp = XCTestExpectation()
        }
        try! realm.write { realm.delete(object) }
        wait(for: [exp], timeout: 1)
    }

    func testUnmanagedMakeThreadSafe() {
        let projections = try! realm.write {
            return [
                SimpleProjection(projecting: realm.create(SimpleObject.self, value: [1])),
                SimpleProjection(projecting: realm.create(SimpleObject.self, value: [2])),
                SimpleProjection(projecting: realm.create(SimpleObject.self, value: [3]))
            ]
        }
        let exp = XCTestExpectation()
        cancellable = projections.publisher
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .map { $0.int }
            .collect()
            .sink { (arr: [Int]) in
                XCTAssertEqual(arr, [1, 2, 3])
                exp.fulfill()
            }
        wait(for: [exp], timeout: 1)
    }

    func testManagedMakeThreadSafe() {
        let projections = try! realm.write {
            return [
                SimpleProjection(projecting: realm.create(SimpleObject.self, value: [1])),
                SimpleProjection(projecting: realm.create(SimpleObject.self, value: [2])),
                SimpleProjection(projecting: realm.create(SimpleObject.self, value: [3]))
            ]
        }

        let exp = XCTestExpectation()
        cancellable = projections.publisher
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .map { $0.int }
            .collect()
            .sink { (arr: [Int]) in
                XCTAssertEqual(arr, [1, 2, 3])
                exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func testFrozenMakeThreadSafe() {
        var exp = XCTestExpectation()
        cancellable = valuePublisher(projection)
            .freeze()
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { projection in
                XCTAssertTrue(projection.isFrozen)
                exp.fulfill()
            }

        for _ in 0..<10 {
            try! realm.write { object.int += 1 }
            wait(for: [exp], timeout: 1)
            exp = XCTestExpectation()
        }
    }

    func testMixedMakeThreadSafe() {
        let realm2 = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "test2"))
        var projections = try! realm.write {
            try! realm2.write {
                return [
                    SimpleProjection(projecting: realm.create(SimpleObject.self, value: [1])),
                    SimpleProjection(projecting: realm2.create(SimpleObject.self, value: [2])),
                    SimpleProjection(projecting: realm.create(SimpleObject.self, value: [3])),
                    SimpleProjection(projecting: realm2.create(SimpleObject.self, value: [4]))
                ]
            }
        }
        projections[2] = projections[2].freeze()
        projections[3] = projections[3].freeze()
        let exp = XCTestExpectation()
        cancellable = projections.publisher
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .map { $0.int }
            .collect()
            .sink { (arr: [Int]) in
                XCTAssertEqual(arr, [1, 2, 3, 4])
                exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func testIdentifiable() {
        let realm = realmWithTestPath()
        try! realm.write {
            realm.create(SimpleObject.self, value: [1])
            realm.create(SimpleObject.self, value: [2])
        }
        let objects = realm.objects(SimpleObject.self)
        let projections = realm.objects(SimpleProjection.self)

        XCTAssertEqual(objects[0].id, objects[0].id)
        XCTAssertEqual(objects[1].id, objects[1].id)
        XCTAssertNotEqual(objects[0].id, objects[1].id)

        XCTAssertEqual(projections[0].id, projections[0].id)
        XCTAssertEqual(projections[1].id, projections[1].id)
        XCTAssertNotEqual(projections[0].id, projections[1].id)

        XCTAssertEqual(objects[0].id, projections[0].id)
        XCTAssertEqual(objects[1].id, projections[1].id)

        let altProjection = AltSimpleProjection(projecting: objects[0])
        XCTAssertEqual(altProjection.id, projections[0].id)

        let storedId = altProjection.id
        try! realm.write {
            altProjection.int += 1
        }
        XCTAssertEqual(storedId, altProjection.id)
    }
}

@available(OSX 10.15, watchOS 6.0, iOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, tvOS 13.0, *)
class CombineAsyncRealmTests: CombinePublisherTestCase {
    func testWillChangeLocalWrite() {
        let asyncWriteExpectation = expectation(description: "Should complete async write")
        cancellable = realm
            .objectWillChange
            .sink {
                asyncWriteExpectation.fulfill()
            }

        realm.writeAsync {
            self.realm.create(SwiftIntObject.self, value: [])
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testWillChangeRemoteWrite() {
        let exp = XCTestExpectation()
        cancellable = realm.objectWillChange.sink {
            exp.fulfill()
        }
        DispatchQueue.main.async {
            let realm = try! Realm(configuration: self.realm.configuration)
            realm.writeAsync {
                realm.create(SwiftIntObject.self, value: [])
            }
        }
        wait(for: [exp], timeout: 3)
    }
}
#endif // canImport(Combine)
