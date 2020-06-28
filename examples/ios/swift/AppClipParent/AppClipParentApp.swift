// Add Copyright
import SwiftUI
import RealmSwift

@main
struct AppClipParentApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView(/*state: State(),*/)
        }
    }
    
    private func fetchResults() -> Results<DemoObject> {
        let config = Realm.Configuration(fileURL: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.io.realm.app_group")!.appendingPathComponent("default.realm"))
        let realm = try! Realm(configuration: config)
        return realm.objects(DemoObject.self)
    }
}
