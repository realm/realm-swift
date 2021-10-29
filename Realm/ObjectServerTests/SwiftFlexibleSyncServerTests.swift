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

#if os(macOS)

import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
import RealmSyncTestSupport
import RealmTestSupport
#endif


class Contact: Object {
    @Persisted var name: String
    @Persisted var address: Address
    @Persisted var userId: String
    @Persisted var age: Int
}

class Address: Object {
    @Persisted var state: String
}

class Author: Object {
    @Persisted var id: String
    @Persisted var name: String
}

#if swift(>=5.5) && canImport(_Concurrency)
@available(macOS 12.0, *)
class SwiftFlexibleSyncTestCase: SwiftSyncTestCase {

}

// MARK: - Completion Block
@available(macOS 12.0.0, *)
class SwiftFlexibleSyncServerTests: SwiftSyncTestCase {
    func testFlexibleSyncDownload() async throws {
        //// Examples
        // Open Realm with a Flexible Configuration
        let app = App(id: "")
        let user = try await app.login(credentials: Credentials.emailPassword(email: "email", password: "password"))
        let config = user.flexibleSyncConfiguration()
        let realm = try await Realm.init(configuration: config, downloadBeforeOpen: .always)

        // Example code 1 - Add 2 different subscriptions, second one without name
        let subscriptions = realm.subscriptions
        if subscriptions.isEmpty {
            try subscriptions.write {
                try subscriptions.add {
                    Subscription<Contact>(name: "contacts-ny") {
                        $0.address.state == "NY" && $0.age > 10
                    }
                    Subscription<Author> {
                        $0.name == "Joe Doe"
                    }
                }
            }
            try subscriptions.waitForSync(completion: { result in
                switch result {
                case .success(()):
                    // Sync succesful
                    break
                case .failure(let error):
                    print(error)
                }
            })
        }

        // Example code 2 - Find a subscription by name and remove a subscription
        let subscriptions2 = realm.subscriptions
        if let subscription = subscriptions2.findSubscription(name: "contacts-ny") {
            try subscriptions2.write {
                try subscriptions2.remove(subscription)
            }
            .onStateChange({ state in
                // Notify state changes
                print(state)
            })
        }

        // Example code 3 - Find a subscription by query and update the subscription
        let subscriptions3 = realm.subscriptions
        let query = { Subscription<Contact> { $0.address.state == "NY" && $0.age > 10 } }
        if let subscription = subscriptions3.findSubscription(query) {
            try subscriptions3.write {
                try subscription.update {
                    Subscription<Contact>(name: "contacts-ny") {
                        $0.address.state == "TX" && $0.age > 21
                    }
                }
            }
        }

        // Example code 4 - Remove all subscriptions for a type
        let subscriptions4 = realm.subscriptions
        try subscriptions4.write {
            try subscriptions4.removeAll(ofType: Contact.self)
        }
        try subscriptions4.waitForSync(completion: { result in
            switch result {
            case .success(()):
                // Sync succesful
                break
            case .failure(let error):
                print(error)
            }
        })
    }
}

// MARK: - Async Await
@available(macOS 12.0.0, *)
extension SwiftFlexibleSyncServerTests {
    func testFlexibleSyncDownloadAsyncAwait() async throws {
        // Examples
        // Open Realm with a Flexible Configuration
        let app = App(id: "")
        let user = try await app.login(credentials: Credentials.emailPassword(email: "email", password: "password"))
        let config = user.flexibleSyncConfiguration()
        let realm = try await Realm.init(configuration: config, downloadBeforeOpen: .always)

        // Example code 1 - Add 2 different subscriptions, second one without name
        let subscriptions = realm.subscriptions
        if subscriptions.isEmpty {
            try await subscriptions.writeAsync {
                try subscriptions.add {
                    Subscription<Contact>(name: "contacts-ny") {
                        $0.address.state == "NY" && $0.age > 10
                    }
                    Subscription<Author> {
                        $0.name == "Joe Doe"
                    }
                }
            }
            try await subscriptions.waitForSync()
        }

        // Example code 2 - Find a subscription by name and remove a subscription
        let subscriptions2 = realm.subscriptions
        if let subscription = subscriptions2.findSubscription(name: "contacts-ny") {
            try await subscriptions2.writeAsync {
                try subscriptions2.remove(subscription)
            }
        }

        // Example code 3 - Find a subscription by query and update the subscription
        let subscriptions3 = realm.subscriptions
        let query = { Subscription<Contact> { $0.address.state == "NY" && $0.age > 10 } }
        if let subscription = subscriptions3.findSubscription(query) {
            try await subscriptions3.writeAsync {
                try subscription.update {
                    Subscription<Contact>(name: "contacts-ny") {
                        $0.address.state == "TX" && $0.age > 21
                    }
                }
            }
        }

        // Example code 4 - Remove all subscriptions for a type
        let subscriptions4 = realm.subscriptions
        try await subscriptions4.writeAsync {
            try subscriptions4.removeAll(ofType: Contact.self)
        }
        try await subscriptions4.waitForSync()
    }
}
#endif // swift(>=5.5)
#endif
