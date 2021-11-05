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
            realm.create(SwiftIntObject.self, value: [1])
            realm.create(SwiftIntObject.self, value: [2])
        }
    }
    return realm
}

private var smallRealm: Realm!
private var mediumRealm: Realm!
private var largeRealm: Realm!

private let isRunningOnDevice = TARGET_IPHONE_SIMULATOR == 0

@available(*, deprecated) // Silence deprecation warnings for RealmOptional
class SwiftPerformanceTests: TestCase {
    override class var defaultTestSuite: XCTestSuite {
        #if !DEBUG && os(iOS) && !targetEnvironment(macCatalyst)
            if isRunningOnDevice {
                return super.defaultTestSuite
            }
        #endif
        return XCTestSuite(name: "SwiftPerformanceTests")
    }

    override class func setUp() {
        super.setUp()
        autoreleasepool {
            smallRealm = createStringObjects(1)
            mediumRealm = createStringObjects(50)
            largeRealm = createStringObjects(500)
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
                for _ in 0..<10000 {
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
            for _ in 0..<500 {
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
                for _ in 0..<10000 {
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
            for _ in 0..<500 {
                let results = realm.objects(SwiftStringObject.self).filter("stringCol = 'a'")
                _ = results.count
            }
        }
    }

    func testCountWhereTableView() {
        let realm = copyRealmToTestPath(mediumRealm)
        measure {
            for _ in 0..<500 {
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


    func testEnumerateAndAccessAllInts() {
        let realm = copyRealmToTestPath(largeRealm)
        measure {
            for intObject in realm.objects(SwiftIntObject.self) {
                _ = intObject.intCol
            }
        }
    }

    func testEnumerateAndAccessAllSlowInts() {
        let realm = copyRealmToTestPath(largeRealm)
        measure {
            let results = realm.objects(SwiftIntObject.self)
            for i in 0..<results.count {
                _ = results[i].intCol
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

    func testEnumerateAndAccessMutableSetProperty() {
        let realm = copyRealmToTestPath(largeRealm)
        realm.beginWrite()
        let setPropertyObject = realm.create(SwiftMutableSetPropertyObject.self,
                                             value: ["name", realm.objects(SwiftStringObject.self).map { $0 } as NSArray, []])
        try! realm.commitWrite()

        measure {
            for stringObject in setPropertyObject.set {
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

    func testEnumerateAndAccessMutableSetPropertySlow() {
        let realm = copyRealmToTestPath(largeRealm)
        realm.beginWrite()
        let setPropertyObject = realm.create(SwiftMutableSetPropertyObject.self,
                                             value: ["name", realm.objects(SwiftStringObject.self).map { $0 } as NSArray, []])
        try! realm.commitWrite()

        measure {
            let set = setPropertyObject.set
            for i in 0..<set.count {
                _ = set[i].stringCol
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
            for i in 0..<10000 {
                realm.create(SwiftStringObject.self, value: [i.description])
            }
        }
        measure {
            for i in 0..<10000 {
                _ = realm.objects(SwiftStringObject.self).filter("stringCol = %@", i.description).first
            }
        }
    }

    func testIndexedStringLookup() {
        let realm = realmWithTestPath()
        try! realm.write {
            for i in 0..<10000 {
                realm.create(SwiftIndexedPropertiesObject.self, value: [i.description, i])
            }
        }
        measure {
            for i in 0..<10000 {
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
            for _ in 0..<2500 {
                autoreleasepool {
                    _ = try! Realm()
                }
            }
        }
        _ = realm.configuration
    }

    func testRealmCreationUncached() {
        measure {
            for _ in 0..<500 {
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
            while object.intCol < 500 {
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

            let token = realm.observe { _, _ in }
            self.startMeasuring()
            while object.intCol < 500 {
                try! realm.write { object.intCol += 1 }
            }
            self.stopMeasuring()
            token.invalidate()
        }
    }

    func testCommitWriteTransactionWithCrossThreadNotification() {
        let stopValue = 1000
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
                        token = realm.observe { _, _ in
                            if object.intCol == stopValue {
                                CFRunLoopStop(CFRunLoopGetCurrent())
                            }
                        }
                        semaphore.signal()
                    }
                    CFRunLoopRun()
                    token.invalidate()
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
        let stopValue = 5000
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
                        token = realm.observe { _, _ in
                            if object.intCol == stopValue {
                                CFRunLoopStop(CFRunLoopGetCurrent())
                            } else if object.intCol % 2 == 0 {
                                try! realm.write { object.intCol += 1 }
                            }
                        }
                        semaphore.signal()
                    }
                    CFRunLoopRun()
                    token.invalidate()
                }
            }

            let token = realm.observe { _, _ in
                if object.intCol % 2 == 1 && object.intCol < stopValue {
                    try! realm.write { object.intCol += 1 }
                }
            }

            _ = semaphore.wait(timeout: DispatchTime.distantFuture)

            self.startMeasuring()
            try! realm.write { object.intCol += 1 }
            while object.intCol < stopValue {
                RunLoop.current.run(mode: RunLoop.Mode.default, before: Date.distantFuture)
            }
            queue.sync {}
            self.stopMeasuring()
            token.invalidate()
        }
    }

    // MARK: - Legacy object creation helpers

    func createObjects<T: Object>(_ type: T.Type, _ create: (T, Int) -> Void) -> Realm {
        let realm = try! Realm()
        try! realm.write {
            for value in 0..<10000 {
                let obj = T()
                create(obj, value)
                realm.add(obj)
            }
        }
        return realm
    }

    func createSwiftListObjects() -> Realm {
        return createObjects(SwiftListOfSwiftObject.self) { (listObject, value) in
            let object = SwiftObject()
            object.intCol = value
            object.stringCol = String(value)
            listObject.array.append(object)
        }
    }

    func createSwiftMutableSetObjects() -> Realm {
        return createObjects(SwiftMutableSetOfSwiftObject.self) { (setObject, value) in
            let object = SwiftObject()
            object.intCol = value
            object.stringCol = String(value)
            setObject.set.insert(object)
        }
    }

    func createIntSwiftObjects() -> Realm {
        return createObjects(SwiftObject.self) { (object, value) in
            object.intCol = value
        }
    }

    func createStringSwiftObjects() -> Realm {
        return createObjects(SwiftObject.self) { (object, value) in
            object.stringCol = String(value)
        }
    }

    func createOptionalIntObjects() -> Realm {
        return createObjects(SwiftOptionalObject.self) { (object, value) in
            object.optIntCol.value = value
        }
    }

    func createOptionalStringObjects() -> Realm {
        return createObjects(SwiftOptionalObject.self) { (object, value) in
            object.optStringCol = String(value)
        }
    }


    // MARK: - Legacy value(forKey:) vs. loop

    func testLegacyListObjectsMap() {
        let objects = createSwiftListObjects().objects(SwiftListOfSwiftObject.self)
        measure {
            _ = Array(objects.map { $0.array })
        }
    }

    func testLegacyListObjectsValueForKey() {
        let objects = createSwiftListObjects().objects(SwiftListOfSwiftObject.self)
        measure {
            _ = objects.value(forKeyPath: "array") as! [List<SwiftListOfSwiftObject>]
        }
    }

    func testLegacyMutableSetObjectsMap() {
        let objects = createSwiftMutableSetObjects().objects(SwiftMutableSetOfSwiftObject.self)
        measure {
            _ = Array(objects.map { $0.set })
        }
    }

    func testLegacyMutableSetObjectsValueForKey() {
        let objects = createSwiftMutableSetObjects().objects(SwiftMutableSetOfSwiftObject.self)
        measure {
            _ = objects.value(forKeyPath: "set") as! [MutableSet<SwiftMutableSetOfSwiftObject>]
        }
    }

    func testLegacyIntObjectsMap() {
        let objects = createIntSwiftObjects().objects(SwiftObject.self)
        measure {
            _ = Array(objects.map { $0.intCol })
        }
    }

    func testLegacyIntObjectsValueForKey() {
        let objects = createIntSwiftObjects().objects(SwiftObject.self)
        measure {
            _ = objects.value(forKeyPath: "intCol") as! [Int]
        }
    }

    func testLegacyStringObjectsMap() {
        let objects = createStringSwiftObjects().objects(SwiftObject.self)
        measure {
            _ = Array(objects.map { $0.stringCol })
        }
    }

    func testLegacyStringObjectsValueForKey() {
        let objects = createStringSwiftObjects().objects(SwiftObject.self)
        measure {
            _ = objects.value(forKeyPath: "stringCol") as! [String]
        }
    }

    func testLegacyOptionalIntObjectsMap() {
        let objects = createOptionalIntObjects().objects(SwiftOptionalObject.self)
        measure {
            _ = Array(objects.map { $0.optIntCol.value })
        }
    }

    func testLegacyOptionalIntObjectsValueForKey() {
        let objects = createOptionalIntObjects().objects(SwiftOptionalObject.self)
        measure {
            _ = objects.value(forKeyPath: "optIntCol") as! [Int]
        }
    }

    func testLegacyOptionalStringObjectsMap() {
        let objects = createOptionalStringObjects().objects(SwiftOptionalObject.self)
        measure {
            _ = Array(objects.map { $0.optStringCol })
        }
    }

    func testLegacyOptionalStringObjectsValueForKey() {
        let objects = createOptionalStringObjects().objects(SwiftOptionalObject.self)
        measure {
            _ = objects.value(forKeyPath: "optStringCol") as! [String]
        }
    }

    // MARK: - Modern object creation helpers

    func createModernCollectionObjects() -> Results<ModernCollectionObject> {
        return createObjects(ModernCollectionObject.self) { (listObject, value) in
            let object = ModernAllTypesObject()
            object.intCol = value
            object.stringCol = String(value)
            listObject.list.append(object)
            listObject.set.insert(object)
            listObject.map[""] = object
        }.objects(ModernCollectionObject.self)
    }

    func createModernObjects() -> Results<ModernIntAndStringObject> {
        return createObjects(ModernIntAndStringObject.self) { (object, value) in
            object.intCol = value
            object.stringCol = String(value)
            object.optIntCol = value
            object.optStringCol = String(value)
        }.objects(ModernIntAndStringObject.self)
    }

    // MARK: - Modern value(forKey:) vs. loop

    func testModernListObjectsMap() {
        let objects = createModernCollectionObjects()
        measure {
            _ = Array(objects.map { $0.list })
        }
    }

    func testModernListObjectsValueForKey() {
        let objects = createModernCollectionObjects()
        measure {
            _ = objects.value(forKeyPath: "list") as! [List<ModernAllTypesObject>]
        }
    }

    func testModernMutableSetObjectsMap() {
        let objects = createModernCollectionObjects()
        measure {
            _ = Array(objects.map { $0.set })
        }
    }

    func testModernMutableSetObjectsValueForKey() {
        let objects = createModernCollectionObjects()
        measure {
            _ = objects.value(forKeyPath: "set") as! [MutableSet<ModernAllTypesObject>]
        }
    }

    func testModernIntObjectsMap() {
        let objects = createModernObjects()
        measure {
            _ = Array(objects.map { $0.intCol })
        }
    }

    func testModernIntObjectsValueForKey() {
        let objects = createModernObjects()
        measure {
            _ = objects.value(forKeyPath: "intCol") as! [Int]
        }
    }

    func testModernStringObjectsMap() {
        let objects = createModernObjects()
        measure {
            _ = Array(objects.map { $0.stringCol })
        }
    }

    func testModernStringObjectsValueForKey() {
        let objects = createModernObjects()
        measure {
            _ = objects.value(forKeyPath: "stringCol") as! [String]
        }
    }

    func testModernOptionalIntObjectsMap() {
        let objects = createModernObjects()
        measure {
            _ = Array(objects.map { $0.optIntCol })
        }
    }

    func testModernOptionalIntObjectsValueForKey() {
        let objects = createModernObjects()
        measure {
            _ = objects.value(forKeyPath: "optIntCol") as! [Int]
        }
    }

    func testModernOptionalStringObjectsMap() {
        let objects = createModernObjects()
        measure {
            _ = Array(objects.map { $0.optStringCol })
        }
    }

    func testModernOptionalStringObjectsValueForKey() {
        let objects = createModernObjects()
        measure {
            _ = objects.value(forKeyPath: "optStringCol") as! [String]
        }
    }
}
