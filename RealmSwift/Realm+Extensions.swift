import Foundation

public extension Realm {

    static let queue = DispatchQueue(label: "RealmQueue", qos: .background)

    static var defaultConfig: Configuration {
        Realm.Configuration(schemaVersion: 100, deleteRealmIfMigrationNeeded: true)
    }

    static var defaultRealm: Realm {
        get throws {
            try provider.defaultRealm
        }
    }

    static var provider: RealmProvider {
        RealmProvider.shared
    }

    /**
     Participate in the current transaction, if it exists, or create one.
     - Parameter block:
     - Throws:
     */
    func inTransactionDo(_ block: (() throws -> Void)) throws {
        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }

}

extension Realm {
    public func writeAsync<T : ThreadConfined>(_ obj: T,
                                               errorHandler: @escaping ((_ error : Swift.Error) -> Void) = { _ in return },
                                               block: @escaping ((Realm, T?) -> Void)) {

        let wrappedObj = ThreadSafeReference(to: obj)
        DispatchQueue(label: "background").async {
            autoreleasepool {
                do {
                    let config = Realm.Configuration(schemaVersion: 100, deleteRealmIfMigrationNeeded: true)
                    let realm = try Realm(configuration: config)
                    let obj = realm.resolve(wrappedObj)

                    try realm.write {
                        block(realm, obj)
                    }
                }
                catch {
                    errorHandler(error)
                }
            }
        }
    }
}