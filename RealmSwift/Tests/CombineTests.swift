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
import Combine
import Realm.Private
import RealmSwift

class CombineIdentifiableObject: Object, ObjectKeyIdentifiable {
    @objc dynamic var value = 0
    @objc dynamic var child: CombineIdentifiableEmbeddedObject?
}
class CombineIdentifiableEmbeddedObject: EmbeddedObject, ObjectKeyIdentifiable {
    @objc dynamic var value = 0
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
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
    if #available(macOS 10.15, watchOS 6.0, iOS 13.0, tvOS 13.0, *) {
        return true
    }
    return false
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
class ObjectIdentifiableTests: TestCase, @unchecked Sendable {
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
                realm.create(CombineIdentifiableObject.self, value: [1, [1]] as [Any]),
                realm.create(CombineIdentifiableObject.self, value: [2, [2]] as [Any])
            )
        }
        XCTAssertEqual(obj1.child!.id, obj1.child!.id)
        XCTAssertNotEqual(obj1.child!.id, obj2.child!.id)
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class CombinePublisherTestCase: TestCase, @unchecked Sendable {
    var realm: Realm!
    var cancellable: AnyCancellable?
    var notificationToken: NotificationToken?
    let subscribeOnQueue = DispatchQueue(label: "subscribe on", qos: .userInteractive, autoreleaseFrequency: .workItem)
    let receiveOnQueue = DispatchQueue(label: "receive on", qos: .userInteractive, autoreleaseFrequency: .workItem)

    override class var defaultTestSuite: XCTestSuite {
        if hasCombine() {
            return super.defaultTestSuite
        }
        return XCTestSuite(name: "\(type(of: self))")
    }

    override func setUp() {
        super.setUp()
        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "CombinePublisherTestCase"))
        XCTAssertTrue(realm.isEmpty)
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

    func watchForNotifierAdded() -> XCTestExpectation {
        // .subscribe(on:) is asynchronous, so we need to wait for the notifier
        // to be ready before we do the thing which should produce notifications
        let ex = expectation(description: "added notifier")
        subscribeOnQueue.sync {
            let r = try! Realm(configuration: realm.configuration, queue: subscribeOnQueue)
            RLMAddBeforeNotifyBlock(ObjectiveCSupport.convert(object: r)) {
                _ = r // retain the Realm until the block is released
                ex.fulfill()
            }
        }
        return ex
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class CombineRealmTests: CombinePublisherTestCase, @unchecked Sendable {
    func testWillChangeLocalWrite() {
        var called = false
        cancellable = realm
            .objectWillChange
            .sink {
            called = true
        }

        try! realm.write {
            realm.create(SwiftIntObject.self)
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
            realm.create(SwiftIntObject.self)
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
                realm.create(SwiftIntObject.self)
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
                backgroundRealm.create(SwiftIntObject.self)
            }
        }
        wait(for: [exp], timeout: 1)
    }
}

// MARK: - Object

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class CombineObjectPublisherTests: CombinePublisherTestCase, @unchecked Sendable {
    var obj: SwiftIntObject!

    override func setUp() {
        super.setUp()
        obj = try! realm.write { realm.create(SwiftIntObject.self) }
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
        let ex = watchForNotifierAdded()
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
            .sink { @Sendable arr in
                XCTAssertEqual(arr.count, 10)
                sema.signal()
            }

        wait(for: [ex], timeout: 2.0)
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
        let ex = watchForNotifierAdded()
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

        wait(for: [ex], timeout: 2.0)
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

        let ex = watchForNotifierAdded()
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
        wait(for: [ex], timeout: 2.0)

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

        let ex = watchForNotifierAdded()
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
        wait(for: [ex], timeout: 2.0)

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
        let ex = watchForNotifierAdded()
        cancellable = changesetPublisher(obj)
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                var prev: SwiftIntObject?
                for change in arr {
                    guard case .change(let obj, let properties) = change else {
                        XCTFail("Expected .change but got \(change)")
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
        wait(for: [ex], timeout: 2.0)

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
            .sink { @Sendable arr in
                for change in arr {
                    guard case .change(let obj, let properties) = change else {
                        XCTFail("Expected .change but got \(change)")
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
        let ex = watchForNotifierAdded()
        cancellable = changesetPublisher(obj)
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .receive(on: receiveOnQueue)
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                var prev: SwiftIntObject?
                for change in arr {
                    guard case .change(let obj, let properties) = change else {
                        XCTFail("Expected .change but got \(change)")
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
        wait(for: [ex], timeout: 2.0)

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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
private class CombineCollectionPublisherTests<Collection: RealmCollection>: CombinePublisherTestCase, @unchecked Sendable
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
            .sink { _ in ex.fulfill()
        }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.modifyObject() }
        wait(for: [ex], timeout: 1.0)
    }

    func testSubscribeOnKeyPathNoChange() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.collectionPublisher(keyPaths: collection.excludedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { _ in ex.fulfill()
        }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "no change notification")
        ex.isInverted = true
        try! realm.write { collection.modifyObject() }
        wait(for: [ex], timeout: 1.0)
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
            .sink { _ in ex.fulfill() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.modifyObject() }
        wait(for: [ex], timeout: 1.0)
    }

    func testChangeSetSubscribeOnKeyPathNoChange() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.changesetPublisher(keyPaths: collection.excludedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .sink { _ in ex.fulfill() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "no change notification")
        ex.isInverted = true
        try! realm.write { collection.modifyObject() }
        wait(for: [ex], timeout: 1.0)
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
            .sink { @Sendable arr in
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
            .sink { @Sendable arr in
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
            .sink { @Sendable arr in
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
            .sink { @Sendable arr in
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
            .sink { @Sendable arr in
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

extension Results: CombineTestCollection where Element == ModernAllTypesObject {
    static func getCollection(_ realm: Realm) -> Results<Element> {
        return realm.objects(Element.self)
    }

    func appendObject() {
        realm?.create(Element.self)
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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class ResultsPublisherTests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        return CombineCollectionPublisherTests<Results<ModernAllTypesObject>>.testSuite("Results")
    }
}

extension List: CombineTestCollection where Element == ModernAllTypesObject {
    static func getCollection(_ realm: Realm) -> List<Element> {
        return try! realm.write { realm.create(ModernAllTypesObject.self).arrayCol }
    }

    func appendObject() {
        append(realm!.create(Element.self))
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


@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class ManagedListPublisherTests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        return CombineCollectionPublisherTests<List<ModernAllTypesObject>>.testSuite("List")
    }
}

extension MutableSet: CombineTestCollection where Element == ModernAllTypesObject {
    static func getCollection(_ realm: Realm) -> MutableSet<Element> {
        return try! realm.write { realm.create(ModernAllTypesObject.self).setCol }
    }

    func appendObject() {
        insert(realm!.create(Element.self))
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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class ManagedMutableSetPublisherTests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        return CombineCollectionPublisherTests<MutableSet<ModernAllTypesObject>>.testSuite("MutableSet")
    }
}

extension LinkingObjects: CombineTestCollection where Element == ModernAllTypesObject {
    static func getCollection(_ realm: Realm) -> LinkingObjects<Element> {
        return try! realm.write { realm.create(ModernAllTypesObject.self).linkingObjects }
    }

    func appendObject() {
        let link = realm!.objects(ModernAllTypesObject.self).first!
        let parent = ModernAllTypesObject()
        parent.objectCol = link
        realm!.add(parent)
    }

    func modifyObject() {
        self.first!.stringCol += "concat"
    }

    var includedKeyPath: [String] {
        return ["stringCol"]
    }

    var excludedKeyPath: [String] {
        return ["intCol"]
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class LinkingObjectsPublisherTests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        return CombineCollectionPublisherTests<LinkingObjects<ModernAllTypesObject>>.testSuite("LinkingObjects")
    }
}

extension AnyRealmCollection: CombineTestCollection where Element == ModernAllTypesObject {
    static func getCollection(_ realm: Realm) -> AnyRealmCollection<Element> {
        return AnyRealmCollection(realm.objects(Element.self))
    }

    func appendObject() {
        realm?.create(Element.self)
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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class AnyRealmCollectionPublisherTests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        return CombineCollectionPublisherTests<AnyRealmCollection<ModernAllTypesObject>>.testSuite("AnyRealmCollection")
    }
}

// MARK: - Map

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
private class CombineMapPublisherTests<Collection: RealmKeyedCollection>: CombinePublisherTestCase, @unchecked Sendable
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
            .sink { _ in ex.fulfill()
        }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.modifyObject() }
        wait(for: [ex], timeout: 1.0)
    }

    func testSubscribeOnKeyPathNoChange() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.collectionPublisher(keyPaths: collection.excludedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { _ in ex.fulfill()
        }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "no change notification")
        ex.isInverted = true
        try! realm.write { collection.modifyObject() }
        wait(for: [ex], timeout: 1.0)
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
            .sink { _ in ex.fulfill()
        }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.modifyObject() }
        wait(for: [ex], timeout: 1.0)
    }

    func testChangeSetSubscribeOnKeyPathNoChange() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.changesetPublisher(keyPaths: collection.excludedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .sink { _ in ex.fulfill()
        }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "no change notification")
        ex.isInverted = true
        try! realm.write { collection.modifyObject() }
        wait(for: [ex], timeout: 1.0)
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
            .sink { @Sendable arr in
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
            .sink { @Sendable arr in
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
            .sink { @Sendable arr in
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
            .sink { @Sendable arr in
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
            .sink { @Sendable arr in
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
        return try! realm.write { realm.create(SwiftMapPropertyObject.self).swiftObjectMap }
    }

    func appendObject() {
        let key = UUID().uuidString
        self[key] = realm!.create(SwiftObject.self)
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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class ManagedMapPublisherTests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        return CombineMapPublisherTests<Map<String, SwiftObject?>>.testSuite("Map")
    }
}

// MARK: - Sectioned Results

protocol RealmSectionedObject: ObjectBase {
    associatedtype Key: _Persistable, Hashable
    var key: Key { get }
}

extension ModernAllTypesObject: RealmSectionedObject {
    var key: Int8 { int8Col } // This property will never change.
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
private class CombineSectionedResultsPublisherTests<Collection: RealmCollection>: CombinePublisherTestCase, @unchecked Sendable
    where Collection: CombineTestCollection, Collection: RealmSubscribable, Collection.Element: RealmSectionedObject {
    var collection: Collection!

    class func testSuite(_ name: String) -> XCTestSuite {
        if hasCombine() {
            // By default this test suite's name will be the generic type's
            // mangled name, which is an unreadable mess. It appears that the
            // way to override it is with a subclass with an explicit name, which
            // can't be done in pure Swift.
            let cls: AnyClass = objc_allocateClassPair(CombineSectionedResultsPublisherTests<Collection>.self, "CombineSectionedResultsPublisherTests<\(name)>", 0)!
            objc_registerClassPair(cls)
            return cls.defaultTestSuite
        }
        return XCTestSuite(name: "CombineSectionedResultsPublisherTests<\(name)>")
    }

    override func setUp() {
        super.setUp()
        collection = Collection.getCollection(realm)
    }

    func testWillChange() {
        let exp = XCTestExpectation()
        let sectionedResults = collection.sectioned(by: \.key)
        cancellable = sectionedResults.objectWillChange.sink {
            exp.fulfill()
        }
        try! realm.write { collection.appendObject() }
        wait(for: [exp], timeout: 1)

        // Test section
        let sectionExp = XCTestExpectation()
        cancellable = sectionedResults[0].objectWillChange.sink {
            sectionExp.fulfill()
        }
        try! realm.write { realm.deleteAll() }
        wait(for: [sectionExp], timeout: 1)
    }

    func testBasic() {
        var exp = XCTestExpectation()
        var calls = 0
        let sectionedResults = collection.sectioned(by: \.key)
        cancellable = sectionedResults.collectionPublisher
            .assertNoFailure()
            .sink { c in
                if c.count != 0 {
                    XCTAssertEqual(c[0].count, calls)
                }
                calls += 1
                exp.fulfill()
            }
        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
            exp = XCTestExpectation()
        }

        // Test section
        var sectionExp = XCTestExpectation()
        var sectionCalls = 10
        cancellable = sectionedResults[0].collectionPublisher
            .assertNoFailure()
            .sink { c in
                XCTAssertEqual(c.count, sectionCalls)
                sectionCalls -= 1
                sectionExp.fulfill()
            }

        for _ in 0..<sectionCalls {
            try! realm.write { realm.delete(collection.last!) }
            wait(for: [sectionExp], timeout: 10)
            sectionExp = XCTestExpectation()
        }
    }

    func testBasicWithNotificationToken() {
        var exp = XCTestExpectation()
        var calls = 0
        let sectionedResults = collection.sectioned(by: \.key)
        cancellable = sectionedResults.collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .assertNoFailure()
            .sink { c in
                if c.count != 0 {
                    XCTAssertEqual(c[0].count, calls)
                }
                calls += 1
                exp.fulfill()
            }
        XCTAssertNotNil(notificationToken)
        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
            exp = XCTestExpectation()
        }

        var sectionExp = XCTestExpectation()
        var sectionCalls = 10
        notificationToken = nil
        cancellable = sectionedResults[0].collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .assertNoFailure()
            .sink { c in
                XCTAssertEqual(c.count, sectionCalls)
                sectionCalls -= 1
                sectionExp.fulfill()
            }
        XCTAssertNotNil(notificationToken)
        for _ in 0..<sectionCalls {
            try! realm.write { realm.delete(collection.last!) }
            wait(for: [sectionExp], timeout: 10)
            sectionExp = XCTestExpectation()
        }
    }

    func testBasicWithoutNotifying() {
        var calls = 0
        let sectionedResults = collection.sectioned(by: \.key)
        cancellable = sectionedResults
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

        var sectionCalls = 0
        notificationToken = nil
        cancellable = sectionedResults[0]
            .collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .assertNoFailure()
            .sink { _ in
                sectionCalls -= 1
            }
        XCTAssertNotNil(notificationToken)
        for _ in 0..<9 {
            try! realm.write(withoutNotifying: [notificationToken!]) { realm.delete(collection.last!) }
            XCTAssertEqual(calls, 1) // 1 for the initial notification
        }
    }

    func checkChangeset<SectionedResults: RealmSectionedResult>(
            _ change: SectionedResultsChange<SectionedResults>,
            insertions: [IndexPath] = [], deletions: [IndexPath] = [], frozen: Bool = false) {
        switch change {
        case .initial(let collection):
            XCTAssertEqual(collection.isFrozen, frozen)
        case .update(let collection, deletions: let del, insertions: let ins,
                     modifications: let modifications, _, _):
            XCTAssertEqual(collection.isFrozen, frozen)
            XCTAssertEqual(ins, insertions)
            XCTAssertEqual(del, deletions)
            XCTAssertEqual(modifications, [])
        }
    }

    func testChangeSet() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        let sectionedResults = collection.sectioned(by: \.key)
        cancellable = sectionedResults.changesetPublisher
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: calls - 1, section: 0)])
                calls += 1
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }

        var sectionExp = XCTestExpectation(description: "change")
        var sectionCalls = 10
        cancellable = sectionedResults[0].changesetPublisher
            .sink { change in
                self.checkChangeset(change, deletions: [IndexPath(item: sectionCalls, section: 0)])
                sectionCalls -= 1
                sectionExp.fulfill()
            }
        for _ in 0..<9 {
            sectionExp = XCTestExpectation(description: "change")
            try! realm.write { realm.delete(collection.last!) }
            wait(for: [sectionExp], timeout: 10)
        }
    }

    func testChangeSetWithToken() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        let sectionedResults = collection.sectioned(by: \.key)
        cancellable = sectionedResults
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: calls - 1, section: 0)])
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

        var sectionExp = XCTestExpectation(description: "change")
        var sectionCalls = 10
        notificationToken = nil
        cancellable = sectionedResults[0]
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .sink { change in
                self.checkChangeset(change, deletions: [IndexPath(item: sectionCalls, section: 0)])
                sectionCalls -= 1
                sectionExp.fulfill()
            }
        XCTAssertNotNil(notificationToken)

        for _ in 0..<9 {
            sectionExp = XCTestExpectation(description: "change")
            try! realm.write { realm.delete(collection.last!) }
            wait(for: [sectionExp], timeout: 10)
        }
    }

    func testChangeSetWithoutNotifying() {
        var calls = 0
        let sectionedResults = collection.sectioned(by: \.key)
        cancellable = sectionedResults
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

        var sectionCalls = 0
        cancellable = sectionedResults[0]
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .sink { _ in
                sectionCalls += 1
            }
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            try! realm.write(withoutNotifying: [notificationToken!]) { collection.appendObject() }
            XCTAssertEqual(sectionCalls, 1) // 1 for the initial observation
        }
    }

    func testSubscribeOn() {
        let sema = DispatchSemaphore(value: 0)
        var calls = 0
        let sectionedResults = collection.sectioned(by: \.key)
        cancellable = sectionedResults
            .collectionPublisher
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { r in
                if r.count != 0 {
                    XCTAssertEqual(r[0].count, calls)
                }
                calls += 1
                sema.signal()
        }
        sema.wait()

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            sema.wait()
        }

        var sectionCalls = collection.count
        cancellable = sectionedResults[0]
            .collectionPublisher
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, sectionCalls)
                sectionCalls += 1
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
        let sectionedResults = collection.sectioned(by: \.key)

        cancellable = sectionedResults.collectionPublisher(keyPaths: collection.includedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { _ in ex.fulfill()
        }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.modifyObject() }
        wait(for: [ex], timeout: 1.0)

        cancellable?.cancel()
        var sectionEx = expectation(description: "initial notification")

        cancellable = sectionedResults[0].collectionPublisher(keyPaths: collection.includedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { _ in
                sectionEx.fulfill()
        }
        wait(for: [sectionEx], timeout: 1.0)

        sectionEx = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [sectionEx], timeout: 1.0)

        sectionEx = expectation(description: "change notification")
        try! realm.write { collection.modifyObject() }
        wait(for: [sectionEx], timeout: 1.0)
    }

    func testSubscribeOnKeyPathNoChange() {
        var ex = expectation(description: "initial notification")
        let sectionedResults = collection.sectioned(by: \.key)

        cancellable = sectionedResults.collectionPublisher(keyPaths: collection.excludedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { _ in ex.fulfill()
        }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "no change notification")
        ex.isInverted = true
        try! realm.write { collection.modifyObject() }
        wait(for: [ex], timeout: 1.0)

        var sectionEx = expectation(description: "initial notification")
        cancellable?.cancel()
        cancellable = sectionedResults[0].collectionPublisher(keyPaths: collection.excludedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { _ in
                sectionEx.fulfill()
        }
        wait(for: [sectionEx], timeout: 1.0)

        sectionEx = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [sectionEx], timeout: 1.0)

        sectionEx = expectation(description: "no change notification")
        sectionEx.isInverted = true
        try! realm.write { collection.modifyObject() }
        wait(for: [sectionEx], timeout: 1.0)
    }

    func testSubscribeOnWithToken() {
        let sema = DispatchSemaphore(value: 0)
        var calls = 0
        let sectionedResults = collection.sectioned(by: \.key)

        cancellable = sectionedResults
            .collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { r in
                if r.count != 0 {
                    XCTAssertEqual(r[0].count, calls)
                }
                calls += 1
                sema.signal()
        }
        sema.wait()
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            sema.wait()
        }

        var sectionCalls = collection.count
        cancellable = sectionedResults[0]
            .collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .subscribe(on: subscribeOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, sectionCalls)
                sectionCalls += 1
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

        cancellable = collection.sectioned(by: \.key).collectionPublisher
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { r in
                if r.count != 0 {
                    XCTAssertEqual(r[0].count, calls)
                }
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }

        var sectionCalls = collection.count
        var sectionExp = XCTestExpectation(description: "initial")

        cancellable = collection.sectioned(by: \.key)[0].collectionPublisher
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, sectionCalls)
                sectionCalls += 1
                sectionExp.fulfill()
        }
        wait(for: [sectionExp], timeout: 10)

        for _ in 0..<10 {
            sectionExp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [sectionExp], timeout: 10)
        }
    }

    func testReceiveOnWithToken() {
        var calls = 0
        var exp = XCTestExpectation(description: "initial")
        cancellable = collection.sectioned(by: \.key)
            .collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { r in
                if r.count != 0 {
                    XCTAssertEqual(r[0].count, calls)
                }
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

        var sectionCalls = collection.count
        var sectionExp = XCTestExpectation(description: "initial")
        cancellable = collection.sectioned(by: \.key)[0]
            .collectionPublisher
            .saveToken(on: self, at: \.notificationToken)
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { r in
                if r.count != 0 {
                    XCTAssertEqual(r.count, sectionCalls)
                }
                sectionCalls += 1
                sectionExp.fulfill()
        }
        wait(for: [sectionExp], timeout: 10)
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            sectionExp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [sectionExp], timeout: 10)
        }
    }

    func testChangeSetSubscribeOn() {
        var calls = 0
        let sema = DispatchSemaphore(value: 0)
        cancellable = collection.sectioned(by: \.key)
            .changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: calls - 1, section: 0)])
                calls += 1
                sema.signal()
        }
        sema.wait()

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            sema.wait()
        }

        var sectionCalls = collection.count
        cancellable = collection.sectioned(by: \.key)
            .changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: sectionCalls - 1, section: 0)])
                sectionCalls += 1
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

        cancellable = collection.sectioned(by: \.key)
            .changesetPublisher(keyPaths: collection.includedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .sink { _ in ex.fulfill()
        }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write {
            collection.appendObject()

        }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write {
            collection.modifyObject()

        }
        wait(for: [ex], timeout: 1.0)

        var sectionEx = expectation(description: "initial notification")

        cancellable = collection.sectioned(by: \.key)[0]
            .changesetPublisher(keyPaths: collection.includedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .sink { _ in sectionEx.fulfill()
        }
        wait(for: [sectionEx], timeout: 1.0)

        sectionEx = expectation(description: "change notification")
        try! realm.write {
            collection.appendObject()
        }
        wait(for: [sectionEx], timeout: 1.0)

        sectionEx = expectation(description: "change notification")
        try! realm.write {
            collection.modifyObject()
        }
        wait(for: [sectionEx], timeout: 1.0)
    }

    func testChangeSetSubscribeOnKeyPathNoChange() {
        var ex = expectation(description: "initial notification")

        cancellable = collection.sectioned(by: \.key)
            .changesetPublisher(keyPaths: collection.excludedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .sink { _ in ex.fulfill()
        }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [ex], timeout: 1.0)

        ex = expectation(description: "no change notification")
        ex.isInverted = true
        try! realm.write { collection.modifyObject() }
        wait(for: [ex], timeout: 1.0)

        var sectionEx = expectation(description: "initial notification")

        cancellable = collection.sectioned(by: \.key)[0]
            .changesetPublisher(keyPaths: collection.excludedKeyPath)
            .subscribe(on: subscribeOnQueue)
            .sink { _ in sectionEx.fulfill()
        }
        wait(for: [sectionEx], timeout: 1.0)

        sectionEx = expectation(description: "change notification")
        try! realm.write { collection.appendObject() }
        wait(for: [sectionEx], timeout: 1.0)

        sectionEx = expectation(description: "no change notification")
        sectionEx.isInverted = true
        try! realm.write { collection.modifyObject() }
        wait(for: [sectionEx], timeout: 1.0)

    }

    func testChangeSetSubscribeOnWithToken() {
        var calls = 0
        let sema = DispatchSemaphore(value: 0)
        cancellable = collection
            .sectioned(by: \.key)
            .changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .saveToken(on: self, at: \.notificationToken)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: calls - 1, section: 0)])
                calls += 1
                sema.signal()
        }
        sema.wait()
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            try! realm.write { collection.appendObject() }
            sema.wait()
        }

        var sectionCalls = collection.count
        cancellable = collection
            .sectioned(by: \.key)[0]
            .changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .saveToken(on: self, at: \.notificationToken)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: sectionCalls - 1, section: 0)])
                sectionCalls += 1
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
        cancellable = collection.sectioned(by: \.key)
            .changesetPublisher
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: calls - 1, section: 0)])
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }

        var sectionExp = XCTestExpectation(description: "initial")
        var sectionCalls = collection.count
        cancellable = collection.sectioned(by: \.key)[0]
            .changesetPublisher
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: sectionCalls - 1, section: 0)])
                sectionCalls += 1
                sectionExp.fulfill()
        }
        wait(for: [sectionExp], timeout: 10)

        for _ in 0..<10 {
            sectionExp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [sectionExp], timeout: 10)
        }
    }

    func testChangeSetReceiveOnWithToken() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        cancellable = collection
            .sectioned(by: \.key)
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: calls - 1, section: 0)])
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

        var sectionExp = XCTestExpectation(description: "initial")
        var sectionCalls = collection.count
        cancellable = collection
            .sectioned(by: \.key)[0]
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: sectionCalls - 1, section: 0)])
                sectionCalls += 1
                sectionExp.fulfill()
        }
        wait(for: [sectionExp], timeout: 10)
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            sectionExp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [sectionExp], timeout: 10)
        }
    }

    func testMakeThreadSafe() {
        var calls = 0
        var exp = XCTestExpectation(description: "initial")
        cancellable = collection
            .sectioned(by: \.key)
            .collectionPublisher
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { r in
                if r.count != 0 {
                    XCTAssertEqual(r[0].count, calls)
                }
                calls += 1
                exp.fulfill()
            }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }

        var sectionCalls = collection.count
        var sectionExp = XCTestExpectation(description: "initial")
        cancellable = collection
            .sectioned(by: \.key)[0]
            .collectionPublisher
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .assertNoFailure()
            .sink { r in
                XCTAssertEqual(r.count, sectionCalls)
                sectionCalls += 1
                sectionExp.fulfill()
            }
        wait(for: [sectionExp], timeout: 10)

        for _ in 0..<10 {
            sectionExp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [sectionExp], timeout: 10)
        }
    }

    func testMakeThreadSafeChangeset() {
        var exp = XCTestExpectation(description: "initial")
        var calls = 0
        cancellable = collection.sectioned(by: \.key)
            .changesetPublisher
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: calls - 1, section: 0)])
                calls += 1
                exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        for _ in 0..<10 {
            exp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [exp], timeout: 10)
        }

        var sectionExp = XCTestExpectation(description: "initial")
        var sectionCalls = collection.count
        cancellable = collection.sectioned(by: \.key)[0]
            .changesetPublisher
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: sectionCalls - 1, section: 0)])
                sectionCalls += 1
                sectionExp.fulfill()
        }
        wait(for: [sectionExp], timeout: 10)

        for _ in 0..<10 {
            sectionExp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [sectionExp], timeout: 10)
        }
    }

    func testMakeThreadSafeWithChangesetToken() {
        var calls = 0
        var exp = XCTestExpectation(description: "initial")
        cancellable = collection
            .sectioned(by: \.key)
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: calls - 1, section: 0)])
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

        var sectionCalls = collection.count
        var sectionExp = XCTestExpectation(description: "initial")
        cancellable = collection
            .sectioned(by: \.key)[0]
            .changesetPublisher
            .saveToken(on: self, at: \.notificationToken)
            .map { $0 }
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .sink { change in
                self.checkChangeset(change, insertions: [IndexPath(item: sectionCalls - 1, section: 0)])
                sectionCalls += 1
                sectionExp.fulfill()
        }
        wait(for: [sectionExp], timeout: 10)
        XCTAssertNotNil(notificationToken)

        for _ in 0..<10 {
            sectionExp = XCTestExpectation(description: "change")
            try! realm.write { collection.appendObject() }
            wait(for: [sectionExp], timeout: 10)
        }
    }

    func testFrozen() {
        let exp = XCTestExpectation()
        let objectsCount = 10

        cancellable = collection.sectioned(by: \.key)
            .collectionPublisher
            .freeze()
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { sections in
                XCTAssertEqual(sections.count, 10)
                for (i, collection) in sections.enumerated() {
                    XCTAssertTrue(collection.isFrozen)
                    if collection.count != 0 {
                        XCTAssertEqual(collection[0].count, i)
                    }
                }
                exp.fulfill()
        }

        for _ in 0..<objectsCount {
            try! realm.write { collection.appendObject() }
        }
        wait(for: [exp], timeout: 10)

        let sectionExp = XCTestExpectation()
        cancellable = collection.sectioned(by: \.key)[0]
            .collectionPublisher
            .freeze()
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                XCTAssertEqual(arr.count, 10)
                for (i, collection) in arr.enumerated() {
                    XCTAssertTrue(collection.isFrozen)
                    XCTAssertEqual(collection.count - objectsCount, i)
                }
                sectionExp.fulfill()
        }

        for _ in 0..<objectsCount {
            try! realm.write { collection.appendObject() }
        }
        wait(for: [sectionExp], timeout: 10)
    }

    func testFrozenChangeSetSubscribeOn() {
        let sema = DispatchSemaphore(value: 0)
        let objectsCount = 10

        cancellable = collection.sectioned(by: \.key)
            .changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .assertNoFailure()
            .signal(sema)
            .prefix(10)
            .collect()
            .sink { @Sendable arr in
                XCTAssertEqual(arr.count, 10)
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, insertions: [IndexPath(item: i - 1, section: 0)], frozen: true)
                }
                sema.signal()
            }

        for _ in 0..<objectsCount {
            sema.wait()
            try! realm.write { collection.appendObject() }
        }
        sema.wait()

        cancellable = collection.sectioned(by: \.key)[0]
            .changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .assertNoFailure()
            .signal(sema)
            .prefix(10)
            .collect()
            .sink { @Sendable arr in
                XCTAssertEqual(arr.count, objectsCount)
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, insertions: [IndexPath(item: (i + objectsCount) - 1, section: 0)], frozen: true)
                }
                sema.signal()
            }

        for _ in 0..<objectsCount {
            sema.wait()
            try! realm.write { collection.appendObject() }
        }
        sema.wait()
    }

    func testFrozenChangeSetReceiveOn() {
        let exp = XCTestExpectation()
        let objectsCount = 10

        cancellable = collection.sectioned(by: \.key)
            .changesetPublisher
            .freeze()
            .receive(on: receiveOnQueue)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                XCTAssertEqual(arr.count, 10)
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, insertions: [IndexPath(item: i - 1, section: 0)], frozen: true)
                }
                exp.fulfill()
        }

        for _ in 0..<objectsCount {
            try! realm.write { collection.appendObject() }
        }
        wait(for: [exp], timeout: 10)

        let sectionExp = XCTestExpectation()
        cancellable = collection.sectioned(by: \.key)[0]
            .changesetPublisher
            .freeze()
            .receive(on: receiveOnQueue)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                XCTAssertEqual(arr.count, objectsCount)
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, insertions: [IndexPath(item: (i + objectsCount) - 1, section: 0)], frozen: true)
                }
                sectionExp.fulfill()
        }

        for _ in 0..<objectsCount {
            try! realm.write { collection.appendObject() }
        }
        wait(for: [sectionExp], timeout: 10)
    }

    func testFrozenChangeSetSubscribeOnAndReceiveOn() {
        let sema = DispatchSemaphore(value: 0)
        let objectsCount = 10

        cancellable = collection.sectioned(by: \.key)
            .changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .receive(on: receiveOnQueue)
            .signal(sema)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, insertions: [IndexPath(item: i - 1, section: 0)], frozen: true)
                }
                sema.signal()
        }

        for _ in 0..<objectsCount {
            sema.wait()
            try! realm.write { collection.appendObject() }
        }
        sema.wait()

        cancellable = collection.sectioned(by: \.key)[0]
            .changesetPublisher
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .receive(on: receiveOnQueue)
            .signal(sema)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, insertions: [IndexPath(item: (i + objectsCount) - 1, section: 0)], frozen: true)
                }
                sema.signal()
        }

        for _ in 0..<objectsCount {
            sema.wait()
            try! realm.write { collection.appendObject() }
        }
        sema.wait()
    }

    func testFrozenMakeThreadSafe() {
        let sema = DispatchSemaphore(value: 0)
        let objectsCount = 10

        cancellable = collection.sectioned(by: \.key)
            .collectionPublisher
            .freeze()
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                for (i, collection) in arr.enumerated() {
                    XCTAssertTrue(collection.isFrozen)
                    if collection.count != 0 {
                        XCTAssertEqual(collection.count, 1)
                        XCTAssertEqual(collection[0].count, i)
                    }
                }
                sema.signal()
            }

        for _ in 0..<objectsCount {
            try! realm.write { collection.appendObject() }
        }
        sema.wait()

        cancellable = collection.sectioned(by: \.key)[0]
            .collectionPublisher
            .freeze()
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                for (i, collection) in arr.enumerated() {
                    XCTAssertTrue(collection.isFrozen)
                    if collection.count != 0 {
                        XCTAssertEqual(collection.count, i + objectsCount)
                    }
                }
                sema.signal()
            }

        for _ in 0..<objectsCount {
            try! realm.write { collection.appendObject() }
        }
        sema.wait()
    }

    func testFrozenMakeThreadSafeChangeset() {
        let exp = XCTestExpectation()
        let objectsCount = 10

        cancellable = collection.sectioned(by: \.key)
            .changesetPublisher
            .freeze()
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, insertions: [IndexPath(item: i - 1, section: 0)], frozen: true)
                }
                exp.fulfill()
        }

        for _ in 0..<objectsCount {
            try! realm.write { collection.appendObject() }
        }
        wait(for: [exp], timeout: 10)

        let sectionExp = XCTestExpectation()
        cancellable = collection.sectioned(by: \.key)[0]
            .changesetPublisher
            .freeze()
            .threadSafeReference()
            .receive(on: receiveOnQueue)
            .prefix(10)
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                for (i, change) in arr.enumerated() {
                    self.checkChangeset(change, insertions: [IndexPath(item: (i + objectsCount) - 1, section: 0)], frozen: true)
                }
                sectionExp.fulfill()
        }

        for _ in 0..<objectsCount {
            try! realm.write { collection.appendObject() }
        }
        wait(for: [sectionExp], timeout: 10)
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
// swiftlint:disable:next type_name
class ResultsWithSectionedResultsPublisherTests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        return CombineSectionedResultsPublisherTests<Results<ModernAllTypesObject>>.testSuite("Results")
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
// swiftlint:disable:next type_name
class ManagedListSectionedResultsPublisherTests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        return CombineSectionedResultsPublisherTests<List<ModernAllTypesObject>>.testSuite("List")
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
// swiftlint:disable:next type_name
class ManagedMutableSetSectionedResultsPublisherTests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        return CombineSectionedResultsPublisherTests<MutableSet<ModernAllTypesObject>>.testSuite("MutableSet")
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
// swiftlint:disable:next type_name
class LinkingObjectsSectionedResultsPublisherTests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        return CombineSectionedResultsPublisherTests<LinkingObjects<ModernAllTypesObject>>.testSuite("LinkingObjects")
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
// swiftlint:disable:next type_name
class AnyRealmCollectionSectionedResultsPublisherTests: TestCase, @unchecked Sendable {
    override class var defaultTestSuite: XCTestSuite {
        return CombineSectionedResultsPublisherTests<AnyRealmCollection<ModernAllTypesObject>>.testSuite("AnyRealmCollection")
    }
}

// MARK: - Projection

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension SimpleObject: ObjectKeyIdentifiable {
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension SimpleProjection: ObjectKeyIdentifiable {
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class AltSimpleProjection: Projection<SimpleObject>, ObjectKeyIdentifiable {
    @Projected(\SimpleObject.int) var int
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class CombineProjectionPublisherTests: CombinePublisherTestCase, @unchecked Sendable {

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
        let ex = watchForNotifierAdded()
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
            .sink { @Sendable arr in
                XCTAssertEqual(arr.count, 10)
                sema.signal()
            }
        wait(for: [ex], timeout: 2.0)

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

        let ex = watchForNotifierAdded()
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
        wait(for: [ex], timeout: 2.0)

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

        let ex = watchForNotifierAdded()
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
        wait(for: [ex], timeout: 2.0)

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

        let ex = watchForNotifierAdded()
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
        wait(for: [ex], timeout: 2.0)

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
            .sink { @Sendable arr in
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

    func testFrozenPublisherSubscribeOn() {
        let setupEx = watchForNotifierAdded()
        let completeEx = expectation(description: "pipeline complete")
        var gotValueEx: XCTestExpectation!
        cancellable = valuePublisher(projection)
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .map { (v: SimpleProjection) -> SimpleProjection in
                gotValueEx.fulfill()
                return v
            }
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                XCTAssertEqual(arr.count, 10)
                for i in 0..<10 {
                    XCTAssertEqual(arr[i].int, i + 1)
                }
                completeEx.fulfill()
            }
        wait(for: [setupEx], timeout: 2.0)
        for _ in 0..<10 {
            gotValueEx = expectation(description: "got value")
            try! realm.write { object.int += 1 }
            wait(for: [gotValueEx], timeout: 2.0)
        }
        try! realm.write { realm.delete(object) }
        wait(for: [completeEx], timeout: 1)
    }

    func testFrozenChangeSetSubscribeOn() {
        let setupEx = watchForNotifierAdded()
        let sema = DispatchSemaphore(value: 0)
        cancellable = changesetPublisher(projection)
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                var prev: SimpleProjection?
                for change in arr {
                    guard case .change(let p, let properties) = change else {
                        XCTFail("Expected .change but got \(change)")
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
        wait(for: [setupEx], timeout: 2.0)

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
            .sink { @Sendable arr in
                for change in arr {
                    guard case .change(let p, let properties) = change else {
                        XCTFail("Expected .change but got \(change)")
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
        let setupEx = watchForNotifierAdded()
        let sema = DispatchSemaphore(value: 0)
        cancellable = changesetPublisher(projection)
            .subscribe(on: subscribeOnQueue)
            .freeze()
            .receive(on: receiveOnQueue)
            .collect()
            .assertNoFailure()
            .sink { @Sendable arr in
                var prev: SimpleProjection?
                for change in arr {
                    guard case .change(let p, let properties) = change else {
                        XCTFail("Expected .change but got \(change)")
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
        wait(for: [setupEx], timeout: 2.0)

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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class CombineAsyncRealmTests: CombinePublisherTestCase, @unchecked Sendable {
    @MainActor
    func testWillChangeLocalWrite() {
        let asyncWriteExpectation = expectation(description: "Should complete async write")
        cancellable = realm.objectWillChange.sink {
                asyncWriteExpectation.fulfill()
            }

        realm.writeAsync {
            self.realm.create(SwiftIntObject.self)
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testWillChangeRemoteWrite() {
        let exp = XCTestExpectation()
        cancellable = realm.objectWillChange.sink {
            exp.fulfill()
        }
        queue.async {
            let realm = try! Realm(configuration: self.realm.configuration, queue: self.queue)
            realm.writeAsync {
                realm.create(SwiftIntObject.self)
            }
        }
        wait(for: [exp], timeout: 3)
    }
}
