import SwiftUI
import RealmSwift

class DemoObject: Object {
    @objc dynamic var uuid = UUID().uuidString
    @objc dynamic var date = NSDate()
    @objc dynamic var title = ""
    @objc dynamic var sectionTitle = ""
}

struct ContentView: View {
    var body: some View {
        List {
            ForEach(fetchResults(), id: \.uuid) { object in
                Text("\(object.uuid)")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
