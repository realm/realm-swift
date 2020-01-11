import Foundation
import RealmSwift

class UserSettings: Object {
    @objc dynamic var lastLangFrom: String = Locale.current.identifier
    @objc dynamic var lastLangTo: String = "fr"

    let translations: RealmSwift.List<Translation> = RealmSwift.List()
}

class AppEnvironment: ObservableObject {
    @Published var tableOfContents: TableOfContents? = .translateView
    @Published var isShowingLanguageSelectionToPage: Bool = false
    @Published var isShowingLanguageSelectionFromPage: Bool = false

    @Published var textToTranslate: String = ""
    @Published var translatedText: String = ""

    @Published var userSettings: UserSettings = UserSettings()

    @Published var languages: Results<Language>
    @Published var translations: Results<Translation>
    @Published var savedTranslations: Results<Translation>

    private let app: RealmApp

    init(app: RealmApp) {
        self.app = app

        let appRealm = try! Realm(configuration: app.configuration())

        self.languages = appRealm.objects(Language.self)
        self.translations = appRealm.objects(Translation.self)
        self.savedTranslations = appRealm.objects(Translation.self).filter("isSaved == true")

        initialize { userSettings in
            self.userSettings = userSettings

            guard let configuration = app.auth.currentUser?.configuration() else {
                fatalError("Impossible state")
            }

            let appRealm = try! Realm(configuration: app.configuration())

            self.languages = appRealm.objects(Language.self)
            let userRealm = try! Realm(configuration: configuration)
            let translations = userRealm.objects(Translation.self)

            self.translations = translations
            self.savedTranslations = translations.filter("isSaved == true")
        }
    }

    /**
     Get the language for the given state.

     - parameter state: whether or not the language is being
                        translated `to` or `from`
     - returns: the language for the given state
     */
    func language(_ state: LanguageState) -> Language {
        switch state {
        case .from:
            return languages.first { $0.languageCode == userSettings.lastLangFrom } ?? .defaultPrimary
        case .to:
            return languages.first { $0.languageCode == userSettings.lastLangTo } ?? .defaultSecondary
        }
    }

    /**
     Set the language for the given state.

     - parameter state: whether or not the language is being
                       translated `to` or `from`
     - parameter language: the language to set to
    */
    func language(_ state: LanguageState, _ language: Language) {
        guard let configuration = app.auth.currentUser?.configuration() else {
            fatalError("Impossible state")
        }

        let realm = try! Realm(configuration: configuration)
        try! realm.write {
            switch state {
            case .from:
                userSettings.lastLangFrom = language.languageCode
            case .to:
                userSettings.lastLangTo = language.languageCode
            }
        }

        objectWillChange.send()
    }

    /**
     Swap the `to` and `from` languages.
     */
    func swapLanguages() {
        let langTo = self.language(.to)
        let langFrom = self.language(.from)
        self.language(.to, langFrom)
        self.language(.from, langTo)
    }

    /**
     Translate the current `textToTranslate` given the current state.
     */
    func translate() {
        app.functions.translate([[
            "text": self.textToTranslate,
            "from": self.userSettings.lastLangFrom,
            "to": self.userSettings.lastLangTo
        ]], Translation.self) { result in
            switch result {
            case .success(let translation):
                self.translatedText = translation.translatedText
                do {
                    guard let configuration = self.app.auth.currentUser?.configuration() else {
                        print("Not logged in")
                        return
                    }

                    let realm = try Realm(configuration: configuration)
                    try realm.write {
                        self.userSettings.translations.append(translation)
                    }
                } catch let error {
                    print(error)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    /**
     Toggle whether or not to save (or "favourite")
     a given translation.

     - parameter translation: the translation to toggle save on
     */
    func toggleSave(for translation: Translation) {
        guard let configuration = app.auth.currentUser?.configuration() else {
            print("Not logged in")
            return
        }

        let realm = try! Realm(configuration: configuration)
        try! realm.write {
            translation.isSaved = !translation.isSaved
        }
    }

    private func downloadLanguages(_ completionHandler: @escaping (UserSettings) -> Void) {
        app.functions.languages([], [Language].self) { result in
            switch result {
            case .success(let languages):
                guard let appRealm = try? Realm(configuration: self.app.configuration()),
                    let user = self.app.auth.currentUser,
                    let userRealm = try? Realm(configuration: user.configuration()),
                    let userSettings = userRealm.objects(UserSettings.self).first else {
                    fatalError("Could not open Realm")
                }

                try! appRealm.write {
                    appRealm.add(languages)
                }

                completionHandler(userSettings)
            case .failure(let error):
                // TODO: Fail gracefully
                fatalError(error.localizedDescription)
            }
        }
    }

    private func initialize(_ completionHandler: @escaping (UserSettings) -> Void) {
        guard let user = app.auth.currentUser else {
            app.auth.logIn(with: SyncCredentials.anonymous(), onCompletion: { user, error in
                guard let user = user else {
                    fatalError(error?.localizedDescription ?? "unknown failure")
                }

                let realm = try! Realm(configuration: user.configuration())
                try! realm.write {
                    realm.add(UserSettings())
                }

                self.downloadLanguages(completionHandler)
            })
            return
        }

        let realm = try! Realm(configuration: user.configuration())
        completionHandler(realm.objects(UserSettings.self).first!)
    }
}
