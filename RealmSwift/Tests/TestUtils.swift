////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 Realm Inc.
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

import Foundation
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmTestSupport
#endif

// Wrap a sendable value in a lock to enable sharing a mutable variable between
// threads.
//
// When guarding a member variable this can be used as a property wrapper to
// simplify use. Due to a bug in the Swift compiler
// (https://github.com/apple/swift/issues/61358), this current doesn't work for
// local variables.
@propertyWrapper
public class Locked<T>: @unchecked Sendable {
    private var _value: T
    private let lock: os_unfair_lock_t = .allocate(capacity: 1)

    public init(_ value: T) {
        _value = value
        lock.initialize(to: os_unfair_lock())
    }

    public var value: T {
        get {
            withLock {$0 }
        }
        set {
            withLock {
                $0 = newValue
            }
        }
        // Accessor for modify operations (e.g. += and mutating functions on structs)
        // which eliminates race conditions which would otherwise happen if multiple
        // threads mutated the value at the same time.
        _modify {
            os_unfair_lock_lock(lock)
            yield &_value
            os_unfair_lock_unlock(lock)
        }
    }

    // Invoke a closure while holding the lock. This can be used to safely
    // perform logic more complicated than a simple assignment or read of the
    // value.
    public func withLock<U>(_ fn: (inout T) -> U) -> U {
        os_unfair_lock_lock(lock)
        let ret = fn(&_value)
        os_unfair_lock_unlock(lock)
        return ret
    }

    // Property wrapper implementation
    public convenience init(wrappedValue: T) {
        self.init(wrappedValue)
    }
    public var wrappedValue: T {
        get { value }
        set { value = newValue }
    }
}

public extension XCTestCase {
    /// Check whether two test objects are equal (refer to the same row in the same Realm), even if their models
    /// don't define a primary key.
    func assertEqual<O: Object>(_ o1: O?, _ o2: O?, fileName: StaticString = #filePath, lineNumber: UInt = #line) {
        if o1 == nil && o2 == nil {
            return
        }
        if let o1 = o1, let o2 = o2, o1.isSameObject(as: o2) {
            return
        }
        XCTFail("Objects expected to be equal, but weren't. First: \(String(describing: o1)), "
            + "second: \(String(describing: o2))", file: (fileName), line: lineNumber)
    }

    /// Check whether two collections containing Realm objects are equal.
    func assertEqual<C: Collection>(_ c1: C, _ c2: C, fileName: StaticString = #filePath, lineNumber: UInt = #line)
        where C.Iterator.Element: Object {
            XCTAssertEqual(c1.count, c2.count, "Collection counts were incorrect", file: (fileName), line: lineNumber)
            for (o1, o2) in zip(c1, c2) {
                assertEqual(o1, o2, fileName: fileName, lineNumber: lineNumber)
            }
    }

    func assertEqual<T: Equatable>(_ expected: [T?], _ actual: [T?], file: StaticString = #file, line: UInt = #line) {
        if expected.count != actual.count {
            XCTFail("assertEqual failed: (\"\(expected)\") is not equal to (\"\(actual)\")",
                file: (file), line: line)
            return
        }

        XCTAssertEqual(expected.count, actual.count, "Collection counts were incorrect", file: (file), line: line)
        for (e, a) in zip(expected, actual) where e != a {
            XCTFail("assertEqual failed: (\"\(expected)\") is not equal to (\"\(actual)\")",
                file: (file), line: line)
            return
        }
    }

    func assertSucceeds(message: String? = nil, fileName: StaticString = #filePath,
                        lineNumber: UInt = #line, block: () throws -> Void) {
        do {
            try block()
        } catch {
            XCTFail("Expected no error, but instead caught <\(error)>.",
                file: (fileName), line: lineNumber)
        }
    }

    func assertFails<T>(_ expectedError: Realm.Error.Code, _ message: String? = nil,
                        fileName: StaticString = #filePath, lineNumber: UInt = #line,
                        block: () throws -> T) {
        do {
            _ = try autoreleasepool(invoking: block)
            XCTFail("Expected to catch <\(expectedError)>, but no error was thrown.",
                file: fileName, line: lineNumber)
        } catch let e as Realm.Error where e.code == expectedError {
            if message != nil {
                XCTAssertEqual(e.localizedDescription, message, file: fileName, line: lineNumber)
            }
        } catch {
            XCTFail("Expected to catch <\(expectedError)>, but instead caught <\(error)>.",
                file: fileName, line: lineNumber)
        }
    }

    func assertFails<T>(_ expectedError: Realm.Error.Code, _ file: URL, _ message: String,
                        fileName: StaticString = #filePath, lineNumber: UInt = #line,
                        block: () throws -> T) {
        do {
            _ = try autoreleasepool(invoking: block)
            XCTFail("Expected to catch <\(expectedError)>, but no error was thrown.",
                file: fileName, line: lineNumber)
        } catch let e as Realm.Error where e.code == expectedError {
            XCTAssertEqual(e.localizedDescription, message, file: fileName, line: lineNumber)
            XCTAssertEqual(e.fileURL, file, file: fileName, line: lineNumber)
        } catch {
            XCTFail("Expected to catch <\(expectedError)>, but instead caught <\(error)>.",
                file: fileName, line: lineNumber)
        }
    }

    func assertFails<T>(_ expectedError: Error, _ message: String? = nil,
                        fileName: StaticString = #filePath, lineNumber: UInt = #line,
                        block: () throws -> T) {
        do {
            _ = try autoreleasepool(invoking: block)
            XCTFail("Expected to catch <\(expectedError)>, but no error was thrown.",
                file: fileName, line: lineNumber)
        } catch let e where e._code == expectedError._code {
            // Success!
        } catch {
            XCTFail("Expected to catch <\(expectedError)>, but instead caught <\(error)>.",
                file: fileName, line: lineNumber)
        }
    }

    func assertNil<T>(block: @autoclosure() -> T?, _ message: String? = nil,
                      fileName: StaticString = #filePath, lineNumber: UInt = #line) {
        XCTAssert(block() == nil, message ?? "", file: (fileName), line: lineNumber)
    }

    func assertMatches(_ block: @autoclosure () -> String, _ regexString: String, _ message: String? = nil,
                       fileName: String = #file, lineNumber: UInt = #line) {
        RLMAssertMatches(self, block, regexString, message, fileName, lineNumber)
    }

    /// Check that a `MutableSet` contains all expected elements.
    func assertSetContains<T, U>(_ set: MutableSet<T>, keyPath: KeyPath<T, U>, items: [U]) where U: Hashable {
        var itemMap = Dictionary(uniqueKeysWithValues: items.map { ($0, false)})
        set.map { $0[keyPath: keyPath]}.forEach {
            itemMap[$0] = items.contains($0)
        }
        // ensure all items are present in the set.
        XCTAssertFalse(itemMap.values.contains(false))
    }

    /// Check that an `AnyRealmCollection` contains all expected elements.
    func assertAnyRealmCollectionContains<T, U>(_ set: AnyRealmCollection<T>, keyPath: KeyPath<T, U>, items: [U]) where U: Hashable {
        var itemMap = Dictionary(uniqueKeysWithValues: items.map { ($0, false)})
        set.map { $0[keyPath: keyPath]}.forEach {
            itemMap[$0] = items.contains($0)
        }
        // ensure all items are present in the set.
        XCTAssertFalse(itemMap.values.contains(false))
    }
}

#if compiler(<6)
@_unsafeInheritExecutor
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func assertThrowsErrorAsync<T, E: Equatable & Error>(
    _ expression: @autoclosure () async throws -> T,
    _ expectedError: E,
    file: StaticString = #filePath, line: UInt = #line) async {
    do {
        _ = try await expression()
        XCTFail("Expected expression to throw error \(expectedError)", file: file, line: line)
    } catch let error as E {
        XCTAssertEqual(error, expectedError, file: file, line: line)
    } catch {
        XCTFail("Expected expression to throw error \(expectedError) but got \(error)", file: file, line: line)
    }
}

// Fork, call an expression which should hit a precondition failure in the child
// process, and then verify that the expected failure message was printed. Note
// that Swift and Foundation do not support fork(), so anything which does more
// than a very limited amount of work before the precondition failure is very
// likely to break.
@_unsafeInheritExecutor
@available(macOS 10.15.4, iOS 13.4, tvOS 13.4, watchOS 6.4, *)
public func assertPreconditionFailure<T>(_ message: String, _ expression: () async throws -> T,
                                         file: StaticString = #filePath, line: UInt = #line) async throws {
    // We can't perform these tests on tvOS, watchOS, or on devices
    guard RLMCanFork() else { return }

    let pipe = Pipe()

    let pid = RLMFork()
    if pid == -1 {
        return XCTFail("Failed to fork for test", file: file, line: line)
    }

    if pid == 0 {
        // In child process
        // Point stdout and stderr at our pipe
        let fd = pipe.fileHandleForWriting.fileDescriptor
        while dup2(fd, STDOUT_FILENO) == -1 && errno == EINTR {}
        while dup2(fd, STDERR_FILENO) == -1 && errno == EINTR {}
        _ = try await expression()
        exit(0)
    }

    try pipe.fileHandleForWriting.close()
    while true {
        var status: Int32 = 0
        let ret = waitpid(pid, &status, 0)
        if ret == -1 && errno == EINTR {
            continue
        }
        guard ret > 0 else {
            return XCTFail("Failed to wait for child process to exit? errno: \(errno)", file: file, line: line)
        }
        guard status != 0 else {
            return XCTFail("Expected child process to crash with message \"\(message)\", but it exited cleanly", file: file, line: line)
        }
        break
    }

    guard let data = try pipe.fileHandleForReading.readToEnd() else {
        return XCTFail("Expected child process to crash with message \"\(message)\", but it exited without printing anything", file: file, line: line)
    }
    guard let str = String(data: data, encoding: .utf8) else {
        return XCTFail("Expected child process to crash with message \"\(message)\", but it did not print valid utf-8", file: file, line: line)
    }

    if !str.contains("Precondition failed: \(message)") && !str.contains("Fatal error: \(message)") {
        XCTFail("Expected \"\(str)\" to contain \"\(message)\")", file: file, line: line)
    }
}
#else
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func assertThrowsErrorAsync<T: Sendable, E: Equatable & Error>(
    _ expression: @autoclosure () async throws -> T,
    _ expectedError: E,
    _isolation: isolated (any Actor)? = #isolation,
    file: StaticString = #filePath, line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected expression to throw error \(expectedError)", file: file, line: line)
    } catch let error as E {
        XCTAssertEqual(error, expectedError, file: file, line: line)
    } catch {
        XCTFail("Expected expression to throw error \(expectedError) but got \(error)", file: file, line: line)
    }
}

// Fork, call an expression which should hit a precondition failure in the child
// process, and then verify that the expected failure message was printed. Note
// that Swift and Foundation do not support fork(), so anything which does more
// than a very limited amount of work before the precondition failure is very
// likely to break.
@available(macOS 10.15.4, iOS 13.4, tvOS 13.4, watchOS 6.4, *)
public func assertPreconditionFailure<T: Sendable>(
    _ message: String, _ expression: () async throws -> T,
    _isolation: isolated (any Actor)? = #isolation,
    file: StaticString = #filePath, line: UInt = #line
) async throws {
    // We can't perform these tests on tvOS, watchOS, or on devices
    guard RLMCanFork() else { return }

    let pipe = Pipe()

    let pid = RLMFork()
    if pid == -1 {
        return XCTFail("Failed to fork for test", file: file, line: line)
    }

    if pid == 0 {
        // In child process
        // Point stdout and stderr at our pipe
        let fd = pipe.fileHandleForWriting.fileDescriptor
        while dup2(fd, STDOUT_FILENO) == -1 && errno == EINTR {}
        while dup2(fd, STDERR_FILENO) == -1 && errno == EINTR {}
        _ = try await expression()
        exit(0)
    }

    try pipe.fileHandleForWriting.close()
    while true {
        var status: Int32 = 0
        let ret = waitpid(pid, &status, 0)
        if ret == -1 && errno == EINTR {
            continue
        }
        guard ret > 0 else {
            return XCTFail("Failed to wait for child process to exit? errno: \(errno)", file: file, line: line)
        }
        guard status != 0 else {
            return XCTFail("Expected child process to crash with message \"\(message)\", but it exited cleanly", file: file, line: line)
        }
        break
    }

    guard let data = try pipe.fileHandleForReading.readToEnd() else {
        return XCTFail("Expected child process to crash with message \"\(message)\", but it exited without printing anything", file: file, line: line)
    }
    guard let str = String(data: data, encoding: .utf8) else {
        return XCTFail("Expected child process to crash with message \"\(message)\", but it did not print valid utf-8", file: file, line: line)
    }

    if !str.contains("Precondition failed: \(message)") && !str.contains("Fatal error: \(message)") {
        XCTFail("Expected \"\(str)\" to contain \"\(message)\")", file: file, line: line)
    }
}
#endif
