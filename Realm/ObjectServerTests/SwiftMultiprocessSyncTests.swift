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

import Foundation
#if os(macOS)

import Realm
import Realm.Private
import RealmSwift
import XCTest

#if canImport(RealmTestSupport)
import RealmSwiftSyncTestSupport
#endif

#if swift(>=5.5) && canImport(_Concurrency)

@available(macOS 12.0, *)
final class RealmExecutor: Executor {
    func enqueue(_ job: UnownedJob) {
        //        swift_task_enqueueOnDispatchQueue()
        //        _enqueueOnDispatchQueue(job, self)
    }
}
@available(macOS 12.0, *)
actor RealmActor {
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        fatalError()
    }
}

@available(macOS 12.0, *)
class SwiftMultiprocessSyncTests: SwiftSyncTestCase {
    enum Event: String, CaseIterable {
        case syncAgentCheckIn
        case nonSyncAgentCheckIn
        case agentsCheckedIn
        case downloadedParentData
        case uploadedChildData
    }

    func send(event: Event) {
        let dnc = DistributedNotificationCenter.default()
        dnc.post(name: NSNotification.Name(event.rawValue), object: nil)
    }

    func testMultiprocessSync() async throws {
        let dnc = DistributedNotificationCenter.default()
        let stream = AsyncStream<Event> { continuation in
            Event.allCases.forEach { event in
                Task {
                    let it = dnc.notifications(named: Notification.Name(event.rawValue),
                                               object: nil).makeAsyncIterator()

                    while let _ = await it.next() {
                        continuation.yield(event)
                        print(event)
                    }
                }
            }
        }

        switch ProcessKind.current {
        case .parent:
            // create an app. we do not use the default app here because
            // it has already been configured.
            let appId = try! RealmServer.shared.createApp()
            let appConfiguration = AppConfiguration(baseURL: "http://localhost:9090",
                                                    transport: nil,
                                                    localAppName: nil,
                                                    localAppVersion: nil)
            let app = App(id: appId, configuration: appConfiguration)

            // register and login to a user. this user will be logged in to
            // in each of the child processes.
            let (email, password) = (randomString(10), "password")
            try await app.emailPasswordAuth.registerUser(email: email, password: password)
            let user = try await app.login(credentials: .emailPassword(email: email, password: password))
            try await withThrowingTaskGroup(of: Void.self) { group in
                // open the realm, and add the three test objects to it.

                group.addTask {
                    var configuration = user.configuration(partitionValue: "mps")
                    configuration.objectTypes = [SwiftPerson.self]

                    var syncAgentCount = 0
                    var nonSyncAgentCount = 0
                    for await event in stream {
                        switch event {
                        case .syncAgentCheckIn:
                            syncAgentCount += 1
                        case .nonSyncAgentCheckIn:
                            nonSyncAgentCount += 1
                            // MARK: CHECKPOINT 2
                            // once the child processes have downloaded
                            // the test objects, they will each modify one.
                            // the object they modify will correspond to
                            // the child process id (not the pid, the id chosen above)
                            // versus the index of the person in the Results
                        case .uploadedChildData:
                            let realm = try await Realm(configuration: configuration)
                            try await self.waitForDownloads(for: realm)
                            let persons = realm.objects(SwiftPerson.self)
                            for i in 0..<3 {
                                XCTAssertEqual(persons[i].firstName, "\(i)")
                                XCTAssertEqual(persons[i].lastName, "of Nine")
                            }
                            return
                        default: break
                        }
                        // MARK: CHECKPOINT 1
                        // once the changesets are uploaded, wait
                        // for each child process to finish initalising.
                        // at this point, each child process should have
                        // opened the shared realm, and a sync agent
                        // will have been chosen.
                        if (event == .syncAgentCheckIn || event == .nonSyncAgentCheckIn)
                            && syncAgentCount + nonSyncAgentCount == 3 {
                            let realm = try await Realm(configuration: configuration)
                            try realm.write {
                                realm.add(SwiftPerson(firstName: "Miles", lastName: "O'Brien"))
                                realm.add(SwiftPerson(firstName: "Jean Luc", lastName: "Picard"))
                                realm.add(SwiftPerson(firstName: "Benjamin", lastName: "Sisko"))
                            }
                            try await self.waitForUploads(for: realm)
                            self.send(event: .agentsCheckedIn)
                        }
                    }
                }
                // generate the child processes in a task group.
                // leveraging TaskGroup here allows us to wait for
                // the processes to finish using async/await.
                for i in 0..<3 {
                    group.addTask {
                        // note: we do not want the child tasks to clean up
                        // on termination, otherwise they will delete each others data.
                        let process = self.childTask(with: .init(appIds: [appId],
                                                                 email: email,
                                                                 password: password,
                                                                 identifer: i,
                                                                 shouldCleanUpOnTermination: false))
                        let pipe = Pipe()
                        pipe.fileHandleForReading.readabilityHandler = { handle in
                            guard handle.availableData.count > 0, let output = String(data: handle.availableData, encoding: .utf8) else {
                                return
                            }
                            print(output)
                        }
                        process.standardError = pipe
                        try process.run()
                        process.waitUntilExit()
                        print("!!DEAD")
                        XCTAssertEqual(process.terminationStatus, 0)
                    }
                }
                try await group.waitForAll()
            }
        case .child(environment: let environment):
            try await withThrowingTaskGroup(of: Void.self) { group in
                let user = try await app.login(credentials: .emailPassword(email: environment.email!,
                                                                           password: environment.password!))
                var userConfiguration = user.configuration(partitionValue: "mps")
                userConfiguration.objectTypes = [SwiftPerson.self]

                group.addTask {
                    var userConfiguration = user.configuration(partitionValue: "mps")
                    userConfiguration.objectTypes = [SwiftPerson.self]
                    let realm = try await Realm(configuration: userConfiguration)
                    for await event in stream {
                        switch event {
                        case .agentsCheckedIn:
                            if realm.syncSession != nil {
                                try await self.waitForDownloads(for: realm)
                                self.send(event: .downloadedParentData)
                            }
                        case .downloadedParentData:
                            realm.refresh()
                            let persons = realm.objects(SwiftPerson.self)
                            XCTAssertEqual(persons[0].firstName, "Miles")
                            XCTAssertEqual(persons[0].lastName, "O'Brien")
                            XCTAssertEqual(persons[1].firstName, "Jean Luc")
                            XCTAssertEqual(persons[1].lastName, "Picard")
                            XCTAssertEqual(persons[2].firstName, "Benjamin")
                            XCTAssertEqual(persons[2].lastName, "Sisko")

                            try realm.write {
                                persons[environment.identifier].firstName = "\(environment.identifier)"
                                persons[environment.identifier].lastName = "of Nine"
                            }
                            // CHECKPOINT 3
                            if realm.syncSession != nil {
                                print("waiting for uploads")
                                try await self.waitForUploads(for: realm)
                                print("uploads complete")
                                self.send(event: .uploadedChildData)
                            }
                        case .uploadedChildData:
                            let persons = realm.objects(SwiftPerson.self)
                            realm.refresh()
                            for i in 0..<3 {
                                XCTAssertEqual(persons[i].firstName, "\(i)")
                                XCTAssertEqual(persons[i].lastName, "of Nine")
                            }
                            return
                        default: break
                        }
                    }
                }
                var token: NSKeyValueObservation? = nil
                let realm = try await Realm(configuration: userConfiguration)
                if realm.syncSession == nil {
                    send(event: .nonSyncAgentCheckIn)
                } else if let session = realm.syncSession {
                    session.resume()
                    if session.connectionState != .connected {
                        token = session.observe(\.connectionState) { session, value in
                            if session.connectionState == .connected {
                                self.send(event: .syncAgentCheckIn)
                                token?.invalidate()
                            }
                        }
                    } else {
                        send(event: .syncAgentCheckIn)
                    }
                }
                try await group.waitForAll()
            }
        }
    }
}
#endif
#endif
