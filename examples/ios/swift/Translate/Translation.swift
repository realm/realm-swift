import Foundation
import RealmSwift

/// A translation from one `Language` to another.
class Translation: Object, Codable {
    private enum CodingKeys: String, CodingKey {
        case originalText, translatedText, to, from
    }

    /// The original text in the language being translated from.
    @objc dynamic var originalText: String
    /// The translated text in the language being translated to.
    @objc dynamic var translatedText: String
    /// The language to translate to.
    @objc dynamic var to: String
    /// The language to translate from.
    @objc dynamic var from: String

    @objc dynamic var isSaved: Bool = false
}
