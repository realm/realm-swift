import SwiftUI
import RealmSwift
import Combine
import Realm.Private

public class SwiftPerson: Object, ObjectKeyIdentifiable {
    @objc public dynamic var _id: ObjectId? = ObjectId.generate()
    @objc public dynamic var firstName: String = ""
    @objc public dynamic var lastName: String = ""
    @objc public dynamic var age: Int = 30

    public convenience init(firstName: String, lastName: String) {
        self.init()
        self.firstName = firstName
        self.lastName = lastName
    }

    public override class func primaryKey() -> String? {
        return "_id"
    }
}

var appId: String!
var app: RealmSwift.App {
    RealmSwift.App(id: appId,
                   configuration: AppConfiguration(baseURL: "http://localhost:9090",
                                                   transport: nil,
                                                   localAppName: nil,
                                                   localAppVersion: nil))
}

struct PersonView: View {
    @AutoOpen(appId: appId, partitionValue: .string(appId)) var realm

    init() {
        app.login(credentials: basicCredentials(usernameSuffix: "username")) { _ in

        }
    }
    var body: some View {
        if let realm = realm {
            VStack {
                Text("People")
                List {
                    ForEach(realm.objects(SwiftPerson.self)) { person in
                        Text(person.firstName)
                    }
                }
            }
        } else {
            ProgressView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        PersonView().frame(width: 200, height: 200)
    }
}

public func basicCredentials(usernameSuffix: String = "") -> Credentials {
    let email = "\(usernameSuffix)"
    let password = "abcdef"
    let credentials = Credentials.emailPassword(email: email, password: password)
    let ex = DispatchSemaphore(value: 0)
    app.emailPasswordAuth.registerUser(email: email, password: password, completion: { error in
        guard error == nil else { fatalError("oops") }
        ex.signal()
    })
    ex.wait()
    return credentials
}

@main
struct App: SwiftUI.App {
    func hydrateServer() -> String {
        print("hydrating")
        let server = RealmServer.shared
        appId = try! server.createApp()
        print("app created: \(appId!)")
        let app = RealmSwift.App(id: appId,
                                 configuration: AppConfiguration(baseURL: "http://localhost:9090",
                                                                 transport: nil,
                                                                 localAppName: nil,
                                                                 localAppVersion: nil))
        var cancellables = [AnyCancellable]()
        let semaphore = DispatchSemaphore(value: 0)
        app.login(credentials: .anonymous)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print(error)
                default: break
                }

            } receiveValue: { user in
                let realm = try! Realm(configuration: user.configuration(partitionValue: .string(appId)))
                try! realm.write {
                    realm.add(
                        (0..<100000).map { _ in SwiftPerson(firstName: "johnny", lastName: "silverhand") }
                    )
                }
                let session = user.session(forPartitionValue: appId as NSString)!
                session.waitForUploadCompletion(on: DispatchQueue(label: "qos")) { _ in
                    user.logOut { _ in
                        user.remove { _ in
                            semaphore.signal()
                        }
                    }
                }
            }.store(in: &cancellables)
        semaphore.wait()
        return appId
    }

    var body: some Scene {
        let view: AnyView = {
            _ = hydrateServer()
            return AnyView(ContentView())
        }()
        return WindowGroup {
            view
        }
    }
}
