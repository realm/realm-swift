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

import SwiftUI
import RealmSwift
import Combine

enum LoggingViewState {
    case initial
    case loggingIn
    case loggedIn
    case syncing
}

struct MainView: View {
    let testType: String = ProcessInfo.processInfo.environment["async_view_type"]!
    let partitionValue: String? = ProcessInfo.processInfo.environment["partition_value"]

    @State var viewState: LoggingViewState = .initial
    @State var user: User?

    var body: some View {
        VStack {
            LoginView(didLogin: { user in
                viewState = .loggedIn
                self.user = user
            }, loggingIn: {
                viewState = .loggingIn
            })
            switch viewState {
            case .initial:
                VStack {
                    Text("Waiting For Login")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.purple)
                .transition(AnyTransition.move(edge: .trailing)).animation(.default)
            case .loggingIn:
                VStack {
                    ProgressView("Logging in...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.blue)
                .transition(AnyTransition.move(edge: .leading)).animation(.default)
            case .loggedIn:
                VStack {
                    Text("Logged in")
                        .accessibilityIdentifier("logged_view")
                    Button("Sync") {
                        viewState = .syncing
                    }
                    .accessibilityIdentifier("sync_button")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.yellow)
                .transition(AnyTransition.move(edge: .trailing)).animation(.default)
            case .syncing:
                switch testType {
                case "async_open":
                    AsyncOpenView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.green)
                        .transition(AnyTransition.move(edge: .leading)).animation(.default)
                case "async_open_environment_partition":
                    AsyncOpenPartitionView()
                        .environment(\.partitionValue, partitionValue ?? user!.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.green)
                        .transition(AnyTransition.move(edge: .leading)).animation(.default)
                case "async_open_environment_configuration":
                    AsyncOpenPartitionView()
                        .environment(\.realmConfiguration, user!.configuration(partitionValue: user!.id))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.green)
                        .transition(AnyTransition.move(edge: .leading)).animation(.default)
                case "async_open_flexible_sync":
                    AsyncOpenFlexibleSyncView()
                        .environment(\.realmConfiguration, user!.flexibleSyncConfiguration())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.green)
                        .transition(AnyTransition.move(edge: .leading)).animation(.default)
                case "auto_open":
                    AutoOpenView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.green)
                        .transition(AnyTransition.move(edge: .leading)).animation(.default)
                case "auto_open_environment_partition":
                    AutoOpenPartitionView()
                        .environment(\.partitionValue, user!.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.green)
                        .transition(AnyTransition.move(edge: .leading)).animation(.default)
                case "auto_open_environment_configuration":
                    AutoOpenPartitionView()
                        .environment(\.realmConfiguration, user!.configuration(partitionValue: user!.id))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.green)
                        .transition(AnyTransition.move(edge: .leading)).animation(.default)
                case "auto_open_flexible_sync":
                    AutoOpenFlexibleSyncView()
                        .environment(\.realmConfiguration, user!.flexibleSyncConfiguration())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.green)
                        .transition(AnyTransition.move(edge: .leading)).animation(.default)
                default:
                    EmptyView()
                }
            }
        }
    }
}

struct LoginView: View {
    @ObservedObject var loginHelper = LoginHelper()
    var didLogin: (User) -> Void
    var loggingIn: () -> Void

    var body: some View {
        VStack {
            Button("Log In User 1") {
                loggingIn()
                loginHelper.login(email: ProcessInfo.processInfo.environment["email1"]!,
                                  password: "password",
                                  completion: { user in
                    didLogin(user)
                })
            }
            .accessibilityIdentifier("login_button_1")
            Button("Log In User 2") {
                loggingIn()
                loginHelper.login(email: ProcessInfo.processInfo.environment["email2"]!,
                                  password: "password",
                                  completion: { user in
                    didLogin(user)
                })
            }
            .accessibilityIdentifier("login_button_2")
            Button("Logout") {
                loginHelper.logout()
            }
            .accessibilityIdentifier("logout_button")
            Button("Logout All Users") {
                loginHelper.logoutAllUsers()
            }
            .accessibilityIdentifier("logout_users_button")
        }
    }
}

class LoginHelper: ObservableObject {
    var cancellables = Set<AnyCancellable>()

    private let appConfig = AppConfiguration(baseURL: "http://localhost:9090",
                                             transport: nil,
                                             localAppName: nil,
                                             localAppVersion: nil)
    private var clientDataRoot: URL {
        let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return applicationSupportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier!)
    }

    func login(email: String, password: String, completion: @escaping (User) -> Void) {
        let app = RealmSwift.App(id: ProcessInfo.processInfo.environment["app_id"]!, configuration: appConfig, rootDirectory: clientDataRoot)
        app.login(credentials: .emailPassword(email: email, password: password))
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    print("Login user error \(error)")
                }
            }, receiveValue: { user in
                completion(user)
            })
            .store(in: &cancellables)
    }

    func logout() {
        let app = RealmSwift.App(id: ProcessInfo.processInfo.environment["app_id"]!, configuration: appConfig, rootDirectory: clientDataRoot)
        app.currentUser?.logOut { _ in }
    }

    func logoutAllUsers() {
        let app = RealmSwift.App(id: ProcessInfo.processInfo.environment["app_id"]!, configuration: appConfig, rootDirectory: clientDataRoot)
        for (_, user) in app.allUsers {
            user.logOut { _ in }
        }
    }
}

struct AsyncOpenView: View {
    @State var canNavigate: Bool = false
    @State var progress: Progress?
    @AsyncOpen(appId: ProcessInfo.processInfo.environment["app_id"]!,
               partitionValue: ProcessInfo.processInfo.environment["partition_value"]!,
               timeout: 2000)
    var asyncOpen

    var body: some View {
        VStack {
            switch asyncOpen {
            case .connecting:
                ProgressView()
            case .waitingForUser:
                ProgressView("Waiting for user to logged in...")
            case .open(let realm):
                if canNavigate {
                    ListView()
                        .environment(\.realm, realm)
                        .transition(AnyTransition.move(edge: .leading)).animation(.default)
                } else {
                    VStack {
                        Text(String(progress!.completedUnitCount))
                            .accessibilityIdentifier("progress_text_view")
                        Button("Navigate Next View") {
                            canNavigate = true
                        }
                        .accessibilityIdentifier("show_list_button_view")
                    }
                }
            case .error(let error):
                ErrorView(error: error)
                    .background(Color.red)
                    .transition(AnyTransition.move(edge: .trailing)).animation(.default)
            case .progress(let progress):
                ProgressView(progress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.yellow)
                    .transition(AnyTransition.move(edge: .trailing)).animation(.default)
                    .onAppear {
                        self.progress = progress
                    }
            }
        }
    }
}

struct AutoOpenView: View {
    @State var canNavigate: Bool = false
    @State var progress: Progress?
    @AutoOpen(appId: ProcessInfo.processInfo.environment["app_id"]!,
              partitionValue: ProcessInfo.processInfo.environment["partition_value"]!,
              timeout: 2000)
    var autoOpen

    var body: some View {
        VStack {
            switch autoOpen {
            case .connecting:
                ProgressView()
            case .waitingForUser:
                ProgressView("Waiting for user to log in...")
            case .open(let realm):
                if canNavigate {
                    ListView()
                        .environment(\.realm, realm)
                        .transition(AnyTransition.move(edge: .leading)).animation(.default)
                } else {
                    VStack {
                        Text(String(progress!.completedUnitCount))
                            .accessibilityIdentifier("progress_text_view")
                        Button("Navigate Next View") {
                            canNavigate = true
                        }
                        .accessibilityIdentifier("show_list_button_view")
                    }
                }
            case .error(let error):
                ErrorView(error: error)
                    .background(Color.red)
                    .transition(AnyTransition.move(edge: .trailing)).animation(.default)
            case .progress(let progress):
                ProgressView(progress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.yellow)
                    .transition(AnyTransition.move(edge: .trailing)).animation(.default)
                    .onAppear {
                        self.progress = progress
                    }
            }
        }
    }
}

struct AsyncOpenPartitionView: View {
    @AsyncOpen(appId: ProcessInfo.processInfo.environment["app_id"]!,
               partitionValue: "wrong_partition_value",
               timeout: 2000)
    var asyncOpen

    var body: some View {
        VStack {
            switch asyncOpen {
            case .connecting:
                ProgressView()
            case .waitingForUser:
                Text("")
                    .accessibilityIdentifier("waiting_user_view")
                ProgressView("Waiting for user to logged in...")
            case .open(let realm):
                ListView()
                    .environment(\.realm, realm)
                    .transition(AnyTransition.move(edge: .leading)).animation(.default)
            case .error(let error):
                ErrorView(error: error)
                    .background(Color.red)
                    .transition(AnyTransition.move(edge: .trailing)).animation(.default)
            case .progress(let progress):
                ProgressView(progress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.yellow)
                    .transition(AnyTransition.move(edge: .trailing)).animation(.default)
            }
        }
    }
}

struct AutoOpenPartitionView: View {
    @AutoOpen(appId: ProcessInfo.processInfo.environment["app_id"]!,
              partitionValue: "wrong_partition_value",
              timeout: 2000)
    var autoOpen

    var body: some View {
        VStack {
            switch autoOpen {
            case .connecting:
                ProgressView()
            case .waitingForUser:
                Text("")
                    .accessibilityIdentifier("waiting_user_view")
                ProgressView("Waiting for user to logged in...")
            case .open(let realm):
                ListView()
                    .environment(\.realm, realm)
                    .transition(AnyTransition.move(edge: .leading)).animation(.default)
            case .error(let error):
                ErrorView(error: error)
                    .background(Color.red)
                    .transition(AnyTransition.move(edge: .trailing)).animation(.default)
            case .progress(let progress):
                ProgressView(progress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.yellow)
                    .transition(AnyTransition.move(edge: .trailing)).animation(.default)
            }
        }
    }
}

enum SubscriptionState {
    case initial
    case completed
    case navigate
}

struct AsyncOpenFlexibleSyncView: View {
    @State var subscriptionState: SubscriptionState = .initial
    @AsyncOpen(appId: ProcessInfo.processInfo.environment["app_id"]!,
               timeout: 2000)
    var asyncOpen

    var body: some View {
        VStack {
            switch asyncOpen {
            case .connecting:
                ProgressView()
            case .waitingForUser:
                ProgressView("Waiting for user to logged in...")
            case .open(let realm):
                switch subscriptionState {
                case .initial:
                    ProgressView("Subscribing to Query")
                        .onAppear {
                            Task {
                                do {
                                    let subs = realm.subscriptions
                                    try await subs.write {
                                        subs.append(QuerySubscription<SwiftPerson>(name: "person_age") {
                                            $0.age > 5 && $0.firstName == ProcessInfo.processInfo.environment["firstName"]!
                                        })
                                    }
                                    subscriptionState = .completed
                                }
                            }
                        }
                case .completed:
                    VStack {
                        Button("Navigate Next View") {
                            subscriptionState = .navigate
                        }
                        .accessibilityIdentifier("show_list_button_view")
                    }
                case .navigate:
                    ListView()
                        .environment(\.realm, realm)
                        .transition(AnyTransition.move(edge: .leading)).animation(.default)
                }
            case .error(let error):
                ErrorView(error: error)
                    .background(Color.red)
                    .transition(AnyTransition.move(edge: .trailing)).animation(.default)
            case .progress(let progress):
                ProgressView(progress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.yellow)
                    .transition(AnyTransition.move(edge: .trailing)).animation(.default)
            }
        }
    }
}

struct AutoOpenFlexibleSyncView: View {
    @State var subscriptionState: SubscriptionState = .initial
    @AutoOpen(appId: ProcessInfo.processInfo.environment["app_id"]!,
              timeout: 2000)
    var asyncOpen

    var body: some View {
        VStack {
            switch asyncOpen {
            case .connecting:
                ProgressView()
            case .waitingForUser:
                ProgressView("Waiting for user to logged in...")
            case .open(let realm):
                switch subscriptionState {
                case .initial:
                    ProgressView("Subscribing to Query")
                        .onAppear {
                            Task {
                                do {
                                    let subs = realm.subscriptions
                                    try await subs.write {
                                        subs.append(QuerySubscription<SwiftPerson>(name: "person_age") {
                                            $0.age > 2 && $0.firstName == ProcessInfo.processInfo.environment["firstName"]!
                                        })
                                    }
                                    subscriptionState = .completed
                                }
                            }
                        }
                case .completed:
                    VStack {
                        Button("Navigate Next View") {
                            subscriptionState = .navigate
                        }
                        .accessibilityIdentifier("show_list_button_view")
                    }
                case .navigate:
                    ListView()
                        .environment(\.realm, realm)
                        .transition(AnyTransition.move(edge: .leading)).animation(.default)
                }
            case .error(let error):
                ErrorView(error: error)
                    .background(Color.red)
                    .transition(AnyTransition.move(edge: .trailing)).animation(.default)
            case .progress(let progress):
                ProgressView(progress)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.yellow)
                    .transition(AnyTransition.move(edge: .trailing)).animation(.default)
            }
        }
    }
}

struct ErrorView: View {
    var error: Error
    var body: some View {
        VStack(spacing: 20) {
            Text("Error")
            Text(error.localizedDescription)
        }
        .padding()
    }
}

struct ListView: View {
    @ObservedResults(SwiftPerson.self) var objects

    var body: some View {
        List {
            ForEach(objects) { object in
                Text("\(object.firstName)")
            }
        }
        .navigationTitle("SwiftHugeSyncObject's List")
    }
}
