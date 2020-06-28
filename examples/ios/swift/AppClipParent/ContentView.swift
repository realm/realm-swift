import SwiftUI
import RealmSwift

struct ContentView: View {
    let config = Realm.Configuration(fileURL: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.io.realm.app_group")!.appendingPathComponent("default.realm"))
    // Remove lazy var. Use an actual good practice for SwiftUI + Realm
    lazy var realm = try! Realm(configuration: config)

    var body: some View {
        List {
            Text("First")
            Text("Second")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
