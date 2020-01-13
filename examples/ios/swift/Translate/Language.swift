import Foundation
import RealmSwift

extension Locale.LanguageDirection: Codable {
}

enum LanguageState {
    case from, to
}

/// A spoken language
class Language: Object, Codable {
    static let defaultPrimary: Language = {
        let language = Language()
        language.name = (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier,
                                                                 value: Locale.current.languageCode!)!
        language.nativeName = language.name
        language.languageCode = "en"
        return language
    }()

    static let defaultSecondary: Language = {
        let language = Language()
        var secondaryLanguage = "fr"
        if Locale.preferredLanguages.count > 1 {
            secondaryLanguage = Locale.preferredLanguages[1]
        }
        let locale = (Locale(identifier: secondaryLanguage) as NSLocale)
        language.languageCode = locale.languageCode
        language.name = (locale as NSLocale).displayName(forKey: NSLocale.Key.identifier,
                         value: locale.languageCode)!
        language.nativeName = language.name
        return language
    }()

    /// The name of the language
    @objc dynamic var name: String = ""
    /// The name of the language in the language itself
    @objc dynamic var nativeName: String = ""
    /// The ISO language code
    @objc dynamic var languageCode: String = ""
    /// The direction the characters of the language are written in
    lazy var direction: Locale.LanguageDirection =
        Locale.characterDirection(forLanguage: languageCode)

    override class func ignoredProperties() -> [String] {
        ["direction"]
    }
}
