import Foundation
import RealmSwift

class MyModel: Object {
    @objc dynamic var str: String = ""
}

let realm = try! Realm()
try! realm.write {
    realm.create(MyModel.self, value: ["Hello, world!"])
}

print(realm.objects(MyModel.self).last!.str)
