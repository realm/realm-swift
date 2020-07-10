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

import Foundation
import RealmSwift
import XCTest

// MARK: - AdminProfile
struct AdminProfile: Codable {
    struct Role: Codable {
        enum CodingKeys: String, CodingKey {
            case groupId = "group_id"
        }

        let groupId: String
    }

    let roles: [Role]
}

// MARK: - Admin
class Admin {
    // MARK: AdminSession
    /// An authenticated session for using the Admin API
    class AdminSession {
        /// The access token of the authenticated user
        var accessToken: String
        /// The group id associated with the authenticated user
        var groupId: String

        init(accessToken: String, groupId: String) {
            self.accessToken = accessToken
            self.groupId = groupId
        }

        // MARK: AdminEndpoint
        /// Representation of a given admin endpoint.
        /// This allows us to call a give endpoint dynamically with loose typing.
        @dynamicMemberLookup
        struct AdminEndpoint {
            /// The access token of the authenticated user
            var accessToken: String
            /// The group id associated with the authenticated user
            var groupId: String
            /// The endpoint url. This will be appending to dynamically by appending the dynamic member called
            /// as if it were a path.
            var url: URL

            /**
             Append the given member to the path. E.g., if the current URL is set to
            http://localhost:9090/api/admin/v3.0/groups/groupId/apps/appId
             and you currently have a:
             ```
             var app: AdminEndpoint
             ```
             you can fetch a list of all services by calling
             ```
             app.services.get()
             ```
             */
            subscript(dynamicMember member: String) -> AdminEndpoint {
                let pattern = "([a-z0-9])([A-Z])"

                let regex = try? NSRegularExpression(pattern: pattern, options: [])
                let range = NSRange(location: 0, length: member.count)
                let snakeCaseMember = regex?.stringByReplacingMatches(in: member,
                                                                      options: [],
                                                                      range: range,
                                                                      withTemplate: "$1_$2").lowercased()
                return AdminEndpoint(accessToken: accessToken,
                                     groupId: groupId,
                                     url: url.appendingPathComponent(snakeCaseMember!))
            }

            /**
             Append the given id to the path. E.g., if the current URL is set to
             http://localhost:9090/api/admin/v3.0/groups/groupId/apps/
              and you currently have a:
              ```
              var apps: AdminEndpoint
              var appId: String
              ```
              you can fetch the app from its appId with
              ```
              apps[appId].get()
              ```
             */
            subscript(_ id: String) -> AdminEndpoint {
                return AdminEndpoint(accessToken: accessToken,
                                     groupId: groupId,
                                     url: url.appendingPathComponent(id))
            }

            private func request(httpMethod: String, data: Any? = nil,
                                 completionHandler: @escaping (Any?, Error?) -> Void) {
                var request = URLRequest(url: url)
                request.httpMethod = httpMethod
                request.allHTTPHeaderFields = [
                    "Authorization": "Bearer \(accessToken)",
                    "Content-Type": "application/json;charset=utf-8",
                    "Accept": "application/json"
                ]
                if let data = data {
                    do {
                        request.httpBody = try JSONSerialization.data(withJSONObject: data)
                    } catch {
                        completionHandler(nil, error)
                    }
                }

                URLSession(configuration: URLSessionConfiguration.default,
                           delegate: nil,
                           delegateQueue: OperationQueue()).dataTask(with: request) { (data, response, error) in
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode >= 200 && httpResponse.statusCode < 300,
                          let data = data else {
                        return completionHandler(nil, error ?? URLError(.badServerResponse))
                    }

                    do {
                        if data.count > 0 {
                            let json = try JSONSerialization.jsonObject(with: data)
                            completionHandler(json, nil)
                        } else {
                            completionHandler(nil, nil)
                        }
                    } catch {
                        completionHandler(nil, error)
                    }
                }.resume()
            }

            func get(_ completionHandler: @escaping (Any?, Error?) -> Void) {
                request(httpMethod: "GET", completionHandler: completionHandler)
            }

            func get(on group: DispatchGroup, _ completionHandler: @escaping (Any?, Error?) -> Void) {
                group.enter()
                get {
                    completionHandler($0, $1)
                    group.leave()
                }
            }

            func get() -> (Any?, Error?) {
                let group = DispatchGroup()
                var any: Any?, error: Error?
                group.enter()
                get {
                    any = $0
                    error = $1
                    group.leave()
                }
                guard case .success = group.wait(timeout: .now() + 5) else {
                    return (any, URLError(.badServerResponse))
                }
                return (any, error)
            }

            func post(_ data: Any, _ completionHandler: @escaping (Any?, Error?) -> Void) {
                request(httpMethod: "POST", data: data, completionHandler: completionHandler)
            }

            func post(on group: DispatchGroup, _ data: Any,
                      _ completionHandler: @escaping (Any?, Error?) -> Void) {
                group.enter()
                post(data) {
                    completionHandler($0, $1)
                    group.leave()
                }
            }

            func post(_ data: Any) -> (Any?, Error?) {
                var any: Any?, error: Error?
                let group = DispatchGroup()
                group.enter()
                post(data) {
                    any = $0
                    error = $1
                    group.leave()
                }
                guard case .success = group.wait(timeout: .now() + 5.0) else {
                    return (any, URLError(.badServerResponse))
                }
                return (any, error)
            }

            func put(_ completionHandler: @escaping (Any?, Error?) -> Void) {
                request(httpMethod: "PUT", completionHandler: completionHandler)
            }

            func put(on group: DispatchGroup, _ data: Any? = nil, _ completionHandler: @escaping (Any?, Error?) -> Void) {
                group.enter()
                request(httpMethod: "PUT", data: data, completionHandler: {
                    completionHandler($0, $1)
                    group.leave()
                })
            }

            func patch(on group: DispatchGroup, _ data: Any, _ completionHandler: @escaping (Any?, Error?) -> Void) {
                group.enter()
                request(httpMethod: "PATCH", data: data, completionHandler: {
                    completionHandler($0, $1)
                    group.leave()
                })
            }
        }

        /// The initial endpoint to access the admin server
        lazy var apps = AdminEndpoint(accessToken: accessToken,
                                      groupId: groupId,
                                      url: URL(string: "http://localhost:9090/api/admin/v3.0/groups/\(groupId)/apps")!)
    }

    private func userProfile(accessToken: String, _ completionHandler: @escaping (AdminProfile?, Error?) -> Void) {
        var request = URLRequest(url: URL(string: "http://localhost:9090/api/admin/v3.0/auth/profile")!)
        request.allHTTPHeaderFields = [
            "Authorization": "Bearer \(String(describing: accessToken))"
        ]
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode >= 200 && httpResponse.statusCode < 300,
                  let data = data else {
                if let error = error {
                    completionHandler(nil, error)
                } else {
                    completionHandler(nil, URLError(.badServerResponse))
                }
                return
            }

            do {
                completionHandler(try JSONDecoder().decode(AdminProfile.self, from: data), nil)
            } catch {
                completionHandler(nil, error)
            }
        }.resume()
    }

    /// Synchronously authenticate an admin session
    func login() throws -> AdminSession {
        let authUrl = URL(string: "http://localhost:9090/api/admin/v3.0/auth/providers/local-userpass/login")!
        var loginRequest = URLRequest(url: authUrl)
        loginRequest.httpMethod = "POST"
        loginRequest.allHTTPHeaderFields = ["Content-Type": "application/json;charset=utf-8",
                                            "Accept": "application/json"]

        loginRequest.httpBody = try! JSONEncoder().encode(["provider": "userpass",
                                                           "username": "unique_user@domain.com",
                                                           "password": "password"])
        var adminSession: AdminSession?
        var outError: Error?
        let group = DispatchGroup()
        group.enter()
        URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue()).dataTask(with: loginRequest) { (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode >= 200 && httpResponse.statusCode < 300,
                  let data = data else {
                if let error = error {
                    outError = error
                } else {
                    outError = URLError(.badServerResponse)
                }
                return
            }

            do {
                guard let accessToken = try JSONDecoder().decode([String: String].self, from: data)["access_token"] else {
                    throw URLError(.badServerResponse)
                }
                self.userProfile(accessToken: accessToken) { (adminProfile, error) in
                    guard let adminProfile = adminProfile else {
                        if let error = error {
                            outError = error
                        } else {
                            outError = URLError(.badServerResponse)
                        }
                        return
                    }

                    adminSession = AdminSession(accessToken: accessToken, groupId: adminProfile.roles[0].groupId)
                    group.leave()
                }
            } catch {
                outError = error
            }
        }.resume()
        guard case .success = group.wait(timeout: .now() + 10) else {
            outError = URLError(.cannotFindHost)
            throw outError!
        }
        if let outError = outError {
            throw outError
        }
        return adminSession!
    }
}

// MARK: RealmServer

/**
 A sandboxed server. This singleton launches and maintains all server processes
 and allows for app creation.
 */
@objc(RealmServer)
public class RealmServer: NSObject {
    /// Shared RealmServer. This class only needs to be initialized and torn down once per test suite run.
    @objc static var shared = RealmServer()

    /// Process that runs the local mongo server. Should be terminated on exit.
    private let mongoProcess = Process()
    /// Process that runs the local backend server. Should be terminated on exit.
    private let serverProcess = Process()

    /// The root URL of the project.
    private lazy var rootUrl = URL(string: #file)!
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    /// The directory where mongo binaries and backing files are kept.
    private lazy var mongoUrl = rootUrl
        .appendingPathComponent("build")
        .appendingPathComponent("mongodb-macos-x86_64-4.4.0-rc5")

    /// The directory where mongo stores its files. This is a unique value so that
    /// we have a fresh mongo each run.
    private lazy var mongoDataDirectory = ObjectId.generate().stringValue

    /// Whether or not this is a parent or child process.
    private lazy var isParentProcess = (getenv("RLMProcessIsChild") == nil)

    /// The current admin session
    private var session: Admin.AdminSession?

    private override init() {
        super.init()

        if isParentProcess {
            atexit {
                _ = RealmServer.shared.tearDown
            }

            do {
                try launchMongoProcess()
                try launchServerProcess()
                self.session = try Admin().login()
            } catch {
                XCTFail("Could not initiate admin session: \(error.localizedDescription)")
            }
        }
    }

    /// Lazy teardown for exit only.
    private lazy var tearDown: () = {
        serverProcess.terminate()

        // step down the replica set
        let rsStepDownProcess = Process()
        rsStepDownProcess.launchPath = mongoUrl.appendingPathComponent("bin").appendingPathComponent("mongo").absoluteString
        rsStepDownProcess.arguments = [
            "admin",
            "--port", "26000",
            "--eval", "'db.adminCommand({replSetStepDown: 0, secondaryCatchUpPeriodSecs: 0, force: true})'"]
        try? rsStepDownProcess.run()
        rsStepDownProcess.waitUntilExit()

        // step down the replica set
        let mongoShutdownProcess = Process()
        mongoShutdownProcess.launchPath = mongoUrl.appendingPathComponent("bin").appendingPathComponent("mongo").absoluteString
        mongoShutdownProcess.arguments = [
            "admin",
            "--port", "26000",
            "--eval", "'db.shutdownServer({force: true})'"]
        try? mongoShutdownProcess.run()
        mongoShutdownProcess.waitUntilExit()

        mongoProcess.waitUntilExit()

        try? FileManager().removeItem(atPath: mongoUrl.appendingPathComponent(mongoDataDirectory).absoluteString)
        try? FileManager().removeItem(atPath: "tmp")
    }()

    /// Launch the mongo server in the background.
    /// This process should run until the test suite is complete.
    private func launchMongoProcess() throws {
        try? FileManager().createDirectory(atPath: mongoUrl.appendingPathComponent(mongoDataDirectory).absoluteString,
                                           withIntermediateDirectories: false,
                                           attributes: nil)

        mongoProcess.launchPath = mongoUrl.appendingPathComponent("bin").appendingPathComponent("mongod").absoluteString
        mongoProcess.arguments = [
            "--quiet",
            "--dbpath", "\(mongoUrl)/\(mongoDataDirectory)",
            "--bind_ip", "localhost",
            "--port", "26000",
            "--replSet", "test"
        ]
        mongoProcess.standardOutput = nil
        try mongoProcess.run()
    }

    private func launchServerProcess() throws {
        let goRoot = rootUrl.appendingPathComponent("build").appendingPathComponent("go").absoluteString
        let bundle = Bundle.init(for: RealmServer.self)
        let serverBinary = bundle.path(forResource: "stitch_server", ofType: nil)
        let createUserBinary = bundle.path(forResource: "create_user", ofType: nil)

        // create the admin user
        let userProcess = Process()
        userProcess.environment = [
            "GOROOT": goRoot,
            "PATH": "$PATH:\(bundle.resourcePath!)",
            "LD_LIBRARY_PATH": bundle.resourcePath!
        ]
        userProcess.launchPath = createUserBinary
        userProcess.arguments = [
            "addUser",
            "-domainID",
            "000000000000000000000000",
            "-mongoURI", "mongodb://localhost:26000",
            "-salt", "DQOWene1723baqD!_@#",
            "-id", "unique_user@domain.com",
            "-password", "password"
        ]
        try userProcess.run()
        userProcess.waitUntilExit()

        serverProcess.environment = [
            "GOROOT": goRoot,
            "PATH": "$PATH:\(bundle.resourcePath!)",
            "LD_LIBRARY_PATH": bundle.resourcePath!
        ]
        // golang server needs a tmp directory
        try? FileManager.default.createDirectory(atPath: "tmp", withIntermediateDirectories: false, attributes: nil)
        serverProcess.launchPath = serverBinary
        serverProcess.arguments = [
            "--configFile",
            bundle.path(forResource: "test_config", ofType: "json")!
        ]

        let pipe = Pipe()
        pipe.fileHandleForReading.readabilityHandler = { file in
            // prettify server output
            let available = String(data: file.availableData, encoding: .utf8)?.split(separator: "\t")
            print(available!.map { part -> String in
                if part.contains("INFO") {
                    return "🔵"
                } else if part.contains("DEBUG") {
                    return "🟡"
                } else if part.contains("ERROR") {
                    return "🔴"
                } else if let json = try? JSONSerialization.jsonObject(with: part.data(using: .utf8)!) {
                    return String(data: try! JSONSerialization.data(withJSONObject: json,
                                                                    options: .prettyPrinted),
                                  encoding: .utf8)!
                } else if !part.isEmpty {
                    return String(part)
                } else {
                    return ""
                }
            }.joined(separator: "\t"))
        }

        serverProcess.standardOutput = pipe
        try serverProcess.run()
        waitForServerToStart()
    }

    private func waitForServerToStart() {
        let group = DispatchGroup()
        group.enter()
        func pingServer(_ tries: Int = 0) {
            let session = URLSession(configuration: URLSessionConfiguration.default,
                                     delegate: nil,
                                     delegateQueue: OperationQueue())
            session.dataTask(with: URL(string: "http://localhost:9090")!) { (_, _, error) in
                if error != nil {
                    usleep(50000)
                    pingServer(tries + 1)
                } else {
                    group.leave()
                }
            }.resume()
        }
        pingServer()
        guard case .success = group.wait(timeout: .now() + 10) else {
            return XCTFail("Server did not start")
        }
    }

    typealias AppId = String

    /// Create a new server app
    @objc func createApp() throws -> AppId {
        guard let session = session else {
            throw URLError(.unknown)
        }

        let (info, appCreationError) = session.apps.post(["name": "test"])
        guard let appInfo = info as? [String: Any],
              let clientAppId = appInfo["client_app_id"] as? String,
              let appId = appInfo["_id"] as? String else {
            throw appCreationError ?? URLError(.badServerResponse)
        }

        let app = session.apps[appId]
        let group = DispatchGroup()

        app.authProviders.post(on: group, ["type": "anon-user"], { if let error = $1 {
            XCTFail(error.localizedDescription)
        }})
        app.authProviders.post(on: group,
            [
                "type": "local-userpass",
                "config": [
                    "emailConfirmationUrl": "http://foo.com",
                    "resetPasswordUrl": "http://foo.com",
                    "confirmEmailSubject": "Hi",
                    "resetPasswordSubject": "Bye",
                    "autoConfirm": true
                ]
            ]) { if let error = $1 {
            XCTFail(error.localizedDescription)
        }}

        app.authProviders.get(on: group) { any, error in
            guard let authProviders = any as? [[String: Any]] else {
                return XCTFail("Bad formatting for authProviders")
            }

            for provider in authProviders where provider["type"] as? String == "api-key" {
                return app.authProviders[provider["_id"] as! String].enable.put(on: group) { if let error = $1 {
                    XCTFail(error.localizedDescription)
                }}
            }
        }

        let (_, _) = app.secrets.post([
            "name": "BackingDB_uri",
            "value": "mongodb://localhost:26000"
        ])

        let (serviceResponse, serviceCreationError) = app.services.post([
            "name": "mongodb1",
            "type": "mongodb",
            "config": [
                "uri": "mongodb://localhost:26000",
                "sync": [
                    "state": "enabled",
                    "database_name": "test_data",
                    "partition": [
                        "key": "realm_id",
                        "type": "string",
                        "permissions": [
                            "read": true,
                            "write": true
                        ]
                    ]
                ]
            ]
        ])

        guard serviceCreationError == nil,
              let serviceId = (serviceResponse as? [String: Any])?["_id"] as? String else {
            throw serviceCreationError ?? URLError(.badServerResponse)
        }

        let dogRule: [String: Any] = [
            "database": "test_data",
            "collection": "Dog",
            "roles": [[
                "name": "default",
                "apply_when": [:],
                "insert": true,
                "delete": true,
                "additional_fields": [:]
            ]],
            "schema": [
                "properties": [
                    "_id": [
                        "bsonType": "objectId"
                    ],
                    "breed": [
                        "bsonType": "string"
                    ],
                    "name": [
                        "bsonType": "string"
                    ],
                    "realm_id": [
                        "bsonType": "string"
                    ]
                ],
                "required": ["name"],
                "title": "Dog"
            ]
        ]

        let personRule: [String: Any] = [
            "database": "test_data",
            "collection": "Person",
            "relationships": [:],
            "roles": [[
                "name": "default",
                "apply_when": [:],
                "write": true,
                "insert": true,
                "delete": true,
                "additional_fields": [:]
            ]],
            "schema": [
                "properties": [
                    "_id": [
                        "bsonType": "objectId"
                    ],
                    "age": [
                        "bsonType": "int"
                    ],
                    "firstName": [
                        "bsonType": "string"
                    ],
                    "lastName": [
                        "bsonType": "string"
                    ],
                    "realm_id": [
                        "bsonType": "string"
                    ]
                ],
                "required": ["firstName",
                             "lastName",
                             "age"],
                "title": "Person"
            ]
        ]

        let hugeSyncObjectRule: [String: Any] = [
            "database": "test_data",
            "collection": "HugeSyncObject",
            "roles": [[
                "name": "default",
                        "apply_when": [:],
                "insert": true,
                "delete": true,
                        "additional_fields": [:]
            ]],
            "schema": [
                "properties": [
                    "_id": [
                        "bsonType": "objectId"
                    ],
                    "dataProp": [
                        "bsonType": "binData"
                    ],
                    "realm_id": [
                        "bsonType": "string"
                    ]
                ],
                "required": [],
                "title": "HugeSyncObject"
            ],
            "relationships": [:]
        ]

        let userDataRule: [String: Any] = [
            "database": "test_data",
            "collection": "UserData",
            "roles": [[
                "name": "default",
                "apply_when": [:],
                "insert": true,
                "delete": true,
                "additional_fields": [:]
            ]],
            "schema": [:],
            "relationships": [:]
        ]

        let rules = app.services[serviceId].rules
        rules.post(on: group, dogRule, { if let error = $1 { XCTFail(error.localizedDescription) }})
        rules.post(on: group, personRule, { if let error = $1 { XCTFail(error.localizedDescription) }})
        rules.post(on: group, hugeSyncObjectRule, { if let error = $1 { XCTFail(error.localizedDescription) }})
        rules.post(on: group, [
            "database": "test_data",
            "collection": "SwiftPerson",
            "roles": [[
                "name": "default",
                "apply_when": [:],
                "insert": true,
                "delete": true,
                "additional_fields": [:]
            ]],
            "schema": [
                "properties": [
                    "_id": [
                        "bsonType": "objectId"
                    ],
                    "age": [
                        "bsonType": "int"
                    ],
                    "firstName": [
                        "bsonType": "string"
                    ],
                    "lastName": [
                        "bsonType": "string"
                    ],
                    "realm_id": [
                        "bsonType": "string"
                    ]
                ],
                "required": [
                             "firstName",
                             "lastName",
                             "age"
                             ],
                "title": "SwiftPerson"
            ],
                "relationships": [:]
        ]) { if let error = $1 { XCTFail(error.localizedDescription) }}

        app.sync.config.put(on: group, [
            "development_mode_enabled": true
        ]) { if let error = $1 { XCTFail(error.localizedDescription) }}

        app.functions.post(on: group, [
            "name": "sum",
            "private": false,
            "can_evaluate": [:],
            "source": """
            exports = function(...args) {
                return parseInt(args.reduce((a,b) => a + b, 0));
            };
            """
        ]) { if let error = $1 { XCTFail(error.localizedDescription) }}

        app.functions.post(on: group, [
            "name": "updateUserData",
            "private": false,
            "can_evaluate": [:],
            "source": """
            exports = async function(data) {
                const user = context.user;
                const mongodb = context.services.get("mongodb1");
                const userDataCollection = mongodb.db("test_data").collection("UserData");
                await userDataCollection.updateOne(
                                                   { "user_id": user.id },
                                                   { "$set": data },
                                                   { "upsert": true }
                                                   );
                return true;
            };
            """
        ]) { if let error = $1 { XCTFail(error.localizedDescription) }}

        _ = rules.post(userDataRule)
        app.customUserData.patch(on: group, [
            "mongo_service_id": serviceId,
            "enabled": true,
            "database_name": "test_data",
            "collection_name": "UserData",
            "user_id_field": "user_id"
        ]) { if let error = $1 { XCTFail(error.localizedDescription) }}

        _ = app.secrets.post([
            "name": "gcm",
            "value": "gcm"
        ])

        app.services.post(on: group, [
            "name": "gcm",
            "type": "gcm",
            "config": [
                "senderId": "gcm"
            ],
            "secret_config": [
                "apiKey": "gcm"
            ],
            "version": 1
        ]) { if let error = $1 { XCTFail(error.localizedDescription) }}

        guard case .success = group.wait(timeout: .now() + 5.0) else {
            throw URLError(.badServerResponse)
        }

        return clientAppId
    }
}
