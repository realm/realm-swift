import Foundation

/**
 Provides a configured instance or Realm. Realm configuration is modularized and de-duplicated here.
 */
public class RealmProvider {

    static let shared = RealmProvider()

    static let bgQueue = DispatchQueue(label: "RealmQueue")

    var defaultRealm: Realm {
        get throws {
            try realm(queue: nil)
        }
    }

    var bgRealm: Realm {
        get throws {
            try realm(queue: RealmProvider.bgQueue)
        }
    }

    public init() {}

    func realm(queue: DispatchQueue? = nil) throws -> Realm {
        do {
            let config = Realm.Configuration(schemaVersion: 100, deleteRealmIfMigrationNeeded: true)
            let realm = try Realm(configuration: config, queue: queue)
            return realm
        } catch {
            throw error
        }
    }

}
