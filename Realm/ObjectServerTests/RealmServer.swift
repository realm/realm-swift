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

private extension URL {
    var fileURL: URL {
        URL(fileURLWithPath: self.absoluteString)
    }
}

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

struct Dependencies: Decodable {
    enum CodingKeys: String, CodingKey {
        case mongoDBVersion = "MONGODB_VERSION",
             goVersion = "GO_VERSION",
             nodeVersion = "NODE_VERSION",
             stitchVersion = "STITCH_VERSION"
    }
    var mongoDBVersion: String
    var goVersion: String
    var nodeVersion: String
    var stitchVersion: String
}


private let dependencies =
    try! JSONDecoder().decode(Dependencies.self,
                              from: JSONEncoder().encode(String(data: FileManager.default.contents(atPath: rootUrl.appendingPathComponent("dependencies.list").absoluteString)!, encoding: .utf8)!.components(separatedBy: "\n").dropLast().reduce(into: [String:String](), {
    let keyValuePair = $1.split(separator: "=")
    $0[String(keyValuePair[0])] = String(keyValuePair[1])
})))

/// The root URL of the project.
private let rootUrl = URL(string: #file)!
    .deletingLastPathComponent() // RealmServer.swift
    .deletingLastPathComponent() // ObjectServerTests
    .deletingLastPathComponent() // Realm
private let buildDir = rootUrl.appendingPathComponent(".build")
private let binDir = buildDir.appendingPathComponent("bin")
/// The directory where mongo stores its files. This is a unique value so that
/// we have a fresh mongo each run.
private var tempDir = URL(fileURLWithPath: NSTemporaryDirectory(),
                          isDirectory: true).appendingPathComponent("realm-test-\(UUID().uuidString)")

// MARK: Builder
@available(OSX 10.13, *)
class Builder {
    static let mongoDBURL = URL(string: "https://fastdl.mongodb.org/osx/mongodb-macos-x86_64-\(dependencies.mongoDBVersion).tgz")!
    static let transpilerTarget = "node10-macos"
    static let stitchSupportLibURL = "https://s3.amazonaws.com/stitch-artifacts/stitch-support/stitch-support-macos-debug-4.3.2-721-ge791a2e-patch-5e2a6ad2a4cf473ae2e67b09.tgz"
    static let mongoDir = buildDir.appendingPathComponent("mongodb-macos-x86_64-\(dependencies.mongoDBVersion)")
    static let mongoExe = binDir.appendingPathComponent("mongo")
    static let mongodExe = binDir.appendingPathComponent("mongod")
    static let libDir = buildDir.appendingPathComponent("lib")

    private var path = ["/bin", "/usr/bin"]
    private var _environment = [String: String]()
    private var environment: [String: String] {
        ["PATH": path.joined(separator: ":")].merging(_environment, uniquingKeysWith: { key1, key2 in key1 })
    }

    @discardableResult
    func puts(_ commandString: String,
              currentDirectoryPath: String? = nil) -> (Int32, String) {
        func createProcesses(_ commandString: String,
                             process: inout Process,
                             processes: inout [Process]) {
            process.currentDirectoryPath = currentDirectoryPath ?? buildDir.absoluteString
            processes.append(process)
            var commandAndFlags = commandString.split(separator: " ")
            process.launchPath = String(commandAndFlags.first!)
            commandAndFlags.removeFirst()
            var args = [String]()
            while commandAndFlags.count > 0 {
                var argument = commandAndFlags.removeFirst()
                if argument.starts(with: "\"") {
                    var nextArg = commandAndFlags.removeFirst()
                    while nextArg.last != "\"" {
                        argument += " \(nextArg)"
                        nextArg = commandAndFlags.removeFirst()
                    }
                    argument += " \(nextArg)"
                }
                if argument.starts(with: "\'") {
                    var nextArg = commandAndFlags.removeFirst()
                    while nextArg.last != "\'" {
                        argument += " \(nextArg)"
                        nextArg = commandAndFlags.removeFirst()
                    }
                    argument += " \(nextArg)"
                }
                if argument != "|" {
                    args.append(String(argument))
                } else {
                    let pipe = Pipe()
                    let outputPipe = Pipe()
                    var tailProcess = Process()
                    createProcesses(commandAndFlags.joined(separator: " "),
                                    process: &tailProcess,
                                    processes: &processes)
                    tailProcess.standardInput = pipe
                    tailProcess.standardOutput = outputPipe
                    process.standardOutput = pipe
                    break
                }
            }
            process.arguments = args
        }
        var processes = [Process]()
        var process = Process()
        process.environment = environment
        createProcesses(commandString, process: &process, processes: &processes)

        processes.forEach {
            $0.launch()
        }
        processes.forEach {
            $0.waitUntilExit()
        }
        if let _ = (processes.last!.standardOutput as? Pipe)?.fileHandleForReading.readDataToEndOfFile() {

        }
        let data = (processes.last!.standardOutput as? Pipe)?.fileHandleForReading.readDataToEndOfFile() ?? Data()
        return (processes.last!.terminationStatus, String(data: data,
                                                          encoding: .utf8)!)
    }

    let fileManager = FileManager.default

    private func setupMongod(server: RealmServer) throws {
        if !fileManager.fileExists(atPath: binDir.appendingPathComponent("mongo").absoluteString) {

            puts("/usr/bin/curl --silent \(Builder.mongoDBURL.absoluteString) | /usr/bin/tar xz")
            puts("/bin/mkdir \(binDir.absoluteString)")
            puts("/bin/cp \(Builder.mongoDir.absoluteString)/bin/mongo \(binDir)/mongo")
            puts("/bin/cp \(Builder.mongoDir.absoluteString)/bin/mongod \(binDir)/mongod")

            let mongoProcess = Process()
            mongoProcess.launchPath = binDir.appendingPathComponent("mongod").path
            mongoProcess.arguments = [
                "--quiet",
                "--dbpath", tempDir.path,
                "--bind_ip", "localhost",
                "--port", "26000",
                "--replSet", "test"
            ]
            mongoProcess.standardOutput = nil
            try mongoProcess.run()

            assert(puts("\(binDir)/mongo --port=26000 --eval=\"rs.initiate()\"").0 == 0)
            assert(puts("""
                        \(binDir)/mongo --port 26000 --eval 'use admin; db.createUser({user: "test", pwd: "test", roles: [{role: "userAdminAnyDatabase", db: "admin"}]})'
                        """).0 == 0)

            let shutdownProcess = server.mongoShutdownProcess()
            shutdownProcess.launch()
            shutdownProcess.waitUntilExit()
            mongoProcess.terminate()
        }
    }

    private func setupStitch() throws {
        print("Setting up stitch")
        let goRoot = buildDir.appendingPathComponent("go")

        try! fileManager.createDirectory(at: Builder.libDir.fileURL, withIntermediateDirectories: true)
        if !fileManager.fileExists(atPath: "\(goRoot.absoluteString)/bin/go") {
            print("Downloading golang")
            puts("/usr/bin/curl --silent https://dl.google.com/go/go\(dependencies.goVersion).darwin-amd64.tar.gz | /usr/bin/tar xz")
            puts("/bin/mkdir -p \(goRoot.absoluteString)/src/github.com/10gen")
        }

        var stitchDir = buildDir.appendingPathComponent("stitch")
        if !fileManager.fileExists(atPath: stitchDir.absoluteString) {
            print("Cloning stitch")
            puts("/usr/bin/git clone git@github.com:10gen/baas \(stitchDir.absoluteString)")
        }

        let stitchWorktree = goRoot
            .appendingPathComponent("src")
            .appendingPathComponent("github.com")
            .appendingPathComponent("10gen")
            .appendingPathComponent("stitch")


        if !FileManager.default.fileExists(atPath: stitchDir.appendingPathComponent(".git").absoluteString) {


            // Fetch the BaaS version if we don't have it
            puts("/usr/bin/git -C \(stitchDir) show-ref --verify --quiet")

            // Set the worktree to the correct version
            if !fileManager.fileExists(atPath: stitchWorktree.absoluteString) {
                puts("/usr/bin/git -C \(stitchWorktree) checkout \(dependencies.stitchVersion)")
            } else {
                puts("/usr/bin/git -C \(stitchDir) worktree add \(dependencies.stitchVersion)")
            }
        } else {
            // We have a stitch directory with no .get directory, meaning we're
            // running on CI and just need to copy the files into place
            if !fileManager.fileExists(atPath: stitchWorktree.absoluteString) {
                puts("/bin/cp -Rc \(stitchDir) \(stitchWorktree)")
            }
        }
        puts("/bin/mkdir -p go/src/github.com/10gen/stitch/etc/dylib")
        stitchDir = stitchWorktree
        if !fileManager.fileExists(atPath: Builder.libDir.appendingPathComponent("libstitch_support.dylib").absoluteString) {
            print("downloading mongodb dylibs")
            puts("/usr/bin/curl -s \(Builder.stitchSupportLibURL) | /usr/bin/tar xvfz - --strip-components=1 -C go/src/github.com/10gen/stitch/etc/dylib")
            puts("/bin/cp go/src/github.com/10gen/stitch/etc/dylib/lib/libstitch_support.dylib lib")
        }

        let updateDocFilepath = binDir.appendingPathComponent("update_doc")
        if !fileManager.fileExists(atPath: updateDocFilepath.absoluteString) {
            print("downloading update_doc")
            puts("/usr/bin/curl --silent -O https://s3.amazonaws.com/stitch-artifacts/stitch-mongo-libs/stitch_mongo_libs_osx_patch_cbcbfd8ebefcca439ff2e4d99b022aedb0d61041_59e2b7a5c9ec4432c400181c_17_10_15_01_19_33/update_doc")
            puts("/bin/mv update_doc bin/update_doc")
            puts("/bin/chmod +x \(updateDocFilepath)")
        }

        let assistedAggFilepath = binDir.appendingPathComponent("assisted_agg")
        if !fileManager.fileExists(atPath: assistedAggFilepath.absoluteString) {
            print("downloading assisted_agg")
            puts("/usr/bin/curl --silent -O https://s3.amazonaws.com/stitch-artifacts/stitch-mongo-libs/stitch_mongo_libs_osx_patch_b1c679a26ecb975372de41238ea44e4719b8fbf0_5f3d91c10ae6066889184912_20_08_19_20_57_17/assisted_agg")
            puts("/bin/mv assisted_agg bin/assisted_agg")
            puts("/bin/chmod +x \(assistedAggFilepath)")
        }

        if !fileManager.fileExists(atPath: buildDir.appendingPathComponent("node-v\(dependencies.nodeVersion)-darwin-x64").absoluteString) {
            print("downloading node 🚀")
            puts("/usr/bin/curl -O https://nodejs.org/dist/v\(dependencies.nodeVersion)/node-v\(dependencies.nodeVersion)-darwin-x64.tar.gz")
            puts("/usr/bin/tar xzf node-v\(dependencies.nodeVersion)-darwin-x64.tar.gz")
        }
        path.append( "\(buildDir)/node-v\(dependencies.nodeVersion)-darwin-x64/bin/")

        if !fileManager.fileExists(atPath: "\(fileManager.homeDirectoryForCurrentUser.path)/.yarn/bin/yarn") {
            puts("/bin/rm -rf ~/.yarn")
            puts("/usr/bin/curl -o- -L https://yarnpkg.com/install.sh | /bin/bash")
        }
        path.append("\(fileManager.homeDirectoryForCurrentUser.path)/.yarn/bin:~/.config/yarn/global/node_modules/.bin")

        if !fileManager.fileExists(atPath: binDir.appendingPathComponent("transpiler").absoluteString) {
            print("building transpiler")
            puts("\(fileManager.homeDirectoryForCurrentUser.path)/.yarn/bin/yarn install",
                 currentDirectoryPath: stitchDir.appendingPathComponent("etc").appendingPathComponent("transpiler").absoluteString)
            puts("\(fileManager.homeDirectoryForCurrentUser.path)/.yarn/bin/yarn run build",
                 currentDirectoryPath: stitchDir.appendingPathComponent("etc").appendingPathComponent("transpiler").absoluteString)
            puts("/bin/cp -c bin/transpiler \(buildDir)/bin", currentDirectoryPath: stitchDir.appendingPathComponent("etc").appendingPathComponent("transpiler").absoluteString)
        }

        _environment["GOROOT"] = goRoot.absoluteString
        _environment["GOCACHE"] = goRoot.appendingPathComponent("cache").absoluteString
        _environment["GOPATH"] = goRoot.appendingPathComponent("bin").absoluteString
        _environment["STITCH_PATH"] = stitchDir.absoluteString
        _environment["LD_LIBRARY_PATH"] = Builder.libDir.absoluteString
        path.append(stitchDir.appendingPathComponent("etc").appendingPathComponent("transpiler").appendingPathComponent("bin").absoluteString)

        if !fileManager.fileExists(atPath: binDir.appendingPathComponent("create_user").absoluteString) {
            print("build create_user binary")

            puts("\(goRoot)/bin/go build -o create_user cmd/auth/user.go", currentDirectoryPath: stitchDir.absoluteString)
            puts("/bin/cp -c create_user \(binDir)", currentDirectoryPath: stitchDir.absoluteString)

            print("create_user binary built")
        }

        if !fileManager.fileExists(atPath: binDir.appendingPathComponent("stitch_server").absoluteString) {
            print("building server binary")

            puts("\(goRoot)/bin/go build -o stitch_server cmd/server/main.go", currentDirectoryPath: stitchDir.absoluteString)
            puts("/bin/cp -c stitch_server \(binDir)", currentDirectoryPath: stitchDir.absoluteString)

            print("server binary built")
        }
    }

    func buildServer(server: RealmServer) throws {
        try! fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        if !fileManager.fileExists(atPath: buildDir.absoluteString) {
            try! FileManager.default.createDirectory(at: URL.init(fileURLWithPath: buildDir.absoluteString, isDirectory: true), withIntermediateDirectories: true)
        }
        try setupMongod(server: server)

        try setupStitch()
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

            func patch(on group: DispatchGroup, _ data: Any, _ completionHandler: @escaping (Result<Any?, Error>) -> Void) {
                request(on: group, httpMethod: "PATCH", data: data, completionHandler)
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
    public var logLevel = LogLevel.info

    /// Process that runs the local mongo server. Should be terminated on exit.
    private let mongoProcess = Process()
    /// Process that runs the local backend server. Should be terminated on exit.
    private let serverProcess = Process()

    /// Whether or not this is a parent or child process.
    private lazy var isParentProcess = (getenv("RLMProcessIsChild") == nil)

    /// The current admin session
    private var session: Admin.AdminSession?

    /// Check if the BaaS files are present and we can run the server
    @objc public class func haveServer() -> Bool {
        _ = buildDir
            .appendingPathComponent("stitch")
//        return FileManager.default.fileExists(atPath: goDir.path)
        return true
    }

    private override init() {
        super.init()

        if isParentProcess {
            atexit {
                _ = RealmServer.shared.tearDown
            }

            do {
                let builder = Builder()
                try! builder.buildServer(server: self)
                try launchMongoProcess()
                try launchServerProcess()
                self.session = try Admin().login()
            } catch {
                XCTFail("Could not initiate admin session: \(error.localizedDescription)")
            }
        }
    }

    fileprivate func mongoShutdownProcess() -> Process {
        let mongo = binDir.appendingPathComponent("mongo").path
        // step down the replica set
        let mongoShutdownProcess = Process()
        mongoShutdownProcess.launchPath = mongo
        mongoShutdownProcess.arguments = [
            "admin",
            "--port", "26000",
            "--eval", "'db.shutdownServer({force: true})'"]
        return mongoShutdownProcess
    }
    /// Lazy teardown for exit only.
    private lazy var tearDown: () = {
        serverProcess.terminate()

        let mongo = binDir.appendingPathComponent("mongo").path

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
        let mongoShutdownProcess = self.mongoShutdownProcess()
        try? mongoShutdownProcess.run()
        mongoShutdownProcess.waitUntilExit()

        mongoProcess.terminate()

        try? FileManager().removeItem(at: tempDir)
    }()

    /// Launch the mongo server in the background.
    /// This process should run until the test suite is complete.
    fileprivate func launchMongoProcess() throws {
        mongoProcess.launchPath = binDir.appendingPathComponent("mongod").path
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
        initProcess.launchPath = binDir.appendingPathComponent("mongo").path
        initProcess.arguments = [
            "--port", "26000",
            "--eval", "rs.initiate()"
        ]
        initProcess.standardOutput = nil
        try initProcess.run()
        initProcess.waitUntilExit()
    }

    private func launchServerProcess() throws {
        let binDir = buildDir.appendingPathComponent("bin").path
        let libDir = buildDir.appendingPathComponent("lib").path
        let binPath = "$PATH:\(binDir)"

        let stitchRoot = buildDir.path + "/go/src/github.com/10gen/stitch"

        // create the admin user
        let userProcess = Process()
        userProcess.environment = [
            "PATH": binPath,
            "LD_LIBRARY_PATH": libDir
        ]
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

        serverProcess.environment = [
            "PATH": binPath,
            "LD_LIBRARY_PATH": libDir
        ]
        // golang server needs a tmp directory
        try! FileManager.default.createDirectory(atPath: "\(tempDir.path)/tmp",
            withIntermediateDirectories: false, attributes: nil)
        serverProcess.launchPath = "\(binDir)/stitch_server"
        serverProcess.currentDirectoryPath = tempDir.path
        serverProcess.arguments = [
            "--configFile",
            "\(stitchRoot)/etc/configs/test_config.json"
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

    public typealias AppId = String

    private func failOnError<T>(_ result: Result<T, Error>) {
        if case .failure(let error) = result {
            XCTFail(error.localizedDescription)
        }
    }

    /// Create a new server app
    @objc public func createApp() throws -> AppId {
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

        let serviceResponse = app.services.post([
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
                        "required": false,
                        "permissions": [
                            "read": true,
                            "write": true
                        ]
                    ]
                ]
            ]
        ])

        guard let serviceId = (try serviceResponse.get() as? [String: Any])?["_id"] as? String else {
            throw URLError(.badServerResponse)
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

        let swiftHugeSyncObjectRule: [String: Any] = [
            "database": "test_data",
            "collection": "SwiftHugeSyncObject",
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
                    "data": [
                        "bsonType": "binData"
                    ],
                    "realm_id": [
                        "bsonType": "string"
                    ]
                ],
                "required": ["_id"],
                "title": "SwiftHugeSyncObject"
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
        rules.post(on: group, dogRule, failOnError)
        rules.post(on: group, personRule, failOnError)
        rules.post(on: group, hugeSyncObjectRule, failOnError)
        rules.post(on: group, swiftHugeSyncObjectRule, failOnError)
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
        ], failOnError)

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
}
