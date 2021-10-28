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
class SwiftFlexibleSyncServerTests: SwiftSyncTestCase {
    func testFlexibleSyncDownload() throws {
//
//        // Non-Async Await
//        // Example code 1 - Add 2 different subscriptions, second one without name
//        if realm.subscriptions.isEmpty {
//            realm.subscribe({
//                Subscription<Contact>(name: "contacts-ny") {
//                    $0.address.state == "NY" && $0.age > 10
//                }
//                Subscription<Author> {
//                    $0.name == "Joe Doe"
//                }
//            }, callback: { results in
//                switch results {
//                case .success(let subscription):
//                    // Return subscription
//                    break
//                case .failure(let error):
//                    // Do something if there is an error
//                    break
//                }
//            })
//                .onStateChange { subscriptionState in
//                    // Do something on states changes
//                    if subscriptionState == .bootstrapping {
//                        // Do something
//                    }
//                }
//        }
        //
        //        // Example code 2 - Remove subscription
        //        if let subscription = realm.subscriptions.first(where: { $0.name == "contacts-tx" }) {
        //            subscription.unsubscribe { results in
        //                switch results {
        //                case .success(let subscription):
        //                    // Return subscription
        //                    break
        //                case .failure(let error):
        //                    // Do something if there is an error
        //                    break
        //                }
        //            }
        //            .onStateChange { subscriptionState in
        //                // Do something on states changes
        //                if case let .error(error) = subscriptionState {
        //                    // Do something for error
        //                }
        //            }
        //        }
        //
        //        // Example code 3 - Update subscription
        //        if let subscription = realm.subscriptions.first(where: { $0.name == "contacts-tx" }) {
        //            subscription.update(to: Contact.self, where: { $0.address.state == "FL" }) { results in
        //                switch results {
        //                case .success(let subscription):
        //                    // Return subscription
        //                    break
        //                case .failure(let error):
        //                    // Do something if there is an error
        //                    break
        //                }
        //            }
        //        }
        //
        //        // Example code 4 - Unsubscribe all subscriptions in the array
        //        realm.subscriptions.unsubscribeAll { results in
        //            switch results {
        //            case .success(let subscription):
        //                // Return subscription
        //                break
        //            case .failure(let error):
        //                // Do something if there is an error
        //                break
        //            }
        //        }
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


        // Async Await
        // Example code 1 - Add 3 different subscriptions, second one without name
        if realm.subscriptions.isEmpty {
            let subscriptions = try await realm.subscribe {
                Subscription<Contact>(name: "contacts-ny") {
                    $0.address.state == "NY" && $0.age > 10
                }
                Subscription<Author> {
                    $0.name == "Joe Doe"
                }
            }
        }

        // Example code 2 - Update Subscription
        let query = { Subscription<Contact> { $0.address.state == "NY" && $0.age > 10 } }
        if let subscription = realm.subscriptions.findSubscription(query) {
            try await subscription.update {
                Subscription<Contact>(name: "contacts-ny") {
                    $0.address.state == "TX" && $0.age > 21

                }
            }
        }

        // Example code 3 - Remove a subscription
        if let subscription = realm.subscriptions.findSubscription(name: "contacts-ny") {
            try await subscription.unsubscribe()
        }

        // Example code 4 - Unsubscribe all subscriptions
        try await realm.subscriptions.unsubscribeAll()
    }

}
#endif // swift(>=5.5)
#endif
