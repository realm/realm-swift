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

class SwiftFlexibleSyncTestCase: SwiftSyncTestCase {

}

// MARK: - Completion Block
 class SwiftFlexibleSyncServerTests: SwiftSyncTestCase {
     func testFlexibleSyncDownload() throws {
         // Open Realm with a Flexible Configuration
         let app = App(id: "")
         var syncUser: User!
         app.login(credentials: Credentials.emailPassword(email: "email", password: "password"), { result in
             switch result {
             case .success(let user):
                 syncUser = user
             case .failure(let error):
                 XCTFail("Should login user \(error)")
             }

         })
         let config = syncUser.flexibleSyncConfiguration()
         var syncedRealm: Realm!
         Realm.asyncOpen(configuration: config, callback: { result in
             switch result {
             case .success(let realm):
                 syncedRealm = realm
             case .failure(let error):
                 XCTFail("Should return a realm \(error)")
             }
         })

         // Example code 1 - Add 2 different subscriptions, second one without name
         let subscriptions = syncedRealm.subscriptions
         if subscriptions.isEmpty {
             try subscriptions.write {
                 try subscriptions.append {
                     Subscription<Contact>(name: "contacts-ny") {
                         $0.address.state == "NY" && $0.age > 10
                     }
                     Subscription<Author> {
                         $0.name == "Joe Doe"
                     }
                 }
             }
             subscriptions.observe { result in
                 switch result {
                 case .success(()):
                     // Sync succesful
                     break
                 case .failure(let error):
                     print(error)
                 }
             }
         }

         // Example code 2 - Find a subscription by name and remove a subscription
         let subscriptions2 = syncedRealm.subscriptions
         if let subscription = subscriptions2.first(where: { $0.name == "contacts-ny" }) {
             try subscriptions2.write {
                 try subscriptions2.remove(subscription)
             }
         }

         // Example code 3 - Find a subscription by query and update the subscription
         let subscriptions3 = syncedRealm.subscriptions
         let query = { Subscription<Contact> { $0.address.state == "NY" && $0.age > 10 } }
         if let subscription = subscriptions3.first(query) {
             try subscriptions3.write {
                 try subscription.update {
                     Subscription<Contact>(name: "contacts-ny") {
                         $0.address.state == "TX" && $0.age > 21
                     }
                 }
             }
         }

         // Example code 4 - Remove all subscriptions for a type
         let subscriptions4 = syncedRealm.subscriptions
         try subscriptions4.write {
             try subscriptions4.removeAll(ofType: Contact.self)
         }
         subscriptions4.observe { result in
             switch result {
             case .success(()):
                 // Sync succesful
                 break
             case .failure(let error):
                 print(error)
             }
         }

         // Example code 5 - Monitor state changes on this subscription set write
         let subscriptions5 = syncedRealm.subscriptions
         try subscriptions5.write {
             try subscriptions4.remove {
                 Subscription<Author> {
                     $0.name == "Joe Doe"
                 }
             }
         }
         .observe { state in
             // Notify state changes
             print(state)
         }
     }
 }

 // MARK: - Async Await
 #if swift(>=5.5) && canImport(_Concurrency)
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
             let task = try await subscriptions.write {
                 try subscriptions.append {
                     Subscription<Contact>(name: "contacts-ny") {
                         $0.address.state == "NY" && $0.age > 10
                     }
                     Subscription<Author> {
                         $0.name == "Joe Doe"
                     }
                 }
             }
             for await state in task.observe() {
                 if case .complete = state {
                     return
                 }
             }
         }

         // Example code 2 - Find a subscription by name and remove a subscription
         let subscriptions2 = realm.subscriptions
         if let subscription = subscriptions2.first(where: { $0.name == "contacts-ny" }) {
             try await subscriptions2.write {
                 try subscriptions2.remove(subscription)
             }
         }

         // Example code 3 - Find a subscription by query and update the subscription
         let subscriptions3 = realm.subscriptions
         let query = { Subscription<Contact> { $0.address.state == "NY" && $0.age > 10 } }
         if let subscription = subscriptions3.first(query) {
             try await subscriptions3.write {
                 try subscription.update {
                     Subscription<Contact>(name: "contacts-ny") {
                         $0.address.state == "TX" && $0.age > 21
                     }
                 }
             }
         }

         // Example code 4 - Remove all subscriptions for a type
         let subscriptions4 = realm.subscriptions
         let task2 = try await subscriptions4.write {
             try subscriptions4.removeAll(ofType: Contact.self)
         }
         for await state in task2.observe() {
             if case .complete = state {
                 return
             }
         }

         // Example code 5 - Monitor state changes on this subscription set write
         let subscriptions5 = realm.subscriptions
         let task3 = try await subscriptions5.write {
             try subscriptions4.remove {
                 Subscription<Author> {
                     $0.name == "Joe Doe"
                 }
             }
         }
         for await state in task3.observe() {
             print(state)
         }
     }
 }
 #endif // canImport(_Concurrency)
 #endif // os(macOS)
