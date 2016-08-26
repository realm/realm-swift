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

#if swift(>=3.0)

private func createStringObjects(_ factor: Int) -> Realm {
    let realm = inMemoryRealm(factor.description)
    try! realm.write {
        for _ in 0..<(1000 * factor) {
            realm.createObject(ofType: SwiftStringObject.self, populatedWith: ["a"])
            realm.createObject(ofType: SwiftStringObject.self, populatedWith: ["b"])
        }
    }
    return realm
}

private var smallRealm: Realm!
private var mediumRealm: Realm!
private var largeRealm: Realm!

private let isRunningOnDevice = TARGET_IPHONE_SIMULATOR == 0

class SwiftPerformanceTests: TestCase {
    override class func defaultTestSuite() -> XCTestSuite {
#if !DEBUG && os(iOS)
        if isRunningOnDevice {
            return super.defaultTestSuite()
        }
#endif
        return XCTestSuite(name: "SwiftPerformanceTests")
    }

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

    override func measure(_ block: (() -> Void)) {
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

    func inMeasureBlock(block: @escaping () -> ()) {
        measureMetrics(type(of: self).defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            _ = block()
        }
    }

    private func copyRealmToTestPath(_ realm: Realm) -> Realm {
        do {
            try FileManager.default.removeItem(at: testRealmURL())
        } catch let error as NSError {
            XCTAssertTrue(error.domain == NSCocoaErrorDomain && error.code == 4)
        } catch {
            fatalError("Unexpected error: \(error)")
        }

        try! realm.writeCopy(toFileURL: testRealmURL())
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
                    _ = realm.createObject(ofType: SwiftStringObject.self, populatedWith: ["a"])
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
                    realm.createObject(ofType: SwiftStringObject.self, populatedWith: ["a"])
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
                let results = realm.allObjects(ofType: SwiftStringObject.self).filter(using: "stringCol = 'a'")
                _ = results.count
            }
        }
    }

    func testCountWhereTableView() {
        let realm = copyRealmToTestPath(mediumRealm)
        measure {
            for _ in 0..<50 {
                let results = realm.allObjects(ofType: SwiftStringObject.self).filter(using: "stringCol = 'a'")
                _ = results.first
                _ = results.count
            }
        }
    }

    func testEnumerateAndAccessQuery() {
        let realm = copyRealmToTestPath(largeRealm)
        measure {
            for stringObject in realm.allObjects(ofType: SwiftStringObject.self).filter(using: "stringCol = 'a'") {
                _ = stringObject.stringCol
            }
        }
    }

    func testEnumerateAndAccessAll() {
        let realm = copyRealmToTestPath(largeRealm)
        measure {
            for stringObject in realm.allObjects(ofType: SwiftStringObject.self) {
                _ = stringObject.stringCol
            }
        }
    }

    func testEnumerateAndAccessAllSlow() {
        let realm = copyRealmToTestPath(largeRealm)
        measure {
            let results = realm.allObjects(ofType: SwiftStringObject.self)
            for i in 0..<results.count {
                _ = results[i].stringCol
            }
        }
    }

    func testEnumerateAndAccessArrayProperty() {
        let realm = copyRealmToTestPath(largeRealm)
        realm.beginWrite()
        let arrayPropertyObject = realm.createObject(ofType: SwiftArrayPropertyObject.self,
                                                     populatedWith: ["name", realm.allObjects(ofType: SwiftStringObject.self).map { $0 } as NSArray, []])
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
        let arrayPropertyObject = realm.createObject(ofType: SwiftArrayPropertyObject.self,
                                                     populatedWith: ["name", realm.allObjects(ofType: SwiftStringObject.self).map { $0 } as NSArray, []])
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
                for stringObject in realm.allObjects(ofType: SwiftStringObject.self) {
                    stringObject.stringCol = "c"
                }
            }
        }
    }

    func testEnumerateAndMutateQuery() {
        let realm = copyRealmToTestPath(largeRealm)
        measure {
            try! realm.write {
                for stringObject in realm.allObjects(ofType: SwiftStringObject.self).filter(using: "stringCol != 'b'") {
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
                realm.delete(realm.allObjects(ofType: SwiftStringObject.self))
            }
            self.stopMeasuring()
        }
    }

    func testQueryDeletion() {
        inMeasureBlock {
            let realm = self.copyRealmToTestPath(mediumRealm)
            self.startMeasuring()
            try! realm.write {
                realm.delete(realm.allObjects(ofType: SwiftStringObject.self).filter(using: "stringCol = 'a' OR stringCol = 'b'"))
            }
            self.stopMeasuring()
        }
    }

    func testManualDeletion() {
        inMeasureBlock {
            let realm = self.copyRealmToTestPath(mediumRealm)
            let objects = realm.allObjects(ofType: SwiftStringObject.self).map { $0 }
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
                realm.createObject(ofType: SwiftStringObject.self, populatedWith: [i.description])
            }
        }
        measure {
            for i in 0..<1000 {
                _ = realm.allObjects(ofType: SwiftStringObject.self).filter(using: "stringCol = %@", i.description).first
            }
        }
    }

    func testIndexedStringLookup() {
        let realm = realmWithTestPath()
        try! realm.write {
            for i in 0..<1000 {
                realm.createObject(ofType: SwiftIndexedPropertiesObject.self, populatedWith: [i.description, i])
            }
        }
        measure {
            for i in 0..<1000 {
                _ = realm.allObjects(ofType: SwiftIndexedPropertiesObject.self).filter(using: "stringCol = %@", i.description).first
            }
        }
    }

    func testLargeINQuery() {
        let realm = realmWithTestPath()
        realm.beginWrite()
        var ids = [Int]()
        for i in 0..<10000 {
            realm.createObject(ofType: SwiftIntObject.self, populatedWith: [i])
            if i % 2 != 0 {
                ids.append(i)
            }
        }
        try! realm.commitWrite()
        measure {
            _ = realm.allObjects(ofType: SwiftIntObject.self).filter(using: "intCol IN %@", ids).first
        }
    }

    func testSortingAllObjects() {
        let realm = realmWithTestPath()
        try! realm.write {
            for _ in 0..<8000 {
                let randomNumber = Int(arc4random_uniform(UInt32(INT_MAX)))
                realm.createObject(ofType: SwiftIntObject.self, populatedWith: [randomNumber])
            }
        }
        measure {
            _ = realm.allObjects(ofType: SwiftIntObject.self).sorted(onProperty: "intCol", ascending: true).last
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
            let object = realm.createObject(ofType: SwiftIntObject.self)
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
            let object = realm.createObject(ofType: SwiftIntObject.self)
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
            let object = realm.createObject(ofType: SwiftIntObject.self)
            try! realm.commitWrite()

            let queue = DispatchQueue(label: "background")
            let semaphore = DispatchSemaphore(value: 0)
            queue.async {
                autoreleasepool {
                    let realm = inMemoryRealm("test")
                    let object = realm.allObjects(ofType: SwiftIntObject.self).first!
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
            let object = realm.createObject(ofType: SwiftIntObject.self)
            try! realm.commitWrite()

            queue.async {
                autoreleasepool {
                    let realm = inMemoryRealm("test")
                    let object = realm.allObjects(ofType: SwiftIntObject.self).first!
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
            queue.sync() {}
            self.stopMeasuring()
            token.stop()
        }
    }
}

#else

private func createStringObjects(factor: Int) -> Realm {
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
    override class func defaultTestSuite() -> XCTestSuite {
#if !DEBUG && os(iOS)
        if isRunningOnDevice {
            return super.defaultTestSuite()
        }
#endif
        return XCTestSuite(name: "SwiftPerformanceTests")
    }

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

    override func measureBlock(block: (() -> Void)) {
        super.measureBlock {
            autoreleasepool {
                block()
            }
        }
    }

    override func measureMetrics(metrics: [String], automaticallyStartMeasuring: Bool, forBlock block: () -> Void) {
        super.measureMetrics(metrics, automaticallyStartMeasuring: automaticallyStartMeasuring) {
            autoreleasepool {
                block()
            }
        }
    }

    func inMeasureBlock(block: () -> ()) {
        measureMetrics(self.dynamicType.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) {
            _ = block()
        }
    }

    private func copyRealmToTestPath(realm: Realm) -> Realm {
        do {
            try NSFileManager.defaultManager().removeItemAtURL(testRealmURL())
        } catch let error as NSError {
            XCTAssertTrue(error.domain == NSCocoaErrorDomain && error.code == 4)
        } catch {
            fatalError("Unexpected error: \(error)")
        }

        try! realm.writeCopyToURL(testRealmURL())
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
        measureBlock {
            for _ in 0..<50 {
                let results = realm.objects(SwiftStringObject.self).filter("stringCol = 'a'")
                _ = results.count
            }
        }
    }

    func testCountWhereTableView() {
        let realm = copyRealmToTestPath(mediumRealm)
        measureBlock {
            for _ in 0..<50 {
                let results = realm.objects(SwiftStringObject.self).filter("stringCol = 'a'")
                _ = results.first
                _ = results.count
            }
        }
    }

    func testEnumerateAndAccessQuery() {
        let realm = copyRealmToTestPath(largeRealm)
        measureBlock {
            for stringObject in realm.objects(SwiftStringObject.self).filter("stringCol = 'a'") {
                _ = stringObject.stringCol
            }
        }
    }

    func testEnumerateAndAccessAll() {
        let realm = copyRealmToTestPath(largeRealm)
        measureBlock {
            for stringObject in realm.objects(SwiftStringObject.self) {
                _ = stringObject.stringCol
            }
        }
    }

    func testEnumerateAndAccessAllSlow() {
        let realm = copyRealmToTestPath(largeRealm)
        measureBlock {
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
            value: ["name", realm.objects(SwiftStringObject.self).map { $0 }, []])
        try! realm.commitWrite()

        measureBlock {
            for stringObject in arrayPropertyObject.array {
                _ = stringObject.stringCol
            }
        }
    }

    func testEnumerateAndAccessArrayPropertySlow() {
        let realm = copyRealmToTestPath(largeRealm)
        realm.beginWrite()
        let arrayPropertyObject = realm.create(SwiftArrayPropertyObject.self,
            value: ["name", realm.objects(SwiftStringObject.self).map { $0 }, []])
        try! realm.commitWrite()

        measureBlock {
            let list = arrayPropertyObject.array
            for i in 0..<list.count {
                _ = list[i].stringCol
            }
        }
    }

    func testEnumerateAndMutateAll() {
        let realm = copyRealmToTestPath(largeRealm)
        measureBlock {
            try! realm.write {
                for stringObject in realm.objects(SwiftStringObject.self) {
                    stringObject.stringCol = "c"
                }
            }
        }
    }

    func testEnumerateAndMutateQuery() {
        let realm = copyRealmToTestPath(largeRealm)
        measureBlock {
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
        measureBlock {
            for i in 0..<1000 {
                realm.objects(SwiftStringObject.self).filter("stringCol = %@", i.description).first
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
        measureBlock {
            for i in 0..<1000 {
                realm.objects(SwiftIndexedPropertiesObject.self).filter("stringCol = %@", i.description).first
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
        measureBlock {
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
        measureBlock {
            _ = realm.objects(SwiftIntObject.self).sorted("intCol", ascending: true).last
        }
    }

    func testRealmCreationCached() {
        var realm: Realm!
        dispatchSyncNewThread {
            realm = try! Realm()
        }

        measureBlock {
            for _ in 0..<250 {
                autoreleasepool {
                    _ = try! Realm()
                }
            }
        }
        _ = realm.configuration
    }

    func testRealmCreationUncached() {
        measureBlock {
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
            let object = realm.create(SwiftIntObject)
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
            let object = realm.create(SwiftIntObject)
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
            let object = realm.create(SwiftIntObject)
            try! realm.commitWrite()

            let queue = dispatch_queue_create("background", nil)
            let semaphore = dispatch_semaphore_create(0)
            dispatch_async(queue) {
                autoreleasepool {
                    let realm = inMemoryRealm("test")
                    let object = realm.objects(SwiftIntObject.self).first!
                    var token: NotificationToken! = nil
                    CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode) {
                        token = realm.addNotificationBlock { _, _ in
                            if object.intCol == stopValue {
                                CFRunLoopStop(CFRunLoopGetCurrent())
                            }
                        }
                        dispatch_semaphore_signal(semaphore)
                    }
                    CFRunLoopRun()
                    token.stop()
                }
            }

            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            self.startMeasuring()
            while object.intCol < stopValue {
                try! realm.write { object.intCol += 1 }
            }
            dispatch_sync(queue) {}
            self.stopMeasuring()
        }
    }

    func testCrossThreadSyncLatency() {
        let stopValue = 500
        let queue = dispatch_queue_create("background", nil)
        let semaphore = dispatch_semaphore_create(0)

        inMeasureBlock {
            let realm = inMemoryRealm("test")
            realm.beginWrite()
            let object = realm.create(SwiftIntObject)
            try! realm.commitWrite()

            dispatch_async(queue) {
                autoreleasepool {
                    let realm = inMemoryRealm("test")
                    let object = realm.objects(SwiftIntObject.self).first!
                    var token: NotificationToken! = nil
                    CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode) {
                        token = realm.addNotificationBlock { _, _ in
                            if object.intCol == stopValue {
                                CFRunLoopStop(CFRunLoopGetCurrent())
                            } else if object.intCol % 2 == 0 {
                                try! realm.write { object.intCol += 1 }
                            }
                        }
                        dispatch_semaphore_signal(semaphore)
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

            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)

            self.startMeasuring()
            try! realm.write { object.intCol += 1 }
            while object.intCol < stopValue {
                NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
            }
            dispatch_sync(queue) {}
            self.stopMeasuring()
            token.stop()
        }
    }
}

#endif
