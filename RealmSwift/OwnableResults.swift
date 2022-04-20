import Foundation
import Realm

public class OwnableResults<T: RealmCollectionValue> {

    private(set) var ownableCollection: RLMOwnableCollection<RLMCollection>

    public init(_ results: Results<T>) {
        ownableCollection = RLMOwnableCollection(items: results.collection)
    }

    public func take() throws -> Results<T> {
        Results<T>(collection: ownableCollection.take())
    }
}
