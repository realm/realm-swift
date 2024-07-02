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

#if canImport(RealmSwiftTestSupport)
import RealmSwiftTestSupport
import RealmSyncTestSupport
#endif

public class BaasClient {
    private let appId: String = "baas-container-service-autzb"
    private let apiKey: String
    private var session: BaasSession?

    public init(apiKey: String) {
        self.apiKey = apiKey
        session = BaasSession(apiKey: apiKey)
    }

    public func getOrDeployContainer(differentiator: String? = nil) -> Result<(String, String), Error>  {
        if let existingContainer = try? getContainers().get()?.first {
            print("Using existing BaaS container at \(existingContainer["httpUrl"] as! String)")
            return .success((existingContainer["id"] as! String, existingContainer["httpUrl"] as! String))
        }

        print("Deploying new BaaS container ...")
        let data = [[
            "key": "DIFFERENTIATOR",
            "value": "local"
        ]]
        let newContainer = try? session?.base.app[dynamicMember: appId].endpoint.startContainer.post(data).get() as? [String: String]
        let id = newContainer!["id"]!
        var httpUrl: String? = nil
        while httpUrl == nil {
            sleep(1)
            httpUrl = try? waitForContainer(id: id).get()
        }

        print("Deployed BaaS instance at \(httpUrl!)")
        return .success((id, httpUrl!))
    }

    public func deleteContainer(id: String, differentiator: String? = nil) -> Result<Void, Error>  {
        print("Stopping all containers with differentiator \(differentiator ?? "")")
        let containers = try? getContainers(differentiator: differentiator).get()
        if let containers = containers {
            for container in containers {
                print("Stopping container \(container["id"] as! String)")
                _ = try? session?.base.app[dynamicMember: appId].endpoint.stopContainer.post(nil).get()
                print("Stopped container \(container["id"] as! String)")
            }
        }
        return .success(())
    }

    private func getUserId() -> Result<String, Error>  {
        let userInfo = try? session?.base.app[dynamicMember: appId].endpoint.userinfo.get().get() as? [String: String]
        return .success(userInfo!["id"]!)
    }

    private func getContainers(differentiator: String? = nil) -> Result< [[String : Any]]?, Error> {
        let containers = try? session?.base.app[dynamicMember: appId].endpoint.listContainers.get().get() as? [[String : Any]]
        guard let containers = containers,
              containers.count > 0 else {
            return .success(nil)
        }

        if let differentiator = differentiator {
            let userId = try? getUserId().get()
            let filteredContainers = containers.filter { $0["creatorId"] as? String == userId && ($0["tags"] as! [String: Any])["DIFFERENTIATOR"] as! String == differentiator }
            return .success(filteredContainers)
        }

        return .success(containers)
    }

    private func waitForContainer(id: String) -> Result<String?, Error>  {
        let containers = try? getContainers().get()
        let fileteredContainer = containers?.filter { $0["id"] as! String == id }.first
        guard let fileteredContainer = fileteredContainer else {
            print("Container \(id) is not created")
            return .success(nil)
        }

        guard fileteredContainer["isRunning"] as! Bool else {
            print("\(id) status is \(fileteredContainer["lastStatus"] ?? ""). Retrying...'")
            return .success(nil)
        }

        let httpUrl = fileteredContainer["httpUrl"] as! String
        var newSession = BaasSession(baseUrl: "\(httpUrl)/api/private/v1.0/version", apiKey: apiKey)
        do {
            _ = try newSession.base.get().get()
            return .success(httpUrl)
        } catch {
            print("Calling the container with \(id) is failing. Retrying...")
            return .success(nil)
        }
    }
}

public struct BaasSession {
    private let baseUrl: String
    private let apiKey: String

    internal init(baseUrl: String = "https://us-east-1.aws.data.mongodb-api.com", apiKey: String) {
        self.baseUrl = baseUrl
        self.apiKey = apiKey
    }

    /// The initial endpoint to access the baasas API
    lazy var base = BaasEndpoint(url: URL(string: baseUrl)!, apiKey: apiKey)

    @dynamicMemberLookup
    struct BaasEndpoint {
        var url: URL
        var apiKey: String

        subscript(dynamicMember member: String) -> BaasEndpoint {
            return BaasEndpoint(url: url.appendingPathComponent(member),
                                apiKey: apiKey)
        }

        typealias Completion = @Sendable (Result<Any?, Error>) -> Void

        private func request(httpMethod: String, 
                             data: Any? = nil,
                             query: [String: Any]? = nil,
                             completionHandler: @escaping Completion) {
            var components = URLComponents(url: self.url, resolvingAgainstBaseURL: false)!
            if let query = query {
                components.query = query.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            }

            var request = URLRequest(url: components.url!)
            request.httpMethod = httpMethod
            request.allHTTPHeaderFields = [
                "apiKey": "\(apiKey)",
            ]

            if let data = data {
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: data, options: .fragmentsAllowed)
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

        private func request(httpMethod: String, data: Any? = nil, query: [String: Any]? = nil) -> Result<Any?, Error> {
            let group = DispatchGroup()
            let result = Locked(Result<Any?, Error>?.none)
            group.enter()
            request(httpMethod: httpMethod, data: data, query: query) {
                result.value = $0
                group.leave()
            }
            guard case .success = group.wait(timeout: .now() + 60) else {
                print("HTTP request timed out: \(httpMethod) \(self.url)")
                return .failure(URLError(.timedOut))
            }
            return result.value!
        }

        func get() -> Result<Any?, Error> {
            let result = request(httpMethod: "GET")
            return result
        }

        func post(_ data: Any?, _ query: [String: String]? = nil) -> Result<Any?, Error> {
            request(httpMethod: "POST", data: data, query: query)
        }
    }
}
