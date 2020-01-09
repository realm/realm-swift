import SwiftUI
import RealmSwift

enum LanguageDirection: String, Codable {
    case leftToRight = "ltr"
    case rightToLeft = "rtl"
}

class Language: Object, Codable, Identifiable {
    var id: Int {
        return name.hashValue
    }

    var name: String = ""
    var nativeName: String = ""
    var direction: LanguageDirection? {
        LanguageDirection.init(rawValue: dir)
    }
    private var dir: String = ""
}

class Languages: Object {
    let languages = RealmSwift.List<Language>()
}

struct LanguageChooseView: View {
    var languagesContainer: Languages
    var token: NotificationToken? = nil
    
    init() {
        guard let realm = try? Realm.open(app: app),
            let languages = realm.objects(Languages.self).first else {
            print("Could not open realm")
            self.languagesContainer = Languages()
            return
        }

        self.languagesContainer = languages
        self.token = self.languagesContainer.languages.observe { change in
            print(change)
        }
    }

    var body: some View {
        VStack {
            List {
                ForEach(self.languagesContainer.languages) { language in
                    Text(language.name)
                }
            }.navigationBarTitle("Translate from")
        }
    }
}

struct ContentView: View {
    init() {

    }

    var body: some View {
        NavigationView {
            TabView {
                VStack {
                    HStack {
                        NavigationLink.init("English",
                                            destination: LanguageChooseView())
                        Spacer()
                        Image(systemName:"arrow.right.arrow.left")
                        Spacer()
                        NavigationLink.init("Danish",
                                            destination: LanguageChooseView())
                    }
                    Spacer()
                }.tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            }.navigationBarTitle("realm Translate", displayMode: .inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
