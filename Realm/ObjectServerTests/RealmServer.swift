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

#if canImport(RealmSwiftTestSupport)
import RealmSwiftTestSupport
import RealmSyncTestSupport
#endif

#if os(macOS)

extension URLSession {
    fileprivate func resultDataTask(with request: URLRequest,
                                    _ completionHandler: @Sendable @escaping (Result<Data, Error>) -> Void) {
        URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue()).dataTask(with: request) { (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode >= 200 && httpResponse.statusCode < 300,
                let data = data {
                completionHandler(.success(data))
            } else if let error = error {
                completionHandler(.failure(error))
            } else if let data = data, let string = String(data: data, encoding: .utf8) {
                completionHandler(.failure(NSError(domain: URLError.errorDomain,
                                                   code: URLError.badServerResponse.rawValue,
                                                   userInfo: [NSLocalizedDescriptionKey: string])))
            } else {
                completionHandler(.failure(URLError(.badServerResponse)))
            }
        }.resume()
    }

    // Synchronously perform a data task, returning the data from it
    fileprivate func resultDataTask(with request: URLRequest) -> Result<Data, Error> {
        let result = Locked(Result<Data, Error>?.none)
        let group = DispatchGroup()
        group.enter()
        resultDataTask(with: request) {
            result.value = $0
            group.leave()
        }
        guard case .success = group.wait(timeout: .now() + 10) else {
            return .failure(URLError(.cannotFindHost))
        }
        return result.value!
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
    func stitchRule(_ objectSchema: ObjectSchema) -> [String: Json] {
        let type: String
        if self.type == .object {
            type = bsonType(objectSchema.primaryKeyProperty!.type)
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

internal protocol Json {}
extension Bool: Json {}
extension Int: Json {}
extension Int64: Json {}
extension String: Json {}
extension Double: Json {}
extension Dictionary: Json where Key == String, Value == Json {}
extension Array: Json where Element == Json {}
extension Optional: Json where Wrapped: Json {}

private extension ObjectSchema {
    func stitchRule(_ partitionKeyType: String?, id: String? = nil, appId: String) -> [String: Json] {
        var stitchProperties: [String: Json] = [:]

        // We only add a partition property for pbs
        if let partitionKeyType = partitionKeyType {
            stitchProperties["realm_id"] = [
                "bsonType": "\(partitionKeyType)"
            ]
        }

        var relationships: [String: Json] = [:]

        // First pass we only add the properties to the schema as we can't add
        // links until the targets of the links exist.
        let pk = primaryKeyProperty!
        stitchProperties[pk.columnName] = pk.stitchRule(self)
        for property in properties {
            if property.type != .object {
                stitchProperties[property.columnName] = property.stitchRule(self)
            } else if id != nil {
                stitchProperties[property.columnName] = property.stitchRule(self)
                relationships[property.columnName] = [
                    "ref": "#/relationship/mongodb1/test_data/\(property.objectClassName!) \(appId)",
                    "foreign_key": "_id",
                    "is_list": property.isArray || property.isSet || property.isMap
                ]
            }
        }

        return [
            "_id": id as Json,
            "schema": [
                "properties": stitchProperties,
                // The server currently only supports non-optional collections
                // but requires them to be marked as optional
                "required": properties.compactMap { $0.isOptional || $0.type == .any || $0.isArray || $0.isMap || $0.isSet ? nil : $0.columnName },
                "title": "\(className)"
            ],
            "metadata": [
                "data_source": "mongodb1",
                "database": "test_data",
                "collection": "\(className) \(appId)"
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
            case roleName = "role_name"
        }

        let roleName: String
        let groupId: String?
    }

    let roles: [Role]
}

// Dispatch has not yet been annotated for sendability
extension DispatchGroup: @unchecked Sendable {
}

private extension DispatchGroup {
    func throwingWait(timeout: DispatchTime) throws {
        if wait(timeout: timeout) == .timedOut {
            throw URLError(.timedOut)
        }
    }
}

// MARK: AdminSession
/// An authenticated session for using the Admin API
final class AdminSession: Sendable {
    /// The access token of the authenticated user
    let accessToken: String
    /// The group id associated with the authenticated user
    let groupId: String

    init(accessToken: String, groupId: String) {
        self.accessToken = accessToken
        self.groupId = groupId
        apps = .init(accessToken: accessToken,
                     groupId: groupId,
                     url: URL(string: "http://localhost:9090/api/admin/v3.0/groups/\(groupId)/apps")!)
        privateApps = .init(accessToken: accessToken,
                            groupId: groupId,
                            url: URL(string: "http://localhost:9090/api/private/v1.0/groups/\(groupId)/apps")!)
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

        typealias Completion = @Sendable (Result<Any?, Error>) -> Void

        private func request(httpMethod: String, data: Any? = nil,
                             completionHandler: @escaping Completion) {
            var components = URLComponents(url: self.url, resolvingAgainstBaseURL: false)!
            components.query = "bypass_service_change=DestructiveSyncProtocolVersionIncrease"
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

        private func request(on group: DispatchGroup, httpMethod: String, data: Any? = nil,
                             _ completionHandler: @escaping Completion) {
            group.enter()
            request(httpMethod: httpMethod, data: data) { result in
                completionHandler(result)
                group.leave()
            }
        }

        private func request(httpMethod: String, data: Any? = nil) -> Result<Any?, Error> {
            let group = DispatchGroup()
            let result = Locked(Result<Any?, Error>?.none)
            group.enter()
            request(httpMethod: httpMethod, data: data) {
                result.value = $0
                group.leave()
            }
            guard case .success = group.wait(timeout: .now() + 60) else {
                print("HTTP request timed out: \(httpMethod) \(self.url)")
                return .failure(URLError(.timedOut))
            }
            return result.value!
        }

        func get(_ completionHandler: @escaping Completion) {
            request(httpMethod: "GET", completionHandler: completionHandler)
        }

        func get(on group: DispatchGroup,
                 _ completionHandler: @escaping Completion) {
            request(on: group, httpMethod: "GET", completionHandler)
        }

        func get() -> Result<Any?, Error> {
            request(httpMethod: "GET")
        }

        func post(_ data: [String: Json], _ completionHandler: @escaping Completion) {
            request(httpMethod: "POST", data: data, completionHandler: completionHandler)
        }

        func post(on group: DispatchGroup, _ data: [String: Json],
                  _ completionHandler: @escaping Completion) {
            request(on: group, httpMethod: "POST", data: data, completionHandler)
        }

        func post(_ data: [String: Json]) -> Result<Any?, Error> {
            request(httpMethod: "POST", data: data)
        }

        func put(_ completionHandler: @escaping Completion) {
            request(httpMethod: "PUT", completionHandler: completionHandler)
        }

        func put(on group: DispatchGroup, data: Json? = nil,
                 _ completionHandler: @escaping Completion) {
            request(on: group, httpMethod: "PUT", data: data, completionHandler)
        }

        func put(data: [String: Json]? = nil, _ completionHandler: @escaping Completion) {
            request(httpMethod: "PUT", data: data, completionHandler: completionHandler)
        }

        func put(_ data: [String: Json]) -> Result<Any?, Error> {
            request(httpMethod: "PUT", data: data)
        }

        func delete(_ completionHandler: @escaping Completion) {
            request(httpMethod: "DELETE", completionHandler: completionHandler)
        }

        func delete(on group: DispatchGroup, _ completionHandler: @escaping Completion) {
            request(on: group, httpMethod: "DELETE", completionHandler)
        }

        func delete() -> Result<Any?, Error> {
            request(httpMethod: "DELETE")
        }

        func patch(on group: DispatchGroup, _ data: [String: Json],
                   _ completionHandler: @escaping Completion) {
            request(on: group, httpMethod: "PATCH", data: data, completionHandler)
        }

        func patch(_ data: Any) -> Result<Any?, Error> {
            request(httpMethod: "PATCH", data: data)
        }

        func patch(_ data: [String: Json], _ completionHandler: @escaping Completion) {
            request(httpMethod: "PATCH", data: data, completionHandler: completionHandler)
        }
    }

    /// The initial endpoint to access the admin server
    let apps: AdminEndpoint///

    /// The initial endpoint to access the private API
    let privateApps: AdminEndpoint
}

// MARK: - Admin
class Admin {
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

        loginRequest.httpBody = try JSONEncoder().encode(["provider": "userpass",
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
                    AdminSession(accessToken: accessToken, groupId: $0.roles.first(where: { role in
                        role.roleName == "GROUP_OWNER"
                    })!.groupId!)
                }
            }
            .get()
    }
}

// Sync mode 
public enum SyncMode {
    case pbs(String) // partition based
    case flx([String]) // flexible sync
    case none
}

// MARK: RealmServer

/**
 A sandboxed server. This singleton launches and maintains all server processes
 and allows for app creation.
 */
@objc(RealmServer)
final public class RealmServer: NSObject, Sendable {
    public enum LogLevel: Sendable {
        case none, info, warn, error
    }

    /// Shared RealmServer. This class only needs to be initialized and torn down once per test suite run.
    @objc public static let shared: RealmServer! = RealmServer(())

    /// Log level for the server and mongo processes.
    public let logLevel = LogLevel.none

    /// Process that runs the local mongo server. Should be terminated on exit.
    private let mongoProcess: Process
    /// Process that runs the local backend server. Should be terminated on exit.
    private let serverProcess: Process

    /// The root URL of the project.
    private static let rootUrl = URL(string: #filePath)!
        .deletingLastPathComponent() // RealmServer.swift
        .deletingLastPathComponent() // ObjectServerTests
        .deletingLastPathComponent() // Realm
    private static let buildDir = rootUrl.appendingPathComponent("ci_scripts/setup_baas/.baas")
    private static let binDir = buildDir.appendingPathComponent("bin")

    /// The directory where mongo stores its files. This is a unique value so that
    /// we have a fresh mongo each run.
    private let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(),
                              isDirectory: true).appendingPathComponent("realm-test-\(UUID().uuidString)")

    /// Whether or not this is a parent or child process.
    private let isParentProcess = (getenv("RLMProcessIsChild") == nil)

    /// The current admin session
    private let session: AdminSession

    /// Created appIds which should be cleaned up
    private let appIds = Locked([String]())

    /// Check if the BaaS files are present and we can run the server
    @objc public static func haveServer() -> Bool {
        let goDir = RealmServer.buildDir.appendingPathComponent("stitch")
        return FileManager.default.fileExists(atPath: goDir.path)
    }

    private init?(_: Void) {
        guard isParentProcess else { return nil }
        atexit {
            RealmServer.shared.tearDown()
        }

        do {
            mongoProcess = try Self.launchMongoProcess(at: tempDir)
            serverProcess = try Self.launchServerProcess(at: tempDir, logLevel: logLevel)
            session = try Admin().login()
            super.init()
            try makeUserAdmin()
        } catch {
            fatalError("Could not initiate admin session: \(error.localizedDescription)")
        }
    }

    private func tearDown() {
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
    }

    /// Launch the mongo server in the background.
    /// This process should run until the test suite is complete.
    private static func launchMongoProcess(at tempDir: URL) throws -> Process {
        try FileManager().createDirectory(at: tempDir,
                                          withIntermediateDirectories: false,
                                          attributes: nil)

        let mongoProcess = Process()
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
        return mongoProcess
    }

    private static func launchServerProcess(at tempDir: URL, logLevel: LogLevel) throws -> Process {
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

        let serverProcess = Process()
        serverProcess.environment = env
        // golang server needs a tmp directory

        try FileManager.default.createDirectory(atPath: "\(tempDir.path)/tmp",
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
                    guard logLevel == .info else {
                        return
                    }
                    parts.append("🔵")
                } else if part.contains("DEBUG") {
                    guard logLevel == .info || logLevel == .warn else {
                        return
                    }
                    parts.append("🟡")
                } else if part.contains("ERROR") {
                    parts.append("🔴")
                } else if let json = try? JSONSerialization.jsonObject(with: part.data(using: .utf8)!) {
                    try! parts.append(String(data: JSONSerialization.data(withJSONObject: json,
                                                                          options: .prettyPrinted),
                                             encoding: .utf8)!)
                } else if !part.isEmpty {
                    parts.append(String(part))
                }
            }
            print(parts.joined(separator: "\t"))
        }

        serverProcess.standardError = nil
        if logLevel != .none {
            serverProcess.standardOutput = pipe
        } else {
            serverProcess.standardOutput = nil
        }

        try serverProcess.run()
        waitForServerToStart()
        return serverProcess
    }

    private static func waitForServerToStart() {
        let group = DispatchGroup()
        group.enter()
        @Sendable func pingServer(_ tries: Int = 0) {
            let session = URLSession(configuration: URLSessionConfiguration.default,
                                     delegate: nil,
                                     delegateQueue: OperationQueue())
            session.dataTask(with: URL(string: "http://localhost:9090/api/admin/v3.0/groups/groupId/apps/appId")!) { (_, _, error) in
                if error != nil {
                    Thread.sleep(forTimeInterval: 0.1)
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

    private func makeUserAdmin() throws {
        let p = Process()
        p.launchPath = RealmServer.binDir.appendingPathComponent("mongo").path
        p.arguments = [
            "--quiet",
            "mongodb://localhost:26000/auth",
            "--eval", """
                // Sometimes the user seems to not exist immediately
                let id = null;
                for (let i = 0; i < 5; ++i) {
                    let user = db.users.findOne({"data.email" : "unique_user@domain.com"});
                    if (user) {
                        id = user._id;
                        break;
                    }
                }
                if (id === null) {
                    throw "could not find admin user";
                }

                let res = db.users.updateOne({"_id": id}, {
                    "$addToSet":
                        {"roles": {"$each": [{"roleName": "GLOBAL_STITCH_ADMIN"},
                                             {"roleName": "GLOBAL_BAAS_FEATURE_ADMIN"}]}}
                });
                if (res.modifiedCount != 1) {
                    throw "could not update admin user";
                }
            """
        ]
        try p.run()
        p.waitUntilExit()
    }

    public typealias AppId = String

    /// Create a new server app
    func createApp(syncMode: SyncMode, types: [ObjectBase.Type], persistent: Bool) throws -> AppId {
        let session = try XCTUnwrap(session)

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
                app.authProviders[provider["_id"] as! String].enable.put(on: group, failOnError)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }

        if case .none = syncMode {
            try group.throwingWait(timeout: .now() + 5.0)
            return clientAppId
        }

        app.secrets.post(on: group, [
            "name": "BackingDB_uri",
            "value": "mongodb://localhost:26000"
        ], failOnError)

        try group.throwingWait(timeout: .now() + 5.0)

        let appService: [String: Json] = [
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

        let schema = types.map { ObjectiveCSupport.convert(object: $0.sharedSchema()!) }

        let partitionKeyType: String?
        if case .pbs(let bsonType) = syncMode {
            partitionKeyType = bsonType
        } else {
            partitionKeyType = nil
        }

        // Creating the schema is a two-step process where we first add all the
        // objects with their properties to them so that we can add relationships
        let lockedSchemaIds = Locked([String: String]())
        for objectSchema in schema {
            app.schemas.post(on: group, objectSchema.stitchRule(partitionKeyType, appId: clientAppId)) {
                switch $0 {
                case .success(let data):
                    lockedSchemaIds.withLock {
                        $0[objectSchema.className] = ((data as! [String: Any])["_id"] as! String)
                    }
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }
        }
        try group.throwingWait(timeout: .now() + 5.0)

        let schemaIds = lockedSchemaIds.value
        for objectSchema in schema {
            let schemaId = schemaIds[objectSchema.className]!
            app.schemas[schemaId].put(on: group, data: objectSchema.stitchRule(partitionKeyType, id: schemaId, appId: clientAppId), failOnError)
        }
        try group.throwingWait(timeout: .now() + 5.0)

        let asymmetricTables = schema.compactMap {
            $0.isAsymmetric ? $0.className : nil
        }
        let serviceConfig: [String: Json]
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

            // We only need to create the userData rule for .pbs since for .flx we
            // have a default rule that covers all collections
            let userDataRule: [String: Json] = [
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
            _ = app.services[serviceId].rules.post(userDataRule)
        case .flx(let fields):
            serviceConfig = [
                "flexible_sync": [
                    "state": "enabled",
                    "database_name": "test_data",
                    "queryable_fields_names": fields as [Json],
                    "asymmetric_tables": asymmetricTables as [Json]
                ]
            ]
            _ = try app.services[serviceId].default_rule.post([
                "roles": [[
                    "name": "all",
                    "apply_when": [String: Json](),
                    "document_filters": [
                        "read": true,
                        "write": true
                    ],
                    "write": true,
                    "read": true,
                    "insert": true,
                    "delete": true
                ]]
            ]).get()
        default:
            fatalError()
        }
        _ = try app.services[serviceId].config.patch(serviceConfig).get()

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

        // Disable exponential backoff when the server isn't ready for us to connect
        // TODO: this is returning 403 with current server. Reenable once it's fixed - see https://mongodb.slack.com/archives/C0121N9LJ14/p1713885482349059
        // session.privateApps[appId].settings.patch(on: group, [
        //    "sync": ["disable_client_error_backoff": true]
        // ], failOnError)

        try group.throwingWait(timeout: .now() + 5.0)

        // Wait for initial sync to complete as connecting before that has a lot of problems
        try waitForSync(appServerId: appId, expectedCount: schema.count - asymmetricTables.count)

        if !persistent {
            appIds.withLock { $0.append(appId) }
        }

        return clientAppId
    }

    @objc public func createApp(fields: [String], types: [ObjectBase.Type], persistent: Bool = false) throws -> AppId {
        return try createApp(syncMode: .flx(fields), types: types, persistent: persistent)
    }

    @objc public func createApp(partitionKeyType: String = "string", types: [ObjectBase.Type], persistent: Bool = false) throws -> AppId {
        return try createApp(syncMode: .pbs(partitionKeyType), types: types, persistent: persistent)
    }

    @objc public func createNonSyncApp() throws -> AppId {
        return try createApp(syncMode: .none, types: [], persistent: false)
    }

    /// Delete all Apps created without `persistent: true`
    @objc func deleteApps() throws {
        for appId in appIds.value {
            let app = try XCTUnwrap(session).apps[appId]
            _ = try app.delete().get()
        }
        appIds.value = []
    }

    @objc func deleteApp(_ appId: String) throws {
        let serverAppId = try retrieveAppServerId(appId)
        let app = try XCTUnwrap(session).apps[serverAppId]
        _ = try app.delete().get()
    }

    // Retrieve Atlas App Services AppId with ClientAppId using the Admin API
    public func retrieveAppServerId(_ clientAppId: String) throws -> String {
        let session = try XCTUnwrap(session)
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
        let session = try XCTUnwrap(session)
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
        let app = session.apps[appServerId]
        do {
            return try app.services[syncServiceId].config.get().get() as? [String: Any]
        } catch {
            throw URLError(.unknown)
        }
    }

    public func isSyncEnabled(appServerId: String, syncServiceId: String) throws -> Bool {
        let session = try XCTUnwrap(session)
        let app = session.apps[appServerId]
        let response = try app.services[syncServiceId].config.get().get() as? [String: Any]
        guard let syncInfo = response?["flexible_sync"] as? [String: Any] else {
            return false
        }
        return syncInfo["state"] as? String == "enabled"
    }

    public func isDevModeEnabled(appServerId: String, syncServiceId: String) throws -> Bool {
        let app = session.apps[appServerId]
        let res = try app.sync.config.get().get() as! [String: Any]
        return res["development_mode_enabled"] as? Bool ?? false
    }

    public func enableDevMode(appServerId: String, syncServiceId: String, syncServiceConfiguration: [String: Any]) -> Result<Any?, Error> {
        let app = session.apps[appServerId]
        return app.sync.config.put(["development_mode_enabled": true])
    }

    public func disableSync(appServerId: String, syncServiceId: String) throws -> Any? {
        let app = session.apps[appServerId]
        return app.services[syncServiceId].config.patch(["flexible_sync": ["state": ""]])
    }

    public func enableSync(appServerId: String, syncServiceId: String, syncServiceConfiguration: [String: Any]) -> Result<Any?, Error> {
        var syncConfig = syncServiceConfiguration
        let app = session.apps[appServerId]
        guard var syncInfo = syncConfig["flexible_sync"] as? [String: Any] else {
            return .failure(URLError(.unknown))
        }
        syncInfo["state"] = "enabled"
        syncConfig["flexible_sync"] = syncInfo
        return app.services[syncServiceId].config.patch(syncConfig)
    }

    public func patchRecoveryMode(flexibleSync: Bool, disable: Bool, _ appServerId: String,
                                  _ syncServiceId: String, _ syncServiceConfiguration: [String: Any]) -> Result<Any?, Error> {
        let configOption = flexibleSync ? "flexible_sync" : "sync"
        let app = session.apps[appServerId]
        var syncConfig = syncServiceConfiguration
        return app.services[syncServiceId].config.get()
            .map { response in
                guard let config = response as? [String: Json] else { return false }
                guard let syncInfo = config[configOption] as? [String: Any] else { return false }
                return syncInfo["is_recovery_mode_disabled"] as? Bool ?? false
            }
            .flatMap { (isDisabled: Bool) in
                if isDisabled == disable {
                    return .success(syncConfig)
                }

                guard var syncInfo = syncConfig[configOption] as? [String: Any] else {
                    return .failure(URLError(.unknown))
                }

                syncInfo["is_recovery_mode_disabled"] = disable
                syncConfig[configOption] = syncInfo
                return app.services[syncServiceId].config.patch(syncConfig)
            }
    }

    public func retrieveUser(_ appId: String, userId: String) -> Result<Any?, Error> {
        guard let appServerId = try? RealmServer.shared.retrieveAppServerId(appId) else {
            return .failure(URLError(.unknown))
        }
        return session.apps[appServerId].users[userId].get()
    }

    // Remove User from Atlas App Services using the Admin API
    public func removeUserForApp(_ appId: String, userId: String) -> Result<Any?, Error> {
        guard let appServerId = try? RealmServer.shared.retrieveAppServerId(appId) else {
            return .failure(URLError(.unknown))
        }
        return session.apps[appServerId].users[userId].delete()
    }

    public func revokeUserSessions(_ appId: String, userId: String) -> Result<Any?, Error> {
        guard let appServerId = try? RealmServer.shared.retrieveAppServerId(appId) else {
            return .failure(URLError(.unknown))
        }
        return session.apps[appServerId].users[userId].logout.put([:])
    }

    public func retrieveSchemaProperties(_ appId: String, className: String,
                                         _ completion: @escaping (Result<[String], Error>) -> Void) {
        let appServerId = try! RealmServer.shared.retrieveAppServerId(appId)

        guard let schemasList = try? session.apps[appServerId].schemas.get().get(),
              let schemas = schemasList as? [[String: Any]],
              let schemaSelected = schemas.first(where: { ($0["metadata"] as? [String: String])?["collection"] == className }) else {
            completion(.failure(URLError(.unknown)))
            return
        }

        guard let schema = try? session.apps[appServerId].schemas[schemaSelected["_id"] as! String].get().get(),
              let schemaProperties = ((schema as? [String: Any])?["schema"] as? [String: Any])?["properties"] as? [String: Any] else {
            completion(.failure(URLError(.unknown)))
            return
        }

        completion(.success(schemaProperties.compactMap { $0.key }))
    }

    public func triggerClientReset(_ appId: String, _ realm: Realm) throws {
        let session = try XCTUnwrap(session)
        let appServerId = try retrieveAppServerId(appId)
        let ident = RLMGetClientFileIdent(ObjectiveCSupport.convert(object: realm))
        XCTAssertNotEqual(ident, 0)
        _ = try session.apps[appServerId].sync.forceReset.put(["file_ident": ident]).get()
    }

    public func waitForSync(appId: String) throws {
        try waitForSync(appServerId: retrieveAppServerId(appId), expectedCount: 1)
    }

    public func waitForSync(appServerId: String, expectedCount: Int) throws {
        let session = try XCTUnwrap(session)
        let start = Date()
        while true {
            let complete = try session.apps[appServerId].sync.progress.get()
                .map { resp in
                    guard let resp = resp as? Dictionary<String, Any?> else { return false }
                    guard let progress = resp["progress"] else { return false }
                    guard let progress = progress as? Dictionary<String, Any?> else { return false }
                    let values = progress.compactMapValues { $0 as? Dictionary<String, Any?> }
                    let complete = values.allSatisfy { $0.value["complete"] as? Bool ?? false }
                    return complete && progress.count >= expectedCount
                }
                .get()
            if complete {
                break
            }
            if -start.timeIntervalSinceNow > 60.0 {
                throw "Waiting for sync to complete timed out"
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
    }
}

@Sendable private func failOnError<T>(_ result: Result<T, Error>) {
    if case .failure(let error) = result {
        XCTFail(error.localizedDescription)
    }
}

extension String: Error {
}

#endif
