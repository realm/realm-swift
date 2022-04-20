import Foundation

public class RealmError : NSError {

    public convenience init(_ message: String = "Realm Error") {
        self.init(domain: "com.symbiose.realm", code: 0, userInfo: [
            NSLocalizedDescriptionKey : message
        ])
    }

}
