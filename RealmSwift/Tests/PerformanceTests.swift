////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 Realm Inc.
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

private func createStringObjects(_ factor: Int) -> Realm {
    let realm = inMemoryRealm(factor.description)
    try! realm.write {
        for _ in 0..<(1000 * factor) {
            realm.create(SwiftStringObject.self, value: ["a"])
            realm.create(SwiftStringObject.self, value: ["b"])
        }
    }
    return realm
}

private var smallRealm: Realm!
private var mediumRealm: Realm!
private var largeRealm: Realm!

private let isRunningOnDevice = TARGET_IPHONE_SIMULATOR == 0

class SwiftPerformanceTests: TestCase {
#if swift(>=4)
    override class var defaultTestSuite: XCTestSuite {
        #if !DEBUG && os(iOS)
            if isRunningOnDevice {
                return super.defaultTestSuite
            }
        #endif
        return XCTestSuite(name: "SwiftPerformanceTests")
    }
#else
    override class func defaultTestSuite() -> XCTestSuite {
#if !DEBUG && os(iOS)
        if isRunningOnDevice {
            return super.defaultTestSuite()
        }
#endif
        return XCTestSuite(name: "SwiftPerformanceTests")
    }
#endif

    override class func setUp() {
        super.setUp()
        autoreleasepool {
            smallRealm = createStringObjects(1)
            mediumRealm = createStringObjects(5)
            largeRealm = createStringObjects(50)
        }
    }

    override class func tearDown() {
        smallRealm = nil
        mediumRealm = nil
        largeRealm = nil
        super.tearDown()
    }

    override func resetRealmState() {
        // Do nothing, as we need to keep our in-memory realms around between tests
    }

#if swift(>=4)
    override func measure(_ block: (() -> Void)) {
        super.measure {
            autoreleasepool {
                block()
            }
        }
    }

    override func measureMetrics(_ metrics: [XCTPerformanceMetric], automaticallyStartMeasuring: Bool, for block: () -> Void) {
        super.measureMetrics(metrics, automaticallyStartMeasuring: automaticallyStartMeasuring) {
            autoreleasepool {
                block()
            }
        }
    }

    func inMeasureBlock(block: () -> Void) {
        measureMetrics(type(of: self).defaultPerformanceMetrics, automaticallyStartMeasuring: false) {
            _ = block()
        }
    }

#else
    override func measure(_ block: @escaping (() -> Void)) {
        super.measure {
            autoreleasepool {
                block()
            }
        }
    }

    override func measureMetrics(_ metrics: [String], automaticallyStartMeasuring: Bool, for block: @escaping () -> Void) {
        super.measureMetrics(metrics, automaticallyStartMeasuring: automaticallyStartMeasuring) {
            autoreleasepool {
                block()
            }
        }
    }

    func inMeasureBlock(block: @escaping () -> Void) {
        measureMetrics(type(of: self).defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            _ = block()
        }
    }
#endif

    private func copyRealmToTestPath(_ realm: Realm) -> Realm {
        do {
            try FileManager.default.removeItem(at: testRealmURL())
        } catch let error as NSError {
            XCTAssertTrue(error.domain == NSCocoaErrorDomain && error.code == 4)
        } catch {
            fatalError("Unexpected error: \(error)")
        }

        try! realm.writeCopy(toFile: testRealmURL())
        return realmWithTestPath()
    }

    func testInsertMultiple() {
        inMeasureBlock {
            let realm = self.realmWithTestPath()
            self.startMeasuring()
            try! realm.write {
                for _ in 0..<5000 {
                    let obj = SwiftStringObject()
                    obj.stringCol = "a"
                    realm.add(obj)
                }
            }
            self.stopMeasuring()
            self.tearDown()
        }
    }

    func testInsertSingleLiteral() {
        inMeasureBlock {
            let realm = self.realmWithTestPath()
            self.startMeasuring()
            for _ in 0..<50 {
                try! realm.write {
                    _ = realm.create(SwiftStringObject.self, value: ["a"])
                }
            }
            self.stopMeasuring()
            self.tearDown()
        }
    }

    func testInsertMultipleLiteral() {
        inMeasureBlock {
            let realm = self.realmWithTestPath()
            self.startMeasuring()
            try! realm.write {
                for _ in 0..<5000 {
                    realm.create(SwiftStringObject.self, value: ["a"])
                }
            }
            self.stopMeasuring()
            self.tearDown()
        }
    }

    func testCountWhereQuery() {
        let realm = copyRealmToTestPath(largeRealm)
        measure {
            for _ in 0..<50 {
                let results = realm.objects(SwiftStringObject.self).filter("stringCol = 'a'")
                _ = results.count
            }
        }
    }

    func testCountWhereTableView() {
        let realm = copyRealmToTestPath(mediumRealm)
        measure {
            for _ in 0..<50 {
                let results = realm.objects(SwiftStringObject.self).filter("stringCol = 'a'")
                _ = results.first
                _ = results.count
            }
        }
    }

    func testEnumerateAndAccessQuery() {
        let realm = copyRealmToTestPath(largeRealm)
        measure {
            for stringObject in realm.objects(SwiftStringObject.self).filter("stringCol = 'a'") {
                _ = stringObject.stringCol
            }
        }
    }

    func testEnumerateAndAccessAll() {
        let realm = copyRealmToTestPath(largeRealm)
        measure {
            for stringObject in realm.objects(SwiftStringObject.self) {
                _ = stringObject.stringCol
            }
        }
    }

    func testEnumerateAndAccessAllSlow() {
        let realm = copyRealmToTestPath(largeRealm)
        measure {
            let results = realm.objects(SwiftStringObject.self)
            for i in 0..<results.count {
                _ = results[i].stringCol
            }
        }
    }

    func testEnumerateAndAccessArrayProperty() {
        let realm = copyRealmToTestPath(largeRealm)
        realm.beginWrite()
        let arrayPropertyObject = realm.create(SwiftArrayPropertyObject.self,
                                                     value: ["name", realm.objects(SwiftStringObject.self).map { $0 } as NSArray, []])
        try! realm.commitWrite()

        measure {
            for stringObject in arrayPropertyObject.array {
                _ = stringObject.stringCol
            }
        }
    }

    func testEnumerateAndAccessArrayPropertySlow() {
        let realm = copyRealmToTestPath(largeRealm)
        realm.beginWrite()
        let arrayPropertyObject = realm.create(SwiftArrayPropertyObject.self,
                                                     value: ["name", realm.objects(SwiftStringObject.self).map { $0 } as NSArray, []])
        try! realm.commitWrite()

        measure {
            let list = arrayPropertyObject.array
            for i in 0..<list.count {
                _ = list[i].stringCol
            }
        }
    }

    func testEnumerateAndMutateAll() {
        let realm = copyRealmToTestPath(largeRealm)
        measure {
            try! realm.write {
                for stringObject in realm.objects(SwiftStringObject.self) {
                    stringObject.stringCol = "c"
                }
            }
        }
    }

    func testEnumerateAndMutateQuery() {
        let realm = copyRealmToTestPath(largeRealm)
        measure {
            try! realm.write {
                for stringObject in realm.objects(SwiftStringObject.self).filter("stringCol != 'b'") {
                    stringObject.stringCol = "c"
                }
            }
        }
    }

    func testDeleteAll() {
        inMeasureBlock {
            let realm = self.copyRealmToTestPath(largeRealm)
            self.startMeasuring()
            try! realm.write {
                realm.delete(realm.objects(SwiftStringObject.self))
            }
            self.stopMeasuring()
        }
    }

    func testQueryDeletion() {
        inMeasureBlock {
            let realm = self.copyRealmToTestPath(mediumRealm)
            self.startMeasuring()
            try! realm.write {
                realm.delete(realm.objects(SwiftStringObject.self).filter("stringCol = 'a' OR stringCol = 'b'"))
            }
            self.stopMeasuring()
        }
    }

    func testManualDeletion() {
        inMeasureBlock {
            let realm = self.copyRealmToTestPath(mediumRealm)
            let objects = realm.objects(SwiftStringObject.self).map { $0 }
            self.startMeasuring()
            try! realm.write {
                realm.delete(objects)
            }
            self.stopMeasuring()
        }
    }

    func testUnindexedStringLookup() {
        let realm = realmWithTestPath()
        try! realm.write {
            for i in 0..<1000 {
                realm.create(SwiftStringObject.self, value: [i.description])
            }
        }
        measure {
            for i in 0..<1000 {
                _ = realm.objects(SwiftStringObject.self).filter("stringCol = %@", i.description).first
            }
        }
    }

    func testIndexedStringLookup() {
        let realm = realmWithTestPath()
        try! realm.write {
            for i in 0..<1000 {
                realm.create(SwiftIndexedPropertiesObject.self, value: [i.description, i])
            }
        }
        measure {
            for i in 0..<1000 {
                _ = realm.objects(SwiftIndexedPropertiesObject.self).filter("stringCol = %@", i.description).first
            }
        }
    }

    func testLargeINQuery() {
        let realm = realmWithTestPath()
        realm.beginWrite()
        var ids = [Int]()
        for i in 0..<10000 {
            realm.create(SwiftIntObject.self, value: [i])
            if i % 2 != 0 {
                ids.append(i)
            }
        }
        try! realm.commitWrite()
        measure {
            _ = realm.objects(SwiftIntObject.self).filter("intCol IN %@", ids).first
        }
    }

    func testSortingAllObjects() {
        let realm = realmWithTestPath()
        try! realm.write {
            for _ in 0..<8000 {
                let randomNumber = Int(arc4random_uniform(UInt32(INT_MAX)))
                realm.create(SwiftIntObject.self, value: [randomNumber])
            }
        }
        measure {
            _ = realm.objects(SwiftIntObject.self).sorted(byKeyPath: "intCol", ascending: true).last
        }
    }

    func testRealmCreationCached() {
        var realm: Realm!
        dispatchSyncNewThread {
            realm = try! Realm()
        }

        measure {
            for _ in 0..<250 {
                autoreleasepool {
                    _ = try! Realm()
                }
            }
        }
        _ = realm.configuration
    }

    func testRealmCreationUncached() {
        measure {
            for _ in 0..<50 {
                autoreleasepool {
                    _ = try! Realm()
                }
            }
        }
    }

    func testCommitWriteTransaction() {
        inMeasureBlock {
            let realm = inMemoryRealm("test")
            realm.beginWrite()
            let object = realm.create(SwiftIntObject.self)
            try! realm.commitWrite()

            self.startMeasuring()
            while object.intCol < 100 {
                try! realm.write { object.intCol += 1 }
            }
            self.stopMeasuring()
        }
    }

    func testCommitWriteTransactionWithLocalNotification() {
        inMeasureBlock {
            let realm = inMemoryRealm("test")
            realm.beginWrite()
            let object = realm.create(SwiftIntObject.self)
            try! realm.commitWrite()

            let token = realm.addNotificationBlock { _, _ in }
            self.startMeasuring()
            while object.intCol < 100 {
                try! realm.write { object.intCol += 1 }
            }
            self.stopMeasuring()
            token.stop()
        }
    }

    func testCommitWriteTransactionWithCrossThreadNotification() {
        let stopValue = 100
        inMeasureBlock {
            let realm = inMemoryRealm("test")
            realm.beginWrite()
            let object = realm.create(SwiftIntObject.self)
            try! realm.commitWrite()

            let queue = DispatchQueue(label: "background")
            let semaphore = DispatchSemaphore(value: 0)
            queue.async {
                autoreleasepool {
                    let realm = inMemoryRealm("test")
                    let object = realm.objects(SwiftIntObject.self).first!
                    var token: NotificationToken! = nil
                    CFRunLoopPerformBlock(CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue) {
                        token = realm.addNotificationBlock { _, _ in
                            if object.intCol == stopValue {
                                CFRunLoopStop(CFRunLoopGetCurrent())
                            }
                        }
                        semaphore.signal()
                    }
                    CFRunLoopRun()
                    token.stop()
                }
            }

            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            self.startMeasuring()
            while object.intCol < stopValue {
                try! realm.write { object.intCol += 1 }
            }
            queue.sync { }
            self.stopMeasuring()
        }
    }

    func testCrossThreadSyncLatency() {
        let stopValue = 500
        let queue = DispatchQueue(label: "background")
        let semaphore = DispatchSemaphore(value: 0)

        inMeasureBlock {
            let realm = inMemoryRealm("test")
            realm.beginWrite()
            let object = realm.create(SwiftIntObject.self)
            try! realm.commitWrite()

            queue.async {
                autoreleasepool {
                    let realm = inMemoryRealm("test")
                    let object = realm.objects(SwiftIntObject.self).first!
                    var token: NotificationToken! = nil
                    CFRunLoopPerformBlock(CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue) {
                        token = realm.addNotificationBlock { _, _ in
                            if object.intCol == stopValue {
                                CFRunLoopStop(CFRunLoopGetCurrent())
                            } else if object.intCol % 2 == 0 {
                                try! realm.write { object.intCol += 1 }
                            }
                        }
                        semaphore.signal()
                    }
                    CFRunLoopRun()
                    token.stop()
                }
            }

            let token = realm.addNotificationBlock { _, _ in
                if object.intCol % 2 == 1 && object.intCol < stopValue {
                    try! realm.write { object.intCol += 1 }
                }
            }

            _ = semaphore.wait(timeout: DispatchTime.distantFuture)

            self.startMeasuring()
            try! realm.write { object.intCol += 1 }
            while object.intCol < stopValue {
                RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date.distantFuture)
            }
            queue.sync {}
            self.stopMeasuring()
            token.stop()
        }
    }

    func testValueForKeyForListObjects() {
        let realm = try! Realm()
        try! realm.write {
            for value in 0..<10000 {
                let listObject = SwiftListOfSwiftObject()
                let object = SwiftObject()
                object.intCol = value
                object.stringCol = String(value)
                listObject.array.append(object)
                realm.add(listObject)
            }
        }
        let objects = realm.objects(SwiftListOfSwiftObject.self)
        measure {
            _ = objects.value(forKeyPath: "array") as! [List<SwiftListOfSwiftObject>]
        }
    }

    func testValueForKeyForIntObjects() {
        let realm = try! Realm()
        try! realm.write {
            for value in 0..<10000 {
                autoreleasepool {
                    let object = SwiftObject()
                    object.intCol = value
                    realm.add(object)
                }
            }
        }
        let objects = realm.objects(SwiftObject.self)
        measure {
            _ = objects.value(forKeyPath: "intCol") as! [Int]
        }
    }

    func testValueForKeyForStringObjects() {
        let realm = try! Realm()
        try! realm.write {
            for value in 0..<10000 {
                autoreleasepool {
                    let object = SwiftObject()
                    object.stringCol = String(value)
                    realm.add(object)
                }
            }
        }
        let objects = realm.objects(SwiftObject.self)
        measure {
            _ = objects.value(forKeyPath: "stringCol") as! [String]
        }
    }

    func testValueForKeyForOptionalIntObjects() {
        let realm = try! Realm()
        try! realm.write {
            for value in 0..<10000 {
                autoreleasepool {
                    let object = SwiftOptionalObject()
                    object.optIntCol.value = value
                    realm.add(object)
                }
            }
        }
        let objects = realm.objects(SwiftOptionalObject.self)
        measure {
            _ = objects.value(forKeyPath: "optIntCol") as! [Int]
        }
    }

    func testValueForKeyForOptionalStringObjects() {
        let realm = try! Realm()
        try! realm.write {
            for value in 0..<10000 {
                autoreleasepool {
                    let object = SwiftOptionalObject()
                    object.optStringCol = String(value)
                    realm.add(object)
                }
            }
        }
        let objects = realm.objects(SwiftOptionalObject.self)
        measure {
            _ = objects.value(forKeyPath: "optStringCol") as! [String]
        }
    }
}
