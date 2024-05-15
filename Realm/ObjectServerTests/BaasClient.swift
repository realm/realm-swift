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

public class BaasClient {
    private let appId: String = "baas-container-service-autzb"
    private var session: BaasSession = BaasSession()

    private let apiKey: String
    public init(apiKey: String) {
        self.apiKey = apiKey

    public func getOrDeployContainer(apiKey: String) {
        let session = try XCTUnwrap(session)
        let existing = session.app[appId].listuContainers
    }

//    var result = (await helper.callEndpoint('listContainers', isPost: false) as List<dynamic>)
//            .map((e) => _ContainerInfo.fromJson(e as Map<String, dynamic>))
//            .whereNotNull();
//        if (differentiator != null) {
//          final userId = await helper.getUserId();
//          result = result.where((c) => c.creatorId == userId && c.tags['DIFFERENTIATOR'] == differentiator);
//        }
//
//        return result.toList();
    private func getContainer() {

    }
}

public class BaasSession {
    private let location = "https://us-east-1.aws.data.mongodb-api.com"

    private let apiKey: String

    internal init(apiKey: String) {
        self.appKey = apiKey
    }

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
                             url: location.appendingPathComponent(snakeCaseMember!))
    }

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
