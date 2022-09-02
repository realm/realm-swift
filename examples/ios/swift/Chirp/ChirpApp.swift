import SwiftUI
import RealmSwift

extension URL: CustomPersistable {
    public typealias PersistedType = String

    public init(persistedValue: String) {
        self.init(string: persistedValue)!
    }

    public var persistableValue: String {
        self.absoluteString
    }
}

class Chirp: Object, Identifiable {
    @Persisted(primaryKey: true) var _id: String
    @Persisted var text: String
    @Persisted var user: ChirpUser?
    @Persisted var media: URL?
    @Persisted var date: Date
}

class ChirpUser: Object, Identifiable {
    @Persisted(primaryKey: true) var _id: String
    @Persisted var username: String
    @Persisted var bio: String
    @Persisted var profilePicture: URL?
    @Persisted var following: RealmSwift.MutableSet<ChirpUser>
    @Persisted var followers: RealmSwift.MutableSet<ChirpUser>
    @Persisted var chirps: RealmSwift.MutableSet<Chirp>
}

struct AppState {
    static var shared: AppState = .init()

    var currentUser: ChirpUser?
    var app = App(id: "<App id>")
}

struct ChirpView: View {
    @ObservedObject var chirp: Chirp

    var body: some View {
        HStack {
            AsyncImage(url: chirp.user!.profilePicture!)
            VStack {
                Text(chirp.user!.username)
                Text(chirp.text)
                if let media = chirp.media {
                    AsyncImage(url: media)
                }
            }
        }
    }
}

struct ChirpUserView: View {
    @ObservedResults(ChirpUser.self, where: { $0.in(AppState.shared.currentUser!.following) })
    var subscribedUsers
    @ObservedObject var user: ChirpUser

    var body: some View {
        VStack(alignment: .center) {
            AsyncImage(url: user.profilePicture!)
            Text(user.bio)
            Button("unfollow") {
                guard let currentUser = AppState.shared.currentUser,
                      let realm = currentUser.realm else { fatalError() }
                try! realm.write {
                    currentUser.following.remove(user)
                }
                Task {
                    try await subscribedUsers.where {
                        $0.in(currentUser.following)
                    }
                }
            }
        }
    }
}

struct ChirpDeckView: View {
    @ObservedResults(ChirpUser.self, where: { $0.in(AppState.shared.currentUser!.following) })
    var subscribedUsers

    var body: some View {
        if case .pending = $subscribedUsers.state {
            ProgressView()
        } else if case let .error(error) = $subscribedUsers.state {
            Text("Error: \(error.localizedDescription)")
        } else {
            List {
                ForEach(subscribedUsers.flatMap(\.chirps).sorted(by: { $0.date > $1.date })) { chirp in
                    ChirpView(chirp: chirp)
                }
            }
        }
    }
}

struct LoginView: View {
    @State var username: String = ""
    @State var password: String = ""

    var body: some View {
        VStack {
            TextField("username", text: $username)
            TextField("password", text: $password)
            Button("login") {
                Task {
                    // login a mongodb realm user
                    let user = try await AppState.shared.app.login(credentials: .emailPassword(email: username, password: password))
                    let realm = try await Realm(configuration: user.flexibleSyncConfiguration())
                    // subscribe to the user's id, and if they exist, set the app state property
                    // else, create the new ChirpUser with the matching id
                    if let chirpUser = try await realm.objects(ChirpUser.self).where({
                        $0._id == user.id
                    }).first {
                        AppState.shared.currentUser = chirpUser
                    } else {
                        let chirpUser = ChirpUser()
                        chirpUser._id = user.id
                        realm.add(chirpUser)
                        AppState.shared.currentUser = chirpUser
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @State var state = AppState.shared

    var body: some View {
        if state.currentUser != nil, let user = AppState.shared.app.currentUser {
            ChirpDeckView().environment(\.realmConfiguration, user.flexibleSyncConfiguration())
        } else {
            LoginView()
        }
    }
}

@main
struct ChirpApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
