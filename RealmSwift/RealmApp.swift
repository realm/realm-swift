////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
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
import Realm
import Realm.Private

public final class RealmMDBService {

}

public final class RealmServices {
    private let appId: String

    public lazy var mongoDb = RealmMDBService()

    fileprivate init(appId: String) {
        self.appId = appId
    }
}

@dynamicMemberLookup
public final class RealmFunctions {
    private let appId: String

    fileprivate init(appId: String) {
        self.appId = appId
    }

    public typealias FunctionSignature<T: Decodable> = ([Any], T.Type, (@escaping (Result<T, Error>) -> Void)) -> Void

    public subscript<T>(dynamicMember string: String) -> FunctionSignature<T> {
        return { (args, type, completionHandler) in
            let url = URL.init(string: String.init(format: RealmApp.defaultBaseURL + RealmApp.appRoute,
                                                   self.appId))
            SyncUser.__callFunction(
                string,
                arguments: args,
                timeout: 30,
                authServerURL: url!,
                callbackQueue: DispatchQueue.main) { data, error in
                    guard let data = data else {
                        completionHandler(.failure(error ?? NSError()))
                        return
                    }

                    do {
                        completionHandler(.success(try JSONDecoder().decode(T.self, from: data)))
                    } catch let error {
                        completionHandler(.failure(error))
                    }
            }
        }
    }
}

public final class RealmAuth {
    private let appId: String

    public var currentUser: SyncUser? {
        SyncUser.current
    }

    public var allUsers: [String: SyncUser] {
        SyncUser.all
    }

    fileprivate init(appId: String) {
        self.appId = appId
    }

    public func logIn(with credentials: SyncCredentials,
                      timeout: TimeInterval = 30,
                      callbackQueue queue: DispatchQueue = DispatchQueue.main,
                      onCompletion completion: @escaping UserCompletionBlock) {
        let url = URL.init(
            string: String.init(format: RealmApp.defaultBaseURL + RealmApp.authProviderRoute,
                                self.appId, credentials.provider.rawValue))

        return SyncUser.__logIn(
            with: RLMSyncCredentials(credentials),
            authServerURL: url!,
            timeout: timeout,
            callbackQueue: queue,
            onCompletion: completion)
    }

    public func switchUser(id: String) {

    }
}

public final class RealmApp {
    public struct Configuration {
        let baseURL: String

        public static let defaultConfiguration: Configuration = {
            Configuration(baseURL: "https://stitch.mongodb.com")
        }()
    }

    static let defaultBaseURL = "https://stitch.mongodb.com"
    static let baseRoute = "/api/client/v2.0"
    static let appRoute = baseRoute + "/app/%@"
    static let appMetadataRoute = appRoute + "/location"
    static let functionCallRoute = appRoute + "/functions/call"
    static let baseAuthRoute = baseRoute + "/auth"
    static let baseAppAuthRoute = appRoute + "/auth"

    static let sessionRoute = baseAuthRoute + "/session"
    static let profileRoute = baseAuthRoute + "/profile"
    static let authProviderRoute = baseAppAuthRoute + "/providers/%@"
    static let authProviderLoginRoute = authProviderRoute + "/login"
    static let authProviderLinkRoute = authProviderLoginRoute + "?link=true"

    internal let appId: String

    public lazy var auth      = RealmAuth(appId: appId)
    public lazy var functions = RealmFunctions(appId: appId)

    public init(appId: String, configuration: RealmApp.Configuration = .defaultConfiguration) {
        self.appId = appId
    }

    /**
     Configure the default application.

     - parameter appId: id of the application
     - parameter configuration: the configuration to use for the default
     */
    public func configuration() -> Realm.Configuration {
        var url = FileManager.default.urls(for: .documentDirectory,
                                           in: .userDomainMask).first!
        url.appendPathComponent(appId)
        return Realm.Configuration(fileURL: url)
    }



    public class func app(appId: String) -> RealmApp {
        return RealmApp(appId: appId)
    }
}
