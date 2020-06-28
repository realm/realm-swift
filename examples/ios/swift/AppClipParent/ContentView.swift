// Add Copyright
import SwiftUI
import RealmSwift

class DemoObject: Object {
    @objc dynamic var uuid = UUID().uuidString
    @objc dynamic var date = NSDate()
    @objc dynamic var title = ""
    @objc dynamic var sectionTitle = ""
}

//final class State: ObservableObject {
//    @Published var realm: Realm
//    @Published var results: Results<DemoObject>
//    @Published var count: Int = 0
//    
//    init() {
//        let config = Realm.Configuration(fileURL: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.io.realm.app_group")!.appendingPathComponent("default.realm"))
//        let realm = try! Realm(configuration: config)
//        results = realm.objects(DemoObject.self)
//        self.realm = realm
//    }
//}

struct ContentView: View {
//    @ObservedObject var state: State
    // Add results here

    var body: some View {
        Section(header: Button("Add Object", action: addObject)) {
            List {
                ForEach(fetchResults(), id: \.uuid) { object in
                    Text("\(object.uuid)")
                }
            }
        }
    }
    
    private func fetchResults() -> Results<DemoObject> {
        let config = Realm.Configuration(fileURL: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.io.realm.app_group")!.appendingPathComponent("default.realm"))
        let realm = try! Realm(configuration: config)
        return realm.objects(DemoObject.self)
    }
    
    private func addObject() {
        let config = Realm.Configuration(fileURL: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.io.realm.app_group")!.appendingPathComponent("default.realm"))
        let realm = try! Realm(configuration: config)
        try! realm.write {
            realm.add(DemoObject())
        }
    }
}

struct ContentRow: View {
    var body: some View {
        Text("Content Row not implemented")
    }
}

func results(realm: Realm) -> AnyRealmCollection<DemoObject> {
    return AnyRealmCollection(realm.objects(DemoObject.self))
}
