////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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
import Realm

/**
 A helper class intended for use when writing unit tests involving Realms, especially those involving the use of GCD.

 To use this class, create a property on your `XCTestCase` class of type `UnitTestHelper`, and either instantiate the
 test helper upon initialization or lazily when requested.

 Your `XCTestCase` test case subclass must override the `invokeTest()` method. In that method, call the helper's
 `invokeTest(with:)` method. Inside the block passed to `invokeTest(with:)`, call `super.invokeTest()`. You can also do
 additional work within the block if necessary.

 Instead of using GCD functions directly, use the `dispatch()` and `dispatchAndWait()` methods instead.
 */
public class UnitTestHelper {

    private let queue = DispatchQueue(label: "UnitTestHelper_dispatch_queue")

    public var shouldResetState : Bool = true

    public init() { }

    /**
     An on-disk test Realm for your unit test to use. The Realm is cleaned up and properly destroyed after each test
     suite.
     */
    public var onDiskTestRealm : Realm {
        get {
            didCreateOnDiskTestRealm = true
            return _onDiskTestRealm
        }
    }

    private var didCreateOnDiskTestRealm = false

    private(set) lazy var _onDiskTestRealm : Realm = {
        let fileManager = FileManager.default
        let url = try! fileManager.urlForDirectory(.cachesDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
        let thisName = "RLMUnitTestHelper-\(UUID().uuidString)"

        var config = Realm.Configuration.defaultConfiguration
        config.fileURL = try! url.appendingPathComponent(thisName)

        return try! Realm(configuration: config)
    }()

    /**
     An in-memory test Realm for your unit test to use. The Realm is properly destroyed after each test suite, unless
     the 'do not clean .
     */
    public private(set) lazy var inMemoryTestRealm : Realm = {
        let thisName = "RLMUnitTestHelper-\(UUID().uuidString)"

        var config = Realm.Configuration.defaultConfiguration
        config.inMemoryIdentifier = thisName

        return try! Realm(configuration: config)
    }()

    /**
     Invoke the unit test.

     This method should always be called within the `XCUnitTest`'s `invokeTest()` method. The block must contain a call
     to `super.invokeTest()`.
     */
    public func invokeTest(with block: () -> Void) {
        autoreleasepool { block() }
        autoreleasepool {
            queue.sync { }
            cleanup()
        }
    }

    /**
     Dispatches an asynchronous block on the test-specific dispatch queue. Prefer this method to using GCD directly.
     */
    public func dispatch(_ block: () -> Void) {
        queue.async {
            autoreleasepool { block() }
        }
    }

    /**
     Dispatches a block on the test-specific dispatch queue, and wait for the block to complete executing before
     returning.
     
     Prefer this method to using GCD directly.
     */
    public func dispatchAndWait(_ block: () -> Void) {
        dispatch(block)
        queue.sync { }
    }

    private func cleanup() {
        guard shouldResetState else { return }
        RLMRealm.resetRealmState()
        if didCreateOnDiskTestRealm {
            let manager = FileManager.default
            let fileURL = _onDiskTestRealm.configuration.fileURL!
            try! manager.removeItem(at: fileURL)
            try! manager.removeItem(at: fileURL.appendingPathExtension("lock"))
            // TODO: update this if we move the note file into the .management dir
            try! manager.removeItem(at: fileURL.appendingPathExtension("note"))
        }
    }
}
