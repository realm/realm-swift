import Foundation
import RealmSwift

enum LanguageDirection: Int, Codable {
    case unknown
    case leftToRight
    case rightToLeft
}

extension Locale.LanguageDirection: Codable {
}

enum LanguageState {
    case from, to
}

class Language: Object, Codable {
    static let defaultPrimary: Language = {
        let language = Language()
        language.name = (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.identifier,
                                                                 value: Locale.current.languageCode!)!
        language.nativeName = language.name
        language.languageCode = Locale.current.languageCode!
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

    @objc dynamic var name: String = ""
    @objc dynamic var nativeName: String = ""
    @objc dynamic var languageCode: String = ""

    lazy var direction: Locale.LanguageDirection =
        Locale.characterDirection(forLanguage: languageCode)

    override class func ignoredProperties() -> [String] {
        ["direction"]
    }
}
