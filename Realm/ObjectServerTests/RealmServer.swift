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
import Realm.Private
import RealmSwift
import XCTest

#if os(macOS)

extension URLSession {
    fileprivate func resultDataTask(with request: URLRequest, _ completionHandler: @escaping (Result<Data, Error>) -> Void) {
        URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue()).dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode >= 200 && httpResponse.statusCode < 300,
                let data = data {
                completionHandler(.success(data))
            } else {
                completionHandler(.failure(error ?? URLError(.badServerResponse)))
            }
        }.resume()
    }

    // Synchronously perform a data task, returning the data from it
    fileprivate func resultDataTask(with request: URLRequest) -> Result<Data, Error> {
        var result: Result<Data, Error>!
        let group = DispatchGroup()
        group.enter()
        resultDataTask(with: request) {
            result = $0
            group.leave()
        }
        guard case .success = group.wait(timeout: .now() + 10) else {
            return .failure(URLError(.cannotFindHost))
        }
        return result
    }
}

private func bsonType(_ type: PropertyType) -> String {
    switch type {
    case .UUID: return "uuid"
    case .any: return "mixed"
    case .bool: return "bool"
    case .data: return "binData"
    case .date: return "date"
    case .decimal128: return "decimal"
    case .double: return "double"
    case .float: return "float"
    case .int: return "long"
    case .object: return "object"
    case .objectId: return "objectId"
    case .string: return "string"
    case .linkingObjects: return "linkingObjects"
    }
}

private extension Property {
    func stitchRule(_ schema: Schema) -> [String: Any] {
        let type: String
        if self.type == .object {
            type = bsonType(schema[objectClassName!]!.primaryKeyProperty!.type)
        } else {
            type = bsonType(self.type)
        }

        if isArray {
            return [
                "bsonType": "array",
                "items": [
                    "bsonType": type
                ]
            ]
        }
        if isSet {
            return [
                "bsonType": "array",
                "uniqueItems": true,
                "items": [
                    "bsonType": type
                ]
            ]
        }
        if isMap {
            return [
                "bsonType": "object",
                "properties": [:],
                "additionalProperties": [
                    "bsonType": type
                ]
            ]
        }

        return [
            "bsonType": type
        ]
    }
}

private extension ObjectSchema {
    func stitchRule(_ partitionKeyType: String?, _ schema: Schema, id: String? = nil) -> [String: Any] {
        var stitchProperties: [String: Any] = [:]

        // We only add a partition property for pbs
        if let partitionKeyType = partitionKeyType {
            stitchProperties["realm_id"] = [
                "bsonType": "\(partitionKeyType)"
            ]
        }

        var relationships: [String: Any] = [:]

        // First pass we only add the properties to the schema as we can't add
        // links until the targets of the links exist.
        let pk = primaryKeyProperty!
        stitchProperties[pk.name] = pk.stitchRule(schema)
        for property in properties {
            if property.type != .object {
                stitchProperties[property.name] = property.stitchRule(schema)
            } else if id != nil {
                stitchProperties[property.name] = property.stitchRule(schema)
                relationships[property.name] = [
                    "ref": "#/relationship/mongodb1/test_data/\(property.objectClassName!)",
                    "foreign_key": "_id",
                    "is_list": property.isArray || property.isSet || property.isMap
                ]
            }
        }

        return [
            "_id": id as Any,
            "schema": [
                "properties": stitchProperties,
                // The server currently only supports non-optional collections
                // but requires them to be marked as optional
                "required": properties.compactMap { $0.isOptional || $0.type == .any || $0.isArray || $0.isMap || $0.isSet ? nil : $0.name },
                "title": "\(className)"
            ],
            "metadata": [
                "data_source": "mongodb1",
                "database": "test_data",
                "collection": "\(className)",
            ],
            "relationships": relationships
        ]
    }
}

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
                                 completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                var components = URLComponents(url: self.url, resolvingAgainstBaseURL: false)!
                components.query = "bypass_service_change=SyncProtocolVersionIncrease"
                var request = URLRequest(url: components.url!)
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
                        completionHandler(.failure(error))
                    }
                }

                URLSession(configuration: URLSessionConfiguration.default,
                           delegate: nil, delegateQueue: OperationQueue())
                    .resultDataTask(with: request) { result in
                        completionHandler(result.flatMap { data in
                            Result {
                                data.count > 0 ? try JSONSerialization.jsonObject(with: data) : nil
                            }
                        })
                }
            }

            private func request(on group: DispatchGroup, httpMethod: String, data: Any? = nil, _ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                group.enter()
                request(httpMethod: httpMethod, data: data) { result in
                    completionHandler(result)
                    group.leave()
                }
            }

            private func request(httpMethod: String, data: Any? = nil) -> Result<Any?, Error> {
                let group = DispatchGroup()
                var result: Result<Any?, Error>!
                group.enter()
                request(httpMethod: httpMethod, data: data) {
                    result = $0
                    group.leave()
                }
                guard case .success = group.wait(timeout: .now() + 5) else {
                    return .failure(URLError(.badServerResponse))
                }
                return result
            }

            func get(_ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                request(httpMethod: "GET", completionHandler: completionHandler)
            }

            func get(on group: DispatchGroup, _ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                request(on: group, httpMethod: "GET", completionHandler)
            }

            func get() -> Result<Any?, Error> {
                request(httpMethod: "GET")
            }

            func post(_ data: Any, _ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                request(httpMethod: "POST", data: data, completionHandler: completionHandler)
            }

            func post(on group: DispatchGroup, _ data: Any,
                      _ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                request(on: group, httpMethod: "POST", data: data, completionHandler)
            }

            func post(_ data: Any) -> Result<Any?, Error> {
                request(httpMethod: "POST", data: data)
            }

            func put(_ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                request(httpMethod: "PUT", completionHandler: completionHandler)
            }

            func put(on group: DispatchGroup, data: Any? = nil, _ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                request(on: group, httpMethod: "PUT", data: data, completionHandler)
            }

            func put(data: Any? = nil, _ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                request(httpMethod: "PUT", data: data, completionHandler: completionHandler)
            }

            func put(_ data: Any) -> Result<Any?, Error> {
                request(httpMethod: "PUT", data: data)
            }

            func delete(_ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                request(httpMethod: "DELETE", completionHandler: completionHandler)
            }

            func delete(on group: DispatchGroup, _ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                request(on: group, httpMethod: "DELETE", completionHandler)
            }

            func patch(on group: DispatchGroup, _ data: Any, _ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                request(on: group, httpMethod: "PATCH", data: data, completionHandler)
            }

            func patch(_ data: Any) -> Result<Any?, Error> {
                request(httpMethod: "PATCH", data: data)
            }

            func patch(_ data: Any, _ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                request(httpMethod: "PATCH", data: data, completionHandler: completionHandler)
            }
        }

        /// The initial endpoint to access the admin server
        lazy var apps = AdminEndpoint(accessToken: accessToken,
                                      groupId: groupId,
                                      url: URL(string: "http://localhost:9090/api/admin/v3.0/groups/\(groupId)/apps")!)
    }

    private func userProfile(accessToken: String) -> Result<AdminProfile, Error> {
        var request = URLRequest(url: URL(string: "http://localhost:9090/api/admin/v3.0/auth/profile")!)
        request.allHTTPHeaderFields = [
            "Authorization": "Bearer \(String(describing: accessToken))"
        ]
        return URLSession.shared.resultDataTask(with: request)
            .flatMap { data in
                Result {
                    try JSONDecoder().decode(AdminProfile.self, from: data)
                }
            }
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
        return try URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue())
            .resultDataTask(with: loginRequest)
            .flatMap { data in
                return Result {
                    if let accessToken = try JSONDecoder().decode([String: String].self, from: data)["access_token"] {
                        return accessToken
                    }
                    throw URLError(.badServerResponse)
                }
            }
            .flatMap { (accessToken: String) -> Result<AdminSession, Error> in
                self.userProfile(accessToken: accessToken).map {
                    AdminSession(accessToken: accessToken, groupId: $0.roles[0].groupId)
                }
            }
            .get()
    }
}

// Sync mode 
public enum SyncMode {
    case pbs(String) // partition based
    case flx([String]) // flexible sync
}

// MARK: RealmServer

/**
 A sandboxed server. This singleton launches and maintains all server processes
 and allows for app creation.
 */
@available(OSX 10.13, *)
@objc(RealmServer)
public class RealmServer: NSObject {
    public enum LogLevel {
        case none, info, warn, error
    }

    /// Shared RealmServer. This class only needs to be initialized and torn down once per test suite run.
    @objc public static var shared = RealmServer()

    /// Log level for the server and mongo processes.
    public var logLevel = LogLevel.none

    /// Process that runs the local mongo server. Should be terminated on exit.
    private let mongoProcess = Process()
    /// Process that runs the local backend server. Should be terminated on exit.
    private let serverProcess = Process()

    /// The root URL of the project.
    private static let rootUrl = URL(string: #file)!
        .deletingLastPathComponent() // RealmServer.swift
        .deletingLastPathComponent() // ObjectServerTests
        .deletingLastPathComponent() // Realm
    private static let buildDir = rootUrl.appendingPathComponent(".baas")
    private static let binDir = buildDir.appendingPathComponent("bin")

    /// The directory where mongo stores its files. This is a unique value so that
    /// we have a fresh mongo each run.
    private lazy var tempDir = URL(fileURLWithPath: NSTemporaryDirectory(),
                                   isDirectory: true).appendingPathComponent("realm-test-\(UUID().uuidString)")

    /// Whether or not this is a parent or child process.
    private lazy var isParentProcess = (getenv("RLMProcessIsChild") == nil)

    /// The current admin session
    private var session: Admin.AdminSession?

    /// Check if the BaaS files are present and we can run the server
    @objc public class func haveServer() -> Bool {
        let goDir = RealmServer.buildDir.appendingPathComponent("stitch")
        return FileManager.default.fileExists(atPath: goDir.path)
    }

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

        let mongo = RealmServer.binDir.appendingPathComponent("mongo").path

        // step down the replica set
        let rsStepDownProcess = Process()
        rsStepDownProcess.launchPath = mongo
        rsStepDownProcess.arguments = [
            "admin",
            "--port", "26000",
            "--eval", "'db.adminCommand({replSetStepDown: 0, secondaryCatchUpPeriodSecs: 0, force: true})'"]
        try? rsStepDownProcess.run()
        rsStepDownProcess.waitUntilExit()

        // step down the replica set
        let mongoShutdownProcess = Process()
        mongoShutdownProcess.launchPath = mongo
        mongoShutdownProcess.arguments = [
            "admin",
            "--port", "26000",
            "--eval", "'db.shutdownServer({force: true})'"]
        try? mongoShutdownProcess.run()
        mongoShutdownProcess.waitUntilExit()

        mongoProcess.terminate()

        try? FileManager().removeItem(at: tempDir)
    }()

    /// Launch the mongo server in the background.
    /// This process should run until the test suite is complete.
    private func launchMongoProcess() throws {
        try! FileManager().createDirectory(at: tempDir,
                                           withIntermediateDirectories: false,
                                           attributes: nil)

        mongoProcess.launchPath = RealmServer.binDir.appendingPathComponent("mongod").path
        mongoProcess.arguments = [
            "--quiet",
            "--dbpath", tempDir.path,
            "--bind_ip", "localhost",
            "--port", "26000",
            "--replSet", "test"
        ]
        mongoProcess.standardOutput = nil
        try mongoProcess.run()

        let initProcess = Process()
        initProcess.launchPath = RealmServer.binDir.appendingPathComponent("mongo").path
        initProcess.arguments = [
            "--port", "26000",
            "--eval", "rs.initiate()"
        ]
        initProcess.standardOutput = nil
        try initProcess.run()
        initProcess.waitUntilExit()
    }

    private func launchServerProcess() throws {
        let binDir = Self.buildDir.appendingPathComponent("bin").path
        let libDir = Self.buildDir.appendingPathComponent("lib").path
        let binPath = "$PATH:\(binDir)"
        let awsAccessKeyId = ProcessInfo.processInfo.environment["AWS_ACCESS_KEY_ID"]!
        let awsSecretAccessKey = ProcessInfo.processInfo.environment["AWS_SECRET_ACCESS_KEY"]!
        let env = [
            "PATH": binPath,
            "DYLD_LIBRARY_PATH": libDir,
            "AWS_ACCESS_KEY_ID": awsAccessKeyId,
            "AWS_SECRET_ACCESS_KEY": awsSecretAccessKey
        ]

        let stitchRoot = RealmServer.buildDir.path + "/go/src/github.com/10gen/stitch"

        for _ in 0..<5 {
            // create the admin user
            let userProcess = Process()
            userProcess.environment = env
            userProcess.launchPath = "\(binDir)/create_user"
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
            if userProcess.terminationStatus == 0 {
                break
            }
        }

        serverProcess.environment = env
        // golang server needs a tmp directory
        try! FileManager.default.createDirectory(atPath: "\(tempDir.path)/tmp",
            withIntermediateDirectories: false, attributes: nil)
        serverProcess.launchPath = "\(binDir)/stitch_server"
        serverProcess.currentDirectoryPath = tempDir.path
        serverProcess.arguments = [
            "--configFile",
            "\(stitchRoot)/etc/configs/test_config.json",
            "--configFile",
            "\(RealmServer.rootUrl)/Realm/ObjectServerTests/config_overrides.json"
        ]

        let pipe = Pipe()
        pipe.fileHandleForReading.readabilityHandler = { file in
            guard file.availableData.count > 0,
                  let available = String(data: file.availableData, encoding: .utf8)?.split(separator: "\t") else {
                return
            }

            // prettify server output
            var parts = [String]()
            for part in available {
                if part.contains("INFO") {
                    guard self.logLevel == .info else {
                        return
                    }
                    parts.append("🔵")
                } else if part.contains("DEBUG") {
                    guard self.logLevel == .info || self.logLevel == .warn else {
                        return
                    }
                    parts.append("🟡")
                } else if part.contains("ERROR") {
                    parts.append("🔴")
                } else if let json = try? JSONSerialization.jsonObject(with: part.data(using: .utf8)!) {
                    parts.append(String(data: try! JSONSerialization.data(withJSONObject: json,
                                                                       options: .prettyPrinted),
                                  encoding: .utf8)!)
                } else if !part.isEmpty {
                    parts.append(String(part))
                }
            }
            print(parts.joined(separator: "\t"))
        }

        if logLevel != .none {
            serverProcess.standardOutput = pipe
        } else {
            serverProcess.standardOutput = nil
        }

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
            session.dataTask(with: URL(string: "http://localhost:9090/api/admin/v3.0/groups/groupId/apps/appId")!) { (_, _, error) in
                if error != nil {
                    usleep(50000)
                    pingServer(tries + 1)
                } else {
                    group.leave()
                }
            }.resume()
        }
        pingServer()
        guard case .success = group.wait(timeout: .now() + 20) else {
            return XCTFail("Server did not start")
        }
    }

    public typealias AppId = String

    private func failOnError<T>(_ result: Result<T, Error>) {
        if case .failure(let error) = result {
            XCTFail(error.localizedDescription)
        }
    }

    /// Create a new server app
    /// This will create a App with different configuration depending on the SyncMode (partition based sync or flexible sync), partition type is used only in case
    /// this is partition based sync, and will crash if one is not provided in that mode
    public func createAppForSyncMode(_ syncMode: SyncMode) throws -> AppId {
        guard let session = session else {
            throw URLError(.unknown)
        }

        let info = try session.apps.post(["name": "test"]).get()
        guard let appInfo = info as? [String: Any],
              let clientAppId = appInfo["client_app_id"] as? String,
              let appId = appInfo["_id"] as? String else {
            throw URLError(.badServerResponse)
        }

        let app = session.apps[appId]
        let group = DispatchGroup()

        _ = app.secrets.post([
            "name": "customTokenKey",
            "value": "My_very_confidential_secretttttt"
        ])

        app.authProviders.post(on: group, [
            "type": "custom-token",
            "config": [
                "audience": [],
                "signingAlgorithm": "HS256",
                "useJWKURI": false
            ],
            "secret_config": ["signingKeys": ["customTokenKey"]],
            "metadata_fields": [
                ["required": false, "name": "user_data.name", "field_name": "name"],
                ["required": false, "name": "user_data.occupation", "field_name": "occupation"],
                ["required": false, "name": "my_metadata.name", "field_name": "anotherName"]
            ]
        ], failOnError)

        app.authProviders.post(on: group, ["type": "anon-user"], failOnError)
        app.authProviders.post(on: group, [
            "type": "local-userpass",
            "config": [
                "emailConfirmationUrl": "http://foo.com",
                "resetPasswordUrl": "http://foo.com",
                "confirmEmailSubject": "Hi",
                "resetPasswordSubject": "Bye",
                "autoConfirm": true
            ]
        ], failOnError)

        app.authProviders.get(on: group) { authProviders in
            do {
                guard let authProviders = try authProviders.get() as? [[String: Any]] else {
                    return XCTFail("Bad formatting for authProviders")
                }
                guard let provider = authProviders.first(where: { $0["type"] as? String == "api-key" }) else {
                    return XCTFail("Did not find api-key provider")
                }
                app.authProviders[provider["_id"] as! String].enable.put(on: group, self.failOnError)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        _ = app.secrets.post([
            "name": "BackingDB_uri",
            "value": "mongodb://localhost:26000"
        ])

        let appService: [String: Any] = [
            "name": "mongodb1",
            "type": "mongodb",
            "config": [
                "uri": "mongodb://localhost:26000"
            ]
        ]

        let serviceResponse = app.services.post(appService)
        guard let serviceId = (try serviceResponse.get() as? [String: Any])?["_id"] as? String else {
            throw URLError(.badServerResponse)
        }

        // Creating the schema is a two-step process where we first add all the
        // objects with their properties to them so that we can add relationships
        let schema = ObjectiveCSupport.convert(object: RLMSchema.shared())
        let syncTypes: [ObjectSchema]
        let partitionKeyType: String?
        if case .pbs(let bsonType) = syncMode {
            syncTypes = schema.objectSchema.filter {
                guard let pk = $0.primaryKeyProperty else { return false }
                return pk.name == "_id"
            }
            partitionKeyType = bsonType
        } else {
            syncTypes = schema.objectSchema.filter {
                let validSyncClasses = ["Dog", "Person", "SwiftPerson", "SwiftTypesSyncObject"]
                return validSyncClasses.contains($0.className)
            }
            partitionKeyType = nil
        }
        var schemaCreations = [Result<Any?, Error>]()
        for objectSchema in syncTypes {
            schemaCreations.append(app.schemas.post(objectSchema.stitchRule(partitionKeyType, schema)))
        }

        var schemaIds: [String: String] = [:]
        for result in schemaCreations {
            guard case .success(let data) = result else {
                fatalError("Failed to create schema: \(result)")
            }
            let dict = (data as! [String: Any])
            let metadata = dict["metadata"] as! [String: String]
            schemaIds[metadata["collection"]!] = dict["_id"]! as? String
        }

        var schemaUpdates = [Result<Any?, Error>]()
        for objectSchema in syncTypes {
            let schemaId = schemaIds[objectSchema.className]!
            schemaUpdates.append(app.schemas[schemaId].put(objectSchema.stitchRule(partitionKeyType, schema, id: schemaId)))
        }

        for result in schemaUpdates {
            guard case .success = result else {
                fatalError("Failed to create relationships for schema: \(result)")
            }
        }

        let serviceConfig: Any
        switch syncMode {
        case .pbs(let bsonType):
            serviceConfig = [
                "sync": [
                    "state": "enabled",
                    "database_name": "test_data",
                    "partition": [
                        "key": "realm_id",
                        "type": "\(bsonType)",
                        "required": false,
                        "permissions": [
                            "read": true,
                            "write": true
                        ]
                    ]
                ]
            ]
        case .flx(let fields):
            serviceConfig = [
                "flexible_sync": [
                    "state": "enabled",
                    "database_name": "test_data",
                    "queryable_fields_names": fields,
                    "permissions": [
                        "rules": [:],
                        "defaultRoles": [[
                            "name": "all",
                            "applyWhen": [:],
                            "read": true,
                            "write": true
                        ]]
                    ]
                ]
            ]
        }
        let serviceConfigResponse = app.services[serviceId].config.patch(serviceConfig)
        guard case .success = serviceConfigResponse else {
            throw URLError(.badServerResponse)
        }

        app.sync.config.put(on: group, data: [
            "development_mode_enabled": true
        ], failOnError)

        app.functions.post(on: group, [
            "name": "sum",
            "private": false,
            "can_evaluate": [:],
            "source": """
            exports = function(...args) {
                return parseInt(args.reduce((a,b) => a + b, 0));
            };
            """
        ], failOnError)

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
        ], failOnError)

        let rules = app.services[serviceId].rules
        let userDataRule: [String: Any] = [
            "database": "test_data",
            "collection": "UserData",
            "roles": [[
                "name": "default",
                "apply_when": [:],
                "insert": true,
                "delete": true,
                "additional_fields": [:]
            ]]
        ]
        _ = rules.post(userDataRule)
        app.customUserData.patch(on: group, [
            "mongo_service_id": serviceId,
            "enabled": true,
            "database_name": "test_data",
            "collection_name": "UserData",
            "user_id_field": "user_id"
        ], failOnError)

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
        ], failOnError)

        guard case .success = group.wait(timeout: .now() + 5.0) else {
            throw URLError(.badServerResponse)
        }

        return clientAppId
    }

    @objc public func createAppWithQueryableFields(_ fields: [String]) throws -> AppId {
        try createAppForSyncMode(.flx(fields))
    }

    @objc public func createAppForBSONType(_ bsonType: String) throws -> AppId {
        try createAppForSyncMode(.pbs(bsonType))
    }

    @objc public func createApp() throws -> AppId {
        try createAppForSyncMode(.pbs("string"))
    }

    // Retrieve Atlas App Services AppId with ClientAppId using the Admin API
    public func retrieveAppServerId(_ clientAppId: String) throws -> String {
        guard let session = session else {
            fatalError()
        }

        let appsListInfo = try session.apps.get().get()
        guard let appsList = appsListInfo as? [[String: Any]] else {
            throw URLError(.badServerResponse)
        }

        let app = appsList.first(where: {
            guard let clientId = $0["client_app_id"] as? String else {
                return false
            }

            return clientId == clientAppId
        })

        guard let appId = app?["_id"] as? String else {
            throw URLError(.badServerResponse)
        }
        return appId
    }

    public func retrieveSyncServiceId(appServerId: String) throws -> String {
        guard let session = session else {
            fatalError()
        }
        let app = session.apps[appServerId]
        // Get all services
        guard let syncServices = try app.services.get().get() as? [[String: Any]] else {
            throw URLError(.unknown)
        }
        // Find sync service
        guard let syncService = syncServices.first(where: {
            $0["name"] as? String == "mongodb1"
        }) else {
            throw URLError(.unknown)
        }
        // Return sync service id
        guard let serviceId = syncService["_id"] as? String else { throw URLError(.unknown) }
        return serviceId
    }

    public func getSyncServiceConfiguration(appServerId: String, syncServiceId: String) throws -> [String: Any]? {
        guard let session = session else {
            fatalError()
        }
        let app = session.apps[appServerId]
        do {
            return try app.services[syncServiceId].config.get().get() as? [String: Any]
        } catch {
            throw URLError(.unknown)
        }
    }

    public func syncEnabled(appServerId: String, syncServiceId: String) throws -> Bool {
        guard let session = session else {
            fatalError()
        }
        let app = session.apps[appServerId]
        let response = try app.services[syncServiceId].config.get().get() as? [String: Any]
        guard let syncInfo = response?["sync"] as? [String: Any] else {
            return false
        }
        return (syncInfo["state"] as? String == "enabled")
    }

    public func devModeEnabled(appServerId: String, syncServiceId: String) throws -> Bool {
        guard let session = session else {
            fatalError()
        }
        let app = session.apps[appServerId]
        let res = try app.sync.config.get().get() as? [String: Any]
        guard let option = res!["development_mode_enabled"] as? Bool else {
            return false
        }
        return option
    }

    public func enableDevMode(appServerId: String, syncServiceId: String, syncServiceConfiguration: [String: Any], _ completion: @escaping (Result<Any?, Error>) -> Void) {
        guard let session = session else {
            completion(.failure(URLError.unknown as! Error))
            return
        }
        let app = session.apps[appServerId]
        app.sync.config.put(data: ["development_mode_enabled": true], completion)
    }

    public func disableSync(appServerId: String, syncServiceId: String, completion: @escaping (Result<Any?, Error>) -> Void) {
        guard let session = session else {
            completion(.failure(URLError.unknown as! Error))
            return
        }
        let app = session.apps[appServerId]
        app.services[syncServiceId].config.patch(["sync": ["state": ""]], completion)
    }

    public func enableSync(appServerId: String, syncServiceId: String, syncServiceConfiguration: [String: Any], _ completion: @escaping (Result<Any?, Error>) -> Void) {
        var syncConfig = syncServiceConfiguration
        guard let session = session else {
            completion(.failure(URLError.unknown as! Error))
            return
        }
        let app = session.apps[appServerId]
        guard var syncInfo = syncConfig["sync"] as? [String: Any] else {
            completion(.failure(URLError.unknown as! Error))
            return
        }
        syncInfo["state"] = "enabled"
        syncConfig["sync"] = syncInfo
        app.services[syncServiceId].config.patch(syncConfig, completion)
    }

    public func retrieveUser(_ appId: String, userId: String, _ completion: @escaping (Result<Any?, Error>) -> Void) {
        guard let appServerId = try? RealmServer.shared.retrieveAppServerId(appId),
              let session = session else {
            completion(.failure(URLError.unknown as! Error))
            return
        }
        let app = session.apps[appServerId]
        app.users[userId].get(completion)
    }

    // Remove User from Atlas App Services using the Admin API
    public func removeUserForApp(_ appId: String, userId: String, _ completion: @escaping (Result<Any?, Error>) -> Void) {
        guard let appServerId = try? RealmServer.shared.retrieveAppServerId(appId),
              let session = session else {
            completion(.failure(URLError.unknown as! Error))
            return
        }
        let app = session.apps[appServerId]
        app.users[userId].delete(completion)
    }
}

#endif
